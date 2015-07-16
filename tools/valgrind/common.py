# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import logging
import platform
import os
import signal
import subprocess
import sys
import time


class NotImplementedError(Exception):
  pass


class TimeoutError(Exception):
  pass


def RunSubprocessInBackground(proc):
  """Runs a subprocess in the background. Returns a handle to the process."""
  logging.info("running %s in the background" % " ".join(proc))
  return subprocess.Popen(proc)


def RunSubprocess(proc, timeout=0):
  """ Runs a subprocess, until it finishes or |timeout| is exceeded and the
  process is killed with taskkill.  A |timeout| <= 0  means no timeout.

  Args:
    proc: list of process components (exe + args)
    timeout: how long to wait before killing, <= 0 means wait forever
  """

  logging.info("running %s, timeout %d sec" % (" ".join(proc), timeout))
  sys.stdout.flush()
  sys.stderr.flush()

  # Manually read and print out stdout and stderr.
  # By default, the subprocess is supposed to inherit these from its parent,
  # however when run under buildbot, it seems unable to read data from a
  # grandchild process, so we have to read the child and print the data as if
  # it came from us for buildbot to read it.  We're not sure why this is
  # necessary.
  # TODO(erikkay): should we buffer stderr and stdout separately?
  p = subprocess.Popen(proc, universal_newlines=True,
                       bufsize=0,  # unbuffered
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

  logging.info("started subprocess")

  did_timeout = False
  if timeout > 0:
    wait_until = time.time() + timeout
  while p.poll() is None and not did_timeout:
    # Have to use readline rather than readlines() or "for line in p.stdout:",
    # otherwise we get buffered even with bufsize=0.
    line = p.stdout.readline()
    while line and not did_timeout:
      sys.stdout.write(line)
      sys.stdout.flush()
      line = p.stdout.readline()
      if timeout > 0:
        did_timeout = time.time() > wait_until

  if did_timeout:
    logging.info("process timed out")
  else:
    logging.info("process ended, did not time out")

  if did_timeout:
    if IsWindows():
      subprocess.call(["taskkill", "/T", "/F", "/PID", str(p.pid)])
    else:
      # Does this kill all children, too?
      os.kill(p.pid, signal.SIGINT)
    logging.error("KILLED %d" % p.pid)
    # Give the process a chance to actually die before continuing
    # so that cleanup can happen safely.
    time.sleep(1.0)
    logging.error("TIMEOUT waiting for %s" % proc[0])
    raise TimeoutError(proc[0])
  else:
    for line in p.stdout:
      sys.stdout.write(line)
    if not IsMac():   # stdout flush fails on Mac
      logging.info("flushing stdout")
      sys.stdout.flush()

  logging.info("collecting result code")
  result = p.poll()
  if result:
    logging.error("%s exited with non-zero result code %d" % (proc[0], result))
  return result


def IsLinux():
  return sys.platform.startswith('linux')


def IsMac():
  return sys.platform.startswith('darwin')


def IsWindows():
  return sys.platform == 'cygwin' or sys.platform.startswith('win')


def WindowsVersionName():
  """Returns the name of the Windows version if it is known, or None.

  Possible return values are: xp, vista, 7, 8, or None
  """
  if sys.platform == 'cygwin':
    # Windows version number is hiding in system name.  Looks like:
    # CYGWIN_NT-6.1-WOW64
    try:
      version_str = platform.uname()[0].split('-')[1]
    except:
      return None
  elif sys.platform.startswith('win'):
    # Normal Windows version string.  Mine: 6.1.7601
    version_str = platform.version()
  else:
    return None

  parts = version_str.split('.')
  try:
    major = int(parts[0])
    minor = int(parts[1])
  except:
    return None  # Can't parse, unknown version.

  if major == 5:
    return 'xp'
  elif major == 6 and minor == 0:
    return 'vista'
  elif major == 6 and minor == 1:
    return '7'
  elif major == 6 and minor == 2:
    return '8'  # Future proof.  ;)
  return None


def PlatformNames():
  """Return an array of string to be used in paths for the platform
  (e.g. suppressions, gtest filters, ignore files etc.)
  The first element of the array describes the 'main' platform
  """
  if IsLinux():
    return ['linux']
  if IsMac():
    return ['mac']
  if IsWindows():
    names = ['win32']
    version_name = WindowsVersionName()
    if version_name is not None:
      names.append('win-%s' % version_name)
    return names
  raise NotImplementedError('Unknown platform "%s".' % sys.platform)


def PutEnvAndLog(env_name, env_value):
  os.putenv(env_name, env_value)
  logging.info('export %s=%s', env_name, env_value)

def BoringCallers(mangled, use_re_wildcards):
  """Return a list of 'boring' function names (optinally mangled)
  with */? wildcards (optionally .*/.).
  Boring = we drop off the bottom of stack traces below such functions.
  """

  need_mangling = [
    # Don't show our testing framework:
    ("testing::Test::Run",     "_ZN7testing4Test3RunEv"),
    ("testing::TestInfo::Run", "_ZN7testing8TestInfo3RunEv"),
    ("testing::internal::Handle*ExceptionsInMethodIfSupported*",
     "_ZN7testing8internal3?Handle*ExceptionsInMethodIfSupported*"),

    # Depend on scheduling:
    ("MessageLoop::Run",     "_ZN11MessageLoop3RunEv"),
    ("MessageLoop::RunTask", "_ZN11MessageLoop7RunTask*"),
    ("RunnableMethod*",      "_ZN14RunnableMethod*"),
    ("DispatchToMethod*",    "_Z*16DispatchToMethod*"),
    ("base::internal::Invoker*::DoInvoke*",
     "_ZN4base8internal8Invoker*DoInvoke*"),  # Invoker{1,2,3}
    ("base::internal::RunnableAdapter*::Run*",
     "_ZN4base8internal15RunnableAdapter*Run*"),
  ]

  ret = []
  for pair in need_mangling:
    ret.append(pair[1 if mangled else 0])

  ret += [
    # Also don't show the internals of libc/pthread.
    "start_thread",
    "main",
    "BaseThreadInitThunk",
  ]

  if use_re_wildcards:
    for i in range(0, len(ret)):
      ret[i] = ret[i].replace('*', '.*').replace('?', '.')

  return ret

def NormalizeWindowsPath(path):
  """If we're using Cygwin Python, turn the path into a Windows path.

  Don't turn forward slashes into backslashes for easier copy-pasting and
  escaping.

  TODO(rnk): If we ever want to cut out the subprocess invocation, we can use
  _winreg to get the root Cygwin directory from the registry key:
  HKEY_LOCAL_MACHINE\SOFTWARE\Cygwin\setup\rootdir.
  """
  if sys.platform.startswith("cygwin"):
    p = subprocess.Popen(["cygpath", "-m", path],
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    (out, err) = p.communicate()
    if err:
      logging.warning("WARNING: cygpath error: %s", err)
    return out.strip()
  else:
    return path

############################
# Common output format code

def PrintUsedSuppressionsList(suppcounts):
  """ Prints out the list of used suppressions in a format common to all the
      memory tools. If the list is empty, prints nothing and returns False,
      otherwise True.

      suppcounts: a dictionary of used suppression counts,
                  Key -> name, Value -> count.
  """
  if not suppcounts:
    return False

  print "-----------------------------------------------------"
  print "Suppressions used:"
  print "  count name"
  for (name, count) in sorted(suppcounts.items(), key=lambda (k,v): (v,k)):
    print "%7d %s" % (count, name)
  print "-----------------------------------------------------"
  sys.stdout.flush()
  return True
