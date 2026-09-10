import copy
import unittest
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'benchmarks'))
from analyze_tokens import analyze


def fixture():
    return [dict(run_id=f'{v}{rep}-T{task:02}',status='passed',input_tokens=(100 if v=='A' else 80),
                 output_tokens=20,cached_input_tokens=50,total_tokens=(120 if v=='A' else 100),
                 model_calls=2,tool_calls=1) for v in 'AB' for rep in range(1,4) for task in range(1,7)]


class AnalysisTests(unittest.TestCase):
    def test_user_stop_retains_extra_and_unmatched_attempts(self):
        rows=[r for r in fixture() if r['run_id'] not in {'B3-T04','B3-T05','B3-T06'}]
        with self.assertRaises(ValueError): analyze(rows)
        result=analyze(rows,completed_repetitions=2)
        self.assertEqual(result['recorded_attempts'],33)
        self.assertEqual(result['all_primary_attempts']['standard']['runs'],12)
        self.assertEqual(result['additional_matched_pairs']['skill']['runs'],3)
        self.assertEqual(result['additional_unmatched']['run_ids'],['A3-T04','A3-T05','A3-T06'])

    def test_sessions_are_separate_and_must_be_complete(self):
        rows=fixture()
        sessions=[dict(rows[0],run_id=f'S-{v}-T{task:02}') for v in 'AB' for task in range(1,4)]
        result=analyze(rows+sessions)
        self.assertEqual(result['all_primary_attempts']['standard']['runs'],18)
        self.assertEqual(result['exploratory_sessions']['standard']['runs'],3)
        self.assertEqual(result['exploratory_sessions']['token_saving_percent'],0)
        with self.assertRaises(ValueError): analyze(rows+sessions[:-1])

    def test_ratios_and_failed_pairs(self):
        rows=fixture()
        rows[-1]['status']='failed_quality'
        result=analyze(rows)
        self.assertAlmostEqual(result['all_primary_attempts']['token_ratio_standard_over_skill'],1.2)
        self.assertEqual(result['all_primary_attempts']['skill']['runs'],18)
        self.assertEqual(result['all_primary_attempts']['skill']['quality_passes'],17)
        self.assertEqual(result['both_passed_pairs']['skill']['runs'],17)
        self.assertAlmostEqual(result['all_primary_attempts']['token_saving_percent'],100/6)

    def test_incomplete_duplicate_and_bad_total_rejected(self):
        rows=fixture()
        for bad in (rows[:-1], rows+[rows[0]]):
            with self.assertRaises(ValueError): analyze(bad)
        rows[0]['total_tokens']=999
        with self.assertRaises(ValueError): analyze(rows)

if __name__=='__main__': unittest.main()
