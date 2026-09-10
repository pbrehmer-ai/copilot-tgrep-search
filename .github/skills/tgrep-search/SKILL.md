---
name: tgrep-search
description: Speed up repeated repository-wide text, literal, regex, and searchable-file discovery with Microsoft tgrep in GitHub Copilot for Visual Studio on Windows. Use when locating code, strings, configuration, or candidate files across a solution's source tree. Preserve IDE tools for semantic references, renames, type information, and unsaved editor buffers.
compatibility: Visual Studio 2026 18.5 or later, Copilot Agent mode with terminal access, Windows PowerShell 5.1 or later, and Microsoft tgrep 1.0.5 on PATH.
metadata:
  version: "0.1.0-draft"
  upstream-version: "1.0.5"
  upstream-agents-commit: "33675ce2342ad36bd080da3e1df91a863a22edbc"
---

# Repository search with tgrep

Use tgrep to reduce repeated full-tree text scans. Reuse an index and a running server when they fit the task. Keep results small enough to inspect. This skill changes how you choose and run searches; it does not replace Visual Studio's built-in tools.

## Choose the right search

- Use indexed tgrep for broad literal/regex searches and candidate-file discovery across saved repository files.
- Use IDE symbol/reference tools for semantic questions, overload resolution, renames, call hierarchies, or type relationships. A text occurrence is not necessarily a reference to the same symbol.
- Use editor context for unsaved changes. Neither an index nor `--no-index` can see unsaved buffers. Do not save the user's work just to make a search succeed.
- Read a known file directly or search that file when the task is already narrow. Do not build an index just to inspect one file.
- If tgrep is missing, incompatible, blocked, or fails, use available IDE search or ripgrep and briefly state the limitation. Do not install software or change policies as a side effect of an ordinary search request.

## Establish the root once

1. Determine the directory of the open solution and the intended source tree. A `.sln`/`.slnx` file is not itself a search directory. Repository root, solution directory, and project directory can differ.
2. In a Git checkout, use `git -C '<solution-directory>' rev-parse --show-toplevel` to help identify the root. Otherwise use the relevant solution/source directory. Do not assume the terminal starts in either location.
3. Account for linked projects or files outside that root only when they belong to the requested scope. Search additional roots explicitly; do not broaden a query to an entire drive. Preserve exclusions and access boundaries required by the user's environment.
4. Remember the selected root for the session, but set it explicitly for **every terminal invocation**, using the tool's working-directory parameter or `Set-Location -LiteralPath '<resolved-root>'`. Shell working directories and PowerShell variables may not persist between tool calls. Use the same root for `status`, `index`, `serve`, and directory searches.

In tgrep 1.0.5, the default index is `<search-root>\.tgrep`; a subdirectory search does **not** discover an ancestor index automatically. With a server at the repository root, keep the positional search root as `.` and scope with `-g 'src/**'` or `-t`. For a custom index location, pass the same `--index-path` to every relevant command. Never share an index between different repositories or worktrees.

## Check readiness without adding per-query overhead

At the first broad search in a repository/session, locate the executable and inspect status. Prefer this setup's pinned executable when present; otherwise resolve the application on PATH. A machine PATH entry can precede the user PATH, so a successful setup does not establish which bare `tgrep` command will run.

```powershell
$tgrepExe = Join-Path $env:LOCALAPPDATA 'Programs\copilot-tgrep\1.0.5\tgrep.exe'
if (-not (Test-Path -LiteralPath $tgrepExe -PathType Leaf)) {
    $tgrepExe = (Get-Command tgrep -CommandType Application -ErrorAction Stop).Source
}
& $tgrepExe --version
& $tgrepExe status .
```

Remember the selected executable path and invoke it explicitly if PATH resolves elsewhere. Later examples use `tgrep` as shorthand for that executable; substitute `& '<resolved-executable-path>'` when needed. Check version/readiness once, not before every query.

Inspect the status **text**, not just its exit code. `status` can succeed while reporting no index or no running server. `Indexing: complete` describes initial-build completion, not freshness.

- **Suitable server already running:** reuse it. Do not start another server or rebuild before each query.
- **No suitable server, repeated broad searches expected:** start one if background processes and local index writes are allowed for this task. Starting a server creates/updates `.tgrep`; keep it out of commits using the project's existing exclusion policy.
- **One-off search with no suitable index/server, or background/index writes unavailable:** use a scoped `--no-index` scan or the available fallback. Do not spend time on setup for a small search.
- **A process cannot survive tool calls:** a completed `tgrep index .` can support repeated searches of unchanged files. It becomes stale after edits; use a direct scan for current results. Rebuilding the on-disk index does not refresh an already running server.

For a default root-local index, the Windows background start is:

```powershell
$tgrepExe = Join-Path $env:LOCALAPPDATA 'Programs\copilot-tgrep\1.0.5\tgrep.exe'
if (-not (Test-Path -LiteralPath $tgrepExe -PathType Leaf)) {
    $tgrepExe = (Get-Command tgrep -CommandType Application -ErrorAction Stop).Source
}
$tgrepProcess = Start-Process -FilePath $tgrepExe -ArgumentList @('serve', '.') -WorkingDirectory (Get-Location).Path -WindowStyle Hidden -PassThru
$tgrepProcess.Id
& $tgrepExe status .
```

This starts a process; it is not proof of readiness. A first build can answer from an empty index; a resumed build can answer from partial data. For an immediate answer, use `--no-index`. If indexed searches are worth waiting for, check status at sensible intervals rather than spinning. An interrupted build may leave an incomplete disk index. Avoid unverified negative conclusions from it.

The startup example assumes default index options. If an existing workflow uses custom options, preserve those options and quote paths appropriately. Do not kill an existing server: other tools or people may be using it. Record a newly started process/root for any explicitly requested cleanup.

## Search with explicit, compact output

Use this order: `tgrep <flags> -- <pattern> <root>`. All flags come before `--`. This also lets words such as `index`, `serve`, `status`, and `help` be searched rather than parsed as commands. Use `-F` for literal strings and symbol spellings unless regex is needed.

From the established root:

```powershell
# Find candidate C# files before reading their contents.
tgrep -l -F -t cs -- 'OrderService' .

# Keep the root index while narrowing to a subtree.
tgrep -n -H --color never -F -g 'src/**' -C 2 -- 'ConnectionStrings' .

# Use a regex only when its alternatives are useful.
tgrep -n -H --color never -g '*.cs' -- 'TODO|FIXME' .

# List eligible filenames; this can also be an index snapshot.
tgrep --files -t cs .

# Inspect current saved contents when freshness is required.
tgrep --no-index -n -H --color never -F -g 'src/**' -- 'OldSettingName' .

# Explicit single files are searched directly.
tgrep -n -H --color never -F -C 2 -- 'OrderService' 'src/Orders/OrderService.cs'
```

Use forward slashes inside globs. Narrow scope before requesting large context. Prefer `-l` for broad discovery, `-C 2` or `-C 3` for inspection, and `-q` for a genuine yes/no query. `-m` caps matches **per file**; it is not a repository-wide result limit. Do not interpret capped output as exhaustive. Captured content output should include paths and line numbers (`-H -n`) or use `--json`/`--vimgrep`.

## Verify freshness when the conclusion depends on it

Use a scoped `--no-index` search for decisive checks after edits, generation, branch changes, bulk file changes, or watcher trouble. Also verify a negative indexed result before concluding that an implementation, reference string, or obsolete setting is absent.

Do not rescan every successful exploratory query by default. Reuse indexed discoveries, then inspect the relevant current files before editing or making a final claim.

`--no-index` reads current saved files but still applies ignore, hidden-file, binary, and size rules. It is not an atomic filesystem snapshot. The default file-size limit is 64 MiB. When the task explicitly includes hidden, ignored, binary, unusually encoded, or larger files, select the necessary supported options and describe the resulting scope. Use `--no-max-filesize` only when that scope requires it. A negative result says nothing about excluded files.

Other index considerations:

- Watcher events are asynchronous; a running server can lag. Missed native events may remain until reconciliation. `--no-watch` disables subsequent automatic refresh.
- `--files` is indexed too; add `--no-index` for current eligible filenames.
- `--hidden`, `--no-ignore`/`-u` variants, `--text`, `--binary`, encoding changes, and explicit single-file searches bypass the index. Expect the cost of a scan.
- `--follow`, `--one-file-system`, and `--ignore-file` only take effect on a full scan. Pair them with `--no-index` when required.
- Keep root, `--index-path`, file-size settings, and `--no-require-git` aligned across index/serve/search. Keep `--exclude` and indexing `--no-ignore` settings aligned between index and server; `--exclude` is not a search flag. Changing the server's admission rules can remove files from the index.
- Outside Git repositories, `.gitignore` is not applied by default. Use `--no-require-git` consistently if the task expects those ignore rules to apply.

## Interpret output and errors

Capture stdout, stderr, and the process exit code together. In PowerShell, read `$LASTEXITCODE` immediately after the tgrep invocation if you need its exit status.

| Exit code | Meaning | Action |
| --- | --- | --- |
| `0` | At least one match | Inspect results and stderr. |
| `1` | No match in the searched scope | Not a command failure; check freshness and exclusions before a definitive absence claim. |
| `2` | Error | Inspect stderr; matches may still have been printed. Correct the query or use a fallback. |

With `-q`, a match can produce `0` despite an error elsewhere; do not use it to prove an entire tree was searched without errors. Missing-index warnings can accompany `0` or `1`; if repeated searches are falling back to scans, correct the root/index configuration instead of assuming the speed benefit is active.

`--json` uses newline-delimited ripgrep-style records. One documented difference matters to parsers: invalid UTF-8 is emitted as repaired `lines.text`, not raw base64 `lines.bytes`. Use a byte-preserving alternative when exact original bytes matter. Unsupported flags should be corrected or handled with another tool, not silently dropped.

## Source

Adapted from [Microsoft's agent guide](https://github.com/microsoft/tgrep/blob/33675ce2342ad36bd080da3e1df91a863a22edbc/AGENTS.md) and [tgrep 1.0.5 documentation](https://github.com/microsoft/tgrep/tree/v1.0.5), with Visual Studio workflow guidance. Setup installs `THIRD_PARTY_NOTICES.md` beside this file; the same notice is in the source repository root. No upstream lookup is needed for ordinary use.
