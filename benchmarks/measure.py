"""Paired filename-search benchmark. Publishes query IDs/timings, never source paths/text.

Run before installation with only --rg, then after explicit server preparation
with --rg and --tgrep. Keep roots, queries, filters and output scope identical.
"""
import argparse
import json
from pathlib import Path
import statistics
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--queries', type=Path, required=True, help='Local JSON array of literal query strings; do not commit it')
    parser.add_argument('--rg', required=True)
    parser.add_argument('--tgrep')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--repeats', type=int, default=7)
    parser.add_argument('--direct', action='store_true')
    parser.add_argument('--glob', action='append', help='Repeat; use --glob=!**/bin/** for exclusions. Defaults to the pilot C# scope')
    args = parser.parse_args()
    if args.repeats < 2 or not args.root.is_dir():
        parser.error('Use an existing source directory and at least two repetitions')
    queries = json.loads(args.queries.read_text(encoding='utf-8-sig'))
    if not isinstance(queries, list) or not queries or any(not isinstance(q, str) or not q for q in queries):
        parser.error('queries must be a nonempty JSON array of nonempty strings')
    globs = args.glob if args.glob is not None else ['*.cs', '!**/bin/**', '!**/obj/**', '!**/.git/**', '!**/.vs/**']
    flags = ['-l', '-F', '--max-filesize', '64M']
    for glob in globs:
        flags += ['-g', glob]
    tools = {'rg': args.rg}
    if args.tgrep:
        tools['tgrep'] = args.tgrep
    versions = {}
    for name, exe in tools.items():
        version = subprocess.run([exe, '--version'], capture_output=True, text=True, timeout=10, check=True)
        versions[name] = version.stdout.splitlines()[0]
    if args.tgrep and not args.direct:
        status = subprocess.run([args.tgrep, 'status', '.'], cwd=args.root, capture_output=True, text=True, timeout=10, check=True)
        import re
        if not re.search(r'^Server status for ', status.stdout, re.M) or not re.search(r'^\s*Indexing:\s+complete\s*$', status.stdout, re.M):
            parser.error('Prepare a running, initially complete server for this exact root first')
    rows, reference = [], {}

    def run(name, number, query, repeat):
        extra = ['--no-index'] if name == 'tgrep' and args.direct else []
        start = time.perf_counter_ns()
        result = subprocess.run([tools[name], *extra, *flags, '--', query, '.'], cwd=args.root, capture_output=True, timeout=120)
        elapsed = (time.perf_counter_ns() - start) / 1e6
        # Strict decoding: repaired path bytes must not create false equivalence.
        paths = frozenset(p.replace('\\', '/').removeprefix('./') for p in result.stdout.decode('utf-8').splitlines())
        if result.returncode not in (0, 1) or result.stderr:
            raise RuntimeError(f'{name}, Q{number:02}: non-success exit code or stderr; inspect locally before publishing a benchmark')
        key = f'Q{number:02}'
        if key in reference and reference[key] != paths:
            raise RuntimeError(f'{key}: result sets differ or the source changed; no speedup claim is valid')
        reference.setdefault(key, paths)
        if repeat is not None:
            rows.append(dict(query_id=key, repeat=repeat, tool=name, ms=elapsed, file_count=len(paths), exit_code=result.returncode))

    for i, query in enumerate(queries, 1):
        for name in tools:
            run(name, i, query, None)
    for repeat in range(args.repeats):
        for i, query in enumerate(queries, 1):
            order = list(tools)
            if (repeat + i - 1) % 2:
                order.reverse()
            for name in order:
                run(name, i, query, repeat)
    totals = {name: sum(row['ms'] for row in rows if row['tool'] == name) for name in tools}
    median_sums = {name: sum(statistics.median(row['ms'] for row in rows if row['tool'] == name and row['query_id'] == f'Q{i:02}') for i in range(1, len(queries)+1)) for name in tools}
    report = dict(versions=versions, repeats=args.repeats, query_count=len(queries), direct=args.direct,
                  all_results_equal=True, measurements=rows, total_ms=totals, sum_medians_ms=median_sums,
                  note='OS caches not flushed; client startup and captured filename output included. Private root, query strings, globs and paths intentionally omitted; retain scope separately locally.')
    if args.tgrep:
        report['total_time_speedup'] = totals['rg'] / totals['tgrep']
        report['median_sum_speedup'] = median_sums['rg'] / median_sums['tgrep']
    args.out.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in report.items() if k != 'measurements'}, indent=2))


if __name__ == '__main__':
    main()
