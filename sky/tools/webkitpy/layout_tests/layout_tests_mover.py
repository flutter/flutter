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

"""Moves a directory of tests.

Given a path to a directory of tests, moves that directory, including all recursive children,
to the specified destination path. Updates all references in tests and resources to reflect the new
location. Also moves any corresponding platform-specific expected results and updates the test
expectations to reflect the move.

If the destination directory does not exist, it and any missing parent directories are created. If
the destination directory already exists, the child members of the origin directory are added to the
destination directory. If any of the child members clash with existing members of the destination
directory, the move fails.

Note that when new entries are added to the test expectations, no attempt is made to group or merge
them with existing entries. This should be be done manually and with lint-test-expectations.
"""

import copy
import logging
import optparse
import os
import re
import urlparse

from webkitpy.common.checkout.scm.detection import SCMDetector
from webkitpy.common.host import Host
from webkitpy.common.system.executive import Executive
from webkitpy.common.system.filesystem import FileSystem
from webkitpy.layout_tests.port.base import Port
from webkitpy.layout_tests.models.test_expectations import TestExpectations


logging.basicConfig()
_log = logging.getLogger(__name__)
_log.setLevel(logging.INFO)

PLATFORM_DIRECTORY = 'platform'

class testsMover(object):

    def __init__(self, port=None):
        self._port = port
        if not self._port:
            host = Host()
            # Given that we use include_overrides=False and model_all_expectations=True when
            # constructing the TestExpectations object, it doesn't matter which Port object we use.
            self._port = host.port_factory.get()
            self._port.host.initialize_scm()
        self._filesystem = self._port.host.filesystem
        self._scm = self._port.host.scm()
        self._layout_tests_root = self._port.layout_tests_dir()

    def _scm_path(self, *paths):
        return self._filesystem.join('tests', *paths)

    def _is_child_path(self, parent, possible_child):
        normalized_parent = self._filesystem.normpath(parent)
        normalized_child = self._filesystem.normpath(possible_child)
        # We need to add a trailing separator to parent to avoid returning true for cases like
        # parent='/foo/b', and possible_child='/foo/bar/baz'.
        return normalized_parent == normalized_child or normalized_child.startswith(normalized_parent + self._filesystem.sep)

    def _move_path(self, path, origin, destination):
        if not self._is_child_path(origin, path):
            return path
        return self._filesystem.normpath(self._filesystem.join(destination, self._filesystem.relpath(path, origin)))

    def _validate_input(self):
        if not self._filesystem.isdir(self._absolute_origin):
            raise Exception('Source path %s is not a directory' % self._origin)
        if not self._is_child_path(self._layout_tests_root, self._absolute_origin):
            raise Exception('Source path %s is not in tests directory' % self._origin)
        if self._filesystem.isfile(self._absolute_destination):
            raise Exception('Destination path %s is a file' % self._destination)
        if not self._is_child_path(self._layout_tests_root, self._absolute_destination):
            raise Exception('Destination path %s is not in tests directory' % self._destination)

        # If destination is an existing directory, we move the children of origin into destination.
        # However, if any of the children of origin would clash with existing children of
        # destination, we fail.
        # FIXME: Consider adding support for recursively moving into an existing directory.
        if self._filesystem.isdir(self._absolute_destination):
            for file_path in self._filesystem.listdir(self._absolute_origin):
                if self._filesystem.exists(self._filesystem.join(self._absolute_destination, file_path)):
                    raise Exception('Origin path %s clashes with existing destination path %s' %
                            (self._filesystem.join(self._origin, file_path), self._filesystem.join(self._destination, file_path)))

    def _get_expectations_for_test(self, model, test_path):
        """Given a TestExpectationsModel object, finds all expectations that match the specified
        test, specified as a relative path. Handles the fact that expectations may be keyed by
        directory.
        """
        expectations = set()
        if model.has_test(test_path):
            expectations.add(model.get_expectation_line(test_path))
        test_path = self._filesystem.dirname(test_path)
        while not test_path == '':
            # The model requires a trailing slash for directories.
            test_path_for_model = test_path + '/'
            if model.has_test(test_path_for_model):
                expectations.add(model.get_expectation_line(test_path_for_model))
            test_path = self._filesystem.dirname(test_path)
        return expectations

    def _get_expectations(self, model, path):
        """Given a TestExpectationsModel object, finds all expectations for all tests under the
        specified relative path.
        """
        expectations = set()
        for test in self._filesystem.files_under(self._filesystem.join(self._layout_tests_root, path), dirs_to_skip=['script-tests', 'resources'],
                                                 file_filter=Port.is_test_file):
            expectations = expectations.union(self._get_expectations_for_test(model, self._filesystem.relpath(test, self._layout_tests_root)))
        return expectations

    @staticmethod
    def _clone_expectation_line_for_path(expectation_line, path):
        """Clones a TestExpectationLine object and updates the clone to apply to the specified
        relative path.
        """
        clone = copy.copy(expectation_line)
        clone.original_string = re.compile(expectation_line.name).sub(path, expectation_line.original_string)
        clone.name = path
        clone.path = path
        # FIXME: Should we search existing expectations for matches, like in
        # TestExpectationsParser._collect_matching_tests()?
        clone.matching_tests = [path]
        return clone

    def _update_expectations(self):
        """Updates all test expectations that are affected by the move.
        """
        _log.info('Updating expectations')
        test_expectations = TestExpectations(self._port, include_overrides=False, model_all_expectations=True)

        for expectation in self._get_expectations(test_expectations.model(), self._origin):
            path = expectation.path
            if self._is_child_path(self._origin, path):
                # If the existing expectation is a child of the moved path, we simply replace it
                # with an expectation for the updated path.
                new_path = self._move_path(path, self._origin, self._destination)
                _log.debug('Updating expectation for %s to %s' % (path, new_path))
                test_expectations.remove_expectation_line(path)
                test_expectations.add_expectation_line(testsMover._clone_expectation_line_for_path(expectation, new_path))
            else:
                # If the existing expectation is not a child of the moved path, we have to leave it
                # in place. But we also add a new expectation for the destination path.
                new_path = self._destination
                _log.warning('Copying expectation for %s to %s. You should check that these expectations are still correct.' %
                             (path, new_path))
                test_expectations.add_expectation_line(testsMover._clone_expectation_line_for_path(expectation, new_path))

        expectations_file = self._port.path_to_generic_test_expectations_file()
        self._filesystem.write_text_file(expectations_file,
                                         TestExpectations.list_to_string(test_expectations._expectations, reconstitute_only_these=[]))
        self._scm.add(self._filesystem.relpath(expectations_file, self._scm.checkout_root))

    def _find_references(self, input_files):
        """Attempts to find all references to other files in the supplied list of files. Returns a
        dictionary that maps from an absolute file path to an array of reference strings.
        """
        reference_regex = re.compile(r'(?:(?:src=|href=|importScripts\(|url\()(?:"([^"]+)"|\'([^\']+)\')|url\(([^\)\'"]+)\))')
        references = {}
        for input_file in input_files:
            matches = reference_regex.findall(self._filesystem.read_binary_file(input_file))
            if matches:
                references[input_file] = [filter(None, match)[0] for match in matches]
        return references

    def _get_updated_reference(self, root, reference):
        """For a reference <reference> in a directory <root>, determines the updated reference.
        Returns the the updated reference, or None if no update is required.
        """
        # If the reference is an absolute path or url, it's safe.
        if reference.startswith('/') or urlparse.urlparse(reference).scheme:
            return None

        # Both the root path and the target of the reference my be subject to the move, so there are
        # four cases to consider. In the case where both or neither are subject to the move, the
        # reference doesn't need updating.
        #
        # This is true even if the reference includes superfluous dot segments which mention a moved
        # directory, as dot segments are collapsed during URL normalization. For example, if
        # foo.html contains a reference 'bar/../script.js', this remains valid (though ugly) even if
        # bar/ is moved to baz/, because the reference is always normalized to 'script.js'.
        absolute_reference = self._filesystem.normpath(self._filesystem.join(root, reference))
        if self._is_child_path(self._absolute_origin, root) == self._is_child_path(self._absolute_origin, absolute_reference):
            return None;

        new_root = self._move_path(root, self._absolute_origin, self._absolute_destination)
        new_absolute_reference = self._move_path(absolute_reference, self._absolute_origin, self._absolute_destination)
        return self._filesystem.relpath(new_absolute_reference, new_root)

    def _get_all_updated_references(self, references):
        """Determines the updated references due to the move. Returns a dictionary that maps from an
        absolute file path to a dictionary that maps from a reference string to the corresponding
        updated reference.
        """
        updates = {}
        for file_path in references.keys():
            root = self._filesystem.dirname(file_path)
            # sript-tests/TEMPLATE.html files contain references which are written as if the file
            # were in the parent directory. This special-casing is ugly, but there are plans to
            # remove script-tests.
            if root.endswith('script-tests') and file_path.endswith('TEMPLATE.html'):
                root = self._filesystem.dirname(root)
            local_updates = {}
            for reference in references[file_path]:
                update = self._get_updated_reference(root, reference)
                if update:
                    local_updates[reference] = update
            if local_updates:
                updates[file_path] = local_updates
        return updates

    def _update_file(self, path, updates):
        contents = self._filesystem.read_binary_file(path)
        # Note that this regex isn't quite as strict as that used to find the references, but this
        # avoids the need for alternative match groups, which simplifies things.
        for target in updates.keys():
            regex = re.compile(r'((?:src=|href=|importScripts\(|url\()["\']?)%s(["\']?)' % target)
            contents = regex.sub(r'\1%s\2' % updates[target], contents)
        self._filesystem.write_binary_file(path, contents)
        self._scm.add(path)

    def _update_test_source_files(self):
        def is_test_source_file(filesystem, dirname, basename):
            pass_regex = re.compile(r'\.(css|js)$')
            fail_regex = re.compile(r'-expected\.')
            return (Port.is_test_file(filesystem, dirname, basename) or pass_regex.search(basename)) and not fail_regex.search(basename)

        test_source_files = self._filesystem.files_under(self._layout_tests_root, file_filter=is_test_source_file)
        _log.info('Considering %s test source files for references' % len(test_source_files))
        references = self._find_references(test_source_files)
        _log.info('Considering references in %s files' % len(references))
        updates = self._get_all_updated_references(references)
        _log.info('Updating references in %s files' % len(updates))
        count = 0
        for file_path in updates.keys():
            self._update_file(file_path, updates[file_path])
            count += 1
            if count % 1000 == 0 or count == len(updates):
                _log.debug('Updated references in %s files' % count)

    def _move_directory(self, origin, destination):
        """Moves the directory <origin> to <destination>. If <destination> is a directory, moves the
        children of <origin> into <destination>. Uses relative paths.
        """
        absolute_origin = self._filesystem.join(self._layout_tests_root, origin)
        if not self._filesystem.isdir(absolute_origin):
            return
        _log.info('Moving directory %s to %s' % (origin, destination))
        # Note that FileSystem.move() may silently overwrite existing files, but we
        # check for this in _validate_input().
        absolute_destination = self._filesystem.join(self._layout_tests_root, destination)
        self._filesystem.maybe_make_directory(absolute_destination)
        for directory in self._filesystem.listdir(absolute_origin):
            self._scm.move(self._scm_path(origin, directory), self._scm_path(destination, directory))
        self._filesystem.rmtree(absolute_origin)

    def _move_files(self):
        """Moves the all files that correspond to the move, including platform-specific expected
        results.
        """
        self._move_directory(self._origin, self._destination)
        for directory in self._filesystem.listdir(self._filesystem.join(self._layout_tests_root, PLATFORM_DIRECTORY)):
            self._move_directory(self._filesystem.join(PLATFORM_DIRECTORY, directory, self._origin),
                           self._filesystem.join(PLATFORM_DIRECTORY, directory, self._destination))

    def _commit_changes(self):
        if not self._scm.supports_local_commits():
            return
        title = 'Move tests directory %s to %s' % (self._origin, self._destination)
        _log.info('Committing change \'%s\'' % title)
        self._scm.commit_locally_with_message('%s\n\nThis commit was automatically generated by move-layout-tests.' % title,
                                              commit_all_working_directory_changes=False)

    def move(self, origin, destination):
        self._origin = origin
        self._destination = destination
        self._absolute_origin = self._filesystem.join(self._layout_tests_root, self._origin)
        self._absolute_destination = self._filesystem.join(self._layout_tests_root, self._destination)
        self._validate_input()
        self._update_expectations()
        self._update_test_source_files()
        self._move_files()
        # FIXME: Handle virtual test suites.
        self._commit_changes()

def main(argv):
    parser = optparse.OptionParser(description=__doc__)
    parser.add_option('--origin',
                      help=('The directory of tests to move, as a relative path from the tests directory.'))
    parser.add_option('--destination',
                      help=('The new path for the directory of tests, as a relative path from the tests directory.'))
    options, _ = parser.parse_args()
    testsMover().move(options.origin, options.destination)
