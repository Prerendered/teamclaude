# Benchmark results

One row per tag or measured commit. See [run.md](run.md). Release notes cite the
differences between rows.

The baseline is v2.0 plus the session-start reconcile and dispatch log, because plain
v2.0 has no log to measure. So those two changes aren't measured themselves.

| Version | Date | Wall time | Dispatches | User escalations | Tier escalations | Bugs: tester | reviewer | security | e2e gate | session start | User | Lessons | Est. cost | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
