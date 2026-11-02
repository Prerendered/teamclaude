#!/usr/bin/env node
// Prints a bench/results.md row from a finished run's team/log.jsonl and bug board.
//   node bench/metrics.mjs <project>
import { readFileSync } from 'node:fs';
import path from 'node:path';

const project = process.argv[2];
if (!project) { console.error('usage: metrics.mjs <project>'); process.exit(1); }

const read = (f) => readFileSync(path.join(project, f), 'utf8');
const events = read('team/log.jsonl').split(/\r?\n/).filter(Boolean).map((line) => JSON.parse(line));
const count = (event) => events.filter((e) => e.event === event).length;

const TIERS = ['haiku', 'sonnet', 'opus', 'fable'];
const dispatches = events.filter((e) => e.event === 'dispatch');

// A tier escalation is an agent working a card on a higher tier than it started on.
const firstTier = new Map();
let tierEscalations = 0;
for (const { agent, card, model } of dispatches) {
  const key = `${agent}/${card}`;
  if (!firstTier.has(key)) firstTier.set(key, model);
  else if (TIERS.indexOf(model) > TIERS.indexOf(firstTier.get(key))) tierEscalations++;
}

const hours = (events.length ? Date.parse(events.at(-1).ts) - Date.parse(events[0].ts) : 0) / 3_600_000;

const foundBy = read('team/bug-board.md').split(/\r?\n/)
  .filter((line) => /^\|\s*B\d+\s*\|/.test(line))
  .map((line) => line.split('|')[4].trim());
const bugs = (source) => foundBy.filter((f) => f === source).length;

const version = read('team/state.md').match(/^team-version:\s*(.+)$/m)?.[1].trim() ?? '?';
const date = new Date().toISOString().slice(0, 10);

console.log(`| ${[
  version, date, `${hours.toFixed(1)}h`, dispatches.length, count('escalation'), tierEscalations,
  bugs('tester'), bugs('reviewer'), bugs('security'), bugs('e2e gate'), bugs('session start'), bugs('User'),
  count('lesson'), '', '',
].join(' | ')} |`);
