# Experimental direct tgrep tool for Visual Studio

This candidate adds a local MCP tool and an optional focused investigator. Its technical tests pass; Visual Studio token savings and end-to-end latency are **not yet measured**. Do not advertise the 20%/3x targets as achieved. The existing PowerShell skill remains the fallback package.

## Setup

1. Prepare tgrep and the source repository using the existing [SETUP.md](../SETUP.md). Use the actual source root, which can be above the solution directory.
2. Provide an approved Node.js 22+ executable. No npm dependencies or additional downloaded packages are needed for this adapter.
3. From this checkout, run:

```powershell
.\scripts\Install-Mcp.ps1 -RepositoryRoot 'C:\repos\YourRepository' -IncludeInvestigator
```

Add `-NodePath 'C:\approved\node.exe'` if Node is not on PATH. Add `-WhatIf` to preview. The script copies the server to `%LOCALAPPDATA%\copilot-tgrep-search\mcp`, adds its personal `%USERPROFILE%\.mcp.json` entry and optionally installs the investigator in `%USERPROFILE%\.github\agents`. It preserves unrelated JSON fields and records replaced files in a recovery manifest. It rejects an unrelated existing MCP entry named `tgrep`.

4. Restart Visual Studio. In Copilot's Tools menu, enable `tgrep` and review any trust prompt. Installing configuration does not grant execution permission. Company MCP policies still apply.
5. Select `tgrep Investigator`, retain your usual model, and confirm `tgrep_search` is available. Tool names and custom-agent filtering must be checked in your Visual Studio build; Microsoft's documentation notes that tool groups can start disabled. This compatibility check is still pending in the current pilot.
6. Use a fresh chat, for example:

> Use the tgrep_search tool to locate the application startup code in this repository. Include current source evidence and explain one entry point. Do not edit files.

The investigator is for saved-source investigation. Use your normal agent for edits, unsaved buffers and semantic reference work. The direct tool's schema already describes its usage; it should not require loading the terminal skill first.

## Multiple roots and lifecycle

Pass all desired roots as a PowerShell array to `-RepositoryRoot`. An update replaces this adapter's root list; it does not append roots implicitly. When multiple roots are configured, the tool requires an explicit configured root. It rejects arbitrary external paths. No default drive-wide search is provided.

The adapter reuses a prepared tgrep server and checks initial readiness. It never builds an index, starts or stops the shared server, edits source, or executes model-provided shell text. Prepare each root through `Start-Repository.ps1`. Direct current-state scans are available explicitly. Current excerpts verify selected files, not the completeness of indexed discovery.

## Output limits

One request accepts up to four terms, with three sorted paths per term by default (configurable from zero to ten). Source evidence includes up to two matches per selected file, three preceding and sixteen following lines, with a shared 8,000-character source budget. Counts, samples, budget omissions, warnings and failures remain visible. Broad discovery remains indexed; selected evidence is read from disk. The adapter does not infer semantic callers or complete method bodies from text matches.

## Recovery and checks

The installer prints a recovery manifest. Close Visual Studio, review the manifest and restore its backed-up files. For a target whose backup is null, remove only that newly installed file after verifying it has not been edited since installation. Preserve intervening changes and unrelated MCP entries. Do not stop a shared tgrep server during rollback.

```powershell
node --test .\tests\test_mcp.mjs
python .\tests\test_mcp_install.py
```

The tests exercise the stdio handshake, real searches in isolated fixtures, current evidence, errors, scope, source limits and installation preservation. They do not certify Copilot's behavior. See [research and design rationale](direct-tool-research.md).
