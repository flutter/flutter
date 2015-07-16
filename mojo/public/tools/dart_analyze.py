#!/usr/bin/python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# To integrate dartanalyze with out build system, we take an input file, run
# the analyzer on it, and write a stamp file if it passed.
#
# The first argument to this script is a reference to this build's gen
# directory, which we treat as the package root. The second is the stamp file
# to touch if we succeed. The rest are passed to the analyzer verbatim.

import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

_IGNORED_PATTERNS = [
  # Ignored because they're not indicative of specific errors.
  re.compile(r'^$'),
  re.compile(r'^Analyzing \['),
  re.compile(r'^No issues found'),
  re.compile(r'^[0-9]+ errors? and [0-9]+ warnings? found.'),
  re.compile(r'^([0-9]+|No) (error|warning|issue)s? found.'),

  # TODO: It seems like this should be re-enabled evenutally.
  re.compile(r'.*is a part and can not|^Only libraries can be analyzed'),
  # TODO: Remove this once dev SDK includes Uri.directory constructor.
  re.compile(r'.*The class \'Uri\' does not have a constructor \'directory\''),
  # TODO: Remove this once Sky no longer generates this warning.
  # dartbug.com/22836
  re.compile(r'.*cannot both be unnamed'),
]

def _success(stamp_file):
  # We passed cleanly, so touch the stamp file so that we don't run again.
  with open(stamp_file, 'a'):
    os.utime(stamp_file, None)
  return 0

def main(args):
  dartzip_file = args.pop(0)
  stamp_file = args.pop(0)

  # Do not run dart analyzer on third_party sources.
  if "/third_party/" in dartzip_file:
    return _success(stamp_file)

  dartzip_basename = os.path.basename(dartzip_file) + ":"

  # Unzip |dartzip_file| to a temporary directory.
  try:
    temp_dir = tempfile.mkdtemp()
    zipfile.ZipFile(dartzip_file).extractall(temp_dir)

    cmd = [
      "../../third_party/dart-sdk/dart-sdk/bin/dartanalyzer",
    ]

    # Grab all the toplevel dart files in the archive.
    dart_files = glob.glob(os.path.join(temp_dir, "*.dart"))

    if not dart_files:
      return _success(stamp_file)

    cmd.extend(dart_files)
    cmd.extend(args)
    cmd.append("--package-root=%s/packages" % temp_dir)
    cmd.append("--fatal-warnings")

    errors = 0
    try:
      subprocess.check_output(cmd, shell=False, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
      errors = set(l for l in e.output.split('\n')
                   if not any(p.match(l) for p in _IGNORED_PATTERNS))
      for error in sorted(errors):
        print >> sys.stderr, error.replace(temp_dir + "/", dartzip_basename)

    if not errors:
      return _success(stamp_file)
    return min(255, len(errors))
  finally:
    shutil.rmtree(temp_dir)

if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
