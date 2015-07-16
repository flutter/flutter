#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Roll services version in the cdn."""

import argparse
import os
import subprocess
import sys
import tempfile

from mopy.config import Config
from mopy.paths import Paths

def target(config):
  target_name = config.target_os + "-" + config.target_cpu
  if config.is_official_build:
    target_name += "-official"
  return target_name


def get_gsutil():
  paths = Paths()
  sys.path.insert(0, os.path.join(paths.src_root, "tools"))
  # pylint: disable=F0401
  import find_depot_tools

  depot_tools_path = find_depot_tools.add_depot_tools_to_path()
  return os.path.join(depot_tools_path, "third_party", "gsutil", "gsutil")


def upload(gsutil_exe, source, dest):
  subprocess.check_call([gsutil_exe, "cp", source, dest])


def write_file_to_gs(gsutil_exe, file_contents, dest):
  with tempfile.NamedTemporaryFile() as temp_version_file:
    temp_version_file.write(file_contents)
    temp_version_file.flush()
    upload(gsutil_exe, temp_version_file.name, dest)


def roll_version(gsutil_exe, config, version):
  service_dir = 'gs://mojo/services/%s/%s' % (target(config), version)
  services = subprocess.check_output(
      [gsutil_exe, 'ls', service_dir]).strip().split('\n')
  for service in services:
    service_binary_name = service.split('/')[-1]
    service_location_file = ("gs://mojo/services/" + target(config) + "/" +
        service_binary_name + "_location")
    service_location_in_gs = service[len('gs://'):]
    write_file_to_gs(gsutil_exe, service_location_in_gs, service_location_file)


def main():
  parser = argparse.ArgumentParser(description="Change the version of the mojo "
      "services on the cdn.")
  parser.add_argument("-v", "--verbose", help="Verbose mode",
      action="store_true")
  parser.add_argument("version",
                      help="New version of the mojo services.")
  args = parser.parse_args()

  gsutil_exe = get_gsutil()

  for target_os in [Config.OS_LINUX, Config.OS_ANDROID]:
    config = Config(target_os=target_os)
    roll_version(gsutil_exe, config, args.version)

  return 0

if __name__ == "__main__":
  sys.exit(main())
