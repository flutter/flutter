#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" Shared code for handling content_aware_hashing for fuchsia.
"""
import json
import os
import subprocess

_script_dir = os.path.abspath(os.path.join(os.path.realpath(__file__), '..'))
_src_root_dir = os.path.join(_script_dir, '..', '..', '..')


def get_content_hash():
  ci_config_path = os.path.join(_src_root_dir, 'flutter', 'ci', 'builders', 'linux_fuchsia.json')
  upload_content_hash = False
  if os.path.exists(ci_config_path):
    with open(ci_config_path, 'r') as f:
      ci_config = json.load(f)
      upload_content_hash = ci_config.get('luci_flags', {}).get('upload_content_hash', False)
  if upload_content_hash:
    script_path = os.path.join(
        _src_root_dir, '..', '..', 'bin', 'internal', 'content_aware_hash.sh'
    )
    if os.path.exists(script_path):
      command = [script_path]
      try:
        content_hash = subprocess.check_output(command, text=True).strip()
        print('Using content hash %s for engine version' % content_hash)
        return content_hash
      except subprocess.CalledProcessError as e:
        print('Error getting content hash, falling back to git hash: %s' % e)
    else:
      print('Could not find content_aware_hash.sh at %s' % script_path)
  return ''
