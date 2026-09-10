"""Read local Copilot OTLP traces; emit allowlisted metadata, never prompts or tool bodies."""
import argparse
import collections
import json
from pathlib import Path


def unpack(value):
    if 'arrayValue' in value:
        return [unpack(v) for v in value['arrayValue'].get('values', [])]
    return next(iter(value.values()), None)


def extract(directory, since=0, *, allow_partial=False):
    spans = {}
    for path in directory.glob('*.jsonl'):
        lines = path.read_text(encoding='utf-8-sig').splitlines()
        for index, line in enumerate(lines):
            if not line.strip():
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError as exc:
                if allow_partial and index == len(lines) - 1:
                    continue  # Live inspection only; final extraction must be strict.
                raise ValueError('Malformed trace record; finish export and review locally') from exc
            for resource in record.get('resourceSpans', []):
                for scope in resource.get('scopeSpans', []):
                    for span in scope.get('spans', []):
                        if int(span.get('startTimeUnixNano', 0)) / 1e9 < since:
                            continue
                        key = (span['traceId'], span['spanId'])
                        if key in spans and spans[key] != span:
                            raise ValueError('Conflicting duplicate span; review locally')
                        spans[key] = span
    rows = []
    for key, span in spans.items():
        attrs = {a['key']: unpack(a['value']) for a in span.get('attributes', [])}
        operation = attrs.get('gen_ai.operation.name')
        if operation not in ('chat', 'execute_tool'):
            continue
        def count(name):
            value = attrs.get('gen_ai.usage.' + name)
            return None if value is None else int(value)
        row = dict(start_seconds=int(span['startTimeUnixNano'])/1e9,
                   end_seconds=int(span['endTimeUnixNano'])/1e9,
                   operation=operation, input_tokens=count('input_tokens'),
                   output_tokens=count('output_tokens'), cached_input_tokens=count('cache_read.input_tokens'),
                   reasoning_tokens=count('reasoning.output_tokens'),
                   model=attrs.get('gen_ai.response.model', attrs.get('gen_ai.request.model')),
                   tool=attrs.get('gen_ai.tool.name'),
                   error=bool(attrs.get('error.type') or span.get('status', {}).get('code') == 2),
                   finish_reasons=attrs.get('gen_ai.response.finish_reasons'))
        if operation == 'execute_tool':
            try:
                arguments = json.loads(attrs.get('gen_ai.tool.call.arguments', '{}'))
            except (json.JSONDecodeError, TypeError):
                arguments = {}
            command = str(arguments.get('command', '')).lower()
            filename = str(arguments.get('filename', '')).lower().replace('\\', '/')
            row['search_evidence'] = {
                'tgrep_command': 'tgrep' in command,
                'search_helper_command': 'search.ps1' in command,
                'direct_scan_flag': '--no-index' in command or '-noindex' in command,
                'skill_file_read': 'tgrep-search/skill.md' in filename,
                'powershell_scan': 'select-string' in command,
                'readiness_command': 'tgrep' in command and (' status' in command or '--version' in command),
            }
        if row['cached_input_tokens'] is not None and row['input_tokens'] is not None:
            if not 0 <= row['cached_input_tokens'] <= row['input_tokens']:
                raise ValueError('Cache count does not fit inclusive input count')
        rows.append(row)
    return sorted(rows, key=lambda row: row['start_seconds'])


def aggregate(rows):
    chats = [r for r in rows if r['operation'] == 'chat']
    def total(field):
        return sum(r[field] for r in chats) if chats and all(r[field] is not None for r in chats) else None
    incoming, outgoing = total('input_tokens'), total('output_tokens')
    return dict(model_calls=len(chats), tool_calls=sum(r['operation']=='execute_tool' for r in rows),
                input_tokens=incoming, output_tokens=outgoing, cached_input_tokens=total('cached_input_tokens'),
                reasoning_tokens=total('reasoning_tokens'),
                total_tokens=(incoming+outgoing if incoming is not None and outgoing is not None else None),
                tool_counts=dict(collections.Counter(r['tool'] for r in rows if r['operation']=='execute_tool')),
                note='Cache and reasoning are subsets, not added again. Missing values remain null. Counts cover exported model calls, not billing or unobserved product activity.')


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--traces', type=Path, required=True)
    parser.add_argument('--since', type=float, default=0)
    parser.add_argument('--until', type=float)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--allow-partial', action='store_true', help='Live inspection only; skip an incomplete final line')
    args=parser.parse_args()
    rows=extract(args.traces,args.since,allow_partial=args.allow_partial)
    if args.until is not None:
        rows=[r for r in rows if r['start_seconds'] <= args.until]
        if any(r['end_seconds'] > args.until for r in rows):
            raise ValueError('Measurement ends before an included call completed')
    result=dict(aggregate=aggregate(rows),calls=rows)
    args.out.write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result['aggregate'],indent=2))
