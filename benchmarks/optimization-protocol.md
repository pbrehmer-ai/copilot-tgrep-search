# Copilot workflow optimization pilot

This small follow-up compares an explicitly requested ripgrep workflow with the installed tgrep skill in Visual Studio Copilot. It does not treat the earlier 4.16x warm-engine result as whole-task acceleration.

## Frozen design

- One saved C# monolith, one source revision, the same model and PowerShell terminal profile, fresh chats and unchanged editor context.
- Two development tasks: batched candidate-path discovery and declaration/caller explanation with current line citations.
- Run both tasks with ripgrep and version 0.3.0 (four attempts).
- If needed, revise the generic integration using those observations and compare both development tasks again (four attempts).
- Freeze the implementation, then evaluate two held-out tasks of the same categories with different search terms (four attempts). Do not tune to their results.
- Maximum twelve measured attempts. Keep failures, retries and Autopilot continuations. No extra attempts merely to obtain a favorable result.

The target is at least 20% fewer exported input plus output tokens, correct answers, and no clear whole-workflow latency regression. This is an engineering pilot, not a statistically powered estimate or a promise for other repositories.

## Measurement and review

Read the local Copilot OTLP export with `extract_usage.py`. Deduplicate trace/span identifiers, count every `chat` operation in the UI-delimited attempt, and reject incomplete final exports. Cache-read input and reasoning output are subsets; do not add them again. These are exported model counters, not billed credits or a claim that unobserved product activity is measured.

Workflow elapsed time is the interval from the first included chat span start to the last included chat/tool span end. It includes model/tool orchestration and Autopilot, excludes human observation delays, and is separate from native search timing. Report model and tool calls alongside tokens.

Inspect actual tool calls to establish which search workflow ran. `index-eligible` describes a request, not proof that the server answered it. Verify a completed, watching server and retain fallback/error warnings. Check candidate paths and explanations against current source independently. A text match alone does not establish symbol identity. Retain scope, citation or correctness deviations even when the final answer looks plausible.

Keep task prompts, private source excerpts, absolute source paths, raw traces, identifiers and settings backups local. Publish only aggregate counters, anonymized task IDs, quality decisions and implementation metadata. Restore temporary personal instructions, skill files and terminal settings after the pilot; preserve existing source edits and the shared server.
