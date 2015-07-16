# Copyright (C) 2010, 2012 Google Inc. All rights reserved.
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

"""Package that handles non-debug, non-file output for run-webkit-tests."""

import math
import optparse

from webkitpy.tool import grammar
from webkitpy.layout_tests.models import test_expectations
from webkitpy.layout_tests.models.test_expectations import TestExpectations, TestExpectationParser
from webkitpy.layout_tests.views.metered_stream import MeteredStream


NUM_SLOW_TESTS_TO_LOG = 10


def print_options():
    return [
        optparse.make_option('-q', '--quiet', action='store_true', default=False,
                             help='run quietly (errors, warnings, and progress only)'),
        optparse.make_option('--timing', action='store_true', default=False,
                             help='display test times (summary plus per-test w/ --verbose)'),
        optparse.make_option('-v', '--verbose', action='store_true', default=False,
                             help='print a summarized result for every test (one line per test)'),
        optparse.make_option('--details', action='store_true', default=False,
                             help='print detailed results for every test'),
        optparse.make_option('--debug-rwt-logging', action='store_true', default=False,
                             help='print timestamps and debug information for run-webkit-tests itself'),
    ]


class Printer(object):
    """Class handling all non-debug-logging printing done by run-webkit-tests."""

    def __init__(self, port, options, regular_output, logger=None):
        self.num_completed = 0
        self.num_tests = 0
        self._port = port
        self._options = options
        self._meter = MeteredStream(regular_output, options.debug_rwt_logging, logger=logger,
                                    number_of_columns=self._port.host.platform.terminal_width())
        self._running_tests = []
        self._completed_tests = []

    def cleanup(self):
        self._meter.cleanup()

    def __del__(self):
        self.cleanup()

    def print_config(self, results_directory):
        self._print_default("Using port '%s'" % self._port.name())
        self._print_default("Test configuration: %s" % self._port.test_configuration())
        self._print_default("View the test results at file://%s/results.html" % results_directory)

        if self._options.enable_versioned_results:
            self._print_default("View the archived results dashboard at file://%s/dashboard.html" % results_directory)

        # FIXME: should these options be in printing_options?
        if self._options.new_baseline:
            self._print_default("Placing new baselines in %s" % self._port.baseline_path())

        fs = self._port.host.filesystem
        fallback_path = [fs.split(x)[1] for x in self._port.baseline_search_path()]
        self._print_default("Baseline search path: %s -> generic" % " -> ".join(fallback_path))

        self._print_default("Using %s build" % self._options.configuration)
        if self._options.pixel_tests:
            self._print_default("Pixel tests enabled")
        else:
            self._print_default("Pixel tests disabled")

        self._print_default("Regular timeout: %s, slow test timeout: %s" %
                  (self._options.time_out_ms, self._options.slow_time_out_ms))

        self._print_default('Command line: ' + ' '.join(self._port.driver_cmd_line()))
        self._print_default('')

    def print_found(self, num_all_test_files, num_to_run, repeat_each, iterations):
        found_str = 'Found %s; running %d' % (grammar.pluralize('test', num_all_test_files), num_to_run)
        if repeat_each * iterations > 1:
            found_str += ' (%d times each: --repeat-each=%d --iterations=%d)' % (repeat_each * iterations, repeat_each, iterations)
        found_str += ', skipping %d' % (num_all_test_files - num_to_run)
        self._print_default(found_str + '.')

    def print_expected(self, run_results, tests_with_result_type_callback):
        self._print_expected_results_of_type(run_results, test_expectations.PASS, "passes", tests_with_result_type_callback)
        self._print_expected_results_of_type(run_results, test_expectations.FAIL, "failures", tests_with_result_type_callback)
        self._print_expected_results_of_type(run_results, test_expectations.FLAKY, "flaky", tests_with_result_type_callback)
        self._print_debug('')

    def print_workers_and_shards(self, num_workers, num_shards, num_locked_shards):
        driver_name = self._port.driver_name()
        if num_workers == 1:
            self._print_default("Running 1 %s." % driver_name)
            self._print_debug("(%s)." % grammar.pluralize('shard', num_shards))
        else:
            self._print_default("Running %d %ss in parallel." % (num_workers, driver_name))
            self._print_debug("(%d shards; %d locked)." % (num_shards, num_locked_shards))
        self._print_default('')

    def _print_expected_results_of_type(self, run_results, result_type, result_type_str, tests_with_result_type_callback):
        tests = tests_with_result_type_callback(result_type)
        now = run_results.tests_by_timeline[test_expectations.NOW]
        wontfix = run_results.tests_by_timeline[test_expectations.WONTFIX]

        # We use a fancy format string in order to print the data out in a
        # nicely-aligned table.
        fmtstr = ("Expect: %%5d %%-8s (%%%dd now, %%%dd wontfix)"
                  % (self._num_digits(now), self._num_digits(wontfix)))
        self._print_debug(fmtstr % (len(tests), result_type_str, len(tests & now), len(tests & wontfix)))

    def _num_digits(self, num):
        ndigits = 1
        if len(num):
            ndigits = int(math.log10(len(num))) + 1
        return ndigits

    def print_results(self, run_time, run_results, summarized_results):
        self._print_timing_statistics(run_time, run_results)
        self._print_one_line_summary(run_time, run_results)

    def _print_timing_statistics(self, total_time, run_results):
        self._print_debug("Test timing:")
        self._print_debug("  %6.2f total testing time" % total_time)
        self._print_debug("")

        self._print_worker_statistics(run_results, int(self._options.child_processes))
        self._print_aggregate_test_statistics(run_results)
        self._print_individual_test_times(run_results)
        self._print_directory_timings(run_results)

    def _print_worker_statistics(self, run_results, num_workers):
        self._print_debug("Thread timing:")
        stats = {}
        cuml_time = 0
        for result in run_results.results_by_name.values():
            stats.setdefault(result.worker_name, {'num_tests': 0, 'total_time': 0})
            stats[result.worker_name]['num_tests'] += 1
            stats[result.worker_name]['total_time'] += result.total_run_time
            cuml_time += result.total_run_time

        for worker_name in stats:
            self._print_debug("    %10s: %5d tests, %6.2f secs" % (worker_name, stats[worker_name]['num_tests'], stats[worker_name]['total_time']))
        self._print_debug("   %6.2f cumulative, %6.2f optimal" % (cuml_time, cuml_time / num_workers))
        self._print_debug("")

    def _print_aggregate_test_statistics(self, run_results):
        times_for_dump_render_tree = [result.test_run_time for result in run_results.results_by_name.values()]
        self._print_statistics_for_test_timings("PER TEST TIME IN TESTSHELL (seconds):", times_for_dump_render_tree)

    def _print_individual_test_times(self, run_results):
        # Reverse-sort by the time spent in the driver.

        individual_test_timings = sorted(run_results.results_by_name.values(), key=lambda result: result.test_run_time, reverse=True)
        num_printed = 0
        slow_tests = []
        timeout_or_crash_tests = []
        unexpected_slow_tests = []
        for test_tuple in individual_test_timings:
            test_name = test_tuple.test_name
            is_timeout_crash_or_slow = False
            if test_name in run_results.slow_tests:
                is_timeout_crash_or_slow = True
                slow_tests.append(test_tuple)

            if test_name in run_results.failures_by_name:
                result = run_results.results_by_name[test_name].type
                if (result == test_expectations.TIMEOUT or
                    result == test_expectations.CRASH):
                    is_timeout_crash_or_slow = True
                    timeout_or_crash_tests.append(test_tuple)

            if (not is_timeout_crash_or_slow and num_printed < NUM_SLOW_TESTS_TO_LOG):
                num_printed = num_printed + 1
                unexpected_slow_tests.append(test_tuple)

        self._print_debug("")
        if unexpected_slow_tests:
            self._print_test_list_timing("%s slowest tests that are not marked as SLOW and did not timeout/crash:" %
                NUM_SLOW_TESTS_TO_LOG, unexpected_slow_tests)
            self._print_debug("")

        if slow_tests:
            self._print_test_list_timing("Tests marked as SLOW:", slow_tests)
            self._print_debug("")

        if timeout_or_crash_tests:
            self._print_test_list_timing("Tests that timed out or crashed:", timeout_or_crash_tests)
            self._print_debug("")

    def _print_test_list_timing(self, title, test_list):
        self._print_debug(title)
        for test_tuple in test_list:
            test_run_time = round(test_tuple.test_run_time, 1)
            self._print_debug("  %s took %s seconds" % (test_tuple.test_name, test_run_time))

    def _print_directory_timings(self, run_results):
        stats = {}
        for result in run_results.results_by_name.values():
            stats.setdefault(result.shard_name, {'num_tests': 0, 'total_time': 0})
            stats[result.shard_name]['num_tests'] += 1
            stats[result.shard_name]['total_time'] += result.total_run_time

        min_seconds_to_print = 15

        timings = []
        for directory in stats:
            rounded_time = round(stats[directory]['total_time'], 1)
            if rounded_time > min_seconds_to_print:
                timings.append((directory, rounded_time, stats[directory]['num_tests']))

        if not timings:
            return

        timings.sort()

        self._print_debug("Time to process slowest subdirectories:")
        for timing in timings:
            self._print_debug("  %s took %s seconds to run %s tests." % timing)
        self._print_debug("")

    def _print_statistics_for_test_timings(self, title, timings):
        self._print_debug(title)
        timings.sort()

        num_tests = len(timings)
        if not num_tests:
            return
        percentile90 = timings[int(.9 * num_tests)]
        percentile99 = timings[int(.99 * num_tests)]

        if num_tests % 2 == 1:
            median = timings[((num_tests - 1) / 2) - 1]
        else:
            lower = timings[num_tests / 2 - 1]
            upper = timings[num_tests / 2]
            median = (float(lower + upper)) / 2

        mean = sum(timings) / num_tests

        for timing in timings:
            sum_of_deviations = math.pow(timing - mean, 2)

        std_deviation = math.sqrt(sum_of_deviations / num_tests)
        self._print_debug("  Median:          %6.3f" % median)
        self._print_debug("  Mean:            %6.3f" % mean)
        self._print_debug("  90th percentile: %6.3f" % percentile90)
        self._print_debug("  99th percentile: %6.3f" % percentile99)
        self._print_debug("  Standard dev:    %6.3f" % std_deviation)
        self._print_debug("")

    def _print_one_line_summary(self, total_time, run_results):
        if self._options.timing:
            parallel_time = sum(result.total_run_time for result in run_results.results_by_name.values())

            # There is serial overhead in layout_test_runner.run() that we can't easily account for when
            # really running in parallel, but taking the min() ensures that in the worst case
            # (if parallel time is less than run_time) we do account for it.
            serial_time = total_time - min(run_results.run_time, parallel_time)

            speedup = (parallel_time + serial_time) / total_time
            timing_summary = ' in %.2fs (%.2fs in rwt, %.2gx)' % (total_time, serial_time, speedup)
        else:
            timing_summary = ''

        total = run_results.total - run_results.expected_skips
        expected = run_results.expected - run_results.expected_skips
        unexpected = run_results.unexpected
        incomplete = total - expected - unexpected
        incomplete_str = ''
        if incomplete:
            self._print_default("")
            incomplete_str = " (%d didn't run)" % incomplete

        if self._options.verbose or self._options.debug_rwt_logging or unexpected:
            self.writeln("")

        expected_summary_str = ''
        if run_results.expected_failures > 0:
            expected_summary_str = " (%d passed, %d didn't)" % (expected - run_results.expected_failures, run_results.expected_failures)

        summary = ''
        if unexpected == 0:
            if expected == total:
                if expected > 1:
                    summary = "All %d tests ran as expected%s%s." % (expected, expected_summary_str, timing_summary)
                else:
                    summary = "The test ran as expected%s%s." % (expected_summary_str, timing_summary)
            else:
                summary = "%s ran as expected%s%s%s." % (grammar.pluralize('test', expected), expected_summary_str, incomplete_str, timing_summary)
        else:
            summary = "%s ran as expected%s, %d didn't%s%s:" % (grammar.pluralize('test', expected), expected_summary_str, unexpected, incomplete_str, timing_summary)

        self._print_quiet(summary)
        self._print_quiet("")

    def _test_status_line(self, test_name, suffix):
        format_string = '[%d/%d] %s%s'
        status_line = format_string % (self.num_completed, self.num_tests, test_name, suffix)
        if len(status_line) > self._meter.number_of_columns():
            overflow_columns = len(status_line) - self._meter.number_of_columns()
            ellipsis = '...'
            if len(test_name) < overflow_columns + len(ellipsis) + 2:
                # We don't have enough space even if we elide, just show the test filename.
                fs = self._port.host.filesystem
                test_name = fs.split(test_name)[1]
            else:
                new_length = len(test_name) - overflow_columns - len(ellipsis)
                prefix = int(new_length / 2)
                test_name = test_name[:prefix] + ellipsis + test_name[-(new_length - prefix):]
        return format_string % (self.num_completed, self.num_tests, test_name, suffix)

    def print_started_test(self, test_name):
        self._running_tests.append(test_name)
        if len(self._running_tests) > 1:
            suffix = ' (+%d)' % (len(self._running_tests) - 1)
        else:
            suffix = ''
        if self._options.verbose:
            write = self._meter.write_update
        else:
            write = self._meter.write_throttled_update
        write(self._test_status_line(test_name, suffix))

    def print_finished_test(self, result, expected, exp_str, got_str):
        self.num_completed += 1
        test_name = result.test_name

        result_message = self._result_message(result.type, result.failures, expected,
                                              self._options.timing, result.test_run_time)

        if self._options.details:
            self._print_test_trace(result, exp_str, got_str)
        elif self._options.verbose or not expected:
            self.writeln(self._test_status_line(test_name, result_message))
        elif self.num_completed == self.num_tests:
            self._meter.write_update('')
        else:
            if test_name == self._running_tests[0]:
                self._completed_tests.insert(0, [test_name, result_message])
            else:
                self._completed_tests.append([test_name, result_message])

            for test_name, result_message in self._completed_tests:
                self._meter.write_throttled_update(self._test_status_line(test_name, result_message))
            self._completed_tests = []
        self._running_tests.remove(test_name)

    def _result_message(self, result_type, failures, expected, timing, test_run_time):
        exp_string = ' unexpectedly' if not expected else ''
        timing_string = ' %.4fs' % test_run_time if timing else ''
        if result_type == test_expectations.PASS:
            return ' passed%s%s' % (exp_string, timing_string)
        else:
            return ' failed%s (%s)%s' % (exp_string, ', '.join(failure.message() for failure in failures), timing_string)

    def _print_test_trace(self, result, exp_str, got_str):
        test_name = result.test_name
        self._print_default(self._test_status_line(test_name, ''))

        base = self._port.lookup_virtual_test_base(test_name)
        if base:
            args = ' '.join(self._port.lookup_virtual_test_args(test_name))
            self._print_default(' base: %s' % base)
            self._print_default(' args: %s' % args)

        references = self._port.reference_files(test_name)
        if references:
            for _, filename in references:
                self._print_default('  ref: %s' % self._port.relative_test_filename(filename))
        else:
            for extension in ('.txt', '.png', '.wav'):
                    self._print_baseline(test_name, extension)

        self._print_default('  exp: %s' % exp_str)
        self._print_default('  got: %s' % got_str)
        self._print_default(' took: %-.3f' % result.test_run_time)
        self._print_default('')

    def _print_baseline(self, test_name, extension):
        baseline = self._port.expected_filename(test_name, extension)
        if self._port._filesystem.exists(baseline):
            relpath = self._port.relative_test_filename(baseline)
        else:
            relpath = '<none>'
        self._print_default('  %s: %s' % (extension[1:], relpath))

    def _print_quiet(self, msg):
        self.writeln(msg)

    def _print_default(self, msg):
        if not self._options.quiet:
            self.writeln(msg)

    def _print_debug(self, msg):
        if self._options.debug_rwt_logging:
            self.writeln(msg)

    def write_throttled_update(self, msg):
        self._meter.write_throttled_update(msg)

    def write_update(self, msg):
        self._meter.write_update(msg)

    def writeln(self, msg):
        self._meter.writeln(msg)

    def flush(self):
        self._meter.flush()
