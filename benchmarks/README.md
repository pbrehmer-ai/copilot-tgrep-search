# Reproduce the search-engine comparison

For actual Copilot model tokens, see the separate [token protocol](TOKEN_PROTOCOL.md), [results](../docs/token-benchmark-results.md) and [sanitized data](results/2026-09-10-tokens.json). The token pilot found overhead, not savings; do not infer tokens from the engine timings below.

Python 3.9+ is required only for benchmarking. Employees do not need Python to use the skill. Use absolute executable paths to reviewed tgrep/ripgrep binaries.

Create a **local, uncommitted** JSON query list (for example `queries.private.json`) containing representative literal strings, including positive and negative queries. Keep source revision, filters, tool versions and machine details locally. Default filters match the pilot's C# scope; repeated `--glob` arguments replace the complete default filter list.

```powershell
# Before installing/preparing tgrep: record an untouched standard baseline.
python .\benchmarks\measure.py --root 'C:\repos\YourRepository' --queries '.\queries.private.json' --rg '<absolute-rg.exe>' --out '.\before.private.json'

# After explicit preparation and initial index completion, with the IDE idle:
python .\benchmarks\measure.py --root 'C:\repos\YourRepository' --queries '.\queries.private.json' --rg '<absolute-rg.exe>' --tgrep '<absolute-tgrep.exe>' --out '.\paired.private.json'

# Separate comparison that explicitly bypasses the index:
python .\benchmarks\measure.py --root 'C:\repos\YourRepository' --queries '.\queries.private.json' --rg '<absolute-rg.exe>' --tgrep '<absolute-tgrep.exe>' --direct --out '.\direct.private.json'
```

The harness warms each query/tool once, alternates tool order, runs seven repetitions by default, and checks complete path-set equality across warm-ups and measured runs. A failure, stderr, decoding problem or mismatch aborts the comparison. It does not flush OS caches. Results include process startup and captured filename output, excluding prior index creation. The script writes only IDs, counts, timings and versions; it does not write source paths, query strings or source content. Review any output before publication.

The published [pilot timing data](results/2026-09-10.json) was anonymized from the original local harness, **not produced by retroactively running this new harness**. It includes every measured paired indexed run; query IDs preserve the original order, while private query text and path sets are deliberately omitted. Consequently readers can reproduce the arithmetic but cannot independently rerun the exact proprietary corpus or validate its original path sets. Test your own corpus for applicability.

Do not conflate engine timings with Copilot answer latency. Measure complete agent tasks separately, with a healthy terminal bridge, the same model/mode, equivalent prompts, multiple repetitions, answer correctness and approval time recorded separately.
