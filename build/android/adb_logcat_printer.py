#!/usr/bin/env python
#
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Shutdown adb_logcat_monitor and print accumulated logs.

To test, call './adb_logcat_printer.py <base_dir>' where
<base_dir> contains 'adb logcat -v threadtime' files named as
logcat_<deviceID>_<sequenceNum>

The script will print the files to out, and will combine multiple
logcats from a single device if there is overlap.

Additionally, if a <base_dir>/LOGCAT_MONITOR_PID exists, the script
will attempt to terminate the contained PID by sending a SIGINT and
monitoring for the deletion of the aforementioned file.
"""
# pylint: disable=W0702

import cStringIO
import logging
import optparse
import os
import re
import signal
import sys
import time


# Set this to debug for more verbose output
LOG_LEVEL = logging.INFO


def CombineLogFiles(list_of_lists, logger):
  """Splices together multiple logcats from the same device.

  Args:
    list_of_lists: list of pairs (filename, list of timestamped lines)
    logger: handler to log events

  Returns:
    list of lines with duplicates removed
  """
  cur_device_log = ['']
  for cur_file, cur_file_lines in list_of_lists:
    # Ignore files with just the logcat header
    if len(cur_file_lines) < 2:
      continue
    common_index = 0
    # Skip this step if list just has empty string
    if len(cur_device_log) > 1:
      try:
        line = cur_device_log[-1]
        # Used to make sure we only splice on a timestamped line
        if re.match(r'^\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} ', line):
          common_index = cur_file_lines.index(line)
        else:
          logger.warning('splice error - no timestamp in "%s"?', line.strip())
      except ValueError:
        # The last line was valid but wasn't found in the next file
        cur_device_log += ['***** POSSIBLE INCOMPLETE LOGCAT *****']
        logger.info('Unable to splice %s. Incomplete logcat?', cur_file)

    cur_device_log += ['*'*30 + '  %s' % cur_file]
    cur_device_log.extend(cur_file_lines[common_index:])

  return cur_device_log


def FindLogFiles(base_dir):
  """Search a directory for logcat files.

  Args:
    base_dir: directory to search

  Returns:
    Mapping of device_id to a sorted list of file paths for a given device
  """
  logcat_filter = re.compile(r'^logcat_(\S+)_(\d+)$')
  # list of tuples (<device_id>, <seq num>, <full file path>)
  filtered_list = []
  for cur_file in os.listdir(base_dir):
    matcher = logcat_filter.match(cur_file)
    if matcher:
      filtered_list += [(matcher.group(1), int(matcher.group(2)),
                         os.path.join(base_dir, cur_file))]
  filtered_list.sort()
  file_map = {}
  for device_id, _, cur_file in filtered_list:
    if device_id not in file_map:
      file_map[device_id] = []

    file_map[device_id] += [cur_file]
  return file_map


def GetDeviceLogs(log_filenames, logger):
  """Read log files, combine and format.

  Args:
    log_filenames: mapping of device_id to sorted list of file paths
    logger: logger handle for logging events

  Returns:
    list of formatted device logs, one for each device.
  """
  device_logs = []

  for device, device_files in log_filenames.iteritems():
    logger.debug('%s: %s', device, str(device_files))
    device_file_lines = []
    for cur_file in device_files:
      with open(cur_file) as f:
        device_file_lines += [(cur_file, f.read().splitlines())]
    combined_lines = CombineLogFiles(device_file_lines, logger)
    # Prepend each line with a short unique ID so it's easy to see
    # when the device changes.  We don't use the start of the device
    # ID because it can be the same among devices.  Example lines:
    # AB324:  foo
    # AB324:  blah
    device_logs += [('\n' + device[-5:] + ':  ').join(combined_lines)]
  return device_logs


def ShutdownLogcatMonitor(base_dir, logger):
  """Attempts to shutdown adb_logcat_monitor and blocks while waiting."""
  try:
    monitor_pid_path = os.path.join(base_dir, 'LOGCAT_MONITOR_PID')
    with open(monitor_pid_path) as f:
      monitor_pid = int(f.readline())

    logger.info('Sending SIGTERM to %d', monitor_pid)
    os.kill(monitor_pid, signal.SIGTERM)
    i = 0
    while True:
      time.sleep(.2)
      if not os.path.exists(monitor_pid_path):
        return
      if not os.path.exists('/proc/%d' % monitor_pid):
        logger.warning('Monitor (pid %d) terminated uncleanly?', monitor_pid)
        return
      logger.info('Waiting for logcat process to terminate.')
      i += 1
      if i >= 10:
        logger.warning('Monitor pid did not terminate. Continuing anyway.')
        return

  except (ValueError, IOError, OSError):
    logger.exception('Error signaling logcat monitor - continuing')


def main(argv):
  parser = optparse.OptionParser(usage='Usage: %prog [options] <log dir>')
  parser.add_option('--output-path',
                    help='Output file path (if unspecified, prints to stdout)')
  options, args = parser.parse_args(argv)
  if len(args) != 1:
    parser.error('Wrong number of unparsed args')
  base_dir = args[0]
  if options.output_path:
    output_file = open(options.output_path, 'w')
  else:
    output_file = sys.stdout

  log_stringio = cStringIO.StringIO()
  logger = logging.getLogger('LogcatPrinter')
  logger.setLevel(LOG_LEVEL)
  sh = logging.StreamHandler(log_stringio)
  sh.setFormatter(logging.Formatter('%(asctime)-2s %(levelname)-8s'
                                    ' %(message)s'))
  logger.addHandler(sh)

  try:
    # Wait at least 5 seconds after base_dir is created before printing.
    #
    # The idea is that 'adb logcat > file' output consists of 2 phases:
    #  1 Dump all the saved logs to the file
    #  2 Stream log messages as they are generated
    #
    # We want to give enough time for phase 1 to complete.  There's no
    # good method to tell how long to wait, but it usually only takes a
    # second.  On most bots, this code path won't occur at all, since
    # adb_logcat_monitor.py command will have spawned more than 5 seconds
    # prior to called this shell script.
    try:
      sleep_time = 5 - (time.time() - os.path.getctime(base_dir))
    except OSError:
      sleep_time = 5
    if sleep_time > 0:
      logger.warning('Monitor just started? Sleeping %.1fs', sleep_time)
      time.sleep(sleep_time)

    assert os.path.exists(base_dir), '%s does not exist' % base_dir
    ShutdownLogcatMonitor(base_dir, logger)
    separator = '\n' + '*' * 80 + '\n\n'
    for log in GetDeviceLogs(FindLogFiles(base_dir), logger):
      output_file.write(log)
      output_file.write(separator)
    with open(os.path.join(base_dir, 'eventlog')) as f:
      output_file.write('\nLogcat Monitor Event Log\n')
      output_file.write(f.read())
  except:
    logger.exception('Unexpected exception')

  logger.info('Done.')
  sh.flush()
  output_file.write('\nLogcat Printer Event Log\n')
  output_file.write(log_stringio.getvalue())

if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
