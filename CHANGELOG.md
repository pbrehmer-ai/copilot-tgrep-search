# Changelog

## 0.2.0-pilot

- Incorporate the 10 September 2026 Windows x64 pilot, including unsuccessful complete Copilot runs and slower non-indexed scans.
- Add per-repository server preparation, initial-readiness wait, actual-root check and local Git exclusion with backup. Support Install.ps1 -RepositoryRoot for combined onboarding.
- Install adjacent helpers with the skill. Batch filename queries with structured exit codes, stderr, bounded displayed paths and per-client timeout. Preserve direct calls for small queries and content inspection.
- Prefer indexed reuse, avoid per-query readiness checks, and prefer available ripgrep/IDE tools for one-off unindexed scans.
- Bound terminal-output retries. Document the Autopilot control failure independently of tgrep; no unverified terminal-profile fix is claimed.
- Publish anonymized timing data and reproducible tooling. Internal identifiers, paths, query text, source contents and raw chat logs remain private.
- Replace draft-only onboarding with observations, acceptance gates and outstanding checks.

## 0.1.0-draft

Initial skill, personal instructions, pinned tgrep 1.0.5 Windows installer and team documentation. Pilot baseline commit: b5dca25dad65161020a678adab7458e35e943c46.
