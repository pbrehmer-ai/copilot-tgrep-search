import json
import tempfile
import unittest
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'benchmarks'))
from extract_usage import extract, aggregate


def span(span_id, operation='chat', **usage):
    attrs=[{'key':'gen_ai.operation.name','value':{'stringValue':operation}}]
    attrs += [{'key':'gen_ai.usage.'+k, 'value':{'intValue':str(v)}} for k,v in usage.items()]
    return {'traceId':'synthetic','spanId':span_id,'startTimeUnixNano':'1000000000',
            'endTimeUnixNano':'2000000000','attributes':attrs}


def write(path, spans):
    path.write_text(json.dumps({'resourceSpans':[{'scopeSpans':[{'spans':spans}]}]})+'\n')


class UsageTests(unittest.TestCase):
    def test_partial_export_requires_explicit_live_mode(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            write(root/'a.jsonl',[span('a',input_tokens=100,output_tokens=10)])
            with (root/'a.jsonl').open('a') as stream:
                stream.write('{')
            with self.assertRaises(ValueError): extract(root)
            self.assertEqual(aggregate(extract(root,allow_partial=True))['total_tokens'],110)
            with (root/'a.jsonl').open('a') as stream:
                stream.write('\n{}\n')
            with self.assertRaises(ValueError): extract(root,allow_partial=True)

    def test_deduplicate_spans_and_ignore_agent_aggregate(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            chat=span('a',input_tokens=100,output_tokens=10,**{'cache_read.input_tokens':60})
            write(root/'a.jsonl',[chat,span('b','invoke_agent',input_tokens=1000)])
            write(root/'b.jsonl',[chat,span('c','execute_tool')])
            result=aggregate(extract(root))
            self.assertEqual(result['total_tokens'],110)
            self.assertEqual(result['cached_input_tokens'],60)
            self.assertEqual(result['model_calls'],1)
            self.assertEqual(result['tool_calls'],1)

    def test_missing_is_unknown_not_zero(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            write(root/'a.jsonl',[span('a',input_tokens=100)])
            result=aggregate(extract(root))
            self.assertIsNone(result['output_tokens'])
            self.assertIsNone(result['total_tokens'])
            self.assertIsNone(result['cached_input_tokens'])

    def test_conflicting_duplicate_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            write(root/'a.jsonl',[span('a',input_tokens=100)])
            write(root/'b.jsonl',[span('a',input_tokens=101)])
            with self.assertRaises(ValueError): extract(root)

    def test_invalid_cache_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            write(root/'a.jsonl',[span('a',input_tokens=10,**{'cache_read.input_tokens':11})])
            with self.assertRaises(ValueError): extract(root)

    def test_private_bodies_not_exported(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            tool=span('a','execute_tool')
            tool['attributes'] += [
                {'key':'gen_ai.tool.call.arguments','value':{'stringValue':json.dumps({'command':'SECRET_QUERY'})}},
                {'key':'gen_ai.tool.call.result','value':{'stringValue':'SECRET_SOURCE'}},
                {'key':'gen_ai.conversation.id','value':{'stringValue':'PRIVATE_ID'}}]
            write(root/'a.jsonl',[tool])
            result=json.dumps(extract(root))
            self.assertNotIn('SECRET',result)
            self.assertNotIn('PRIVATE_ID',result)

if __name__=='__main__': unittest.main()
