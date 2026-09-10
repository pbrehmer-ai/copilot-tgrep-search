"""Recompute paired workflow metrics from sanitized optimization attempts."""
import json
from pathlib import Path
import argparse


def compare(attempts, baseline, candidate, tasks):
    selected = {}
    for attempt in attempts:
        if attempt['variant'] not in (baseline, candidate) or attempt['task'] not in tasks:
            continue
        key = (attempt['variant'], attempt['task'])
        if key in selected:
            raise ValueError('Duplicate variant/task')
        incoming, outgoing = attempt['input_tokens'], attempt['output_tokens']
        if incoming is None or outgoing is None or min(incoming, outgoing) < 0:
            raise ValueError('Missing or negative usage')
        if attempt['total_tokens'] != incoming + outgoing:
            raise ValueError('Token total mismatch')
        cache = attempt.get('cached_input_tokens')
        if cache is not None and not 0 <= cache <= incoming:
            raise ValueError('Cache is not an input subset')
        if attempt['workflow_seconds'] <= 0:
            raise ValueError('Invalid elapsed time')
        selected[key] = attempt
    if set(selected) != {(variant, task) for variant in (baseline, candidate) for task in tasks}:
        raise ValueError('Incomplete pairing')
    totals = {}
    for variant in (baseline, candidate):
        rows = [selected[variant, task] for task in tasks]
        totals[variant] = {field: sum(row[field] for row in rows) for field in
                           ('input_tokens', 'output_tokens', 'total_tokens', 'model_calls', 'tool_calls', 'workflow_seconds')}
        totals[variant]['quality_passes'] = sum(row['quality_pass'] for row in rows)
    a, b = totals[baseline], totals[candidate]
    if not a['total_tokens'] or not b['total_tokens']:
        raise ValueError('Zero usage cannot establish a comparison')
    return dict(tasks=tasks, totals=totals,
                token_reduction_percent=100*(1-b['total_tokens']/a['total_tokens']),
                token_factor=a['total_tokens']/b['total_tokens'],
                workflow_speedup=a['workflow_seconds']/b['workflow_seconds'],
                all_answers_pass=all(row['quality_pass'] for row in selected.values()))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('file', type=Path)
    args = parser.parse_args()
    data = json.loads(args.file.read_text(encoding='utf-8'))
    print(json.dumps({group['name']: compare(data['attempts'], group['baseline'], group['candidate'], group['tasks'])
                      for group in data['comparisons']}, indent=2))
