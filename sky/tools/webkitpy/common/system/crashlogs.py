# Copyright (c) 2011, Google Inc. All rights reserved.
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

import re


class CrashLogs(object):
    def __init__(self, host):
        self._host = host

    def find_newest_log(self, process_name, pid=None, include_errors=False, newer_than=None):
        if self._host.platform.is_mac():
            return self._find_newest_log_darwin(process_name, pid, include_errors, newer_than)
        return None

    def _log_directory_darwin(self):
        log_directory = self._host.filesystem.expanduser("~")
        log_directory = self._host.filesystem.join(log_directory, "Library", "Logs")
        if self._host.filesystem.exists(self._host.filesystem.join(log_directory, "DiagnosticReports")):
            log_directory = self._host.filesystem.join(log_directory, "DiagnosticReports")
        else:
            log_directory = self._host.filesystem.join(log_directory, "CrashReporter")
        return log_directory

    def _find_newest_log_darwin(self, process_name, pid, include_errors, newer_than):
        def is_crash_log(fs, dirpath, basename):
            return basename.startswith(process_name + "_") and basename.endswith(".crash")

        log_directory = self._log_directory_darwin()
        logs = self._host.filesystem.files_under(log_directory, file_filter=is_crash_log)
        first_line_regex = re.compile(r'^Process:\s+(?P<process_name>.*) \[(?P<pid>\d+)\]$')
        errors = ''
        for path in reversed(sorted(logs)):
            try:
                if not newer_than or self._host.filesystem.mtime(path) > newer_than:
                    f = self._host.filesystem.read_text_file(path)
                    match = first_line_regex.match(f[0:f.find('\n')])
                    if match and match.group('process_name') == process_name and (pid is None or int(match.group('pid')) == pid):
                        return errors + f
            except IOError, e:
                if include_errors:
                    errors += "ERROR: Failed to read '%s': %s\n" % (path, str(e))
            except OSError, e:
                if include_errors:
                    errors += "ERROR: Failed to read '%s': %s\n" % (path, str(e))

        if include_errors and errors:
            return errors
        return None
