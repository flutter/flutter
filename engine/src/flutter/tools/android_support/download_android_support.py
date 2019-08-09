#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import sys
import urllib2
import cStringIO
import zipfile
import json

# Path constants. (All of these should be absolute paths.)
THIS_DIR = os.path.abspath(os.path.dirname(__file__))
FLUTTER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..', '..', '..'))
INSTALL_DIR = os.path.join(FLUTTER_DIR, 'third_party', 'android_support')

def GetInstalledVersion(out_file_name):
  version_file = os.path.join(INSTALL_DIR, out_file_name + '.stamp')
  if not os.path.exists(version_file):
    return None
  with open(version_file) as f:
    return f.read().strip()

def getFile(url, out_file_name):
  # Read latest version.
  if url == GetInstalledVersion(out_file_name):
    return

  downloaded_file = urllib2.urlopen(url).read()
  if not os.path.exists(INSTALL_DIR):
      os.mkdir(INSTALL_DIR)

  if (url.endswith('.aar')):
    aar_zip = zipfile.ZipFile(cStringIO.StringIO(downloaded_file))
    with open(os.path.join(INSTALL_DIR, out_file_name), 'w') as f:
      f.write(aar_zip.read('classes.jar'))
  else:
    with open(os.path.join(INSTALL_DIR, out_file_name), 'w') as f:
      f.write(downloaded_file)

  # Write version as the last step.
  with open(os.path.join(INSTALL_DIR, out_file_name + '.stamp'), 'w') as f:
    f.write('%s\n' % url)


def main():
  with open (os.path.join(THIS_DIR, 'files.json')) as f:
    files = json.load(f)

  for entry in files:
    getFile(entry['url'], entry['out_file_name'])

if __name__ == '__main__':
  sys.exit(main())
