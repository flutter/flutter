#!/usr/bin/env python

# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Takes a screenshot or a screen video capture from an Android device."""

import logging
import optparse
import os
import sys

from pylib import screenshot
from pylib.device import device_errors
from pylib.device import device_utils

def _PrintMessage(heading, eol='\n'):
  sys.stdout.write('%s%s' % (heading, eol))
  sys.stdout.flush()


def _CaptureScreenshot(device, host_file):
  host_file = device.TakeScreenshot(host_file)
  _PrintMessage('Screenshot written to %s' % os.path.abspath(host_file))


def _CaptureVideo(device, host_file, options):
  size = tuple(map(int, options.size.split('x'))) if options.size else None
  recorder = screenshot.VideoRecorder(device,
                                      megabits_per_second=options.bitrate,
                                      size=size,
                                      rotate=options.rotate)
  try:
    recorder.Start()
    _PrintMessage('Recording. Press Enter to stop...', eol='')
    raw_input()
  finally:
    recorder.Stop()
  host_file = recorder.Pull(host_file)
  _PrintMessage('Video written to %s' % os.path.abspath(host_file))


def main():
  # Parse options.
  parser = optparse.OptionParser(description=__doc__,
                                 usage='screenshot.py [options] [filename]')
  parser.add_option('-d', '--device', metavar='ANDROID_DEVICE', help='Serial '
                    'number of Android device to use.', default=None)
  parser.add_option('-f', '--file', help='Save result to file instead of '
                    'generating a timestamped file name.', metavar='FILE')
  parser.add_option('-v', '--verbose', help='Verbose logging.',
                    action='store_true')
  video_options = optparse.OptionGroup(parser, 'Video capture')
  video_options.add_option('--video', help='Enable video capturing. Requires '
                           'Android KitKat or later', action='store_true')
  video_options.add_option('-b', '--bitrate', help='Bitrate in megabits/s, '
                           'from 0.1 to 100 mbps, %default mbps by default.',
                           default=4, type='float')
  video_options.add_option('-r', '--rotate', help='Rotate video by 90 degrees.',
                           default=False, action='store_true')
  video_options.add_option('-s', '--size', metavar='WIDTHxHEIGHT',
                           help='Frame size to use instead of the device '
                           'screen size.', default=None)
  parser.add_option_group(video_options)

  (options, args) = parser.parse_args()

  if len(args) > 1:
    parser.error('Too many positional arguments.')
  host_file = args[0] if args else options.file

  if options.verbose:
    logging.getLogger().setLevel(logging.DEBUG)

  devices = device_utils.DeviceUtils.HealthyDevices()
  if options.device:
    device = next((d for d in devices if d == options.device), None)
    if not device:
      raise device_errors.DeviceUnreachableError(options.device)
  else:
    if len(devices) > 1:
      parser.error('Multiple devices are attached. '
                   'Please specify device serial number with --device.')
    elif len(devices) == 1:
      device = devices[0]
    else:
      raise device_errors.NoDevicesError()

  if options.video:
    _CaptureVideo(device, host_file, options)
  else:
    _CaptureScreenshot(device, host_file)
  return 0


if __name__ == '__main__':
  sys.exit(main())
