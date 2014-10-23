# Copyright (C) 2014 Google Inc. All rights reserved.
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
#     * Neither the Google name nor the names of its
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

from webkitpy.layout_tests.port import driver
import time
import shutil


class BrowserTestDriver(driver.Driver):
    """Object for running print preview test(s) using browser_tests."""
    def __init__(self, port, worker_number, pixel_tests, no_timeout=False):
        """Invokes the constructor of driver.Driver."""
        super(BrowserTestDriver, self).__init__(port, worker_number, pixel_tests, no_timeout)

    def start(self, pixel_tests, per_test_args, deadline):
        """Same as Driver.start() however, it has an extra step. It waits for
        a path to a file to be used for stdin to be printed by the browser test.
        If a path is found by the deadline test test will open the file and
        assign it to the stdin of the process that is owned by this driver's
        server process.
        """
        # FIXME(ivandavid): Need to handle case where the layout test doesn't
        # get a file name.
        new_cmd_line = self.cmd_line(pixel_tests, per_test_args)
        if not self._server_process or new_cmd_line != self._current_cmd_line:
            self._start(pixel_tests, per_test_args)
            self._run_post_start_tasks()
            self._open_stdin_path(deadline)

    # Gets the path of the directory that the file for stdin communication is
    # in. Since the browser test cannot clean it up, the layout test framework
    # will. Everything the browser test uses is stored in the same directory as
    # the stdin file, so deleting that directory recursively will remove all the
    # other temp data, like the printed pdf. This function assumes the correct
    # file path is sent. It won't delete files with only one component to avoid
    # accidentally deleting files like /tmp.
    def _open_stdin_path(self, deadline, test=False):
        # FIXME(ivandavid): Come up with a way to test & see what happens when
        # the file can't be opened.
        path, found = self._read_stdin_path(deadline)
        if found:
            if test == False:
                self._server_process._proc.stdin = open(path, 'wb', 0)

    def _read_stdin_path(self, deadline):
        # return (stdin_path, bool)
        block = self._read_block(deadline)
        if block.stdin_path:
            return (block.stdin_path, True)
        return (None, False)

    def cmd_line(self, pixel_tests, per_test_args):
        """Command line arguments to run the browser test."""
        cmd = self._command_wrapper(self._port.get_option('wrapper'))
        cmd.append(self._port._path_to_driver())
        cmd.append('--gtest_filter=PrintPreviewPdfGeneratedBrowserTest.MANUAL_LayoutTestDriver')
        cmd.append('--run-manual')
        cmd.append('--single_process')
        cmd.extend(per_test_args)
        cmd.extend(self._port.get_option('additional_drt_flag', []))
        return cmd

    def stop(self):
        if self._server_process:
            self._server_process.write('QUIT')
        super(BrowserTestDriver, self).stop(self._port.driver_stop_timeout())
