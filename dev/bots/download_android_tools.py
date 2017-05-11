#!/usr/bin/python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Downloads trimmed-down Android Tools from Google Cloud Storage and extracts
them to INSTALL_DIR, updating INSTALL_DIR/VERSION_* stamp files with current
version. Does nothing if INSTALL_DIR/VERSION_* are already up to date.
"""

import os
import shutil
import subprocess
import sys
import tarfile
import optparse

# Path constants. (All of these should be absolute paths.)
THIS_DIR = os.path.abspath(os.path.dirname(__file__))
INSTALL_DIR = os.path.join(THIS_DIR, 'android_tools')

import find_depot_tools

DEPOT_PATH = find_depot_tools.add_depot_tools_to_path()
GSUTIL_PATH = os.path.join(DEPOT_PATH, 'gsutil.py')

def RunCommand(command):
  """Run command and return success (True) or failure."""

  print 'Running %s' % (str(command))
  if subprocess.call(command, shell=False) == 0:
    return True
  print 'Failed.'
  return False

def GetInstalledVersion(version_stamp):
  version_file = os.path.join(INSTALL_DIR, version_stamp)
  if not os.path.exists(version_file):
    return None
  with open(version_file) as f:
    return f.read().strip()

def VersionStampName(tools_name):
  if sys.platform.startswith('linux'):
    return 'VERSION_LINUX_' + tools_name.upper()
  elif sys.platform == 'darwin':
    return 'VERSION_MACOSX_' + tools_name.upper()
  elif sys.platform.startswith(('cygwin', 'win')):
    return 'VERSION_WIN_' + tools_name.upper()
  else:
    raise Exception('Unsupported platform: ' + sys.platform)

def UpdateTools(tools_name):
  """Downloads zipped tools from Google Cloud Storage and extracts them,
     stamping current version."""

  # Read latest version.
  version_stamp = VersionStampName(tools_name)
  version = ''
  with open(os.path.join(THIS_DIR, version_stamp)) as f:
    version = f.read().strip()
  # Return if installed binaries are up to date.
  if version == GetInstalledVersion(version_stamp):
    return True

  # Remove the old install directory checked out from git.
  if os.path.exists(os.path.join(INSTALL_DIR, '.git')):
    shutil.rmtree(INSTALL_DIR)
  # Make sure that the install directory exists.
  if not os.path.exists(INSTALL_DIR):
    os.mkdir(INSTALL_DIR)
  # Remove current installation.
  tools_root = os.path.join(INSTALL_DIR, tools_name)
  if os.path.exists(tools_root):
    shutil.rmtree(tools_root)

  # Download tools from GCS.
  archive_path = os.path.join(INSTALL_DIR, tools_name + '.tar.gz')
  download_cmd = ['python', GSUTIL_PATH, 'cp',
                  'gs://mojo/android/tool/%s.tar.gz' % version,
                  archive_path]
  if not RunCommand(download_cmd):
    print ('WARNING: Failed to download Android tools.')
    return False

  print "Extracting Android tools (" + tools_name + ")"
  with tarfile.open(archive_path) as arch:
    arch.extractall(INSTALL_DIR)
  os.remove(archive_path)
  # Write version as the last step.
  with open(os.path.join(INSTALL_DIR, version_stamp), 'w+') as f:
    f.write('%s\n' % version)
  return True

def main(argv):
  option_parser = optparse.OptionParser()
  option_parser.add_option('-t',
                           '--type',
                           help='type of the tools: sdk, ndk, or both',
                           type='string',
                           default='both')
  (options, args) = option_parser.parse_args(argv)

  if len(args) > 1:
    print 'Unknown argument: ', args[1:]
    option_parser.print_help()
    sys.exit(1)

  if not options.type in ('sdk', 'ndk', 'both'):
    option_parser.print_help()
    sys.exit(1)

  if options.type in ('sdk', 'both') and not UpdateTools('sdk'):
    print ('ERROR: Failed to download sdk.')
    sys.exit(1)

  if options.type in ('ndk', 'both') and not UpdateTools('ndk'):
    print ('ERROR: Failed to download ndk.')
    sys.exit(1)

if __name__ == '__main__':
  sys.exit(main(sys.argv))
