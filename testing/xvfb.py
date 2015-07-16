#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Runs the test with xvfb on linux. Runs the test normally on other platforms.

For simplicity in gyp targets, this script just runs the test normal on
non-linux platforms.
"""

import os
import platform
import signal
import subprocess
import sys

import test_env


def kill(pid):
  """Kills a process and traps exception if the process doesn't exist anymore.
  """
  # If the process doesn't exist, it raises an exception that we can ignore.
  try:
    os.kill(pid, signal.SIGKILL)
  except OSError:
    pass


def get_xvfb_path(server_dir):
  """Figures out which X server to use."""
  xvfb_path = os.path.join(server_dir, 'Xvfb.' + platform.architecture()[0])
  if not os.path.exists(xvfb_path):
    xvfb_path = os.path.join(server_dir, 'Xvfb')
  if not os.path.exists(xvfb_path):
    print >> sys.stderr, (
        'No Xvfb found in designated server path: %s' % server_dir)
    raise Exception('No virtual server')
  return xvfb_path


def start_xvfb(xvfb_path, display):
  """Starts a virtual X server that we run the tests in.

  This makes it so we can run the tests even if we didn't start the tests from
  an X session.

  Args:
    xvfb_path: Path to Xvfb.
  """
  cmd = [xvfb_path, display, '-screen', '0', '1024x768x24', '-ac',
         '-nolisten', 'tcp', '-dpi', '96']
  try:
    proc = subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  except OSError:
    print >> sys.stderr, 'Failed to run %s' % ' '.join(cmd)
    return
  return proc


def wait_for_xvfb(xdisplaycheck, env):
  """Waits for xvfb to be fully initialized by using xdisplaycheck."""
  try:
    _logs = subprocess.check_output(
        [xdisplaycheck],
        stderr=subprocess.STDOUT,
        env=env)
  except OSError:
    print >> sys.stderr, 'Failed to load %s with cwd=%s' % (
        xdisplaycheck, os.getcwd())
    return False
  except subprocess.CalledProcessError as e:
    print >> sys.stderr, (
        'Xvfb failed to load properly (code %d) according to %s' %
        (e.returncode, xdisplaycheck))
    return False

  return True


def run_executable(cmd, build_dir, env):
  """Runs an executable within a xvfb buffer on linux or normally on other
  platforms.

  Requires that both xvfb and openbox are installed on linux.

  Detects recursion with an environment variable and do not create a recursive X
  buffer if present.
  """
  # First look if we are inside a display.
  if env.get('_CHROMIUM_INSIDE_XVFB') == '1':
    # No need to recurse.
    return test_env.run_executable(cmd, env)

  pid = None
  xvfb = 'Xvfb'
  try:
    if sys.platform == 'linux2':
      # Defaults to X display 9.
      display = ':9'
      xvfb_proc = start_xvfb(xvfb, display)
      if not xvfb_proc or not xvfb_proc.pid:
        return 1
      env['DISPLAY'] = display
      if not wait_for_xvfb(os.path.join(build_dir, 'xdisplaycheck'), env):
        rc = xvfb_proc.poll()
        if rc is None:
          print 'Xvfb still running, stopping.'
          xvfb_proc.terminate()
        else:
          print 'Xvfb exited, code %d' % rc

        print 'Xvfb output:'
        for l in xvfb_proc.communicate()[0].splitlines():
          print '> %s' % l

        return 3
      # Inhibit recursion.
      env['_CHROMIUM_INSIDE_XVFB'] = '1'
      # Some ChromeOS tests need a window manager. Technically, it could be
      # another script but that would be overkill.
      try:
        wm_cmd = ['openbox']
        subprocess.Popen(
            wm_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env)
      except OSError:
        print >> sys.stderr, 'Failed to run %s' % ' '.join(wm_cmd)
        return 1
    return test_env.run_executable(cmd, env)
  finally:
    if pid:
      kill(pid)


def main():
  if len(sys.argv) < 3:
    print >> sys.stderr, (
        'Usage: xvfb.py [path to build_dir] [command args...]')
    return 2
  return run_executable(sys.argv[2:], sys.argv[1], os.environ.copy())


if __name__ == "__main__":
  sys.exit(main())
