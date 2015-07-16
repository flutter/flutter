# Copyright (C) 2012 Google, Inc.
# Copyright (C) 2010 Chris Jerdonek (cjerdonek@webkit.org)
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""this module is responsible for finding python tests."""

import logging
import re


_log = logging.getLogger(__name__)


class _DirectoryTree(object):
    def __init__(self, filesystem, top_directory, starting_subdirectory):
        self.filesystem = filesystem
        self.top_directory = filesystem.realpath(top_directory)
        self.search_directory = self.top_directory
        self.top_package = ''
        if starting_subdirectory:
            self.top_package = starting_subdirectory.replace(filesystem.sep, '.') + '.'
            self.search_directory = filesystem.join(self.top_directory, starting_subdirectory)

    def find_modules(self, suffixes, sub_directory=None):
        if sub_directory:
            search_directory = self.filesystem.join(self.top_directory, sub_directory)
        else:
            search_directory = self.search_directory

        def file_filter(filesystem, dirname, basename):
            return any(basename.endswith(suffix) for suffix in suffixes)

        filenames = self.filesystem.files_under(search_directory, file_filter=file_filter)
        return [self.to_module(filename) for filename in filenames]

    def to_module(self, path):
        return path.replace(self.top_directory + self.filesystem.sep, '').replace(self.filesystem.sep, '.')[:-3]

    def subpath(self, path):
        """Returns the relative path from the top of the tree to the path, or None if the path is not under the top of the tree."""
        realpath = self.filesystem.realpath(self.filesystem.join(self.top_directory, path))
        if realpath.startswith(self.top_directory + self.filesystem.sep):
            return realpath.replace(self.top_directory + self.filesystem.sep, '')
        return None

    def clean(self):
        """Delete all .pyc files in the tree that have no matching .py file."""
        _log.debug("Cleaning orphaned *.pyc files from: %s" % self.search_directory)
        filenames = self.filesystem.files_under(self.search_directory)
        for filename in filenames:
            if filename.endswith(".pyc") and filename[:-1] not in filenames:
                _log.info("Deleting orphan *.pyc file: %s" % filename)
                self.filesystem.remove(filename)


class Finder(object):
    def __init__(self, filesystem):
        self.filesystem = filesystem
        self.trees = []
        self._names_to_skip = []

    def add_tree(self, top_directory, starting_subdirectory=None):
        self.trees.append(_DirectoryTree(self.filesystem, top_directory, starting_subdirectory))

    def skip(self, names, reason, bugid):
        self._names_to_skip.append(tuple([names, reason, bugid]))

    def additional_paths(self, paths):
        return [tree.top_directory for tree in self.trees if tree.top_directory not in paths]

    def clean_trees(self):
        for tree in self.trees:
            tree.clean()

    def is_module(self, name):
        relpath = name.replace('.', self.filesystem.sep) + '.py'
        return any(self.filesystem.exists(self.filesystem.join(tree.top_directory, relpath)) for tree in self.trees)

    def is_dotted_name(self, name):
        return re.match(r'[a-zA-Z.][a-zA-Z0-9_.]*', name)

    def to_module(self, path):
        for tree in self.trees:
            if path.startswith(tree.top_directory):
                return tree.to_module(path)
        return None

    def find_names(self, args, find_all):
        suffixes = ['_unittest.py', '_integrationtest.py']
        if args:
            names = []
            for arg in args:
                names.extend(self._find_names_for_arg(arg, suffixes))
            return names

        return self._default_names(suffixes, find_all)

    def _find_names_for_arg(self, arg, suffixes):
        realpath = self.filesystem.realpath(arg)
        if self.filesystem.exists(realpath):
            names = self._find_in_trees(realpath, suffixes)
            if not names:
                _log.error("%s is not in one of the test trees." % arg)
            return names

        # See if it's a python package in a tree (or a relative path from the top of a tree).
        names = self._find_in_trees(arg.replace('.', self.filesystem.sep), suffixes)
        if names:
            return names

        if self.is_dotted_name(arg):
            # The name may not exist, but that's okay; we'll find out later.
            return [arg]

        _log.error("%s is not a python name or an existing file or directory." % arg)
        return []

    def _find_in_trees(self, path, suffixes):
        for tree in self.trees:
            relpath = tree.subpath(path)
            if not relpath:
                continue
            if self.filesystem.isfile(path):
                return [tree.to_module(path)]
            else:
                return tree.find_modules(suffixes, path)
        return []

    def _default_names(self, suffixes, find_all):
        modules = []
        for tree in self.trees:
            modules.extend(tree.find_modules(suffixes))
        modules.sort()

        for module in modules:
            _log.debug("Found: %s" % module)

        if not find_all:
            for (names, reason, bugid) in self._names_to_skip:
                self._exclude(modules, names, reason, bugid)

        return modules

    def _exclude(self, modules, module_prefixes, reason, bugid):
        _log.info('Skipping tests in the following modules or packages because they %s:' % reason)
        for prefix in module_prefixes:
            _log.info('    %s' % prefix)
            modules_to_exclude = filter(lambda m: m.startswith(prefix), modules)
            for m in modules_to_exclude:
                if len(modules_to_exclude) > 1:
                    _log.debug('        %s' % m)
                modules.remove(m)
        _log.info('    (https://bugs.webkit.org/show_bug.cgi?id=%d; use --all to include)' % bugid)
        _log.info('')
