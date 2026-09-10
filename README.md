# tgrep Search for GitHub Copilot

Use Microsoft tgrep for repeated code discovery in large **Visual Studio** solutions. One personal installation provides the skill, compact search helper and default preference across your projects.

**0.3.0-pilot: ready for your next-machine trial.** This revision addresses observed Copilot retries and excessive output. Helper checks pass; its end-to-end Copilot behavior and token benefit have not yet been measured. The previous revision used **89.54% more tokens** in the balanced pilot. Keep that [result](docs/token-benchmark-results.md) separate from this new candidate and the earlier [4.16× warm engine speedup](docs/benchmark-results.md).

## Easiest setup: give Copilot this task

Open your solution in **Visual Studio 2026 18.5+**, select **Copilot Chat → Agent**, and paste:

> Set up https://github.com/pbrehmer-ai/copilot-tgrep-search for the source repository of my open Visual Studio solution. Read SETUP.md and follow it using the supplied installer. Preserve my existing instructions, prepare the index, verify setup, and tell me the next action.

Copilot should clone the package outside your source tree, download the pinned Microsoft executable, install the complete personal skill and short preference, then start/reuse the source repository's index. It should use the existing scripts rather than write a new skill from scratch.

**You need read access to this private repository, Git and a working approved PowerShell terminal.** Sign in through the normal GitHub/Git flow if prompted. A plain URL is not an automatic skill-install command: the explicit request above tells Copilot what to do. If it cannot retrieve the private repo, clone or download its ZIP yourself and point Copilot to the local SETUP.md. Do not paste access tokens into chat.

At the end, **restart Visual Studio once** and use a fresh Agent chat. Resolve any actual terminal/skill permission prompts through your normal company process. A PowerShell 7 profile with `-NoLogo -NoProfile` worked in the pilot; the installer does not modify VS settings or execution policies. A terminal that prints output but never returns it to chat needs [troubleshooting](docs/troubleshooting.md) first.

## Manual alternative: one installer command

Clone or extract this repository, open an approved PowerShell host in its folder, and run:

```powershell
.\scripts\Install.ps1 -RepositoryRoot 'C:\repos\YourRepository'
```

Use the **source root**, which may be above the open solution folder. Add `-WhatIf` to preview without changes/downloads. Wait for READY, then run:

```powershell
.\scripts\Check-Setup.ps1 -Root 'C:\repos\YourRepository'
```

The read-only check compares the installed files with this checkout, verifies the pinned executable version and initial server readiness. It cannot prove that Copilot will select the skill. See [SETUP.md](SETUP.md) for the full agent-executable workflow, private-repo fallback and timeout handling.

## First use after restarting Visual Studio

> Use the tgrep-search skill to find the main application entry points in this solution's source repository. Reuse the prepared index, return at most three candidate paths, and explain one entry point from its current file. Do not edit files.

Check that the skill activates, an actual search result reaches chat and Copilot finishes the answer. Afterwards, ask normal code questions; the short preference should select the skill for broad discovery. Known-file reads and semantic references can correctly use IDE tools instead. Do not add skill files to a .csproj or .sln.

For another repository, or after its server has stopped, run the installed helper:

```powershell
& "$env:USERPROFILE\.copilot\skills\tgrep-search\scripts\Start-Repository.ps1" -Root 'C:\repos\AnotherRepository'
```

One server is reused per source root. No login service or scheduled task is installed. Initial indexing has a disk/memory and time cost; ordinary IDE/ripgrep search remains appropriate for small one-off scans. The helpers use the pinned executable's absolute path, so their calls do not depend on PATH propagation.

## What changed for 0.3.0

- A short skill entry point and preference; advanced rules load only when needed.
- Full matching-file counts plus five sample paths by default; zero paths for counts only.
- Deterministic sorting before sampling and compact JSON with an explicit Results schema.
- Optional first-call readiness check combined with the query; reuse readiness afterwards.
- Oversized sample requests capped at 1000 instead of triggering the observed retry.
- Indexed discovery distinguished from current exhaustive checks; no blanket no-index rule for saved source.
- One setup task and a read-only installed-package check. No automatic VS profile or permission changes.

## Installed locations

| Location | Content |
| --- | --- |
| `%LOCALAPPDATA%\Programs\copilot-tgrep\1.0.5\` | Official executable from a checksum-verified archive |
| `%USERPROFILE%\.copilot\skills\tgrep-search\` | SKILL.md, three scripts, advanced reference and notice |
| `%USERPROFILE%\copilot-instructions.md` | One marked preference; unrelated content preserved |
| `%LOCALAPPDATA%\copilot-tgrep-search\backups\` | Recovery manifest and replaced files |
| `<source-root>\.tgrep\` | Index/server metadata, excluded locally from Git when needed |

The installer updates user PATH and records its previous value. Index preparation preserves unrelated local Git exclusions. It does not change project files, save editor buffers, require administrator rights or install an extension/MCP server. Windows x64 was exercised; ARM64 and the complete company-specific installation matrix remain to be validated.

## Documentation

[Agent setup](SETUP.md) · [Manual setup and rollback](docs/manual-setup.md) · [Troubleshooting](docs/troubleshooting.md) · [Team rollout](docs/team-rollout.md) · [Validation](docs/validation-plan.md) · [Token results](docs/token-benchmark-results.md) · [Engine results](docs/benchmark-results.md) · [Design](docs/design.md) · [Changelog](CHANGELOG.md)

This is an independent integration using [Microsoft tgrep](https://github.com/microsoft/tgrep), not an official Visual Studio extension. Microsoft documents [personal Copilot skills](https://learn.microsoft.com/en-us/visualstudio/ide/copilot-agent-skills?view=visualstudio) and [user-level preferences](https://learn.microsoft.com/en-us/visualstudio/ide/copilot-chat-context?view=visualstudio). See [third-party notices](THIRD_PARTY_NOTICES.md).
