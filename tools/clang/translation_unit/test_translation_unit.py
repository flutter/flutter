#!/usr/bin/env python
# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Test for TranslationUnitGenerator tool."""

import difflib
import glob
import json
import ntpath
import os
import os.path
import subprocess
import sys


def _GenerateCompileCommands(files):
  """Returns a JSON string containing a compilation database for the input."""
  return json.dumps([{'directory': '.',
                      'command': 'clang++ -fsyntax-only -std=c++11 -c %s' % f,
                      'file': f} for f in files], indent=2)


def _NumberOfTestsToString(tests):
  """Returns an English sentence describing the number of tests."""
  return "%d test%s" % (tests, 's' if tests != 1 else '')


# Before running this test script, please build the translation_unit clang tool
# first. This is explained here:
# https://code.google.com/p/chromium/wiki/ClangToolRefactoring
def main():
  tools_clang_directory = os.path.dirname(os.path.dirname(
      os.path.realpath(__file__)))
  tools_clang_scripts_directory = os.path.join(tools_clang_directory, 'scripts')
  test_directory_for_tool = os.path.join(
      tools_clang_directory, 'translation_unit', 'test_files')
  compile_database = os.path.join(test_directory_for_tool,
                                  'compile_commands.json')
  source_files = glob.glob(os.path.join(test_directory_for_tool, '*.cc'))

  # Generate a temporary compilation database to run the tool over.
  with open(compile_database, 'w') as f:
    f.write(_GenerateCompileCommands(source_files))

  args = ['python',
          os.path.join(tools_clang_scripts_directory, 'run_tool.py'),
          'translation_unit',
          test_directory_for_tool]
  args.extend(source_files)
  run_tool = subprocess.Popen(args, stdout=subprocess.PIPE)
  stdout, _ = run_tool.communicate()
  if run_tool.returncode != 0:
    print 'run_tool failed:\n%s' % stdout
    sys.exit(1)

  passed = 0
  failed = 0
  for actual in source_files:
    actual += '.filepaths'
    expected = actual + '.expected'
    print '[ RUN      ] %s' % os.path.relpath(actual)
    expected_output = actual_output = None
    with open(expected, 'r') as f:
      expected_output = f.readlines()
    with open(actual, 'r') as f:
      actual_output = f.readlines()
    has_same_filepaths = True
    for expected_line, actual_line in zip(expected_output, actual_output):
      if '//' in actual_output:
        if actual_output.split('//')[1] != expected_output:
          sys.stdout.write('expected: %s' % expected_output)
          sys.stdout.write('actual: %s' % actual_output.split('//')[1])
          break
        else:
          continue
      if ntpath.basename(expected_line) != ntpath.basename(actual_line):
        sys.stdout.write('expected: %s' % ntpath.basename(expected_line))
        sys.stdout.write('actual: %s' % ntpath.basename(actual_line))
        has_same_filepaths = False
        break
    if not has_same_filepaths:
      failed += 1
      for line in difflib.unified_diff(expected_output, actual_output,
                                       fromfile=os.path.relpath(expected),
                                       tofile=os.path.relpath(actual)):
        sys.stdout.write(line)
      print '[  FAILED  ] %s' % os.path.relpath(actual)
      # Don't clean up the file on failure, so the results can be referenced
      # more easily.
      continue
    print '[       OK ] %s' % os.path.relpath(actual)
    passed += 1
    os.remove(actual)

  if failed == 0:
    os.remove(compile_database)

  print '[==========] %s ran.' % _NumberOfTestsToString(len(source_files))
  if passed > 0:
    print '[  PASSED  ] %s.' % _NumberOfTestsToString(passed)
  if failed > 0:
    print '[  FAILED  ] %s.' % _NumberOfTestsToString(failed)


if __name__ == '__main__':
  sys.exit(main())
