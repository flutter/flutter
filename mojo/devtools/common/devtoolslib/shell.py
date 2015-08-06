# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


class Shell(object):
  """Represents an abstract Mojo shell."""

  def serve_local_directory(self, local_dir_path, port=0):
    """Serves the content of the local (host) directory, making it available to
    the shell under the url returned by the function.

    The server will run on a separate thread until the program terminates. The
    call returns immediately.

    Args:
      local_dir_path: path to the directory to be served
      port: port at which the server will be available to the shell

    Returns:
      The url that the shell can use to access the content of |local_dir_path|.
    """
    raise NotImplementedError()

  def serve_local_directories(self, mappings, port=0):
    """Serves the content of the local (host) directories, making it available
    to the shell under the url returned by the function.

    The server will run on a separate thread until the program terminates. The
    call returns immediately.

    Args:
      mappings: List of tuples (prefix, local_base_path_list) mapping URLs that
          start with |prefix| to one or more local directories enumerated in
          |local_base_path_list|. The prefixes should skip the leading slash.
          The first matching prefix and the first location that contains the
          requested file will be used each time.
      port: port at which the server will be available to the shell

    Returns:
      The url that the shell can use to access the server.
    """
    raise NotImplementedError()

  def forward_host_port_to_shell(self, host_port):
    """Forwards a port on the host machine to the same port wherever the shell
    is running.

    This is a no-op if the shell is running locally.
    """
    raise NotImplementedError()

  def run(self, arguments):
    """Runs the shell with given arguments until shell exits, passing the stdout
    mingled with stderr produced by the shell onto the stdout.

    Returns:
      Exit code retured by the shell or None if the exit code cannot be
      retrieved.
    """
    raise NotImplementedError()

  def run_and_get_output(self, arguments, timeout=None):
    """Runs the shell with given arguments until shell exits and returns the
    output.

    Args:
      arguments: list of arguments for the shell
      timeout: maximum running time in seconds, after which the shell will be
          terminated

    Returns:
      A tuple of (return_code, output, did_time_out). |return_code| is the exit
      code returned by the shell or None if the exit code cannot be retrieved.
      |output| is the stdout mingled with the stderr produced by the shell.
      |did_time_out| is True iff the shell was terminated because it exceeded
      the |timeout| and False otherwise.
    """
    raise NotImplementedError()
