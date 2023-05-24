#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
A top level harness to run all unit-tests in a specific engine build.
"""

from pathlib import Path

import argparse
import csv
import errno
import glob
import multiprocessing
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import typing
import xvfb

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
BUILDROOT_DIR = os.path.abspath(
    os.path.join(os.path.realpath(__file__), '..', '..', '..')
)
OUT_DIR = os.path.join(BUILDROOT_DIR, 'out')
GOLDEN_DIR = os.path.join(BUILDROOT_DIR, 'flutter', 'testing', 'resources')
FONTS_DIR = os.path.join(
    BUILDROOT_DIR, 'flutter', 'third_party', 'txt', 'third_party', 'fonts'
)
ROBOTO_FONT_PATH = os.path.join(FONTS_DIR, 'Roboto-Regular.ttf')
FONT_SUBSET_DIR = os.path.join(BUILDROOT_DIR, 'flutter', 'tools', 'font-subset')

FML_UNITTESTS_FILTER = '--gtest_filter=-*TimeSensitiveTest*'
ENCODING = 'UTF-8'


def print_divider(char='='):
  print('\n')
  for _ in range(4):
    print(''.join([char for _ in range(80)]))
  print('\n')


def is_asan(build_dir):
  with open(os.path.join(build_dir, 'args.gn')) as args:
    if 'is_asan = true' in args.read():
      return True

  return False


def run_cmd(
    cmd: typing.List[str],
    forbidden_output: typing.List[str] = None,
    expect_failure: bool = False,
    env: typing.Dict[str, str] = None,
    allowed_failure_output: typing.List[str] = None,
    **kwargs
) -> None:
  if forbidden_output is None:
    forbidden_output = []
  if allowed_failure_output is None:
    allowed_failure_output = []

  command_string = ' '.join(cmd)

  print_divider('>')
  print(f'Running command "{command_string}"')

  start_time = time.time()
  collect_output = forbidden_output or allowed_failure_output
  stdout_pipe = sys.stdout if not collect_output else subprocess.PIPE
  stderr_pipe = sys.stderr if not collect_output else subprocess.PIPE

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
    print_divider('!')

    print(
        f'Failed Command:\n\n{command_string}\n\nExit Code: {process.returncode}\n'
    )

    if stdout:
      print(f'STDOUT: \n{stdout}')

    if stderr:
      print(f'STDERR: \n{stderr}')

    print_divider('!')

    allowed_failure = False
    for allowed_string in allowed_failure_output:
      if (stdout and allowed_string in stdout) or (stderr and
                                                   allowed_string in stderr):
        allowed_failure = True

    if not allowed_failure:
      raise RuntimeError(
          f'Command "{command_string}" exited with code {process.returncode}.'
      )

  if stdout or stderr:
    print(stdout)
    print(stderr)

  for forbidden_string in forbidden_output:
    if (stdout and forbidden_string in stdout) or (stderr and
                                                   forbidden_string in stderr):
      raise RuntimeError(
          f'command "{command_string}" contained forbidden string {forbidden_string}'
      )

  print_divider('<')
  print(
      f'Command run successfully in {end_time - start_time:.2f} seconds: {command_string}'
  )


def is_mac():
  return sys.platform == 'darwin'


def is_aarm64():
  assert is_mac()
  output = subprocess.check_output(['sysctl', 'machdep.cpu'])
  text = output.decode('utf-8')
  aarm64 = text.find('Apple') >= 0
  if not aarm64:
    assert text.find('GenuineIntel') >= 0
  return aarm64


def is_linux():
  return sys.platform.startswith('linux')


def is_windows():
  return sys.platform.startswith(('cygwin', 'win'))


def executable_suffix():
  return '.exe' if is_windows() else ''


def find_executable_path(path):
  if os.path.exists(path):
    return path

  if is_windows():
    exe_path = path + '.exe'
    if os.path.exists(exe_path):
      return exe_path

    bat_path = path + '.bat'
    if os.path.exists(bat_path):
      return bat_path

  raise Exception('Executable %s does not exist!' % path)


def build_engine_executable_command(
    build_dir, executable_name, flags=None, coverage=False, gtest=False
):
  if flags is None:
    flags = []

  unstripped_exe = os.path.join(build_dir, 'exe.unstripped', executable_name)
  # We cannot run the unstripped binaries directly when coverage is enabled.
  if is_linux() and os.path.exists(unstripped_exe) and not coverage:
    # Use unstripped executables in order to get better symbolized crash
    # stack traces on Linux.
    executable = unstripped_exe
  else:
    executable = find_executable_path(os.path.join(build_dir, executable_name))

  coverage_script = os.path.join(
      BUILDROOT_DIR, 'flutter', 'build', 'generate_coverage.py'
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
          BUILDROOT_DIR, 'third_party', 'gtest-parallel', 'gtest-parallel'
      )
      test_command = ['python3', gtest_parallel] + test_command

  return test_command


def run_engine_executable( # pylint: disable=too-many-arguments
    build_dir,
    executable_name,
    executable_filter,
    flags=None,
    cwd=BUILDROOT_DIR,
    forbidden_output=None,
    allowed_failure_output=None,
    expect_failure=False,
    coverage=False,
    extra_env=None,
    gtest=False,
):
  if executable_filter is not None and executable_name not in executable_filter:
    print('Skipping %s due to filter.' % executable_name)
    return

  if flags is None:
    flags = []
  if forbidden_output is None:
    forbidden_output = []
  if allowed_failure_output is None:
    allowed_failure_output = []
  if extra_env is None:
    extra_env = {}

  unstripped_exe = os.path.join(build_dir, 'exe.unstripped', executable_name)
  env = os.environ.copy()
  if is_linux():
    env['LD_LIBRARY_PATH'] = build_dir
    env['VK_DRIVER_FILES'] = os.path.join(build_dir, 'vk_swiftshader_icd.json')
    if os.path.exists(unstripped_exe):
      try:
        os.symlink(
            os.path.join(build_dir, 'lib.unstripped', 'libvulkan.so.1'),
            os.path.join(build_dir, 'exe.unstripped', 'libvulkan.so.1')
        )
      except OSError as err:
        if err.errno == errno.EEXIST:
          pass
        else:
          raise
  elif is_mac():
    env['DYLD_LIBRARY_PATH'] = build_dir
  else:
    env['PATH'] = build_dir + ':' + env['PATH']

  print('Running %s in %s' % (executable_name, cwd))

  test_command = build_engine_executable_command(
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
    run_cmd(
        test_command,
        cwd=cwd,
        forbidden_output=forbidden_output,
        expect_failure=expect_failure,
        env=env,
        allowed_failure_output=allowed_failure_output,
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
              BUILDROOT_DIR, 'flutter', 'testing', 'analyze_core_dump.sh'
          ),
          BUILDROOT_DIR,
          unstripped_exe,
          core_path,
          dump_path,
      ])
      os.unlink(core_path)
    raise


class EngineExecutableTask():  # pylint: disable=too-many-instance-attributes

  def __init__( # pylint: disable=too-many-arguments
      self,
      build_dir,
      executable_name,
      executable_filter,
      flags=None,
      cwd=BUILDROOT_DIR,
      forbidden_output=None,
      allowed_failure_output=None,
      expect_failure=False,
      coverage=False,
      extra_env=None,
  ):
    self.build_dir = build_dir
    self.executable_name = executable_name
    self.executable_filter = executable_filter
    self.flags = flags
    self.cwd = cwd
    self.forbidden_output = forbidden_output
    self.allowed_failure_output = allowed_failure_output
    self.expect_failure = expect_failure
    self.coverage = coverage
    self.extra_env = extra_env

  def __call__(self, *args):
    run_engine_executable(
        self.build_dir,
        self.executable_name,
        self.executable_filter,
        flags=self.flags,
        cwd=self.cwd,
        forbidden_output=self.forbidden_output,
        allowed_failure_output=self.allowed_failure_output,
        expect_failure=self.expect_failure,
        coverage=self.coverage,
        extra_env=self.extra_env,
    )

  def __str__(self):
    command = build_engine_executable_command(
        self.build_dir,
        self.executable_name,
        flags=self.flags,
        coverage=self.coverage
    )
    return ' '.join(command)


shuffle_flags = [
    '--gtest_repeat=2',
    '--gtest_shuffle',
]


def run_cc_tests(build_dir, executable_filter, coverage, capture_core_dump):
  print('Running Engine Unit-tests.')

  if capture_core_dump and is_linux():
    import resource  # pylint: disable=import-outside-toplevel
    resource.setrlimit(
        resource.RLIMIT_CORE, (resource.RLIM_INFINITY, resource.RLIM_INFINITY)
    )

  repeat_flags = [
      '--repeat=2',
  ]

  def make_test(name, flags=None, extra_env=None):
    if flags is None:
      flags = repeat_flags
    if extra_env is None:
      extra_env = {}
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
      make_test('fml_unittests', flags=[FML_UNITTESTS_FILTER] + repeat_flags),
      make_test('no_dart_plugin_registrant_unittests'),
      make_test('runtime_unittests'),
      make_test('testing_unittests'),
      make_test('tonic_unittests'),
      # The image release unit test can take a while on slow machines.
      make_test('ui_unittests', flags=repeat_flags + ['--timeout=90']),
  ]

  if not is_windows():
    unittests += [
        # https://github.com/google/googletest/issues/2490
        make_test('android_external_view_embedder_unittests'),
        make_test('jni_unittests'),
        make_test('platform_view_android_delegate_unittests'),
        # https://github.com/flutter/flutter/issues/36295
        make_test('shell_unittests'),
    ]

  if is_windows():
    unittests += [
        # The accessibility library only supports Mac and Windows.
        make_test('accessibility_unittests'),
        make_test('client_wrapper_windows_unittests'),
        make_test('flutter_windows_unittests'),
    ]

  # These unit-tests are Objective-C and can only run on Darwin.
  if is_mac():
    unittests += [
        # The accessibility library only supports Mac and Windows.
        make_test('accessibility_unittests'),
        make_test('flutter_channels_unittests'),
        make_test('spring_animation_unittests'),
    ]

  if is_linux():
    flow_flags = [
        '--golden-dir=%s' % GOLDEN_DIR,
        '--font-file=%s' % ROBOTO_FONT_PATH,
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
    run_engine_executable(
        build_dir,
        test,
        executable_filter,
        flags,
        coverage=coverage,
        extra_env=extra_env,
        gtest=True
    )

  if is_mac():
    # flutter_desktop_darwin_unittests uses global state that isn't handled
    # correctly by gtest-parallel.
    # https://github.com/flutter/flutter/issues/104789
    if not os.path.basename(build_dir).startswith('host_debug'):
      # Test is disabled for flaking in debug runs:
      # https://github.com/flutter/flutter/issues/127441
      run_engine_executable(
          build_dir,
          'flutter_desktop_darwin_unittests',
          executable_filter,
          shuffle_flags,
          coverage=coverage
      )
    extra_env = {
        # pylint: disable=line-too-long
        # See https://developer.apple.com/documentation/metal/diagnosing_metal_programming_issues_early?language=objc
        'MTL_SHADER_VALIDATION': '1',  # Enables all shader validation tests.
        'MTL_SHADER_VALIDATION_GLOBAL_MEMORY':
            '1',  # Validates accesses to device and constant memory.
        'MTL_SHADER_VALIDATION_THREADGROUP_MEMORY':
            '1',  # Validates accesses to threadgroup memory.
        'MTL_SHADER_VALIDATION_TEXTURE_USAGE':
            '1',  # Validates that texture references are not nil.
        'VK_ICD_FILENAMES': os.path.join(build_dir, 'vk_swiftshader_icd.json'),
    }
    if is_aarm64():
      extra_env.update({
          'METAL_DEBUG_ERROR_MODE': '0',  # Enables metal validation.
          'METAL_DEVICE_WRAPPER_TYPE': '1',  # Enables metal validation.
      })
    # Impeller tests are only supported on macOS for now.
    run_engine_executable(
        build_dir,
        'impeller_unittests',
        executable_filter,
        shuffle_flags,
        coverage=coverage,
        extra_env=extra_env,
        # TODO(117122): Remove this allowlist.
        # https://github.com/flutter/flutter/issues/114872
        allowed_failure_output=[
            '[MTLCompiler createVertexStageAndLinkPipelineWithFragment:',
            '[MTLCompiler pipelineStateWithVariant:',
        ]
    )


def parse_impeller_vulkan_filter():
  test_status_path = os.path.join(SCRIPT_DIR, 'impeller_vulkan_test_status.csv')
  gtest_filter = '--gtest_filter="'
  with open(test_status_path, 'r') as csvfile:
    csvreader = csv.reader(csvfile)
    next(csvreader)  # Skip header.
    for row in csvreader:
      if row[1] == 'pass':
        gtest_filter += '*%s:' % row[0]
  gtest_filter += '"'
  return gtest_filter


def run_engine_benchmarks(build_dir, executable_filter):
  print('Running Engine Benchmarks.')

  icu_flags = [
      '--icu-data-file-path=%s' % os.path.join(build_dir, 'icudtl.dat')
  ]

  run_engine_executable(
      build_dir, 'shell_benchmarks', executable_filter, icu_flags
  )

  run_engine_executable(
      build_dir, 'fml_benchmarks', executable_filter, icu_flags
  )

  run_engine_executable(
      build_dir, 'ui_benchmarks', executable_filter, icu_flags
  )

  run_engine_executable(
      build_dir, 'display_list_builder_benchmarks', executable_filter, icu_flags
  )

  run_engine_executable(
      build_dir, 'geometry_benchmarks', executable_filter, icu_flags
  )

  if is_linux():
    run_engine_executable(
        build_dir, 'txt_benchmarks', executable_filter, icu_flags
    )


def gather_dart_test(
    build_dir,
    dart_file,
    multithreaded,
    enable_observatory=False,
    expect_failure=False,
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
      '// FlutterTesterOptions=(.*)', dart_file_contents.read()
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


def ensure_ios_tests_are_built(ios_out_dir):
  """Builds the engine variant and the test dylib containing the XCTests"""
  tmp_out_dir = os.path.join(OUT_DIR, ios_out_dir)
  ios_test_lib = os.path.join(tmp_out_dir, 'libios_test_flutter.dylib')
  message = []
  message.append(
      'gn --ios --unoptimized --runtime-mode=debug --no-lto --simulator'
  )
  message.append('ninja -C %s ios_test_flutter' % ios_out_dir)
  final_message = "%s or %s doesn't exist. Please run the following commands: \n%s" % (
      ios_out_dir, ios_test_lib, '\n'.join(message)
  )
  assert os.path.exists(tmp_out_dir
                       ) and os.path.exists(ios_test_lib), final_message

  ios_test_lib_time = os.path.getmtime(ios_test_lib)
  flutter_dylib = os.path.join(tmp_out_dir, 'libFlutter.dylib')
  flutter_dylib_time = os.path.getmtime(flutter_dylib)

  final_message = '%s is older than %s. Please run the following commands: \n%s' % (
      ios_test_lib, flutter_dylib, '\n'.join(message)
  )
  assert flutter_dylib_time <= ios_test_lib_time, final_message


def assert_expected_xcode_version():
  """Checks that the user has a version of Xcode installed"""
  version_output = subprocess.check_output(['xcodebuild', '-version'])
  # TODO ricardoamador: remove this check when python 2 is deprecated.
  version_output = version_output if isinstance(
      version_output, str
  ) else version_output.decode(ENCODING)
  version_output = version_output.strip()
  match = re.match(r'Xcode (\d+)', version_output)
  message = 'Xcode must be installed to run the iOS embedding unit tests'
  assert match, message


def java_home():
  script_path = os.path.dirname(os.path.realpath(__file__))
  if is_mac():
    return os.path.join(
        script_path, '..', '..', 'third_party', 'java', 'openjdk', 'Contents',
        'Home'
    )
  return os.path.join(script_path, '..', '..', 'third_party', 'java', 'openjdk')


def java_bin():
  return os.path.join(
      java_home(), 'bin', 'java.exe' if is_windows() else 'java'
  )


def run_java_tests(executable_filter, android_variant='android_debug_unopt'):
  """Runs the Java JUnit unit tests for the Android embedding"""
  test_runner_dir = os.path.join(
      BUILDROOT_DIR, 'flutter', 'shell', 'platform', 'android', 'test_runner'
  )
  gradle_bin = os.path.join(
      BUILDROOT_DIR, 'third_party', 'gradle', 'bin',
      'gradle.bat' if is_windows() else 'gradle'
  )
  flutter_jar = os.path.join(OUT_DIR, android_variant, 'flutter.jar')
  android_home = os.path.join(
      BUILDROOT_DIR, 'third_party', 'android_tools', 'sdk'
  )
  build_dir = os.path.join(
      OUT_DIR, android_variant, 'robolectric_tests', 'build'
  )
  gradle_cache_dir = os.path.join(
      OUT_DIR, android_variant, 'robolectric_tests', '.gradle'
  )

  test_class = executable_filter if executable_filter else '*'
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

  env = dict(os.environ, ANDROID_HOME=android_home, JAVA_HOME=java_home())
  run_cmd(command, cwd=test_runner_dir, env=env)


def run_android_tests(android_variant='android_debug_unopt', adb_path=None):
  test_runner_name = 'flutter_shell_native_unittests'
  tests_path = os.path.join(OUT_DIR, android_variant, test_runner_name)
  remote_path = '/data/local/tmp'
  remote_tests_path = os.path.join(remote_path, test_runner_name)
  if adb_path is None:
    adb_path = 'adb'
  run_cmd([adb_path, 'push', tests_path, remote_path], cwd=BUILDROOT_DIR)
  run_cmd([adb_path, 'shell', remote_tests_path])

  systrace_test = os.path.join(
      BUILDROOT_DIR, 'flutter', 'testing', 'android_systrace_test.py'
  )
  scenario_apk = os.path.join(
      OUT_DIR, android_variant, 'firebase_apks', 'scenario_app.apk'
  )
  run_cmd([
      systrace_test, '--adb-path', adb_path, '--apk-path', scenario_apk,
      '--package-name', 'dev.flutter.scenarios', '--activity-name',
      '.PlatformViewsActivity'
  ])


def run_objc_tests(ios_variant='ios_debug_sim_unopt', test_filter=None):
  """Runs Objective-C XCTest unit tests for the iOS embedding"""
  assert_expected_xcode_version()
  ios_out_dir = os.path.join(OUT_DIR, ios_variant)
  ensure_ios_tests_are_built(ios_out_dir)

  new_simulator_name = 'IosUnitTestsSimulator'

  # Delete simulators with this name in case any were leaked
  # from another test run.
  delete_simulator(new_simulator_name)

  create_simulator = [
      'xcrun '
      'simctl '
      'create '
      '%s com.apple.CoreSimulator.SimDeviceType.iPhone-11' % new_simulator_name
  ]
  run_cmd(create_simulator, shell=True)

  try:
    ios_unit_test_dir = os.path.join(
        BUILDROOT_DIR, 'flutter', 'testing', 'ios', 'IosUnitTests'
    )

    with tempfile.TemporaryDirectory(suffix='ios_embedding_xcresult'
                                    ) as result_bundle_temp:
      result_bundle_path = os.path.join(result_bundle_temp, 'ios_embedding')

      # Avoid using xcpretty unless the following can be addressed:
      # - Make sure all relevant failure output is printed on a failure.
      # - Make sure that a failing exit code is set for CI.
      # See https://github.com/flutter/flutter/issues/63742
      test_command = [
          'xcodebuild '
          '-sdk iphonesimulator '
          '-scheme IosUnitTests '
          '-resultBundlePath ' + result_bundle_path + ' '
          '-destination name=' + new_simulator_name + ' '
          'test '
          'FLUTTER_ENGINE=' + ios_variant
      ]
      if test_filter is not None:
        test_command[0] = test_command[0] + ' -only-testing:%s' % test_filter
      try:
        run_cmd(test_command, cwd=ios_unit_test_dir, shell=True)

      except:
        # The LUCI environment may provide a variable containing a directory path
        # for additional output files that will be uploaded to cloud storage.
        # Upload the xcresult when the tests fail.
        luci_test_outputs_path = os.environ.get('FLUTTER_TEST_OUTPUTS_DIR')
        xcresult_bundle = os.path.join(
            result_bundle_temp, 'ios_embedding.xcresult'
        )
        if luci_test_outputs_path and os.path.exists(xcresult_bundle):
          dump_path = os.path.join(
              luci_test_outputs_path, 'ios_embedding.xcresult'
          )
          # xcresults contain many little files. Archive the bundle before upload.
          shutil.make_archive(dump_path, 'zip', root_dir=xcresult_bundle)
        raise

  finally:
    delete_simulator(new_simulator_name)


def delete_simulator(simulator_name):
  # Will delete all simulators with this name.
  command = [
      'xcrun',
      'simctl',
      'delete',
      simulator_name,
  ]
  # Let this fail if the simulator was never created.
  run_cmd(command, expect_failure=True)


def gather_dart_tests(build_dir, test_filter):
  dart_tests_dir = os.path.join(
      BUILDROOT_DIR,
      'flutter',
      'testing',
      'dart',
  )

  # Now that we have the Sky packages at the hardcoded location, run `dart pub get`.
  run_engine_executable(
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

  if 'release' not in build_dir:
    for dart_test_file in dart_observatory_tests:
      if test_filter is not None and os.path.basename(dart_test_file
                                                     ) not in test_filter:
        print("Skipping '%s' due to filter." % dart_test_file)
      else:
        print(
            "Gathering dart test '%s' with observatory enabled" % dart_test_file
        )
        yield gather_dart_test(build_dir, dart_test_file, True, True)
        yield gather_dart_test(build_dir, dart_test_file, False, True)

  for dart_test_file in dart_tests:
    if test_filter is not None and os.path.basename(dart_test_file
                                                   ) not in test_filter:
      print("Skipping '%s' due to filter." % dart_test_file)
    else:
      print("Gathering dart test '%s'" % dart_test_file)
      yield gather_dart_test(build_dir, dart_test_file, True)
      yield gather_dart_test(build_dir, dart_test_file, False)


def gather_dart_smoke_test(build_dir):
  smoke_test = os.path.join(
      BUILDROOT_DIR, 'flutter', 'testing', 'smoke_test_failure',
      'fail_test.dart'
  )
  yield gather_dart_test(build_dir, smoke_test, True, expect_failure=True)
  yield gather_dart_test(build_dir, smoke_test, False, expect_failure=True)


def gather_front_end_server_tests(build_dir):
  test_dir = os.path.join(BUILDROOT_DIR, 'flutter', 'flutter_frontend_server')
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


def gather_path_ops_tests(build_dir):
  # TODO(dnfield): https://github.com/flutter/flutter/issues/107321
  if is_asan(build_dir):
    return

  test_dir = os.path.join(
      BUILDROOT_DIR, 'flutter', 'tools', 'path_ops', 'dart', 'test'
  )
  opts = ['--disable-dart-dev', os.path.join(test_dir, 'path_ops_test.dart')]
  yield EngineExecutableTask(
      build_dir,
      os.path.join('dart-sdk', 'bin', 'dart'),
      None,
      flags=opts,
      cwd=test_dir
  )


def gather_const_finder_tests(build_dir):
  test_dir = os.path.join(
      BUILDROOT_DIR, 'flutter', 'tools', 'const_finder', 'test'
  )
  opts = [
      '--disable-dart-dev',
      os.path.join(test_dir, 'const_finder_test.dart'),
      os.path.join(build_dir, 'gen', 'frontend_server.dart.snapshot'),
      os.path.join(build_dir, 'flutter_patched_sdk'),
      os.path.join(build_dir, 'dart-sdk', 'lib', 'libraries.json')
  ]
  yield EngineExecutableTask(
      build_dir,
      os.path.join('dart-sdk', 'bin', 'dart'),
      None,
      flags=opts,
      cwd=test_dir
  )


def gather_litetest_tests(build_dir):
  test_dir = os.path.join(BUILDROOT_DIR, 'flutter', 'testing', 'litetest')
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


def run_benchmark_tests(build_dir):
  test_dir = os.path.join(BUILDROOT_DIR, 'flutter', 'testing', 'benchmark')
  dart_tests = glob.glob('%s/test/*_test.dart' % test_dir)
  for dart_test_file in dart_tests:
    opts = ['--disable-dart-dev', dart_test_file]
    run_engine_executable(
        build_dir,
        os.path.join('dart-sdk', 'bin', 'dart'),
        None,
        flags=opts,
        cwd=test_dir
    )


def gather_githooks_tests(build_dir):
  test_dir = os.path.join(BUILDROOT_DIR, 'flutter', 'tools', 'githooks')
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


def gather_clang_tidy_tests(build_dir):
  test_dir = os.path.join(BUILDROOT_DIR, 'flutter', 'tools', 'clang_tidy')
  dart_tests = glob.glob('%s/test/*_test.dart' % test_dir)
  for dart_test_file in dart_tests:
    opts = [
        '--disable-dart-dev', dart_test_file,
        os.path.join(build_dir, 'compile_commands.json'),
        os.path.join(BUILDROOT_DIR, 'flutter')
    ]
    yield EngineExecutableTask(
        build_dir,
        os.path.join('dart-sdk', 'bin', 'dart'),
        None,
        flags=opts,
        cwd=test_dir
    )


def gather_api_consistency_tests(build_dir):
  test_dir = os.path.join(BUILDROOT_DIR, 'flutter', 'tools', 'api_check')
  dart_tests = glob.glob('%s/test/*_test.dart' % test_dir)
  for dart_test_file in dart_tests:
    opts = [
        '--disable-dart-dev', dart_test_file,
        os.path.join(BUILDROOT_DIR, 'flutter')
    ]
    yield EngineExecutableTask(
        build_dir,
        os.path.join('dart-sdk', 'bin', 'dart'),
        None,
        flags=opts,
        cwd=test_dir
    )


def run_engine_tasks_in_parallel(tasks):
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
    except Exception as exn:  # pylint: disable=broad-except
      failures += [(task, exn)]

  if len(failures) > 0:
    print('The following commands failed:')
    for task, exn in failures:
      print('%s\n%s\n' % (str(task), str(exn)))
    raise Exception()


class DirectoryChange():
  """
  A scoped change in the CWD.
  """
  old_cwd: str = ''
  new_cwd: str = ''

  def __init__(self, new_cwd: str):
    self.new_cwd = new_cwd

  def __enter__(self):
    self.old_cwd = os.getcwd()
    os.chdir(self.new_cwd)

  def __exit__(self, exception_type, exception_value, exception_traceback):
    os.chdir(self.old_cwd)


def run_impeller_golden_tests(build_dir: str):
  """
  Executes the impeller golden image tests from in the `variant` build.
  """
  tests_path: str = os.path.join(build_dir, 'impeller_golden_tests')
  if not os.path.exists(tests_path):
    raise Exception(
        'Cannot find the "impeller_golden_tests" executable in "%s". You may need to build it.'
        % (build_dir)
    )
  harvester_path: Path = Path(SCRIPT_DIR).parent.joinpath('impeller').joinpath(
      'golden_tests_harvester'
  )
  with tempfile.TemporaryDirectory(prefix='impeller_golden') as temp_dir:
    run_cmd([tests_path, '--working_dir=%s' % temp_dir])
    with DirectoryChange(harvester_path):
      run_cmd(['dart', 'pub', 'get'])
      bin_path = Path('.').joinpath('bin'
                                   ).joinpath('golden_tests_harvester.dart')
      run_cmd(['dart', 'run', str(bin_path), temp_dir])


def main():
  parser = argparse.ArgumentParser(
      description="""
In order to learn the details of running tests in the engine, please consult the
Flutter Wiki page on the subject: https://github.com/flutter/flutter/wiki/Testing-the-engine
"""
  )
  all_types = [
      'engine',
      'dart',
      'benchmarks',
      'java',
      'android',
      'objc',
      'font-subset',
      'impeller-golden',
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
      help=(
          'Filter parameter for which objc tests to run '
          '(example: "IosUnitTestsTests/SemanticsObjectTest/testShouldTriggerAnnouncement")'
      )
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

  build_dir = os.path.join(OUT_DIR, args.variant)
  if args.type != 'java' and args.type != 'android':
    assert os.path.exists(
        build_dir
    ), 'Build variant directory %s does not exist!' % build_dir

  if args.sanitizer_suppressions:
    assert is_linux() or is_mac(
    ), 'The sanitizer suppressions flag is only supported on Linux and Mac.'
    file_dir = os.path.dirname(os.path.abspath(__file__))
    command = [
        'env', '-i', 'bash', '-c',
        'source {}/sanitizer_suppressions.sh >/dev/null && env'
        .format(file_dir)
    ]
    process = subprocess.Popen(command, stdout=subprocess.PIPE)
    for line in process.stdout:
      key, _, value = line.decode('utf8').strip().partition('=')
      os.environ[key] = value
    process.communicate()  # Avoid pipe deadlock while waiting for termination.

  engine_filter = args.engine_filter.split(',') if args.engine_filter else None
  if 'engine' in types:
    run_cc_tests(
        build_dir, engine_filter, args.coverage, args.engine_capture_core_dump
    )

  # Use this type to exclusively run impeller vulkan tests.
  # TODO (https://github.com/flutter/flutter/issues/113961): Remove this once
  # impeller vulkan tests are stable.
  if 'impeller-vulkan' in types:
    build_name = args.variant
    try:
      xvfb.start_virtual_x(build_name, build_dir)
      vulkan_gtest_filter = parse_impeller_vulkan_filter()
      gtest_flags = shuffle_flags
      gtest_flags.append(vulkan_gtest_filter)
      run_engine_executable(
          build_dir,
          'impeller_unittests',
          engine_filter,
          gtest_flags,
          coverage=args.coverage
      )
    finally:
      xvfb.stop_virtual_x(build_name)

  if 'dart' in types:
    dart_filter = args.dart_filter.split(',') if args.dart_filter else None
    tasks = list(gather_dart_smoke_test(build_dir))
    tasks += list(gather_litetest_tests(build_dir))
    tasks += list(gather_githooks_tests(build_dir))
    tasks += list(gather_clang_tidy_tests(build_dir))
    tasks += list(gather_api_consistency_tests(build_dir))
    tasks += list(gather_path_ops_tests(build_dir))
    tasks += list(gather_const_finder_tests(build_dir))
    tasks += list(gather_front_end_server_tests(build_dir))
    tasks += list(gather_dart_tests(build_dir, dart_filter))
    run_engine_tasks_in_parallel(tasks)

  if 'java' in types:
    assert not is_windows(
    ), "Android engine files can't be compiled on Windows."
    java_filter = args.java_filter
    if ',' in java_filter or '*' in java_filter:
      print(
          'Can only filter JUnit4 tests by single entire class name, '
          'eg "io.flutter.SmokeTest". Ignoring filter=' + java_filter
      )
      java_filter = None
    run_java_tests(java_filter, args.android_variant)

  if 'android' in types:
    assert not is_windows(
    ), "Android engine files can't be compiled on Windows."
    run_android_tests(args.android_variant, args.adb_path)

  if 'objc' in types:
    assert is_mac(), 'iOS embedding tests can only be run on macOS.'
    run_objc_tests(args.ios_variant, args.objc_filter)

  # https://github.com/flutter/flutter/issues/36300
  if 'benchmarks' in types and not is_windows():
    run_benchmark_tests(build_dir)
    run_engine_benchmarks(build_dir, engine_filter)

  variants_to_skip = ['host_release', 'host_profile']
  if ('engine' in types or
      'font-subset' in types) and args.variant not in variants_to_skip:
    run_cmd(['python3', 'test.py'], cwd=FONT_SUBSET_DIR)

  if 'impeller-golden' in types:
    run_impeller_golden_tests(build_dir)


if __name__ == '__main__':
  sys.exit(main())
