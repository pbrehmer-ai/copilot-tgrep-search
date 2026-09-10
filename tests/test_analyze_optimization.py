import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('optimization', Path(__file__).parents[1]/'benchmarks/analyze_optimization.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ComparisonTests(unittest.TestCase):
    def rows(self):
        return [dict(variant=v, task='T', input_tokens=n, output_tokens=10,
                     total_tokens=n+10, cached_input_tokens=n-5, workflow_seconds=seconds,
                     model_calls=2, tool_calls=1, quality_pass=passed)
                for v,n,seconds,passed in [('A',90,10,True),('B',40,5,False)]]

    def test_failures_retained_and_cache_not_added(self):
        result=module.compare(self.rows(),'A','B',['T'])
        self.assertEqual(result['token_reduction_percent'],50)
        self.assertEqual(result['workflow_speedup'],2)
        self.assertFalse(result['all_answers_pass'])

    def test_missing_duplicate_and_invalid_accounting_rejected(self):
        rows=self.rows()
        for broken in [rows[:1], rows+[rows[0]], [dict(rows[0], total_tokens=999),rows[1]],
                       [dict(rows[0], cached_input_tokens=999),rows[1]]]:
            with self.assertRaises(ValueError): module.compare(broken,'A','B',['T'])


if __name__ == '__main__': unittest.main()
