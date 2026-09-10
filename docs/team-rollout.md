# Team rollout

## Employee experience

For the next-machine trial, give employees the short setup request in [README](../README.md). Copilot follows [SETUP.md](../SETUP.md), runs the supplied installer and checks the installed package. Employees still need repository access, a healthy terminal and one Visual Studio restart. Version 0.3.0 is a candidate for this trial; the previous token measurements apply to 0.2.0, not the new package.

Distribute a reviewed revision with the pinned tgrep 1.0.5 executable: one personal installation, one preparation step for each source repository/session, then ordinary Copilot work. The combined installer option accepts the first source root. Indexes and servers are per source root; the skill is per user.

The repository is private. Employees need read access or an approved internal package. A Copilot license alone does not grant repository access. Do not make it public to work around access management.

## Current gate

The [engine pilot](benchmark-results.md) passed installation, automatic skill loading and equivalent engine results but failed complete agent execution with its original terminal profile. A later PowerShell 7 profile allowed complete attempts. However, the [0.2.0 token benchmark](token-benchmark-results.md) found **89.54% more model tokens** and correctness failures. Version 0.3.0 is ready for the next-machine trial, with no new end-to-end measurement. Company-wide deployment remains gated on representative quality and efficiency improvements, as well as clean onboarding acceptance.

## Distribution checklist

1. Select the supported VS build, shell profile and model. Validate terminal initialization and a minimal command-to-chat round trip first.
2. Review the skill, conditional reference, default rule and three adjacent helper scripts as one package. Check the pinned executable checksum. Distribute through existing IT tooling or the supplied installer; the installer downloads from GitHub and has no offline switch.
3. Confirm permission for local executable/index storage and a loopback server. Installation does not grant Copilot tool permissions. Autopilot is optional, not a prerequisite or a substitute for healthy tools.
4. Prepare each repository's actual root; preserve custom index workflows and project exclusions. Verify local .tgrep exclusion after creation. Avoid duplicate personal/repository copies of the same skill.
5. Run the [acceptance scenarios](validation-plan.md) on representative solutions. Include complete answers, fresh/negative checks, errors and repeated searches. Record model/tool overhead separately from engine latency.
6. Start with a small team using the exact employee package. Expand only after onboarding and completion pass. Assign an owner, supported-version matrix and rollback package.

For restricted/offline environments, use [manual setup](manual-setup.md). Do not bypass script policies. Windows ARM64, alternative shells and company-specific restrictions require separate validation.

## Why a rule plus a skill and helpers?

The short rule expresses when to use tgrep. The skill contains the decision procedure. The helpers implement repeatable setup, argument quoting, bounded output and error capture. Employees install these together; they do not maintain independent rule sets.

This arrangement influences tool selection. It does not replace Visual Studio's built-in search implementation or guarantee model obedience. Keep semantic IDE tools and unsaved editor context available.

Organization-wide instructions are optional, not a prerequisite. Confirm support in the exact company environment before relying on them. Local personal/repository discovery provides the documented baseline.

## Maintenance

Review upstream changes before changing the version pin. Preserve tgrep 1.0.5 until a candidate passes the same checks. Publish sanitized results tied to the tested integration commit; do not upload proprietary corpora, identifiers or raw transcripts. Track installation, helper tests, engine measurements and complete agent acceptance separately.
