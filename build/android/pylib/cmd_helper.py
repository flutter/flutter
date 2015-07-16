# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A wrapper for subprocess to make calling shell commands easier."""

import logging
import os
import pipes
import select
import signal
import string
import StringIO
import subprocess
import time

# fcntl is not available on Windows.
try:
  import fcntl
except ImportError:
  fcntl = None

_SafeShellChars = frozenset(string.ascii_letters + string.digits + '@%_-+=:,./')

def SingleQuote(s):
  """Return an shell-escaped version of the string using single quotes.

  Reliably quote a string which may contain unsafe characters (e.g. space,
  quote, or other special characters such as '$').

  The returned value can be used in a shell command line as one token that gets
  to be interpreted literally.

  Args:
    s: The string to quote.

  Return:
    The string quoted using single quotes.
  """
  return pipes.quote(s)

def DoubleQuote(s):
  """Return an shell-escaped version of the string using double quotes.

  Reliably quote a string which may contain unsafe characters (e.g. space
  or quote characters), while retaining some shell features such as variable
  interpolation.

  The returned value can be used in a shell command line as one token that gets
  to be further interpreted by the shell.

  The set of characters that retain their special meaning may depend on the
  shell implementation. This set usually includes: '$', '`', '\', '!', '*',
  and '@'.

  Args:
    s: The string to quote.

  Return:
    The string quoted using double quotes.
  """
  if not s:
    return '""'
  elif all(c in _SafeShellChars for c in s):
    return s
  else:
    return '"' + s.replace('"', '\\"') + '"'


def Popen(args, stdout=None, stderr=None, shell=None, cwd=None, env=None):
  return subprocess.Popen(
      args=args, cwd=cwd, stdout=stdout, stderr=stderr,
      shell=shell, close_fds=True, env=env,
      preexec_fn=lambda: signal.signal(signal.SIGPIPE, signal.SIG_DFL))


def Call(args, stdout=None, stderr=None, shell=None, cwd=None, env=None):
  pipe = Popen(args, stdout=stdout, stderr=stderr, shell=shell, cwd=cwd,
               env=env)
  pipe.communicate()
  return pipe.wait()


def RunCmd(args, cwd=None):
  """Opens a subprocess to execute a program and returns its return value.

  Args:
    args: A string or a sequence of program arguments. The program to execute is
      the string or the first item in the args sequence.
    cwd: If not None, the subprocess's current directory will be changed to
      |cwd| before it's executed.

  Returns:
    Return code from the command execution.
  """
  logging.info(str(args) + ' ' + (cwd or ''))
  return Call(args, cwd=cwd)


def GetCmdOutput(args, cwd=None, shell=False):
  """Open a subprocess to execute a program and returns its output.

  Args:
    args: A string or a sequence of program arguments. The program to execute is
      the string or the first item in the args sequence.
    cwd: If not None, the subprocess's current directory will be changed to
      |cwd| before it's executed.
    shell: Whether to execute args as a shell command.

  Returns:
    Captures and returns the command's stdout.
    Prints the command's stderr to logger (which defaults to stdout).
  """
  (_, output) = GetCmdStatusAndOutput(args, cwd, shell)
  return output


def _ValidateAndLogCommand(args, cwd, shell):
  if isinstance(args, basestring):
    if not shell:
      raise Exception('string args must be run with shell=True')
  else:
    if shell:
      raise Exception('array args must be run with shell=False')
    args = ' '.join(SingleQuote(c) for c in args)
  if cwd is None:
    cwd = ''
  else:
    cwd = ':' + cwd
  logging.info('[host]%s> %s', cwd, args)
  return args


def GetCmdStatusAndOutput(args, cwd=None, shell=False):
  """Executes a subprocess and returns its exit code and output.

  Args:
    args: A string or a sequence of program arguments. The program to execute is
      the string or the first item in the args sequence.
    cwd: If not None, the subprocess's current directory will be changed to
      |cwd| before it's executed.
    shell: Whether to execute args as a shell command. Must be True if args
      is a string and False if args is a sequence.

  Returns:
    The 2-tuple (exit code, output).
  """
  _ValidateAndLogCommand(args, cwd, shell)
  pipe = Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
               shell=shell, cwd=cwd)
  stdout, stderr = pipe.communicate()

  if stderr:
    logging.critical(stderr)
  if len(stdout) > 4096:
    logging.debug('Truncated output:')
  logging.debug(stdout[:4096])
  return (pipe.returncode, stdout)


class TimeoutError(Exception):
  """Module-specific timeout exception."""
  pass


def _IterProcessStdout(process, timeout=None, buffer_size=4096,
                       poll_interval=1):
  assert fcntl, 'fcntl module is required'
  try:
    # Enable non-blocking reads from the child's stdout.
    child_fd = process.stdout.fileno()
    fl = fcntl.fcntl(child_fd, fcntl.F_GETFL)
    fcntl.fcntl(child_fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)

    end_time = (time.time() + timeout) if timeout else None
    while True:
      if end_time and time.time() > end_time:
        raise TimeoutError
      read_fds, _, _ = select.select([child_fd], [], [], poll_interval)
      if child_fd in read_fds:
        data = os.read(child_fd, buffer_size)
        if not data:
          break
        yield data
      if process.poll() is not None:
        break
  finally:
    try:
      # Make sure the process doesn't stick around if we fail with an
      # exception.
      process.kill()
    except OSError:
      pass
    process.wait()


def GetCmdStatusAndOutputWithTimeout(args, timeout, cwd=None, shell=False,
                                     logfile=None):
  """Executes a subprocess with a timeout.

  Args:
    args: List of arguments to the program, the program to execute is the first
      element.
    timeout: the timeout in seconds or None to wait forever.
    cwd: If not None, the subprocess's current directory will be changed to
      |cwd| before it's executed.
    shell: Whether to execute args as a shell command. Must be True if args
      is a string and False if args is a sequence.
    logfile: Optional file-like object that will receive output from the
      command as it is running.

  Returns:
    The 2-tuple (exit code, output).
  """
  _ValidateAndLogCommand(args, cwd, shell)
  output = StringIO.StringIO()
  process = Popen(args, cwd=cwd, shell=shell, stdout=subprocess.PIPE,
                  stderr=subprocess.STDOUT)
  for data in _IterProcessStdout(process, timeout=timeout):
    if logfile:
      logfile.write(data)
    output.write(data)
  return process.returncode, output.getvalue()


def IterCmdOutputLines(args, timeout=None, cwd=None, shell=False,
                       check_status=True):
  """Executes a subprocess and continuously yields lines from its output.

  Args:
    args: List of arguments to the program, the program to execute is the first
      element.
    cwd: If not None, the subprocess's current directory will be changed to
      |cwd| before it's executed.
    shell: Whether to execute args as a shell command. Must be True if args
      is a string and False if args is a sequence.
    check_status: A boolean indicating whether to check the exit status of the
      process after all output has been read.

  Yields:
    The output of the subprocess, line by line.

  Raises:
    CalledProcessError if check_status is True and the process exited with a
      non-zero exit status.
  """
  cmd = _ValidateAndLogCommand(args, cwd, shell)
  process = Popen(args, cwd=cwd, shell=shell, stdout=subprocess.PIPE,
                  stderr=subprocess.STDOUT)
  buffer_output = ''
  for data in _IterProcessStdout(process, timeout=timeout):
    buffer_output += data
    has_incomplete_line = buffer_output[-1] not in '\r\n'
    lines = buffer_output.splitlines()
    buffer_output = lines.pop() if has_incomplete_line else ''
    for line in lines:
      yield line
  if buffer_output:
    yield buffer_output
  if check_status and process.returncode:
    raise subprocess.CalledProcessError(process.returncode, cmd)
