# Copyright (C) 2010 Google Inc. All rights reserved.
# Copyright (C) 2010 Gabor Rapcsanyi (rgabor@inf.u-szeged.hu), University of Szeged
# Copyright (C) 2011 Apple Inc. All rights reserved.
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

import Queue
import StringIO
import codecs
import json
import logging
import os
import platform
import re
import sys
import thread
import time
import threading
import unittest

from webkitpy.common.system import outputcapture, path
from webkitpy.common.system.crashlogs_unittest import make_mock_crash_report_darwin
from webkitpy.common.system.systemhost import SystemHost
from webkitpy.common.host import Host
from webkitpy.common.host_mock import MockHost

from webkitpy.layout_tests import port
from webkitpy.layout_tests import run_webkit_tests
from webkitpy.layout_tests.models import test_run_results
from webkitpy.layout_tests.port import Port
from webkitpy.layout_tests.port import test
from webkitpy.test.skip import skip_if
from webkitpy.tool import grammar
from webkitpy.tool.mocktool import MockOptions


def parse_args(extra_args=None, tests_included=False, new_results=False, print_nothing=True):
    extra_args = extra_args or []
    args = []
    if not '--platform' in extra_args:
        args.extend(['--platform', 'test'])
    if not new_results:
        args.append('--no-new-test-results')

    if not '--child-processes' in extra_args:
        args.extend(['--child-processes', 1])
    args.extend(extra_args)
    if not tests_included:
        # We use the glob to test that globbing works.
        args.extend(['passes',
                     'http/tests',
                     'websocket/tests',
                     'failures/expected/*'])
    return run_webkit_tests.parse_args(args)


def passing_run(extra_args=None, port_obj=None, tests_included=False, host=None, shared_port=True):
    options, parsed_args = parse_args(extra_args, tests_included)
    if not port_obj:
        host = host or MockHost()
        port_obj = host.port_factory.get(port_name=options.platform, options=options)

    if shared_port:
        port_obj.host.port_factory.get = lambda *args, **kwargs: port_obj

    logging_stream = StringIO.StringIO()
    run_details = run_webkit_tests.run(port_obj, options, parsed_args, logging_stream=logging_stream)
    return run_details.exit_code == 0


def logging_run(extra_args=None, port_obj=None, tests_included=False, host=None, new_results=False, shared_port=True):
    options, parsed_args = parse_args(extra_args=extra_args,
                                      tests_included=tests_included,
                                      print_nothing=False, new_results=new_results)
    host = host or MockHost()
    if not port_obj:
        port_obj = host.port_factory.get(port_name=options.platform, options=options)

    run_details, output = run_and_capture(port_obj, options, parsed_args, shared_port)
    return (run_details, output, host.user)


def run_and_capture(port_obj, options, parsed_args, shared_port=True):
    if shared_port:
        port_obj.host.port_factory.get = lambda *args, **kwargs: port_obj
    oc = outputcapture.OutputCapture()
    try:
        oc.capture_output()
        logging_stream = StringIO.StringIO()
        run_details = run_webkit_tests.run(port_obj, options, parsed_args, logging_stream=logging_stream)
    finally:
        oc.restore_output()
    return (run_details, logging_stream)


def get_tests_run(args, host=None, port_obj=None):
    results = get_test_results(args, host=host, port_obj=port_obj)
    return [result.test_name for result in results]


def get_test_batches(args, host=None):
    results = get_test_results(args, host)
    batches = []
    batch = []
    current_pid = None
    for result in results:
        if batch and result.pid != current_pid:
            batches.append(batch)
            batch = []
        batch.append(result.test_name)
    if batch:
        batches.append(batch)
    return batches


def get_test_results(args, host=None, port_obj=None):
    options, parsed_args = parse_args(args, tests_included=True)

    host = host or MockHost()
    port_obj = port_obj or host.port_factory.get(port_name=options.platform, options=options)

    oc = outputcapture.OutputCapture()
    oc.capture_output()
    logging_stream = StringIO.StringIO()
    try:
        run_details = run_webkit_tests.run(port_obj, options, parsed_args, logging_stream=logging_stream)
    finally:
        oc.restore_output()

    all_results = []
    if run_details.initial_results:
        all_results.extend(run_details.initial_results.all_results)

    if run_details.retry_results:
        all_results.extend(run_details.retry_results.all_results)
    return all_results


def parse_full_results(full_results_text):
    json_to_eval = full_results_text.replace("ADD_RESULTS(", "").replace(");", "")
    compressed_results = json.loads(json_to_eval)
    return compressed_results


class StreamTestingMixin(object):
    def assertContains(self, stream, string):
        self.assertTrue(string in stream.getvalue())

    def assertEmpty(self, stream):
        self.assertFalse(stream.getvalue())

    def assertNotEmpty(self, stream):
        self.assertTrue(stream.getvalue())


class RunTest(unittest.TestCase, StreamTestingMixin):
    def setUp(self):
        # A real PlatformInfo object is used here instead of a
        # MockPlatformInfo because we need to actually check for
        # Windows and Mac to skip some tests.
        self._platform = SystemHost().platform

        # FIXME: Remove this when we fix test-webkitpy to work
        # properly on cygwin (bug 63846).
        self.should_test_processes = not self._platform.is_win()

    def test_basic(self):
        options, args = parse_args(tests_included=True)
        logging_stream = StringIO.StringIO()
        host = MockHost()
        port_obj = host.port_factory.get(options.platform, options)
        details = run_webkit_tests.run(port_obj, options, args, logging_stream)

        # These numbers will need to be updated whenever we add new tests.
        self.assertEqual(details.initial_results.total, test.TOTAL_TESTS)
        self.assertEqual(details.initial_results.expected_skips, test.TOTAL_SKIPS)
        self.assertEqual(len(details.initial_results.unexpected_results_by_name), test.UNEXPECTED_PASSES + test.UNEXPECTED_FAILURES)
        self.assertEqual(details.exit_code, test.UNEXPECTED_FAILURES)
        self.assertEqual(details.retry_results.total, test.UNEXPECTED_FAILURES)

        expected_tests = details.initial_results.total - details.initial_results.expected_skips - len(details.initial_results.unexpected_results_by_name)
        expected_summary_str = ''
        if details.initial_results.expected_failures > 0:
            expected_summary_str = " (%d passed, %d didn't)" % (expected_tests - details.initial_results.expected_failures, details.initial_results.expected_failures)
        one_line_summary = "%d tests ran as expected%s, %d didn't:\n" % (
            expected_tests,
            expected_summary_str,
            len(details.initial_results.unexpected_results_by_name))
        self.assertTrue(one_line_summary in logging_stream.buflist)

        # Ensure the results were summarized properly.
        self.assertEqual(details.summarized_failing_results['num_regressions'], details.exit_code)

        # Ensure the results were written out and displayed.
        failing_results_text = host.filesystem.read_text_file('/tmp/layout-test-results/failing_results.json')
        json_to_eval = failing_results_text.replace("ADD_RESULTS(", "").replace(");", "")
        self.assertEqual(json.loads(json_to_eval), details.summarized_failing_results)

        full_results_text = host.filesystem.read_text_file('/tmp/layout-test-results/full_results.json')
        self.assertEqual(json.loads(full_results_text), details.summarized_full_results)

        self.assertEqual(host.user.opened_urls, [path.abspath_to_uri(MockHost().platform, '/tmp/layout-test-results/results.html')])

    def test_batch_size(self):
        batch_tests_run = get_test_batches(['--batch-size', '2'])
        for batch in batch_tests_run:
            self.assertTrue(len(batch) <= 2, '%s had too many tests' % ', '.join(batch))

    def test_max_locked_shards(self):
        # Tests for the default of using one locked shard even in the case of more than one child process.
        if not self.should_test_processes:
            return
        save_env_webkit_test_max_locked_shards = None
        if "WEBKIT_TEST_MAX_LOCKED_SHARDS" in os.environ:
            save_env_webkit_test_max_locked_shards = os.environ["WEBKIT_TEST_MAX_LOCKED_SHARDS"]
            del os.environ["WEBKIT_TEST_MAX_LOCKED_SHARDS"]
        _, regular_output, _ = logging_run(['--debug-rwt-logging', '--child-processes', '2'], shared_port=False)
        try:
            self.assertTrue(any(['1 locked' in line for line in regular_output.buflist]))
        finally:
            if save_env_webkit_test_max_locked_shards:
                os.environ["WEBKIT_TEST_MAX_LOCKED_SHARDS"] = save_env_webkit_test_max_locked_shards

    def test_child_processes_2(self):
        if self.should_test_processes:
            _, regular_output, _ = logging_run(
                ['--debug-rwt-logging', '--child-processes', '2'], shared_port=False)
            self.assertTrue(any(['Running 2 ' in line for line in regular_output.buflist]))

    def test_child_processes_min(self):
        if self.should_test_processes:
            _, regular_output, _ = logging_run(
                ['--debug-rwt-logging', '--child-processes', '2', '-i', 'passes/passes', 'passes'],
                tests_included=True, shared_port=False)
            self.assertTrue(any(['Running 1 ' in line for line in regular_output.buflist]))

    def test_dryrun(self):
        tests_run = get_tests_run(['--dry-run'])
        self.assertEqual(tests_run, [])

        tests_run = get_tests_run(['-n'])
        self.assertEqual(tests_run, [])

    def test_enable_sanitizer(self):
        self.assertTrue(passing_run(['--enable-sanitizer', 'failures/expected/text.html']))

    def test_exception_raised(self):
        # Exceptions raised by a worker are treated differently depending on
        # whether they are in-process or out. inline exceptions work as normal,
        # which allows us to get the full stack trace and traceback from the
        # worker. The downside to this is that it could be any error, but this
        # is actually useful in testing.
        #
        # Exceptions raised in a separate process are re-packaged into
        # WorkerExceptions (a subclass of BaseException), which have a string capture of the stack which can
        # be printed, but don't display properly in the unit test exception handlers.
        self.assertRaises(BaseException, logging_run,
            ['failures/expected/exception.html', '--child-processes', '1'], tests_included=True)

        if self.should_test_processes:
            self.assertRaises(BaseException, logging_run,
                ['--child-processes', '2', '--skipped=ignore', 'failures/expected/exception.html', 'passes/text.html'], tests_included=True, shared_port=False)

    def test_device_failure(self):
        # Test that we handle a device going offline during a test properly.
        details, regular_output, _ = logging_run(['failures/expected/device_failure.html'], tests_included=True)
        self.assertEqual(details.exit_code, 0)
        self.assertTrue('worker/0 has failed' in regular_output.getvalue())

    def test_full_results_html(self):
        host = MockHost()
        details, _, _ = logging_run(['--full-results-html'], host=host)
        self.assertEqual(details.exit_code, 0)
        self.assertEqual(len(host.user.opened_urls), 1)

    def test_keyboard_interrupt(self):
        # Note that this also tests running a test marked as SKIP if
        # you specify it explicitly.
        details, _, _ = logging_run(['failures/expected/keyboard.html', '--child-processes', '1'], tests_included=True)
        self.assertEqual(details.exit_code, test_run_results.INTERRUPTED_EXIT_STATUS)

        if self.should_test_processes:
            _, regular_output, _ = logging_run(['failures/expected/keyboard.html', 'passes/text.html', '--child-processes', '2', '--skipped=ignore'], tests_included=True, shared_port=False)
            self.assertTrue(any(['Interrupted, exiting' in line for line in regular_output.buflist]))

    def test_no_tests_found(self):
        details, err, _ = logging_run(['resources'], tests_included=True)
        self.assertEqual(details.exit_code, test_run_results.NO_TESTS_EXIT_STATUS)
        self.assertContains(err, 'No tests to run.\n')

    def test_no_tests_found_2(self):
        details, err, _ = logging_run(['foo'], tests_included=True)
        self.assertEqual(details.exit_code, test_run_results.NO_TESTS_EXIT_STATUS)
        self.assertContains(err, 'No tests to run.\n')

    def test_no_tests_found_3(self):
        details, err, _ = logging_run(['--run-chunk', '5:400', 'foo/bar.html'], tests_included=True)
        self.assertEqual(details.exit_code, test_run_results.NO_TESTS_EXIT_STATUS)
        self.assertContains(err, 'No tests to run.\n')

    def test_natural_order(self):
        tests_to_run = ['passes/audio.html', 'failures/expected/text.html', 'failures/expected/missing_text.html', 'passes/args.html']
        tests_run = get_tests_run(['--order=natural'] + tests_to_run)
        self.assertEqual(['failures/expected/missing_text.html', 'failures/expected/text.html', 'passes/args.html', 'passes/audio.html'], tests_run)

    def test_natural_order_test_specified_multiple_times(self):
        tests_to_run = ['passes/args.html', 'passes/audio.html', 'passes/audio.html', 'passes/args.html']
        tests_run = get_tests_run(['--order=natural'] + tests_to_run)
        self.assertEqual(['passes/args.html', 'passes/args.html', 'passes/audio.html', 'passes/audio.html'], tests_run)

    def test_random_order(self):
        tests_to_run = ['passes/audio.html', 'failures/expected/text.html', 'failures/expected/missing_text.html', 'passes/args.html']
        tests_run = get_tests_run(['--order=random'] + tests_to_run)
        self.assertEqual(sorted(tests_to_run), sorted(tests_run))

    def test_random_daily_seed_order(self):
        tests_to_run = ['passes/audio.html', 'failures/expected/text.html', 'failures/expected/missing_text.html', 'passes/args.html']
        tests_run = get_tests_run(['--order=random-seeded'] + tests_to_run)
        self.assertEqual(sorted(tests_to_run), sorted(tests_run))

    def test_random_order_test_specified_multiple_times(self):
        tests_to_run = ['passes/args.html', 'passes/audio.html', 'passes/audio.html', 'passes/args.html']
        tests_run = get_tests_run(['--order=random'] + tests_to_run)
        self.assertEqual(tests_run.count('passes/audio.html'), 2)
        self.assertEqual(tests_run.count('passes/args.html'), 2)

    def test_no_order(self):
        tests_to_run = ['passes/audio.html', 'failures/expected/text.html', 'failures/expected/missing_text.html', 'passes/args.html']
        tests_run = get_tests_run(['--order=none'] + tests_to_run)
        self.assertEqual(tests_to_run, tests_run)

    def test_no_order_test_specified_multiple_times(self):
        tests_to_run = ['passes/args.html', 'passes/audio.html', 'passes/audio.html', 'passes/args.html']
        tests_run = get_tests_run(['--order=none'] + tests_to_run)
        self.assertEqual(tests_to_run, tests_run)

    def test_no_order_with_directory_entries_in_natural_order(self):
        tests_to_run = ['http/tests/ssl', 'perf/foo', 'http/tests/passes']
        tests_run = get_tests_run(['--order=none'] + tests_to_run)
        self.assertEqual(tests_run, ['http/tests/ssl/text.html', 'perf/foo/test.html', 'http/tests/passes/image.html', 'http/tests/passes/text.html'])

    def test_repeat_each(self):
        tests_to_run = ['passes/image.html', 'passes/text.html']
        tests_run = get_tests_run(['--repeat-each', '2'] + tests_to_run)
        self.assertEqual(tests_run, ['passes/image.html', 'passes/image.html', 'passes/text.html', 'passes/text.html'])

    def test_ignore_flag(self):
        # Note that passes/image.html is expected to be run since we specified it directly.
        tests_run = get_tests_run(['-i', 'passes', 'passes/image.html'])
        self.assertFalse('passes/text.html' in tests_run)
        self.assertTrue('passes/image.html' in tests_run)

    def test_skipped_flag(self):
        tests_run = get_tests_run(['passes'])
        self.assertFalse('passes/skipped/skip.html' in tests_run)
        num_tests_run_by_default = len(tests_run)

        # Check that nothing changes when we specify skipped=default.
        self.assertEqual(len(get_tests_run(['--skipped=default', 'passes'])),
                          num_tests_run_by_default)

        # Now check that we run one more test (the skipped one).
        tests_run = get_tests_run(['--skipped=ignore', 'passes'])
        self.assertTrue('passes/skipped/skip.html' in tests_run)
        self.assertEqual(len(tests_run), num_tests_run_by_default + 1)

        # Now check that we only run the skipped test.
        self.assertEqual(get_tests_run(['--skipped=only', 'passes']), ['passes/skipped/skip.html'])

        # Now check that we don't run anything.
        self.assertEqual(get_tests_run(['--skipped=always', 'passes/skipped/skip.html']), [])

    def test_iterations(self):
        tests_to_run = ['passes/image.html', 'passes/text.html']
        tests_run = get_tests_run(['--iterations', '2'] + tests_to_run)
        self.assertEqual(tests_run, ['passes/image.html', 'passes/text.html', 'passes/image.html', 'passes/text.html'])

    def test_repeat_each_iterations_num_tests(self):
        # The total number of tests should be: number_of_tests *
        # repeat_each * iterations
        host = MockHost()
        _, err, _ = logging_run(
            ['--iterations', '2', '--repeat-each', '4', '--debug-rwt-logging', 'passes/text.html', 'failures/expected/text.html'],
            tests_included=True, host=host)
        self.assertContains(err, "All 16 tests ran as expected (8 passed, 8 didn't).\n")

    def test_run_chunk(self):
        # Test that we actually select the right chunk
        all_tests_run = get_tests_run(['passes', 'failures'])
        chunk_tests_run = get_tests_run(['--run-chunk', '1:4', 'passes', 'failures'])
        self.assertEqual(all_tests_run[4:8], chunk_tests_run)

        # Test that we wrap around if the number of tests is not evenly divisible by the chunk size
        tests_to_run = ['passes/error.html', 'passes/image.html', 'passes/platform_image.html', 'passes/text.html']
        chunk_tests_run = get_tests_run(['--run-chunk', '1:3'] + tests_to_run)
        self.assertEqual(['passes/text.html', 'passes/error.html', 'passes/image.html'], chunk_tests_run)

    def test_run_part(self):
        # Test that we actually select the right part
        tests_to_run = ['passes/error.html', 'passes/image.html', 'passes/platform_image.html', 'passes/text.html']
        tests_run = get_tests_run(['--run-part', '1:2'] + tests_to_run)
        self.assertEqual(['passes/error.html', 'passes/image.html'], tests_run)

        # Test that we wrap around if the number of tests is not evenly divisible by the chunk size
        # (here we end up with 3 parts, each with 2 tests, and we only have 4 tests total, so the
        # last part repeats the first two tests).
        chunk_tests_run = get_tests_run(['--run-part', '3:3'] + tests_to_run)
        self.assertEqual(['passes/error.html', 'passes/image.html'], chunk_tests_run)

    def test_run_singly(self):
        batch_tests_run = get_test_batches(['--run-singly'])
        for batch in batch_tests_run:
            self.assertEqual(len(batch), 1, '%s had too many tests' % ', '.join(batch))

    def test_skip_failing_tests(self):
        # This tests that we skip both known failing and known flaky tests. Because there are
        # no known flaky tests in the default test_expectations, we add additional expectations.
        host = MockHost()
        host.filesystem.write_text_file('/tmp/overrides.txt', 'Bug(x) passes/image.html [ ImageOnlyFailure Pass ]\n')

        batches = get_test_batches(['--skip-failing-tests', '--additional-expectations', '/tmp/overrides.txt'], host=host)
        has_passes_text = False
        for batch in batches:
            self.assertFalse('failures/expected/text.html' in batch)
            self.assertFalse('passes/image.html' in batch)
            has_passes_text = has_passes_text or ('passes/text.html' in batch)
        self.assertTrue(has_passes_text)

    def test_single_file(self):
        tests_run = get_tests_run(['passes/text.html'])
        self.assertEqual(tests_run, ['passes/text.html'])

    def test_single_file_with_prefix(self):
        tests_run = get_tests_run(['tests/passes/text.html'])
        self.assertEqual(['passes/text.html'], tests_run)

    def test_single_skipped_file(self):
        tests_run = get_tests_run(['failures/expected/keybaord.html'])
        self.assertEqual([], tests_run)

    def test_stderr_is_saved(self):
        host = MockHost()
        self.assertTrue(passing_run(host=host))
        self.assertEqual(host.filesystem.read_text_file('/tmp/layout-test-results/passes/error-stderr.txt'),
                          'stuff going to stderr')

    def test_test_list(self):
        host = MockHost()
        filename = '/tmp/foo.txt'
        host.filesystem.write_text_file(filename, 'passes/text.html')
        tests_run = get_tests_run(['--test-list=%s' % filename], host=host)
        self.assertEqual(['passes/text.html'], tests_run)
        host.filesystem.remove(filename)
        details, err, user = logging_run(['--test-list=%s' % filename], tests_included=True, host=host)
        self.assertEqual(details.exit_code, test_run_results.NO_TESTS_EXIT_STATUS)
        self.assertNotEmpty(err)

    def test_test_list_with_prefix(self):
        host = MockHost()
        filename = '/tmp/foo.txt'
        host.filesystem.write_text_file(filename, 'tests/passes/text.html')
        tests_run = get_tests_run(['--test-list=%s' % filename], host=host)
        self.assertEqual(['passes/text.html'], tests_run)

    def test_smoke_test(self):
        host = MockHost()
        smoke_test_filename = test.LAYOUT_TEST_DIR + '/SmokeTests'
        host.filesystem.write_text_file(smoke_test_filename, 'passes/text.html\n')

        # Test the default smoke testing.
        tests_run = get_tests_run(['--smoke'], host=host)
        self.assertEqual(['passes/text.html'], tests_run)

        # Test running the smoke tests plus some manually-specified tests.
        tests_run = get_tests_run(['--smoke', 'passes/image.html'], host=host)
        self.assertEqual(['passes/image.html', 'passes/text.html'], tests_run)

        # Test running the smoke tests plus some manually-specified tests.
        tests_run = get_tests_run(['--no-smoke', 'passes/image.html'], host=host)
        self.assertEqual(['passes/image.html'], tests_run)

        # Test that we don't run just the smoke tests by default on a normal test port.
        tests_run = get_tests_run([], host=host)
        self.assertNotEqual(['passes/text.html'], tests_run)

        # Create a port that does run only the smoke tests by default, and verify that works as expected.
        port_obj = host.port_factory.get('test')
        port_obj.default_smoke_test_only = lambda: True
        tests_run = get_tests_run([], host=host, port_obj=port_obj)
        self.assertEqual(['passes/text.html'], tests_run)

        # Verify that --no-smoke continues to work on a smoke-by-default port.
        tests_run = get_tests_run(['--no-smoke'], host=host, port_obj=port_obj)
        self.assertNotEqual(['passes/text.html'], tests_run)

    def test_missing_and_unexpected_results(self):
        # Test that we update expectations in place. If the expectation
        # is missing, update the expected generic location.
        host = MockHost()
        details, err, _ = logging_run(['--no-show-results', '--retry-failures',
            'failures/expected/missing_image.html',
            'failures/unexpected/missing_text.html',
            'failures/unexpected/text-image-checksum.html'],
            tests_included=True, host=host)
        file_list = host.filesystem.written_files.keys()
        self.assertEqual(details.exit_code, 2)
        json_string = host.filesystem.read_text_file('/tmp/layout-test-results/full_results.json')
        self.assertTrue(json_string.find('"text-image-checksum.html":{"expected":"PASS","actual":"IMAGE+TEXT","is_unexpected":true') != -1)
        self.assertTrue(json_string.find('"missing_text.html":{"expected":"PASS","is_missing_text":true,"actual":"MISSING","is_unexpected":true') != -1)
        self.assertTrue(json_string.find('"num_regressions":2') != -1)
        self.assertTrue(json_string.find('"num_flaky":0') != -1)

    def test_different_failure_on_retry(self):
        # This tests that if a test fails two different ways -- both unexpected
        # -- we treat it as a failure rather than a flaky result.  We use the
        # initial failure for simplicity and consistency w/ the flakiness
        # dashboard, even if the second failure is worse.

        details, err, _ = logging_run(['--retry-failures', 'failures/unexpected/text_then_crash.html'], tests_included=True)
        self.assertEqual(details.exit_code, 1)
        self.assertEqual(details.summarized_failing_results['tests']['failures']['unexpected']['text_then_crash.html']['actual'],
                         'TEXT CRASH')

        # If we get a test that fails two different ways -- but the second one is expected --
        # we should treat it as a flaky result and report the initial unexpected failure type
        # to the dashboard. However, the test should be considered passing.
        details, err, _ = logging_run(['--retry-failures', 'failures/expected/crash_then_text.html'], tests_included=True)
        self.assertEqual(details.exit_code, 0)
        self.assertEqual(details.summarized_failing_results['tests']['failures']['expected']['crash_then_text.html']['actual'],
                         'CRASH FAIL')

    def test_pixel_test_directories(self):
        host = MockHost()

        """Both tests have failing checksum. We include only the first in pixel tests so only that should fail."""
        args = ['--pixel-tests', '--retry-failures', '--pixel-test-directory', 'failures/unexpected/pixeldir',
                'failures/unexpected/pixeldir/image_in_pixeldir.html',
                'failures/unexpected/image_not_in_pixeldir.html']
        details, err, _ = logging_run(extra_args=args, host=host, tests_included=True)

        self.assertEqual(details.exit_code, 1)
        expected_token = '"pixeldir":{"image_in_pixeldir.html":{"expected":"PASS","actual":"IMAGE","is_unexpected":true'
        json_string = host.filesystem.read_text_file('/tmp/layout-test-results/full_results.json')
        self.assertTrue(json_string.find(expected_token) != -1)

    def test_crash_with_stderr(self):
        host = MockHost()
        _, regular_output, _ = logging_run(['failures/unexpected/crash-with-stderr.html'], tests_included=True, host=host)
        self.assertTrue(host.filesystem.read_text_file('/tmp/layout-test-results/full_results.json').find('{"crash-with-stderr.html":{"expected":"PASS","actual":"CRASH","has_stderr":true,"is_unexpected":true') != -1)

    def test_no_image_failure_with_image_diff(self):
        host = MockHost()
        _, regular_output, _ = logging_run(['failures/unexpected/checksum-with-matching-image.html'], tests_included=True, host=host)
        self.assertTrue(host.filesystem.read_text_file('/tmp/layout-test-results/full_results.json').find('"num_regressions":0') != -1)

    def test_exit_after_n_failures_upload(self):
        host = MockHost()
        details, regular_output, user = logging_run(
           ['failures/unexpected/text-image-checksum.html', 'passes/text.html', '--exit-after-n-failures', '1'],
           tests_included=True, host=host)

        # By returning False, we know that the incremental results were generated and then deleted.
        self.assertFalse(host.filesystem.exists('/tmp/layout-test-results/incremental_results.json'))

        self.assertEqual(details.exit_code, test_run_results.EARLY_EXIT_STATUS)

        # This checks that passes/text.html is considered SKIPped.
        self.assertTrue('"skipped":1' in host.filesystem.read_text_file('/tmp/layout-test-results/full_results.json'))

        # This checks that we told the user we bailed out.
        self.assertTrue('Exiting early after 1 failures. 1 tests run.\n' in regular_output.getvalue())

        # This checks that neither test ran as expected.
        # FIXME: This log message is confusing; tests that were skipped should be called out separately.
        self.assertTrue('0 tests ran as expected, 2 didn\'t:\n' in regular_output.getvalue())

    def test_exit_after_n_failures(self):
        # Unexpected failures should result in tests stopping.
        tests_run = get_tests_run(['failures/unexpected/text-image-checksum.html', 'passes/text.html', '--exit-after-n-failures', '1'])
        self.assertEqual(['failures/unexpected/text-image-checksum.html'], tests_run)

        # But we'll keep going for expected ones.
        tests_run = get_tests_run(['failures/expected/text.html', 'passes/text.html', '--exit-after-n-failures', '1'])
        self.assertEqual(['failures/expected/text.html', 'passes/text.html'], tests_run)

    def test_exit_after_n_crashes(self):
        # Unexpected crashes should result in tests stopping.
        tests_run = get_tests_run(['failures/unexpected/crash.html', 'passes/text.html', '--exit-after-n-crashes-or-timeouts', '1'])
        self.assertEqual(['failures/unexpected/crash.html'], tests_run)

        # Same with timeouts.
        tests_run = get_tests_run(['failures/unexpected/timeout.html', 'passes/text.html', '--exit-after-n-crashes-or-timeouts', '1'])
        self.assertEqual(['failures/unexpected/timeout.html'], tests_run)

        # But we'll keep going for expected ones.
        tests_run = get_tests_run(['failures/expected/crash.html', 'passes/text.html', '--exit-after-n-crashes-or-timeouts', '1'])
        self.assertEqual(['failures/expected/crash.html', 'passes/text.html'], tests_run)

    def test_results_directory_absolute(self):
        # We run a configuration that should fail, to generate output, then
        # look for what the output results url was.

        host = MockHost()
        with host.filesystem.mkdtemp() as tmpdir:
            _, _, user = logging_run(['--results-directory=' + str(tmpdir)], tests_included=True, host=host)
            self.assertEqual(user.opened_urls, [path.abspath_to_uri(host.platform, host.filesystem.join(tmpdir, 'results.html'))])

    def test_results_directory_default(self):
        # We run a configuration that should fail, to generate output, then
        # look for what the output results url was.

        # This is the default location.
        _, _, user = logging_run(tests_included=True)
        self.assertEqual(user.opened_urls, [path.abspath_to_uri(MockHost().platform, '/tmp/layout-test-results/results.html')])

    def test_results_directory_relative(self):
        # We run a configuration that should fail, to generate output, then
        # look for what the output results url was.
        host = MockHost()
        host.filesystem.maybe_make_directory('/tmp/cwd')
        host.filesystem.chdir('/tmp/cwd')
        _, _, user = logging_run(['--results-directory=foo'], tests_included=True, host=host)
        self.assertEqual(user.opened_urls, [path.abspath_to_uri(host.platform, '/tmp/cwd/foo/results.html')])

    def test_retrying_default_value(self):
        host = MockHost()
        details, err, _ = logging_run(['--debug-rwt-logging', 'failures/unexpected/text-image-checksum.html'], tests_included=True, host=host)
        self.assertEqual(details.exit_code, 1)
        self.assertFalse('Retrying' in err.getvalue())

        host = MockHost()
        details, err, _ = logging_run(['--debug-rwt-logging', 'failures/unexpected'], tests_included=True, host=host)
        self.assertEqual(details.exit_code, test.UNEXPECTED_FAILURES - 7)  # FIXME: This should be a constant in test.py .
        self.assertTrue('Retrying' in err.getvalue())

    def test_retrying_default_value_test_list(self):
        host = MockHost()
        filename = '/tmp/foo.txt'
        host.filesystem.write_text_file(filename, 'failures/unexpected/text-image-checksum.html\nfailures/unexpected/crash.html')
        details, err, _ = logging_run(['--debug-rwt-logging', '--test-list=%s' % filename], tests_included=True, host=host)
        self.assertEqual(details.exit_code, 2)
        self.assertFalse('Retrying' in err.getvalue())

        host = MockHost()
        filename = '/tmp/foo.txt'
        host.filesystem.write_text_file(filename, 'failures')
        details, err, _ = logging_run(['--debug-rwt-logging', '--test-list=%s' % filename], tests_included=True, host=host)
        self.assertEqual(details.exit_code, test.UNEXPECTED_FAILURES - 7)
        self.assertTrue('Retrying' in err.getvalue())

    def test_retrying_and_flaky_tests(self):
        host = MockHost()
        details, err, _ = logging_run(['--debug-rwt-logging', '--retry-failures', 'failures/flaky'], tests_included=True, host=host)
        self.assertEqual(details.exit_code, 0)
        self.assertTrue('Retrying' in err.getvalue())
        self.assertTrue(host.filesystem.exists('/tmp/layout-test-results/failures/flaky/text-actual.txt'))
        self.assertFalse(host.filesystem.exists('/tmp/layout-test-results/retries/failures/flaky/text-actual.txt'))
        self.assertEqual(len(host.user.opened_urls), 0)

        # Now we test that --clobber-old-results does remove the old entries and the old retries,
        # and that we don't retry again.
        host = MockHost()
        details, err, _ = logging_run(['--no-retry-failures', '--clobber-old-results', 'failures/flaky'], tests_included=True, host=host)
        self.assertEqual(details.exit_code, 1)
        self.assertTrue('Clobbering old results' in err.getvalue())
        self.assertTrue('flaky/text.html' in err.getvalue())
        self.assertTrue(host.filesystem.exists('/tmp/layout-test-results/failures/flaky/text-actual.txt'))
        self.assertFalse(host.filesystem.exists('retries'))
        self.assertEqual(len(host.user.opened_urls), 1)

    def test_retrying_crashed_tests(self):
        host = MockHost()
        details, err, _ = logging_run(['--retry-failures', 'failures/unexpected/crash.html'], tests_included=True, host=host)
        self.assertEqual(details.exit_code, 1)
        self.assertTrue('Retrying' in err.getvalue())

    def test_retrying_leak_tests(self):
        host = MockHost()
        details, err, _ = logging_run(['--retry-failures', 'failures/unexpected/leak.html'], tests_included=True, host=host)
        self.assertEqual(details.exit_code, 1)
        self.assertTrue('Retrying' in err.getvalue())

    def test_retrying_force_pixel_tests(self):
        host = MockHost()
        details, err, _ = logging_run(['--no-pixel-tests', '--retry-failures', 'failures/unexpected/text-image-checksum.html'], tests_included=True, host=host)
        self.assertEqual(details.exit_code, 1)
        self.assertTrue('Retrying' in err.getvalue())
        self.assertTrue(host.filesystem.exists('/tmp/layout-test-results/failures/unexpected/text-image-checksum-actual.txt'))
        self.assertFalse(host.filesystem.exists('/tmp/layout-test-results/failures/unexpected/text-image-checksum-actual.png'))
        self.assertTrue(host.filesystem.exists('/tmp/layout-test-results/retries/failures/unexpected/text-image-checksum-actual.txt'))
        self.assertTrue(host.filesystem.exists('/tmp/layout-test-results/retries/failures/unexpected/text-image-checksum-actual.png'))
        json_string = host.filesystem.read_text_file('/tmp/layout-test-results/full_results.json')
        json = parse_full_results(json_string)
        self.assertEqual(json["tests"]["failures"]["unexpected"]["text-image-checksum.html"],
            {"expected": "PASS", "actual": "TEXT IMAGE+TEXT", "is_unexpected": True})
        self.assertFalse(json["pixel_tests_enabled"])
        self.assertEqual(details.enabled_pixel_tests_in_retry, True)

    def test_retrying_uses_retries_directory(self):
        host = MockHost()
        details, err, _ = logging_run(['--debug-rwt-logging', '--retry-failures', 'failures/unexpected/text-image-checksum.html'], tests_included=True, host=host)
        self.assertEqual(details.exit_code, 1)
        self.assertTrue(host.filesystem.exists('/tmp/layout-test-results/failures/unexpected/text-image-checksum-actual.txt'))
        self.assertTrue(host.filesystem.exists('/tmp/layout-test-results/retries/failures/unexpected/text-image-checksum-actual.txt'))

    def test_run_order__inline(self):
        # These next tests test that we run the tests in ascending alphabetical
        # order per directory. HTTP tests are sharded separately from other tests,
        # so we have to test both.
        tests_run = get_tests_run(['-i', 'passes/passes', 'passes'])
        self.assertEqual(tests_run, sorted(tests_run))

        tests_run = get_tests_run(['http/tests/passes'])
        self.assertEqual(tests_run, sorted(tests_run))

    def test_virtual(self):
        self.assertTrue(passing_run(['passes/text.html', 'passes/args.html',
                                     'virtual/passes/text.html', 'virtual/passes/args.html']))

    def test_reftest_run(self):
        tests_run = get_tests_run(['passes/reftest.html'])
        self.assertEqual(['passes/reftest.html'], tests_run)

    def test_reftest_run_reftests_if_pixel_tests_are_disabled(self):
        tests_run = get_tests_run(['--no-pixel-tests', 'passes/reftest.html'])
        self.assertEqual(['passes/reftest.html'], tests_run)

    def test_reftest_expected_html_should_be_ignored(self):
        tests_run = get_tests_run(['passes/reftest-expected.sky'])
        self.assertEqual([], tests_run)

    def test_reftest_driver_should_run_expected_html(self):
        tests_run = get_test_results(['passes/reftest.html'])
        self.assertEqual(tests_run[0].references, ['passes/reftest-expected.sky'])

    def test_reftest_driver_should_run_expected_mismatch_html(self):
        tests_run = get_test_results(['passes/mismatch.html'])
        self.assertEqual(tests_run[0].references, ['passes/mismatch-expected-mismatch.sky'])

    def test_reftest_should_not_use_naming_convention_if_not_listed_in_reftestlist(self):
        host = MockHost()
        _, err, _ = logging_run(['--no-show-results', 'reftests/foo/'], tests_included=True, host=host)
        results = parse_full_results(host.filesystem.read_text_file('/tmp/layout-test-results/full_results.json'))

        self.assertEqual(results["tests"]["reftests"]["foo"]["unlistedtest.html"]["actual"], "MISSING"),
        self.assertEqual(results["num_regressions"], 5)
        self.assertEqual(results["num_flaky"], 0)

    def test_reftest_crash(self):
        test_results = get_test_results(['failures/unexpected/crash-reftest.html'])
        # The list of references should be empty since the test crashed and we didn't run any references.
        self.assertEqual(test_results[0].references, [])

    def test_reftest_with_virtual_reference(self):
        _, err, _ = logging_run(['--details', 'virtual/passes/reftest.html'], tests_included=True)
        self.assertTrue('ref: virtual/passes/reftest-expected.sky' in err.getvalue())

    def test_additional_platform_directory(self):
        self.assertTrue(passing_run(['--additional-platform-directory', '/tmp/foo']))
        self.assertTrue(passing_run(['--additional-platform-directory', '/tmp/../foo']))
        self.assertTrue(passing_run(['--additional-platform-directory', '/tmp/foo', '--additional-platform-directory', '/tmp/bar']))
        self.assertTrue(passing_run(['--additional-platform-directory', 'foo']))

    def test_additional_expectations(self):
        host = MockHost()
        host.filesystem.write_text_file('/tmp/overrides.txt', 'Bug(x) failures/unexpected/mismatch.html [ ImageOnlyFailure ]\n')
        self.assertTrue(passing_run(['--additional-expectations', '/tmp/overrides.txt', 'failures/unexpected/mismatch.html'],
                                    tests_included=True, host=host))

    @staticmethod
    def has_test_of_type(tests, type):
        return [test for test in tests if type in test]

    def test_platform_directories_ignored_when_searching_for_tests(self):
        tests_run = get_tests_run(['--platform', 'test-mac-leopard'])
        self.assertFalse('platform/test-mac-leopard/http/test.html' in tests_run)
        self.assertFalse('platform/test-win-win7/http/test.html' in tests_run)

    def test_platform_directories_not_searched_for_additional_tests(self):
        tests_run = get_tests_run(['--platform', 'test-mac-leopard', 'http'])
        self.assertFalse('platform/test-mac-leopard/http/test.html' in tests_run)
        self.assertFalse('platform/test-win-win7/http/test.html' in tests_run)

    def test_output_diffs(self):
        # Test to ensure that we don't generate -wdiff.html or -pretty.html if wdiff and PrettyPatch
        # aren't available.
        host = MockHost()
        _, err, _ = logging_run(['--pixel-tests', 'failures/unexpected/text-image-checksum.html'], tests_included=True, host=host)
        written_files = host.filesystem.written_files
        self.assertTrue(any(path.endswith('-diff.txt') for path in written_files.keys()))
        self.assertFalse(any(path.endswith('-wdiff.html') for path in written_files.keys()))
        self.assertFalse(any(path.endswith('-pretty-diff.html') for path in written_files.keys()))

        full_results_text = host.filesystem.read_text_file('/tmp/layout-test-results/full_results.json')
        full_results = json.loads(full_results_text.replace("ADD_RESULTS(", "").replace(");", ""))
        self.assertEqual(full_results['has_wdiff'], False)
        self.assertEqual(full_results['has_pretty_patch'], False)

    def test_unsupported_platform(self):
        stdout = StringIO.StringIO()
        stderr = StringIO.StringIO()
        res = run_webkit_tests.main(['--platform', 'foo'], stdout, stderr)

        self.assertEqual(res, test_run_results.UNEXPECTED_ERROR_EXIT_STATUS)
        self.assertEqual(stdout.getvalue(), '')
        self.assertTrue('unsupported platform' in stderr.getvalue())

    def test_build_check(self):
        # By using a port_name for a different platform than the one we're running on, the build check should always fail.
        if sys.platform == 'darwin':
            port_name = 'linux-x86'
        else:
            port_name = 'mac-lion'
        out = StringIO.StringIO()
        err = StringIO.StringIO()
        self.assertEqual(run_webkit_tests.main(['--platform', port_name, 'resources/results.html'], out, err), test_run_results.UNEXPECTED_ERROR_EXIT_STATUS)

    def test_verbose_in_child_processes(self):
        # When we actually run multiple processes, we may have to reconfigure logging in the
        # child process (e.g., on win32) and we need to make sure that works and we still
        # see the verbose log output. However, we can't use logging_run() because using
        # outputcapture to capture stdout and stderr latter results in a nonpicklable host.

        # Test is flaky on Windows: https://bugs.webkit.org/show_bug.cgi?id=98559
        if not self.should_test_processes:
            return

        options, parsed_args = parse_args(['--verbose', '--fully-parallel', '--child-processes', '2', 'passes/text.html', 'passes/image.html'], tests_included=True, print_nothing=False)
        host = MockHost()
        port_obj = host.port_factory.get(port_name=options.platform, options=options)
        logging_stream = StringIO.StringIO()
        run_webkit_tests.run(port_obj, options, parsed_args, logging_stream=logging_stream)
        self.assertTrue('text.html passed' in logging_stream.getvalue())
        self.assertTrue('image.html passed' in logging_stream.getvalue())

    def disabled_test_driver_logging(self):
        # FIXME: Figure out how to either use a mock-test port to
        # get output or mack mock ports work again.
        host = Host()
        _, err, _ = logging_run(['--platform', 'mock-win', '--driver-logging', 'resources/results.html'],
                                tests_included=True, host=host)
        self.assertTrue('OUT:' in err.getvalue())

    def test_write_full_results_to(self):
        host = MockHost()
        details, _, _ = logging_run(['--write-full-results-to', '/tmp/full_results.json'], host=host)
        self.assertEqual(details.exit_code, 0)
        self.assertTrue(host.filesystem.exists('/tmp/full_results.json'))


class EndToEndTest(unittest.TestCase):
    def test_reftest_with_two_notrefs(self):
        # Test that we update expectations in place. If the expectation
        # is missing, update the expected generic location.
        host = MockHost()
        _, _, _ = logging_run(['--no-show-results', 'reftests/foo/'], tests_included=True, host=host)
        file_list = host.filesystem.written_files.keys()

        json_string = host.filesystem.read_text_file('/tmp/layout-test-results/failing_results.json')
        json = parse_full_results(json_string)
        self.assertTrue("multiple-match-success.html" not in json["tests"]["reftests"]["foo"])
        self.assertTrue("multiple-mismatch-success.html" not in json["tests"]["reftests"]["foo"])
        self.assertTrue("multiple-both-success.html" not in json["tests"]["reftests"]["foo"])

        self.assertEqual(json["tests"]["reftests"]["foo"]["multiple-match-failure.html"],
            {"expected": "PASS", "actual": "IMAGE", "reftest_type": ["=="], "is_unexpected": True})
        self.assertEqual(json["tests"]["reftests"]["foo"]["multiple-mismatch-failure.html"],
            {"expected": "PASS", "actual": "IMAGE", "reftest_type": ["!="], "is_unexpected": True})
        self.assertEqual(json["tests"]["reftests"]["foo"]["multiple-both-failure.html"],
            {"expected": "PASS", "actual": "IMAGE", "reftest_type": ["==", "!="], "is_unexpected": True})


class RebaselineTest(unittest.TestCase, StreamTestingMixin):
    def assertBaselines(self, file_list, file, extensions, err):
        "assert that the file_list contains the baselines."""
        for ext in extensions:
            baseline = file + "-expected" + ext
            baseline_msg = 'Writing new expected result "%s"\n' % baseline
            self.assertTrue(any(f.find(baseline) != -1 for f in file_list))
            self.assertContains(err, baseline_msg)

    # FIXME: Add tests to ensure that we're *not* writing baselines when we're not
    # supposed to be.

    def test_reset_results(self):
        # Test that we update expectations in place. If the expectation
        # is missing, update the expected generic location.
        host = MockHost()
        details, err, _ = logging_run(
            ['--pixel-tests', '--reset-results', 'passes/image.html', 'failures/expected/missing_image.html'],
            tests_included=True, host=host, new_results=True)
        file_list = host.filesystem.written_files.keys()
        self.assertEqual(details.exit_code, 0)
        self.assertEqual(len(file_list), 8)
        self.assertBaselines(file_list, "passes/image", [".txt", ".png"], err)
        self.assertBaselines(file_list, "failures/expected/missing_image", [".txt", ".png"], err)

    def test_missing_results(self):
        # Test that we update expectations in place. If the expectation
        # is missing, update the expected generic location.
        host = MockHost()
        details, err, _ = logging_run(['--no-show-results',
            'failures/unexpected/missing_text.html',
            'failures/unexpected/missing_image.html',
            'failures/unexpected/missing_render_tree_dump.html'],
            tests_included=True, host=host, new_results=True)
        file_list = host.filesystem.written_files.keys()
        self.assertEqual(details.exit_code, 3)
        self.assertEqual(len(file_list), 10)
        self.assertBaselines(file_list, "failures/unexpected/missing_text", [".txt"], err)
        self.assertBaselines(file_list, "platform/test/failures/unexpected/missing_image", [".png"], err)
        self.assertBaselines(file_list, "platform/test/failures/unexpected/missing_render_tree_dump", [".txt"], err)

    def test_missing_results_not_added_if_expected_missing(self):
        # Test that we update expectations in place. If the expectation
        # is missing, update the expected generic location.
        host = MockHost()
        options, parsed_args = run_webkit_tests.parse_args([])

        port = test.TestPort(host, options=options)
        host.filesystem.write_text_file(port.path_to_generic_test_expectations_file(), """
Bug(foo) failures/unexpected/missing_text.html [ Missing ]
Bug(foo) failures/unexpected/missing_image.html [ NeedsRebaseline ]
Bug(foo) failures/unexpected/missing_audio.html [ NeedsManualRebaseline ]
Bug(foo) failures/unexpected/missing_render_tree_dump.html [ Missing ]
""")
        details, err, _ = logging_run(['--no-show-results',
            'failures/unexpected/missing_text.html',
            'failures/unexpected/missing_image.html',
            'failures/unexpected/missing_audio.html',
            'failures/unexpected/missing_render_tree_dump.html'],
            tests_included=True, host=host, new_results=True,  port_obj=port)
        file_list = host.filesystem.written_files.keys()
        self.assertEqual(details.exit_code, 0)
        self.assertEqual(len(file_list), 7)
        self.assertFalse(any('failures/unexpected/missing_text-expected' in file for file in file_list))
        self.assertFalse(any('failures/unexpected/missing_image-expected' in file for file in file_list))
        self.assertFalse(any('failures/unexpected/missing_render_tree_dump-expected' in file for file in file_list))

    def test_missing_results_not_added_if_expected_missing_and_reset_results(self):
        # Test that we update expectations in place. If the expectation
        # is missing, update the expected generic location.
        host = MockHost()
        options, parsed_args = run_webkit_tests.parse_args(['--pixel-tests', '--reset-results'])

        port = test.TestPort(host, options=options)
        host.filesystem.write_text_file(port.path_to_generic_test_expectations_file(), """
Bug(foo) failures/unexpected/missing_text.html [ Missing ]
Bug(foo) failures/unexpected/missing_image.html [ NeedsRebaseline ]
Bug(foo) failures/unexpected/missing_audio.html [ NeedsManualRebaseline ]
Bug(foo) failures/unexpected/missing_render_tree_dump.html [ Missing ]
""")
        details, err, _ = logging_run(['--pixel-tests', '--reset-results',
            'failures/unexpected/missing_text.html',
            'failures/unexpected/missing_image.html',
            'failures/unexpected/missing_audio.html',
            'failures/unexpected/missing_render_tree_dump.html'],
            tests_included=True, host=host, new_results=True,  port_obj=port)
        file_list = host.filesystem.written_files.keys()
        self.assertEqual(details.exit_code, 0)
        self.assertEqual(len(file_list), 11)
        self.assertBaselines(file_list, "failures/unexpected/missing_text", [".txt"], err)
        self.assertBaselines(file_list, "failures/unexpected/missing_image", [".png"], err)
        self.assertBaselines(file_list, "failures/unexpected/missing_render_tree_dump", [".txt"], err)

    def test_new_baseline(self):
        # Test that we update the platform expectations in the version-specific directories
        # for both existing and new baselines.
        host = MockHost()
        details, err, _ = logging_run(
            ['--pixel-tests', '--new-baseline', 'passes/image.html', 'failures/expected/missing_image.html'],
            tests_included=True, host=host, new_results=True)
        file_list = host.filesystem.written_files.keys()
        self.assertEqual(details.exit_code, 0)
        self.assertEqual(len(file_list), 8)
        self.assertBaselines(file_list,
            "platform/test-mac-leopard/passes/image", [".txt", ".png"], err)
        self.assertBaselines(file_list,
            "platform/test-mac-leopard/failures/expected/missing_image", [".txt", ".png"], err)


class PortTest(unittest.TestCase):
    def assert_mock_port_works(self, port_name, args=[]):
        self.assertTrue(passing_run(args + ['--platform', 'mock-' + port_name, 'resources/results.html'], tests_included=True, host=Host()))

    def disabled_test_mac_lion(self):
        self.assert_mock_port_works('mac-lion')


class MainTest(unittest.TestCase):
    def test_exception_handling(self):
        orig_run_fn = run_webkit_tests.run

        # unused args pylint: disable=W0613
        def interrupting_run(port, options, args, stderr):
            raise KeyboardInterrupt

        def successful_run(port, options, args, stderr):

            class FakeRunDetails(object):
                exit_code = test_run_results.UNEXPECTED_ERROR_EXIT_STATUS

            return FakeRunDetails()

        def exception_raising_run(port, options, args, stderr):
            assert False

        stdout = StringIO.StringIO()
        stderr = StringIO.StringIO()
        try:
            run_webkit_tests.run = interrupting_run
            res = run_webkit_tests.main([], stdout, stderr)
            self.assertEqual(res, test_run_results.INTERRUPTED_EXIT_STATUS)

            run_webkit_tests.run = successful_run
            res = run_webkit_tests.main(['--platform', 'test'], stdout, stderr)
            self.assertEqual(res, test_run_results.UNEXPECTED_ERROR_EXIT_STATUS)

            run_webkit_tests.run = exception_raising_run
            res = run_webkit_tests.main([], stdout, stderr)
            self.assertEqual(res, test_run_results.UNEXPECTED_ERROR_EXIT_STATUS)
        finally:
            run_webkit_tests.run = orig_run_fn

    def test_buildbot_results_are_printed_on_early_exit(self):
        # unused args pylint: disable=W0613
        stdout = StringIO.StringIO()
        stderr = StringIO.StringIO()
        res = run_webkit_tests.main(['--platform', 'test', '--exit-after-n-failures', '1',
                                     'failures/unexpected/missing_text.html',
                                     'failures/unexpected/missing_image.html'],
                                    stdout, stderr)
        self.assertEqual(res, test_run_results.EARLY_EXIT_STATUS)
        self.assertEqual(stdout.getvalue(),
                ('\n'
                 'Regressions: Unexpected missing results (1)\n'
                 '  failures/unexpected/missing_image.html [ Missing ]\n\n'))
