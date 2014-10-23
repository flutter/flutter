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

import threading

from webkitpy.common.host_mock import MockHost
from webkitpy.common.net.buildbot.buildbot_mock import MockBuildBot

# FIXME: Old-style "Ports" need to die and be replaced by modern layout_tests.port which needs to move to common.
from webkitpy.common.config.ports_mock import MockPort


# FIXME: We should just replace this with optparse.Values(default=kwargs)
class MockOptions(object):
    """Mock implementation of optparse.Values."""

    def __init__(self, **kwargs):
        # The caller can set option values using keyword arguments. We don't
        # set any values by default because we don't know how this
        # object will be used. Generally speaking unit tests should
        # subclass this or provider wrapper functions that set a common
        # set of options.
        self.update(**kwargs)

    def update(self, **kwargs):
        self.__dict__.update(**kwargs)
        return self

    def ensure_value(self, key, value):
        if getattr(self, key, None) == None:
            self.__dict__[key] = value
        return self.__dict__[key]


# FIXME: This should be renamed MockWebKitPatch.
class MockTool(MockHost):
    def __init__(self, *args, **kwargs):
        MockHost.__init__(self, *args, **kwargs)

        self._deprecated_port = MockPort()

        self.wakeup_event = threading.Event()

    def deprecated_port(self):
        return self._deprecated_port

    def path(self):
        return "echo"

    def buildbot_for_builder_name(self, name):
        return MockBuildBot()
