#!/usr/bin/env python
#
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Saves logcats from all connected devices.

Usage: adb_logcat_monitor.py <base_dir> [<adb_binary_path>]

This script will repeatedly poll adb for new devices and save logcats
inside the <base_dir> directory, which it attempts to create.  The
script will run until killed by an external signal.  To test, run the
script in a shell and <Ctrl>-C it after a while.  It should be
resilient across phone disconnects and reconnects and start the logcat
early enough to not miss anything.
"""

import logging
import os
import re
import shutil
import signal
import subprocess
import sys
import time

# Map from device_id -> (process, logcat_num)
devices = {}


class TimeoutException(Exception):
  """Exception used to signal a timeout."""
  pass


class SigtermError(Exception):
  """Exception used to catch a sigterm."""
  pass


def StartLogcatIfNecessary(device_id, adb_cmd, base_dir):
  """Spawns a adb logcat process if one is not currently running."""
  process, logcat_num = devices[device_id]
  if process:
    if process.poll() is None:
      # Logcat process is still happily running
      return
    else:
      logging.info('Logcat for device %s has died', device_id)
      error_filter = re.compile('- waiting for device -')
      for line in process.stderr:
        if not error_filter.match(line):
          logging.error(device_id + ':   ' + line)

  logging.info('Starting logcat %d for device %s', logcat_num,
               device_id)
  logcat_filename = 'logcat_%s_%03d' % (device_id, logcat_num)
  logcat_file = open(os.path.join(base_dir, logcat_filename), 'w')
  process = subprocess.Popen([adb_cmd, '-s', device_id,
                              'logcat', '-v', 'threadtime'],
                             stdout=logcat_file,
                             stderr=subprocess.PIPE)
  devices[device_id] = (process, logcat_num + 1)


def GetAttachedDevices(adb_cmd):
  """Gets the device list from adb.

  We use an alarm in this function to avoid deadlocking from an external
  dependency.

  Args:
    adb_cmd: binary to run adb

  Returns:
    list of devices or an empty list on timeout
  """
  signal.alarm(2)
  try:
    out, err = subprocess.Popen([adb_cmd, 'devices'],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE).communicate()
    if err:
      logging.warning('adb device error %s', err.strip())
    return re.findall('^(\\S+)\tdevice$', out, re.MULTILINE)
  except TimeoutException:
    logging.warning('"adb devices" command timed out')
    return []
  except (IOError, OSError):
    logging.exception('Exception from "adb devices"')
    return []
  finally:
    signal.alarm(0)


def main(base_dir, adb_cmd='adb'):
  """Monitor adb forever.  Expects a SIGINT (Ctrl-C) to kill."""
  # We create the directory to ensure 'run once' semantics
  if os.path.exists(base_dir):
    print 'adb_logcat_monitor: %s already exists? Cleaning' % base_dir
    shutil.rmtree(base_dir, ignore_errors=True)

  os.makedirs(base_dir)
  logging.basicConfig(filename=os.path.join(base_dir, 'eventlog'),
                      level=logging.INFO,
                      format='%(asctime)-2s %(levelname)-8s %(message)s')

  # Set up the alarm for calling 'adb devices'. This is to ensure
  # our script doesn't get stuck waiting for a process response
  def TimeoutHandler(_signum, _unused_frame):
    raise TimeoutException()
  signal.signal(signal.SIGALRM, TimeoutHandler)

  # Handle SIGTERMs to ensure clean shutdown
  def SigtermHandler(_signum, _unused_frame):
    raise SigtermError()
  signal.signal(signal.SIGTERM, SigtermHandler)

  logging.info('Started with pid %d', os.getpid())
  pid_file_path = os.path.join(base_dir, 'LOGCAT_MONITOR_PID')

  try:
    with open(pid_file_path, 'w') as f:
      f.write(str(os.getpid()))
    while True:
      for device_id in GetAttachedDevices(adb_cmd):
        if not device_id in devices:
          subprocess.call([adb_cmd, '-s', device_id, 'logcat', '-c'])
          devices[device_id] = (None, 0)

      for device in devices:
        # This will spawn logcat watchers for any device ever detected
        StartLogcatIfNecessary(device, adb_cmd, base_dir)

      time.sleep(5)
  except SigtermError:
    logging.info('Received SIGTERM, shutting down')
  except: # pylint: disable=bare-except
    logging.exception('Unexpected exception in main.')
  finally:
    for process, _ in devices.itervalues():
      if process:
        try:
          process.terminate()
        except OSError:
          pass
    os.remove(pid_file_path)


if __name__ == '__main__':
  if 2 <= len(sys.argv) <= 3:
    print 'adb_logcat_monitor: Initializing'
    sys.exit(main(*sys.argv[1:3]))

  print 'Usage: %s <base_dir> [<adb_binary_path>]' % sys.argv[0]
