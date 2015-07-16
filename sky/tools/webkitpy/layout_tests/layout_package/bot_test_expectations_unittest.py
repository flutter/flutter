# Copyright (C) 2013 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the Google name nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import unittest

from webkitpy.layout_tests.layout_package import bot_test_expectations
from webkitpy.layout_tests.models import test_expectations
from webkitpy.layout_tests.port import builders


class BotTestExpectationsFactoryTest(unittest.TestCase):
    def fake_results_json_for_builder(self, builder):
        return bot_test_expectations.ResultsJSON(builder, 'Dummy content')

    def test_expectations_for_builder(self):
        factory = bot_test_expectations.BotTestExpectationsFactory()
        factory._results_json_for_builder = self.fake_results_json_for_builder

        old_builders = builders._exact_matches
        builders._exact_matches = {
            "Dummy builder name": {"port_name": "dummy-port", "specifiers": []},
        }

        try:
            self.assertIsNotNone(factory.expectations_for_builder('Dummy builder name'))
        finally:
            builders._exact_matches = old_builders

    def test_expectations_for_port(self):
        factory = bot_test_expectations.BotTestExpectationsFactory()
        factory._results_json_for_builder = self.fake_results_json_for_builder

        old_builders = builders._exact_matches
        builders._exact_matches = {
            "Dummy builder name": {"port_name": "dummy-port", "specifiers": []},
        }

        try:
            self.assertIsNotNone(factory.expectations_for_port('dummy-port'))
        finally:
            builders._exact_matches = old_builders


class BotTestExpectationsTest(unittest.TestCase):
    # FIXME: Find a way to import this map from Tools/TestResultServer/model/jsonresults.py.
    FAILURE_MAP = {"A": "AUDIO", "C": "CRASH", "F": "TEXT", "I": "IMAGE", "O": "MISSING",
        "N": "NO DATA", "P": "PASS", "T": "TIMEOUT", "Y": "NOTRUN", "X": "SKIP", "Z": "IMAGE+TEXT", "K": "LEAK"}

    # All result_string's in this file expect newest result
    # on left: "PFF", means it just passed after 2 failures.

    def _assert_is_flaky(self, results_string, should_be_flaky):
        results_json = self._results_json_from_test_data({})
        expectations = bot_test_expectations.BotTestExpectations(results_json, set('test'))
        length_encoded = self._results_from_string(results_string)['results']
        num_actual_results = len(expectations._flaky_types_in_results(length_encoded, only_ignore_very_flaky=True))
        if should_be_flaky:
            self.assertGreater(num_actual_results, 1)
        else:
            self.assertEqual(num_actual_results, 1)

    def test_basic_flaky(self):
        self._assert_is_flaky('PFF', False)  # Used to fail, but now passes.
        self._assert_is_flaky('FFP', False)  # Just started failing.
        self._assert_is_flaky('PFPF', True)  # Seen both failures and passes.
        # self._assert_is_flaky('PPPF', True)  # Should be counted as flaky but isn't yet.
        self._assert_is_flaky('FPPP', False)  # Just started failing, not flaky.
        self._assert_is_flaky('PFFP', True)  # Failed twice in a row, still flaky.
        # Failing 3+ times in a row is unlikely to be flaky, but rather a transient failure on trunk.
        # self._assert_is_flaky('PFFFP', False)
        # self._assert_is_flaky('PFFFFP', False)

    def _results_json_from_test_data(self, test_data):
        test_data[bot_test_expectations.ResultsJSON.FAILURE_MAP_KEY] = self.FAILURE_MAP
        json_dict = {
            'builder': test_data,
        }
        return bot_test_expectations.ResultsJSON('builder', json_dict)

    def _results_from_string(self, results_string):
        results_list = []
        last_char = None
        for char in results_string:
            if char != last_char:
                results_list.insert(0, [1, char])
            else:
                results_list[0][0] += 1
        return {'results': results_list}

    def _assert_expectations(self, test_data, expectations_string, only_ignore_very_flaky):
        results_json = self._results_json_from_test_data(test_data)
        expectations = bot_test_expectations.BotTestExpectations(results_json, set('test'))
        self.assertEqual(expectations.flakes_by_path(only_ignore_very_flaky), expectations_string)

    def _assert_unexpected_results(self, test_data, expectations_string):
        results_json = self._results_json_from_test_data(test_data)
        expectations = bot_test_expectations.BotTestExpectations(results_json, set('test'))
        self.assertEqual(expectations.unexpected_results_by_path(), expectations_string)

    def test_basic(self):
        test_data = {
            'tests': {
                'foo': {
                    'veryflaky.html': self._results_from_string('FPFP'),
                    'maybeflaky.html': self._results_from_string('PPFP'),
                    'notflakypass.html': self._results_from_string('PPPP'),
                    'notflakyfail.html': self._results_from_string('FFFF'),
                }
            }
        }
        self._assert_expectations(test_data, {
            'foo/veryflaky.html': sorted(["TEXT", "PASS"]),
        }, only_ignore_very_flaky=True)

        self._assert_expectations(test_data, {
            'foo/veryflaky.html': sorted(["TEXT", "PASS"]),
            'foo/maybeflaky.html': sorted(["TEXT", "PASS"]),
        }, only_ignore_very_flaky=False)

    def test_all_failure_types(self):
        test_data = {
            'tests': {
                'foo': {
                    'allfailures.html': self._results_from_string('FPFPCNCNTXTXIZIZOCOCYKYK'),
                    'imageplustextflake.html': self._results_from_string('ZPZPPPPPPPPPPPPPPPPP'),
                }
            }
        }
        self._assert_expectations(test_data, {
            'foo/imageplustextflake.html': sorted(["IMAGE+TEXT", "PASS"]),
            'foo/allfailures.html': sorted(["TEXT", "PASS", "IMAGE+TEXT", "TIMEOUT", "CRASH", "IMAGE", "MISSING", "LEAK"]),
        }, only_ignore_very_flaky=True)

    def test_unexpected_results_no_unexpected(self):
        test_data = {
            'tests': {
                'foo': {
                    'pass1.html': {'results': [[4, 'P']]},
                    'pass2.html': {'results': [[2, 'Z']], 'expected': 'PASS FAIL'},
                    'fail.html': {'results': [[2, 'P'], [1, 'F']], 'expected': 'PASS FAIL'},
                    'not_run.html': {'results': []},
                    'crash.html': {'results': [[2, 'F'], [1, 'C']], 'expected': 'CRASH FAIL WONTFIX'},
                }
            }
        }
        self._assert_unexpected_results(test_data, {})

    def test_unexpected_results_all_unexpected(self):
        test_data = {
            'tests': {
                'foo': {
                    'pass1.html': {'results': [[4, 'P']], 'expected': 'FAIL'},
                    'pass2.html': {'results': [[2, 'P']], 'expected': 'IMAGE'},
                    'fail.html': {'results': [[4, 'F']]},
                    'f_p.html': {'results': [[1, 'F'], [2, 'P']]},
                    'crash.html': {'results': [[2, 'F'], [1, 'C']], 'expected': 'WONTFIX'},
                    'image.html': {'results': [[2, 'F'], [1, 'I']], 'expected': 'CRASH FAIL'},
                    'i_f.html': {'results': [[1, 'F'], [5, 'I']], 'expected': 'PASS'},
                    'all.html': self._results_from_string('FPFPCNCNTXTXIZIZOCOCYKYK'),
                }
            }
        }
        self.maxDiff = None
        self._assert_unexpected_results(test_data, {
            'foo/pass1.html': sorted(["FAIL", "PASS"]),
            'foo/pass2.html': sorted(["IMAGE", "PASS"]),
            'foo/fail.html': sorted(["TEXT", "PASS"]),
            'foo/f_p.html': sorted(["TEXT", "PASS"]),
            'foo/crash.html': sorted(["WONTFIX", "CRASH", "TEXT"]),
            'foo/image.html': sorted(["CRASH", "FAIL", "IMAGE"]),
            'foo/i_f.html': sorted(["PASS", "IMAGE", "TEXT"]),
            'foo/all.html': sorted(["TEXT", "PASS", "IMAGE+TEXT", "TIMEOUT", "CRASH", "IMAGE", "MISSING", "LEAK"]),
        })
