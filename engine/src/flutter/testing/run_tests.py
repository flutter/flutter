#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
A top level harness to run all unit-tests in a specific engine build.
"""

import sys
import os
import argparse
import glob
import subprocess

buildroot_dir = os.path.abspath(os.path.join(os.path.realpath(__file__), '..', '..', '..'))
out_dir = os.path.join(buildroot_dir, 'out')
fonts_dir = os.path.join(buildroot_dir, 'flutter', 'third_party', 'txt', 'third_party', 'fonts')
dart_tests_dir = os.path.join(buildroot_dir, 'flutter', 'testing', 'dart',)

fonts_dir_flag = '--font-directory=%s' % fonts_dir
time_sensitve_test_flag = '--gtest_filter="-*TimeSensitiveTest*"'

def IsMac():
  sys.platform == 'darwin'


def IsLinux():
  sys.platform.startswith('linux')


def IsWindows():
  sys.platform.startswith(('cygwin', 'win'))


def RunEngineExecutable(build_dir, executable_name, filter, flags=[], cwd=buildroot_dir):
  if not filter in executable_name:
    print 'Skipping %s due to filter.' % executable_name
    return

  print 'Running %s in %s' % (executable_name, cwd)
  
  executable = os.path.join(build_dir, executable_name)
  assert os.path.exists(executable), '%s does not exist!' % executable
  
  test_command = [ executable ] + flags
  print ' '.join(test_command)
  
  subprocess.check_call(test_command, cwd=cwd)


def RunCCTests(build_dir, filter):
  print "Running Engine Unit-tests."    

  RunEngineExecutable(build_dir, 'client_wrapper_glfw_unittests', filter)

  RunEngineExecutable(build_dir, 'client_wrapper_unittests', filter)

  RunEngineExecutable(build_dir, 'embedder_unittests', filter)

  RunEngineExecutable(build_dir, 'flow_unittests', filter)

  RunEngineExecutable(build_dir, 'fml_unittests', filter, [ time_sensitve_test_flag ])

  RunEngineExecutable(build_dir, 'runtime_unittests', filter)

  RunEngineExecutable(build_dir, 'shell_unittests', filter)

  RunEngineExecutable(build_dir, 'ui_unittests', filter)

  if IsMac():
    RunEngineExecutable(build_dir, 'flutter_channels_unittests', filter)

  if IsLinux():
    RunEngineExecutable(build_dir, 'txt_unittests', filter, [ fonts_dir_flag ])


def RunEngineBenchmarks(build_dir, filter):
  print "Running Engine Benchmarks."

  RunEngineExecutable(build_dir, 'shell_benchmarks', filter)
  
  RunEngineExecutable(build_dir, 'fml_benchmarks', filter)

  if IsLinux():
    RunEngineExecutable(build_dir, 'txt_benchmarks', filter, [ fonts_dir_flag ])



def SnapshotTest(build_dir, dart_file, kernel_file_output):
  print "Generating snapshot for test %s" % dart_file

  dart = os.path.join(build_dir, 'dart-sdk', 'bin', 'dart')
  frontend_server = os.path.join(build_dir, 'gen', 'frontend_server.dart.snapshot')
  flutter_patched_sdk = os.path.join(build_dir, 'flutter_patched_sdk')
  test_packages = os.path.join(dart_tests_dir, '.packages')

  assert os.path.exists(dart)
  assert os.path.exists(frontend_server)
  assert os.path.exists(flutter_patched_sdk)
  assert os.path.exists(test_packages)
  
  snapshot_command = [
    dart,
    frontend_server,
    '--sdk-root',
    flutter_patched_sdk,
    '--incremental',
    '--strong',
    '--target=flutter',
    '--packages',
    test_packages,
    '--output-dill',
    kernel_file_output,
    dart_file
  ]
  
  subprocess.check_call(snapshot_command, cwd=buildroot_dir)
  assert os.path.exists(kernel_file_output)


def RunDartTest(build_dir, dart_file, filter):
  kernel_file_name = os.path.basename(dart_file) + '.kernel.dill'
  kernel_file_output = os.path.join(out_dir, kernel_file_name)
  
  SnapshotTest(build_dir, dart_file, kernel_file_output)

  print "Running test '%s' using 'flutter_tester'" % kernel_file_name
  RunEngineExecutable(build_dir, 'flutter_tester', filter, [
    '--disable-observatory',
    '--use-test-fonts',
    kernel_file_output
  ])

def RunPubGet(build_dir, directory):
  print "Running 'pub get' in the tests directory %s" % dart_tests_dir

  pub_get_command = [
    os.path.join(build_dir, 'dart-sdk', 'bin', 'pub'),
    'get'
  ]
  subprocess.check_call(pub_get_command, cwd=directory)


def EnsureDebugUnoptSkyPackagesAreBuilt():
  variant_out_dir = os.path.join(out_dir, 'host_debug_unopt')

  ninja_command = [
    'autoninja',
    '-C',
    variant_out_dir,
    'flutter/sky/packages'
  ]

  # Attempt running Ninja if the out directory exists.
  # We don't want to blow away any custom GN args the caller may have already set.
  if os.path.exists(variant_out_dir):
    subprocess.check_call(ninja_command, cwd=buildroot_dir)
    return

  gn_command = [
    os.path.join(buildroot_dir, 'flutter', 'tools', 'gn'),
    '--runtime-mode',
    'debug',
    '--unopt',
    '--no-lto',
  ]
  
  subprocess.check_call(gn_command, cwd=buildroot_dir)
  subprocess.check_call(ninja_command, cwd=buildroot_dir)

def RunDartTests(build_dir, filter):
  # This one is a bit messy. The pubspec.yaml at flutter/testing/dart/pubspec.yaml
  # has dependencies that are hardcoded to point to the sky packages at host_debug_unopt/
  # Before running Dart tests, make sure to run just that target (NOT the whole engine)
  EnsureDebugUnoptSkyPackagesAreBuilt();

  # Now that we have the Sky packages at the hardcoded location, run `pub get`.
  RunPubGet(build_dir, dart_tests_dir)

  dart_tests = glob.glob('%s/*.dart' % dart_tests_dir)

  for dart_test_file in dart_tests:
    if filter in os.path.basename(dart_test_file):
      print "Testing dart file %s" % dart_test_file
      RunDartTest(build_dir, dart_test_file, filter)
    else:
      print "Skipping %s due to filter." % dart_test_file


def RunTests(build_dir, filter, run_engine_tests, run_dart_tests, run_benchmarks):
  if run_engine_tests:
    RunCCTests(build_dir, filter)

  if run_dart_tests:
    RunDartTests(build_dir, filter)

  if run_benchmarks:
    RunEngineBenchmarks(build_dir, filter)


def main():
  parser = argparse.ArgumentParser();

  parser.add_argument('--variant', dest='variant', action='store', 
      default='host_debug_unopt', help='The engine build variant to run the tests for.');
  parser.add_argument('--type', type=str, choices=['all', 'engine', 'dart', 'benchmarks'], default='all')
  parser.add_argument('--filter', type=str, default='',
      help='The file name filter to use to select specific tests to run.')

  args = parser.parse_args()
  
  run_engine_tests = args.type in ['engine', 'all']
  run_dart_tests = args.type in ['dart', 'all']
  run_benchmarks = args.type in ['benchmarks', 'all']

  build_dir = os.path.join(out_dir, args.variant)
  assert os.path.exists(build_dir), 'Build variant directory %s does not exist!' % build_dir
  RunTests(build_dir, args.filter, run_engine_tests, run_dart_tests, run_benchmarks)


if __name__ == '__main__':
  sys.exit(main())
