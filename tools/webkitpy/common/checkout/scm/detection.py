# Copyright (c) 2009, 2010, 2011 Google Inc. All rights reserved.
# Copyright (c) 2009 Apple Inc. All rights reserved.
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

from webkitpy.common.system.filesystem import FileSystem
from webkitpy.common.system.executive import Executive

from .svn import SVN
from .git import Git

_log = logging.getLogger(__name__)


class SCMDetector(object):
    def __init__(self, filesystem, executive):
        self._filesystem = filesystem
        self._executive = executive

    def default_scm(self, patch_directories=None):
        """Return the default SCM object as determined by the CWD and running code.

        Returns the default SCM object for the current working directory; if the
        CWD is not in a checkout, then we attempt to figure out if the SCM module
        itself is part of a checkout, and return that one. If neither is part of
        a checkout, None is returned.
        """
        cwd = self._filesystem.getcwd()
        scm_system = self.detect_scm_system(cwd, patch_directories)
        if not scm_system:
            script_directory = self._filesystem.dirname(self._filesystem.path_to_module(self.__module__))
            scm_system = self.detect_scm_system(script_directory, patch_directories)
            if scm_system:
                _log.info("The current directory (%s) is not a WebKit checkout, using %s" % (cwd, scm_system.checkout_root))
            else:
                raise Exception("FATAL: Failed to determine the SCM system for either %s or %s" % (cwd, script_directory))
        return scm_system

    def detect_scm_system(self, path, patch_directories=None):
        absolute_path = self._filesystem.abspath(path)

        if patch_directories == []:
            patch_directories = None

        if SVN.in_working_directory(absolute_path, executive=self._executive):
            return SVN(cwd=absolute_path, patch_directories=patch_directories, filesystem=self._filesystem, executive=self._executive)

        if Git.in_working_directory(absolute_path, executive=self._executive):
            return Git(cwd=absolute_path, filesystem=self._filesystem, executive=self._executive)

        return None


# FIXME: These free functions are all deprecated:

def detect_scm_system(path, patch_directories=None):
    return SCMDetector(FileSystem(), Executive()).detect_scm_system(path, patch_directories)
