# Copilot setup task — Windows / Visual Studio

Use this file when the user explicitly asks to install this integration. This is the setup workflow, not an instruction to install software during ordinary code searches. Use the supplied scripts; do not regenerate the skill, helpers or instructions from a summary.

## What the user needs

Visual Studio 2026 **18.5+**, Copilot **Agent** mode with a working terminal tool, Git, and read access to this private GitHub repository. A company-approved **PowerShell 7** host is recommended because it completed the pilot's terminal round trip; 5.1 can be used if it works in the target environment. Installing the skill does not grant GitHub access or tool permissions.

A bare GitHub URL is not a skill installer. The user can paste this task into Copilot:

> Set up https://github.com/pbrehmer-ai/copilot-tgrep-search for the source repository of my open Visual Studio solution. Clone it outside my source tree, read SETUP.md and follow it. Use the supplied installer, preserve my existing instructions, and prepare the repository index. Check the installation and tell me the one next action I need to take.

## Execute setup

1. **Identify the source root.** Use the open solution's path and `git -C '<solution-directory>' rev-parse --show-toplevel`. Confirm it matches the user's intended source tree. If the solution is outside Git, use its explicitly identified source directory. Do not index a whole drive or the integration checkout. Resolve ambiguity before writing an index.
2. **Check the terminal round trip before installation.** Through the terminal tool, report the actual PowerShell version and working directory. Require output to return to chat. If the command visibly finishes but your tool keeps waiting, stop after one bounded retrieval. Tell the user to select a company-approved PowerShell 7 terminal profile with `-NoLogo -NoProfile` in Visual Studio and retest. Do not silently edit VS settings, install a shell, bypass execution policy or treat Autopilot as a fix. A blocked terminal requires this small manual/IT step first.
3. **Obtain this package.** Clone with the existing authenticated Git tooling to `%LOCALAPPDATA%\copilot-tgrep-search\package`. Create its parent if needed. If that path already exists, check its Git origin and status; reuse a matching clean checkout. Update only by fast-forward, preserving local edits. For an unrelated/non-Git directory, use a new sibling directory rather than overwrite it. Authentication is handled by the user/normal Git credential flow; never request a token in chat. If access is unavailable, the user can download/extract the private repository ZIP and give you its local folder.

```powershell
git clone https://github.com/pbrehmer-ai/copilot-tgrep-search.git "$env:LOCALAPPDATA\copilot-tgrep-search\package"
```

4. **Read the local SETUP.md and preview the installer.** Record the checkout commit with `git rev-parse HEAD`. Set the terminal working directory to that checkout explicitly. Read `scripts/Install.ps1` if tool policy requires code review, then run the preview. Continue with the already authorized installation when the preview matches the identified root; do not invent another approval step. Respect any actual tool approval or company policy.

```powershell
.\scripts\Install.ps1 -RepositoryRoot '<absolute-source-root>' -WhatIf
.\scripts\Install.ps1 -RepositoryRoot '<absolute-source-root>'
```

The installer downloads **Microsoft tgrep 1.0.5**, verifies the pinned archive digest, installs the complete personal skill package and a marked preference, preserves unrelated instructions and PATH entries, and records backups. It then starts or reuses the source root's server, excludes `.tgrep/` through local Git configuration when needed, and waits for initial indexing. It does not save editor buffers, alter source projects, create a service, change Visual Studio settings or grant tool permissions.

For scripts blocked in the current host, use the company's existing approved PowerShell host or [manual/IT setup](docs/manual-setup.md). Do not download and pipe scripts into execution, or bypass policy. If Git is unavailable, use the extracted ZIP route. Avoid reinstall loops: an index timeout is a repository-preparation issue, not a failed executable download. Check status and, if appropriate, extend preparation with `scripts/Start-Repository.ps1 -Root '<root>' -TimeoutSeconds 600`.

5. **Verify installed files and readiness.** From the same checkout:

```powershell
.\scripts\Check-Setup.ps1 -Root '<absolute-source-root>'
```

Exit 0 means the installed package matches this checkout, the pinned version responds, and initial server readiness is reported. Exit 2 gives missing/mismatched files or an unready server. It is a read-only check; it does not establish Copilot activation or freshness. Resolve the specific issue instead of recreating files manually. Do not stop a shared server.

6. **Give a short handoff.** Report the installed commit/version, source root, check result and printed recovery directory. Ask the user to **restart Visual Studio once**, keep the original solution open, and use a fresh Agent chat with the check below. Do not close unsaved work automatically. Most installation work is complete at this point; restart and any product/security prompts remain user actions.

## After the restart

Use this short prompt in a fresh Copilot Agent chat:

> Use the tgrep-search skill to find the main application entry points in this solution's source repository. Reuse the prepared index, return at most three candidate paths, then explain one relevant entry point from its current file. Do not edit files.

Require the skill to appear, an actual search result to reach chat, and the answer to complete. The helper's `index-eligible` field describes its requested mode; inspect fallback warnings before claiming indexed execution. Do not add `-NoIndex` solely because discovery concerns saved source. Final absence claims or explicitly current exhaustive checks still need appropriate current-file verification.

The short preference should also discover the skill for ordinary broad searches. A known-file or semantic task may correctly use IDE tools instead. No `.csproj`/`.sln` edits or special Copilot extension are needed. Microsoft documents [personal skill discovery](https://learn.microsoft.com/en-us/visualstudio/ide/copilot-agent-skills?view=visualstudio) and [user preferences](https://learn.microsoft.com/en-us/visualstudio/ide/copilot-chat-context?view=visualstudio).

**Version 0.3.0-pilot is ready for the next-machine evaluation, not a company-wide performance guarantee.** Its helper checks are separate from full Copilot validation. The previous version increased token usage; that historical result remains in [the token report](docs/token-benchmark-results.md). No new lengthy benchmark is required to install or try this package.
