# Copilot optimization results — 10 September 2026

**The final held-out pair used 6.57% more exported model tokens and completed with a 1.14x workflow speed ratio (ripgrep time / tgrep time).** The predeclared target of at least 20% fewer tokens, correct answers and no workflow slowdown was not met. This is two tasks with one attempt per variant, not a general performance guarantee.

The final tgrep workflow used **129,630 tokens in 40.177 seconds**, compared with **121,635 tokens in 45.815 seconds** for ripgrep. Both answers in each variant were correct. The implementation is an efficiency experiment with useful bounded-output features, not a demonstrated token-saving release.

## Results by stage

| Stage | ripgrep tokens | tgrep tokens | Token reduction | Workflow speed ratio | Correct answers A/B |
| --- | ---: | ---: | ---: | ---: | --- |
| 0.3.0 development | 154,956 | 180,364 | -16.40% | 1.10x | 2/2 · 1/2 |
| 0.4.0 development | 137,684 | 131,621 | 4.40% | 1.13x | 2/2 · 2/2 |
| 0.4.1 held-out | 121,635 | 129,630 | -6.57% | 1.14x | 2/2 · 2/2 |

A negative reduction means increased tokens; a speed ratio below 1 means a slower candidate. Do not pool the intermediate and final versions into one claimed final treatment.

## All twelve attempts

| Variant | Task | Input | Output | Cache subset | Model calls | Tool calls | Workflow seconds | Quality |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| A | D1 | 62,565 | 1,080 | 48,043 | 5 | 3 | 25.225 | Pass |
| A | D2 | 90,352 | 959 | 82,495 | 7 | 8 | 24.499 | Pass |
| B03 | D1 | 63,801 | 532 | 49,035 | 5 | 3 | 18.425 | Pass |
| B03 | D2 | 114,697 | 1,334 | 95,259 | 7 | 8 | 26.789 | Fail |
| A2 | D1 | 59,759 | 1,171 | 57,603 | 5 | 3 | 24.300 | Pass |
| A2 | D2 | 75,812 | 942 | 71,581 | 6 | 7 | 22.964 | Pass |
| B04 | D1 | 48,670 | 494 | 35,122 | 4 | 3 | 15.545 | Pass |
| B04 | D2 | 81,165 | 1,292 | 70,868 | 6 | 8 | 26.195 | Pass |
| B041 | H1 | 48,856 | 437 | 35,197 | 4 | 3 | 19.107 | Pass |
| B041 | H2 | 79,463 | 874 | 72,854 | 6 | 5 | 21.070 | Pass |
| A2 | H1 | 45,853 | 538 | 34,142 | 4 | 2 | 21.514 | Pass |
| A2 | H2 | 74,363 | 881 | 70,174 | 6 | 7 | 24.301 | Pass |

A/A2 are skill-disabled ripgrep workflows. B03 is 0.3.0 (`8399d28`), B04 is 0.4.0 (`f870332`), B041 is 0.4.1 (`676ce5a`). D1/D2 are development tasks; H1/H2 are different, held-out terms. D1/H1 ask for batched sorted candidate paths; D2/H2 ask for a declaration and direct caller explained from current source.

## What changed and what Copilot actually did

- 0.3.0 used indexed-eligible helper searches but still requested large file ranges. B03-D2 explained a downstream field use rather than the requested property reader; this failure remains in the totals.
- 0.4.0 added compact output and bounded current excerpts to the initial discovery call. The candidate-path task avoided an Autopilot reminder. The explanation was correct but still reread already supplied lines and parallel implementations.
- Before any held-out run, 0.4.1 clarified that excerpts already count as current reads, defaults should be retained until needed, and one requested example does not require inspecting parallel implementations. No extra development rerun was added. This is a documented adjustment to the staged protocol within its twelve-attempt cap.
- Both final tgrep attempts invoked the supplied compact helper with CheckReady. The explanation used IncludeContext and fewer get_file calls than the 0.4.0 development explanation, but still reread a caller excerpt and received an Autopilot completion reminder. Instructions improve the workflow without enforcing deterministic behavior.
- Skill-loading overhead remains. Compact output, fewer repeated reads and timely completion can benefit ripgrep integrations too: this is a package/workflow comparison, not intrinsic token compression by tgrep.

## Native speed check

A separate short warm check used three development query literals, one untimed warmup per engine/query, then three alternating-order repetitions. Matching file sets were identical. Summed per-query medians: ripgrep **611.525 ms**, tgrep **71.285 ms**; ratio **8.58x**. The raw timed samples are in the JSON.

This excludes index construction, helper processing, source excerpts and Copilot orchestration. It uses fewer/different searches than the historical 4.16x engine test; those factors are not directly interchangeable. The shared server was complete and watching. No fallback warnings or native errors were emitted. Actual helper invocation and readiness support indexed eligibility; the Copilot trace does not expose a per-query server-hit counter. Current excerpts deliberately read selected files directly.

## Method and limits

The same 91-project solution, 7,389 eligible saved C# files (82,265,218 bytes), model gpt-5.6-luna, Visual Studio 18.9.12112.369, tgrep 1.0.5 and ripgrep 15.2.0 were used. Both variants used the same temporary PowerShell 7.6.5 -NoLogo -NoProfile profile. Fresh chats retained the same editor context. Skills/preferences were switched between application restarts. Native results and line citations were checked locally; no source edits were made.

All exported chat spans in each UI-delimited attempt were deduplicated. Input includes cache reads; output includes any exported reasoning subset, so neither is added again. Missing reasoning counters remain null. Retry, tool-error and Autopilot calls remain included. These are exported model usage counters, not billed credits or unobserved product activity. Relative per-call offsets and token counters are included for recalculation.

Workflow seconds run from the first included chat span start through the last included chat/tool span end. They include orchestration and Autopilot, exclude human observation delays and solution startup, and are not pure search latency. Single attempts are sensitive to model choices, cache/server state and service latency. No confidence interval or universal multiplier is justified.

One ripgrep development attempt repaired a filename-encoding error. Baseline commands sometimes expressed directory exclusions as root globs; a separate file-set check found the same 7,389 eligible files as recursive exclusions on this corpus because existing ignores already excluded those directories. This does not make those spellings equivalent in other repositories.

The final implementation was frozen before the held-out tasks. The held-out examples are new terms in the same corpus and task families, not an independent repository or model. Raw prompts, source excerpts, absolute paths, trace identifiers and settings backups remain local. Historical data were not overwritten.

## Reproduce and use

### Validation and restoration

The isolated PowerShell helper fixture passed, including compact/full count equivalence, numbered current excerpts, the shared character limit, changed-file reads and preserved errors. All twelve Python unit tests passed, including comparison accounting and failure retention. These checks validate the helper and analyzer; they do not establish model compliance or a complete clean-install matrix.

After all twelve Copilot attempts, the original personal skill, personal preference and Visual Studio settings were restored and their four backed-up file hashes matched. The three pre-existing modified source files and the repository instruction file also retained their original hashes. Visual Studio was reopened with the original settings; the shared tgrep server was left running. Updating the local personal installation to this candidate requires running the supplied installer normally.

### Remaining optimization opportunity

The held-out workflows both made ten model calls in total, despite tgrep using one fewer tool call. A smaller result body alone therefore did not reduce total model usage. A future iteration should reduce skill-loading/context overhead and unnecessary model turns, including duplicate source reads and completion reminders. An equivalent compact ripgrep helper would be a useful additional control to separate packaging improvements from engine selection. No such additional experiment was run in this capped pilot, and the final skill was not changed after the held-out results.

### Recalculation

Recompute the published comparison without accessing private source:

```powershell
python benchmarks/analyze_optimization.py benchmarks/results/2026-09-10-optimization.json
```

For installation or updates, use [SETUP.md](../SETUP.md) and the supplied installer; restart Visual Studio and use a fresh chat. Candidate discovery should remain compact; explanation tasks should add IncludeContext and reuse current excerpts. Known files, semantic references, unsaved buffers and decisive current absence require their appropriate existing tools/freshness path.

[Sanitized data](../benchmarks/results/2026-09-10-optimization.json) · [Protocol](../benchmarks/optimization-protocol.md) · [Historical token report](token-benchmark-results.md) · [Historical engine report](benchmark-results.md)
