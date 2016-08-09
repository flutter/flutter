#!/usr/bin/env python
#
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Creates an AndroidManifest.xml for an APK split.

Given the manifest file for the main APK, generates an AndroidManifest.xml with
the value required for a Split APK (package, versionCode, etc).
"""

import optparse
import xml.etree.ElementTree

from util import build_utils

MANIFEST_TEMPLATE = """<?xml version="1.0" encoding="utf-8"?>
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android"
    package="%(package)s"
    split="%(split)s">
  <uses-sdk android:minSdkVersion="21" />
  <application android:hasCode="%(has_code)s">
  </application>
</manifest>
"""

def ParseArgs():
  """Parses command line options.

  Returns:
    An options object as from optparse.OptionsParser.parse_args()
  """
  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)
  parser.add_option('--main-manifest', help='The main manifest of the app')
  parser.add_option('--out-manifest', help='The output manifest')
  parser.add_option('--split', help='The name of the split')
  parser.add_option(
      '--has-code',
      action='store_true',
      default=False,
      help='Whether the split will contain a .dex file')

  (options, args) = parser.parse_args()

  if args:
    parser.error('No positional arguments should be given.')

  # Check that required options have been provided.
  required_options = ('main_manifest', 'out_manifest', 'split')
  build_utils.CheckOptions(options, parser, required=required_options)

  return options


def Build(main_manifest, split, has_code):
  """Builds a split manifest based on the manifest of the main APK.

  Args:
    main_manifest: the XML manifest of the main APK as a string
    split: the name of the split as a string
    has_code: whether this split APK will contain .dex files

  Returns:
    The XML split manifest as a string
  """

  doc = xml.etree.ElementTree.fromstring(main_manifest)
  package = doc.get('package')

  return MANIFEST_TEMPLATE % {
      'package': package,
      'split': split.replace('-', '_'),
      'has_code': str(has_code).lower()
  }


def main():
  options = ParseArgs()
  main_manifest = file(options.main_manifest).read()
  split_manifest = Build(
      main_manifest,
      options.split,
      options.has_code)

  with file(options.out_manifest, 'w') as f:
    f.write(split_manifest)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        [options.main_manifest] + build_utils.GetPythonDependencies())


if __name__ == '__main__':
  main()
