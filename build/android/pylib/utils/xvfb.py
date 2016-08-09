# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# pylint: disable=W0702

import os
import signal
import subprocess
import sys
import time


def _IsLinux():
  """Return True if on Linux; else False."""
  return sys.platform.startswith('linux')


class Xvfb(object):
  """Class to start and stop Xvfb if relevant.  Nop if not Linux."""

  def __init__(self):
    self._pid = 0

  def Start(self):
    """Start Xvfb and set an appropriate DISPLAY environment.  Linux only.

    Copied from tools/code_coverage/coverage_posix.py
    """
    if not _IsLinux():
      return
    proc = subprocess.Popen(['Xvfb', ':9', '-screen', '0', '1024x768x24',
                             '-ac'],
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    self._pid = proc.pid
    if not self._pid:
      raise Exception('Could not start Xvfb')
    os.environ['DISPLAY'] = ':9'

    # Now confirm, giving a chance for it to start if needed.
    for _ in range(10):
      proc = subprocess.Popen('xdpyinfo >/dev/null', shell=True)
      _, retcode = os.waitpid(proc.pid, 0)
      if retcode == 0:
        break
      time.sleep(0.25)
    if retcode != 0:
      raise Exception('Could not confirm Xvfb happiness')

  def Stop(self):
    """Stop Xvfb if needed.  Linux only."""
    if self._pid:
      try:
        os.kill(self._pid, signal.SIGKILL)
      except:
        pass
      del os.environ['DISPLAY']
      self._pid = 0
