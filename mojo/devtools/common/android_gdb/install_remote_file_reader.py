# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import android_gdb.config as config
import subprocess
import tempfile


def install(gsutil, adb='adb'):
  verification_call_output = subprocess.check_output(
      [adb, 'shell', 'ls', config.REMOTE_FILE_READER_DEVICE_PATH])
  if config.REMOTE_FILE_READER_DEVICE_PATH != verification_call_output.strip():
    with tempfile.NamedTemporaryFile() as temp_file:
      subprocess.check_call([gsutil, 'cp', config.REMOTE_FILE_READER_CLOUD_PATH,
                             temp_file.name])
      subprocess.check_call([adb, 'push', temp_file.name,
                             config.REMOTE_FILE_READER_DEVICE_PATH])
      subprocess.check_call([adb, 'shell', 'chmod', '777',
                             config.REMOTE_FILE_READER_DEVICE_PATH])
