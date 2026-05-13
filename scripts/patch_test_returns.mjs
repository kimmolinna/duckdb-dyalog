/**
 * Normalize test tradfns: explicit r←Name header; end with ⎕←↑r (session log only).
 * Run: node scripts/patch_test_returns.mjs
 */
import { readFileSync, writeFileSync, readdirSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..", "db");

function fixHeaderLine(line) {
  const s = line.replace(/\n$/, "");
  if (!s.trim() || s.trimStart().startsWith("⍝")) return line;
  if (/^\s*r←test/.test(s)) return line;
  const m = s.match(/^(\s*)(test[A-Za-z0-9]+);(.*)$/);
  if (!m) return line;
  let rest = m[3];
  const parts = rest.split(";");
  if (parts.length && parts[parts.length - 1] === "r") parts.pop();
  rest = parts.join(";");
  return `${m[1]}r←${m[2]};${rest}\n`;
}

function fixThreeLineBanner(text) {
  return text.replace(/⎕←↑r\n+⎕←''\n⎕←'([^']*)'\n/g, (_, msg) => {
    return `r,←⊂''\nr,←⊂'${msg}'\n⎕←↑r\n`;
  });
}

function fixPhase2(text) {
  let lines = text.split(/(?<=\n)/);
  if (lines.length) lines[0] = fixHeaderLine(lines[0]);
  let t = lines.join("");
  t = t.replaceAll("{}close db\n⎕←↑r\n\n⍝ =====", "{}close db\n\n⍝ =====");
  t = t.replaceAll(
    "{}close db\n\n⎕←↑r\n\n⍝ ===== SUMMARY =====",
    "{}close db\n\n⍝ ===== SUMMARY ====="
  );
  const labels = [
    "Test STRUCT Type",
    "Test MAP Type",
    "Test ENUM Type",
    "Test Nested LIST",
    "Test Pending/Streaming API",
    "Test Appender Row-wise API",
    "Test Appender Clear/Columns API",
    "Test Appender Error API",
  ];
  for (const label of labels) {
    const once = `r←⊂'${label}'`;
    const rep = `r,←⊂'${label}'`;
    if (!t.includes(once)) continue;
    t = t.replace(once, rep);
  }
  t = t.replace(
    "⍝ ===== SUMMARY =====\n⎕←''\n⎕←'Phase 2 testing complete!'\n" +
      "⎕←'Advanced data types plus pending/streaming, extended appender/error APIs, " +
      "and Arrow conversion smoke coverage have been implemented.'\n",
    "⍝ ===== SUMMARY =====\n" +
      "r,←⊂''\n" +
      "r,←⊂'Phase 2 testing complete!'\n" +
      "r,←⊂'Advanced data types plus pending/streaming, extended appender/error APIs, " +
      "and Arrow conversion smoke coverage have been implemented.'\n" +
      "⎕←↑r\n"
  );
  return t;
}

function listTestFiles() {
  const testsDir = join(ROOT, "tests");
  return readdirSync(testsDir)
    .filter((f) => /^test.*\.aplf$/i.test(f))
    .map((f) => join(testsDir, f))
    .sort();
}

function processFile(path, raw) {
  let lines = raw.split(/(?<=\n)/);
  if (lines.length) lines[0] = fixHeaderLine(lines[0]);
  let text = lines.join("");
  const base = path.split(/[/\\]/).pop();
  if (base === "testPhase2.aplf") text = fixPhase2(text);
  else {
    text = fixThreeLineBanner(text);
  }
  return text;
}

function main() {
  const paths = listTestFiles();
  let n = 0;
  for (const p of paths) {
    const raw = readFileSync(p, "utf8");
    const text = processFile(p, raw);
    if (text !== raw) {
      writeFileSync(p, text.replace(/\r\n/g, "\n"), "utf8");
      n++;
    }
  }
  const testAplf = join(ROOT, "tests", "test.aplf");
  let t = readFileSync(testAplf, "utf8");
  let tl = t.split(/(?<=\n)/);
  if (tl.length) tl[0] = fixHeaderLine(tl[0]);
  t = tl.join("");
  if (t.includes("r←↑s1,s2") && !t.includes("\n⎕←↑r\n")) {
    t = t.replace("r←↑s1,s2\n", "r←↑s1,s2\n⎕←↑r\n");
  }
  writeFileSync(testAplf, t.replace(/\r\n/g, "\n"), "utf8");

  const p1 = join(ROOT, "tests", "testPhase1.aplf");
  t = readFileSync(p1, "utf8");
  tl = t.split(/(?<=\n)/);
  if (tl.length) tl[0] = fixHeaderLine(tl[0]);
  t = tl.join("");
  if (!t.includes("\n⎕←↑r\n")) {
    t = t.replace(
      " r,←⊂'All critical functionality for prepared statements, configuration, and error handling has been implemented.'\n\n",
      " r,←⊂'All critical functionality for prepared statements, configuration, and error handling has been implemented.'\n⎕←↑r\n\n"
    );
  }
  writeFileSync(p1, t.replace(/\r\n/g, "\n"), "utf8");

  console.log("patched test files");
}

main();
