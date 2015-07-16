# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import subprocess
import sys

def download_from_public_bucket(gs_path, output_path, depot_tools_path):
  gsutil_exe = os.path.join(depot_tools_path, "third_party", "gsutil", "gsutil")

  # We're downloading from a public bucket which does not need authentication,
  # but the user might have busted credential files somewhere such as ~/.boto
  # that the gsutil script will try (and fail) to use. Setting these
  # environment variables convinces gsutil not to attempt to use these, but
  # also generates a useless warning about failing to load the file. We want
  # to discard this warning but still preserve all output in the case of an
  # actual failure. So, we run the script and capture all output and then
  # throw the output away if the script succeeds (return code 0).
  env = os.environ.copy()
  env["AWS_CREDENTIAL_FILE"] = ""
  env["BOTO_CONFIG"] = ""
  try:
    subprocess.check_output(
        [gsutil_exe,
         "--bypass_prodaccess",
         "cp",
         gs_path,
         output_path],
        stderr=subprocess.STDOUT,
        env=env)
  except subprocess.CalledProcessError as e:
    print e.output
    sys.exit(1)
