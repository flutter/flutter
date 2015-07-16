# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import logging
import os
import tempfile
import time

from pylib import cmd_helper
from pylib import device_signal
from pylib.device import device_errors

# TODO(jbudorick) Remove once telemetry gets switched over.
import pylib.android_commands
import pylib.device.device_utils


class VideoRecorder(object):
  """Records a screen capture video from an Android Device (KitKat or newer).

  Args:
    device: DeviceUtils instance.
    host_file: Path to the video file to store on the host.
    megabits_per_second: Video bitrate in megabits per second. Allowed range
                         from 0.1 to 100 mbps.
    size: Video frame size tuple (width, height) or None to use the device
          default.
    rotate: If True, the video will be rotated 90 degrees.
  """
  def __init__(self, device, megabits_per_second=4, size=None,
               rotate=False):
    # TODO(jbudorick) Remove once telemetry gets switched over.
    if isinstance(device, pylib.android_commands.AndroidCommands):
      device = pylib.device.device_utils.DeviceUtils(device)
    self._device = device
    self._device_file = (
        '%s/screen-recording.mp4' % device.GetExternalStoragePath())
    self._recorder = None
    self._recorder_stdout = None
    self._is_started = False

    self._args = ['adb']
    if str(self._device):
      self._args += ['-s', str(self._device)]
    self._args += ['shell', 'screenrecord', '--verbose']
    self._args += ['--bit-rate', str(megabits_per_second * 1000 * 1000)]
    if size:
      self._args += ['--size', '%dx%d' % size]
    if rotate:
      self._args += ['--rotate']
    self._args += [self._device_file]

  def Start(self):
    """Start recording video."""
    self._recorder_stdout = tempfile.mkstemp()[1]
    self._recorder = cmd_helper.Popen(
        self._args, stdout=open(self._recorder_stdout, 'w'))
    if not self._device.GetPids('screenrecord'):
      raise RuntimeError('Recording failed. Is your device running Android '
                         'KitKat or later?')

  def IsStarted(self):
    if not self._is_started:
      for line in open(self._recorder_stdout):
        self._is_started = line.startswith('Content area is ')
        if self._is_started:
          break
    return self._is_started

  def Stop(self):
    """Stop recording video."""
    os.remove(self._recorder_stdout)
    self._is_started = False
    if not self._recorder:
      return
    if not self._device.KillAll('screenrecord', signum=device_signal.SIGINT,
                                quiet=True):
      logging.warning('Nothing to kill: screenrecord was not running')
    self._recorder.wait()

  def Pull(self, host_file=None):
    """Pull resulting video file from the device.

    Args:
      host_file: Path to the video file to store on the host.
    Returns:
      Output video file name on the host.
    """
    # TODO(jbudorick): Merge filename generation with the logic for doing so in
    # DeviceUtils.
    host_file_name = (
        host_file
        or 'screen-recording-%s.mp4' % time.strftime('%Y%m%dT%H%M%S',
                                                     time.localtime()))
    host_file_name = os.path.abspath(host_file_name)
    self._device.PullFile(self._device_file, host_file_name)
    self._device.RunShellCommand('rm -f "%s"' % self._device_file)
    return host_file_name
