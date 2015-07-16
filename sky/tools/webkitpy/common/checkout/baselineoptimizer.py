# Copyright (C) 2011, Google Inc. All rights reserved.
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

import copy
import logging

from webkitpy.common.memoized import memoized

_log = logging.getLogger(__name__)


# FIXME: Should this function be somewhere more general?
def _invert_dictionary(dictionary):
    inverted_dictionary = {}
    for key, value in dictionary.items():
        if inverted_dictionary.get(value):
            inverted_dictionary[value].append(key)
        else:
            inverted_dictionary[value] = [key]
    return inverted_dictionary


class BaselineOptimizer(object):
    ROOT_LAYOUT_TESTS_DIRECTORY = 'tests'

    def __init__(self, host, port_names, skip_scm_commands):
        self._filesystem = host.filesystem
        self._port_factory = host.port_factory
        self._skip_scm_commands = skip_scm_commands
        self._files_to_delete = []
        self._files_to_add = []
        self._scm = host.scm()
        self._port_names = port_names
        # Only used by unittests.
        self.new_results_by_directory = []

    def _baseline_root(self, port, baseline_name):
        virtual_suite = port.lookup_virtual_suite(baseline_name)
        if virtual_suite:
            return self._filesystem.join(self.ROOT_LAYOUT_TESTS_DIRECTORY, virtual_suite.name)
        return self.ROOT_LAYOUT_TESTS_DIRECTORY

    def _baseline_search_path(self, port, baseline_name):
        virtual_suite = port.lookup_virtual_suite(baseline_name)
        if virtual_suite:
            return port.virtual_baseline_search_path(baseline_name)
        return port.baseline_search_path()

    @memoized
    def _relative_baseline_search_paths(self, port_name, baseline_name):
        port = self._port_factory.get(port_name)
        relative_paths = [self._filesystem.relpath(path, port.webkit_base()) for path in self._baseline_search_path(port, baseline_name)]
        return relative_paths + [self._baseline_root(port, baseline_name)]

    def _join_directory(self, directory, baseline_name):
        # This code is complicated because both the directory name and the baseline_name have the virtual
        # test suite in the name and the virtual baseline name is not a strict superset of the non-virtual name.
        # For example, virtual/gpu/fast/canvas/foo-expected.png corresponds to fast/canvas/foo-expected.png and
        # the baseline directories are like platform/mac/virtual/gpu/fast/canvas. So, to get the path
        # to the baseline in the platform directory, we need to append jsut foo-expected.png to the directory.
        virtual_suite = self._port_factory.get().lookup_virtual_suite(baseline_name)
        if virtual_suite:
            baseline_name_without_virtual = baseline_name[len(virtual_suite.name) + 1:]
        else:
            baseline_name_without_virtual = baseline_name
        return self._filesystem.join(self._scm.checkout_root, directory, baseline_name_without_virtual)

    def read_results_by_directory(self, baseline_name):
        results_by_directory = {}
        directories = reduce(set.union, map(set, [self._relative_baseline_search_paths(port_name, baseline_name) for port_name in self._port_names]))

        for directory in directories:
            path = self._join_directory(directory, baseline_name)
            if self._filesystem.exists(path):
                results_by_directory[directory] = self._filesystem.sha1(path)
        return results_by_directory

    def _results_by_port_name(self, results_by_directory, baseline_name):
        results_by_port_name = {}
        for port_name in self._port_names:
            for directory in self._relative_baseline_search_paths(port_name, baseline_name):
                if directory in results_by_directory:
                    results_by_port_name[port_name] = results_by_directory[directory]
                    break
        return results_by_port_name

    @memoized
    def _directories_immediately_preceding_root(self, baseline_name):
        directories = set()
        for port_name in self._port_names:
            port = self._port_factory.get(port_name)
            directory = self._filesystem.relpath(self._baseline_search_path(port, baseline_name)[-1], port.webkit_base())
            directories.add(directory)
        return directories

    def _optimize_result_for_root(self, new_results_by_directory, baseline_name):
        # The root directory (i.e. tests) is the only one that doesn't correspond
        # to a specific platform. As such, it's the only one where the baseline in fallback directories
        # immediately before it can be promoted up, i.e. if win and mac
        # have the same baseline, then it can be promoted up to be the tests baseline.
        # All other baselines can only be removed if they're redundant with a baseline earlier
        # in the fallback order. They can never promoted up.
        directories_immediately_preceding_root = self._directories_immediately_preceding_root(baseline_name)

        shared_result = None
        root_baseline_unused = False
        for directory in directories_immediately_preceding_root:
            this_result = new_results_by_directory.get(directory)

            # If any of these directories don't have a baseline, there's no optimization we can do.
            if not this_result:
                return

            if not shared_result:
                shared_result = this_result
            elif shared_result != this_result:
                root_baseline_unused = True

        baseline_root = self._baseline_root(self._port_factory.get(), baseline_name)

        # The root baseline is unused if all the directories immediately preceding the root
        # have a baseline, but have different baselines, so the baselines can't be promoted up.
        if root_baseline_unused:
            if baseline_root in new_results_by_directory:
                del new_results_by_directory[baseline_root]
            return

        new_results_by_directory[baseline_root] = shared_result
        for directory in directories_immediately_preceding_root:
            del new_results_by_directory[directory]

    def _find_optimal_result_placement(self, baseline_name):
        results_by_directory = self.read_results_by_directory(baseline_name)
        results_by_port_name = self._results_by_port_name(results_by_directory, baseline_name)
        port_names_by_result = _invert_dictionary(results_by_port_name)

        new_results_by_directory = self._remove_redundant_results(results_by_directory, results_by_port_name, port_names_by_result, baseline_name)
        self._optimize_result_for_root(new_results_by_directory, baseline_name)

        return results_by_directory, new_results_by_directory

    def _remove_redundant_results(self, results_by_directory, results_by_port_name, port_names_by_result, baseline_name):
        new_results_by_directory = copy.copy(results_by_directory)
        for port_name in self._port_names:
            current_result = results_by_port_name.get(port_name)

            # This happens if we're missing baselines for a port.
            if not current_result:
                continue;

            fallback_path = self._relative_baseline_search_paths(port_name, baseline_name)
            current_index, current_directory = self._find_in_fallbackpath(fallback_path, current_result, new_results_by_directory)
            for index in range(current_index + 1, len(fallback_path)):
                new_directory = fallback_path[index]
                if not new_directory in new_results_by_directory:
                    # No result for this baseline in this directory.
                    continue
                elif new_results_by_directory[new_directory] == current_result:
                    # Result for new_directory are redundant with the result earlier in the fallback order.
                    if current_directory in new_results_by_directory:
                        del new_results_by_directory[current_directory]
                else:
                    # The new_directory contains a different result, so stop trying to push results up.
                    break

        return new_results_by_directory

    def _find_in_fallbackpath(self, fallback_path, current_result, results_by_directory):
        for index, directory in enumerate(fallback_path):
            if directory in results_by_directory and (results_by_directory[directory] == current_result):
                return index, directory
        assert False, "result %s not found in fallback_path %s, %s" % (current_result, fallback_path, results_by_directory)

    def _platform(self, filename):
        platform_dir = self.ROOT_LAYOUT_TESTS_DIRECTORY + self._filesystem.sep + 'platform' + self._filesystem.sep
        if filename.startswith(platform_dir):
            return filename.replace(platform_dir, '').split(self._filesystem.sep)[0]
        platform_dir = self._filesystem.join(self._scm.checkout_root, platform_dir)
        if filename.startswith(platform_dir):
            return filename.replace(platform_dir, '').split(self._filesystem.sep)[0]
        return '(generic)'

    def _move_baselines(self, baseline_name, results_by_directory, new_results_by_directory):
        data_for_result = {}
        for directory, result in results_by_directory.items():
            if not result in data_for_result:
                source = self._join_directory(directory, baseline_name)
                data_for_result[result] = self._filesystem.read_binary_file(source)

        scm_files = []
        fs_files = []
        for directory, result in results_by_directory.items():
            if new_results_by_directory.get(directory) != result:
                file_name = self._join_directory(directory, baseline_name)
                if self._scm.exists(file_name):
                    scm_files.append(file_name)
                else:
                    fs_files.append(file_name)

        if scm_files or fs_files:
            if scm_files:
                _log.debug("    Deleting (SCM):")
                for platform_dir in sorted(self._platform(filename) for filename in scm_files):
                    _log.debug("      " + platform_dir)
                if self._skip_scm_commands:
                    self._files_to_delete.extend(scm_files)
                else:
                    self._scm.delete_list(scm_files)
            if fs_files:
                _log.debug("    Deleting (file system):")
                for platform_dir in sorted(self._platform(filename) for filename in fs_files):
                    _log.debug("      " + platform_dir)
                for filename in fs_files:
                    self._filesystem.remove(filename)
        else:
            _log.debug("    (Nothing to delete)")

        file_names = []
        for directory, result in new_results_by_directory.items():
            if results_by_directory.get(directory) != result:
                destination = self._join_directory(directory, baseline_name)
                self._filesystem.maybe_make_directory(self._filesystem.split(destination)[0])
                self._filesystem.write_binary_file(destination, data_for_result[result])
                file_names.append(destination)

        if file_names:
            _log.debug("    Adding:")
            for platform_dir in sorted(self._platform(filename) for filename in file_names):
                _log.debug("      " + platform_dir)
            if self._skip_scm_commands:
                # Have adds win over deletes.
                self._files_to_delete = list(set(self._files_to_delete) - set(file_names))
                self._files_to_add.extend(file_names)
            else:
                self._scm.add_list(file_names)
        else:
            _log.debug("    (Nothing to add)")

    def write_by_directory(self, results_by_directory, writer, indent):
        for path in sorted(results_by_directory):
            writer("%s%s: %s" % (indent, self._platform(path), results_by_directory[path][0:6]))

    def _optimize_subtree(self, baseline_name):
        basename = self._filesystem.basename(baseline_name)
        results_by_directory, new_results_by_directory = self._find_optimal_result_placement(baseline_name)

        if new_results_by_directory == results_by_directory:
            if new_results_by_directory:
                _log.debug("  %s: (already optimal)" % basename)
                self.write_by_directory(results_by_directory, _log.debug, "    ")
            else:
                _log.debug("  %s: (no baselines found)" % basename)
            # This is just used for unittests. Intentionally set it to the old data if we don't modify anything.
            self.new_results_by_directory.append(results_by_directory)
            return True

        if self._results_by_port_name(results_by_directory, baseline_name) != self._results_by_port_name(new_results_by_directory, baseline_name):
            # This really should never happen. Just a sanity check to make sure the script fails in the case of bugs
            # instead of committing incorrect baselines.
            _log.error("  %s: optimization failed" % basename)
            self.write_by_directory(results_by_directory, _log.warning, "      ")
            return False

        _log.debug("  %s:" % basename)
        _log.debug("    Before: ")
        self.write_by_directory(results_by_directory, _log.debug, "      ")
        _log.debug("    After: ")
        self.write_by_directory(new_results_by_directory, _log.debug, "      ")

        self._move_baselines(baseline_name, results_by_directory, new_results_by_directory)
        return True

    def _optimize_virtual_root(self, baseline_name, non_virtual_baseline_name):
        default_port = self._port_factory.get()
        virtual_root_expected_baseline_path = self._filesystem.join(default_port.layout_tests_dir(), baseline_name)
        if not self._filesystem.exists(virtual_root_expected_baseline_path):
            return
        root_sha1 = self._filesystem.sha1(virtual_root_expected_baseline_path)

        results_by_directory = self.read_results_by_directory(non_virtual_baseline_name)
        # See if all the immediate predecessors of the virtual root have the same expected result.
        for port_name in self._port_names:
            directories = self._relative_baseline_search_paths(port_name, non_virtual_baseline_name)
            for directory in directories:
                if directory not in results_by_directory:
                    continue
                if results_by_directory[directory] != root_sha1:
                    return
                break

        _log.debug("Deleting redundant virtual root expected result.")
        if self._skip_scm_commands and virtual_root_expected_baseline_path in self._files_to_add:
            self._files_to_add.remove(virtual_root_expected_baseline_path)
        if self._scm.exists(virtual_root_expected_baseline_path):
            _log.debug("    Deleting (SCM): " + virtual_root_expected_baseline_path)
            if self._skip_scm_commands:
                self._files_to_delete.append(virtual_root_expected_baseline_path)
            else:
                self._scm.delete(virtual_root_expected_baseline_path)
        else:
            _log.debug("    Deleting (file system): " + virtual_root_expected_baseline_path)
            self._filesystem.remove(virtual_root_expected_baseline_path)

    def optimize(self, baseline_name):
        # The virtual fallback path is the same as the non-virtual one tacked on to the bottom of the non-virtual path.
        # See https://docs.google.com/a/chromium.org/drawings/d/1eGdsIKzJ2dxDDBbUaIABrN4aMLD1bqJTfyxNGZsTdmg/edit for
        # a visual representation of this.
        #
        # So, we can optimize the virtual path, then the virtual root and then the regular path.

        self._files_to_delete = []
        self._files_to_add = []
        _log.debug("Optimizing regular fallback path.")
        result = self._optimize_subtree(baseline_name)
        non_virtual_baseline_name = self._port_factory.get().lookup_virtual_test_base(baseline_name)
        if not non_virtual_baseline_name:
            return result, self._files_to_delete, self._files_to_add

        self._optimize_virtual_root(baseline_name, non_virtual_baseline_name)

        _log.debug("Optimizing non-virtual fallback path.")
        result |= self._optimize_subtree(non_virtual_baseline_name)
        return result, self._files_to_delete, self._files_to_add
