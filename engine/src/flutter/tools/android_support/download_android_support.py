#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import sys
import urllib2
import cStringIO
import zipfile

# Path constants. (All of these should be absolute paths.)
THIS_DIR = os.path.abspath(os.path.dirname(__file__))
FLUTTER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..', '..', '..'))
INSTALL_DIR = os.path.join(FLUTTER_DIR, 'third_party', 'android_support')

def GetInstalledVersion(version_stamp):
  version_file = os.path.join(INSTALL_DIR, version_stamp)
  if not os.path.exists(version_file):
    return None
  with open(version_file) as f:
    return f.read().strip()

def main():
  # Read latest version.
  version_stamp = 'VERSION_SUPPORT_FRAGMENT'
  version = ''
  with open(os.path.join(THIS_DIR, version_stamp)) as f:
    version = f.read().strip()
  # Return if installed binaries are up to date.
  if version == GetInstalledVersion(version_stamp):
    return

  # Download the AAR and extract the JAR.
  aar = urllib2.urlopen(version).read()
  aar_zip = zipfile.ZipFile(cStringIO.StringIO(aar))
  if not os.path.exists(INSTALL_DIR):
    os.mkdir(INSTALL_DIR)
  with open(os.path.join(INSTALL_DIR, 'android_support_fragment.jar'), 'w') as f:
    f.write(aar_zip.read('classes.jar'))

  # Write version as the last step.
  with open(os.path.join(INSTALL_DIR, version_stamp), 'w') as f:
    f.write('%s\n' % version)

if __name__ == '__main__':
  sys.exit(main())
