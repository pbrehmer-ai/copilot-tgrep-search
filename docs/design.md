# Design and evidence

## Goal

Reduce the time GitHub Copilot spends on repeated repository text searches in Visual Studio, without trading away correctness or the IDE's semantic understanding.

tgrep uses a trigram index to identify likely candidate files before searching them. A local server keeps the index warm and applies filesystem updates. The benefit is strongest for repeated, selective searches across large repositories. Initial indexing, broad high-volume output, and tool-call overhead still cost time.

## Decisions

| Decision | Reason |
| --- | --- |
| One `tgrep-search/SKILL.md` with adjacent helpers | Copilot can follow the procedure without fetching documentation; helpers preserve native results and automate repository preparation. |
| Short default instruction | Skill discovery is conditional; the preference makes the intended search choice explicit without loading the full procedure on every request. |
| Personal installation for the first rollout | One setup serves multiple projects and avoids editing every source repository. A repository-scoped option remains available. |
| Pinned tgrep 1.0.5 | Documentation and executable behavior can be reviewed against the same release. |
| Root-local `.tgrep` by default | Uses the documented default. The skill explains root discipline and consistent custom paths when existing project policy requires them. |
| Reuse a server across queries | Avoids paying startup/readiness overhead on every search. |
| Scoped direct scans for decisive current-state checks | Index freshness is eventual; a successful indexed search is not proof of an exhaustive current view. |
| Keep native IDE tools | Text matching cannot replace semantic references, type navigation, or unsaved editor context. |
| No new MCP integration | Copilot already has a terminal tool; an extra service interface is unnecessary for the first implementation. |
| No broad tool-permission declarations in the skill | Existing Visual Studio approvals and company policies remain authoritative. |

## Performance claims

Microsoft's [published benchmarks](https://github.com/microsoft/tgrep/blob/v1.0.5/BENCHMARKS.md) compare tgrep client/server searches against ripgrep over large repositories. Index creation happens before search timing. Those results support investigating this approach, but do not establish a speedup for this Visual Studio integration or for every solution.

The [local pilot](benchmark-results.md) measured initial index cost and paired engine performance: 4.16x across all timed warm searches and 8.74x by summed per-query medians. It also established automatic skill loading and actual tgrep invocation. Complete Copilot answers failed acceptance because terminal results did not return reliably, including without tgrep. The new helpers do not constitute a fix for that output channel or a measured Copilot productivity multiplier.

## Microsoft guide adaptations

The upstream agent guide already explains search order, flags, machine-readable output, exit codes, and freshness. This integration adds the Visual Studio workflow and Windows setup, and turns those facts into explicit search decisions.

Two details were checked in the 1.0.5 source because they materially affect operation:

- [Default index directory](https://github.com/microsoft/tgrep/blob/v1.0.5/tgrep-core/src/builder.rs) and [search routing](https://github.com/microsoft/tgrep/blob/v1.0.5/tgrep-cli/src/search.rs): searching a nested directory does not automatically find an ancestor index. Keep the indexed root and use glob filters.
- [Status implementation](https://github.com/microsoft/tgrep/blob/v1.0.5/tgrep-cli/src/status.rs): a successful `status` command can report a missing index or a stopped server. Interpret its text, not only the exit code.

The [server](https://github.com/microsoft/tgrep/blob/v1.0.5/tgrep-cli/src/serve.rs) is a local tgrep service, not an MCP server. An upstream mention of integration with **Copilot CLI** does not establish built-in integration with **Visual Studio**.

## Source baseline

Reviewed on **September 10, 2026**. This is a documentation/source review baseline, not a runtime validation record.

| Source | Baseline |
| --- | --- |
| [Microsoft tgrep release](https://github.com/microsoft/tgrep/releases/tag/v1.0.5) | `v1.0.5`, release commit `d55b022023518646c90742f4761488dc95633b73` |
| [Microsoft AGENTS.md](https://github.com/microsoft/tgrep/blob/33675ce2342ad36bd080da3e1df91a863a22edbc/AGENTS.md) | Added in PR #143, commit `33675ce2342ad36bd080da3e1df91a863a22edbc`; contents match the 1.0.5 guide |
| [Release asset metadata](https://api.github.com/repos/microsoft/tgrep/releases/tags/v1.0.5) | Windows x64/ARM64 archive digests recorded in setup and manual instructions |
| [Visual Studio Agent Skills](https://learn.microsoft.com/en-us/visualstudio/ide/copilot-agent-skills?view=visualstudio) | Skills require Visual Studio 2026 18.5+; local and repository discovery paths documented |
| [Visual Studio custom instructions](https://learn.microsoft.com/en-us/visualstudio/ide/copilot-chat-context?view=visualstudio) | Personal `%USERPROFILE%/copilot-instructions.md` and repository `.github/copilot-instructions.md` |
| [Visual Studio Agent mode](https://learn.microsoft.com/en-us/visualstudio/ide/copilot-agent-mode?view=visualstudio) | Terminal tools, approvals, solution visibility, and symbol tools |
| [GitHub custom-instruction support](https://docs.github.com/en/copilot/reference/custom-instructions-support#visual-studio) | Does not list automatic `AGENTS.md` loading for Visual Studio Chat |

Upstream changes should be reviewed before updating the binary pin or skill. Keep Windows commands and source links aligned with the chosen release.
