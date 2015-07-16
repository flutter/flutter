# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


class Shell(object):
  """Represents an abstract Mojo shell."""

  def ServeLocalDirectory(self, local_dir_path, port=0,
                          additional_mappings=None):
    """Serves the content of the local (host) directory, making it available to
    the shell under the url returned by the function.

    The server will run on a separate thread until the program terminates. The
    call returns immediately.

    Args:
      local_dir_path: path to the directory to be served
      port: port at which the server will be available to the shell
      additional_mappings: List of tuples (prefix, local_base_path) mapping
          URLs that start with |prefix| to local directory at |local_base_path|.
          The prefixes should skip the leading slash.

    Returns:
      The url that the shell can use to access the content of |local_dir_path|.
    """
    raise NotImplementedError()

  def ForwardHostPortToShell(self, host_port):
    """Forwards a port on the host machine to the same port wherever the shell
    is running.

    This is a no-op if the shell is running locally.
    """
    raise NotImplementedError()

  def Run(self, arguments):
    """Runs the shell with given arguments until shell exits, passing the stdout
    mingled with stderr produced by the shell onto the stdout.

    Returns:
      Exit code retured by the shell or None if the exit code cannot be
      retrieved.
    """
    raise NotImplementedError()

  def RunAndGetOutput(self, arguments):
    """Runs the shell with given arguments until shell exits and returns the
    output.

    Args:
      arguments: list of arguments for the shell

    Returns:
      A tuple of (return_code, output). |return_code| is the exit code returned
      by the shell or None if the exit code cannot be retrieved. |output| is the
      stdout mingled with the stderr produced by the shell.
    """
    raise NotImplementedError()
