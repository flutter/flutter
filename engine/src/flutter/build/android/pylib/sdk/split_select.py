# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This module wraps Android's split-select tool."""

import os

from pylib import cmd_helper
from pylib import constants
from pylib.utils import timeout_retry

_SPLIT_SELECT_PATH = os.path.join(constants.ANDROID_SDK_TOOLS, 'split-select')

def _RunSplitSelectCmd(args):
  """Runs a split-select command.

  Args:
    args: A list of arguments for split-select.

  Returns:
    The output of the command.
  """
  cmd = [_SPLIT_SELECT_PATH] + args
  status, output = cmd_helper.GetCmdStatusAndOutput(cmd)
  if status != 0:
    raise Exception('Failed running command "%s" with output "%s".' %
                    (' '.join(cmd), output))
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

def SelectSplits(device, base_apk, split_apks):
  """Determines which APK splits the device requires.

  Args:
    device: A DeviceUtils object.
    base_apk: The path of the base APK.
    split_apks: A list of paths of APK splits.

  Returns:
    The list of APK splits that the device requires.
  """
  config = _SplitConfig(device)
  args = ['--target', config, '--base', base_apk]
  for split in split_apks:
    args.extend(['--split', split])
  return _RunSplitSelectCmd(args).splitlines()