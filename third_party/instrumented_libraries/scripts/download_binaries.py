#!/usr/bin/env python
# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Downloads pre-built sanitizer-instrumented third-party libraries from GCS."""

import os
import re
import subprocess
import sys

def get_ubuntu_release():
  supported_releases = ['precise', 'trusty']
  release = subprocess.check_output(['lsb_release', '-cs']).strip()
  if release not in supported_releases:
    raise Exception("Supported Ubuntu versions: %s", str(supported_releases))
  return release


def get_configuration(gyp_defines):
  if re.search(r'\b(msan)=1', gyp_defines):
    if 'msan_track_origins=0' in gyp_defines:
      return 'msan-no-origins'
    if 'msan_track_origins=2' in gyp_defines:
      return 'msan-chained-origins'
    if 'msan_track_origins=' not in gyp_defines:
      # NB: must be the same as the default value in common.gypi
      return 'msan-chained-origins'
  raise Exception(
      "Prebuilt instrumented libraries not available for your configuration.")


def get_archive_name(gyp_defines):
  return "%s-%s.tgz" % (get_configuration(gyp_defines), get_ubuntu_release())


def main(args):
  gyp_defines = os.environ.get('GYP_DEFINES', '')
  if not 'use_prebuilt_instrumented_libraries=1' in gyp_defines:
    return 0

  if not sys.platform.startswith('linux'):
    raise Exception("'use_prebuilt_instrumented_libraries=1' requires Linux.")

  archive_name = get_archive_name(gyp_defines)
  sha1file = '%s.sha1' % archive_name
  target_directory = 'src/third_party/instrumented_libraries/binaries/'

  subprocess.check_call([
      'download_from_google_storage',
      '--no_resume',
      '--no_auth',
      '--bucket', 'chromium-instrumented-libraries',
      '-s', sha1file], cwd=target_directory)

  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
