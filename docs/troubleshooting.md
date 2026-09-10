# Troubleshooting

Check each layer in order: installation → terminal round trip → skill discovery → index readiness → actual search and complete answer.

## A command finished but Copilot keeps waiting

Observed in Visual Studio Enterprise 18.9.12112.369 with GPT-5.6 Luna and Windows PowerShell 5.1.26100.9444: results appeared and the prompt returned, but Copilot's foreground tool stayed pending. Its background-output tool repeatedly returned `running` and `0 total lines`. Autopilot did not fix it. A fresh control requesting only PowerShell version and working directory reproduced it without tgrep.

1. Cancel the pending turn. Do not keep resubmitting searches or start additional servers.
2. Check terminal initialization. The pilot encountered a publisher question and a PSReadLine loading error. Resolve prompts under company policy; do not bypass policy or automatically trust every publisher.
3. Restart Visual Studio and use a fresh chat. Ask for only PowerShell version and working directory through the terminal tool.
4. Require a completed chat answer. If only the console receives output, the terminal path fails acceptance. Use available IDE search and collect the exact VS build, shell profile, model and sanitized reproduction for your administrator or Visual Studio support.

A supported alternative terminal profile is a possible controlled experiment, **not a verified fix**. The pilot inspected profiles but did not change them. Do not apply VS Code terminal settings to Visual Studio. The new search helper preserves errors and limits its search client's lifetime; it cannot repair the IDE-to-agent output channel.

## Installation and discovery

| Symptom | Action |
| --- | --- |
| Script execution disabled | Use an approved PowerShell host or manual/IT distribution. The installer pilot used PowerShell 7.6.5; Windows PowerShell 5.1 blocked a separate benchmark script. Hosts can have different existing policies. |
| Personal skill asks for access | Review outside-workspace read permission. Installation and permission to read are separate. Repository-scoped installation is an alternative. |
| tgrep not found | Restart Visual Studio completely. Verify the executable's absolute path, then user PATH in the new process. |
| rg not found during fallback | This occurred in the baseline. Use an available IDE tool or approved executable; do not assume every Visual Studio terminal includes ripgrep. |
| Skill not selected | Check Agent mode, VS 18.5+, custom instructions, exact SKILL.md path and duplicate skills. Explicitly request the skill once to isolate discovery from execution. |
| Wrong executable version | The skill prefers the pinned absolute path. Machine PATH can precede user PATH. Review rather than silently using an incompatible version. |
| Partial installer failure | Inspect its recovery manifest before retrying; preserve intervening edits. Repository preparation is separate from personal file installation. |

## Index and results

| Symptom | Action |
| --- | --- |
| Repeated scan/no-index warnings | Verify positional root and server. A subdirectory does not discover the parent index; keep the root and filter with globs. |
| Setup not READY before timeout | Inspect tgrep status for the same root. The helper leaves the server running. Check it before extending the wait; do not start more processes. |
| Initial indexing complete but edits missing | Watchers are asynchronous; use a scoped saved-file scan before decisive claims. Unsaved buffers require IDE context. |
| .tgrep appears in Git status | Verify after index creation with `git status --short --untracked-files=all -- .tgrep`. A hidden folder or misleading check-ignore display is insufficient. |
| Helper Succeeded false, stderr or timeout | Inspect the result. Partial paths are not exhaustive. Correct scope/options or fall back; never replace failure with a zero-match claim. |
| PathsTruncated true | Only a subset is displayed. ReturnedPathCount is reliable only for a successful, correctly scoped, sufficiently fresh search. Narrow before requesting more output. |
| No speed benefit | Verify server use and equivalent filters/output. Startup, extra model/tool calls and helper serialization can outweigh savings. |

Keep source code, secrets, internal query strings and raw terminal transcripts out of support reports and this integration repository.
