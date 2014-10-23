# Copyright (C) 2010 Google Inc. All rights reserved.
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
#     * Neither the name of Google Inc. nor the names of its
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

from webkitpy.common.host_mock import MockHost
from webkitpy.layout_tests.models import test_expectations
from webkitpy.layout_tests.models import test_failures
from webkitpy.layout_tests.models import test_results
from webkitpy.layout_tests.models import test_run_results


def get_result(test_name, result_type=test_expectations.PASS, run_time=0):
    failures = []
    if result_type == test_expectations.TIMEOUT:
        failures = [test_failures.FailureTimeout()]
    elif result_type == test_expectations.AUDIO:
        failures = [test_failures.FailureAudioMismatch()]
    elif result_type == test_expectations.CRASH:
        failures = [test_failures.FailureCrash()]
    elif result_type == test_expectations.LEAK:
        failures = [test_failures.FailureLeak()]
    return test_results.TestResult(test_name, failures=failures, test_run_time=run_time)


def run_results(port, extra_skipped_tests=[]):
    tests = ['passes/text.html', 'failures/expected/timeout.html', 'failures/expected/crash.html', 'failures/expected/leak.html', 'failures/expected/keyboard.html',
             'failures/expected/audio.html', 'passes/skipped/skip.html']
    expectations = test_expectations.TestExpectations(port, tests)
    if extra_skipped_tests:
        expectations.add_extra_skipped_tests(extra_skipped_tests)
    return test_run_results.TestRunResults(expectations, len(tests))


def summarized_results(port, expected, passing, flaky, only_include_failing=False, extra_skipped_tests=[]):
    test_is_slow = False

    initial_results = run_results(port, extra_skipped_tests)
    if expected:
        initial_results.add(get_result('passes/text.html', test_expectations.PASS), expected, test_is_slow)
        initial_results.add(get_result('failures/expected/audio.html', test_expectations.AUDIO), expected, test_is_slow)
        initial_results.add(get_result('failures/expected/timeout.html', test_expectations.TIMEOUT), expected, test_is_slow)
        initial_results.add(get_result('failures/expected/crash.html', test_expectations.CRASH), expected, test_is_slow)
        initial_results.add(get_result('failures/expected/leak.html', test_expectations.LEAK), expected, test_is_slow)
    elif passing:
        skipped_result = get_result('passes/skipped/skip.html')
        skipped_result.type = test_expectations.SKIP
        initial_results.add(skipped_result, expected, test_is_slow)

        initial_results.add(get_result('passes/text.html', run_time=1), expected, test_is_slow)
        initial_results.add(get_result('failures/expected/audio.html'), expected, test_is_slow)
        initial_results.add(get_result('failures/expected/timeout.html'), expected, test_is_slow)
        initial_results.add(get_result('failures/expected/crash.html'), expected, test_is_slow)
        initial_results.add(get_result('failures/expected/leak.html'), expected, test_is_slow)
    else:
        initial_results.add(get_result('passes/text.html', test_expectations.TIMEOUT, run_time=1), expected, test_is_slow)
        initial_results.add(get_result('failures/expected/audio.html', test_expectations.AUDIO, run_time=0.049), expected, test_is_slow)
        initial_results.add(get_result('failures/expected/timeout.html', test_expectations.CRASH, run_time=0.05), expected, test_is_slow)
        initial_results.add(get_result('failures/expected/crash.html', test_expectations.TIMEOUT), expected, test_is_slow)
        initial_results.add(get_result('failures/expected/leak.html', test_expectations.TIMEOUT), expected, test_is_slow)

        # we only list keyboard.html here, since normally this is WontFix
        initial_results.add(get_result('failures/expected/keyboard.html', test_expectations.SKIP), expected, test_is_slow)

    if flaky:
        retry_results = run_results(port, extra_skipped_tests)
        retry_results.add(get_result('passes/text.html'), True, test_is_slow)
        retry_results.add(get_result('failures/expected/timeout.html'), True, test_is_slow)
        retry_results.add(get_result('failures/expected/crash.html'), True, test_is_slow)
        retry_results.add(get_result('failures/expected/leak.html'), True, test_is_slow)
    else:
        retry_results = None

    return test_run_results.summarize_results(port, initial_results.expectations, initial_results, retry_results, enabled_pixel_tests_in_retry=False, only_include_failing=only_include_failing)


class InterpretTestFailuresTest(unittest.TestCase):
    def setUp(self):
        host = MockHost()
        self.port = host.port_factory.get(port_name='test')

    def test_interpret_test_failures(self):
        test_dict = test_run_results._interpret_test_failures([test_failures.FailureReftestMismatchDidNotOccur(self.port.abspath_for_test('foo/reftest-expected-mismatch.html'))])
        self.assertEqual(len(test_dict), 0)

        test_dict = test_run_results._interpret_test_failures([test_failures.FailureMissingAudio()])
        self.assertIn('is_missing_audio', test_dict)

        test_dict = test_run_results._interpret_test_failures([test_failures.FailureMissingResult()])
        self.assertIn('is_missing_text', test_dict)

        test_dict = test_run_results._interpret_test_failures([test_failures.FailureMissingImage()])
        self.assertIn('is_missing_image', test_dict)

        test_dict = test_run_results._interpret_test_failures([test_failures.FailureMissingImageHash()])
        self.assertIn('is_missing_image', test_dict)


class SummarizedResultsTest(unittest.TestCase):
    def setUp(self):
        host = MockHost(initialize_scm_by_default=False)
        self.port = host.port_factory.get(port_name='test')

    def test_no_svn_revision(self):
        summary = summarized_results(self.port, expected=False, passing=False, flaky=False)
        self.assertNotIn('revision', summary)

    def test_num_failures_by_type(self):
        summary = summarized_results(self.port, expected=False, passing=False, flaky=False)
        self.assertEquals(summary['num_failures_by_type'], {'CRASH': 1, 'MISSING': 0, 'TEXT': 0, 'IMAGE': 0, 'NEEDSREBASELINE': 0, 'NEEDSMANUALREBASELINE': 0, 'PASS': 0, 'REBASELINE': 0, 'SKIP': 0, 'SLOW': 0, 'TIMEOUT': 3, 'IMAGE+TEXT': 0, 'LEAK': 0, 'FAIL': 0, 'AUDIO': 1, 'WONTFIX': 1})

        summary = summarized_results(self.port, expected=True, passing=False, flaky=False)
        self.assertEquals(summary['num_failures_by_type'], {'CRASH': 1, 'MISSING': 0, 'TEXT': 0, 'IMAGE': 0, 'NEEDSREBASELINE': 0, 'NEEDSMANUALREBASELINE': 0, 'PASS': 1, 'REBASELINE': 0, 'SKIP': 0, 'SLOW': 0, 'TIMEOUT': 1, 'IMAGE+TEXT': 0, 'LEAK': 1, 'FAIL': 0, 'AUDIO': 1, 'WONTFIX': 0})

        summary = summarized_results(self.port, expected=False, passing=True, flaky=False)
        self.assertEquals(summary['num_failures_by_type'], {'CRASH': 0, 'MISSING': 0, 'TEXT': 0, 'IMAGE': 0, 'NEEDSREBASELINE': 0, 'NEEDSMANUALREBASELINE': 0, 'PASS': 5, 'REBASELINE': 0, 'SKIP': 1, 'SLOW': 0, 'TIMEOUT': 0, 'IMAGE+TEXT': 0, 'LEAK': 0, 'FAIL': 0, 'AUDIO': 0, 'WONTFIX': 0})

    def test_svn_revision(self):
        self.port._options.builder_name = 'dummy builder'
        summary = summarized_results(self.port, expected=False, passing=False, flaky=False)
        self.assertNotEquals(summary['blink_revision'], '')

    def test_bug_entry(self):
        self.port._options.builder_name = 'dummy builder'
        summary = summarized_results(self.port, expected=False, passing=True, flaky=False)
        self.assertEquals(summary['tests']['passes']['skipped']['skip.html']['bugs'], ['Bug(test)'])

    def test_extra_skipped_tests(self):
        self.port._options.builder_name = 'dummy builder'
        summary = summarized_results(self.port, expected=False, passing=True, flaky=False, extra_skipped_tests=['passes/text.html'])
        self.assertEquals(summary['tests']['passes']['text.html']['expected'], 'NOTRUN')

    def test_summarized_results_wontfix(self):
        self.port._options.builder_name = 'dummy builder'
        summary = summarized_results(self.port, expected=False, passing=False, flaky=False)
        self.assertEquals(summary['tests']['failures']['expected']['keyboard.html']['expected'], 'WONTFIX')
        self.assertTrue(summary['tests']['passes']['text.html']['is_unexpected'])

    def test_summarized_results_expected_pass(self):
        self.port._options.builder_name = 'dummy builder'
        summary = summarized_results(self.port, expected=False, passing=True, flaky=False)
        self.assertTrue(summary['tests']['passes']['text.html'])
        self.assertTrue('is_unexpected' not in summary['tests']['passes']['text.html'])

    def test_summarized_results_expected_only_include_failing(self):
        self.port._options.builder_name = 'dummy builder'
        summary = summarized_results(self.port, expected=True, passing=False, flaky=False, only_include_failing=True)
        self.assertNotIn('passes', summary['tests'])
        self.assertTrue(summary['tests']['failures']['expected']['audio.html'])
        self.assertTrue(summary['tests']['failures']['expected']['timeout.html'])
        self.assertTrue(summary['tests']['failures']['expected']['crash.html'])
        self.assertTrue(summary['tests']['failures']['expected']['leak.html'])

    def test_summarized_results_skipped(self):
        self.port._options.builder_name = 'dummy builder'
        summary = summarized_results(self.port, expected=False, passing=True, flaky=False)
        self.assertEquals(summary['tests']['passes']['skipped']['skip.html']['expected'], 'SKIP')

    def test_summarized_results_only_inlude_failing(self):
        self.port._options.builder_name = 'dummy builder'
        summary = summarized_results(self.port, expected=False, passing=True, flaky=False, only_include_failing=True)
        self.assertTrue('passes' not in summary['tests'])

    def test_rounded_run_times(self):
        summary = summarized_results(self.port, expected=False, passing=False, flaky=False)
        self.assertEquals(summary['tests']['passes']['text.html']['time'], 1)
        self.assertTrue('time' not in summary['tests']['failures']['expected']['audio.html'])
        self.assertEquals(summary['tests']['failures']['expected']['timeout.html']['time'], 0.1)
        self.assertTrue('time' not in summary['tests']['failures']['expected']['crash.html'])
        self.assertTrue('time' not in summary['tests']['failures']['expected']['leak.html'])

    def test_timeout_then_unexpected_pass(self):
        tests = ['failures/expected/image.html']
        expectations = test_expectations.TestExpectations(self.port, tests)
        initial_results = test_run_results.TestRunResults(expectations, len(tests))
        initial_results.add(get_result('failures/expected/image.html', test_expectations.TIMEOUT, run_time=1), False, False)
        retry_results = test_run_results.TestRunResults(expectations, len(tests))
        retry_results.add(get_result('failures/expected/image.html', test_expectations.PASS, run_time=0.1), False, False)
        summary = test_run_results.summarize_results(self.port, expectations, initial_results, retry_results, enabled_pixel_tests_in_retry=True, only_include_failing=True)
        self.assertEquals(summary['num_regressions'], 0)
        self.assertEquals(summary['num_passes'], 1)
