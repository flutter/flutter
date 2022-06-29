#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
A top level harness to run all unit-tests in a specific engine build.
"""

import argparse
import glob
import errno
import multiprocessing
import os
import re
import subprocess
import sys
import time

buildroot_dir = os.path.abspath(
    os.path.join(os.path.realpath(__file__), '..', '..', '..')
)
out_dir = os.path.join(buildroot_dir, 'out')
golden_dir = os.path.join(buildroot_dir, 'flutter', 'testing', 'resources')
fonts_dir = os.path.join(
    buildroot_dir, 'flutter', 'third_party', 'txt', 'third_party', 'fonts'
)
roboto_font_path = os.path.join(fonts_dir, 'Roboto-Regular.ttf')
font_subset_dir = os.path.join(buildroot_dir, 'flutter', 'tools', 'font-subset')

fml_unittests_filter = '--gtest_filter=-*TimeSensitiveTest*'


def PrintDivider(char='='):
  print('\n')
  for _ in range(4):
    print(''.join([char for _ in range(80)]))
  print('\n')


def RunCmd(cmd, forbidden_output=[], expect_failure=False, env=None, **kwargs):
  command_string = ' '.join(cmd)

  PrintDivider('>')
  print('Running command "%s"' % command_string)

  start_time = time.time()
  stdout_pipe = sys.stdout if not forbidden_output else subprocess.PIPE
  stderr_pipe = sys.stderr if not forbidden_output else subprocess.PIPE
  process = subprocess.Popen(
      cmd,
      stdout=stdout_pipe,
      stderr=stderr_pipe,
      env=env,
      universal_newlines=True,
      **kwargs
  )
  stdout, stderr = process.communicate()
  end_time = time.time()

  if process.returncode != 0 and not expect_failure:
    PrintDivider('!')

    print(
        'Failed Command:\n\n%s\n\nExit Code: %d\n' %
        (command_string, process.returncode)
    )

    if stdout:
      print('STDOUT: \n%s' % stdout)

    if stderr:
      print('STDERR: \n%s' % stderr)

    PrintDivider('!')

    raise Exception(
        'Command "%s" exited with code %d.' %
        (command_string, process.returncode)
    )

  if stdout or stderr:
    print(stdout)
    print(stderr)

  for forbidden_string in forbidden_output:
    if (stdout and forbidden_string in stdout) or (stderr and
                                                   forbidden_string in stderr):
      raise Exception(
          'command "%s" contained forbidden string %s' %
          (command_string, forbidden_string)
      )

  PrintDivider('<')
  print(
      'Command run successfully in %.2f seconds: %s' %
      (end_time - start_time, command_string)
  )


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


def BuildEngineExecutableCommand(
    build_dir, executable_name, flags=[], coverage=False, gtest=False
):
  unstripped_exe = os.path.join(build_dir, 'exe.unstripped', executable_name)
  # We cannot run the unstripped binaries directly when coverage is enabled.
  if IsLinux() and os.path.exists(unstripped_exe) and not coverage:
    # Use unstripped executables in order to get better symbolized crash
    # stack traces on Linux.
    executable = unstripped_exe
  else:
    executable = FindExecutablePath(os.path.join(build_dir, executable_name))

  coverage_script = os.path.join(
      buildroot_dir, 'flutter', 'build', 'generate_coverage.py'
  )

  if coverage:
    coverage_flags = [
        '-t', executable, '-o',
        os.path.join(build_dir, 'coverage', executable_name), '-f', 'html'
    ]
    updated_flags = ['--args=%s' % ' '.join(flags)]
    test_command = [coverage_script] + coverage_flags + updated_flags
  else:
    test_command = [executable] + flags
    if gtest:
      gtest_parallel = os.path.join(
          buildroot_dir, 'third_party', 'gtest-parallel', 'gtest-parallel'
      )
      test_command = ['python3', gtest_parallel] + test_command

  return test_command


def RunEngineExecutable(
    build_dir,
    executable_name,
    filter,
    flags=[],
    cwd=buildroot_dir,
    forbidden_output=[],
    expect_failure=False,
    coverage=False,
    extra_env={},
    gtest=False
):
  if filter is not None and executable_name not in filter:
    print('Skipping %s due to filter.' % executable_name)
    return

  unstripped_exe = os.path.join(build_dir, 'exe.unstripped', executable_name)
  env = os.environ.copy()
  if IsLinux():
    env['LD_LIBRARY_PATH'] = build_dir
    env['VK_DRIVER_FILES'] = os.path.join(build_dir, 'vk_swiftshader_icd.json')
    if os.path.exists(unstripped_exe):
      try:
        os.symlink(
            os.path.join(build_dir, 'lib.unstripped', 'libvulkan.so.1'),
            os.path.join(build_dir, 'exe.unstripped', 'libvulkan.so.1')
        )
      except OSError as e:
        if e.errno == errno.EEXIST:
          pass
        else:
          raise
  elif IsMac():
    env['DYLD_LIBRARY_PATH'] = build_dir
  else:
    env['PATH'] = build_dir + ":" + env['PATH']

  print('Running %s in %s' % (executable_name, cwd))

  test_command = BuildEngineExecutableCommand(
      build_dir,
      executable_name,
      flags=flags,
      coverage=coverage,
      gtest=gtest,
  )

  env['FLUTTER_BUILD_DIRECTORY'] = build_dir
  for key, value in extra_env.items():
    env[key] = value

  try:
    RunCmd(
        test_command,
        cwd=cwd,
        forbidden_output=forbidden_output,
        expect_failure=expect_failure,
        env=env
    )
  except:
    # The LUCI environment may provide a variable containing a directory path
    # for additional output files that will be uploaded to cloud storage.
    # If the command generated a core dump, then run a script to analyze
    # the dump and output a report that will be uploaded.
    luci_test_outputs_path = os.environ.get('FLUTTER_TEST_OUTPUTS_DIR')
    core_path = os.path.join(cwd, 'core')
    if luci_test_outputs_path and os.path.exists(core_path) and os.path.exists(
        unstripped_exe):
      dump_path = os.path.join(
          luci_test_outputs_path, '%s_%s.txt' % (executable_name, sys.platform)
      )
      print('Writing core dump analysis to %s' % dump_path)
      subprocess.call([
          os.path.join(
              buildroot_dir, 'flutter', 'testing', 'analyze_core_dump.sh'
          ),
          buildroot_dir,
          unstripped_exe,
          core_path,
          dump_path,
      ])
      os.unlink(core_path)
    raise


class EngineExecutableTask(object):

  def __init__(
      self,
      build_dir,
      executable_name,
      filter,
      flags=[],
      cwd=buildroot_dir,
      forbidden_output=[],
      expect_failure=False,
      coverage=False,
      extra_env={}
  ):
    self.build_dir = build_dir
    self.executable_name = executable_name
    self.filter = filter
    self.flags = flags
    self.cwd = cwd
    self.forbidden_output = forbidden_output
    self.expect_failure = expect_failure
    self.coverage = coverage
    self.extra_env = extra_env

  def __call__(self, *args):
    RunEngineExecutable(
        self.build_dir,
        self.executable_name,
        self.filter,
        flags=self.flags,
        cwd=self.cwd,
        forbidden_output=self.forbidden_output,
        expect_failure=self.expect_failure,
        coverage=self.coverage,
        extra_env=self.extra_env,
    )

  def __str__(self):
    command = BuildEngineExecutableCommand(
        self.build_dir,
        self.executable_name,
        flags=self.flags,
        coverage=self.coverage
    )
    return " ".join(command)


def RunCCTests(build_dir, filter, coverage, capture_core_dump):
  print("Running Engine Unit-tests.")

  if capture_core_dump and IsLinux():
    import resource
    resource.setrlimit(
        resource.RLIMIT_CORE, (resource.RLIM_INFINITY, resource.RLIM_INFINITY)
    )

  shuffle_flags = [
      "--gtest_repeat=2",
      "--gtest_shuffle",
  ]

  repeat_flags = [
      "--repeat=2",
  ]

  def make_test(name, flags=repeat_flags, extra_env={}):
    return (name, flags, extra_env)

  unittests = [
      make_test('client_wrapper_glfw_unittests'),
      make_test('client_wrapper_unittests'),
      make_test('common_cpp_core_unittests'),
      make_test('common_cpp_unittests'),
      make_test('dart_plugin_registrant_unittests'),
      make_test('display_list_rendertests'),
      make_test('display_list_unittests'),
      make_test('embedder_a11y_unittests'),
      make_test('embedder_proctable_unittests'),
      make_test('embedder_unittests'),
      make_test('fml_unittests', flags=[fml_unittests_filter] + repeat_flags),
      make_test('no_dart_plugin_registrant_unittests'),
      make_test('runtime_unittests'),
      make_test('testing_unittests'),
      make_test('tonic_unittests'),
      # The image release unit test can take a while on slow machines.
      make_test('ui_unittests', flags=repeat_flags + ['--timeout=90']),
  ]

  if not IsWindows():
    unittests += [
        # https://github.com/google/googletest/issues/2490
        make_test('android_external_view_embedder_unittests'),
        make_test('jni_unittests'),
        make_test('platform_view_android_delegate_unittests'),
        # https://github.com/flutter/flutter/issues/36295
        make_test('shell_unittests'),
    ]

  if IsWindows():
    unittests += [
        # The accessibility library only supports Mac and Windows.
        make_test('accessibility_unittests'),
        make_test('client_wrapper_windows_unittests'),
        make_test('flutter_windows_unittests'),
    ]

  # These unit-tests are Objective-C and can only run on Darwin.
  if IsMac():
    unittests += [
        # The accessibility library only supports Mac and Windows.
        make_test('accessibility_unittests'),
        make_test('flutter_channels_unittests'),
    ]

  if IsLinux():
    flow_flags = [
        '--golden-dir=%s' % golden_dir,
        '--font-file=%s' % roboto_font_path,
    ]
    icu_flags = [
        '--icu-data-file-path=%s' % os.path.join(build_dir, 'icudtl.dat')
    ]
    unittests += [
        make_test('flow_unittests', flags=repeat_flags + ['--'] + flow_flags),
        make_test('flutter_glfw_unittests'),
        make_test(
            'flutter_linux_unittests', extra_env={'G_DEBUG': 'fatal-criticals'}
        ),
        # https://github.com/flutter/flutter/issues/36296
        make_test('txt_unittests', flags=repeat_flags + ['--'] + icu_flags),
    ]
  else:
    flow_flags = ['--gtest_filter=-PerformanceOverlayLayer.Gold']
    unittests += [
        make_test('flow_unittests', flags=repeat_flags + flow_flags),
    ]

  for test, flags, extra_env in unittests:
    RunEngineExecutable(
        build_dir,
        test,
        filter,
        flags,
        coverage=coverage,
        extra_env=extra_env,
        gtest=True
    )

  if IsMac():
    # flutter_desktop_darwin_unittests uses global state that isn't handled
    # correctly by gtest-parallel.
    # https://github.com/flutter/flutter/issues/104789
    RunEngineExecutable(
        build_dir,
        'flutter_desktop_darwin_unittests',
        filter,
        shuffle_flags,
        coverage=coverage
    )
    # Impeller tests are only supported on macOS for now.
    RunEngineExecutable(
        build_dir,
        'impeller_unittests',
        filter,
        shuffle_flags,
        coverage=coverage
    )


def RunEngineBenchmarks(build_dir, filter):
  print("Running Engine Benchmarks.")

  icu_flags = [
      '--icu-data-file-path=%s' % os.path.join(build_dir, 'icudtl.dat')
  ]

  RunEngineExecutable(build_dir, 'shell_benchmarks', filter, icu_flags)

  RunEngineExecutable(build_dir, 'fml_benchmarks', filter, icu_flags)

  RunEngineExecutable(build_dir, 'ui_benchmarks', filter, icu_flags)

  if IsLinux():
    RunEngineExecutable(build_dir, 'txt_benchmarks', filter, icu_flags)


def GatherDartTest(
    build_dir,
    test_packages,
    dart_file,
    verbose_dart_snapshot,
    multithreaded,
    enable_observatory=False,
    expect_failure=False,
    alternative_tester=False
):
  kernel_file_name = os.path.basename(dart_file) + '.dill'
  kernel_file_output = os.path.join(build_dir, 'gen', kernel_file_name)
  error_message = "%s doesn't exist. Please run the build that populates %s" % (
      kernel_file_output, build_dir
  )
  assert os.path.isfile(kernel_file_output), error_message

  command_args = []
  if not enable_observatory:
    command_args.append('--disable-observatory')

  dart_file_contents = open(dart_file, 'r')
  custom_options = re.findall(
      "// FlutterTesterOptions=(.*)", dart_file_contents.read()
  )
  dart_file_contents.close()
  command_args.extend(custom_options)

  command_args += [
      '--use-test-fonts',
      '--icu-data-file-path=%s' % os.path.join(build_dir, 'icudtl.dat'),
      '--flutter-assets-dir=%s' %
      os.path.join(build_dir, 'gen', 'flutter', 'lib', 'ui', 'assets'),
      '--disable-asset-fonts',
      kernel_file_output,
  ]

  if multithreaded:
    threading = 'multithreaded'
    command_args.insert(0, '--force-multithreading')
  else:
    threading = 'single-threaded'

  tester_name = 'flutter_tester'
  print(
      "Running test '%s' using '%s' (%s)" %
      (kernel_file_name, tester_name, threading)
  )
  forbidden_output = [] if 'unopt' in build_dir or expect_failure else [
      '[ERROR'
  ]
  return EngineExecutableTask(
      build_dir,
      tester_name,
      None,
      command_args,
      forbidden_output=forbidden_output,
      expect_failure=expect_failure,
  )


def EnsureDebugUnoptSkyPackagesAreBuilt():
  variant_out_dir = os.path.join(out_dir, 'host_debug_unopt')
  message = []
  message.append('gn --runtime-mode debug --unopt --no-lto')
  message.append('ninja -C %s flutter/sky/packages' % variant_out_dir)
  final_message = '%s doesn\'t exist. Please run the following commands: \n%s' % (
      variant_out_dir, '\n'.join(message)
  )
  assert os.path.exists(variant_out_dir), final_message


def EnsureIosTestsAreBuilt(ios_out_dir):
  """Builds the engine variant and the test dylib containing the XCTests"""
  tmp_out_dir = os.path.join(out_dir, ios_out_dir)
  ios_test_lib = os.path.join(tmp_out_dir, 'libios_test_flutter.dylib')
  message = []
  message.append(
      'gn --ios --unoptimized --runtime-mode=debug --no-lto --simulator'
  )
  message.append('autoninja -C %s ios_test_flutter' % ios_out_dir)
  final_message = '%s or %s doesn\'t exist. Please run the following commands: \n%s' % (
      ios_out_dir, ios_test_lib, '\n'.join(message)
  )
  assert os.path.exists(tmp_out_dir
                       ) and os.path.exists(ios_test_lib), final_message


def AssertExpectedXcodeVersion():
  """Checks that the user has a version of Xcode installed"""
  version_output = subprocess.check_output(['xcodebuild', '-version'])
  match = re.match(b"Xcode (\d+)", version_output)
  message = "Xcode must be installed to run the iOS embedding unit tests"
  assert match, message


def JavaHome():
  script_path = os.path.dirname(os.path.realpath(__file__))
  if IsMac():
    return os.path.join(
        script_path, '..', '..', 'third_party', 'java', 'openjdk', 'Contents',
        'Home'
    )
  else:
    return os.path.join(
        script_path, '..', '..', 'third_party', 'java', 'openjdk'
    )


def JavaBin():
  return os.path.join(JavaHome(), 'bin', 'java.exe' if IsWindows() else 'java')


def RunJavaTests(filter, android_variant='android_debug_unopt'):
  """Runs the Java JUnit unit tests for the Android embedding"""
  test_runner_dir = os.path.join(
      buildroot_dir, 'flutter', 'shell', 'platform', 'android', 'test_runner'
  )
  gradle_bin = os.path.join(
      buildroot_dir, 'third_party', 'gradle', 'bin',
      'gradle.bat' if IsWindows() else 'gradle'
  )
  flutter_jar = os.path.join(out_dir, android_variant, 'flutter.jar')
  android_home = os.path.join(
      buildroot_dir, 'third_party', 'android_tools', 'sdk'
  )
  build_dir = os.path.join(
      out_dir, android_variant, 'robolectric_tests', 'build'
  )
  gradle_cache_dir = os.path.join(
      out_dir, android_variant, 'robolectric_tests', '.gradle'
  )

  test_class = filter if filter else '*'
  command = [
      gradle_bin,
      '-Pflutter_jar=%s' % flutter_jar,
      '-Pbuild_dir=%s' % build_dir,
      'testDebugUnitTest',
      '--tests=%s' % test_class,
      '--rerun-tasks',
      '--no-daemon',
      '--project-cache-dir=%s' % gradle_cache_dir,
      '--gradle-user-home=%s' % gradle_cache_dir,
  ]

  env = dict(os.environ, ANDROID_HOME=android_home, JAVA_HOME=JavaHome())
  RunCmd(command, cwd=test_runner_dir, env=env)


def RunAndroidTests(android_variant='android_debug_unopt', adb_path=None):
  test_runner_name = 'flutter_shell_native_unittests'
  tests_path = os.path.join(out_dir, android_variant, test_runner_name)
  remote_path = '/data/local/tmp'
  remote_tests_path = os.path.join(remote_path, test_runner_name)
  if adb_path == None:
    adb_path = 'adb'
  RunCmd([adb_path, 'push', tests_path, remote_path], cwd=buildroot_dir)
  RunCmd([adb_path, 'shell', remote_tests_path])

  systrace_test = os.path.join(
      buildroot_dir, 'flutter', 'testing', 'android_systrace_test.py'
  )
  scenario_apk = os.path.join(
      out_dir, android_variant, 'firebase_apks', 'scenario_app.apk'
  )
  RunCmd([
      systrace_test, '--adb-path', adb_path, '--apk-path', scenario_apk,
      '--package-name', 'dev.flutter.scenarios', '--activity-name',
      '.PlatformViewsActivity'
  ])


def RunObjcTests(ios_variant='ios_debug_sim_unopt', test_filter=None):
  """Runs Objective-C XCTest unit tests for the iOS embedding"""
  AssertExpectedXcodeVersion()
  ios_out_dir = os.path.join(out_dir, ios_variant)
  EnsureIosTestsAreBuilt(ios_out_dir)

  new_simulator_name = 'IosUnitTestsSimulator'

  # Delete simulators with this name in case any were leaked
  # from another test run.
  DeleteSimulator(new_simulator_name)

  create_simulator = [
      'xcrun '
      'simctl '
      'create '
      '%s com.apple.CoreSimulator.SimDeviceType.iPhone-11' % new_simulator_name
  ]
  RunCmd(create_simulator, shell=True)

  try:
    ios_unit_test_dir = os.path.join(
        buildroot_dir, 'flutter', 'testing', 'ios', 'IosUnitTests'
    )
    # Avoid using xcpretty unless the following can be addressed:
    # - Make sure all relevant failure output is printed on a failure.
    # - Make sure that a failing exit code is set for CI.
    # See https://github.com/flutter/flutter/issues/63742
    test_command = [
        'xcodebuild '
        '-sdk iphonesimulator '
        '-scheme IosUnitTests '
        "-destination name='" + new_simulator_name + "' "
        'test '
        'FLUTTER_ENGINE=' + ios_variant
    ]
    if test_filter != None:
      test_command[0] = test_command[0] + " -only-testing:%s" % test_filter
    RunCmd(test_command, cwd=ios_unit_test_dir, shell=True)
  finally:
    DeleteSimulator(new_simulator_name)


def DeleteSimulator(simulator_name):
  # Will delete all simulators with this name.
  delete_simulator = [
      'xcrun',
      'simctl',
      'delete',
      simulator_name,
  ]
  # Let this fail if the simulator was never created.
  RunCmd(delete_simulator, expect_failure=True)


def GatherDartTests(build_dir, filter, verbose_dart_snapshot):
  dart_tests_dir = os.path.join(
      buildroot_dir,
      'flutter',
      'testing',
      'dart',
  )

  # This one is a bit messy. The pubspec.yaml at flutter/testing/dart/pubspec.yaml
  # has dependencies that are hardcoded to point to the sky packages at host_debug_unopt/
  # Before running Dart tests, make sure to run just that target (NOT the whole engine)
  EnsureDebugUnoptSkyPackagesAreBuilt()

  # Now that we have the Sky packages at the hardcoded location, run `dart pub get`.
  RunEngineExecutable(
      build_dir,
      os.path.join('dart-sdk', 'bin', 'dart'),
      None,
      flags=['pub', 'get', '--offline'],
      cwd=dart_tests_dir,
  )

  dart_observatory_tests = glob.glob(
      '%s/observatory/*_test.dart' % dart_tests_dir
  )
  dart_tests = glob.glob('%s/*_test.dart' % dart_tests_dir)
  test_packages = os.path.join(
      dart_tests_dir, '.dart_tool', 'package_config.json'
  )

  if 'release' not in build_dir:
    for dart_test_file in dart_observatory_tests:
      if filter is not None and os.path.basename(dart_test_file) not in filter:
        print("Skipping '%s' due to filter." % dart_test_file)
      else:
        print(
            "Gathering dart test '%s' with observatory enabled" % dart_test_file
        )
        yield GatherDartTest(
            build_dir, test_packages, dart_test_file, verbose_dart_snapshot,
            True, True
        )
        yield GatherDartTest(
            build_dir, test_packages, dart_test_file, verbose_dart_snapshot,
            False, True
        )

  for dart_test_file in dart_tests:
    if filter is not None and os.path.basename(dart_test_file) not in filter:
      print("Skipping '%s' due to filter." % dart_test_file)
    else:
      print("Gathering dart test '%s'" % dart_test_file)
      yield GatherDartTest(
          build_dir, test_packages, dart_test_file, verbose_dart_snapshot, True
      )
      yield GatherDartTest(
          build_dir, test_packages, dart_test_file, verbose_dart_snapshot, False
      )


def GatherDartSmokeTest(build_dir, verbose_dart_snapshot):
  smoke_test = os.path.join(
      buildroot_dir, "flutter", "testing", "smoke_test_failure",
      "fail_test.dart"
  )
  test_packages = os.path.join(
      buildroot_dir, "flutter", "testing", "smoke_test_failure", ".dart_tool",
      "package_config.json"
  )
  yield GatherDartTest(
      build_dir,
      test_packages,
      smoke_test,
      verbose_dart_snapshot,
      True,
      expect_failure=True
  )
  yield GatherDartTest(
      build_dir,
      test_packages,
      smoke_test,
      verbose_dart_snapshot,
      False,
      expect_failure=True
  )


def GatherFrontEndServerTests(build_dir):
  test_dir = os.path.join(buildroot_dir, 'flutter', 'flutter_frontend_server')
  dart_tests = glob.glob('%s/test/*_test.dart' % test_dir)
  for dart_test_file in dart_tests:
    opts = [
        '--disable-dart-dev', dart_test_file, build_dir,
        os.path.join(build_dir, 'gen', 'frontend_server.dart.snapshot'),
        os.path.join(build_dir, 'flutter_patched_sdk')
    ]
    yield EngineExecutableTask(
        build_dir,
        os.path.join('dart-sdk', 'bin', 'dart'),
        None,
        flags=opts,
        cwd=test_dir
    )


def GatherConstFinderTests(build_dir):
  test_dir = os.path.join(
      buildroot_dir, 'flutter', 'tools', 'const_finder', 'test'
  )
  opts = [
      '--disable-dart-dev',
      os.path.join(test_dir, 'const_finder_test.dart'),
      os.path.join(build_dir, 'gen', 'frontend_server.dart.snapshot'),
      os.path.join(build_dir, 'flutter_patched_sdk')
  ]
  yield EngineExecutableTask(
      build_dir,
      os.path.join('dart-sdk', 'bin', 'dart'),
      None,
      flags=opts,
      cwd=test_dir
  )


def GatherLitetestTests(build_dir):
  test_dir = os.path.join(buildroot_dir, 'flutter', 'testing', 'litetest')
  dart_tests = glob.glob('%s/test/*_test.dart' % test_dir)
  for dart_test_file in dart_tests:
    opts = ['--disable-dart-dev', dart_test_file]
    yield EngineExecutableTask(
        build_dir,
        os.path.join('dart-sdk', 'bin', 'dart'),
        None,
        flags=opts,
        cwd=test_dir
    )


def RunBenchmarkTests(build_dir):
  test_dir = os.path.join(buildroot_dir, 'flutter', 'testing', 'benchmark')
  dart_tests = glob.glob('%s/test/*_test.dart' % test_dir)
  for dart_test_file in dart_tests:
    opts = ['--disable-dart-dev', dart_test_file]
    RunEngineExecutable(
        build_dir,
        os.path.join('dart-sdk', 'bin', 'dart'),
        None,
        flags=opts,
        cwd=test_dir
    )


def GatherGithooksTests(build_dir):
  test_dir = os.path.join(buildroot_dir, 'flutter', 'tools', 'githooks')
  dart_tests = glob.glob('%s/test/*_test.dart' % test_dir)
  for dart_test_file in dart_tests:
    opts = ['--disable-dart-dev', dart_test_file]
    yield EngineExecutableTask(
        build_dir,
        os.path.join('dart-sdk', 'bin', 'dart'),
        None,
        flags=opts,
        cwd=test_dir
    )


def GatherClangTidyTests(build_dir):
  test_dir = os.path.join(buildroot_dir, 'flutter', 'tools', 'clang_tidy')
  dart_tests = glob.glob('%s/test/*_test.dart' % test_dir)
  for dart_test_file in dart_tests:
    opts = [
        '--disable-dart-dev', dart_test_file,
        os.path.join(build_dir, 'compile_commands.json'),
        os.path.join(buildroot_dir, 'flutter')
    ]
    yield EngineExecutableTask(
        build_dir,
        os.path.join('dart-sdk', 'bin', 'dart'),
        None,
        flags=opts,
        cwd=test_dir
    )


def GatherApiConsistencyTests(build_dir):
  test_dir = os.path.join(buildroot_dir, 'flutter', 'tools', 'api_check')
  dart_tests = glob.glob('%s/test/*_test.dart' % test_dir)
  for dart_test_file in dart_tests:
    opts = [
        '--disable-dart-dev', dart_test_file,
        os.path.join(buildroot_dir, 'flutter')
    ]
    yield EngineExecutableTask(
        build_dir,
        os.path.join('dart-sdk', 'bin', 'dart'),
        None,
        flags=opts,
        cwd=test_dir
    )


def RunEngineTasksInParallel(tasks):
  # Work around a bug in Python.
  #
  # The multiprocessing package relies on the win32 WaitForMultipleObjects()
  # call, which supports waiting on a maximum of MAXIMUM_WAIT_OBJECTS (defined
  # by Windows to be 64) handles, processes in this case. To avoid hitting
  # this, we limit ourselves to 60 handles (since there are a couple extra
  # processes launched for the queue reader and thread wakeup reader).
  #
  # See: https://bugs.python.org/issue26903
  max_processes = multiprocessing.cpu_count()
  if sys.platform.startswith(('cygwin', 'win')) and max_processes > 60:
    max_processes = 60

  pool = multiprocessing.Pool(processes=max_processes)
  async_results = [(t, pool.apply_async(t, ())) for t in tasks]
  failures = []
  for task, async_result in async_results:
    try:
      async_result.get()
    except Exception as exn:
      failures += [(task, exn)]

  if len(failures) > 0:
    print("The following commands failed:")
    for task, exn in failures:
      print("%s\n%s\n" % (str(task), str(exn)))
    raise Exception()


def main():
  parser = argparse.ArgumentParser()
  all_types = [
      'engine', 'dart', 'benchmarks', 'java', 'android', 'objc', 'font-subset'
  ]

  parser.add_argument(
      '--variant',
      dest='variant',
      action='store',
      default='host_debug_unopt',
      help='The engine build variant to run the tests for.'
  )
  parser.add_argument(
      '--type',
      type=str,
      default='all',
      help='A list of test types, default is "all" (equivalent to "%s")' %
      (','.join(all_types))
  )
  parser.add_argument(
      '--engine-filter',
      type=str,
      default='',
      help='A list of engine test executables to run.'
  )
  parser.add_argument(
      '--dart-filter',
      type=str,
      default='',
      help='A list of Dart test scripts to run.'
  )
  parser.add_argument(
      '--java-filter',
      type=str,
      default='',
      help='A single Java test class to run (example: "io.flutter.SmokeTest")'
  )
  parser.add_argument(
      '--android-variant',
      dest='android_variant',
      action='store',
      default='android_debug_unopt',
      help='The engine build variant to run java or android tests for'
  )
  parser.add_argument(
      '--ios-variant',
      dest='ios_variant',
      action='store',
      default='ios_debug_sim_unopt',
      help='The engine build variant to run objective-c tests for'
  )
  parser.add_argument(
      '--verbose-dart-snapshot',
      dest='verbose_dart_snapshot',
      action='store_true',
      default=False,
      help='Show extra dart snapshot logging.'
  )
  parser.add_argument(
      '--objc-filter',
      type=str,
      default=None,
      help='Filter parameter for which objc tests to run (example: "IosUnitTestsTests/SemanticsObjectTest/testShouldTriggerAnnouncement")'
  )
  parser.add_argument(
      '--coverage',
      action='store_true',
      default=None,
      help='Generate coverage reports for each unit test framework run.'
  )
  parser.add_argument(
      '--engine-capture-core-dump',
      dest='engine_capture_core_dump',
      action='store_true',
      default=False,
      help='Capture core dumps from crashes of engine tests.'
  )
  parser.add_argument(
      '--use-sanitizer-suppressions',
      dest='sanitizer_suppressions',
      action='store_true',
      default=False,
      help='Provide the sanitizer suppressions lists to the via environment to the tests.'
  )
  parser.add_argument(
      '--adb-path',
      dest='adb_path',
      action='store',
      default=None,
      help='Provide the path of adb used for android tests. By default it looks on $PATH.'
  )

  args = parser.parse_args()

  if args.type == 'all':
    types = all_types
  else:
    types = args.type.split(',')

  build_dir = os.path.join(out_dir, args.variant)
  if args.type != 'java' and args.type != 'android':
    assert os.path.exists(
        build_dir
    ), 'Build variant directory %s does not exist!' % build_dir

  if args.sanitizer_suppressions:
    assert IsLinux() or IsMac(
    ), "The sanitizer suppressions flag is only supported on Linux and Mac."
    file_dir = os.path.dirname(os.path.abspath(__file__))
    command = [
        "env", "-i", "bash", "-c",
        "source {}/sanitizer_suppressions.sh >/dev/null && env"
        .format(file_dir)
    ]
    process = subprocess.Popen(command, stdout=subprocess.PIPE)
    for line in process.stdout:
      key, _, value = line.decode('utf8').strip().partition("=")
      os.environ[key] = value
    process.communicate()  # Avoid pipe deadlock while waiting for termination.

  engine_filter = args.engine_filter.split(',') if args.engine_filter else None
  if 'engine' in types:
    RunCCTests(
        build_dir, engine_filter, args.coverage, args.engine_capture_core_dump
    )

  if 'dart' in types:
    assert not IsWindows(
    ), "Dart tests can't be run on windows. https://github.com/flutter/flutter/issues/36301."
    dart_filter = args.dart_filter.split(',') if args.dart_filter else None
    tasks = list(GatherDartSmokeTest(build_dir, args.verbose_dart_snapshot))
    tasks += list(GatherLitetestTests(build_dir))
    tasks += list(GatherGithooksTests(build_dir))
    tasks += list(GatherClangTidyTests(build_dir))
    tasks += list(GatherApiConsistencyTests(build_dir))
    tasks += list(GatherConstFinderTests(build_dir))
    tasks += list(GatherFrontEndServerTests(build_dir))
    tasks += list(
        GatherDartTests(build_dir, dart_filter, args.verbose_dart_snapshot)
    )
    RunEngineTasksInParallel(tasks)

  if 'java' in types:
    assert not IsWindows(), "Android engine files can't be compiled on Windows."
    java_filter = args.java_filter
    if ',' in java_filter or '*' in java_filter:
      print(
          'Can only filter JUnit4 tests by single entire class name, eg "io.flutter.SmokeTest". Ignoring filter='
          + java_filter
      )
      java_filter = None
    RunJavaTests(java_filter, args.android_variant)

  if 'android' in types:
    assert not IsWindows(), "Android engine files can't be compiled on Windows."
    RunAndroidTests(args.android_variant, args.adb_path)

  if 'objc' in types:
    assert IsMac(), "iOS embedding tests can only be run on macOS."
    RunObjcTests(args.ios_variant, args.objc_filter)

  # https://github.com/flutter/flutter/issues/36300
  if 'benchmarks' in types and not IsWindows():
    RunBenchmarkTests(build_dir)
    RunEngineBenchmarks(build_dir, engine_filter)

  variants_to_skip = ['host_release', 'host_profile']
  if ('engine' in types or
      'font-subset' in types) and args.variant not in variants_to_skip:
    RunCmd(['python3', 'test.py'], cwd=font_subset_dir)


if __name__ == '__main__':
  sys.exit(main())
