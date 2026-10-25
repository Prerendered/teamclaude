// Game test bridge — in-game side (e2e-verification layer 3). DEV BUILDS ONLY:
// compile it only with TEAMCLAUDE_BRIDGE defined (Debug configuration), never
// into a release build.
//
// Loader-agnostic: the mod wires three things (see game-bridge README):
//   GameBridge.Start(port)  — once, when the mod initializes
//   GameBridge.Pump()       — every frame, from the loader's main-thread update hook
//   GameBridge.Log(line)    — from the mod's logger (and the loader's, if hookable)
// Probes and commands are registered by the project per story's plan.
//
// Targets mods hosted on .NET 6+ (IL2CPP loaders such as MelonLoader / RedLoader).
// Mono-runtime games without System.Text.Json: swap the serializer, keep the protocol.
#if TEAMCLAUDE_BRIDGE
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

public static class GameBridge
{
    public delegate object Handler(JsonElement args);

    static readonly Dictionary<string, Handler> Probes = new();
    static readonly Dictionary<string, Handler> Commands = new();
    static readonly ConcurrentQueue<(JsonElement req, TaskCompletionSource<string> reply)> Inbox = new();
    static readonly List<string> Logs = new();
    static readonly object LogLock = new();
    const int MaxLogLines = 5000;

    static TcpListener _listener;
    static string _modVersion = "0.0.0";
    public static Func<object> HealthExtra = () => null; // e.g. current save, scene

    public static void Probe(string name, Handler h) => Probes[name] = h;
    public static void Command(string name, Handler h) => Commands[name] = h;

    public static void Log(string line)
    {
        lock (LogLock)
        {
            Logs.Add($"[{DateTime.UtcNow:O}] {line}");
            if (Logs.Count > MaxLogLines) Logs.RemoveRange(0, Logs.Count - MaxLogLines);
        }
    }

    public static void Start(int port, string modVersion)
    {
        _modVersion = modVersion;
        _listener = new TcpListener(IPAddress.Loopback, port); // never a public interface
        _listener.Start();
        new Thread(AcceptLoop) { IsBackground = true, Name = "GameBridge" }.Start();
        Log($"bridge listening on 127.0.0.1:{port}");
    }

    public static void Stop() => _listener?.Stop();

    // Main thread: game APIs are only safe here. Runs every queued request.
    public static void Pump()
    {
        while (Inbox.TryDequeue(out var item))
        {
            object id = null;
            try
            {
                id = item.req.TryGetProperty("id", out var idEl) ? idEl.GetInt64() : null;
                var result = Dispatch(item.req);
                item.reply.SetResult(JsonSerializer.Serialize(new { id, result }));
            }
            catch (Exception e)
            {
                item.reply.SetResult(JsonSerializer.Serialize(new { id, error = e.Message }));
            }
        }
    }

    static object Dispatch(JsonElement req)
    {
        var method = req.GetProperty("method").GetString();
        var p = req.TryGetProperty("params", out var pe) ? pe : default;
        switch (method)
        {
            case "health":
                return new { ready = true, version = _modVersion, extra = HealthExtra() };
            case "list":
                return new { probes = Probes.Keys, commands = Commands.Keys };
            case "read_logs":
            {
                var since = p.ValueKind == JsonValueKind.Object && p.TryGetProperty("since", out var s) ? s.GetInt32() : 0;
                lock (LogLock)
                {
                    since = Math.Clamp(since, 0, Logs.Count);
                    return new { lines = Logs.GetRange(since, Logs.Count - since), cursor = Logs.Count };
                }
            }
            case "query": return Run(Probes, "probe", p);
            case "command": return Run(Commands, "command", p);
            default: throw new InvalidOperationException($"unknown method: {method}");
        }
    }

    static object Run(Dictionary<string, Handler> table, string kind, JsonElement p)
    {
        var name = p.GetProperty("name").GetString();
        if (!table.TryGetValue(name, out var h)) throw new InvalidOperationException($"unknown {kind}: {name}");
        var args = p.TryGetProperty("args", out var a) ? a : JsonDocument.Parse("{}").RootElement;
        return h(args);
    }

    // Background thread: one JSON line in, one JSON line out, per connection.
    static void AcceptLoop()
    {
        while (true)
        {
            TcpClient client;
            try { client = _listener.AcceptTcpClient(); }
            catch (SocketException) { return; } // stopped
            catch (ObjectDisposedException) { return; }
            ThreadPool.QueueUserWorkItem(_ => Serve(client));
        }
    }

    static void Serve(TcpClient client)
    {
        using (client)
        using (var stream = client.GetStream())
        using (var reader = new StreamReader(stream, Encoding.UTF8))
        using (var writer = new StreamWriter(stream, new UTF8Encoding(false)) { AutoFlush = true })
        {
            try
            {
                var line = reader.ReadLine();
                if (line == null) return;
                var reply = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);
                Inbox.Enqueue((JsonDocument.Parse(line).RootElement.Clone(), reply));
                // A paused or loading game stops pumping — time out instead of hanging.
                writer.WriteLine(reply.Task.Wait(TimeSpan.FromSeconds(30))
                    ? reply.Task.Result
                    : JsonSerializer.Serialize(new { error = "game did not pump within 30s (paused or loading?)" }));
            }
            catch (Exception e)
            {
                try { writer.WriteLine(JsonSerializer.Serialize(new { error = e.Message })); } catch { }
            }
        }
    }
}
#endif
