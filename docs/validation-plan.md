# Validation plan — next stage

**Not executed.** This initial repository contains authored instructions and setup code. No installer run, Copilot integration trial, or performance benchmark has been performed. This document is the handoff for the next stage, not a record of passing checks.

## Setup and recovery

- Exercise the installer on supported Windows x64 and ARM64 environments, with Windows PowerShell 5.1 and PowerShell 7 where available.
- Verify a clean installation, an existing skill, an existing instruction file with unrelated content, and a repeated installation.
- Check UTF-8/UTF-16 instruction files, exact marker replacement, malformed/duplicate markers, Unicode paths, and paths containing spaces.
- Confirm archive digest mismatch and network failure stop with a clear error; examine the filesystem after partial failures.
- Confirm `-WhatIf` performs no downloads or writes, and no setup action weakens script or tool policies.
- Confirm user PATH changes preserve other entries and newly launched Visual Studio finds the intended executable.
- Confirm the recovery manifest and backups allow a controlled rollback while preserving changes made after installation.

## Copilot behavior in real solutions

| Scenario | Evidence to collect |
| --- | --- |
| Ordinary broad search, without mentioning tgrep | Skill activation and actual tgrep terminal calls. |
| Repository with no index | Correct first-run behavior, time to readiness, and no unsupported absence claim. |
| Existing warm server | Reuse without redundant startup/status calls before every query. |
| Nested solution in a monorepo | Correct root and glob scope; no accidental fallback to a subdirectory index. |
| Linked project or file outside the main root | Explicit authorized scope and accurate explanation of what was searched. |
| Recently saved edit, generated file, branch switch | Relevant direct-scan verification when freshness matters. |
| Unsaved editor change | IDE/editor context; no claim that tgrep read unsaved data. |
| Semantic references and overloads | Use of symbol-aware IDE tools. |
| Hidden/ignored/large file requested | Correct admission flags and scope disclosure. |
| Missing binary, stopped server, unsupported option | Clear fallback and useful answer. |
| Large result set | Scope/output reduction without treating truncation as exhaustive. |

Compare important search results with a current direct scan under equivalent filters. Investigate differences instead of assuming either tool's default file set is identical.

## Measure useful speed

Use representative employee tasks on the same machine and saved source revision. Record the Visual Studio build, Copilot model, repository size, tgrep version, query scope, and whether the server/index is cold or warm.

Measure separately:

1. Initial installation and index creation.
2. Repeated warm searches and the amount of returned text.
3. Complete Copilot tasks with and without the integration, including tool/model round trips and verification work.

Repeat comparable trials, keep output scopes equivalent, and report variability. Check correctness before claiming a speed improvement. Include cases where tgrep does not win and where startup costs dominate.

## Before broad rollout

Record results against the repository commit used for the pilot. Resolve material correctness or setup problems, agree on supported environments, establish employee access and package ownership, and replace the draft status only when the evidence supports it. Do not mark this checklist as complete based solely on source review.
