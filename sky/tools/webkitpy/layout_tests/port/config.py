# Copyright (C) 2010 Google Inc. All rights reserved.
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

# FIXME: Remove this file altogether. It's useless in a Blink checkout.

import logging

from webkitpy.common import webkit_finder


_log = logging.getLogger(__name__)


class Config(object):
    _FLAGS_FROM_CONFIGURATIONS = {
        "Debug": "--debug",
        "Release": "--release",
    }

    def __init__(self, executive, filesystem, port_implementation=None):
        self._executive = executive
        self._filesystem = filesystem
        self._webkit_finder = webkit_finder.WebKitFinder(self._filesystem)
        self._default_configuration = None
        self._build_directories = {}
        self._port_implementation = port_implementation

    def build_directory(self, configuration):
        """Returns the path to the build directory for the configuration."""
        if configuration:
            flags = ["--configuration", self.flag_for_configuration(configuration)]
        else:
            configuration = ""
            flags = []

        if self._port_implementation:
            flags.append('--' + self._port_implementation)

        if not self._build_directories.get(configuration):
            self._build_directories[configuration] = self._webkit_finder.path_from_webkit_base('out', configuration)

        return self._build_directories[configuration]

    def flag_for_configuration(self, configuration):
        return self._FLAGS_FROM_CONFIGURATIONS[configuration]

    def default_configuration(self):
        return 'Release'
