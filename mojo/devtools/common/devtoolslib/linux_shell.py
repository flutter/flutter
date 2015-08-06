# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import subprocess
import threading

from devtoolslib import http_server
from devtoolslib.shell import Shell
from devtoolslib.utils import overrides


class LinuxShell(Shell):
  """Wrapper around Mojo shell running on Linux.

  Args:
    executable_path: path to the shell binary
    command_prefix: optional list of arguments to prepend to the shell command,
        allowing e.g. to run the shell under debugger.
  """

  def __init__(self, executable_path, command_prefix=None):
    self.executable_path = executable_path
    self.command_prefix = command_prefix if command_prefix else []

  @overrides(Shell)
  def serve_local_directory(self, local_dir_path, port=0):
    mappings = [('', [local_dir_path])]
    return 'http://%s:%d/' % http_server.start_http_server(mappings, port)

  @overrides(Shell)
  def serve_local_directories(self, mappings, port=0):
    return 'http://%s:%d/' % http_server.start_http_server(mappings, port)

  @overrides(Shell)
  def forward_host_port_to_shell(self, host_port):
    pass

  @overrides(Shell)
  def run(self, arguments):
    command = self.command_prefix + [self.executable_path] + arguments
    return subprocess.call(command, stderr=subprocess.STDOUT)

  @overrides(Shell)
  def run_and_get_output(self, arguments, timeout=None):
    command = self.command_prefix + [self.executable_path] + arguments
    p = subprocess.Popen(command, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)

    class Results:
      """Workaround for Python scoping rules that prevent assigning to variables
      from the outer scope.
      """
      output = None

    def do_run():
      (Results.output, _) = p.communicate()

    run_thread = threading.Thread(target=do_run)
    run_thread.start()
    run_thread.join(timeout)

    if run_thread.is_alive():
      p.terminate()
      return p.returncode, Results.output, True
    return p.returncode, Results.output, False
