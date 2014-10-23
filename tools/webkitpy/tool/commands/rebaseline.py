# Copyright (c) 2010 Google Inc. All rights reserved.
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
# (INCLUDING NEGLIGENCE OR/ OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Queue
import json
import logging
import optparse
import re
import sys
import threading
import time
import traceback
import urllib
import urllib2

from webkitpy.common.checkout.baselineoptimizer import BaselineOptimizer
from webkitpy.common.memoized import memoized
from webkitpy.common.system.executive import ScriptError
from webkitpy.layout_tests.controllers.test_result_writer import TestResultWriter
from webkitpy.layout_tests.models import test_failures
from webkitpy.layout_tests.models.test_expectations import TestExpectations, BASELINE_SUFFIX_LIST, SKIP
from webkitpy.layout_tests.port import builders
from webkitpy.layout_tests.port import factory
from webkitpy.tool.multicommandtool import AbstractDeclarativeCommand


_log = logging.getLogger(__name__)


# FIXME: Should TestResultWriter know how to compute this string?
def _baseline_name(fs, test_name, suffix):
    return fs.splitext(test_name)[0] + TestResultWriter.FILENAME_SUFFIX_EXPECTED + "." + suffix


class AbstractRebaseliningCommand(AbstractDeclarativeCommand):
    # not overriding execute() - pylint: disable=W0223

    no_optimize_option = optparse.make_option('--no-optimize', dest='optimize', action='store_false', default=True,
        help=('Do not optimize/de-dup the expectations after rebaselining (default is to de-dup automatically). '
              'You can use "webkit-patch optimize-baselines" to optimize separately.'))

    platform_options = factory.platform_options(use_globs=True)

    results_directory_option = optparse.make_option("--results-directory", help="Local results directory to use")

    suffixes_option = optparse.make_option("--suffixes", default=','.join(BASELINE_SUFFIX_LIST), action="store",
        help="Comma-separated-list of file types to rebaseline")

    def __init__(self, options=None):
        super(AbstractRebaseliningCommand, self).__init__(options=options)
        self._baseline_suffix_list = BASELINE_SUFFIX_LIST
        self._scm_changes = {'add': [], 'delete': [], 'remove-lines': []}

    def _add_to_scm_later(self, path):
        self._scm_changes['add'].append(path)

    def _delete_from_scm_later(self, path):
        self._scm_changes['delete'].append(path)


class BaseInternalRebaselineCommand(AbstractRebaseliningCommand):
    def __init__(self):
        super(BaseInternalRebaselineCommand, self).__init__(options=[
            self.results_directory_option,
            self.suffixes_option,
            optparse.make_option("--builder", help="Builder to pull new baselines from"),
            optparse.make_option("--test", help="Test to rebaseline"),
            ])

    def _baseline_directory(self, builder_name):
        port = self._tool.port_factory.get_from_builder_name(builder_name)
        override_dir = builders.rebaseline_override_dir(builder_name)
        if override_dir:
            return self._tool.filesystem.join(port.layout_tests_dir(), 'platform', override_dir)
        return port.baseline_version_dir()

    def _test_root(self, test_name):
        return self._tool.filesystem.splitext(test_name)[0]

    def _file_name_for_actual_result(self, test_name, suffix):
        return "%s-actual.%s" % (self._test_root(test_name), suffix)

    def _file_name_for_expected_result(self, test_name, suffix):
        return "%s-expected.%s" % (self._test_root(test_name), suffix)


class CopyExistingBaselinesInternal(BaseInternalRebaselineCommand):
    name = "copy-existing-baselines-internal"
    help_text = "Copy existing baselines down one level in the baseline order to ensure new baselines don't break existing passing platforms."

    @memoized
    def _immediate_predecessors_in_fallback(self, path_to_rebaseline):
        port_names = self._tool.port_factory.all_port_names()
        immediate_predecessors_in_fallback = []
        for port_name in port_names:
            port = self._tool.port_factory.get(port_name)
            if not port.buildbot_archives_baselines():
                continue
            baseline_search_path = port.baseline_search_path()
            try:
                index = baseline_search_path.index(path_to_rebaseline)
                if index:
                    immediate_predecessors_in_fallback.append(self._tool.filesystem.basename(baseline_search_path[index - 1]))
            except ValueError:
                # index throw's a ValueError if the item isn't in the list.
                pass
        return immediate_predecessors_in_fallback

    def _port_for_primary_baseline(self, baseline):
        for port in [self._tool.port_factory.get(port_name) for port_name in self._tool.port_factory.all_port_names()]:
            if self._tool.filesystem.basename(port.baseline_version_dir()) == baseline:
                return port
        raise Exception("Failed to find port for primary baseline %s." % baseline)

    def _copy_existing_baseline(self, builder_name, test_name, suffix):
        baseline_directory = self._baseline_directory(builder_name)
        ports = [self._port_for_primary_baseline(baseline) for baseline in self._immediate_predecessors_in_fallback(baseline_directory)]

        old_baselines = []
        new_baselines = []

        # Need to gather all the baseline paths before modifying the filesystem since
        # the modifications can affect the results of port.expected_filename.
        for port in ports:
            old_baseline = port.expected_filename(test_name, "." + suffix)
            if not self._tool.filesystem.exists(old_baseline):
                _log.debug("No existing baseline for %s." % test_name)
                continue

            new_baseline = self._tool.filesystem.join(port.baseline_path(), self._file_name_for_expected_result(test_name, suffix))
            if self._tool.filesystem.exists(new_baseline):
                _log.debug("Existing baseline at %s, not copying over it." % new_baseline)
                continue

            expectations = TestExpectations(port, [test_name])
            if SKIP in expectations.get_expectations(test_name):
                _log.debug("%s is skipped on %s." % (test_name, port.name()))
                continue

            old_baselines.append(old_baseline)
            new_baselines.append(new_baseline)

        for i in range(len(old_baselines)):
            old_baseline = old_baselines[i]
            new_baseline = new_baselines[i]

            _log.debug("Copying baseline from %s to %s." % (old_baseline, new_baseline))
            self._tool.filesystem.maybe_make_directory(self._tool.filesystem.dirname(new_baseline))
            self._tool.filesystem.copyfile(old_baseline, new_baseline)
            if not self._tool.scm().exists(new_baseline):
                self._add_to_scm_later(new_baseline)

    def execute(self, options, args, tool):
        for suffix in options.suffixes.split(','):
            self._copy_existing_baseline(options.builder, options.test, suffix)
        print json.dumps(self._scm_changes)


class RebaselineTest(BaseInternalRebaselineCommand):
    name = "rebaseline-test-internal"
    help_text = "Rebaseline a single test from a buildbot. Only intended for use by other webkit-patch commands."

    def _results_url(self, builder_name):
        return self._tool.buildbot_for_builder_name(builder_name).builder_with_name(builder_name).latest_layout_test_results_url()

    def _save_baseline(self, data, target_baseline, baseline_directory, test_name, suffix):
        if not data:
            _log.debug("No baseline data to save.")
            return

        filesystem = self._tool.filesystem
        filesystem.maybe_make_directory(filesystem.dirname(target_baseline))
        filesystem.write_binary_file(target_baseline, data)
        if not self._tool.scm().exists(target_baseline):
            self._add_to_scm_later(target_baseline)

    def _rebaseline_test(self, builder_name, test_name, suffix, results_url):
        baseline_directory = self._baseline_directory(builder_name)

        source_baseline = "%s/%s" % (results_url, self._file_name_for_actual_result(test_name, suffix))
        target_baseline = self._tool.filesystem.join(baseline_directory, self._file_name_for_expected_result(test_name, suffix))

        _log.debug("Retrieving %s." % source_baseline)
        self._save_baseline(self._tool.web.get_binary(source_baseline, convert_404_to_None=True), target_baseline, baseline_directory, test_name, suffix)

    def _rebaseline_test_and_update_expectations(self, options):
        port = self._tool.port_factory.get_from_builder_name(options.builder)
        if (port.reference_files(options.test)):
            _log.warning("Cannot rebaseline reftest: %s", options.test)
            return

        if options.results_directory:
            results_url = 'file://' + options.results_directory
        else:
            results_url = self._results_url(options.builder)
        self._baseline_suffix_list = options.suffixes.split(',')

        for suffix in self._baseline_suffix_list:
            self._rebaseline_test(options.builder, options.test, suffix, results_url)
        self._scm_changes['remove-lines'].append({'builder': options.builder, 'test': options.test})

    def execute(self, options, args, tool):
        self._rebaseline_test_and_update_expectations(options)
        print json.dumps(self._scm_changes)


class OptimizeBaselines(AbstractRebaseliningCommand):
    name = "optimize-baselines"
    help_text = "Reshuffles the baselines for the given tests to use as litte space on disk as possible."
    show_in_main_help = True
    argument_names = "TEST_NAMES"

    def __init__(self):
        super(OptimizeBaselines, self).__init__(options=[
            self.suffixes_option,
            optparse.make_option('--no-modify-scm', action='store_true', default=False, help='Dump SCM commands as JSON instead of '),
            ] + self.platform_options)

    def _optimize_baseline(self, optimizer, test_name):
        files_to_delete = []
        files_to_add = []
        for suffix in self._baseline_suffix_list:
            baseline_name = _baseline_name(self._tool.filesystem, test_name, suffix)
            succeeded, more_files_to_delete, more_files_to_add = optimizer.optimize(baseline_name)
            if not succeeded:
                print "Heuristics failed to optimize %s" % baseline_name
            files_to_delete.extend(more_files_to_delete)
            files_to_add.extend(more_files_to_add)
        return files_to_delete, files_to_add

    def execute(self, options, args, tool):
        self._baseline_suffix_list = options.suffixes.split(',')
        port_names = tool.port_factory.all_port_names(options.platform)
        if not port_names:
            print "No port names match '%s'" % options.platform
            return

        optimizer = BaselineOptimizer(tool, port_names, skip_scm_commands=options.no_modify_scm)
        port = tool.port_factory.get(port_names[0])
        for test_name in port.tests(args):
            _log.info("Optimizing %s" % test_name)
            files_to_delete, files_to_add = self._optimize_baseline(optimizer, test_name)
            for path in files_to_delete:
                self._delete_from_scm_later(path)
            for path in files_to_add:
                self._add_to_scm_later(path)

        print json.dumps(self._scm_changes)


class AnalyzeBaselines(AbstractRebaseliningCommand):
    name = "analyze-baselines"
    help_text = "Analyzes the baselines for the given tests and prints results that are identical."
    show_in_main_help = True
    argument_names = "TEST_NAMES"

    def __init__(self):
        super(AnalyzeBaselines, self).__init__(options=[
            self.suffixes_option,
            optparse.make_option('--missing', action='store_true', default=False, help='show missing baselines as well'),
            ] + self.platform_options)
        self._optimizer_class = BaselineOptimizer  # overridable for testing
        self._baseline_optimizer = None
        self._port = None

    def _write(self, msg):
        print msg

    def _analyze_baseline(self, options, test_name):
        for suffix in self._baseline_suffix_list:
            baseline_name = _baseline_name(self._tool.filesystem, test_name, suffix)
            results_by_directory = self._baseline_optimizer.read_results_by_directory(baseline_name)
            if results_by_directory:
                self._write("%s:" % baseline_name)
                self._baseline_optimizer.write_by_directory(results_by_directory, self._write, "  ")
            elif options.missing:
                self._write("%s: (no baselines found)" % baseline_name)

    def execute(self, options, args, tool):
        self._baseline_suffix_list = options.suffixes.split(',')
        port_names = tool.port_factory.all_port_names(options.platform)
        if not port_names:
            print "No port names match '%s'" % options.platform
            return

        self._baseline_optimizer = self._optimizer_class(tool, port_names, skip_scm_commands=False)
        self._port = tool.port_factory.get(port_names[0])
        for test_name in self._port.tests(args):
            self._analyze_baseline(options, test_name)


class AbstractParallelRebaselineCommand(AbstractRebaseliningCommand):
    # not overriding execute() - pylint: disable=W0223

    def __init__(self, options=None):
        super(AbstractParallelRebaselineCommand, self).__init__(options=options)
        self._builder_data = {}

    def builder_data(self):
        if not self._builder_data:
            for builder_name in self._release_builders():
                builder = self._tool.buildbot_for_builder_name(builder_name).builder_with_name(builder_name)
                self._builder_data[builder_name] = builder.latest_layout_test_results()
        return self._builder_data

    # The release builders cycle much faster than the debug ones and cover all the platforms.
    def _release_builders(self):
        release_builders = []
        for builder_name in builders.all_builder_names():
            if builder_name.find('ASAN') != -1:
                continue
            port = self._tool.port_factory.get_from_builder_name(builder_name)
            if port.test_configuration().build_type == 'release':
                release_builders.append(builder_name)
        return release_builders

    def _run_webkit_patch(self, args, verbose):
        try:
            verbose_args = ['--verbose'] if verbose else []
            stderr = self._tool.executive.run_command([self._tool.path()] + verbose_args + args, cwd=self._tool.scm().checkout_root, return_stderr=True)
            for line in stderr.splitlines():
                _log.warning(line)
        except ScriptError, e:
            _log.error(e)

    def _builders_to_fetch_from(self, builders_to_check):
        # This routine returns the subset of builders that will cover all of the baseline search paths
        # used in the input list. In particular, if the input list contains both Release and Debug
        # versions of a configuration, we *only* return the Release version (since we don't save
        # debug versions of baselines).
        release_builders = set()
        debug_builders = set()
        builders_to_fallback_paths = {}
        for builder in builders_to_check:
            port = self._tool.port_factory.get_from_builder_name(builder)
            if port.test_configuration().build_type == 'release':
                release_builders.add(builder)
            else:
                debug_builders.add(builder)
        for builder in list(release_builders) + list(debug_builders):
            port = self._tool.port_factory.get_from_builder_name(builder)
            fallback_path = port.baseline_search_path()
            if fallback_path not in builders_to_fallback_paths.values():
                builders_to_fallback_paths[builder] = fallback_path
        return builders_to_fallback_paths.keys()

    def _rebaseline_commands(self, test_prefix_list, options):
        path_to_webkit_patch = self._tool.path()
        cwd = self._tool.scm().checkout_root
        copy_baseline_commands = []
        rebaseline_commands = []
        lines_to_remove = {}
        port = self._tool.port_factory.get()

        for test_prefix in test_prefix_list:
            for test in port.tests([test_prefix]):
                for builder in self._builders_to_fetch_from(test_prefix_list[test_prefix]):
                    actual_failures_suffixes = self._suffixes_for_actual_failures(test, builder, test_prefix_list[test_prefix][builder])
                    if not actual_failures_suffixes:
                        # If we're not going to rebaseline the test because it's passing on this
                        # builder, we still want to remove the line from TestExpectations.
                        if test not in lines_to_remove:
                            lines_to_remove[test] = []
                        lines_to_remove[test].append(builder)
                        continue

                    suffixes = ','.join(actual_failures_suffixes)
                    cmd_line = ['--suffixes', suffixes, '--builder', builder, '--test', test]
                    if options.results_directory:
                        cmd_line.extend(['--results-directory', options.results_directory])
                    if options.verbose:
                        cmd_line.append('--verbose')
                    copy_baseline_commands.append(tuple([[self._tool.executable, path_to_webkit_patch, 'copy-existing-baselines-internal'] + cmd_line, cwd]))
                    rebaseline_commands.append(tuple([[self._tool.executable, path_to_webkit_patch, 'rebaseline-test-internal'] + cmd_line, cwd]))
        return copy_baseline_commands, rebaseline_commands, lines_to_remove

    def _serial_commands(self, command_results):
        files_to_add = set()
        files_to_delete = set()
        lines_to_remove = {}
        for output in [result[1].split('\n') for result in command_results]:
            file_added = False
            for line in output:
                try:
                    if line:
                        parsed_line = json.loads(line)
                        if 'add' in parsed_line:
                            files_to_add.update(parsed_line['add'])
                        if 'delete' in parsed_line:
                            files_to_delete.update(parsed_line['delete'])
                        if 'remove-lines' in parsed_line:
                            for line_to_remove in parsed_line['remove-lines']:
                                test = line_to_remove['test']
                                builder = line_to_remove['builder']
                                if test not in lines_to_remove:
                                    lines_to_remove[test] = []
                                lines_to_remove[test].append(builder)
                        file_added = True
                except ValueError:
                    _log.debug('"%s" is not a JSON object, ignoring' % line)

            if not file_added:
                _log.debug('Could not add file based off output "%s"' % output)

        return list(files_to_add), list(files_to_delete), lines_to_remove

    def _optimize_baselines(self, test_prefix_list, verbose=False):
        optimize_commands = []
        for test in test_prefix_list:
            all_suffixes = set()
            for builder in self._builders_to_fetch_from(test_prefix_list[test]):
                all_suffixes.update(self._suffixes_for_actual_failures(test, builder, test_prefix_list[test][builder]))

            # FIXME: We should propagate the platform options as well.
            cmd_line = ['--no-modify-scm', '--suffixes', ','.join(all_suffixes), test]
            if verbose:
                cmd_line.append('--verbose')

            path_to_webkit_patch = self._tool.path()
            cwd = self._tool.scm().checkout_root
            optimize_commands.append(tuple([[self._tool.executable, path_to_webkit_patch, 'optimize-baselines'] + cmd_line, cwd]))
        return optimize_commands

    def _update_expectations_files(self, lines_to_remove):
        # FIXME: This routine is way too expensive. We're creating O(n ports) TestExpectations objects.
        # This is slow and uses a lot of memory.
        tests = lines_to_remove.keys()
        to_remove = []

        # This is so we remove lines for builders that skip this test, e.g. Android skips most
        # tests and we don't want to leave stray [ Android ] lines in TestExpectations..
        # This is only necessary for "webkit-patch rebaseline" and for rebaselining expected
        # failures from garden-o-matic. rebaseline-expectations and auto-rebaseline will always
        # pass the exact set of ports to rebaseline.
        for port_name in self._tool.port_factory.all_port_names():
            port = self._tool.port_factory.get(port_name)
            generic_expectations = TestExpectations(port, tests=tests, include_overrides=False)
            full_expectations = TestExpectations(port, tests=tests, include_overrides=True)
            for test in tests:
                if self._port_skips_test(port, test, generic_expectations, full_expectations):
                    for test_configuration in port.all_test_configurations():
                        if test_configuration.version == port.test_configuration().version:
                            to_remove.append((test, test_configuration))

        for test in lines_to_remove:
            for builder in lines_to_remove[test]:
                port = self._tool.port_factory.get_from_builder_name(builder)
                for test_configuration in port.all_test_configurations():
                    if test_configuration.version == port.test_configuration().version:
                        to_remove.append((test, test_configuration))

        port = self._tool.port_factory.get()
        expectations = TestExpectations(port, include_overrides=False)
        expectationsString = expectations.remove_configurations(to_remove)
        path = port.path_to_generic_test_expectations_file()
        self._tool.filesystem.write_text_file(path, expectationsString)

    def _port_skips_test(self, port, test, generic_expectations, full_expectations):
        fs = port.host.filesystem
        if port.default_smoke_test_only():
            smoke_test_filename = fs.join(port.layout_tests_dir(), 'SmokeTests')
            if fs.exists(smoke_test_filename) and test not in fs.read_text_file(smoke_test_filename):
                return True

        return (SKIP in full_expectations.get_expectations(test) and
                SKIP not in generic_expectations.get_expectations(test))

    def _run_in_parallel_and_update_scm(self, commands):
        command_results = self._tool.executive.run_in_parallel(commands)
        log_output = '\n'.join(result[2] for result in command_results).replace('\n\n', '\n')
        for line in log_output.split('\n'):
            if line:
                print >> sys.stderr, line  # FIXME: Figure out how to log properly.

        files_to_add, files_to_delete, lines_to_remove = self._serial_commands(command_results)
        if files_to_delete:
            self._tool.scm().delete_list(files_to_delete)
        if files_to_add:
            self._tool.scm().add_list(files_to_add)
        return lines_to_remove

    def _rebaseline(self, options, test_prefix_list):
        for test, builders_to_check in sorted(test_prefix_list.items()):
            _log.info("Rebaselining %s" % test)
            for builder, suffixes in sorted(builders_to_check.items()):
                _log.debug("  %s: %s" % (builder, ",".join(suffixes)))

        copy_baseline_commands, rebaseline_commands, extra_lines_to_remove = self._rebaseline_commands(test_prefix_list, options)
        lines_to_remove = {}

        if copy_baseline_commands:
            self._run_in_parallel_and_update_scm(copy_baseline_commands)
        if rebaseline_commands:
            lines_to_remove = self._run_in_parallel_and_update_scm(rebaseline_commands)

        for test in extra_lines_to_remove:
            if test in lines_to_remove:
                lines_to_remove[test] = lines_to_remove[test] + extra_lines_to_remove[test]
            else:
                lines_to_remove[test] = extra_lines_to_remove[test]

        if lines_to_remove:
            self._update_expectations_files(lines_to_remove)

        if options.optimize:
            self._run_in_parallel_and_update_scm(self._optimize_baselines(test_prefix_list, options.verbose))

    def _suffixes_for_actual_failures(self, test, builder_name, existing_suffixes):
        actual_results = self.builder_data()[builder_name].actual_results(test)
        if not actual_results:
            return set()
        return set(existing_suffixes) & TestExpectations.suffixes_for_actual_expectations_string(actual_results)


class RebaselineJson(AbstractParallelRebaselineCommand):
    name = "rebaseline-json"
    help_text = "Rebaseline based off JSON passed to stdin. Intended to only be called from other scripts."

    def __init__(self,):
        super(RebaselineJson, self).__init__(options=[
            self.no_optimize_option,
            self.results_directory_option,
            ])

    def execute(self, options, args, tool):
        self._rebaseline(options, json.loads(sys.stdin.read()))


class RebaselineExpectations(AbstractParallelRebaselineCommand):
    name = "rebaseline-expectations"
    help_text = "Rebaselines the tests indicated in TestExpectations."
    show_in_main_help = True

    def __init__(self):
        super(RebaselineExpectations, self).__init__(options=[
            self.no_optimize_option,
            ] + self.platform_options)
        self._test_prefix_list = None

    def _tests_to_rebaseline(self, port):
        tests_to_rebaseline = {}
        for path, value in port.expectations_dict().items():
            expectations = TestExpectations(port, include_overrides=False, expectations_dict={path: value})
            for test in expectations.get_rebaselining_failures():
                suffixes = TestExpectations.suffixes_for_expectations(expectations.get_expectations(test))
                tests_to_rebaseline[test] = suffixes or BASELINE_SUFFIX_LIST
        return tests_to_rebaseline

    def _add_tests_to_rebaseline_for_port(self, port_name):
        builder_name = builders.builder_name_for_port_name(port_name)
        if not builder_name:
            return
        tests = self._tests_to_rebaseline(self._tool.port_factory.get(port_name)).items()

        if tests:
            _log.info("Retrieving results for %s from %s." % (port_name, builder_name))

        for test_name, suffixes in tests:
            _log.info("    %s (%s)" % (test_name, ','.join(suffixes)))
            if test_name not in self._test_prefix_list:
                self._test_prefix_list[test_name] = {}
            self._test_prefix_list[test_name][builder_name] = suffixes

    def execute(self, options, args, tool):
        options.results_directory = None
        self._test_prefix_list = {}
        port_names = tool.port_factory.all_port_names(options.platform)
        for port_name in port_names:
            self._add_tests_to_rebaseline_for_port(port_name)
        if not self._test_prefix_list:
            _log.warning("Did not find any tests marked Rebaseline.")
            return

        self._rebaseline(options, self._test_prefix_list)


class Rebaseline(AbstractParallelRebaselineCommand):
    name = "rebaseline"
    help_text = "Rebaseline tests with results from the build bots. Shows the list of failing tests on the builders if no test names are provided."
    show_in_main_help = True
    argument_names = "[TEST_NAMES]"

    def __init__(self):
        super(Rebaseline, self).__init__(options=[
            self.no_optimize_option,
            # FIXME: should we support the platform options in addition to (or instead of) --builders?
            self.suffixes_option,
            self.results_directory_option,
            optparse.make_option("--builders", default=None, action="append", help="Comma-separated-list of builders to pull new baselines from (can also be provided multiple times)"),
            ])

    def _builders_to_pull_from(self):
        chosen_names = self._tool.user.prompt_with_list("Which builder to pull results from:", self._release_builders(), can_choose_multiple=True)
        return [self._builder_with_name(name) for name in chosen_names]

    def _builder_with_name(self, name):
        return self._tool.buildbot_for_builder_name(name).builder_with_name(name)

    def execute(self, options, args, tool):
        if not args:
            _log.error("Must list tests to rebaseline.")
            return

        if options.builders:
            builders_to_check = []
            for builder_names in options.builders:
                builders_to_check += [self._builder_with_name(name) for name in builder_names.split(",")]
        else:
            builders_to_check = self._builders_to_pull_from()

        test_prefix_list = {}
        suffixes_to_update = options.suffixes.split(",")

        for builder in builders_to_check:
            for test in args:
                if test not in test_prefix_list:
                    test_prefix_list[test] = {}
                test_prefix_list[test][builder.name()] = suffixes_to_update

        if options.verbose:
            _log.debug("rebaseline-json: " + str(test_prefix_list))

        self._rebaseline(options, test_prefix_list)


class AutoRebaseline(AbstractParallelRebaselineCommand):
    name = "auto-rebaseline"
    help_text = "Rebaselines any NeedsRebaseline lines in TestExpectations that have cycled through all the bots."
    AUTO_REBASELINE_BRANCH_NAME = "auto-rebaseline-temporary-branch"

    # Rietveld uploader stinks. Limit the number of rebaselines in a given patch to keep upload from failing.
    # FIXME: http://crbug.com/263676 Obviously we should fix the uploader here.
    MAX_LINES_TO_REBASELINE = 200

    SECONDS_BEFORE_GIVING_UP = 300

    def __init__(self):
        super(AutoRebaseline, self).__init__(options=[
            # FIXME: Remove this option.
            self.no_optimize_option,
            # FIXME: Remove this option.
            self.results_directory_option,
            ])

    def bot_revision_data(self):
        revisions = []
        for result in self.builder_data().values():
            if result.run_was_interrupted():
                _log.error("Can't rebaseline because the latest run on %s exited early." % result.builder_name())
                return []
            revisions.append({
                "builder": result.builder_name(),
                "revision": result.blink_revision(),
            })
        return revisions

    def tests_to_rebaseline(self, tool, min_revision, print_revisions):
        port = tool.port_factory.get()
        expectations_file_path = port.path_to_generic_test_expectations_file()

        tests = set()
        revision = None
        author = None
        bugs = set()
        has_any_needs_rebaseline_lines = False

        for line in tool.scm().blame(expectations_file_path).split("\n"):
            comment_index = line.find("#")
            if comment_index == -1:
                comment_index = len(line)
            line_without_comments = re.sub(r"\s+", " ", line[:comment_index].strip())

            if "NeedsRebaseline" not in line_without_comments:
                continue

            has_any_needs_rebaseline_lines = True

            parsed_line = re.match("^(\S*)[^(]*\((\S*).*?([^ ]*)\ \[[^[]*$", line_without_comments)

            commit_hash = parsed_line.group(1)
            svn_revision = tool.scm().svn_revision_from_git_commit(commit_hash)

            test = parsed_line.group(3)
            if print_revisions:
                _log.info("%s is waiting for r%s" % (test, svn_revision))

            if not svn_revision or svn_revision > min_revision:
                continue

            if revision and svn_revision != revision:
                continue

            if not revision:
                revision = svn_revision
                author = parsed_line.group(2)

            bugs.update(re.findall("crbug\.com\/(\d+)", line_without_comments))
            tests.add(test)

            if len(tests) >= self.MAX_LINES_TO_REBASELINE:
                _log.info("Too many tests to rebaseline in one patch. Doing the first %d." % self.MAX_LINES_TO_REBASELINE)
                break

        return tests, revision, author, bugs, has_any_needs_rebaseline_lines

    def link_to_patch(self, revision):
        return "http://src.chromium.org/viewvc/blink?view=revision&revision=" + str(revision)

    def commit_message(self, author, revision, bugs):
        bug_string = ""
        if bugs:
            bug_string = "BUG=%s\n" % ",".join(bugs)

        return """Auto-rebaseline for r%s

%s

%sTBR=%s
""" % (revision, self.link_to_patch(revision), bug_string, author)

    def get_test_prefix_list(self, tests):
        test_prefix_list = {}
        lines_to_remove = {}

        for builder_name in self._release_builders():
            port_name = builders.port_name_for_builder_name(builder_name)
            port = self._tool.port_factory.get(port_name)
            expectations = TestExpectations(port, include_overrides=True)
            for test in expectations.get_needs_rebaseline_failures():
                if test not in tests:
                    continue

                if test not in test_prefix_list:
                    lines_to_remove[test] = []
                    test_prefix_list[test] = {}
                lines_to_remove[test].append(builder_name)
                test_prefix_list[test][builder_name] = BASELINE_SUFFIX_LIST

        return test_prefix_list, lines_to_remove

    def _run_git_cl_command(self, options, command):
        subprocess_command = ['git', 'cl'] + command
        if options.verbose:
            subprocess_command.append('--verbose')

        process = self._tool.executive.popen(subprocess_command, stdout=self._tool.executive.PIPE, stderr=self._tool.executive.STDOUT)
        last_output_time = time.time()

        # git cl sometimes completely hangs. Bail if we haven't gotten any output to stdout/stderr in a while.
        while process.poll() == None and time.time() < last_output_time + self.SECONDS_BEFORE_GIVING_UP:
            # FIXME: This doesn't make any sense. readline blocks, so all this code to
            # try and bail is useless. Instead, we should do the readline calls on a
            # subthread. Then the rest of this code would make sense.
            out = process.stdout.readline().rstrip('\n')
            if out:
                last_output_time = time.time()
                _log.info(out)

        if process.poll() == None:
            _log.error('Command hung: %s' % subprocess_command)
            return False
        return True

    # FIXME: Move this somewhere more general.
    def tree_status(self):
        blink_tree_status_url = "http://blink-status.appspot.com/status"
        status = urllib2.urlopen(blink_tree_status_url).read().lower()
        if status.find('closed') != -1 or status == "0":
            return 'closed'
        elif status.find('open') != -1 or status == "1":
            return 'open'
        return 'unknown'

    def execute(self, options, args, tool):
        if tool.scm().executable_name == "svn":
            _log.error("Auto rebaseline only works with a git checkout.")
            return

        if tool.scm().has_working_directory_changes():
            _log.error("Cannot proceed with working directory changes. Clean working directory first.")
            return

        revision_data = self.bot_revision_data()
        if not revision_data:
            return

        min_revision = int(min([item["revision"] for item in revision_data]))
        tests, revision, author, bugs, has_any_needs_rebaseline_lines = self.tests_to_rebaseline(tool, min_revision, print_revisions=options.verbose)

        if options.verbose:
            _log.info("Min revision across all bots is %s." % min_revision)
            for item in revision_data:
                _log.info("%s: r%s" % (item["builder"], item["revision"]))

        if not tests:
            _log.debug('No tests to rebaseline.')
            return

        if self.tree_status() == 'closed':
            _log.info('Cannot proceed. Tree is closed.')
            return

        _log.info('Rebaselining %s for r%s by %s.' % (list(tests), revision, author))

        test_prefix_list, lines_to_remove = self.get_test_prefix_list(tests)

        did_finish = False
        try:
            old_branch_name = tool.scm().current_branch()
            tool.scm().delete_branch(self.AUTO_REBASELINE_BRANCH_NAME)
            tool.scm().create_clean_branch(self.AUTO_REBASELINE_BRANCH_NAME)

            # If the tests are passing everywhere, then this list will be empty. We don't need
            # to rebaseline, but we'll still need to update TestExpectations.
            if test_prefix_list:
                self._rebaseline(options, test_prefix_list)

            tool.scm().commit_locally_with_message(self.commit_message(author, revision, bugs))

            # FIXME: It would be nice if we could dcommit the patch without uploading, but still
            # go through all the precommit hooks. For rebaselines with lots of files, uploading
            # takes a long time and sometimes fails, but we don't want to commit if, e.g. the
            # tree is closed.
            did_finish = self._run_git_cl_command(options, ['upload', '-f'])

            if did_finish:
                # Uploading can take a very long time. Do another pull to make sure TestExpectations is up to date,
                # so the dcommit can go through.
                # FIXME: Log the pull and dcommit stdout/stderr to the log-server.
                tool.executive.run_command(['git', 'pull'])

                self._run_git_cl_command(options, ['dcommit', '-f'])
        except Exception as e:
            _log.error(e)
        finally:
            if did_finish:
                self._run_git_cl_command(options, ['set_close'])
            tool.scm().ensure_cleanly_tracking_remote_master()
            tool.scm().checkout_branch(old_branch_name)
            tool.scm().delete_branch(self.AUTO_REBASELINE_BRANCH_NAME)


class RebaselineOMatic(AbstractDeclarativeCommand):
    name = "rebaseline-o-matic"
    help_text = "Calls webkit-patch auto-rebaseline in a loop."
    show_in_main_help = True

    SLEEP_TIME_IN_SECONDS = 30
    LOG_SERVER = 'blinkrebaseline.appspot.com'
    QUIT_LOG = '##QUIT##'

    # Uploaded log entries append to the existing entry unless the
    # newentry flag is set. In that case it starts a new entry to
    # start appending to.
    def _log_to_server(self, log='', is_new_entry=False):
        query = {
            'log': log,
        }
        if is_new_entry:
            query['newentry'] = 'on'
        try:
            urllib2.urlopen("http://" + self.LOG_SERVER + "/updatelog", data=urllib.urlencode(query))
        except:
            traceback.print_exc(file=sys.stderr)

    def _log_to_server_thread(self):
        is_new_entry = True
        while True:
            messages = [self._log_queue.get()]
            while not self._log_queue.empty():
                messages.append(self._log_queue.get())
            self._log_to_server('\n'.join(messages), is_new_entry=is_new_entry)
            is_new_entry = False
            if self.QUIT_LOG in messages:
                return

    def _post_log_to_server(self, log):
        self._log_queue.put(log)

    def _log_line(self, handle):
        out = handle.readline().rstrip('\n')
        if out:
            if self._verbose:
                print out
            self._post_log_to_server(out)
        return out

    def _run_logged_command(self, command):
        process = self._tool.executive.popen(command, stdout=self._tool.executive.PIPE, stderr=self._tool.executive.STDOUT)

        out = self._log_line(process.stdout)
        while out:
            # FIXME: This should probably batch up lines if they're available and log to the server once.
            out = self._log_line(process.stdout)

    def _do_one_rebaseline(self):
        self._log_queue = Queue.Queue(256)
        log_thread = threading.Thread(name='LogToServer', target=self._log_to_server_thread)
        log_thread.start()
        try:
            old_branch_name = self._tool.scm().current_branch()
            self._run_logged_command(['git', 'pull'])
            rebaseline_command = [self._tool.filesystem.join(self._tool.scm().checkout_root, 'Tools', 'Scripts', 'webkit-patch'), 'auto-rebaseline']
            if self._verbose:
                rebaseline_command.append('--verbose')
            self._run_logged_command(rebaseline_command)
        except:
            self._log_queue.put(self.QUIT_LOG)
            traceback.print_exc(file=sys.stderr)
            # Sometimes git crashes and leaves us on a detached head.
            self._tool.scm().checkout_branch(old_branch_name)
        else:
            self._log_queue.put(self.QUIT_LOG)
        log_thread.join()

    def execute(self, options, args, tool):
        self._verbose = options.verbose
        while True:
            self._do_one_rebaseline()
            time.sleep(self.SLEEP_TIME_IN_SECONDS)
