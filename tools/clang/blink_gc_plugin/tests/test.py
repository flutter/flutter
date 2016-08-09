#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


import argparse
import glob
import os
import subprocess
import sys


def run_test(test_base_name, cmd, reset_results):
  """Run a test case.

  Args:
    test_base_name: The name for the test C++ source file without the extension.
    cmd: The actual command to run for the test.
    reset_results: True if the results should be overwritten in place.

  Returns:
    None on pass, or a str with the description of the failure.
  """
  try:
    actual = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  except subprocess.CalledProcessError as e:
    # Some of the Blink GC plugin tests intentionally trigger compile errors, so
    # just ignore an exit code that indicates failure.
    actual = e.output
  except Exception as e:
    return 'could not execute %s (%s)' % (cmd, e)

  # Some Blink GC plugins dump a JSON representation of the object graph, and
  # use the processed results as the actual results of the test.
  if os.path.exists('%s.graph.json' % test_base_name):
    try:
      actual = subprocess.check_output(
          ['python', '../process-graph.py', '-c',
           '%s.graph.json' % test_base_name],
          stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError, e:
      # The graph processing script returns a failure exit code if the graph is
      # 'bad' (e.g. it has a cycle). The output still needs to be captured in
      # that case, since the expected results capture the errors.
      actual = e.output
    finally:
      # Clean up the .graph.json file to prevent false passes from stale results
      # from a previous run.
      os.remove('%s.graph.json' % test_base_name)

  # On Windows, clang emits CRLF as the end of line marker. Normalize it to LF
  # to match posix systems.
  actual = actual.replace('\r\n', '\n')

  result_file = '%s.txt%s' % (
      test_base_name, '' if reset_results else '.actual')
  try:
    expected = open('%s.txt' % test_base_name).read()
  except IOError:
    open(result_file, 'w').write(actual)
    return 'no expected file found'

  if expected != actual:
    open(result_file, 'w').write(actual)
    error = 'expected and actual differed\n'
    error += 'Actual:\n' + actual
    error += 'Expected:\n' + expected
    return error


def run_tests(clang_path, plugin_path, reset_results):
  """Runs the tests.

  Args:
    clang_path: The path to the clang binary to be tested.
    plugin_path: An optional path to the plugin to test. This may be None, if
                 plugin is built directly into clang, like on Windows.
    reset_results: True if the results should be overwritten in place.

  Returns:
    (passing, failing): Two lists containing the base names of the passing and
                        failing tests respectively.
  """
  passing = []
  failing = []

  # The plugin option to dump the object graph is incompatible with
  # -fsyntax-only. It generates the .graph.json file based on the name of the
  # output file, but there is no output filename with -fsyntax-only.
  base_cmd = [clang_path, '-c', '-std=c++11']
  base_cmd.extend(['-Wno-inaccessible-base'])
  if plugin_path:
    base_cmd.extend(['-Xclang', '-load', '-Xclang', plugin_path])
  base_cmd.extend(['-Xclang', '-add-plugin', '-Xclang', 'blink-gc-plugin'])

  tests = glob.glob('*.cpp')
  for test in tests:
    sys.stdout.write('Testing %s... ' % test)
    test_base_name, _ = os.path.splitext(test)

    cmd = base_cmd[:]
    try:
      cmd.extend(file('%s.flags' % test_base_name).read().split())
    except IOError:
      pass
    cmd.append(test)

    failure_message = run_test(test_base_name, cmd, reset_results)
    if failure_message:
      print 'failed: %s' % failure_message
      failing.append(test_base_name)
    else:
      print 'passed!'
      passing.append(test_base_name)

  return passing, failing


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument(
      '--reset-results', action='store_true',
      help='If specified, overwrites the expected results in place.')
  parser.add_argument('clang_path', help='The path to the clang binary.')
  parser.add_argument('plugin_path', nargs='?',
                      help='The path to the plugin library, if any.')
  args = parser.parse_args()

  os.chdir(os.path.dirname(os.path.realpath(__file__)))

  print 'Using clang %s...' % args.clang_path
  print 'Using plugin %s...' % args.plugin_path

  passing, failing = run_tests(args.clang_path,
                               args.plugin_path,
                               args.reset_results)
  print 'Ran %d tests: %d succeeded, %d failed' % (
      len(passing) + len(failing), len(passing), len(failing))
  for test in failing:
    print '    %s' % test
  return len(failing)


if __name__ == '__main__':
  sys.exit(main())
