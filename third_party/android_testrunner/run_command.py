#!/usr/bin/python2.4
#
#
# Copyright 2007, The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# System imports
import os
import signal
import subprocess
import tempfile
import threading
import time

# local imports
import errors
import logger

_abort_on_error = False

def SetAbortOnError(abort=True):
  """Sets behavior of RunCommand to throw AbortError if command process returns
  a negative error code"""
  global _abort_on_error
  _abort_on_error = abort

def RunCommand(cmd, timeout_time=None, retry_count=3, return_output=True,
               stdin_input=None):
  """Spawn and retry a subprocess to run the given shell command.

  Args:
    cmd: shell command to run
    timeout_time: time in seconds to wait for command to run before aborting.
    retry_count: number of times to retry command
    return_output: if True return output of command as string. Otherwise,
      direct output of command to stdout.
    stdin_input: data to feed to stdin
  Returns:
    output of command
  """
  result = None
  while True:
    try:
      result = RunOnce(cmd, timeout_time=timeout_time,
                       return_output=return_output, stdin_input=stdin_input)
    except errors.WaitForResponseTimedOutError:
      if retry_count == 0:
        raise
      retry_count -= 1
      logger.Log("No response for %s, retrying" % cmd)
    else:
      # Success
      return result

def RunOnce(cmd, timeout_time=None, return_output=True, stdin_input=None):
  """Spawns a subprocess to run the given shell command.

  Args:
    cmd: shell command to run
    timeout_time: time in seconds to wait for command to run before aborting.
    return_output: if True return output of command as string. Otherwise,
      direct output of command to stdout.
    stdin_input: data to feed to stdin
  Returns:
    output of command
  Raises:
    errors.WaitForResponseTimedOutError if command did not complete within
      timeout_time seconds.
    errors.AbortError is command returned error code and SetAbortOnError is on.
  """
  start_time = time.time()
  so = []
  global _abort_on_error, error_occurred
  error_occurred = False

  if return_output:
    output_dest = tempfile.TemporaryFile(bufsize=0)
  else:
    # None means direct to stdout
    output_dest = None
  if stdin_input:
    stdin_dest = subprocess.PIPE
  else:
    stdin_dest = None
  pipe = subprocess.Popen(
      cmd,
      executable='/bin/bash',
      stdin=stdin_dest,
      stdout=output_dest,
      stderr=subprocess.STDOUT,
      shell=True, close_fds=True,
      preexec_fn=lambda: signal.signal(signal.SIGPIPE, signal.SIG_DFL))

  def Run():
    global error_occurred
    try:
      pipe.communicate(input=stdin_input)
      output = None
      if return_output:
        output_dest.seek(0)
        output = output_dest.read()
        output_dest.close()
      if output is not None and len(output) > 0:
        so.append(output)
    except OSError, e:
      logger.SilentLog("failed to retrieve stdout from: %s" % cmd)
      logger.Log(e)
      so.append("ERROR")
      error_occurred = True
    if pipe.returncode:
      logger.SilentLog("Error: %s returned %d error code" %(cmd,
          pipe.returncode))
      error_occurred = True

  t = threading.Thread(target=Run)
  t.start()
  t.join(timeout_time)
  if t.isAlive():
    try:
      pipe.kill()
    except OSError:
      # Can't kill a dead process.
      pass
    finally:
      logger.SilentLog("about to raise a timeout for: %s" % cmd)
      raise errors.WaitForResponseTimedOutError

  output = "".join(so)
  if _abort_on_error and error_occurred:
    raise errors.AbortError(msg=output)

  return "".join(so)


def RunHostCommand(binary, valgrind=False):
  """Run a command on the host (opt using valgrind).

  Runs the host binary and returns the exit code.
  If successfull, the output (stdout and stderr) are discarded,
  but printed in case of error.
  The command can be run under valgrind in which case all the
  output are always discarded.

  Args:
    binary: full path of the file to be run.
    valgrind: If True the command will be run under valgrind.

  Returns:
    The command exit code (int)
  """
  if not valgrind:
    subproc = subprocess.Popen(binary, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT)
    subproc.wait()
    if subproc.returncode != 0:         # In case of error print the output
      print subproc.communicate()[0]
    return subproc.returncode
  else:
    # Need the full path to valgrind to avoid other versions on the system.
    subproc = subprocess.Popen(["/usr/bin/valgrind", "--tool=memcheck",
                                "--leak-check=yes", "-q", binary],
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    # Cannot rely on the retcode of valgrind. Instead look for an empty output.
    valgrind_out = subproc.communicate()[0].strip()
    if valgrind_out:
      print valgrind_out
      return 1
    else:
      return 0


def HasValgrind():
  """Check that /usr/bin/valgrind exists.

  We look for the fullpath to avoid picking up 'alternative' valgrind
  on the system.

  Returns:
    True if a system valgrind was found.
  """
  return os.path.exists("/usr/bin/valgrind")
