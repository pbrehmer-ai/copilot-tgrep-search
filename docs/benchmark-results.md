# Pilot results: 10 September 2026

## What was measured

A real Windows x64 source tree with **91 projects**, **7,389 eligible C# files** and **78.45 MiB** of C# content. The server indexed 14,562 eligible text files overall; the measured queries were restricted to C#. Visual Studio Enterprise 2026 executable version: **18.9.12112.369**. Copilot: **GPT-5.6 Luna**, initially Agent/Interactive and later Autopilot for diagnostics. tgrep: **1.0.5**; ripgrep: **15.2.0**.

The tested integration was commit **b5dca25dad65161020a678adab7458e35e943c46**, before this revision's new helpers. No benchmark here claims to measure the revised helper overhead or a completed Copilot workflow. This is one workload, not a universal large-monorepo guarantee.

## Paired warm searches

Eight case-sensitive literal queries; filename-only output; the same source root, C# glob, bin/obj/.git/.vs exclusions and 64 MiB maximum file size for both tools. Each query/tool had one warm-up, then seven measured repetitions with alternating tool order. The index was complete and reused, and Visual Studio was idle during the primary paired measurement. OS caches were not flushed. Timings include client process startup and captured output.

All complete result-path sets matched across measured repetitions. Every measured native exit code was 0 or 1, with empty stderr. Private query strings and result paths are replaced by stable IDs below.

| Query ID | Matching files | ripgrep median ms | Indexed tgrep median ms | Median ratio |
| --- | ---: | ---: | ---: | ---: |
| Q01 | 0 | 202.25 | 19.13 | 10.57× |
| Q02 | 0 | 208.03 | 19.22 | 10.82× |
| Q03 | 19 | 203.60 | 20.13 | 10.12× |
| Q04 | 508 | 216.50 | 27.98 | 7.74× |
| Q05 | 915 | 205.56 | 29.72 | 6.92× |
| Q06 | 921 | 205.35 | 28.19 | 7.29× |
| Q07 | 87 | 202.98 | 22.36 | 9.08× |
| Q08 | 150 | 206.04 | 22.03 | 9.35× |

| Aggregate | ripgrep | Indexed tgrep | Interpretation |
| --- | ---: | ---: | --- |
| Total, 56 measured searches/tool | 11,778.0771 ms | 2,834.0445 ms | **4.16×** total-time speedup |
| Mean latency | 210.32 ms | 50.61 ms | Includes all outliers |
| P95, nearest rank | 237.03 ms | 319.59 ms | tgrep's tail was worse in this sample |
| Sum of eight per-query medians | — | — | **8.74×** ratio of sums, not average of ratios |

The main ratio is `11,778.0771 / 2,834.0445 = 4.155925…`. Several tgrep calls took about 0.32–0.34 seconds. They were retained, explaining the lower all-run result compared with the median-based result. Do not present 8.74× as an all-run average or hide the P95 regression.

A separate paired **non-indexed** comparison, also seven repetitions with equal result sets, gave a median-sum ratio of **0.28×**: direct tgrep scans were **3.54 times slower than ripgrep**. Before any installation, the untouched ripgrep baseline had medians of approximately 195–209 ms.

The two negative indexed queries measure the engine only. A correct agent may need an additional direct scan before claiming absence; that cost is not included in the indexed number.

## Index cost

- Initial bootstrap: **32.1 seconds** in the server log, consistent with status polls bracketing completion at 31.49–32.51 seconds.
- Index: **208.63 MiB** at observation; 447,445 trigrams.
- Reported peak memory during bootstrap: **146.7 MiB**. Observed server private memory later: **101.82 MiB**.
- Native watcher active; later reconciliation observed. No deliberate watcher mutation test was included in this corpus benchmark.
- Approximate amortization: 32.1 seconds divided by the mean saving of 159.71 ms is **about 201 similar queries**, excluding agent overhead. Existing-index startup and different query mixes change this estimate.

The coordinator started the server separately to measure initialization. Copilot did not create it autonomously in the successful engine measurement.

## What happened inside Copilot

| Acceptance item | Observed result |
| --- | --- |
| Installer and pinned download verification | Passed in PowerShell 7.6.5 on Windows x64 |
| Original source/configuration preservation | Protected file hashes unchanged |
| Automatic skill discovery without naming tgrep | Passed in fresh chats |
| Actual tgrep invocation and correct source root | Observed |
| Complete repeated search answer after installation | **Failed acceptance in this VS configuration** |
| Autopilot resolves approval pauses | Observed; not sufficient for completion |
| Minimal control without tgrep | Same terminal completion/output-delivery failure |

Before installation, Copilot selected rg, found it unavailable in its terminal PATH, then successfully answered using PowerShell scans. After installation, Copilot automatically loaded the skill and ran tgrep. Terminal initialization first encountered a publisher prompt and PSReadLine error. Subsequent commands completed visibly but the tool stayed pending, including after IDE restarts.

An assisted indexed continuation printed results, but background retrieval repeatedly returned `running` and `0 total lines`. A fresh Autopilot control requesting only PowerShell version and working directory reproduced the failure without tgrep. This demonstrates that the symptom is not specific to tgrep; it does not establish the underlying cause.

Copilot also discarded stderr and omitted per-command exit checks in an observed generated command despite the original prose rules. The revised search helper addresses native error capture; it does not fix the terminal bridge.

Manual approvals, observation gaps and terminal failures invalidate a numerical comparison of full chat durations. **There is no measured complete-Copilot speedup.** A supplementary PowerShell-algorithm replay is omitted from headline claims because its host and timing phases were not equivalent to the VS baseline.

## Evidence and applicability

[Anonymized measured rows](../benchmarks/results/2026-09-10.json) retain all 112 primary timing records and counts. Private corpus paths, source, query text and chat transcripts remain local. Readers can recompute statistics, but cannot independently validate withheld path sets or rerun the proprietary corpus. See the [reproduction harness](../benchmarks/README.md) for testing another tree.

The new helpers passed local fixture tests separately in PowerShell 7.6.5: preparation/reuse, effective Git exclusion, root rejection, batched counts and truncation, quotes/backslashes, Unicode filenames, no-match/error handling, saved-file direct search and client timeout. These checks do not establish ARM64 compatibility, company-policy compatibility, or a successful revised Copilot run.

Proceed with controlled pilots. Require a healthy terminal round trip and complete indexed answer before recommending this setup company-wide.
