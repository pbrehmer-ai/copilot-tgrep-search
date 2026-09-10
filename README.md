# tgrep Search for GitHub Copilot

An experimental integration for repeated code searches in large Visual Studio solutions, using [Microsoft tgrep](https://github.com/microsoft/tgrep), a reusable Copilot skill, and a local index.

**Token benchmark: no savings demonstrated.** In 24 attempts across two complete A/B repetitions, the current skill used **1.90× as many model tokens (+89.54%)** as standard Copilot. Nine additional attempts are retained separately. Copilot often bypassed the index and retried helper calls. See [token results and follow-up priorities](docs/token-benchmark-results.md).

**Measured search-engine benefit: 4.16× faster than ripgrep** across 56 warm searches per tool on a real 7,389-file C# workload, with identical result sets. The median-based aggregate was 8.74×. **These are not full Copilot answer speedups.** The pilot verified automatic skill loading and tgrep execution, but Visual Studio's terminal output/completion channel stalled even under Autopilot and without tgrep. See [results and limitations](docs/benchmark-results.md).

**Status: experimental pilot, not approved for company-wide rollout.** A later PowerShell 7 profile allowed complete Copilot attempts, but the token comparison exposed overhead and correctness failures. Installation, engine behavior, helper checks and complete agent behavior remain separate acceptance gates.

## Start here

You need Windows, Visual Studio 2026 **18.5+**, Copilot **Agent** mode with terminal access, Git for cloning, and a company-approved PowerShell host. The installer targets x64/ARM64 and PowerShell 5.1+; the real installer pilot ran in **PowerShell 7.6.5 on x64**. ARM64 and unrestricted 5.1 execution have not been validated. No administrator rights are needed.

### 1. Install once for your Windows user

Clone this repository or download and extract its ZIP. Private-repository access is required.

```powershell
git clone https://github.com/pbrehmer-ai/copilot-tgrep-search.git
Set-Location -LiteralPath '.\copilot-tgrep-search'
.\scripts\Install.ps1 -WhatIf
.\scripts\Install.ps1 -RepositoryRoot 'C:\repos\YourRepository'
```

Replace the root with your **source repository**, which may be above the folder containing the open .sln/.slnx. The optional `-RepositoryRoot` performs the next step immediately. To install only personal files, omit it. `-WhatIf` makes no changes or downloads.

If scripts or downloads are blocked, use [manual/IT setup](docs/manual-setup.md); do not change execution policy. The installer backs up replaced files, verifies the pinned Microsoft download, and preserves unrelated personal instructions and PATH entries. It does not change Visual Studio settings or tool approvals.

### 2. Prepare each repository for repeated searches

Skip this immediately after successful installation with `-RepositoryRoot`. For another repository or after the server has stopped, run:

```powershell
.\scripts\Start-Repository.ps1 -Root 'C:\repos\YourRepository'
```

Wait for **READY**. This starts or reuses a hidden local tgrep server, excludes the root-local .tgrep/ from Git through .git/info/exclude when necessary, and waits for initial indexing. It backs up the previous exclude file. Default timeout: 120 seconds; use `-TimeoutSeconds 600` for a larger first build. A timeout leaves the server running and requires checking status, not reinstalling.

The server is reused across queries and remains running after the script exits. No scheduled task or automatic login service is installed. Indexing consumes disk/memory and has an upfront cost; use ordinary IDE/ripgrep search for small one-off scans. Initial completion does not guarantee freshness after edits. Existing custom index locations/options require the [manual workflow](docs/manual-setup.md#custom-index-workflows).

### 3. Restart Visual Studio and check one complete round trip

Completely restart Visual Studio to receive the new user PATH. Open your solution, select **Copilot Chat → Agent**, and enable custom instructions in Options. Finish any terminal initialization or publisher prompts through your normal company process. A personal skill may need outside-workspace read permission.

First ask Copilot:

> Using your terminal tool, report the actual PowerShell version and current working directory. Do not edit files or change settings.

**Continue only when Copilot returns the result in chat.** Output visible only in the terminal is not a pass. If it hangs, follow [terminal troubleshooting](docs/troubleshooting.md); Autopilot is optional and did not solve the pilot's output-delivery failure.

Then ask normally, without needing to mention tgrep:

> Find the C# files implementing order validation and invoice creation. Reuse the existing repository search server, exclude bin and obj, and explain the relevant entry points. Do not edit files.

Check that Copilot loads tgrep-search, performs actual searches and completes its answer. You can explicitly request **“Use the tgrep-search skill”** if discovery does not occur. Do not add skill files to a project or solution file.

## What is installed?

| Location | Purpose |
| --- | --- |
| %LOCALAPPDATA%\Programs\copilot-tgrep\1.0.5\tgrep.exe | Pinned Microsoft executable with verified archive digest |
| User PATH | Makes it available to newly launched applications |
| %USERPROFILE%\.copilot\skills\tgrep-search\ | SKILL.md, three helper scripts and third-party notice |
| %USERPROFILE%\copilot-instructions.md | One marked search-preference section; other content retained |
| %LOCALAPPDATA%\copilot-tgrep-search\backups\ | Installer recovery records and prior files |
| <source-root>\.tgrep\ | Local index/server metadata, only after repository preparation |
| %LOCALAPPDATA%\copilot-tgrep-search\repository-backups\ | Prior local Git exclude files when setup adds an exclusion |

Employees run setup; they do not maintain several instructions manually. The short preference loads the skill when useful. Scripts handle repetitive setup/error capture, while direct tgrep calls remain available for low-overhead single searches and file inspection. No MCP integration or Visual Studio extension is added.

## Work efficiently

- Reuse one ready server for repeated broad searches; keep the positional root fixed and narrow with globs.
- Batch independent discovery queries, return a few candidate paths, then inspect those files. Avoid status/help calls before every query.
- Use IDE tools for semantic references and unsaved editor buffers. Use current saved-file scans for decisive absence checks or after changes.
- Preserve stderr and exit codes. Stop terminal retry loops; installation does not prove the terminal bridge works.
- Direct tgrep scans were **3.54× slower than ripgrep** in this workload. The index provides the measured benefit.

## Documentation

| Need | Read |
| --- | --- |
| Measurements, method and caveats | [Benchmark results](docs/benchmark-results.md) |
| Actual Copilot tokens and observed overhead | [Token benchmark](docs/token-benchmark-results.md), [protocol](benchmarks/TOKEN_PROTOCOL.md) |
| Diagnose setup or a stuck Copilot terminal | [Troubleshooting](docs/troubleshooting.md) |
| Exact agent behavior | [Skill](.github/skills/tgrep-search/SKILL.md), [default instruction](instructions/copilot-tgrep.md) |
| Manual install, update, rollback | [Manual setup](docs/manual-setup.md) |
| Employee distribution and acceptance gates | [Team rollout](docs/team-rollout.md) |
| Architecture and official sources | [Design](docs/design.md) |
| Reproduce checks and remaining validation | [Validation](docs/validation-plan.md) |
| Changes since the original pilot | [Changelog](CHANGELOG.md) |

This is an independent team integration, not an official Microsoft Visual Studio extension. See [third-party notices](THIRD_PARTY_NOTICES.md).
