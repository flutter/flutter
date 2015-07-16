# Copyright (C) 2011 Google Inc. All rights reserved.
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
import math
import threading
import time

from webkitpy.common import message_pool
from webkitpy.layout_tests.controllers import single_test_runner
from webkitpy.layout_tests.models.test_run_results import TestRunResults
from webkitpy.layout_tests.models import test_expectations
from webkitpy.layout_tests.models import test_failures
from webkitpy.layout_tests.models import test_results
from webkitpy.tool import grammar


_log = logging.getLogger(__name__)


TestExpectations = test_expectations.TestExpectations

# Export this so callers don't need to know about message pools.
WorkerException = message_pool.WorkerException


class TestRunInterruptedException(Exception):
    """Raised when a test run should be stopped immediately."""
    def __init__(self, reason):
        Exception.__init__(self)
        self.reason = reason
        self.msg = reason

    def __reduce__(self):
        return self.__class__, (self.reason,)


class LayoutTestRunner(object):
    def __init__(self, options, port, printer, results_directory, test_is_slow_fn):
        self._options = options
        self._port = port
        self._printer = printer
        self._results_directory = results_directory
        self._test_is_slow = test_is_slow_fn
        self._sharder = Sharder(self._port.split_test, self._options.max_locked_shards)
        self._filesystem = self._port.host.filesystem

        self._expectations = None
        self._test_inputs = []
        self._retrying = False

        self._current_run_results = None

    def run_tests(self, expectations, test_inputs, tests_to_skip, num_workers, retrying):
        self._expectations = expectations
        self._test_inputs = test_inputs
        self._retrying = retrying
        self._shards_to_redo = []

        # FIXME: rename all variables to test_run_results or some such ...
        run_results = TestRunResults(self._expectations, len(test_inputs) + len(tests_to_skip))
        self._current_run_results = run_results
        self._printer.num_tests = len(test_inputs)
        self._printer.num_completed = 0

        if not retrying:
            self._printer.print_expected(run_results, self._expectations.get_tests_with_result_type)

        for test_name in set(tests_to_skip):
            result = test_results.TestResult(test_name)
            result.type = test_expectations.SKIP
            run_results.add(result, expected=True, test_is_slow=self._test_is_slow(test_name))

        self._printer.write_update('Sharding tests ...')
        locked_shards, unlocked_shards = self._sharder.shard_tests(test_inputs,
            int(self._options.child_processes), self._options.fully_parallel,
            self._options.run_singly or (self._options.batch_size == 1))

        # We don't have a good way to coordinate the workers so that they don't
        # try to run the shards that need a lock. The easiest solution is to
        # run all of the locked shards first.
        all_shards = locked_shards + unlocked_shards
        num_workers = min(num_workers, len(all_shards))
        self._printer.print_workers_and_shards(num_workers, len(all_shards), len(locked_shards))

        if self._options.dry_run:
            return run_results

        self._printer.write_update('Starting %s ...' % grammar.pluralize('worker', num_workers))

        start_time = time.time()
        try:
            with message_pool.get(self, self._worker_factory, num_workers, self._port.host) as pool:
                pool.run(('test_list', shard.name, shard.test_inputs) for shard in all_shards)

            if self._shards_to_redo:
                num_workers -= len(self._shards_to_redo)
                if num_workers > 0:
                    with message_pool.get(self, self._worker_factory, num_workers, self._port.host) as pool:
                        pool.run(('test_list', shard.name, shard.test_inputs) for shard in self._shards_to_redo)
        except TestRunInterruptedException, e:
            _log.warning(e.reason)
            run_results.interrupted = True
        except KeyboardInterrupt:
            self._printer.flush()
            self._printer.writeln('Interrupted, exiting ...')
            run_results.keyboard_interrupted = True
        except Exception, e:
            _log.debug('%s("%s") raised, exiting' % (e.__class__.__name__, str(e)))
            raise
        finally:
            run_results.run_time = time.time() - start_time

        return run_results

    def _worker_factory(self, worker_connection):
        results_directory = self._results_directory
        if self._retrying:
            self._filesystem.maybe_make_directory(self._filesystem.join(self._results_directory, 'retries'))
            results_directory = self._filesystem.join(self._results_directory, 'retries')
        return Worker(worker_connection, results_directory, self._options)

    def _mark_interrupted_tests_as_skipped(self, run_results):
        for test_input in self._test_inputs:
            if test_input.test_name not in run_results.results_by_name:
                result = test_results.TestResult(test_input.test_name, [test_failures.FailureEarlyExit()])
                # FIXME: We probably need to loop here if there are multiple iterations.
                # FIXME: Also, these results are really neither expected nor unexpected. We probably
                # need a third type of result.
                run_results.add(result, expected=False, test_is_slow=self._test_is_slow(test_input.test_name))

    def _interrupt_if_at_failure_limits(self, run_results):
        # Note: The messages in this method are constructed to match old-run-webkit-tests
        # so that existing buildbot grep rules work.
        def interrupt_if_at_failure_limit(limit, failure_count, run_results, message):
            if limit and failure_count >= limit:
                message += " %d tests run." % (run_results.expected + run_results.unexpected)
                self._mark_interrupted_tests_as_skipped(run_results)
                raise TestRunInterruptedException(message)

        interrupt_if_at_failure_limit(
            self._options.exit_after_n_failures,
            run_results.unexpected_failures,
            run_results,
            "Exiting early after %d failures." % run_results.unexpected_failures)
        interrupt_if_at_failure_limit(
            self._options.exit_after_n_crashes_or_timeouts,
            run_results.unexpected_crashes + run_results.unexpected_timeouts,
            run_results,
            # This differs from ORWT because it does not include WebProcess crashes.
            "Exiting early after %d crashes and %d timeouts." % (run_results.unexpected_crashes, run_results.unexpected_timeouts))

    def _update_summary_with_result(self, run_results, result):
        expected = self._expectations.matches_an_expected_result(result.test_name, result.type, self._options.pixel_tests or result.reftest_type, self._options.enable_sanitizer)
        exp_str = self._expectations.get_expectations_string(result.test_name)
        got_str = self._expectations.expectation_to_string(result.type)

        if result.device_failed:
            self._printer.print_finished_test(result, False, exp_str, "Aborted")
            return

        run_results.add(result, expected, self._test_is_slow(result.test_name))
        self._printer.print_finished_test(result, expected, exp_str, got_str)
        self._interrupt_if_at_failure_limits(run_results)

    def handle(self, name, source, *args):
        method = getattr(self, '_handle_' + name)
        if method:
            return method(source, *args)
        raise AssertionError('unknown message %s received from %s, args=%s' % (name, source, repr(args)))

    def _handle_started_test(self, worker_name, test_input, test_timeout_sec):
        self._printer.print_started_test(test_input.test_name)

    def _handle_finished_test_list(self, worker_name, list_name):
        pass

    def _handle_finished_test(self, worker_name, result, log_messages=[]):
        self._update_summary_with_result(self._current_run_results, result)

    def _handle_device_failed(self, worker_name, list_name, remaining_tests):
        _log.warning("%s has failed" % worker_name)
        if remaining_tests:
            self._shards_to_redo.append(TestShard(list_name, remaining_tests))

class Worker(object):
    def __init__(self, caller, results_directory, options):
        self._caller = caller
        self._worker_number = caller.worker_number
        self._name = caller.name
        self._results_directory = results_directory
        self._options = options

        # The remaining fields are initialized in start()
        self._host = None
        self._port = None
        self._batch_size = None
        self._batch_count = None
        self._filesystem = None
        self._driver = None
        self._num_tests = 0

    def __del__(self):
        self.stop()

    def start(self):
        """This method is called when the object is starting to be used and it is safe
        for the object to create state that does not need to be pickled (usually this means
        it is called in a child process)."""
        self._host = self._caller.host
        self._filesystem = self._host.filesystem
        self._port = self._host.port_factory.get(self._options.platform, self._options)

        self._batch_count = 0
        self._batch_size = self._options.batch_size or 0

    def handle(self, name, source, test_list_name, test_inputs):
        assert name == 'test_list'
        for i, test_input in enumerate(test_inputs):
            device_failed = self._run_test(test_input, test_list_name)
            if device_failed:
                self._caller.post('device_failed', test_list_name, test_inputs[i:])
                self._caller.stop_running()
                return

        self._caller.post('finished_test_list', test_list_name)

    def _update_test_input(self, test_input):
        if test_input.reference_files is None:
            # Lazy initialization.
            test_input.reference_files = self._port.reference_files(test_input.test_name)
        if test_input.reference_files:
            test_input.should_run_pixel_test = True
        else:
            test_input.should_run_pixel_test = self._port.should_run_as_pixel_test(test_input)

    def _run_test(self, test_input, shard_name):
        self._batch_count += 1

        stop_when_done = False
        if self._batch_size > 0 and self._batch_count >= self._batch_size:
            self._batch_count = 0
            stop_when_done = True

        self._update_test_input(test_input)
        test_timeout_sec = self._timeout(test_input)
        start = time.time()
        device_failed = False

        if self._driver and self._driver.has_crashed():
            self._kill_driver()
        if not self._driver:
            self._driver = self._port.create_driver(self._worker_number)

        if not self._driver:
            # FIXME: Is this the best way to handle a device crashing in the middle of the test, or should we create
            # a new failure type?
            device_failed = True
            return device_failed

        self._caller.post('started_test', test_input, test_timeout_sec)
        result = single_test_runner.run_single_test(self._port, self._options, self._results_directory,
            self._name, self._driver, test_input, stop_when_done)

        result.shard_name = shard_name
        result.worker_name = self._name
        result.total_run_time = time.time() - start
        result.test_number = self._num_tests
        self._num_tests += 1
        self._caller.post('finished_test', result)
        self._clean_up_after_test(test_input, result)
        return result.device_failed

    def stop(self):
        _log.debug("%s cleaning up" % self._name)
        self._kill_driver()

    def _timeout(self, test_input):
        """Compute the appropriate timeout value for a test."""
        # The driver watchdog uses 2.5x the timeout; we want to be
        # larger than that. We also add a little more padding if we're
        # running tests in a separate thread.
        #
        # Note that we need to convert the test timeout from a
        # string value in milliseconds to a float for Python.

        # FIXME: Can we just return the test_input.timeout now?
        driver_timeout_sec = 3.0 * float(test_input.timeout) / 1000.0

    def _kill_driver(self):
        # Be careful about how and when we kill the driver; if driver.stop()
        # raises an exception, this routine may get re-entered via __del__.
        driver = self._driver
        self._driver = None
        if driver:
            _log.debug("%s killing driver" % self._name)
            driver.stop()


    def _clean_up_after_test(self, test_input, result):
        test_name = test_input.test_name

        if result.failures:
            # Check and kill the driver if we need to.
            if any([f.driver_needs_restart() for f in result.failures]):
                self._kill_driver()
                # Reset the batch count since the shell just bounced.
                self._batch_count = 0

            # Print the error message(s).
            _log.debug("%s %s failed:" % (self._name, test_name))
            for f in result.failures:
                _log.debug("%s  %s" % (self._name, f.message()))
        elif result.type == test_expectations.SKIP:
            _log.debug("%s %s skipped" % (self._name, test_name))
        else:
            _log.debug("%s %s passed" % (self._name, test_name))


class TestShard(object):
    """A test shard is a named list of TestInputs."""

    def __init__(self, name, test_inputs):
        self.name = name
        self.test_inputs = test_inputs
        self.requires_lock = test_inputs[0].requires_lock

    def __repr__(self):
        return "TestShard(name='%s', test_inputs=%s, requires_lock=%s'" % (self.name, self.test_inputs, self.requires_lock)

    def __eq__(self, other):
        return self.name == other.name and self.test_inputs == other.test_inputs


class Sharder(object):
    def __init__(self, test_split_fn, max_locked_shards):
        self._split = test_split_fn
        self._max_locked_shards = max_locked_shards

    def shard_tests(self, test_inputs, num_workers, fully_parallel, run_singly):
        """Groups tests into batches.
        This helps ensure that tests that depend on each other (aka bad tests!)
        continue to run together as most cross-tests dependencies tend to
        occur within the same directory.
        Return:
            Two list of TestShards. The first contains tests that must only be
            run under the server lock, the second can be run whenever.
        """

        # FIXME: Move all of the sharding logic out of manager into its
        # own class or module. Consider grouping it with the chunking logic
        # in prepare_lists as well.
        if num_workers == 1:
            return self._shard_in_two(test_inputs)
        elif fully_parallel:
            return self._shard_every_file(test_inputs, run_singly)
        return self._shard_by_directory(test_inputs)

    def _shard_in_two(self, test_inputs):
        """Returns two lists of shards, one with all the tests requiring a lock and one with the rest.

        This is used when there's only one worker, to minimize the per-shard overhead."""
        locked_inputs = []
        unlocked_inputs = []
        for test_input in test_inputs:
            if test_input.requires_lock:
                locked_inputs.append(test_input)
            else:
                unlocked_inputs.append(test_input)

        locked_shards = []
        unlocked_shards = []
        if locked_inputs:
            locked_shards = [TestShard('locked_tests', locked_inputs)]
        if unlocked_inputs:
            unlocked_shards = [TestShard('unlocked_tests', unlocked_inputs)]

        return locked_shards, unlocked_shards

    def _shard_every_file(self, test_inputs, run_singly):
        """Returns two lists of shards, each shard containing a single test file.

        This mode gets maximal parallelism at the cost of much higher flakiness."""
        locked_shards = []
        unlocked_shards = []
        virtual_inputs = []

        for test_input in test_inputs:
            # Note that we use a '.' for the shard name; the name doesn't really
            # matter, and the only other meaningful value would be the filename,
            # which would be really redundant.
            if test_input.requires_lock:
                locked_shards.append(TestShard('.', [test_input]))
            elif test_input.test_name.startswith('virtual') and not run_singly:
                # This violates the spirit of sharding every file, but in practice, since the
                # virtual test suites require a different commandline flag and thus a restart
                # of content_shell, it's too slow to shard them fully.
                virtual_inputs.append(test_input)
            else:
                unlocked_shards.append(TestShard('.', [test_input]))

        locked_virtual_shards, unlocked_virtual_shards = self._shard_by_directory(virtual_inputs)

        # The locked shards still need to be limited to self._max_locked_shards in order to not
        # overload the http server for the http tests.
        return (self._resize_shards(locked_virtual_shards + locked_shards, self._max_locked_shards, 'locked_shard'),
            unlocked_virtual_shards + unlocked_shards)

    def _shard_by_directory(self, test_inputs):
        """Returns two lists of shards, each shard containing all the files in a directory.

        This is the default mode, and gets as much parallelism as we can while
        minimizing flakiness caused by inter-test dependencies."""
        locked_shards = []
        unlocked_shards = []
        unlocked_slow_shards = []
        tests_by_dir = {}
        # FIXME: Given that the tests are already sorted by directory,
        # we can probably rewrite this to be clearer and faster.
        for test_input in test_inputs:
            directory = self._split(test_input.test_name)[0]
            tests_by_dir.setdefault(directory, [])
            tests_by_dir[directory].append(test_input)

        for directory, test_inputs in tests_by_dir.iteritems():
            shard = TestShard(directory, test_inputs)
            if test_inputs[0].requires_lock:
                locked_shards.append(shard)
            # In practice, virtual test suites are slow to run. It's a bit hacky, but
            # put them first since they're the long-tail of test runtime.
            elif directory.startswith('virtual'):
                unlocked_slow_shards.append(shard)
            else:
                unlocked_shards.append(shard)

        # Sort the shards by directory name.
        locked_shards.sort(key=lambda shard: shard.name)
        unlocked_slow_shards.sort(key=lambda shard: shard.name)
        unlocked_shards.sort(key=lambda shard: shard.name)

        # Put a ceiling on the number of locked shards, so that we
        # don't hammer the servers too badly.

        # FIXME: For now, limit to one shard or set it
        # with the --max-locked-shards. After testing to make sure we
        # can handle multiple shards, we should probably do something like
        # limit this to no more than a quarter of all workers, e.g.:
        # return max(math.ceil(num_workers / 4.0), 1)
        return (self._resize_shards(locked_shards, self._max_locked_shards, 'locked_shard'),
                unlocked_slow_shards + unlocked_shards)

    def _resize_shards(self, old_shards, max_new_shards, shard_name_prefix):
        """Takes a list of shards and redistributes the tests into no more
        than |max_new_shards| new shards."""

        # This implementation assumes that each input shard only contains tests from a
        # single directory, and that tests in each shard must remain together; as a
        # result, a given input shard is never split between output shards.
        #
        # Each output shard contains the tests from one or more input shards and
        # hence may contain tests from multiple directories.

        def divide_and_round_up(numerator, divisor):
            return int(math.ceil(float(numerator) / divisor))

        def extract_and_flatten(shards):
            test_inputs = []
            for shard in shards:
                test_inputs.extend(shard.test_inputs)
            return test_inputs

        def split_at(seq, index):
            return (seq[:index], seq[index:])

        num_old_per_new = divide_and_round_up(len(old_shards), max_new_shards)
        new_shards = []
        remaining_shards = old_shards
        while remaining_shards:
            some_shards, remaining_shards = split_at(remaining_shards, num_old_per_new)
            new_shards.append(TestShard('%s_%d' % (shard_name_prefix, len(new_shards) + 1), extract_and_flatten(some_shards)))
        return new_shards
