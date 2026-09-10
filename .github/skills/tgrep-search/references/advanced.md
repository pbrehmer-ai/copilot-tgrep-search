# Conditional search reference

Read only the section needed for the current task. Normal count/path discovery is fully described in SKILL.md.

## Direct content inspection

Use the pinned executable at `%LOCALAPPDATA%\Programs\copilot-tgrep\1.0.5\tgrep.exe`, or resolve an approved application on PATH. All flags precede `--`; then supply the pattern and root/file. Literal search uses `-F`. Capture stderr and read `$LASTEXITCODE` immediately after each native call; do not discard errors with `2>$null`.

```powershell
& "$env:LOCALAPPDATA\Programs\copilot-tgrep\1.0.5\tgrep.exe" -n -H --color never -F -C 2 -- 'OrderService' '<absolute-source-root>/src/Orders.cs'
$searchExit = $LASTEXITCODE
```

Exit 0 means a match, 1 means no match in scope, and 2 means an error even if partial matches were printed. With `-q`, a match can hide an error elsewhere; avoid it for exhaustive validation. Limit context and inspect selected files rather than printing every matching line across a monolith. `-m` caps matches per file, not across the repository.

## Root, index and scope

The default index is `<source-root>/.tgrep`. A subdirectory does not find its parent's index: retain the indexed root and narrow with `-g 'src/**'`. The helpers support only this default configuration. For a custom index, preserve the same `--index-path` and admission options for serve/index/search; do not start a second default server alongside it. Never reuse an index across repositories or worktrees.

Startup can expose an empty or partial index. Wait for initial completion before trusting it even for counts; completion does not guarantee freshness after edits. A disk index without a server is only as current as its last build. Rebuilding disk state does not refresh an already-running server. Do not stop an existing server to fix an ordinary query.

The normal ignore, hidden, binary and size rules still apply to direct scans. The default file-size cap is 64 MiB. `--hidden`, `--no-ignore` variants, `--text`, `--binary`, encoding overrides and explicit single files bypass indexing. `--follow`, `--one-file-system` and `--ignore-file` require `--no-index` to take effect. Use these only when the requested scope needs them, and describe exclusions when making absence claims. `--files` can also use an index snapshot.

Keep index/serve/search size settings and `--no-require-git` consistent. `--exclude` is an index/serve option, not a search filter. Outside Git, applying .gitignore requires the appropriate `--no-require-git` workflow. The stock helpers do not model custom admission rules; use reviewed direct commands for those cases.

## Helper output and recovery

`-CheckReady` combines one status check and the search for the first indexed batch. If no initially complete server with an active watcher is found, it returns SetupRequired and an empty Results array, exiting 2. It starts nothing. Omit the flag once readiness is known. `-NoIndex` deliberately bypasses this guard because it reads disk; no readiness claim is made. Neither a passing guard nor `index-eligible` proves server routing or subsequent freshness.

`MatchFileCount` is valid only when Succeeded is true; it reflects the selected search mode and scope. Stderr warnings still matter. `ReturnedPathCount` retains the previous raw-count field for compatibility and is not authoritative on error. Paths are a sorted sample, not necessarily the entire result. Sorting is OrdinalIgnoreCase after slash normalization; ask or use an explicit alternative when a task requires a different collation.

The helper captures complete filename output locally, then emits a bounded sample in compact JSON. This reduces text sent to Copilot, not the amount of engine output captured in memory. A client timeout stops only that helper's search process and skips remaining queries. Helper exit 0 means all executed queries succeeded; 2 means at least one failed. An incomplete batch is not a completed answer.

If the terminal has returned to its prompt but Copilot cannot receive the result, stop after one bounded output retrieval. A working PowerShell 7 `-NoLogo -NoProfile` profile resolved this on one pilot machine; profile changes belong to explicit setup/troubleshooting, not normal search. Use approved IDE tools if the terminal remains unavailable.

`--json` uses line-delimited records. Invalid UTF-8 is repaired in `lines.text`, so use a byte-preserving alternative if original bytes are required.

Adapted from the existing integration guide and [Microsoft's tgrep 1.0.5 agent guide](https://github.com/microsoft/tgrep/blob/v1.0.5/AGENTS.md). See the installed THIRD_PARTY_NOTICES.md. No upstream fetch is needed for ordinary use.
