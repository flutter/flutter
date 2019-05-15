#!/usr/bin/env python
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

'''Pave and boot one of the known target types with the images in the Fuchsia
SDK.
'''

import argparse
import collections
import json
import os
import subprocess
import sys
import tempfile

def SDKSubDirectory():
  if sys.platform == 'darwin':
    return 'mac'
  elif sys.platform.startswith('linux'):
    return 'linux'
  else:
    raise Error('Unsupported platform.')

def main():
  parser = argparse.ArgumentParser();

  parser.add_argument('--target',
    type=str, dest='target', choices=['chromebook'], default='chromebook')
   
  args = parser.parse_args()
  

  sdk_dir = os.path.join(os.path.dirname(sys.argv[0]),
    "..", "..", "fuchsia", "sdk", SDKSubDirectory())
  sdk_dir = os.path.abspath(sdk_dir)

  assert os.path.exists(sdk_dir)

  # TODO(chinmaygarde): This will be patched in the future for arm64.
  target_dir = os.path.join(sdk_dir, "target", "x64")
  target_dir = os.path.abspath(target_dir)
  assert os.path.exists(target_dir)

  with tempfile.NamedTemporaryFile() as ssh_keys_file:
    ssh_keys = subprocess.check_output(['ssh-add', '-L'])
    ssh_keys_file.write(ssh_keys)
    ssh_keys_file.flush()

    if args.target == 'chromebook':
      bootserver_command = [
        os.path.join(sdk_dir, "tools", "bootserver"),
        "--boot",
        os.path.join(target_dir, "fuchsia.zbi"),
        "--fvm",
        os.path.join(target_dir, "fvm.sparse.blk"),
        "--zircona",
        os.path.join(target_dir, "fuchsia.zbi"),
        "--zirconr",
        os.path.join(target_dir, "zircon.vboot"),
        "--authorized-keys",
        ssh_keys_file.name
      ]
    else:
      raise Error('Target not specified.')

    subprocess.check_call(bootserver_command)

  return 0

if __name__ == '__main__':
  sys.exit(main())
