# Direct-tool optimization research — 10 September 2026

## What the current sources establish

- [Microsoft tgrep](https://github.com/microsoft/tgrep) still lists [v1.0.5](https://github.com/microsoft/tgrep/releases/tag/v1.0.5), published September 8, as its latest release. The inspected main revision was `a0f0c041d2106119e4adcd0bf5dbafeef60f9615`; subsequent-to-release commits concern stats ordering and lint fixes, not a documented Visual Studio token optimization.
- [Microsoft's AGENTS.md](https://github.com/microsoft/tgrep/blob/a0f0c041d2106119e4adcd0bf5dbafeef60f9615/AGENTS.md) includes a minimal model-tool schema. It calls for configured-root containment, search-only arguments, and preservation of exit codes and stderr. Indexed discovery, small output and deliberate current-file scans remain the relevant search rules.
- [GitHub's CLI reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference) documents `USE_TGREP` and automatic switching for large repositories. This is a Copilot CLI feature; it does not document that switch for Visual Studio Chat.
- [Visual Studio MCP support](https://learn.microsoft.com/en-us/visualstudio/ide/mcp-servers?view=visualstudio) provides direct tools through a personal `.mcp.json`. [Custom agents](https://learn.microsoft.com/en-us/visualstudio/ide/copilot-specialized-agents?view=visualstudio) can supply a focused tool set, inherit the selected model and be installed per user. Microsoft's page also documents tool-group enablement issues, so discovery alone does not prove that a tool is usable.
- A public [community tgrep MCP adapter](https://github.com/sagarbalaai-code/tgrep-mcp) exists. Its README lists search, indexing, status, counting and server-start tools. The inspected repository had one commit and no published Visual Studio token/latency benchmark establishing our targets. This integration was implemented independently; it does not install that package or copy its code.

Web searches for tgrep/Copilot token optimizations, Visual Studio use cases and MCP integrations did not locate an independently demonstrated Visual Studio result meeting both targets. Absence from these searches is not proof that no such work exists.

## Why change the integration boundary?

In the previous held-out tgrep pair, exported model spans occupied 16.310 of 19.107 seconds and 19.818 of 21.070 seconds respectively. Tool spans occupied only 1.943 and 0.579 seconds. These span totals are diagnostic and may overlap; they are not additive billing or a causal speed estimate. They show why accelerating the native search alone cannot plausibly explain a threefold improvement in those complete workflows.

The next candidate exposes a single read-only MCP search tool. It removes skill loading and generated terminal commands from the normal search path, batches terms and returns bounded current excerpts in the discovery response. A focused investigator is a separate optional workflow for saved-source questions. It is not a replacement for an editing agent or the IDE's semantic tools.

Any improvement from fewer tool schemas, different instructions or fewer model turns belongs to the integration package. A matched ripgrep adapter would help isolate the engine contribution. Same-model paired measurements, correct answers and fresh tasks remain necessary; neither an MCP label nor a smaller response proves the requested 20% token saving and 3x end-to-end speedup.
