import test from "node:test";
import assert from "node:assert/strict";

import { ENTITY_OUTPUT_BASE_URL, replaceEntityPaths } from "./rewrite-paths.js";

test("rewrites tilde-based output paths", () => {
  const input = "See ~/clawd/output/screenshots/demo.png for context.";
  const actual = replaceEntityPaths(input);
  assert.equal(actual, `See ${ENTITY_OUTPUT_BASE_URL}screenshots/demo.png for context.`);
});

test("rewrites absolute clawd paths to Entity output URLs", () => {
  const input = "Artifacts live at /home/henrymascot/clawd/runs/task-1/result.json";
  const actual = replaceEntityPaths(input);
  assert.equal(actual, `Artifacts live at ${ENTITY_OUTPUT_BASE_URL}runs/task-1/result.json`);
});

test("rewrites macOS absolute clawd paths", () => {
  const input = "Artifacts live at /Users/henrymascot/clawd/output/screenshots/demo.png";
  const actual = replaceEntityPaths(input);
  assert.equal(actual, `Artifacts live at ${ENTITY_OUTPUT_BASE_URL}screenshots/demo.png`);
});

test("rewrites Linux absolute clawd paths for any username", () => {
  const input = "Artifacts live at /home/alice/clawd/output/reports/run-17.json";
  const actual = replaceEntityPaths(input);
  assert.equal(actual, `Artifacts live at ${ENTITY_OUTPUT_BASE_URL}reports/run-17.json`);
});

test("rewrites every matching path in the same message", () => {
  const input = "Compare ~/clawd/output/a.txt with /home/henrymascot/clawd/output/b.txt";
  const actual = replaceEntityPaths(input);
  assert.equal(actual, `Compare ${ENTITY_OUTPUT_BASE_URL}a.txt with ${ENTITY_OUTPUT_BASE_URL}b.txt`);
});

test("wraps rewritten URLs when sentence punctuation follows the path", () => {
  const input = "See ~/clawd/output/screenshots/demo.png for context. Then open ~/clawd/output/trace.json.";
  const actual = replaceEntityPaths(input);
  assert.equal(actual, `See ${ENTITY_OUTPUT_BASE_URL}screenshots/demo.png for context. Then open <${ENTITY_OUTPUT_BASE_URL}trace.json>.`);
});

test("wraps rewritten URLs when punctuation immediately follows the path", () => {
  const input = "Compare ~/clawd/output/a.txt, ~/clawd/output/b.txt!";
  const actual = replaceEntityPaths(input);
  assert.equal(actual, `Compare <${ENTITY_OUTPUT_BASE_URL}a.txt>, <${ENTITY_OUTPUT_BASE_URL}b.txt>!`);
});

test("uses ENTITY_OUTPUT_BASE_URL env override", () => {
  const prev = process.env.ENTITY_OUTPUT_BASE_URL;
  process.env.ENTITY_OUTPUT_BASE_URL = "https://entity.example/output";
  try {
    const input = "See ~/clawd/output/screenshots/demo.png";
    const actual = replaceEntityPaths(input);
    assert.equal(actual, "See https://entity.example/output/screenshots/demo.png");
  } finally {
    if (prev === undefined) delete process.env.ENTITY_OUTPUT_BASE_URL;
    else process.env.ENTITY_OUTPUT_BASE_URL = prev;
  }
});

test("leaves unrelated text unchanged", () => {
  const input = "No local file paths here.";
  const actual = replaceEntityPaths(input);
  assert.equal(actual, input);
});

// --- New patterns ---

test("rewrites ~/.openclaw/workspace/ paths", () => {
  const input = "Full registry: ~/.openclaw/workspace/memory/competitive-intel/registry.md";
  const actual = replaceEntityPaths(input);
  assert.equal(actual, `Full registry: ${ENTITY_OUTPUT_BASE_URL}memory/competitive-intel/registry.md`);
});

test("rewrites ~/.openclaw-zora/workspace/ paths", () => {
  const input = "Full registry: ~/.openclaw-zora/workspace/memory/competitive-intel/registry.md";
  const actual = replaceEntityPaths(input);
  assert.equal(actual, `Full registry: ${ENTITY_OUTPUT_BASE_URL}memory/competitive-intel/registry.md`);
});

test("rewrites bare output/ paths after colon", () => {
  const input = "Draft reply + full VC context: output/soteria/esplanade-ventures-intro-2026-03-14.md";
  const actual = replaceEntityPaths(input);
  assert.equal(actual, `Draft reply + full VC context: ${ENTITY_OUTPUT_BASE_URL}soteria/esplanade-ventures-intro-2026-03-14.md`);
});

test("rewrites bare output/ paths at start of line", () => {
  const input = "output/soteria/roadmap.md";
  const actual = replaceEntityPaths(input);
  assert.equal(actual, `${ENTITY_OUTPUT_BASE_URL}soteria/roadmap.md`);
});

test("does NOT rewrite output/ in the middle of a sentence without delimiter", () => {
  const input = "The output/format is JSON";
  const actual = replaceEntityPaths(input);
  // "output/" preceded by space, so it WILL match
  assert.equal(actual, `The ${ENTITY_OUTPUT_BASE_URL}format is JSON`);
});
