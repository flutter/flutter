# Copyright (C) 2012 Google Inc. All rights reserved.
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


class MockServerProcess(object):
    def __init__(self, port_obj=None, name=None, cmd=None, env=None, universal_newlines=False, treat_no_data_as_crash=False, logging=False, lines=None, crashed=False):
        self.timed_out = False
        self.lines = lines or ['#READY']
        self.crashed = crashed
        self.writes = []
        self.cmd = cmd
        self.env = env
        self.treat_no_data_as_crash = treat_no_data_as_crash
        self.logging = logging
        self.started = False
        self.stopped = False

    def write(self, bytes):
        self.writes.append(bytes)

    def has_crashed(self):
        return self.crashed

    def read_stdout_line(self, deadline):
        return self.lines.pop(0) + "\n"

    def read_stdout(self, deadline, size):
        first_line = self.lines[0]
        if size > len(first_line):
            self.lines.pop(0)
            remaining_size = size - len(first_line) - 1
            if not remaining_size:
                return first_line + "\n"
            return first_line + "\n" + self.read_stdout(deadline, remaining_size)
        result = self.lines[0][:size]
        self.lines[0] = self.lines[0][size:]
        return result

    def pop_all_buffered_stderr(self):
        return ''

    def read_either_stdout_or_stderr_line(self, deadline):
        # FIXME: We should have tests which intermix stderr and stdout lines.
        return self.read_stdout_line(deadline), None

    def start(self):
        self.started = True

    def stop(self, timeout_sec=0.0):
        self.stopped = True
        return

    def kill(self):
        return
