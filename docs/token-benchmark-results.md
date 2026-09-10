# Copilot token benchmark — 10 September 2026

**Historical scope:** these measurements apply to 0.2.0-pilot at b6f6be5. The later 0.3.0 candidate addresses the observed overhead and adds guided setup; its token benefit has not been measured. The original dataset and findings below remain unchanged.

**The tested integration increased token usage. It did not demonstrate token savings.** Across two complete A/B repetitions, the skill condition used **1.90× as many exported model tokens (+89.54%)** as standard Copilot. This measures the 0.2.0 integration and workload, not tgrep's intrinsic search efficiency or billing.

## Scope and stopping point

The experiment ran in Visual Studio Enterprise **18.9.12112.369**, Copilot Agent / Autopilot, **GPT-5.6 Luna**, with **PowerShell 7.6.5 `-NoLogo -NoProfile`**. The source solution had **91 projects**, **7,389 eligible C# files** and **82,265,218 source bytes**. tgrep was **1.0.5**, ripgrep **15.2.0**, and the tested integration was [b6f6be5](https://github.com/pbrehmer-ai/copilot-tgrep-search/tree/b6f6be55dc041f55f75e9690b90eecf201720d87), version 0.2.0-pilot.

The plan called for 36 fresh-chat attempts plus an exploratory same-chat comparison. **The user requested an early finish during B3-T03.** That active attempt completed; no further Copilot tests ran. We retained **all 33 completed attempts**. The headline uses the **24 attempts in the first two complete, balanced repetitions**. Nine additional attempts are reported separately below. The same-chat comparison was not performed. Selection follows the completed blocks, not which runs were favorable.

A disabled only this integration and kept standard search tools available. B enabled the revised personal skill, helpers and preference, with an already ready server. Both used identical task prompts, shell, model, source and unrelated instructions. Copilot chose its own commands; the baseline was not forced to use ripgrep. The revised personal files were staged from the tested commit; this was **not another clean installer acceptance test**.

## Two complete repetitions

| Measurement | Standard A | Skill B |
| --- | ---: | ---: |
| Attempts | 12 | 12 |
| Correct answers | 12 | 11 |
| Input tokens, including cached input | 722,354 | 1,369,356 |
| Output tokens | 7,560 | 14,098 |
| **Input + output** | **729,914** | **1,383,454** |
| Cached input, already included above | 660,436 | 1,149,670 |
| Uncached input | 61,918 | 219,686 |
| Model calls | 59 | 89 |
| Tool calls | 39 | 69 |
| Median tokens per attempt | 59,554 | 106,227.5 |

`saving = 100 × (729914 - 1383454) / 729914 = -89.54%`

`standard / skill = 0.53`; equivalently, `skill / standard = 1.90`.

Uncached input also increased, by **254.80%**. This is not a cost estimate: the report does not model pricing, premium requests, credits or unobserved product activity. Reasoning-token breakdowns were absent and remain `null`. All exported model calls, repeated context, retries and Autopilot follow-ups are included. Cache is a subset of input and is not added again.

| Task, two attempts per condition | Standard tokens | Skill tokens | Skill overhead |
| --- | ---: | ---: | ---: |
| T01 — rare literal, count and alphabetical paths | 109,193 | 192,011 | +75.85% |
| T02 — frequent literal, count and alphabetical paths | 105,091 | 326,815 | +210.98% |
| T03 — three independent literals | 107,040 | 259,126 | +142.08% |
| T04 — declaration/use explanation with citations | 171,049 | 257,711 | +50.67% |
| T05 — verify current saved-file absence | 103,628 | 195,278 | +88.44% |
| T06 — one known file, literal absent | 133,913 | 152,513 | +13.89% |

B1-T04 failed quality because the explanation asserted a relationship between different configuration keys without supporting evidence. Excluding its A/B pair leaves 11 pairs where both answers passed: **636,793 vs 1,251,916 tokens**, or **96.60% more with the skill**. Removing that failure does not reverse the result.

## Additional attempts retained

Third-repetition T01–T03 completed for both conditions: **178,822 standard vs 429,683 skill tokens**, or **140.29% more with the skill**. Each condition passed two of three tasks. A3-T03 searched the solution working directory instead of the requested source root and returned incorrect counts. B3-T01 had the correct count but did not match the fixed alphabetical-path oracle; its commands performed no explicit sorting. Future prompts should specify the exact collation, since “alphabetical” alone leaves some ambiguity.

A3-T04, A3-T05 and A3-T06 also completed correctly, consuming **176,637 tokens** together. Their B counterparts were not run, so these three attempts have no comparative ratio. All counters and per-call records remain in the [sanitized dataset](../benchmarks/results/2026-09-10-tokens.json). Across all recorded attempts, A passed 17/18 and B passed 13/15; these unequal groups are not the headline comparison.

## What Copilot actually did

- The skill loaded automatically for broad searches. In the balanced B set it was read twice in nine attempts and three times in one; the two known-file tasks skipped it. Repeated file reads and subsequent model calls added overhead.
- Copilot frequently chose **`--no-index` / `-NoIndex`**, even though a server was ready. It also chose ripgrep in B2-T01. Review of the recorded search commands found **no demonstrated indexed search in this token experiment**. Status/version checks alone do not establish indexed use.
- The helper's `MaxPaths` limit is 1–1000. Copilot repeatedly requested 100000, then retried. It sometimes expected `.Queries` instead of `.Results` and reran searches to inspect the schema.
- Large filename outputs and repeated searches increased the material returned to subsequent model calls. Counts and a few paths could often have answered the task with less output.
- The standard condition also had retries and a scope mistake. Those attempts were retained under the same rules.

The traces support these observations but do not isolate a causal token cost for each individual design choice. This exact-count, saved-file workload frequently led to direct scans; it does not measure the potential of repeated indexed discovery in a long development session.

## Terminal finding and restoration

The earlier Developer Windows PowerShell 5.1 profile had a broken command-to-chat round trip, including without tgrep and under Autopilot. A temporary **PowerShell 7.6.5 `-NoLogo -NoProfile`** profile passed the minimal control and allowed these measured attempts to complete. This is an observed working configuration on this machine, not a proven root cause or universal fix. No execution policy or tool approval policy was changed by this benchmark.

After the final attempt, the original Visual Studio settings, personal skill and marked instructions were restored from checked backups. The original solution was reopened. Protected source-file hashes and the existing unrelated repository instructions remained unchanged; the three pre-existing saved modifications remained intact. The existing shared tgrep server was left running. No company source, private query strings, raw traces or chat transcripts are published here.

## Follow-up priorities

Keep the tested skill unchanged in this results update. A future revision should be separately benchmarked:

1. Shorten the initial skill and move optional detail into references loaded only when needed.
2. Show one valid helper invocation and a compact `.Results` schema, including valid `MaxPaths` values. Explain that `ReturnedPathCount` describes the full successful result while `Paths` may be truncated.
3. Provide counts and deterministic sorted samples without returning hundreds of paths. Sort before truncation when alphabetical output is required.
4. Clarify when to reuse the index for discovery and when current saved-file verification is required. Do not weaken decisive absence checks merely to improve a benchmark.
5. Reuse successful results within a turn and avoid repeated schema/status discovery. Retest actual indexed invocation, correctness and total model usage before claiming an improvement.

The earlier **4.16× warm search-engine speedup** remains a separate result. It cannot be translated into token savings or full Copilot productivity gains. Company-wide rollout remains unapproved pending integration improvements and representative acceptance testing.

See the [measurement protocol](../benchmarks/TOKEN_PROTOCOL.md), [parser](../benchmarks/extract_usage.py), [statistics script](../benchmarks/analyze_tokens.py) and [data](../benchmarks/results/2026-09-10-tokens.json). Two completed repetitions on one private corpus are a descriptive pilot; exact private prompts and source are withheld, so external readers can reproduce the arithmetic, not independently rerun this exact corpus.
