# tgrep Search for GitHub Copilot

Help GitHub Copilot spend less time scanning large repositories in Visual Studio.

This repository packages [Microsoft tgrep](https://github.com/microsoft/tgrep) as a reusable Agent Skill, with a short default search instruction and a Windows setup script. It is designed to speed up repeated text searches by reusing a trigram index and a local search server. Visual Studio's symbol navigation and editor tools remain available for tasks that need them.

**Status: initial draft for review.** The skill, setup script, and onboarding instructions have been authored. Installer execution, Copilot behavior, and performance testing are the next stage; they have not been validated yet. No measured Visual Studio speedup is claimed.

## Quick start

You need **Windows x64 or ARM64**, **Visual Studio 2026 18.5+**, GitHub Copilot access, and permission to use Agent mode and its terminal tool. Setup uses Windows PowerShell 5.1+ and downloads the pinned tgrep release from GitHub. It does not need administrator rights.

### 1. Get this repository

Clone it with Git or use **Code → Download ZIP** and extract it. If the repository is private, sign in with an account that has access.

```powershell
git clone https://github.com/pbrehmer-ai/copilot-tgrep-search.git
Set-Location -LiteralPath '.\copilot-tgrep-search'
```

### 2. Run the setup from this repository

Review [what setup changes](#what-setup-changes), then run:

```powershell
.\scripts\Install.ps1
```

The intended outcome is one installation per Windows user, usable across their projects. If your company blocks unsigned scripts or direct downloads, use the [manual setup](docs/manual-setup.md) or ask IT to distribute the same files. Keep your existing execution and security policies.

### 3. Open your solution in Visual Studio

Restart Visual Studio after setup so its terminal receives the updated PATH. Open **Copilot Chat → Agent**. In **Tools → Options**, search for **custom instructions** and ensure loading custom instructions is enabled. Allow the terminal tool according to your team's normal approval settings.

Ask for your normal work, for example:

> Find where the application reads its connection strings and explain which configuration wins.

The default instruction directs Copilot to the skill for suitable repository text searches. A skill activation appears in chat; terminal calls show whether tgrep is actually used. You can also explicitly say, **“Use the tgrep-search skill for this repository search.”**

## What setup changes

| Location | Purpose |
| --- | --- |
| `%LOCALAPPDATA%\Programs\copilot-tgrep\1.0.5\tgrep.exe` | Pinned Microsoft tgrep executable; the download is checked against a recorded SHA-256 digest. |
| User `PATH` | Makes that executable available to new processes. Existing entries are preserved. |
| `%USERPROFILE%\.copilot\skills\tgrep-search\SKILL.md` | The self-contained search skill. |
| `%USERPROFILE%\.copilot\skills\tgrep-search\THIRD_PARTY_NOTICES.md` | Microsoft attribution and license notice. |
| `%USERPROFILE%\copilot-instructions.md` | A marked tgrep section; unrelated instructions are preserved. |
| `%LOCALAPPDATA%\copilot-tgrep-search\backups\…` | Recovery information and backups of replaced files. |

Setup does not start a server, build an index, change Visual Studio settings, or grant tool permissions. Copilot handles appropriate per-repository search setup later under the skill's rules. Repository indexes stay local and must be excluded from commits.

The installer is supplied for the next pilot stage and has not been executed as part of this initial publication. [Review its source](scripts/Install.ps1) or preview its planned changes with `-WhatIf` during that stage.

## What this improves

tgrep can avoid rereading most files on repeated, selective searches of large source trees. This skill helps Copilot preserve that benefit by choosing the correct root, reusing the server, narrowing queries, and returning manageable results. It also explains when an index is too stale to support a conclusion.

It does not make every Copilot action faster. Index creation has an upfront cost; a small search may be cheaper with existing tools. Microsoft's published benchmarks compare tgrep with ripgrep, not this skill with Visual Studio's built-in search. See [design and evidence](docs/design.md).

## Find what you need

| You want to… | Read |
| --- | --- |
| Inspect the exact instructions Copilot receives | [SKILL.md](.github/skills/tgrep-search/SKILL.md) and [default instruction](instructions/copilot-tgrep.md) |
| Install without the setup script, update, or remove it | [Manual setup](docs/manual-setup.md) |
| Distribute it to a team | [Team rollout](docs/team-rollout.md) |
| Understand the choices and Microsoft sources | [Design and evidence](docs/design.md) |
| See what must be tested next | [Validation plan](docs/validation-plan.md) |

This is a team integration built from Microsoft's documentation, not an official Microsoft Visual Studio tgrep extension. Upstream attribution is recorded in [third-party notices](THIRD_PARTY_NOTICES.md).
