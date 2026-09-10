# Copilot token benchmark protocol

**Published pilot deviation:** the user stopped testing during B3-T03. That attempt completed, leaving 33 recorded attempts. The headline uses two complete repetitions (24 attempts); the third repetition's three complete pairs and three unmatched standard attempts are retained separately. The same-chat follow-up below describes the planned method and was not executed. The result file declares `completed_repetitions: 2`; the analyzer requires every task in those complete blocks.

Measure complete Copilot attempts with and without this integration. Faster search execution does not by itself reduce model tokens. Do not assume a positive result.

## Freeze the comparison

Record the Visual Studio build, model, Agent/Autopilot mode, shell profile, source revision and saved-file state, eligible file count, tool versions and integration commit. Keep unrelated instructions, editor context and available standard search tools identical. Keep private source details in local files excluded from Git.

Use two conditions:

- **A — standard:** disable only this integration's skill and marked preference, and remove its executable from the test process PATH. Keep the ordinary search tools available. Copilot chooses its own search strategy.
- **B — integration:** enable the pinned skill, helpers and preference, and provide a ready repository server. Copilot chooses its strategy without being told to use a particular command in each task.

Restart Visual Studio between condition changes and use a fresh chat for each primary attempt. Do not change the tested integration during the experiment. An installed skill does not prove it was loaded, and a status call does not prove an indexed search occurred.

First verify a healthy terminal round trip: request the shell version and working directory, and require the answer to reach chat. Keep this control and any failed setup experiments outside the primary dataset. Apply the same working shell configuration to both conditions.

## Workload and order

Choose six read-only tasks and establish their answers independently before testing:

| ID | Task | Acceptance |
| --- | --- | --- |
| T01 | Rare literal, count and first three alphabetical paths | Exact count and paths |
| T02 | Frequent literal, count and first three alphabetical paths | Exact count and paths |
| T03 | Three independent literals, counts and two example paths each | All counts and examples correct |
| T04 | Explain a declaration/use relationship across two source files | Relationship supported by inspected code and accurate line citations |
| T05 | Verify absence in current saved source | Correct zero result, complete requested scope and current-file verification |
| T06 | Search one already known file | Correct occurrences or absence; no repository-wide discovery |

Fix case sensitivity, literal semantics, root and excluded directories in identical A/B prompts. In the published pilot, T06's literal was absent. This was not a positive known-file lookup test. Tasks requested short answers and prohibited editing, builds, installation, settings changes and disclosure of configuration values.

Run each task three times per condition: **36 fresh-chat attempts**. The pilot's fixed block order was A1, B1, B2, A2, A3, B3. This partly balances order but is not randomized and cannot eliminate time or cache effects. Retain failed attempts and retries; do not replace them with more favorable runs.

An exploratory follow-up uses T01, T02 and T03 sequentially in one fresh chat per condition. Report those six turns separately. One session per condition cannot establish a stable long-session effect.

## Collect actual telemetry

The tested Visual Studio installation exported local OTLP JSONL traces beneath `%TEMP%\VSGitHubCopilotLogs\traces`. Availability and schemas may differ across versions; verify locally before measuring. Do not infer tokens from characters, UI context percentages, request quotas or elapsed time.

For each attempt, record a start immediately before sending the prompt and an end after the answer and all Autopilot follow-ups finish. Keep the application otherwise idle. Inspect exported model and tool calls within those boundaries. A call that finishes after the recorded end invalidates that boundary. Check that no unrelated chat ran concurrently and no model call straddled the start. Review the trace against the visible tool sequence.

`extract_usage.py` reads the trace files, deduplicates `(traceId, spanId)`, rejects conflicting duplicates and ignores enclosing `invoke_agent` aggregates. It includes only per-model `chat` and `execute_tool` spans. Strict extraction rejects malformed records. `--allow-partial` is for provisional inspection while a writer is active, never final publication.

```powershell
python .\benchmarks\extract_usage.py --traces '<local-trace-directory>' --since <start-unix-seconds> --until <end-unix-seconds> --out '.\run.private.json'
```

The output excludes prompts, source and tool bodies, but still contains absolute timestamps. Keep it private until separately reviewed and sanitized. The published pilot data further removes timestamps and keeps only ordinal call order, counters, generic tool names and coarse search evidence flags. `tgrep_command` is a lexical substring check: it can match a helper, status command or even query text. It is not proof of execution or an indexed-search classifier. The report's actual-use findings require local command review.

## Count and interpret

Primary metric: sum **input tokens + output tokens across every exported model call in each attempt**, including repeated context, retries, skill reads and Autopilot follow-ups. These are model usage counters, not unique source tokens, billed tokens or all unobserved Copilot activity.

Cached input is already included in input. Report it separately without adding it twice. Derive uncached input as `input - cached input`; this is still not a bill. Reasoning, where provided, is a subset of output. Missing counters remain `null`, never zero. See the [OpenTelemetry GenAI attribute definitions](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/).

For totals A and B:

- Token saving: `100 × (A - B) / A` percent. Negative means increased usage.
- Standard-to-skill token ratio: `A / B`. Values below one mean the skill used more tokens.
- Skill overhead factor: `B / A`.

Report input, output, cached and uncached input, model/tool calls and correctness alongside totals. Publish all-attempt results first, then per-task results and pairs where both variants passed. Three repetitions are a descriptive pilot, not evidence of statistical significance or applicability to every monolith. The workload's exact-count and freshness requirements may favor scans over index discovery.

Recompute the published primary statistics with:

```powershell
python .\benchmarks\analyze_tokens.py .\benchmarks\results\2026-09-10-tokens.json
python -m unittest discover -s tests -p 'test_*.py'
```

Before publishing, restore test-only settings and personal files, verify protected source hashes and Git status, and inspect the entire staged diff for private queries, paths, source, tokens, identifiers and transcripts. Keep the tested commit explicit. Document observed improvements as follow-up hypotheses until a new controlled benchmark validates them.
