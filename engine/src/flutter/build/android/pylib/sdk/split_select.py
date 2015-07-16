# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This module wraps Android's split-select tool."""
# pylint: disable=unused-argument

import os

from pylib import cmd_helper
from pylib import constants
from pylib.utils import timeout_retry

_SPLIT_SELECT_PATH = os.path.join(constants.ANDROID_SDK_TOOLS, 'split-select')
_DEFAULT_TIMEOUT = 30
_DEFAULT_RETRIES = 2

def _RunSplitSelectCmd(args, timeout=None, retries=None):
  """Runs a split-select command.

  Args:
    args: A list of arguments for split-select.
    timeout: Timeout in seconds.
    retries: Number of retries.

  Returns:
    The output of the command.
  """
  cmd = [_SPLIT_SELECT_PATH] + args
  status, output = cmd_helper.GetCmdStatusAndOutputWithTimeout(
      cmd, timeout_retry.CurrentTimeoutThread().GetRemainingTime())
  if status != 0:
    raise Exception('Failed running command %s' % str(cmd))
  return output

def _SplitConfig(device):
  """Returns a config specifying which APK splits are required by the device.

  Args:
    device: A DeviceUtils object.
  """
  return ('%s-r%s-%s:%s' %
          (device.language,
           device.country,
           device.screen_density,
           device.product_cpu_abi))

def SelectSplits(device, base_apk, split_apks,
                 timeout=_DEFAULT_TIMEOUT, retries=_DEFAULT_RETRIES):
  """Determines which APK splits the device requires.

  Args:
    device: A DeviceUtils object.
    base_apk: The path of the base APK.
    split_apks: A list of paths of APK splits.
    timeout: Timeout in seconds.
    retries: Number of retries.

  Returns:
    The list of APK splits that the device requires.
  """
  config = _SplitConfig(device)
  args = ['--target', config, '--base', base_apk]
  for split in split_apks:
    args.extend(['--split', split])
  return _RunSplitSelectCmd(args, timeout=timeout, retries=retries).splitlines()