# Anchoring an edit site — the shared rule

> **Shared rule, cited by [implementation-plan.md](implementation-plan.md) and [bug-resolution-record.md](bug-resolution-record.md).**
> Cite this file; do not copy the table into a template or a filed deliverable.

**An anchor must survive an edit above it.** A line number alone never qualifies: it is correct only against the
commit it was read at, and the first insertion above it makes it wrong silently.

**Quote the shortest unique existing text at the edit site.** Where lines have drifted, the executor relocates the
site by searching for that text rather than re-planning or re-investigating.

| Kind | Anchor with | Verify with |
|---|---|---|
| compiled source | symbol signature, or an exact quoted line | the unit or integration test that exercises it |
| test | test class or method name | the test run itself |
| schema / migration | schema object name plus the statement text; a new migration file needs no anchor | applying it, and applying it twice |
| UI | component or class name, plus a template selector, test id, or translation key | the component test, or a before-and-after view |
| configuration | the key path, written out in full | the rendered or effective configuration, diffed |
| deployment manifest / chart | chart or manifest name plus the key path | rendering the template for **each** environment and diffing |
| process, workflow or rule definition | the element or rule identifier | an engine or runtime execution |
| generated artifact | **never edited** — name the generator and its input | re-running the generator |
| data fix | the selection predicate, plus the row count it matched | a dry-run count before, and the count after |
