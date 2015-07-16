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

"""
The Manager runs a series of tests (TestType interface) against a set
of test files.  If a test file fails a TestType, it returns a list of TestFailure
objects to the Manager. The Manager then aggregates the TestFailures to
create a final report.
"""

import datetime
import json
import logging
import random
import sys
import time

from webkitpy.common.net.file_uploader import FileUploader
from webkitpy.layout_tests.controllers.layout_test_finder import LayoutTestFinder
from webkitpy.layout_tests.controllers.layout_test_runner import LayoutTestRunner
from webkitpy.layout_tests.controllers.test_result_writer import TestResultWriter
from webkitpy.layout_tests.layout_package import json_results_generator
from webkitpy.layout_tests.models import test_expectations
from webkitpy.layout_tests.models import test_failures
from webkitpy.layout_tests.models import test_run_results
from webkitpy.layout_tests.models.test_input import TestInput

_log = logging.getLogger(__name__)

# Builder base URL where we have the archived test results.
BUILDER_BASE_URL = "http://build.chromium.org/buildbot/layout_test_results/"

TestExpectations = test_expectations.TestExpectations



class Manager(object):
    """A class for managing running a series of tests on a series of layout
    test files."""

    def __init__(self, port, options, printer):
        """Initialize test runner data structures.

        Args:
          port: an object implementing port-specific
          options: a dictionary of command line options
          printer: a Printer object to record updates to.
        """
        self._port = port
        self._filesystem = port.host.filesystem
        self._options = options
        self._printer = printer
        self._expectations = None

        self.HTTP_SUBDIR = 'http' + port.TEST_PATH_SEPARATOR
        self.PERF_SUBDIR = 'perf'
        self.WEBSOCKET_SUBDIR = 'websocket' + port.TEST_PATH_SEPARATOR
        self.LAYOUT_TESTS_DIRECTORY = 'tests'
        self.ARCHIVED_RESULTS_LIMIT = 25
        self._http_server_started = False
        self._websockets_server_started = False

        self._results_directory = self._port.results_directory()
        self._finder = LayoutTestFinder(self._port, self._options)
        self._runner = LayoutTestRunner(self._options, self._port, self._printer, self._results_directory, self._test_is_slow)

    def _collect_tests(self, args):
        return self._finder.find_tests(self._options, args)

    def _is_http_test(self, test):
        return self.HTTP_SUBDIR in test or self._is_websocket_test(test)

    def _is_websocket_test(self, test):
        return self.WEBSOCKET_SUBDIR in test

    def _http_tests(self, test_names):
        return set(test for test in test_names if self._is_http_test(test))

    def _is_perf_test(self, test):
        return self.PERF_SUBDIR == test or (self.PERF_SUBDIR + self._port.TEST_PATH_SEPARATOR) in test

    def _prepare_lists(self, paths, test_names):
        tests_to_skip = self._finder.skip_tests(paths, test_names, self._expectations, self._http_tests(test_names))
        tests_to_run = [test for test in test_names if test not in tests_to_skip]

        if not tests_to_run:
            return tests_to_run, tests_to_skip

        # Create a sorted list of test files so the subset chunk,
        # if used, contains alphabetically consecutive tests.
        if self._options.order == 'natural':
            tests_to_run.sort(key=self._port.test_key)
        elif self._options.order == 'random':
            random.shuffle(tests_to_run)
        elif self._options.order == 'random-seeded':
            rnd = random.Random()
            rnd.seed(4) # http://xkcd.com/221/
            rnd.shuffle(tests_to_run)

        tests_to_run, tests_in_other_chunks = self._finder.split_into_chunks(tests_to_run)
        self._expectations.add_extra_skipped_tests(tests_in_other_chunks)
        tests_to_skip.update(tests_in_other_chunks)

        return tests_to_run, tests_to_skip

    def _test_input_for_file(self, test_file):
        return TestInput(test_file,
            self._options.slow_time_out_ms if self._test_is_slow(test_file) else self._options.time_out_ms,
            self._test_requires_lock(test_file),
            should_add_missing_baselines=(self._options.new_test_results and not self._test_is_expected_missing(test_file)))

    def _test_requires_lock(self, test_file):
        """Return True if the test needs to be locked when
        running multiple copies of NRWTs. Perf tests are locked
        because heavy load caused by running other tests in parallel
        might cause some of them to timeout."""
        return False

    def _test_is_expected_missing(self, test_file):
        expectations = self._expectations.model().get_expectations(test_file)
        return test_expectations.MISSING in expectations or test_expectations.NEEDS_REBASELINE in expectations or test_expectations.NEEDS_MANUAL_REBASELINE in expectations

    def _test_is_slow(self, test_file):
        return test_expectations.SLOW in self._expectations.model().get_expectations(test_file)

    def needs_servers(self, test_names):
        return any(self._test_requires_lock(test_name) for test_name in test_names)

    def _rename_results_folder(self):
        try:
            timestamp = time.strftime("%Y-%m-%d-%H-%M-%S", time.localtime(self._filesystem.mtime(self._filesystem.join(self._results_directory, "results.html"))))
        except OSError, e:
            # It might be possible that results.html was not generated in previous run, because the test
            # run was interrupted even before testing started. In those cases, don't archive the folder.
            # Simply override the current folder contents with new results.
            import errno
            if e.errno == errno.EEXIST:
                _log.warning("No results.html file found in previous run, skipping it.")
            return None
        archived_name = ''.join((self._filesystem.basename(self._results_directory), "_", timestamp))
        archived_path = self._filesystem.join(self._filesystem.dirname(self._results_directory), archived_name)
        self._filesystem.move(self._results_directory, archived_path)

    def _clobber_old_archived_results(self):
        results_directory_path = self._filesystem.dirname(self._results_directory)
        file_list = self._filesystem.listdir(results_directory_path)
        results_directories = []
        for dir in file_list:
            file_path = self._filesystem.join(results_directory_path, dir)
            if self._filesystem.isdir(file_path):
                results_directories.append(file_path)
        results_directories.sort(key=lambda x: self._filesystem.mtime(x))
        self._printer.write_update("Clobbering old archived results in %s" % results_directory_path)
        for dir in results_directories[:-self.ARCHIVED_RESULTS_LIMIT]:
            self._filesystem.rmtree(dir)

    def _set_up_run(self, test_names):
        self._printer.write_update("Checking build ...")
        if self._options.build:
            exit_code = self._port.check_build(self.needs_servers(test_names), self._printer)
            if exit_code:
                _log.error("Build check failed")
                return exit_code

        # This must be started before we check the system dependencies,
        # since the helper may do things to make the setup correct.
        if self._options.pixel_tests:
            self._printer.write_update("Starting pixel test helper ...")
            self._port.start_helper()

        # Check that the system dependencies (themes, fonts, ...) are correct.
        if not self._options.nocheck_sys_deps:
            self._printer.write_update("Checking system dependencies ...")
            exit_code = self._port.check_sys_deps(self.needs_servers(test_names))
            if exit_code:
                self._port.stop_helper()
                return exit_code

        if self._options.enable_versioned_results and self._filesystem.exists(self._results_directory):
            if self._options.clobber_old_results:
                _log.warning("Flag --enable_versioned_results overrides --clobber-old-results.")
            self._clobber_old_archived_results()
            # Rename the existing results folder for archiving.
            self._rename_results_folder()
        elif self._options.clobber_old_results:
            self._clobber_old_results()

        # Create the output directory if it doesn't already exist.
        self._port.host.filesystem.maybe_make_directory(self._results_directory)

        self._port.setup_test_run()
        return test_run_results.OK_EXIT_STATUS

    def run(self, args):
        """Run the tests and return a RunDetails object with the results."""
        start_time = time.time()
        self._printer.write_update("Collecting tests ...")
        try:
            paths, test_names = self._collect_tests(args)
        except IOError:
            # This is raised if --test-list doesn't exist
            return test_run_results.RunDetails(exit_code=test_run_results.NO_TESTS_EXIT_STATUS)

        self._printer.write_update("Parsing expectations ...")
        self._expectations = test_expectations.TestExpectations(self._port, test_names)

        tests_to_run, tests_to_skip = self._prepare_lists(paths, test_names)
        self._printer.print_found(len(test_names), len(tests_to_run), self._options.repeat_each, self._options.iterations)

        # Check to make sure we're not skipping every test.
        if not tests_to_run:
            _log.critical('No tests to run.')
            return test_run_results.RunDetails(exit_code=test_run_results.NO_TESTS_EXIT_STATUS)

        exit_code = self._set_up_run(tests_to_run)
        if exit_code:
            return test_run_results.RunDetails(exit_code=exit_code)

        if self._options.retry_failures is None:
            should_retry_failures = False
        else:
            should_retry_failures = self._options.retry_failures

        enabled_pixel_tests_in_retry = False
        try:
            self._start_servers(tests_to_run)

            initial_results = self._run_tests(tests_to_run, tests_to_skip, self._options.repeat_each, self._options.iterations,
                self._port.num_workers(int(self._options.child_processes)), retrying=False)

            # Don't retry failures when interrupted by user or failures limit exception.
            should_retry_failures = should_retry_failures and not (initial_results.interrupted or initial_results.keyboard_interrupted)

            tests_to_retry = self._tests_to_retry(initial_results)
            if should_retry_failures and tests_to_retry:
                enabled_pixel_tests_in_retry = self._force_pixel_tests_if_needed()

                _log.info('')
                _log.info("Retrying %d unexpected failure(s) ..." % len(tests_to_retry))
                _log.info('')
                retry_results = self._run_tests(tests_to_retry, tests_to_skip=set(), repeat_each=1, iterations=1,
                    num_workers=1, retrying=True)

                if enabled_pixel_tests_in_retry:
                    self._options.pixel_tests = False
            else:
                retry_results = None
        finally:
            self._stop_servers()
            self._clean_up_run()

        # Some crash logs can take a long time to be written out so look
        # for new logs after the test run finishes.
        self._printer.write_update("looking for new crash logs")
        self._look_for_new_crash_logs(initial_results, start_time)
        if retry_results:
            self._look_for_new_crash_logs(retry_results, start_time)

        _log.debug("summarizing results")
        summarized_full_results = test_run_results.summarize_results(self._port, self._expectations, initial_results, retry_results, enabled_pixel_tests_in_retry)
        summarized_failing_results = test_run_results.summarize_results(self._port, self._expectations, initial_results, retry_results, enabled_pixel_tests_in_retry, only_include_failing=True)

        exit_code = summarized_failing_results['num_regressions']
        if exit_code > test_run_results.MAX_FAILURES_EXIT_STATUS:
            _log.warning('num regressions (%d) exceeds max exit status (%d)' %
                         (exit_code, test_run_results.MAX_FAILURES_EXIT_STATUS))
            exit_code = test_run_results.MAX_FAILURES_EXIT_STATUS

        if not self._options.dry_run:
            self._write_json_files(summarized_full_results, summarized_failing_results, initial_results)

            if self._options.write_full_results_to:
                self._filesystem.copyfile(self._filesystem.join(self._results_directory, "full_results.json"),
                                          self._options.write_full_results_to)

            self._upload_json_files()

            results_path = self._filesystem.join(self._results_directory, "results.html")
            self._copy_results_html_file(results_path)
            if initial_results.keyboard_interrupted:
                exit_code = test_run_results.INTERRUPTED_EXIT_STATUS
            else:
                if initial_results.interrupted:
                    exit_code = test_run_results.EARLY_EXIT_STATUS
                if self._options.show_results and (exit_code or (self._options.full_results_html and initial_results.total_failures)):
                    self._port.show_results_html_file(results_path)
                self._printer.print_results(time.time() - start_time, initial_results, summarized_failing_results)
        return test_run_results.RunDetails(exit_code, summarized_full_results, summarized_failing_results, initial_results, retry_results, enabled_pixel_tests_in_retry)

    def _run_tests(self, tests_to_run, tests_to_skip, repeat_each, iterations, num_workers, retrying):

        test_inputs = []
        for _ in xrange(iterations):
            for test in tests_to_run:
                for _ in xrange(repeat_each):
                    test_inputs.append(self._test_input_for_file(test))
        return self._runner.run_tests(self._expectations, test_inputs, tests_to_skip, num_workers, retrying)

    def _start_servers(self, tests_to_run):
        if self._port.requires_sky_server() or any(self._is_http_test(test) for test in tests_to_run):
            self._printer.write_update('Starting HTTP server ...')
            self._port.start_sky_server(additional_dirs={}, number_of_drivers=self._options.max_locked_shards)
            self._http_server_started = True

        if any(self._is_websocket_test(test) for test in tests_to_run):
            self._printer.write_update('Starting WebSocket server ...')
            self._port.start_websocket_server()
            self._websockets_server_started = True

    def _stop_servers(self):
        if self._http_server_started:
            self._printer.write_update('Stopping HTTP server ...')
            self._http_server_started = False
            self._port.stop_sky_server()
        if self._websockets_server_started:
            self._printer.write_update('Stopping WebSocket server ...')
            self._websockets_server_started = False
            self._port.stop_websocket_server()

    def _clean_up_run(self):
        _log.debug("Flushing stdout")
        sys.stdout.flush()
        _log.debug("Flushing stderr")
        sys.stderr.flush()
        _log.debug("Stopping helper")
        self._port.stop_helper()
        _log.debug("Cleaning up port")
        self._port.clean_up_test_run()

    def _force_pixel_tests_if_needed(self):
        if self._options.pixel_tests:
            return False

        _log.debug("Restarting helper")
        self._port.stop_helper()
        self._options.pixel_tests = True
        self._port.start_helper()

        return True

    def _look_for_new_crash_logs(self, run_results, start_time):
        """Since crash logs can take a long time to be written out if the system is
           under stress do a second pass at the end of the test run.

           run_results: the results of the test run
           start_time: time the tests started at.  We're looking for crash
               logs after that time.
        """
        crashed_processes = []
        for test, result in run_results.unexpected_results_by_name.iteritems():
            if (result.type != test_expectations.CRASH):
                continue
            for failure in result.failures:
                if not isinstance(failure, test_failures.FailureCrash):
                    continue
                crashed_processes.append([test, failure.process_name, failure.pid])

        sample_files = self._port.look_for_new_samples(crashed_processes, start_time)
        if sample_files:
            for test, sample_file in sample_files.iteritems():
                writer = TestResultWriter(self._port._filesystem, self._port, self._port.results_directory(), test)
                writer.copy_sample_file(sample_file)

        crash_logs = self._port.look_for_new_crash_logs(crashed_processes, start_time)
        if crash_logs:
            for test, crash_log in crash_logs.iteritems():
                writer = TestResultWriter(self._port._filesystem, self._port, self._port.results_directory(), test)
                writer.write_crash_log(crash_log)

    def _clobber_old_results(self):
        # Just clobber the actual test results directories since the other
        # files in the results directory are explicitly used for cross-run
        # tracking.
        self._printer.write_update("Clobbering old results in %s" %
                                   self._results_directory)
        layout_tests_dir = self._port.layout_tests_dir()
        possible_dirs = self._port.test_dirs()
        for dirname in possible_dirs:
            if self._filesystem.isdir(self._filesystem.join(layout_tests_dir, dirname)):
                self._filesystem.rmtree(self._filesystem.join(self._results_directory, dirname))

        # Port specific clean-up.
        self._port.clobber_old_port_specific_results()

    def _tests_to_retry(self, run_results):
        return [result.test_name for result in run_results.unexpected_results_by_name.values() if result.type != test_expectations.PASS]

    def _write_json_files(self, summarized_full_results, summarized_failing_results, initial_results):
        _log.debug("Writing JSON files in %s." % self._results_directory)

        # FIXME: Upload stats.json to the server and delete times_ms.
        times_trie = json_results_generator.test_timings_trie(initial_results.results_by_name.values())
        times_json_path = self._filesystem.join(self._results_directory, "times_ms.json")
        json_results_generator.write_json(self._filesystem, times_trie, times_json_path)

        stats_trie = self._stats_trie(initial_results)
        stats_path = self._filesystem.join(self._results_directory, "stats.json")
        self._filesystem.write_text_file(stats_path, json.dumps(stats_trie))

        full_results_path = self._filesystem.join(self._results_directory, "full_results.json")
        json_results_generator.write_json(self._filesystem, summarized_full_results, full_results_path)

        full_results_path = self._filesystem.join(self._results_directory, "failing_results.json")
        # We write failing_results.json out as jsonp because we need to load it from a file url for results.html and Chromium doesn't allow that.
        json_results_generator.write_json(self._filesystem, summarized_failing_results, full_results_path, callback="ADD_RESULTS")

        _log.debug("Finished writing JSON files.")

    def _upload_json_files(self):
        if not self._options.test_results_server:
            return

        if not self._options.master_name:
            _log.error("--test-results-server was set, but --master-name was not.  Not uploading JSON files.")
            return

        _log.debug("Uploading JSON files for builder: %s", self._options.builder_name)
        attrs = [("builder", self._options.builder_name),
                 ("testtype", "Sky tests"),
                 ("master", self._options.master_name)]

        files = [(file, self._filesystem.join(self._results_directory, file)) for file in ["failing_results.json", "full_results.json", "times_ms.json"]]

        url = "http://%s/testfile/upload" % self._options.test_results_server
        # Set uploading timeout in case appengine server is having problems.
        # 120 seconds are more than enough to upload test results.
        uploader = FileUploader(url, 120)
        try:
            response = uploader.upload_as_multipart_form_data(self._filesystem, files, attrs)
            if response:
                if response.code == 200:
                    _log.debug("JSON uploaded.")
                else:
                    _log.debug("JSON upload failed, %d: '%s'" % (response.code, response.read()))
            else:
                _log.error("JSON upload failed; no response returned")
        except Exception, err:
            _log.error("Upload failed: %s" % err)

    def _copy_results_html_file(self, destination_path):
        base_dir = self._port.path_from_webkit_base('tests', 'resources')
        results_file = self._filesystem.join(base_dir, 'results.html')
        # Note that the results.html template file won't exist when we're using a MockFileSystem during unit tests,
        # so make sure it exists before we try to copy it.
        if self._filesystem.exists(results_file):
            self._filesystem.copyfile(results_file, destination_path)

    def _stats_trie(self, initial_results):
        def _worker_number(worker_name):
            return int(worker_name.split('/')[1]) if worker_name else -1

        stats = {}
        for result in initial_results.results_by_name.values():
            if result.type != test_expectations.SKIP:
                stats[result.test_name] = {'results': (_worker_number(result.worker_name), result.test_number, result.pid, int(result.test_run_time * 1000), int(result.total_run_time * 1000))}
        stats_trie = {}
        for name, value in stats.iteritems():
            json_results_generator.add_path_to_trie(name, value, stats_trie)
        return stats_trie
