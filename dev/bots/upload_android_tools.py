#!/usr/bin/python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
This script takes an Android Tools tree, creates a tar.gz archive and
uploads it to Google Cloud Storage at gs://mojo/android/tool. It also produces
the VERSION stamp files with the sha1 code of the uploaded archive.

This script operates in the INSTALL_DIR directory, so it automatically updates
your current installation of the android tools binaries on success. On failure
it invalidates your current installation; to fix it, run
run download_android_tools.py.
"""

import hashlib
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

def RunCommand(command, env=None):
  """Run command and return success (True) or failure."""

  print 'Running %s' % (str(command))
  if subprocess.call(command, shell=False, env=env) == 0:
    return True
  print 'Failed.'
  return False

def VersionStampName(tools_name):
  if sys.platform.startswith('linux'):
    return 'VERSION_LINUX_' + tools_name.upper()
  elif sys.platform == 'darwin':
    return 'VERSION_MACOSX_' + tools_name.upper()
  elif sys.platform.startswith(('cygwin', 'win')):
    return 'VERSION_WIN_' + tools_name.upper()
  else:
    raise Exception('Unsupported platform: ' + sys.platform)

def CheckInstallDir(tools_name):
  """Check if the tools directory exists."""

  tools_dir = os.path.join(INSTALL_DIR, tools_name)
  if not os.path.exists(tools_dir):
    print tools_dir + ' does not exists'
    sys.exit(1)
  # Remove the existing version stamp.
  version_stamp = VersionStampName(tools_name)
  stamp_file = os.path.join(INSTALL_DIR, version_stamp)
  if os.path.exists(stamp_file):
    os.remove(stamp_file)

def Compress(tools_name):
  """Compresses the tools into tar.gz and generates sha1 code, renames the
     archive to sha1.tar.gz and returns the sha1 code."""

  print "Compressing tools, this may take several minutes."
  os.chdir(INSTALL_DIR)
  archive_name = tools_name + '.tar.gz'
  with tarfile.open(os.path.join(archive_name), 'w|gz') as tools:
    tools.add(tools_name)

  sha1 = ''
  with open(os.path.join(INSTALL_DIR, archive_name)) as f:
    sha1 = hashlib.sha1(f.read()).hexdigest()
  os.rename(os.path.join(INSTALL_DIR, archive_name),
            os.path.join(INSTALL_DIR, '%s.tar.gz' % sha1))
  return sha1

def Upload(tools_name, sha1):
  """Uploads INSTALL_DIR/sha1.tar.gz to Google Cloud Storage under
     gs://mojo/android/tool and writes sha1 to THIS_DIR/VERSION_*."""

  file_name = '%s.tar.gz' % sha1
  upload_cmd = ['python', GSUTIL_PATH, 'cp',
                '-n', # Do not upload if the file already exists.
                os.path.join(INSTALL_DIR, file_name),
                'gs://mojo/android/tool/%s' % file_name]

  print "Uploading ' + tools_name + ' tools to GCS."
  if not RunCommand(upload_cmd):
    print "Failed to upload android tool to GCS."
    sys.exit(1)
  os.remove(os.path.join(INSTALL_DIR, file_name))
  # Write versions as the last step.
  version_stamp = VersionStampName(tools_name)
  stamp_file = os.path.join(THIS_DIR, version_stamp)
  with open(stamp_file, 'w+') as stamp:
    stamp.write('%s\n' % sha1)

  stamp_file = os.path.join(INSTALL_DIR, version_stamp)
  with open(stamp_file, 'w+') as stamp:
    stamp.write('%s\n' % sha1)

def main(argv):
  option_parser = optparse.OptionParser()
  option_parser.add_option('-t',
                           '--type',
                           help='type of the tools: sdk or ndk',
                           type='string')
  (options, args) = option_parser.parse_args(argv)

  if len(args) > 1:
    print 'Unknown argument: ', args[1:]
    option_parser.print_help()
    sys.exit(1)

  if not options.type in {'sdk', 'ndk'}:
    option_parser.print_help()
    sys.exit(1)

  CheckInstallDir(options.type)
  sha1 = Compress(options.type)
  Upload(options.type, sha1)
  print "Done."

if __name__ == '__main__':
  sys.exit(main(sys.argv))
