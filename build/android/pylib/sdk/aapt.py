# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This module wraps the Android Asset Packaging Tool."""

import os

from pylib import cmd_helper
from pylib import constants
from pylib.utils import timeout_retry

_AAPT_PATH = os.path.join(constants.ANDROID_SDK_TOOLS, 'aapt')

def _RunAaptCmd(args):
  """Runs an aapt command.

  Args:
    args: A list of arguments for aapt.

  Returns:
    The output of the command.
  """
  cmd = [_AAPT_PATH] + args
  status, output = cmd_helper.GetCmdStatusAndOutput(cmd)
  if status != 0:
    raise Exception('Failed running aapt command: "%s" with output "%s".' %
                    (' '.join(cmd), output))
  return output

def Dump(what, apk, assets=None):
  """Returns the output of the aapt dump command.

  Args:
    what: What you want to dump.
    apk: Path to apk you want to dump information for.
    assets: List of assets in apk you want to dump information for.
  """
  assets = assets or []
  if isinstance(assets, basestring):
    assets = [assets]
  return _RunAaptCmd(['dump', what, apk] + assets).splitlines()