#!/usr/bin/env node
// Lints a deliverable against the Register in design-document.md.
// Usage: node .ai-steering/workflows/lint-deliverable.mjs <file> [<file> ...]
// Output: <file>:<line>: <rule>: <message>. Exit 1 when anything is reported.
// Portable: no dependencies, no project names.

import { readFileSync } from "node:fs";

const SENTENCE_MAX_WORDS = 25;
const EMDASH_MAX_PER_LINE = 1;
const REVISION_ROW_MAX_WORDS = 25;

const BANNED_PHRASES = [
    "this section",
    "this document carries",
    "stated rather than omitted",
    "stated, never omitted",
    "rather than omitted",
    "is the single home",
    "single home of",
    "cited, not restated",
    "cited not restated",
    "not restated",
    "never restated",
    "does not restate",
    "in those words",
    "first-class reader",
    "not an optional one",
    "not an omission",
    "that is the rule",
    "that is not a deviation",
    "stated rather than",
    "not a sketch",
    "not a paragraph of intent",
    "load-bearing",
    "worth stating",
    "it is worth",
    "needless to say",
    "in other words",
];

const files = process.argv.slice(2);
if (files.length === 0) {
    console.error("usage: lint-deliverable.mjs <file> [<file> ...]");
    process.exit(2);
}

let failed = false;
for (const file of files) {
    const findings = lint(file, readFileSync(file, "utf8"));
    for (const f of findings) console.log(`${file}:${f.line}: ${f.rule}: ${f.message}`);
    if (findings.length > 0) failed = true;
}
process.exit(failed ? 1 : 0);

function lint(file, text) {
    const lines = text.split(/\r?\n/);
    const findings = [];
    const report = (line, rule, message) => findings.push({ line, rule, message });

    // Classify every line once.
    const kind = classify(lines);

    // Everything from a template Reference heading onward is deleted at filing; only report its presence.
    let referenceStart = lines.length;
    lines.forEach((l, i) => { if (referenceStart === lines.length && /^##\s+Reference — delete this section/.test(l)) referenceStart = i; });
    const inBody = (i) => i < referenceStart;

    // 1. Author instructions left in.
    lines.forEach((l, i) => {
        if (l.includes("<!-- fill:")) report(i + 1, "fill-comment", "author instruction left in the document");
        if (/^##\s+Reference — delete this section/.test(l)) report(i + 1, "reference-section", "template Reference section left in the document");
    });

    // 2. Section budgets.
    const headings = [];
    lines.forEach((l, i) => {
        if (kind[i] === "heading") headings.push({ line: i, level: l.match(/^#+/)[0].length });
    });
    headings.forEach((h, idx) => {
        let end = lines.length;
        for (let j = idx + 1; j < headings.length; j++) {
            if (headings[j].level <= h.level) { end = headings[j].line; break; }
        }
        let budget = null;
        for (let i = h.line + 1; i < end; i++) {
            const m = lines[i].match(/<!--\s*budget:\s*(\d+)\s*-->/);
            if (m) { budget = Number(m[1]); break; }
            if (kind[i] === "heading") break;
        }
        if (budget === null) return;
        let words = 0;
        for (let i = h.line + 1; i < end; i++) {
            if (kind[i] === "code" || kind[i] === "comment" || kind[i] === "heading" || kind[i] === "blank") continue;
            words += countWords(stripMarkup(lines[i]));
        }
        if (words > budget) {
            report(h.line + 1, "budget", `section is ${words} words, budget ${budget}`);
        }
    });

    // 3. Sentence length, prose lines only.
    lines.forEach((l, i) => {
        if (kind[i] !== "prose" || !inBody(i)) return;
        const clean = stripMarkup(l);
        for (const s of splitSentences(clean)) {
            const n = countWords(s);
            if (n > SENTENCE_MAX_WORDS) {
                report(i + 1, "sentence-length", `${n} words: "${s.slice(0, 60)}${s.length > 60 ? "…" : ""}"`);
            }
        }
    });

    // 4. Banned phrases, everywhere except code and comments.
    lines.forEach((l, i) => {
        if (kind[i] === "code" || kind[i] === "comment" || kind[i] === "frontmatter" || !inBody(i)) return;
        const lower = stripMarkup(l).toLowerCase();
        for (const p of BANNED_PHRASES) {
            if (lower.includes(p)) report(i + 1, "banned-phrase", `"${p}"`);
        }
    });

    // 5. Em-dash density, prose lines only.
    lines.forEach((l, i) => {
        if (kind[i] !== "prose" || !inBody(i)) return;
        const n = (l.match(/—/g) || []).length;
        if (n > EMDASH_MAX_PER_LINE) report(i + 1, "em-dash", `${n} em-dashes on one line`);
    });

    // 6. Revision-log rows.
    let inRevision = false;
    lines.forEach((l, i) => {
        if (kind[i] === "heading") { inRevision = /revision/i.test(l); return; }
        if (!inRevision || kind[i] !== "table") return;
        const cells = l.split("|").map((c) => c.trim()).filter((c) => c.length > 0);
        if (cells.length < 3 || /^-+$/.test(cells[0])) return;
        const last = stripMarkup(cells[cells.length - 1]);
        const n = countWords(last);
        if (n > REVISION_ROW_MAX_WORDS) report(i + 1, "revision-row", `${n} words in the change cell, budget ${REVISION_ROW_MAX_WORDS}`);
    });

    return findings;
}

function classify(lines) {
    const kind = new Array(lines.length);
    let inCode = false;
    let inComment = false;
    let inFrontmatter = false;
    lines.forEach((l, i) => {
        if (i === 0 && l.trim() === "---") { inFrontmatter = true; kind[i] = "frontmatter"; return; }
        if (inFrontmatter) { kind[i] = "frontmatter"; if (l.trim() === "---") inFrontmatter = false; return; }
        if (inCode) { kind[i] = "code"; if (/^\s*```/.test(l)) inCode = false; return; }
        if (/^\s*```/.test(l)) { inCode = true; kind[i] = "code"; return; }
        if (inComment) { kind[i] = "comment"; if (l.includes("-->")) inComment = false; return; }
        if (/^\s*<!--/.test(l)) { kind[i] = "comment"; if (!l.includes("-->")) inComment = true; return; }
        if (l.trim() === "") { kind[i] = "blank"; return; }
        if (/^#{1,6}\s/.test(l)) { kind[i] = "heading"; return; }
        if (/^\s*\|/.test(l)) { kind[i] = "table"; return; }
        if (/^\s*(---|\*\*\*|___)\s*$/.test(l)) { kind[i] = "rule"; return; }
        kind[i] = "prose";
    });
    return kind;
}

function stripMarkup(s) {
    return s
        .replace(/`[^`]*`/g, "CODE")
        .replace(/<[^>]+>/g, "")
        .replace(/\[([^\]]*)\]\([^)]*\)/g, "$1")
        .replace(/[*_]{1,3}/g, "")
        .replace(/&nbsp;|·/g, " ");
}

function countWords(s) {
    return s.split(/\s+/).filter((w) => /[A-Za-z0-9]/.test(w)).length;
}

function splitSentences(s) {
    // Split on a terminator followed by whitespace and a capital letter, a quote, or end of line.
    return s
        .split(/(?<=[.!?])\s+(?=[A-Z"“(]|$)/)
        .map((x) => x.trim())
        .filter((x) => x.length > 0);
}
