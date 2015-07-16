#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import sys
import tempfile
import zipfile

_PLATFORMS = ["linux-x64", "android-arm"]
_APPS = ["network_service", "network_service_apptests"]
_CURRENT_PATH = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, os.path.join(_CURRENT_PATH, "pylib"))
import gs

script_dir = os.path.dirname(os.path.realpath(__file__))


def download_app(app, version, tools_directory):
  prebuilt_directory = os.path.join(script_dir, "prebuilt/%s" % app)
  stamp_path = os.path.join(prebuilt_directory, "VERSION")

  try:
    with open(stamp_path) as stamp_file:
      current_version = stamp_file.read().strip()
      if current_version == version:
        return  # Already have the right version.
  except IOError:
    pass  # If the stamp file does not exist we need to download a new binary.

  for platform in _PLATFORMS:
    download_app_for_platform(app, version, platform, tools_directory)

  with open(stamp_path, 'w') as stamp_file:
    stamp_file.write(version)

def download_app_for_platform(app, version, platform, tools_directory):
  find_depot_tools_path = os.path.join(_CURRENT_PATH, tools_directory)
  sys.path.insert(0, find_depot_tools_path)
  # pylint: disable=F0401
  import find_depot_tools
  depot_tools_path = find_depot_tools.add_depot_tools_to_path()

  binary_name = app + ".mojo"
  gs_path = "gs://mojo/%s/%s/%s/%s.zip" % (app, version, platform, binary_name)
  output_directory = os.path.join(script_dir,
                                  "prebuilt/%s/%s" % (app, platform))

  with tempfile.NamedTemporaryFile() as temp_zip_file:
    gs.download_from_public_bucket(gs_path, temp_zip_file.name,
                                   depot_tools_path)
    with zipfile.ZipFile(temp_zip_file.name) as z:
      zi = z.getinfo(binary_name)
      mode = zi.external_attr >> 16
      z.extract(zi, output_directory)
      os.chmod(os.path.join(output_directory, binary_name), mode)

def main():
  parser = argparse.ArgumentParser(
      description="Download prebuilt network service binaries from google " +
                  "storage")
  parser.add_argument("--tools-directory",
                      dest="tools_directory",
                      metavar="<tools-directory>",
                      type=str,
                      required=True,
                      help="Path to the directory containing "
                           "find_depot_tools.py, specified as a relative path "
                           "from the location of this file.")
  args = parser.parse_args()

  version_path = os.path.join(script_dir, "NETWORK_SERVICE_VERSION")
  with open(version_path) as version_file:
    version = version_file.read().strip()

  for app in _APPS:
    download_app(app, version, args.tools_directory)

  return 0


if __name__ == "__main__":
  sys.exit(main())
