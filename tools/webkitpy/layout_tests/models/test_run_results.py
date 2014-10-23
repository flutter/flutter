# Copyright (C) 2010 Google Inc. All rights reserved.
# Copyright (C) 2010 Gabor Rapcsanyi (rgabor@inf.u-szeged.hu), University of Szeged
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

import logging
import signal
import time

from webkitpy.layout_tests.models import test_expectations
from webkitpy.layout_tests.models import test_failures


_log = logging.getLogger(__name__)

OK_EXIT_STATUS = 0

# This matches what the shell does on POSIX.
INTERRUPTED_EXIT_STATUS = signal.SIGINT + 128

# POSIX limits status codes to 0-255. Normally run-webkit-tests returns the number
# of tests that failed. These indicate exceptional conditions triggered by the
# script itself, so we count backwards from 255 (aka -1) to enumerate them.
#
# FIXME: crbug.com/357866. We really shouldn't return the number of failures
# in the exit code at all.
EARLY_EXIT_STATUS = 251
SYS_DEPS_EXIT_STATUS = 252
NO_TESTS_EXIT_STATUS = 253
NO_DEVICES_EXIT_STATUS = 254
UNEXPECTED_ERROR_EXIT_STATUS = 255

ERROR_CODES = (
    INTERRUPTED_EXIT_STATUS,
    EARLY_EXIT_STATUS,
    SYS_DEPS_EXIT_STATUS,
    NO_TESTS_EXIT_STATUS,
    NO_DEVICES_EXIT_STATUS,
    UNEXPECTED_ERROR_EXIT_STATUS,
)

# In order to avoid colliding with the above codes, we put a ceiling on
# the value returned by num_regressions
MAX_FAILURES_EXIT_STATUS = 101

class TestRunException(Exception):
    def __init__(self, code, msg):
        self.code = code
        self.msg = msg


class TestRunResults(object):
    def __init__(self, expectations, num_tests):
        self.total = num_tests
        self.remaining = self.total
        self.expectations = expectations
        self.expected = 0
        self.expected_failures = 0
        self.unexpected = 0
        self.unexpected_failures = 0
        self.unexpected_crashes = 0
        self.unexpected_timeouts = 0
        self.tests_by_expectation = {}
        self.tests_by_timeline = {}
        self.results_by_name = {}  # Map of test name to the last result for the test.
        self.all_results = []  # All results from a run, including every iteration of every test.
        self.unexpected_results_by_name = {}
        self.failures_by_name = {}
        self.total_failures = 0
        self.expected_skips = 0
        for expectation in test_expectations.TestExpectations.EXPECTATIONS.values():
            self.tests_by_expectation[expectation] = set()
        for timeline in test_expectations.TestExpectations.TIMELINES.values():
            self.tests_by_timeline[timeline] = expectations.get_tests_with_timeline(timeline)
        self.slow_tests = set()
        self.interrupted = False
        self.keyboard_interrupted = False
        self.run_time = 0  # The wall clock time spent running the tests (layout_test_runner.run()).

    def add(self, test_result, expected, test_is_slow):
        result_type_for_stats = test_result.type
        if test_expectations.WONTFIX in self.expectations.model().get_expectations(test_result.test_name):
            result_type_for_stats = test_expectations.WONTFIX
        self.tests_by_expectation[result_type_for_stats].add(test_result.test_name)

        self.results_by_name[test_result.test_name] = test_result
        if test_result.type != test_expectations.SKIP:
            self.all_results.append(test_result)
        self.remaining -= 1
        if len(test_result.failures):
            self.total_failures += 1
            self.failures_by_name[test_result.test_name] = test_result.failures
        if expected:
            self.expected += 1
            if test_result.type == test_expectations.SKIP:
                self.expected_skips += 1
            elif test_result.type != test_expectations.PASS:
                self.expected_failures += 1
        else:
            self.unexpected_results_by_name[test_result.test_name] = test_result
            self.unexpected += 1
            if len(test_result.failures):
                self.unexpected_failures += 1
            if test_result.type == test_expectations.CRASH:
                self.unexpected_crashes += 1
            elif test_result.type == test_expectations.TIMEOUT:
                self.unexpected_timeouts += 1
        if test_is_slow:
            self.slow_tests.add(test_result.test_name)


class RunDetails(object):
    def __init__(self, exit_code, summarized_full_results=None, summarized_failing_results=None, initial_results=None, retry_results=None, enabled_pixel_tests_in_retry=False):
        self.exit_code = exit_code
        self.summarized_full_results = summarized_full_results
        self.summarized_failing_results = summarized_failing_results
        self.initial_results = initial_results
        self.retry_results = retry_results
        self.enabled_pixel_tests_in_retry = enabled_pixel_tests_in_retry


def _interpret_test_failures(failures):
    test_dict = {}
    failure_types = [type(failure) for failure in failures]
    # FIXME: get rid of all this is_* values once there is a 1:1 map between
    # TestFailure type and test_expectations.EXPECTATION.
    if test_failures.FailureMissingAudio in failure_types:
        test_dict['is_missing_audio'] = True

    if test_failures.FailureMissingResult in failure_types:
        test_dict['is_missing_text'] = True

    if test_failures.FailureMissingImage in failure_types or test_failures.FailureMissingImageHash in failure_types:
        test_dict['is_missing_image'] = True

    if test_failures.FailureTestHarnessAssertion in failure_types:
        test_dict['is_testharness_test'] = True

    return test_dict


def summarize_results(port_obj, expectations, initial_results, retry_results, enabled_pixel_tests_in_retry, only_include_failing=False):
    """Returns a dictionary containing a summary of the test runs, with the following fields:
        'version': a version indicator
        'fixable': The number of fixable tests (NOW - PASS)
        'skipped': The number of skipped tests (NOW & SKIPPED)
        'num_regressions': The number of non-flaky failures
        'num_flaky': The number of flaky failures
        'num_passes': The number of unexpected passes
        'tests': a dict of tests -> {'expected': '...', 'actual': '...'}
    """
    results = {}
    results['version'] = 3

    tbe = initial_results.tests_by_expectation
    tbt = initial_results.tests_by_timeline
    results['fixable'] = len(tbt[test_expectations.NOW] - tbe[test_expectations.PASS])
    # FIXME: Remove this. It is redundant with results['num_failures_by_type'].
    results['skipped'] = len(tbt[test_expectations.NOW] & tbe[test_expectations.SKIP])

    num_passes = 0
    num_flaky = 0
    num_regressions = 0
    keywords = {}
    for expecation_string, expectation_enum in test_expectations.TestExpectations.EXPECTATIONS.iteritems():
        keywords[expectation_enum] = expecation_string.upper()

    num_failures_by_type = {}
    for expectation in initial_results.tests_by_expectation:
        tests = initial_results.tests_by_expectation[expectation]
        if expectation != test_expectations.WONTFIX:
            tests &= tbt[test_expectations.NOW]
        num_failures_by_type[keywords[expectation]] = len(tests)
    # The number of failures by type.
    results['num_failures_by_type'] = num_failures_by_type

    tests = {}

    for test_name, result in initial_results.results_by_name.iteritems():
        expected = expectations.get_expectations_string(test_name)
        result_type = result.type
        actual = [keywords[result_type]]

        if only_include_failing and result.type == test_expectations.SKIP:
            continue

        if result_type == test_expectations.PASS:
            num_passes += 1
            if not result.has_stderr and only_include_failing:
                continue
        elif result_type != test_expectations.SKIP and test_name in initial_results.unexpected_results_by_name:
            if retry_results:
                if test_name not in retry_results.unexpected_results_by_name:
                    # The test failed unexpectedly at first, but ran as expected the second time -> flaky.
                    actual.extend(expectations.get_expectations_string(test_name).split(" "))
                    num_flaky += 1
                else:
                    retry_result_type = retry_results.unexpected_results_by_name[test_name].type
                    if retry_result_type == test_expectations.PASS:
                        #  The test failed unexpectedly at first, then passed unexpectedly -> unexpected pass.
                        num_passes += 1
                        if not result.has_stderr and only_include_failing:
                            continue
                    else:
                        # The test failed unexpectedly both times -> regression.
                        num_regressions += 1
                        if not keywords[retry_result_type] in actual:
                            actual.append(keywords[retry_result_type])
            else:
                # The test failed unexpectedly, but we didn't do any retries -> regression.
                num_regressions += 1

        test_dict = {}

        rounded_run_time = round(result.test_run_time, 1)
        if rounded_run_time:
            test_dict['time'] = rounded_run_time

        if result.has_stderr:
            test_dict['has_stderr'] = True

        bugs = expectations.model().get_expectation_line(test_name).bugs
        if bugs:
            test_dict['bugs'] = bugs

        if result.reftest_type:
            test_dict.update(reftest_type=list(result.reftest_type))

        test_dict['expected'] = expected
        test_dict['actual'] = " ".join(actual)

        def is_expected(actual_result):
            return expectations.matches_an_expected_result(test_name, result_type,
                port_obj.get_option('pixel_tests') or result.reftest_type,
                port_obj.get_option('enable_sanitizer'))

        # To avoid bloating the output results json too much, only add an entry for whether the failure is unexpected.
        if not all(is_expected(actual_result) for actual_result in actual):
            test_dict['is_unexpected'] = True

        test_dict.update(_interpret_test_failures(result.failures))

        if retry_results:
            retry_result = retry_results.unexpected_results_by_name.get(test_name)
            if retry_result:
                test_dict.update(_interpret_test_failures(retry_result.failures))

        if (result.has_repaint_overlay):
            test_dict['has_repaint_overlay'] = True

        # Store test hierarchically by directory. e.g.
        # foo/bar/baz.html: test_dict
        # foo/bar/baz1.html: test_dict
        #
        # becomes
        # foo: {
        #     bar: {
        #         baz.html: test_dict,
        #         baz1.html: test_dict
        #     }
        # }
        parts = test_name.split('/')
        current_map = tests
        for i, part in enumerate(parts):
            if i == (len(parts) - 1):
                current_map[part] = test_dict
                break
            if part not in current_map:
                current_map[part] = {}
            current_map = current_map[part]

    results['tests'] = tests
    # FIXME: Remove this. It is redundant with results['num_failures_by_type'].
    results['num_passes'] = num_passes
    results['num_flaky'] = num_flaky
    # FIXME: Remove this. It is redundant with results['num_failures_by_type'].
    results['num_regressions'] = num_regressions
    results['interrupted'] = initial_results.interrupted  # Does results.html have enough information to compute this itself? (by checking total number of results vs. total number of tests?)
    results['layout_tests_dir'] = port_obj.layout_tests_dir()
    results['has_wdiff'] = port_obj.wdiff_available()
    results['has_pretty_patch'] = port_obj.pretty_patch_available()
    results['pixel_tests_enabled'] = port_obj.get_option('pixel_tests')
    results['seconds_since_epoch'] = int(time.time())
    results['build_number'] = port_obj.get_option('build_number')
    results['builder_name'] = port_obj.get_option('builder_name')

    # Don't do this by default since it takes >100ms.
    # It's only used for uploading data to the flakiness dashboard.
    results['chromium_revision'] = ''
    results['blink_revision'] = ''
    if port_obj.get_option('builder_name'):
        for (name, path) in port_obj.repository_paths():
            scm = port_obj.host.scm_for_path(path)
            if scm:
                rev = scm.svn_revision(path)
            if rev:
                results[name.lower() + '_revision'] = rev
            else:
                _log.warn('Failed to determine svn revision for %s, '
                          'leaving "%s_revision" key blank in full_results.json.'
                          % (path, name))

    return results
