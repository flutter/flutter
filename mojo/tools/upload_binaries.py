#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tool to roll Chromium into Mojo. See:
https://github.com/domokit/mojo/wiki/Rolling-code-between-chromium-and-mojo#chromium---mojo-updates
"""

import argparse
import glob
import itertools
import os
import subprocess
import sys
import tempfile
import time
import zipfile

import mopy.gn as gn
from mopy.config import Config
from mopy.paths import Paths
from mopy.version import Version

sys.path.append(os.path.join(os.path.dirname(__file__), os.pardir, os.pardir,
                             "third_party", "pyelftools"))
import elftools.elf.elffile as elffile

sys.path.append(os.path.join(os.path.dirname(__file__), os.pardir,
                             'devtools', 'common'))
import android_gdb.signatures as signatures


BLACKLISTED_APPS = [
  # The network service apps are not produced out of the Mojo repo, but may
  # be present in the build dir.
  "network_service.mojo",
  "network_service_apptests.mojo",
]

ARCHITECTURE_INDEPENDENT_FILES = [
  # These are files other than *.mojo files which are part of our binary
  # artifact scheme. These files must be architecture independent.
  "obj/mojo/dart/apptest/apptest.dartzip",
]


def target(config):
  target_name = config.target_os + "-" + config.target_cpu
  if config.is_official_build:
    target_name += "-official"
  return target_name

def find_apps_to_upload(build_dir):
  apps = []
  for path in glob.glob(build_dir + "/*"):
    if not os.path.isfile(path):
      continue
    _, ext = os.path.splitext(path)
    if ext != '.mojo':
      continue
    if os.path.basename(path) in BLACKLISTED_APPS:
      continue
    apps.append(path)
  return apps


def find_architecture_independent_files(build_dir):
  existing_files = []
  for path in ARCHITECTURE_INDEPENDENT_FILES:
    joined_path = os.path.join(build_dir, path)
    if os.path.isfile(joined_path):
      existing_files.append(joined_path)
  return existing_files


def upload(config, source, dest, dry_run):
  paths = Paths(config)
  sys.path.insert(0, os.path.join(paths.src_root, "tools"))
  # pylint: disable=F0401
  import find_depot_tools

  depot_tools_path = find_depot_tools.add_depot_tools_to_path()
  gsutil_exe = os.path.join(depot_tools_path, "third_party", "gsutil", "gsutil")

  if dry_run:
    print str([gsutil_exe, "cp", source, dest])
  else:
    subprocess.check_call([gsutil_exe, "cp", source, dest])


def upload_symbols(config, build_dir, dry_run):
  dest_dir = "gs://mojo/symbols/"
  symbols_dir = os.path.join(build_dir, "symbols")
  for name in os.listdir(symbols_dir):
    path = os.path.join(symbols_dir, name)
    with open(path) as f:
      signature = signatures.get_signature(f, elffile)
      if signature is not None:
        dest = dest_dir + signature
        upload(config, path, dest, dry_run)


def upload_shell(config, dry_run, verbose):
  paths = Paths(config)
  zipfile_name = target(config)
  version = Version().version

  # Upload the binary.
  # TODO(blundell): Change this to be in the same structure as the LATEST files,
  # e.g., gs://mojo/shell/linux-x64/<version>/shell.zip.
  dest = "gs://mojo/shell/" + version + "/" + zipfile_name + ".zip"
  with tempfile.NamedTemporaryFile() as zip_file:
    with zipfile.ZipFile(zip_file, 'w') as z:
      shell_path = paths.target_mojo_shell_path
      with open(shell_path) as shell_binary:
        shell_filename = os.path.basename(shell_path)
        zipinfo = zipfile.ZipInfo(shell_filename)
        zipinfo.external_attr = 0777 << 16L
        compress_type = zipfile.ZIP_DEFLATED
        if config.target_os == Config.OS_ANDROID:
          # The APK is already compressed.
          compress_type = zipfile.ZIP_STORED
        zipinfo.compress_type = compress_type
        zipinfo.date_time = time.gmtime(os.path.getmtime(shell_path))
        if verbose:
          print "zipping %s" % shell_path
        z.writestr(zipinfo, shell_binary.read())
    upload(config, zip_file.name, dest, dry_run)

  # Update the LATEST file to contain the version of the new binary.
  latest_file = "gs://mojo/shell/%s/LATEST" % target(config)
  write_file_to_gs(version, latest_file, config, dry_run)


def upload_sky_shell_linux(config, dry_run, verbose, dest_prefix):
  paths = Paths(config)
  dest = '%(prefix)s/sky_shell.zip' % { 'prefix': dest_prefix }
  with tempfile.NamedTemporaryFile() as zip_file:
    with zipfile.ZipFile(zip_file, 'w') as z:
      shell_path = paths.target_sky_shell_path
      shell_filename = os.path.basename(shell_path)
      if verbose:
        print 'zipping %s' % shell_path
      z.write(shell_path, shell_filename, zipfile.ZIP_DEFLATED)
      icu_filename = 'icudtl.dat'
      icu_path = os.path.join(os.path.dirname(shell_path), icu_filename)
      if verbose:
        print 'zipping %s' % icu_path
      z.write(icu_path, icu_filename, zipfile.ZIP_DEFLATED)
    upload(config, zip_file.name, dest, dry_run)


def upload_sky_shell_android(config, dry_run, _, dest_prefix):
  paths = Paths(config)
  shell_path = paths.target_sky_shell_path
  shell_filename = os.path.basename(shell_path)
  dest = '%(prefix)s/%(filename)s' % {
    'prefix': dest_prefix,
    'filename': shell_filename,
  }
  upload(config, shell_path, dest, dry_run)


def upload_sky_shell(config, dry_run, verbose):
  target_name = target(config)
  version = Version().version
  template_data = { 'target': target_name, 'version': version }
  dest_prefix = 'gs://mojo/sky/shell/%(target)s/%(version)s' % template_data
  latest_file = 'gs://mojo/sky/shell/%(target)s/LATEST' % template_data
  if config.target_os == Config.OS_LINUX:
    upload_sky_shell_linux(config, dry_run, verbose, dest_prefix)
  elif config.target_os == Config.OS_ANDROID:
    upload_sky_shell_android(config, dry_run, verbose, dest_prefix)
  else:
    return
  write_file_to_gs(version, latest_file, config, dry_run)


def upload_app(app_binary_path, config, dry_run):
  app_binary_name = os.path.basename(app_binary_path)
  version = Version().version
  gsutil_app_location = ("gs://mojo/services/%s/%s/%s" %
                         (target(config), version, app_binary_name))

  # Upload the new binary.
  upload(config, app_binary_path, gsutil_app_location, dry_run)


def upload_file(file_path, config, dry_run):
  file_binary_name = os.path.basename(file_path)
  version = Version().version
  gsutil_file_location = "gs://mojo/file/%s/%s" % (version, file_binary_name)

  # Upload the new binary.
  upload(config, file_path, gsutil_file_location, dry_run)


def write_file_to_gs(file_contents, dest, config, dry_run):
  with tempfile.NamedTemporaryFile() as temp_version_file:
    temp_version_file.write(file_contents)
    temp_version_file.flush()
    upload(config, temp_version_file.name, dest, dry_run)


def main():
  parser = argparse.ArgumentParser(description="Upload binaries for apps and "
      "the Mojo shell to google storage (by default on Linux, but this can be "
      "changed via options).")
  parser.add_argument("-n", "--dry_run", help="Dry run, do not actually "+
      "upload", action="store_true")
  parser.add_argument("-v", "--verbose", help="Verbose mode",
      action="store_true")
  parser.add_argument("--android",
                      action="store_true",
                      help="Upload the shell and apps for Android")
  parser.add_argument("--official",
                      action="store_true",
                      help="Upload the official build of the Android shell")
  args = parser.parse_args()

  is_official_build = args.official
  target_os = Config.OS_LINUX
  if args.android:
    target_os = Config.OS_ANDROID
  elif is_official_build:
    print "Uploading official builds is only supported for android."
    return 1

  config = Config(target_os=target_os, is_debug=False,
                  is_official_build=is_official_build)

  upload_shell(config, args.dry_run, args.verbose)
  upload_sky_shell(config, args.dry_run, args.verbose)

  if is_official_build:
    print "Skipping uploading apps (official apk build)."
    return 0

  build_directory = gn.BuildDirectoryForConfig(config, Paths(config).src_root)
  apps_to_upload = find_apps_to_upload(build_directory)
  for app in apps_to_upload:
    upload_app(app, config, args.dry_run)

  files_to_upload = find_architecture_independent_files(build_directory)
  for file_to_upload in files_to_upload:
    upload_file(file_to_upload, config, args.dry_run)

  upload_symbols(config, build_directory, args.dry_run)

  return 0

if __name__ == "__main__":
  sys.exit(main())
