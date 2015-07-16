# Copyright (C) 2011 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#    * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#    * Neither the name of Google Inc. nor the names of its
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

from webkitpy.common.checkout.scm.scm_mock import MockSCM
from webkitpy.common.net.buildbot.buildbot_mock import MockBuildBot
from webkitpy.common.net.web_mock import MockWeb
from webkitpy.common.system.systemhost_mock import MockSystemHost

# New-style ports need to move down into webkitpy.common.
from webkitpy.layout_tests.port.factory import PortFactory
from webkitpy.layout_tests.port.test import add_unit_tests_to_mock_filesystem


class MockHost(MockSystemHost):
    def __init__(self, log_executive=False, executive_throws_when_run=None, initialize_scm_by_default=True, web=None, scm=None):
        MockSystemHost.__init__(self, log_executive, executive_throws_when_run)
        add_unit_tests_to_mock_filesystem(self.filesystem)
        self.web = web or MockWeb()

        self._scm = scm
        # FIXME: we should never initialize the SCM by default, since the real
        # object doesn't either. This has caused at least one bug (see bug 89498).
        if initialize_scm_by_default:
            self.initialize_scm()
        self.buildbot = MockBuildBot()
        self._chromium_buildbot = MockBuildBot()

        # Note: We're using a real PortFactory here.  Tests which don't wish to depend
        # on the list of known ports should override this with a MockPortFactory.
        self.port_factory = PortFactory(self)

    def initialize_scm(self, patch_directories=None):
        if not self._scm:
            self._scm = MockSCM(filesystem=self.filesystem, executive=self.executive)
        # Various pieces of code (wrongly) call filesystem.chdir(checkout_root).
        # Making the checkout_root exist in the mock filesystem makes that chdir not raise.
        self.filesystem.maybe_make_directory(self._scm.checkout_root)

    def scm(self):
        return self._scm

    def scm_for_path(self, path):
        # FIXME: consider supporting more than one SCM so that we can do more comprehensive testing.
        self.initialize_scm()
        return self._scm

    def checkout(self):
        return self._checkout

    def chromium_buildbot(self):
        return self._chromium_buildbot
