#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
A top level harness to run all unit-tests in a specific engine build.
"""

import argparse
import glob
import os
import re
import subprocess
import sys

buildroot_dir = os.path.abspath(os.path.join(os.path.realpath(__file__), '..', '..', '..'))
out_dir = os.path.join(buildroot_dir, 'out')
golden_dir = os.path.join(buildroot_dir, 'flutter', 'testing', 'resources')
fonts_dir = os.path.join(buildroot_dir, 'flutter', 'third_party', 'txt', 'third_party', 'fonts')
roboto_font_path = os.path.join(fonts_dir, 'Roboto-Regular.ttf')
dart_tests_dir = os.path.join(buildroot_dir, 'flutter', 'testing', 'dart',)

fonts_dir_flag = '--font-directory=%s' % fonts_dir
time_sensitve_test_flag = '--gtest_filter="-*TimeSensitiveTest*"'

def IsMac():
  return sys.platform == 'darwin'


def IsLinux():
  return sys.platform.startswith('linux')


def IsWindows():
  return sys.platform.startswith(('cygwin', 'win'))


def ExecutableSuffix():
  return '.exe' if IsWindows() else ''

def FindExecutablePath(path):
  if os.path.exists(path):
    return path

  if IsWindows():
    exe_path = path + '.exe'
    if os.path.exists(exe_path):
      return exe_path

    bat_path = path + '.bat'
    if os.path.exists(bat_path):
      return bat_path

  raise Exception('Executable %s does not exist!' % path)


def RunEngineExecutable(build_dir, executable_name, filter, flags=[], cwd=buildroot_dir):
  if filter is not None and executable_name not in filter:
    print 'Skipping %s due to filter.' % executable_name
    return

  executable = FindExecutablePath(os.path.join(build_dir, executable_name))

  print 'Running %s in %s' % (executable_name, cwd)
  test_command = [ executable ] + flags
  print ' '.join(test_command)
  subprocess.check_call(test_command, cwd=cwd)


def RunCCTests(build_dir, filter):
  print "Running Engine Unit-tests."

  RunEngineExecutable(build_dir, 'client_wrapper_glfw_unittests', filter)

  RunEngineExecutable(build_dir, 'client_wrapper_unittests', filter)

  # https://github.com/flutter/flutter/issues/36294
  if not IsWindows():
    RunEngineExecutable(build_dir, 'embedder_unittests', filter)

  flow_flags = ['--gtest_filter=-PerformanceOverlayLayer.Gold']
  if IsLinux():
    flow_flags = [
      '--golden-dir=%s' % golden_dir,
      '--font-file=%s' % roboto_font_path,
    ]
  RunEngineExecutable(build_dir, 'flow_unittests', filter, flow_flags)

  RunEngineExecutable(build_dir, 'fml_unittests', filter, [ time_sensitve_test_flag ])

  RunEngineExecutable(build_dir, 'runtime_unittests', filter)

  # https://github.com/flutter/flutter/issues/36295
  if not IsWindows():
    RunEngineExecutable(build_dir, 'shell_unittests', filter)

  RunEngineExecutable(build_dir, 'ui_unittests', filter)

  # These unit-tests are Objective-C and can only run on Darwin.
  if IsMac():
    RunEngineExecutable(build_dir, 'flutter_channels_unittests', filter)

  # https://github.com/flutter/flutter/issues/36296
  if IsLinux():
    RunEngineExecutable(build_dir, 'txt_unittests', filter, [ fonts_dir_flag ])


def RunEngineBenchmarks(build_dir, filter):
  print "Running Engine Benchmarks."

  RunEngineExecutable(build_dir, 'shell_benchmarks', filter)

  RunEngineExecutable(build_dir, 'fml_benchmarks', filter)

  if IsLinux():
    RunEngineExecutable(build_dir, 'txt_benchmarks', filter, [ fonts_dir_flag ])



def SnapshotTest(build_dir, dart_file, kernel_file_output, verbose_dart_snapshot):
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

  if verbose_dart_snapshot:
    subprocess.check_call(snapshot_command, cwd=buildroot_dir)
  else:
    with open(os.devnull,"w") as out_file:
      subprocess.check_call(snapshot_command, cwd=buildroot_dir, stdout=out_file)
  assert os.path.exists(kernel_file_output)


def RunDartTest(build_dir, dart_file, verbose_dart_snapshot):
  kernel_file_name = os.path.basename(dart_file) + '.kernel.dill'
  kernel_file_output = os.path.join(out_dir, kernel_file_name)

  SnapshotTest(build_dir, dart_file, kernel_file_output, verbose_dart_snapshot)

  print "Running test '%s' using 'flutter_tester'" % kernel_file_name
  RunEngineExecutable(build_dir, 'flutter_tester', None, [
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

def EnsureJavaTestsAreBuilt(android_out_dir):
  ninja_command = [
    'autoninja',
    '-C',
    android_out_dir,
    'flutter/shell/platform/android:robolectric_tests'
  ]

  # Attempt running Ninja if the out directory exists.
  # We don't want to blow away any custom GN args the caller may have already set.
  if os.path.exists(android_out_dir):
    subprocess.check_call(ninja_command, cwd=buildroot_dir)
    return

  # Otherwise prepare the directory first, then build the test.
  gn_command = [
    os.path.join(buildroot_dir, 'flutter', 'tools', 'gn'),
    '--android',
    '--unoptimized',
    '--runtime-mode=debug',
    '--no-lto',
  ]
  subprocess.check_call(gn_command, cwd=buildroot_dir)
  subprocess.check_call(ninja_command, cwd=buildroot_dir)

def AssertExpectedJavaVersion():
  EXPECTED_VERSION = '1.8'
  # `java -version` is output to stderr. https://bugs.java.com/bugdatabase/view_bug.do?bug_id=4380614
  version_output = subprocess.check_output(['java', '-version'], stderr=subprocess.STDOUT)
  match = bool(re.compile('version "%s' % EXPECTED_VERSION).search(version_output))
  message = "JUnit tests need to be run with Java %s. Check the `java -version` on your PATH." % EXPECTED_VERSION
  assert match, message

def RunJavaTests(filter, android_variant='android_debug_unopt'):
  AssertExpectedJavaVersion()
  android_out_dir = os.path.join(out_dir, android_variant)
  EnsureJavaTestsAreBuilt(android_out_dir)

  robolectric_dir = os.path.join(buildroot_dir, 'third_party', 'robolectric', 'lib')
  classpath = map(str, [
    os.path.join(buildroot_dir, 'third_party', 'android_tools', 'sdk', 'platforms', 'android-29', 'android.jar'),
    os.path.join(robolectric_dir, '*'), # Wildcard for all jars in the directory
    os.path.join(android_out_dir, 'flutter.jar'),
    os.path.join(android_out_dir, 'robolectric_tests.jar')
  ])

  test_class = filter if filter else 'io.flutter.FlutterTestSuite'
  command = [
    'java',
    '-Drobolectric.offline=true',
    '-Drobolectric.dependency.dir=' + robolectric_dir,
    '-classpath', ':'.join(classpath),
    '-Drobolectric.logging=stdout',
    'org.junit.runner.JUnitCore',
    test_class
  ]

  return subprocess.check_call(command)

def RunDartTests(build_dir, filter, verbose_dart_snapshot):
  # This one is a bit messy. The pubspec.yaml at flutter/testing/dart/pubspec.yaml
  # has dependencies that are hardcoded to point to the sky packages at host_debug_unopt/
  # Before running Dart tests, make sure to run just that target (NOT the whole engine)
  EnsureDebugUnoptSkyPackagesAreBuilt();

  # Now that we have the Sky packages at the hardcoded location, run `pub get`.
  RunEngineExecutable(build_dir, os.path.join('dart-sdk', 'bin', 'pub'), None, flags=['get'], cwd=dart_tests_dir)

  dart_tests = glob.glob('%s/*.dart' % dart_tests_dir)

  for dart_test_file in dart_tests:
    if filter is not None and os.path.basename(dart_test_file) not in filter:
      print "Skipping %s due to filter." % dart_test_file
    else:
      print "Testing dart file %s" % dart_test_file
      RunDartTest(build_dir, dart_test_file, verbose_dart_snapshot)

def main():
  parser = argparse.ArgumentParser();

  parser.add_argument('--variant', dest='variant', action='store',
      default='host_debug_unopt', help='The engine build variant to run the tests for.');
  parser.add_argument('--type', type=str, default='all')
  parser.add_argument('--engine-filter', type=str, default='',
      help='A list of engine test executables to run.')
  parser.add_argument('--dart-filter', type=str, default='',
      help='A list of Dart test scripts to run.')
  parser.add_argument('--java-filter', type=str, default='',
      help='A single Java test class to run.')
  parser.add_argument('--android-variant', dest='android_variant', action='store',
      default='android_debug_unopt',
      help='The engine build variant to run java tests for')
  parser.add_argument('--verbose-dart-snapshot', dest='verbose_dart_snapshot', action='store_true',
      default=False, help='Show extra dart snapshot logging.')

  args = parser.parse_args()

  if args.type == 'all':
    types = ['engine', 'dart', 'benchmarks', 'java']
  else:
    types = args.type.split(',')

  build_dir = os.path.join(out_dir, args.variant)
  if args.type != 'java':
    assert os.path.exists(build_dir), 'Build variant directory %s does not exist!' % build_dir

  engine_filter = args.engine_filter.split(',') if args.engine_filter else None
  if 'engine' in types:
    RunCCTests(build_dir, engine_filter)

  if 'dart' in types:
    assert not IsWindows(), "Dart tests can't be run on windows. https://github.com/flutter/flutter/issues/36301."
    dart_filter = args.dart_filter.split(',') if args.dart_filter else None
    RunDartTests(build_dir, dart_filter, args.verbose_dart_snapshot)

  if 'java' in types:
    assert not IsWindows(), "Android engine files can't be compiled on Windows."
    java_filter = args.java_filter
    if ',' in java_filter or '*' in java_filter:
      print('Can only filter JUnit4 tests by single entire class name, eg "io.flutter.SmokeTest". Ignoring filter=' + java_filter)
      java_filter = None
    RunJavaTests(java_filter, args.android_variant)

  # https://github.com/flutter/flutter/issues/36300
  if 'benchmarks' in types and not IsWindows():
    RunEngineBenchmarks(build_dir, engine_filter)


if __name__ == '__main__':
  sys.exit(main())
