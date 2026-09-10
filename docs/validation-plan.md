# Validation and acceptance

## Current evidence

The later [token benchmark](token-benchmark-results.md) tested b6f6be5 under PowerShell 7.6.5 and collected 33 completed attempts before the user stopped further testing. Its two complete balanced repetitions showed token overhead, not savings. The same-chat follow-up and remaining three skill tasks were not run. This does not complete the installer or rollout matrix.

The original Windows x64 pilot tested integration commit b5dca25dad65161020a678adab7458e35e943c46. Installation, discovery and engine equivalence passed; complete Copilot execution failed. See [results](benchmark-results.md). The revised helper tests are separate from that corpus benchmark.

Run the local fixture checks from a company-approved PowerShell host with Git and the reviewed tgrep executable available:

```powershell
.\tests\Test-Helpers.ps1
.\scripts\Install.ps1 -WhatIf
```

The helper test creates an isolated temporary Git repository, starts a server only there, verifies it is reused, and stops that test server. It retains the fixture and exclusion backup for inspection. No company source tree is modified. Checks cover parsing, preview, initial readiness, local exclusion preservation/effectiveness, root boundaries, filename batches, filters, truncation, quoting, Unicode filenames, exit 1/2 handling, direct freshness and client timeout.

## Installer matrix still required for release

The original real installer passed on PowerShell 7.6.5 / x64. Validate the revised package's full clean install and upgrade, copied helpers, recovery record and unrelated-instruction/PATH preservation in a test account. Also exercise UTF-8/UTF-16, malformed markers, network/hash failure, permission failures, intervening edits, repeat install, repository-preparation failure after personal installation, and rollback. Validate Windows PowerShell 5.1 and ARM64 separately. Syntax compatibility is not runtime proof.

## Complete Copilot acceptance

Use the same model/mode, source revision, scope and answer requirements before and after setup.

| Scenario | Pass evidence |
| --- | --- |
| Minimal terminal control without tgrep | Correct version/directory in the final chat answer |
| Ordinary broad search without naming skill | Skill activation, real query and correct completed answer |
| First preparation, no existing index | Waits for initial readiness; no absence claim from partial data |
| Warm repeated searches | Same root/server, no repeated initialization/help/status loop |
| Nested solution in monorepo | Source root preserved; subtrees filtered with globs |
| Batched helper output | Counts, truncation, stderr and native exit codes interpreted correctly |
| Saved edits, generation, branch switch, decisive absence | Appropriate current saved-file verification |
| Unsaved buffers and semantic references | IDE/editor context and symbol-aware tools |
| Linked/outside-root project | Explicit authorized additional scope |
| Missing binary, stopped server, errors or blocked scripts | Useful bounded fallback, no silent false-negative result |
| Terminal completion/output failure | Stops retry loop and reports limitation; does not invent an answer |

Document any assisted continuation; it is not proof of autonomous setup or completion. A wrapper test cannot certify a model followed the skill.

## Performance reproduction

Use [benchmarks/measure.py](../benchmarks/README.md) for paired engine measurements. Record cold index cost separately, alternate tool order, retain outliers, validate complete path sets and report scope. Also measure full agent tasks once the terminal bridge works, recording manual approval time separately. Never relabel engine or algorithm-replay ratios as Copilot productivity multipliers.

## Release decision

Only mark a supported configuration ready after clean installation/upgrade, representative correctness cases and complete agent answers pass. Keep known failures and slower cases visible. Do not declare the remaining matrix complete from code review or a single happy-path fixture run.
