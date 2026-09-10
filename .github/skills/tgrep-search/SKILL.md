---
name: tgrep-search
description: Search large saved source trees with Microsoft tgrep. Use for broad or repeated text discovery and bounded current source evidence. Use IDE tools for known files, semantic references and unsaved buffers.
compatibility: Visual Studio 2026 18.5+, Copilot Agent mode, a working approved PowerShell terminal, and tgrep 1.0.5.
metadata:
  version: "0.4.1-pilot"
  upstream-version: "1.0.5"
---

# Search with bounded evidence

Load this skill once. Use the source repository root, which may be above the solution directory; resolve with git only when unknown. Run the adjacent helper in the existing PowerShell host (adjust the script path to this skill's installation):

```powershell
& "$env:USERPROFILE\.copilot\skills\tgrep-search\scripts\Search.ps1" -Root '<absolute-source-root>' -Pattern 'OrderService','InvoiceService' -Glob '*.cs','!**/bin/**','!**/obj/**','!**/.git/**','!**/.vs/**' -MaxPaths 3 -Compact -CheckReady
```

Replace terms and scope. Batch independent terms. Literal matching is case-sensitive; `-Regex` enables regex. `-CheckReady` combines first-use readiness and search; omit it once ready in this session. `SetupRequired` means no search ran: use an authorized setup workflow or existing search tools. Never stop a shared server.

**For explanation or line citations, add `-IncludeContext` to that first search.** It reads sampled files from disk: two matches per file, six context lines each side, 6000 source-text characters across the batch. Keep these defaults initially. **Evidence already satisfies a request to inspect current saved contents: do not reread those same lines with get_file merely to verify freshness.** If one declaration/caller example is requested, choose one complete, verified pair and stop; do not inspect parallel implementations. Read only missing ranges when a body or relationship extends beyond the excerpt. Expand limits only to fill an identified gap (advanced options below). A similarly named field or downstream use is not a direct caller.

Read `Results`: `Pattern`, `Succeeded`, full `MatchFileCount`, sorted slash-normalized `Paths`, `PathsTruncated`; optional `Evidence` contains `Path`, `MatchLines`, numbered `Lines`. Samples use OrdinalIgnoreCase; larger MaxPaths does not improve count accuracy (0 means counts only, cap 1000). Evidence is always an excerpt, not a complete occurrence list; `EvidenceTruncated` additionally marks the character budget. Handle `EvidenceErrors`, other errors/warnings and incomplete batches; failed searches have null counts. Reuse results; do not reread helpers or retry to discover the schema.

When necessary: `-ContextLines 0..20`, `-MaxMatches 1..10`, `-MaxEvidenceChars 100..20000`. A larger maximum is not a target.

Keep broad discovery indexed. "Saved files" alone does not require `-NoIndex`. Use it for decisive absence, explicitly current exhaustive counts, or uncertain freshness after changes. Current excerpts verify selected files only. `index-eligible` is a request, not proof of server use. Preserve warnings. For unusual encodings, hidden files, custom indexes or recovery, read [advanced.md](references/advanced.md).

Finish when the requested evidence is sufficient. In hosts requiring `task_complete`, call it once the task is actually complete, before the final response, instead of waiting for an Autopilot reminder. Ordinary searches do not authorize installation, terminal-profile or permission changes.
