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

import logging


_log = logging.getLogger(__name__)


class DumpReader(object):
    """Base class for breakpad dump readers."""

    def __init__(self, host, build_dir):
        self._host = host
        self._build_dir = build_dir

    def check_is_functional(self):
        """This routine must be implemented by subclasses.

        Returns True if this reader is functional."""
        raise NotImplementedError()

    def crash_dumps_directory(self):
        return self._host.filesystem.join(self._build_dir, 'crash-dumps')

    def clobber_old_results(self):
        if self._host.filesystem.isdir(self.crash_dumps_directory()):
            self._host.filesystem.rmtree(self.crash_dumps_directory())

    def look_for_new_crash_logs(self, crashed_processes, start_time):
        if not crashed_processes:
            return None

        if not self.check_is_functional():
            return None

        pid_to_minidump = dict()
        for root, dirs, files in self._host.filesystem.walk(self.crash_dumps_directory()):
            for dmp in [f for f in files if f.endswith(self._file_extension())]:
                dmp_file = self._host.filesystem.join(root, dmp)
                if self._host.filesystem.mtime(dmp_file) < start_time:
                    continue
                pid = self._get_pid_from_dump(dmp_file)
                if pid:
                    pid_to_minidump[pid] = dmp_file

        result = dict()
        for test, process_name, pid in crashed_processes:
            if str(pid) in pid_to_minidump:
                stack = self._get_stack_from_dump(pid_to_minidump[str(pid)])
                if stack:
                    result[test] = stack

        return result

    def _get_pid_from_dump(self, dump_file):
        """This routine must be implemented by subclasses.

        This routine returns the PID of the crashed process that produced the given dump_file."""
        raise NotImplementedError()

    def _get_stack_from_dump(self, dump_file):
        """This routine must be implemented by subclasses.

        Returns the stack stored in the given breakpad dump_file."""
        raise NotImplementedError()

    def _file_extension(self):
        """This routine must be implemented by subclasses.

        Returns the file extension of crash dumps written by breakpad."""
        raise NotImplementedError()
