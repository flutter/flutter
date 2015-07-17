#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Creates a TOC file from a Java jar.

The TOC file contains the non-package API of the jar. This includes all
public/protected/package classes/functions/members and the values of static
final variables (members with package access are kept because in some cases we
have multiple libraries with the same package, particularly test+non-test). Some
other information (major/minor javac version) is also included.

This TOC file then can be used to determine if a dependent library should be
rebuilt when this jar changes. I.e. any change to the jar that would require a
rebuild, will have a corresponding change in the TOC file.
"""

import optparse
import os
import re
import sys
import zipfile

from util import build_utils
from util import md5_check


def GetClassesInZipFile(zip_file):
  classes = []
  files = zip_file.namelist()
  for f in files:
    if f.endswith('.class'):
      # f is of the form org/chromium/base/Class$Inner.class
      classes.append(f.replace('/', '.')[:-6])
  return classes


def CallJavap(classpath, classes):
  javap_cmd = [
      'javap',
      '-package',  # Show public/protected/package.
      # -verbose is required to get constant values (which can be inlined in
      # dependents).
      '-verbose',
      '-J-XX:NewSize=4m',
      '-classpath', classpath
      ] + classes
  return build_utils.CheckOutput(javap_cmd)


def ExtractToc(disassembled_classes):
  # javap output is structured by indent (2-space) levels.
  good_patterns = [
      '^[^ ]', # This includes all class/function/member signatures.
      '^  SourceFile:',
      '^  minor version:',
      '^  major version:',
      '^  Constant value:',
      ]
  bad_patterns = [
      '^const #', # Matches the constant pool (i.e. literals used in the class).
    ]

  def JavapFilter(line):
    return (re.match('|'.join(good_patterns), line) and
        not re.match('|'.join(bad_patterns), line))
  toc = filter(JavapFilter, disassembled_classes.split('\n'))

  return '\n'.join(toc)


def UpdateToc(jar_path, toc_path):
  classes = GetClassesInZipFile(zipfile.ZipFile(jar_path))
  toc = ''
  if len(classes) != 0:
    javap_output = CallJavap(classpath=jar_path, classes=classes)
    toc = ExtractToc(javap_output)

  with open(toc_path, 'w') as tocfile:
    tocfile.write(toc)


def DoJarToc(options):
  jar_path = options.jar_path
  toc_path = options.toc_path
  record_path = '%s.md5.stamp' % toc_path
  md5_check.CallAndRecordIfStale(
      lambda: UpdateToc(jar_path, toc_path),
      record_path=record_path,
      input_paths=[jar_path],
      force=not os.path.exists(toc_path),
      )
  build_utils.Touch(toc_path, fail_if_missing=True)


def main():
  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)

  parser.add_option('--jar-path', help='Input .jar path.')
  parser.add_option('--toc-path', help='Output .jar.TOC path.')
  parser.add_option('--stamp', help='Path to touch on success.')

  options, _ = parser.parse_args()

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        build_utils.GetPythonDependencies())

  DoJarToc(options)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        build_utils.GetPythonDependencies())

  if options.stamp:
    build_utils.Touch(options.stamp)


if __name__ == '__main__':
  sys.exit(main())
