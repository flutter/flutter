# Copyright (c) 2010 Google Inc. All rights reserved.
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
import os
import sys

from webkitpy.common.checkout.scm.detection import SCMDetector
from webkitpy.common.memoized import memoized
from webkitpy.common.net import buildbot, web
from webkitpy.common.net.buildbot.chromiumbuildbot import ChromiumBuildBot
from webkitpy.common.system.systemhost import SystemHost
from webkitpy.layout_tests.port.factory import PortFactory


_log = logging.getLogger(__name__)


class Host(SystemHost):
    def __init__(self):
        SystemHost.__init__(self)
        self.web = web.Web()

        self._scm = None

        # Everything below this line is WebKit-specific and belongs on a higher-level object.
        self.buildbot = buildbot.BuildBot()

        # FIXME: Unfortunately Port objects are currently the central-dispatch objects of the NRWT world.
        # In order to instantiate a port correctly, we have to pass it at least an executive, user, scm, and filesystem
        # so for now we just pass along the whole Host object.
        # FIXME: PortFactory doesn't belong on this Host object if Port is going to have a Host (circular dependency).
        self.port_factory = PortFactory(self)

        self._engage_awesome_locale_hacks()

    # We call this from the Host constructor, as it's one of the
    # earliest calls made for all webkitpy-based programs.
    def _engage_awesome_locale_hacks(self):
        # To make life easier on our non-english users, we override
        # the locale environment variables inside webkitpy.
        # If we don't do this, programs like SVN will output localized
        # messages and svn.py will fail to parse them.
        # FIXME: We should do these overrides *only* for the subprocesses we know need them!
        # This hack only works in unix environments.
        os.environ['LANGUAGE'] = 'en'
        os.environ['LANG'] = 'en_US.UTF-8'
        os.environ['LC_MESSAGES'] = 'en_US.UTF-8'
        os.environ['LC_ALL'] = ''

    # FIXME: This is a horrible, horrible hack for WinPort and should be removed.
    # Maybe this belongs in SVN in some more generic "find the svn binary" codepath?
    # Or possibly Executive should have a way to emulate shell path-lookups?
    # FIXME: Unclear how to test this, since it currently mutates global state on SVN.
    def _engage_awesome_windows_hacks(self):
        try:
            self.executive.run_command(['svn', 'help'])
        except OSError, e:
            try:
                self.executive.run_command(['svn.bat', 'help'])
                # The Win port uses the depot_tools package, which contains a number
                # of development tools, including Python and svn. Instead of using a
                # real svn executable, depot_tools indirects via a batch file, called
                # svn.bat. This batch file allows depot_tools to auto-update the real
                # svn executable, which is contained in a subdirectory.
                #
                # That's all fine and good, except that subprocess.popen can detect
                # the difference between a real svn executable and batch file when we
                # don't provide use shell=True. Rather than use shell=True on Windows,
                # We hack the svn.bat name into the SVN class.
                _log.debug('Engaging svn.bat Windows hack.')
                from webkitpy.common.checkout.scm.svn import SVN
                SVN.executable_name = 'svn.bat'
            except OSError, e:
                _log.debug('Failed to engage svn.bat Windows hack.')
        try:
            self.executive.run_command(['git', 'help'])
        except OSError, e:
            try:
                self.executive.run_command(['git.bat', 'help'])
                # The Win port uses the depot_tools package, which contains a number
                # of development tools, including Python and git. Instead of using a
                # real git executable, depot_tools indirects via a batch file, called
                # git.bat. This batch file allows depot_tools to auto-update the real
                # git executable, which is contained in a subdirectory.
                #
                # That's all fine and good, except that subprocess.popen can detect
                # the difference between a real git executable and batch file when we
                # don't provide use shell=True. Rather than use shell=True on Windows,
                # We hack the git.bat name into the SVN class.
                _log.debug('Engaging git.bat Windows hack.')
                from webkitpy.common.checkout.scm.git import Git
                Git.executable_name = 'git.bat'
            except OSError, e:
                _log.debug('Failed to engage git.bat Windows hack.')

    def initialize_scm(self, patch_directories=None):
        if sys.platform == "win32":
            self._engage_awesome_windows_hacks()
        detector = SCMDetector(self.filesystem, self.executive)
        self._scm = detector.default_scm(patch_directories)

    def scm(self):
        return self._scm

    def scm_for_path(self, path):
        # FIXME: make scm() be a wrapper around this, and clean up the way
        # callers call initialize_scm() (to remove patch_directories) and scm().
        if sys.platform == "win32":
            self._engage_awesome_windows_hacks()
        return SCMDetector(self.filesystem, self.executive).detect_scm_system(path)

    def buildbot_for_builder_name(self, name):
        if self.port_factory.get_from_builder_name(name).is_chromium():
            return self.chromium_buildbot()
        return self.buildbot

    @memoized
    def chromium_buildbot(self):
        return ChromiumBuildBot()
