#!/usr/bin/env python
#
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is used to test the findbugs plugin, it calls
# build/android/pylib/utils/findbugs.py to analyze the classes in
# org.chromium.tools.findbugs.plugin package, and expects to get the same
# issue with those in expected_result.txt.
#
# Useful command line:
# --rebaseline to generate the expected_result.txt, please make sure don't
# remove the expected result of exsting tests.


import argparse
import os
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__),
                                             '..', '..', '..', '..',
                                             'build', 'android')))

from pylib import constants
from pylib.utils import findbugs


_EXPECTED_WARNINGS = set([
    findbugs.FindBugsWarning(
        bug_type='CHROMIUM_SYNCHRONIZED_THIS',
        start_line=15,
        end_line=15,
        file_name='SimpleSynchronizedThis.java',
        message=(
            "Shouldn't use synchronized(this)",
            'In class org.chromium.tools.findbugs.plugin.'
                + 'SimpleSynchronizedThis',
            'In method org.chromium.tools.findbugs.plugin.'
                + 'SimpleSynchronizedThis.synchronizedThis()',
            'At SimpleSynchronizedThis.java:[line 15]',
        )),
    findbugs.FindBugsWarning(
        bug_type='CHROMIUM_SYNCHRONIZED_METHOD',
        start_line=14,
        end_line=14,
        file_name='SimpleSynchronizedStaticMethod.java',
        message=(
            "Shouldn't use synchronized method",
            'In class org.chromium.tools.findbugs.plugin.'
                + 'SimpleSynchronizedStaticMethod',
            'In method org.chromium.tools.findbugs.plugin.'
                + 'SimpleSynchronizedStaticMethod.synchronizedStaticMethod()',
            'At SimpleSynchronizedStaticMethod.java:[line 14]',
        )),
    findbugs.FindBugsWarning(
        bug_type='CHROMIUM_SYNCHRONIZED_METHOD',
        start_line=15,
        end_line=15,
        file_name='SimpleSynchronizedMethod.java',
        message=(
            "Shouldn't use synchronized method",
            'In class org.chromium.tools.findbugs.plugin.'
                + 'SimpleSynchronizedMethod',
            'In method org.chromium.tools.findbugs.plugin.'
                + 'SimpleSynchronizedMethod.synchronizedMethod()',
            'At SimpleSynchronizedMethod.java:[line 15]',
        )),
])


def main(argv):

  parser = argparse.ArgumentParser()
  parser.add_argument(
      '-l', '--release-build', action='store_true', dest='release',
      help='Run the release build of the findbugs plugin test.')
  args = parser.parse_args()

  test_jar_path = os.path.join(
      constants.GetOutDirectory(
          'Release' if args.release else 'Debug'),
      'lib.java', 'findbugs_plugin_test.jar')

  findbugs_command, findbugs_warnings = findbugs.Run(
      None, 'org.chromium.tools.findbugs.plugin.*', None, None, None,
      [test_jar_path])

  missing_warnings = _EXPECTED_WARNINGS.difference(findbugs_warnings)
  if missing_warnings:
    print 'Missing warnings:'
    for w in missing_warnings:
      print '%s' % str(w)

  unexpected_warnings = findbugs_warnings.difference(_EXPECTED_WARNINGS)
  if unexpected_warnings:
    print 'Unexpected warnings:'
    for w in unexpected_warnings:
      print '%s' % str(w)

  return len(unexpected_warnings) + len(missing_warnings)

if __name__ == '__main__':
  sys.exit(main(sys.argv))
