#!/usr/bin/python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Downloads Go binaries from Google Cloud Storage and extracts them to
INSTALL_DIR, updating INSTALL_DIR/VERSION stamp file with current version.
Does nothing if INSTALL_DIR/VERSION is already up to date.
"""

import os
import shutil
import subprocess
import sys
import tarfile

# Path constants. (All of these should be absolute paths.)
THIS_DIR = os.path.abspath(os.path.dirname(__file__))
MOJO_DIR = os.path.abspath(os.path.join(THIS_DIR, '..', '..'))
# Should be the same as in upload.py.
INSTALL_DIR = os.path.join(MOJO_DIR, 'third_party', 'go', 'tool')

sys.path.insert(0, os.path.join(MOJO_DIR, 'tools'))
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

def VersionFileName():
  if sys.platform.startswith('linux'):
    platform_suffix = 'LINUX'
  elif sys.platform == 'darwin':
    platform_suffix = 'MACOSX'
  else:
    raise Exception('unsupported platform: ' + sys.platform)
  return 'VERSION_' + platform_suffix

def GetInstalledVersion():
  version_file = os.path.join(INSTALL_DIR, VersionFileName())
  if not os.path.exists(version_file):
    return None
  with open(version_file) as f:
    return f.read().strip()

def InstallGoBinaries(version):
  """Downloads zipped go binaries from Google Cloud Storage and extracts them,
     stamping current version."""

  # Remove current installation.
  if os.path.exists(INSTALL_DIR):
    shutil.rmtree(INSTALL_DIR)
  os.mkdir(INSTALL_DIR)
  # Download go tool binaries from GCS.
  archive_path = os.path.join(INSTALL_DIR, 'go.tar.gz')
  download_cmd = ['python', GSUTIL_PATH, '-b', 'cp',
                  'gs://mojo/go/tool/%s.tar.gz' % version,
                  archive_path]
  if not RunCommand(download_cmd):
    print ('WARNING: Failed to download Go tool binaries.')
    return

  print "Extracting Go binaries."
  with tarfile.open(archive_path) as arch:
    arch.extractall(INSTALL_DIR)
  os.remove(archive_path)
  # Write version as the last step.
  with open(os.path.join(INSTALL_DIR, VersionFileName()), 'w+') as f:
    f.write('%s\n' % version)

def main():
  # Read latest version.
  version = ''
  with open(os.path.join(THIS_DIR, VersionFileName())) as f:
    version = f.read().strip()
  # Return if installed binaries are up to date.
  if version == GetInstalledVersion():
    return
  InstallGoBinaries(version)

if __name__ == '__main__':
  sys.exit(main())
