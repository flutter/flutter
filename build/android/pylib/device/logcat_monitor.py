# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# pylint: disable=unused-argument

import collections
import itertools
import logging
import subprocess
import tempfile
import time
import re

from pylib.device import adb_wrapper
from pylib.device import decorators
from pylib.device import device_errors


class LogcatMonitor(object):

  _THREADTIME_RE_FORMAT = (
      r'(?P<date>\S*) +(?P<time>\S*) +(?P<proc_id>%s) +(?P<thread_id>%s) +'
      r'(?P<log_level>%s) +(?P<component>%s) *: +(?P<message>%s)$')

  def __init__(self, adb, clear=True, filter_specs=None):
    """Create a LogcatMonitor instance.

    Args:
      adb: An instance of adb_wrapper.AdbWrapper.
      clear: If True, clear the logcat when monitoring starts.
      filter_specs: An optional list of '<tag>[:priority]' strings.
    """
    if isinstance(adb, adb_wrapper.AdbWrapper):
      self._adb = adb
    else:
      raise ValueError('Unsupported type passed for argument "device"')
    self._clear = clear
    self._filter_specs = filter_specs
    self._logcat_out = None
    self._logcat_out_file = None
    self._logcat_proc = None

  @decorators.WithTimeoutAndRetriesDefaults(10, 0)
  def WaitFor(self, success_regex, failure_regex=None, timeout=None,
              retries=None):
    """Wait for a matching logcat line or until a timeout occurs.

    This will attempt to match lines in the logcat against both |success_regex|
    and |failure_regex| (if provided). Note that this calls re.search on each
    logcat line, not re.match, so the provided regular expressions don't have
    to match an entire line.

    Args:
      success_regex: The regular expression to search for.
      failure_regex: An optional regular expression that, if hit, causes this
        to stop looking for a match. Can be None.
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      A match object if |success_regex| matches a part of a logcat line, or
      None if |failure_regex| matches a part of a logcat line.
    Raises:
      CommandFailedError on logcat failure (NOT on a |failure_regex| match).
      CommandTimeoutError if no logcat line matching either |success_regex| or
        |failure_regex| is found in |timeout| seconds.
      DeviceUnreachableError if the device becomes unreachable.
    """
    if isinstance(success_regex, basestring):
      success_regex = re.compile(success_regex)
    if isinstance(failure_regex, basestring):
      failure_regex = re.compile(failure_regex)

    logging.debug('Waiting %d seconds for "%s"', timeout, success_regex.pattern)

    # NOTE This will continue looping until:
    #  - success_regex matches a line, in which case the match object is
    #    returned.
    #  - failure_regex matches a line, in which case None is returned
    #  - the timeout is hit, in which case a CommandTimeoutError is raised.
    for l in self._adb.Logcat(filter_specs=self._filter_specs):
      m = success_regex.search(l)
      if m:
        return m
      if failure_regex and failure_regex.search(l):
        return None

  def FindAll(self, message_regex, proc_id=None, thread_id=None, log_level=None,
              component=None):
    """Finds all lines in the logcat that match the provided constraints.

    Args:
      message_regex: The regular expression that the <message> section must
        match.
      proc_id: The process ID to match. If None, matches any process ID.
      thread_id: The thread ID to match. If None, matches any thread ID.
      log_level: The log level to match. If None, matches any log level.
      component: The component to match. If None, matches any component.

    Yields:
      A match object for each matching line in the logcat. The match object
      will always contain, in addition to groups defined in |message_regex|,
      the following named groups: 'date', 'time', 'proc_id', 'thread_id',
      'log_level', 'component', and 'message'.
    """
    if proc_id is None:
      proc_id = r'\d+'
    if thread_id is None:
      thread_id = r'\d+'
    if log_level is None:
      log_level = r'[VDIWEF]'
    if component is None:
      component = r'[^\s:]+'
    threadtime_re = re.compile(
        type(self)._THREADTIME_RE_FORMAT % (
            proc_id, thread_id, log_level, component, message_regex))

    for line in self._adb.Logcat(dump=True, logcat_format='threadtime'):
      m = re.match(threadtime_re, line)
      if m:
        yield m

  def Start(self):
    """Starts the logcat monitor.

    Clears the logcat if |clear| was set in |__init__|.
    """
    if self._clear:
      self._adb.Logcat(clear=True)

  def __enter__(self):
    """Starts the logcat monitor."""
    self.Start()
    return self

  def __exit__(self, exc_type, exc_val, exc_tb):
    """Stops the logcat monitor."""
    pass
