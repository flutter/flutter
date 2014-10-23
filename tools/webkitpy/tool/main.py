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
#
# A tool for automating dealing with bugzilla, posting patches, committing patches, etc.

from optparse import make_option
import os
import threading

from webkitpy.common.host import Host
from webkitpy.tool.multicommandtool import MultiCommandTool
from webkitpy.tool import commands


class WebKitPatch(MultiCommandTool, Host):
    global_options = [
        make_option("-v", "--verbose", action="store_true", dest="verbose", default=False, help="enable all logging"),
        make_option("-d", "--directory", action="append", dest="patch_directories", default=[], help="Directory to look at for changed files"),
    ]

    def __init__(self, path):
        MultiCommandTool.__init__(self)
        Host.__init__(self)
        self._path = path
        self.wakeup_event = threading.Event()

    def path(self):
        return self._path

    def should_show_in_main_help(self, command):
        if not command.show_in_main_help:
            return False
        if command.requires_local_commits:
            return self.scm().supports_local_commits()
        return True

    # FIXME: This may be unnecessary since we pass global options to all commands during execute() as well.
    def handle_global_options(self, options):
        self.initialize_scm(options.patch_directories)

    def should_execute_command(self, command):
        if command.requires_local_commits and not self.scm().supports_local_commits():
            failure_reason = "%s requires local commits using %s in %s." % (command.name, self.scm().display_name(), self.scm().checkout_root)
            return (False, failure_reason)
        return (True, None)
