# Team rollout

The intended employee experience is one setup action, then normal work in Visual Studio Agent mode. This document describes the rollout after the initial review and pilot. No company-wide deployment has been performed.

## Distribution model

Maintain one reviewed copy of the skill and default instruction in this repository. Package a specific repository revision and the pinned Microsoft tgrep release through the company's existing software distribution channel.

The setup script supports a per-user installation without administrator rights. IT can instead place the same files through its existing device-management process. For offline or restricted devices, stage the approved tgrep executable and use the manual setup instructions; the current script downloads from GitHub and has no offline switch.

The initial repository is private. Before employee rollout, give the intended team read access through the repository owner's normal access-management process, or distribute an approved package internally. Employees cannot clone a private personal repository solely because they have a Copilot license. Do not publish the repository publicly just to simplify setup.

## Prerequisites to confirm

- The target is **GitHub Copilot in Visual Studio 2026 18.5+ on Windows x64/ARM64**. A subscription using a Claude model inside Copilot is still Copilot; it does not load Claude Code configuration automatically by virtue of model choice.
- Agent mode and terminal commands are available under the company's Copilot settings.
- The company permits the local tgrep executable, local index storage, and a loopback search server where needed.
- The chosen installation method respects script-signing, software-distribution, and network policies. Tool approvals are configured through the existing Visual Studio workflow, not granted by this skill.
- Repo-specific exclusions and instruction files are accounted for. A terminal search must not be used to bypass intended data-access boundaries.

## Staged adoption

1. **Review this draft.** Agree on skill behavior, instruction wording, index scope, and the initial tgrep version. Keep the initial state marked as unvalidated.
2. **Run the pilot.** Complete the [validation plan](validation-plan.md) with representative solutions, including at least one large repository. Record both correctness and total task time.
3. **Publish a reviewed revision.** Record the repository commit, supported Visual Studio builds, tgrep version, checksums, and known limitations. Approve or revise the performance claim based on measured results.
4. **Distribute to a small team.** Use the same package employees will receive. Collect actual activation/fallback behavior and installation friction before expanding.
5. **Expand and maintain.** Give one owner responsibility for reviewing upstream tgrep changes and keeping the skill, binary pin, and setup consistent. Keep a previous reviewed package available for rollback.

## Why two instruction layers?

The small default instruction tells Copilot when to consider tgrep. The skill contains the operating procedure and loads when relevant. Both are installed together; employees do not maintain two independent sets of search rules.

An installation makes the skill available. It does not guarantee a model will choose it for every task, replace a built-in tool implementation, or bypass higher-priority instructions. Validate observed behavior rather than treating file presence as adoption.

## Organization-level instructions

Do not make central GitHub organization instructions a prerequisite for this initial rollout. As checked on September 10, 2026, [Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/ide/copilot-chat-context?view=visualstudio#use-organization-level-custom-instructions) describes their use in Visual Studio, while [GitHub's organization-instruction page](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-organization-instructions) limits its stated support to GitHub.com features.

A future pilot can establish support in the company's exact environment and move the short preference there if useful. The documented local skill and instruction paths provide a concrete starting point independent of that discrepancy.

## Scope of this first repository

Included: one search skill, one default-instruction template, a per-user setup script, onboarding documentation, source attribution, and the next-stage validation plan.

Deferred: runtime tests, measured performance results, company-wide distribution, automated update services, CI validation, and any separate Codex/Claude Code packaging. No MCP server or Visual Studio extension is required by this design.
