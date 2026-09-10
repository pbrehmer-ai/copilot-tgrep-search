"""Recompute descriptive A/B statistics from published per-run counters."""
import argparse
import json
import statistics
from pathlib import Path


FIELDS = ('input_tokens','output_tokens','cached_input_tokens','total_tokens','model_calls','tool_calls')


def group(rows):
    result = {'runs':len(rows), 'quality_passes':sum(r['status']=='passed' for r in rows)}
    for field in FIELDS:
        values=[r.get(field) for r in rows]
        result[field]=sum(values) if values and all(v is not None for v in values) else None
    incoming,cached=result['input_tokens'],result['cached_input_tokens']
    result['uncached_input_tokens']=incoming-cached if incoming is not None and cached is not None else None
    result['median_total_tokens']=statistics.median(r['total_tokens'] for r in rows) if rows and all(r.get('total_tokens') is not None for r in rows) else None
    return result


def compare(a,b):
    left,right=group(a),group(b)
    def ratio(field):
        x,y=left.get(field),right.get(field)
        return x/y if x is not None and y is not None and y!=0 else None
    def saving(field):
        x,y=left.get(field),right.get(field)
        return 100*(x-y)/x if x is not None and x!=0 and y is not None else None
    return {'standard':left,'skill':right,'token_ratio_standard_over_skill':ratio('total_tokens'),
            'token_saving_percent':saving('total_tokens'),'uncached_input_saving_percent':saving('uncached_input_tokens')}


def analyze(rows, completed_repetitions=3):
    if completed_repetitions not in (1,2,3):
        raise ValueError('Completed repetitions must be 1..3')
    attempts=[r for r in rows if r['run_id'][0] in ('A','B')]
    all_ids=[r['run_id'] for r in attempts]
    allowed={f'{v}{rep}-T{task:02}' for v in 'AB' for rep in range(1,4) for task in range(1,7)}
    if len(all_ids)!=len(set(all_ids)) or not set(all_ids)<=allowed:
        raise ValueError('Unexpected or duplicate attempt ID')
    primary=[r for r in attempts if int(r['run_id'][1])<=completed_repetitions]
    ids=[r['run_id'] for r in primary]
    expected={f'{v}{rep}-T{task:02}' for v in 'AB' for rep in range(1,completed_repetitions+1) for task in range(1,7)}
    if len(ids)!=len(set(ids)) or set(ids)!=expected:
        raise ValueError('Expected every A/B task in the declared completed repetitions')
    for row in rows:
        for field in FIELDS:
            if row.get(field) is not None and (not isinstance(row[field],int) or row[field]<0):
                raise ValueError('Invalid counter')
        if row.get('cached_input_tokens') is not None and row.get('input_tokens') is not None and row['cached_input_tokens']>row['input_tokens']:
            raise ValueError('Cached input exceeds inclusive input')
        if all(row.get(f) is not None for f in ('input_tokens','output_tokens','total_tokens')) and row['total_tokens'] != row['input_tokens']+row['output_tokens']:
            raise ValueError('Total is not input + output')
    standard=[r for r in primary if r['run_id'].startswith('A')]
    skill=[r for r in primary if r['run_id'].startswith('B')]
    by_task={f'T{task:02}':compare([r for r in standard if r['run_id'].endswith(f'T{task:02}')],[r for r in skill if r['run_id'].endswith(f'T{task:02}')]) for task in range(1,7)}
    passed_pairs={r['run_id'][1:] for r in standard if r['status']=='passed'} & {r['run_id'][1:] for r in skill if r['status']=='passed'}
    result = {'all_primary_attempts':compare(standard,skill),'by_task':by_task,
            'both_passed_pairs':compare([r for r in standard if r['run_id'][1:] in passed_pairs],[r for r in skill if r['run_id'][1:] in passed_pairs]),
            'note':'Negative savings mean overhead. Cached input is a subset. Ratios describe this integration and workload, not intrinsic engine efficiency, billing, or universal performance.'}
    extra=[r for r in attempts if r not in primary]
    if extra:
        extra_a=[r for r in extra if r['run_id'].startswith('A')]
        extra_b=[r for r in extra if r['run_id'].startswith('B')]
        paired={r['run_id'][1:] for r in extra_a}&{r['run_id'][1:] for r in extra_b}
        result['additional_matched_pairs']=compare([r for r in extra_a if r['run_id'][1:] in paired], [r for r in extra_b if r['run_id'][1:] in paired])
        result['additional_unmatched']={'run_ids':[r['run_id'] for r in extra if r['run_id'][1:] not in paired], 'counters':group([r for r in extra if r['run_id'][1:] not in paired])}
    result['completed_repetitions']=completed_repetitions
    result['recorded_attempts']=len(attempts)
    sessions=[r for r in rows if r['run_id'].startswith('S-')]
    if sessions:
        expected_sessions={f'S-{v}-T{task:02}' for v in 'AB' for task in range(1,4)}
        if len(sessions)!=6 or {r['run_id'] for r in sessions}!=expected_sessions:
            raise ValueError('Expected six exploratory session turns')
        result['exploratory_sessions']=compare([r for r in sessions if r['run_id'].startswith('S-A-')],
                                               [r for r in sessions if r['run_id'].startswith('S-B-')])
        result['exploratory_sessions']['note']='One three-task chat per condition, analyzed separately; no claim of a stable session effect.'
    return result


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('results',type=Path)
    args=parser.parse_args()
    data=json.loads(args.results.read_text(encoding='utf-8-sig'))
    print(json.dumps(analyze(data if isinstance(data,list) else data['runs'],3 if isinstance(data,list) else data.get('completed_repetitions',3)),indent=2))
