---
name: tgrep-search
description: Find candidate files and count literal or regex matches across large saved source trees with Microsoft tgrep. Use for broad or repeated repository text searches. Read already-known files directly; use IDE tools for semantic references and unsaved buffers.
compatibility: Visual Studio 2026 18.5+, Copilot Agent mode, a working approved PowerShell terminal, and tgrep 1.0.5.
metadata:
  version: "0.3.0-pilot"
  upstream-version: "1.0.5"
---

# Repository search

Use a ready index for broad discovery. Keep the source root fixed and return counts plus a few candidate paths. Read this skill once per chat; do not reread it or the helper source to discover the output schema below.

## Run one useful search

Resolve the source root from the open solution, using `git -C '<solution-directory>' rev-parse --show-toplevel` when needed. A nested solution folder is often not the repository root. Always pass the absolute root, even if the terminal's working directory changes.

When setup already reported READY for this root in the current session, reuse it without another status/version call. Otherwise add `-CheckReady` to the first helper call: it checks readiness and searches in the same call. `SetupRequired: true` means no query ran; prepare with the adjacent `scripts/Start-Repository.ps1 -Root '<root>'` if authorized, or use existing IDE/ripgrep tools for a one-off scan. Initial completion is not proof of freshness.

For counts or candidate paths, execute the adjacent helper in the existing PowerShell host. Substitute the path relative to the SKILL.md actually loaded; the usual personal path is:

```powershell
& "$env:USERPROFILE\.copilot\skills\tgrep-search\scripts\Search.ps1" -Root '<absolute-source-root>' -Pattern 'OrderService','InvoiceService' -Glob '*.cs','!**/bin/**','!**/obj/**','!**/.git/**','!**/.vs/**' -MaxPaths 3 -CheckReady
```

Omit `-CheckReady` after readiness is established in this session. Replace patterns and filters with the requested scope. Literals are case-sensitive by default; add `-Regex` only for regex. Batch independent terms in one call. Default MaxPaths is 5; use 0 for counts only. The helper sorts all paths before sampling, so 3 suffices for the first three alphabetical paths. Larger values are capped at 1000; they never increase count accuracy.

## Read the result, do not repeat the search

The helper returns compact JSON with **Results**, not Queries:

```json
{"SearchMode":"index-eligible","PathLimit":3,"RequestedQueries":1,"CompletedQueries":1,"Results":[{"Pattern":"OrderService","Succeeded":true,"ExitCode":0,"TimedOut":false,"Stderr":"","MatchFileCount":42,"Paths":["src/A.cs","src/B.cs","src/C.cs"],"PathsTruncated":true}]}
```

`Results[i].MatchFileCount` is the full matching-file count for that successful search, independent of PathLimit; it is null on failure. Paths are repository-relative, slash-normalized and sorted with OrdinalIgnoreCase. `ReturnedPathCount` is a compatibility alias for the observed full count. Read Paths directly; do not request all paths just to count or sort them. Reuse the returned result if subsequent processing is needed, without rerunning the command to inspect its schema.

Check Succeeded, Stderr, ReadinessStderr and CompletedQueries. Native exit 1 is a successful no-match result, not an execution failure. Errors/timeouts are not zero matches. SearchMode describes the request; `index-eligible` is not proof of server use. Preserve fallback warnings and correct the root/server if repeated searches scan unexpectedly.

## Choose freshness deliberately

“Saved source files” alone does not require bypassing a ready index for exploratory discovery. Inspect selected current files before explaining or editing them. Use `-NoIndex` for decisive absence checks, an explicitly current exhaustive count, or after changes/watcher trouble when the result must reflect disk now. Narrow the scope where the task permits it. Never weaken freshness to claim a speedup, and do not rescan every positive exploratory result.

Read a known file directly; do not load this skill for that alone. Use IDE tools for symbol identity and unsaved buffers. A text match does not establish a declaration/reference relationship.

If the helper fails, correct an evident argument error once or use available IDE/ripgrep tools. If terminal output does not reach chat, allow one bounded retrieval, then stop that workflow. Ordinary searches do not authorize installation, profile changes or permission changes. Do not stop a shared server.

For custom index paths, direct content commands, unusual encodings, hidden/ignored files or terminal recovery, read [advanced.md](references/advanced.md) only when needed. The installed executable is `%LOCALAPPDATA%\Programs\copilot-tgrep\1.0.5\tgrep.exe`; helpers resolve it without relying on a refreshed PATH.
