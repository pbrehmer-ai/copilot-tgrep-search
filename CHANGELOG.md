# Changelog

## 0.3.0-pilot

- Add SETUP.md with one Copilot installation task, authenticated private-repository fallback, terminal control, supplied-script installation and restart handoff.
- Shorten the skill and persistent preference; install a conditional advanced reference with backups.
- Emit compact JSON with full MatchFileCount, null on errors, and normalized OrdinalIgnoreCase-sorted samples. Default to five paths, support zero for counts, and cap oversized requests at 1000.
- Document Results explicitly and discourage repeated schema discovery, output expansion and unnecessary direct scans. Preserve current-file verification requirements.
- Combine initial readiness and discovery with optional -CheckReady; return no queries for an unready server. Reuse readiness afterwards.
- Add a read-only Check-Setup.ps1 for installed-package/version/server checks; reject invalid or nested source roots before installation writes.
- Extend isolated helper checks for sampling, sorting, compact output, errors and installed-file mismatch detection. Ready for a next-machine trial; no new Copilot token or performance improvement is claimed.

## Token benchmark report — 10 September 2026

- Publish 33 completed Copilot attempts, with the headline based on two complete balanced repetitions: 89.54% more model tokens with the tested integration. Retain failed and unmatched attempts separately.
- Document actual per-model token telemetry, cache accounting, parser tests, reproducible statistics and privacy limitations.
- Record the working PowerShell 7 terminal profile and restoration of original settings. No universal terminal fix is claimed.
- Document helper retries, repeated skill reads and direct scans. Keep the tested skill and helpers unchanged; no token-saving optimization is claimed without a new comparison.
- Stop further benchmarking at the user's request; the same-chat follow-up remains unperformed.

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
