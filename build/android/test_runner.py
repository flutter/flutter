#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Runs all types of tests from one unified interface."""

import argparse
import collections
import logging
import os
import shutil
import signal
import sys
import threading
import unittest

from pylib import constants
from pylib import forwarder
from pylib import ports
from pylib.base import base_test_result
from pylib.base import environment_factory
from pylib.base import test_dispatcher
from pylib.base import test_instance_factory
from pylib.base import test_run_factory
from pylib.device import device_errors
from pylib.device import device_utils
from pylib.gtest import gtest_config
# TODO(jbudorick): Remove this once we stop selectively enabling platform mode.
from pylib.gtest import gtest_test_instance
from pylib.gtest import setup as gtest_setup
from pylib.gtest import test_options as gtest_test_options
from pylib.linker import setup as linker_setup
from pylib.host_driven import setup as host_driven_setup
from pylib.instrumentation import setup as instrumentation_setup
from pylib.instrumentation import test_options as instrumentation_test_options
from pylib.junit import setup as junit_setup
from pylib.junit import test_dispatcher as junit_dispatcher
from pylib.monkey import setup as monkey_setup
from pylib.monkey import test_options as monkey_test_options
from pylib.perf import setup as perf_setup
from pylib.perf import test_options as perf_test_options
from pylib.perf import test_runner as perf_test_runner
from pylib.results import json_results
from pylib.results import report_results
from pylib.uiautomator import setup as uiautomator_setup
from pylib.uiautomator import test_options as uiautomator_test_options
from pylib.utils import apk_helper
from pylib.utils import base_error
from pylib.utils import reraiser_thread
from pylib.utils import run_tests_helper


def AddCommonOptions(parser):
  """Adds all common options to |parser|."""

  group = parser.add_argument_group('Common Options')

  default_build_type = os.environ.get('BUILDTYPE', 'Debug')

  debug_or_release_group = group.add_mutually_exclusive_group()
  debug_or_release_group.add_argument(
      '--debug', action='store_const', const='Debug', dest='build_type',
      default=default_build_type,
      help=('If set, run test suites under out/Debug. '
            'Default is env var BUILDTYPE or Debug.'))
  debug_or_release_group.add_argument(
      '--release', action='store_const', const='Release', dest='build_type',
      help=('If set, run test suites under out/Release. '
            'Default is env var BUILDTYPE or Debug.'))

  group.add_argument('--build-directory', dest='build_directory',
                     help=('Path to the directory in which build files are'
                           ' located (should not include build type)'))
  group.add_argument('--output-directory', dest='output_directory',
                     help=('Path to the directory in which build files are'
                           ' located (must include build type). This will take'
                           ' precedence over --debug, --release and'
                           ' --build-directory'))
  group.add_argument('--num_retries', dest='num_retries', type=int, default=2,
                     help=('Number of retries for a test before '
                           'giving up (default: %(default)s).'))
  group.add_argument('-v',
                     '--verbose',
                     dest='verbose_count',
                     default=0,
                     action='count',
                     help='Verbose level (multiple times for more)')
  group.add_argument('--flakiness-dashboard-server',
                     dest='flakiness_dashboard_server',
                     help=('Address of the server that is hosting the '
                           'Chrome for Android flakiness dashboard.'))
  group.add_argument('--enable-platform-mode', action='store_true',
                     help=('Run the test scripts in platform mode, which '
                           'conceptually separates the test runner from the '
                           '"device" (local or remote, real or emulated) on '
                           'which the tests are running. [experimental]'))
  group.add_argument('-e', '--environment', default='local',
                     choices=constants.VALID_ENVIRONMENTS,
                     help='Test environment to run in (default: %(default)s).')
  group.add_argument('--adb-path',
                     help=('Specify the absolute path of the adb binary that '
                           'should be used.'))
  group.add_argument('--json-results-file', dest='json_results_file',
                     help='If set, will dump results in JSON form '
                          'to specified file.')

def ProcessCommonOptions(args):
  """Processes and handles all common options."""
  run_tests_helper.SetLogLevel(args.verbose_count)
  constants.SetBuildType(args.build_type)
  if args.build_directory:
    constants.SetBuildDirectory(args.build_directory)
  if args.output_directory:
    constants.SetOutputDirectory(args.output_directory)
  if args.adb_path:
    constants.SetAdbPath(args.adb_path)
  # Some things such as Forwarder require ADB to be in the environment path.
  adb_dir = os.path.dirname(constants.GetAdbPath())
  if adb_dir and adb_dir not in os.environ['PATH'].split(os.pathsep):
    os.environ['PATH'] = adb_dir + os.pathsep + os.environ['PATH']


def AddRemoteDeviceOptions(parser):
  group = parser.add_argument_group('Remote Device Options')

  group.add_argument('--trigger',
                     help=('Only triggers the test if set. Stores test_run_id '
                           'in given file path. '))
  group.add_argument('--collect',
                     help=('Only collects the test results if set. '
                           'Gets test_run_id from given file path.'))
  group.add_argument('--remote-device', action='append',
                     help='Device type to run test on.')
  group.add_argument('--results-path',
                     help='File path to download results to.')
  group.add_argument('--api-protocol',
                     help='HTTP protocol to use. (http or https)')
  group.add_argument('--api-address',
                     help='Address to send HTTP requests.')
  group.add_argument('--api-port',
                     help='Port to send HTTP requests to.')
  group.add_argument('--runner-type',
                     help='Type of test to run as.')
  group.add_argument('--runner-package',
                     help='Package name of test.')
  group.add_argument('--device-type',
                     choices=constants.VALID_DEVICE_TYPES,
                     help=('Type of device to run on. iOS or android'))
  group.add_argument('--device-oem', action='append',
                     help='Device OEM to run on.')
  group.add_argument('--remote-device-file',
                     help=('File with JSON to select remote device. '
                           'Overrides all other flags.'))
  group.add_argument('--remote-device-timeout', type=int,
                     help='Times to retry finding remote device')
  group.add_argument('--network-config', type=int,
                     help='Integer that specifies the network environment '
                          'that the tests will be run in.')

  device_os_group = group.add_mutually_exclusive_group()
  device_os_group.add_argument('--remote-device-minimum-os',
                               help='Minimum OS on device.')
  device_os_group.add_argument('--remote-device-os', action='append',
                               help='OS to have on the device.')

  api_secret_group = group.add_mutually_exclusive_group()
  api_secret_group.add_argument('--api-secret', default='',
                                help='API secret for remote devices.')
  api_secret_group.add_argument('--api-secret-file', default='',
                                help='Path to file that contains API secret.')

  api_key_group = group.add_mutually_exclusive_group()
  api_key_group.add_argument('--api-key', default='',
                             help='API key for remote devices.')
  api_key_group.add_argument('--api-key-file', default='',
                             help='Path to file that contains API key.')


def AddDeviceOptions(parser):
  """Adds device options to |parser|."""
  group = parser.add_argument_group(title='Device Options')
  group.add_argument('--tool',
                     dest='tool',
                     help=('Run the test under a tool '
                           '(use --tool help to list them)'))
  group.add_argument('-d', '--device', dest='test_device',
                     help=('Target device for the test suite '
                           'to run on.'))


def AddGTestOptions(parser):
  """Adds gtest options to |parser|."""

  gtest_suites = list(gtest_config.STABLE_TEST_SUITES
                      + gtest_config.EXPERIMENTAL_TEST_SUITES)

  group = parser.add_argument_group('GTest Options')
  group.add_argument('-s', '--suite', dest='suite_name',
                     nargs='+', metavar='SUITE_NAME', required=True,
                     help=('Executable name of the test suite to run. '
                           'Available suites include (but are not limited to): '
                            '%s' % ', '.join('"%s"' % s for s in gtest_suites)))
  group.add_argument('--gtest_also_run_disabled_tests',
                     '--gtest-also-run-disabled-tests',
                     dest='run_disabled', action='store_true',
                     help='Also run disabled tests if applicable.')
  group.add_argument('-a', '--test-arguments', dest='test_arguments',
                     default='',
                     help='Additional arguments to pass to the test.')
  group.add_argument('-t', dest='timeout', type=int, default=60,
                     help='Timeout to wait for each test '
                          '(default: %(default)s).')
  group.add_argument('--isolate_file_path',
                     '--isolate-file-path',
                     dest='isolate_file_path',
                     help='.isolate file path to override the default '
                          'path')
  group.add_argument('--app-data-file', action='append', dest='app_data_files',
                     help='A file path relative to the app data directory '
                          'that should be saved to the host.')
  group.add_argument('--app-data-file-dir',
                     help='Host directory to which app data files will be'
                          ' saved. Used with --app-data-file.')
  group.add_argument('--delete-stale-data', dest='delete_stale_data',
                     action='store_true',
                     help='Delete stale test data on the device.')

  filter_group = group.add_mutually_exclusive_group()
  filter_group.add_argument('-f', '--gtest_filter', '--gtest-filter',
                            dest='test_filter',
                            help='googletest-style filter string.')
  filter_group.add_argument('--gtest-filter-file', dest='test_filter_file',
                            help='Path to file that contains googletest-style '
                                  'filter strings. (Lines will be joined with '
                                  '":" to create a single filter string.)')

  AddDeviceOptions(parser)
  AddCommonOptions(parser)
  AddRemoteDeviceOptions(parser)


def AddLinkerTestOptions(parser):
  group = parser.add_argument_group('Linker Test Options')
  group.add_argument('-f', '--gtest-filter', dest='test_filter',
                     help='googletest-style filter string.')
  AddCommonOptions(parser)
  AddDeviceOptions(parser)


def AddJavaTestOptions(argument_group):
  """Adds the Java test options to |option_parser|."""

  argument_group.add_argument(
      '-f', '--test-filter', dest='test_filter',
      help=('Test filter (if not fully qualified, will run all matches).'))
  argument_group.add_argument(
      '-A', '--annotation', dest='annotation_str',
      help=('Comma-separated list of annotations. Run only tests with any of '
            'the given annotations. An annotation can be either a key or a '
            'key-values pair. A test that has no annotation is considered '
            '"SmallTest".'))
  argument_group.add_argument(
      '-E', '--exclude-annotation', dest='exclude_annotation_str',
      help=('Comma-separated list of annotations. Exclude tests with these '
            'annotations.'))
  argument_group.add_argument(
      '--screenshot', dest='screenshot_failures', action='store_true',
      help='Capture screenshots of test failures')
  argument_group.add_argument(
      '--save-perf-json', action='store_true',
      help='Saves the JSON file for each UI Perf test.')
  argument_group.add_argument(
      '--official-build', action='store_true', help='Run official build tests.')
  argument_group.add_argument(
      '--test_data', '--test-data', action='append', default=[],
      help=('Each instance defines a directory of test data that should be '
            'copied to the target(s) before running the tests. The argument '
            'should be of the form <target>:<source>, <target> is relative to '
            'the device data directory, and <source> is relative to the '
            'chromium build directory.'))
  argument_group.add_argument(
      '--disable-dalvik-asserts', dest='set_asserts', action='store_false',
      default=True, help='Removes the dalvik.vm.enableassertions property')



def ProcessJavaTestOptions(args):
  """Processes options/arguments and populates |options| with defaults."""

  # TODO(jbudorick): Handle most of this function in argparse.
  if args.annotation_str:
    args.annotations = args.annotation_str.split(',')
  elif args.test_filter:
    args.annotations = []
  else:
    args.annotations = ['Smoke', 'SmallTest', 'MediumTest', 'LargeTest',
                        'EnormousTest', 'IntegrationTest']

  if args.exclude_annotation_str:
    args.exclude_annotations = args.exclude_annotation_str.split(',')
  else:
    args.exclude_annotations = []


def AddInstrumentationTestOptions(parser):
  """Adds Instrumentation test options to |parser|."""

  parser.usage = '%(prog)s [options]'

  group = parser.add_argument_group('Instrumentation Test Options')
  AddJavaTestOptions(group)

  java_or_python_group = group.add_mutually_exclusive_group()
  java_or_python_group.add_argument(
      '-j', '--java-only', action='store_false',
      dest='run_python_tests', default=True, help='Run only the Java tests.')
  java_or_python_group.add_argument(
      '-p', '--python-only', action='store_false',
      dest='run_java_tests', default=True,
      help='Run only the host-driven tests.')

  group.add_argument('--host-driven-root',
                     help='Root of the host-driven tests.')
  group.add_argument('-w', '--wait_debugger', dest='wait_for_debugger',
                     action='store_true',
                     help='Wait for debugger.')
  group.add_argument('--apk-under-test', dest='apk_under_test',
                     help=('the name of the apk under test.'))
  group.add_argument('--test-apk', dest='test_apk', required=True,
                     help=('The name of the apk containing the tests '
                           '(without the .apk extension; '
                           'e.g. "ContentShellTest").'))
  group.add_argument('--coverage-dir',
                     help=('Directory in which to place all generated '
                           'EMMA coverage files.'))
  group.add_argument('--device-flags', dest='device_flags', default='',
                     help='The relative filepath to a file containing '
                          'command-line flags to set on the device')
  group.add_argument('--device-flags-file', default='',
                     help='The relative filepath to a file containing '
                          'command-line flags to set on the device')
  group.add_argument('--isolate_file_path',
                     '--isolate-file-path',
                     dest='isolate_file_path',
                     help='.isolate file path to override the default '
                          'path')
  group.add_argument('--delete-stale-data', dest='delete_stale_data',
                     action='store_true',
                     help='Delete stale test data on the device.')

  AddCommonOptions(parser)
  AddDeviceOptions(parser)
  AddRemoteDeviceOptions(parser)


def ProcessInstrumentationOptions(args):
  """Processes options/arguments and populate |options| with defaults.

  Args:
    args: argparse.Namespace object.

  Returns:
    An InstrumentationOptions named tuple which contains all options relevant to
    instrumentation tests.
  """

  ProcessJavaTestOptions(args)

  if not args.host_driven_root:
    args.run_python_tests = False

  args.test_apk_path = os.path.join(
      constants.GetOutDirectory(),
      constants.SDK_BUILD_APKS_DIR,
      '%s.apk' % args.test_apk)
  args.test_apk_jar_path = os.path.join(
      constants.GetOutDirectory(),
      constants.SDK_BUILD_TEST_JAVALIB_DIR,
      '%s.jar' %  args.test_apk)
  args.test_support_apk_path = '%sSupport%s' % (
      os.path.splitext(args.test_apk_path))

  args.test_runner = apk_helper.GetInstrumentationName(args.test_apk_path)

  # TODO(jbudorick): Get rid of InstrumentationOptions.
  return instrumentation_test_options.InstrumentationOptions(
      args.tool,
      args.annotations,
      args.exclude_annotations,
      args.test_filter,
      args.test_data,
      args.save_perf_json,
      args.screenshot_failures,
      args.wait_for_debugger,
      args.coverage_dir,
      args.test_apk,
      args.test_apk_path,
      args.test_apk_jar_path,
      args.test_runner,
      args.test_support_apk_path,
      args.device_flags,
      args.isolate_file_path,
      args.set_asserts,
      args.delete_stale_data
      )


def AddUIAutomatorTestOptions(parser):
  """Adds UI Automator test options to |parser|."""

  group = parser.add_argument_group('UIAutomator Test Options')
  AddJavaTestOptions(group)
  group.add_argument(
      '--package', required=True, choices=constants.PACKAGE_INFO.keys(),
      metavar='PACKAGE', help='Package under test.')
  group.add_argument(
      '--test-jar', dest='test_jar', required=True,
      help=('The name of the dexed jar containing the tests (without the '
            '.dex.jar extension). Alternatively, this can be a full path '
            'to the jar.'))

  AddCommonOptions(parser)
  AddDeviceOptions(parser)


def ProcessUIAutomatorOptions(args):
  """Processes UIAutomator options/arguments.

  Args:
    args: argparse.Namespace object.

  Returns:
    A UIAutomatorOptions named tuple which contains all options relevant to
    uiautomator tests.
  """

  ProcessJavaTestOptions(args)

  if os.path.exists(args.test_jar):
    # The dexed JAR is fully qualified, assume the info JAR lives along side.
    args.uiautomator_jar = args.test_jar
  else:
    args.uiautomator_jar = os.path.join(
        constants.GetOutDirectory(),
        constants.SDK_BUILD_JAVALIB_DIR,
        '%s.dex.jar' % args.test_jar)
  args.uiautomator_info_jar = (
      args.uiautomator_jar[:args.uiautomator_jar.find('.dex.jar')] +
      '_java.jar')

  return uiautomator_test_options.UIAutomatorOptions(
      args.tool,
      args.annotations,
      args.exclude_annotations,
      args.test_filter,
      args.test_data,
      args.save_perf_json,
      args.screenshot_failures,
      args.uiautomator_jar,
      args.uiautomator_info_jar,
      args.package,
      args.set_asserts)


def AddJUnitTestOptions(parser):
  """Adds junit test options to |parser|."""

  group = parser.add_argument_group('JUnit Test Options')
  group.add_argument(
      '-s', '--test-suite', dest='test_suite', required=True,
      help=('JUnit test suite to run.'))
  group.add_argument(
      '-f', '--test-filter', dest='test_filter',
      help='Filters tests googletest-style.')
  group.add_argument(
      '--package-filter', dest='package_filter',
      help='Filters tests by package.')
  group.add_argument(
      '--runner-filter', dest='runner_filter',
      help='Filters tests by runner class. Must be fully qualified.')
  group.add_argument(
      '--sdk-version', dest='sdk_version', type=int,
      help='The Android SDK version.')
  AddCommonOptions(parser)


def AddMonkeyTestOptions(parser):
  """Adds monkey test options to |parser|."""

  group = parser.add_argument_group('Monkey Test Options')
  group.add_argument(
      '--package', required=True, choices=constants.PACKAGE_INFO.keys(),
      metavar='PACKAGE', help='Package under test.')
  group.add_argument(
      '--event-count', default=10000, type=int,
      help='Number of events to generate (default: %(default)s).')
  group.add_argument(
      '--category', default='',
      help='A list of allowed categories.')
  group.add_argument(
      '--throttle', default=100, type=int,
      help='Delay between events (ms) (default: %(default)s). ')
  group.add_argument(
      '--seed', type=int,
      help=('Seed value for pseudo-random generator. Same seed value generates '
            'the same sequence of events. Seed is randomized by default.'))
  group.add_argument(
      '--extra-args', default='',
      help=('String of other args to pass to the command verbatim.'))

  AddCommonOptions(parser)
  AddDeviceOptions(parser)

def ProcessMonkeyTestOptions(args):
  """Processes all monkey test options.

  Args:
    args: argparse.Namespace object.

  Returns:
    A MonkeyOptions named tuple which contains all options relevant to
    monkey tests.
  """
  # TODO(jbudorick): Handle this directly in argparse with nargs='+'
  category = args.category
  if category:
    category = args.category.split(',')

  # TODO(jbudorick): Get rid of MonkeyOptions.
  return monkey_test_options.MonkeyOptions(
      args.verbose_count,
      args.package,
      args.event_count,
      category,
      args.throttle,
      args.seed,
      args.extra_args)

def AddUirobotTestOptions(parser):
  """Adds uirobot test options to |option_parser|."""
  group = parser.add_argument_group('Uirobot Test Options')

  group.add_argument('--app-under-test', required=True,
                     help='APK to run tests on.')
  group.add_argument(
      '--minutes', default=5, type=int,
      help='Number of minutes to run uirobot test [default: %(default)s].')

  AddCommonOptions(parser)
  AddDeviceOptions(parser)
  AddRemoteDeviceOptions(parser)

def AddPerfTestOptions(parser):
  """Adds perf test options to |parser|."""

  group = parser.add_argument_group('Perf Test Options')

  class SingleStepAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
      if values and not namespace.single_step:
        parser.error('single step command provided, '
                     'but --single-step not specified.')
      elif namespace.single_step and not values:
        parser.error('--single-step specified, '
                     'but no single step command provided.')
      setattr(namespace, self.dest, values)

  step_group = group.add_mutually_exclusive_group(required=True)
  # TODO(jbudorick): Revise --single-step to use argparse.REMAINDER.
  # This requires removing "--" from client calls.
  step_group.add_argument(
      '--single-step', action='store_true',
      help='Execute the given command with retries, but only print the result '
           'for the "most successful" round.')
  step_group.add_argument(
      '--steps',
      help='JSON file containing the list of commands to run.')
  step_group.add_argument(
      '--print-step',
      help='The name of a previously executed perf step to print.')

  group.add_argument(
      '--output-json-list',
      help='Write a simple list of names from --steps into the given file.')
  group.add_argument(
      '--collect-chartjson-data',
      action='store_true',
      help='Cache the chartjson output from each step for later use.')
  group.add_argument(
      '--output-chartjson-data',
      default='',
      help='Write out chartjson into the given file.')
  group.add_argument(
      '--flaky-steps',
      help=('A JSON file containing steps that are flaky '
            'and will have its exit code ignored.'))
  group.add_argument(
      '--no-timeout', action='store_true',
      help=('Do not impose a timeout. Each perf step is responsible for '
            'implementing the timeout logic.'))
  group.add_argument(
      '-f', '--test-filter',
      help=('Test filter (will match against the names listed in --steps).'))
  group.add_argument(
      '--dry-run', action='store_true',
      help='Just print the steps without executing.')
  # Uses 0.1 degrees C because that's what Android does.
  group.add_argument(
      '--max-battery-temp', type=int,
      help='Only start tests when the battery is at or below the given '
           'temperature (0.1 C)')
  group.add_argument('single_step_command', nargs='*', action=SingleStepAction,
                     help='If --single-step is specified, the command to run.')
  AddCommonOptions(parser)
  AddDeviceOptions(parser)


def ProcessPerfTestOptions(args):
  """Processes all perf test options.

  Args:
    args: argparse.Namespace object.

  Returns:
    A PerfOptions named tuple which contains all options relevant to
    perf tests.
  """
  # TODO(jbudorick): Move single_step handling down into the perf tests.
  if args.single_step:
    args.single_step = ' '.join(args.single_step_command)
  # TODO(jbudorick): Get rid of PerfOptions.
  return perf_test_options.PerfOptions(
      args.steps, args.flaky_steps, args.output_json_list,
      args.print_step, args.no_timeout, args.test_filter,
      args.dry_run, args.single_step, args.collect_chartjson_data,
      args.output_chartjson_data, args.max_battery_temp)


def AddPythonTestOptions(parser):
  group = parser.add_argument_group('Python Test Options')
  group.add_argument(
      '-s', '--suite', dest='suite_name', metavar='SUITE_NAME',
      choices=constants.PYTHON_UNIT_TEST_SUITES.keys(),
      help='Name of the test suite to run.')
  AddCommonOptions(parser)


def _RunGTests(args, devices):
  """Subcommand of RunTestsCommands which runs gtests."""
  exit_code = 0
  for suite_name in args.suite_name:
    # TODO(jbudorick): Either deprecate multi-suite or move its handling down
    # into the gtest code.
    gtest_options = gtest_test_options.GTestOptions(
        args.tool,
        args.test_filter,
        args.run_disabled,
        args.test_arguments,
        args.timeout,
        args.isolate_file_path,
        suite_name,
        args.app_data_files,
        args.app_data_file_dir,
        args.delete_stale_data)
    runner_factory, tests = gtest_setup.Setup(gtest_options, devices)

    results, test_exit_code = test_dispatcher.RunTests(
        tests, runner_factory, devices, shard=True, test_timeout=None,
        num_retries=args.num_retries)

    if test_exit_code and exit_code != constants.ERROR_EXIT_CODE:
      exit_code = test_exit_code

    report_results.LogFull(
        results=results,
        test_type='Unit test',
        test_package=suite_name,
        flakiness_server=args.flakiness_dashboard_server)

    if args.json_results_file:
      json_results.GenerateJsonResultsFile(results, args.json_results_file)

  return exit_code


def _RunLinkerTests(args, devices):
  """Subcommand of RunTestsCommands which runs linker tests."""
  runner_factory, tests = linker_setup.Setup(args, devices)

  results, exit_code = test_dispatcher.RunTests(
      tests, runner_factory, devices, shard=True, test_timeout=60,
      num_retries=args.num_retries)

  report_results.LogFull(
      results=results,
      test_type='Linker test',
      test_package='ChromiumLinkerTest')

  if args.json_results_file:
    json_results.GenerateJsonResultsFile(results, args.json_results_file)

  return exit_code


def _RunInstrumentationTests(args, devices):
  """Subcommand of RunTestsCommands which runs instrumentation tests."""
  logging.info('_RunInstrumentationTests(%s, %s)' % (str(args), str(devices)))

  instrumentation_options = ProcessInstrumentationOptions(args)

  if len(devices) > 1 and args.wait_for_debugger:
    logging.warning('Debugger can not be sharded, using first available device')
    devices = devices[:1]

  results = base_test_result.TestRunResults()
  exit_code = 0

  if args.run_java_tests:
    runner_factory, tests = instrumentation_setup.Setup(
        instrumentation_options, devices)

    test_results, exit_code = test_dispatcher.RunTests(
        tests, runner_factory, devices, shard=True, test_timeout=None,
        num_retries=args.num_retries)

    results.AddTestRunResults(test_results)

  if args.run_python_tests:
    runner_factory, tests = host_driven_setup.InstrumentationSetup(
        args.host_driven_root, args.official_build,
        instrumentation_options)

    if tests:
      test_results, test_exit_code = test_dispatcher.RunTests(
          tests, runner_factory, devices, shard=True, test_timeout=None,
          num_retries=args.num_retries)

      results.AddTestRunResults(test_results)

      # Only allow exit code escalation
      if test_exit_code and exit_code != constants.ERROR_EXIT_CODE:
        exit_code = test_exit_code

  if args.device_flags:
    args.device_flags = os.path.join(constants.DIR_SOURCE_ROOT,
                                     args.device_flags)

  report_results.LogFull(
      results=results,
      test_type='Instrumentation',
      test_package=os.path.basename(args.test_apk),
      annotation=args.annotations,
      flakiness_server=args.flakiness_dashboard_server)

  if args.json_results_file:
    json_results.GenerateJsonResultsFile(results, args.json_results_file)

  return exit_code


def _RunUIAutomatorTests(args, devices):
  """Subcommand of RunTestsCommands which runs uiautomator tests."""
  uiautomator_options = ProcessUIAutomatorOptions(args)

  runner_factory, tests = uiautomator_setup.Setup(uiautomator_options)

  results, exit_code = test_dispatcher.RunTests(
      tests, runner_factory, devices, shard=True, test_timeout=None,
      num_retries=args.num_retries)

  report_results.LogFull(
      results=results,
      test_type='UIAutomator',
      test_package=os.path.basename(args.test_jar),
      annotation=args.annotations,
      flakiness_server=args.flakiness_dashboard_server)

  if args.json_results_file:
    json_results.GenerateJsonResultsFile(results, args.json_results_file)

  return exit_code


def _RunJUnitTests(args):
  """Subcommand of RunTestsCommand which runs junit tests."""
  runner_factory, tests = junit_setup.Setup(args)
  results, exit_code = junit_dispatcher.RunTests(tests, runner_factory)

  report_results.LogFull(
      results=results,
      test_type='JUnit',
      test_package=args.test_suite)

  if args.json_results_file:
    json_results.GenerateJsonResultsFile(results, args.json_results_file)

  return exit_code


def _RunMonkeyTests(args, devices):
  """Subcommand of RunTestsCommands which runs monkey tests."""
  monkey_options = ProcessMonkeyTestOptions(args)

  runner_factory, tests = monkey_setup.Setup(monkey_options)

  results, exit_code = test_dispatcher.RunTests(
      tests, runner_factory, devices, shard=False, test_timeout=None,
      num_retries=args.num_retries)

  report_results.LogFull(
      results=results,
      test_type='Monkey',
      test_package='Monkey')

  if args.json_results_file:
    json_results.GenerateJsonResultsFile(results, args.json_results_file)

  return exit_code


def _RunPerfTests(args):
  """Subcommand of RunTestsCommands which runs perf tests."""
  perf_options = ProcessPerfTestOptions(args)

  # Just save a simple json with a list of test names.
  if perf_options.output_json_list:
    return perf_test_runner.OutputJsonList(
        perf_options.steps, perf_options.output_json_list)

  # Just print the results from a single previously executed step.
  if perf_options.print_step:
    return perf_test_runner.PrintTestOutput(
        perf_options.print_step, perf_options.output_chartjson_data)

  runner_factory, tests, devices = perf_setup.Setup(perf_options)

  # shard=False means that each device will get the full list of tests
  # and then each one will decide their own affinity.
  # shard=True means each device will pop the next test available from a queue,
  # which increases throughput but have no affinity.
  results, _ = test_dispatcher.RunTests(
      tests, runner_factory, devices, shard=False, test_timeout=None,
      num_retries=args.num_retries)

  report_results.LogFull(
      results=results,
      test_type='Perf',
      test_package='Perf')

  if args.json_results_file:
    json_results.GenerateJsonResultsFile(results, args.json_results_file)

  if perf_options.single_step:
    return perf_test_runner.PrintTestOutput('single_step')

  perf_test_runner.PrintSummary(tests)

  # Always return 0 on the sharding stage. Individual tests exit_code
  # will be returned on the print_step stage.
  return 0


def _RunPythonTests(args):
  """Subcommand of RunTestsCommand which runs python unit tests."""
  suite_vars = constants.PYTHON_UNIT_TEST_SUITES[args.suite_name]
  suite_path = suite_vars['path']
  suite_test_modules = suite_vars['test_modules']

  sys.path = [suite_path] + sys.path
  try:
    suite = unittest.TestSuite()
    suite.addTests(unittest.defaultTestLoader.loadTestsFromName(m)
                   for m in suite_test_modules)
    runner = unittest.TextTestRunner(verbosity=1+args.verbose_count)
    return 0 if runner.run(suite).wasSuccessful() else 1
  finally:
    sys.path = sys.path[1:]


def _GetAttachedDevices(test_device=None):
  """Get all attached devices.

  Args:
    test_device: Name of a specific device to use.

  Returns:
    A list of attached devices.
  """
  attached_devices = device_utils.DeviceUtils.HealthyDevices()
  if test_device:
    test_device = [d for d in attached_devices if d == test_device]
    if not test_device:
      raise device_errors.DeviceUnreachableError(
          'Did not find device %s among attached device. Attached devices: %s'
          % (test_device, ', '.join(attached_devices)))
    return test_device

  else:
    if not attached_devices:
      raise device_errors.NoDevicesError()
    return sorted(attached_devices)


def RunTestsCommand(args, parser):
  """Checks test type and dispatches to the appropriate function.

  Args:
    args: argparse.Namespace object.
    parser: argparse.ArgumentParser object.

  Returns:
    Integer indicated exit code.

  Raises:
    Exception: Unknown command name passed in, or an exception from an
        individual test runner.
  """
  command = args.command

  ProcessCommonOptions(args)

  if args.enable_platform_mode:
    return RunTestsInPlatformMode(args, parser)

  if command in constants.LOCAL_MACHINE_TESTS:
    devices = []
  else:
    devices = _GetAttachedDevices(args.test_device)

  forwarder.Forwarder.RemoveHostLog()
  if not ports.ResetTestServerPortAllocation():
    raise Exception('Failed to reset test server port.')

  if command == 'gtest':
    if args.suite_name[0] in gtest_test_instance.BROWSER_TEST_SUITES:
      return RunTestsInPlatformMode(args, parser)
    return _RunGTests(args, devices)
  elif command == 'linker':
    return _RunLinkerTests(args, devices)
  elif command == 'instrumentation':
    return _RunInstrumentationTests(args, devices)
  elif command == 'uiautomator':
    return _RunUIAutomatorTests(args, devices)
  elif command == 'junit':
    return _RunJUnitTests(args)
  elif command == 'monkey':
    return _RunMonkeyTests(args, devices)
  elif command == 'perf':
    return _RunPerfTests(args)
  elif command == 'python':
    return _RunPythonTests(args)
  else:
    raise Exception('Unknown test type.')


_SUPPORTED_IN_PLATFORM_MODE = [
  # TODO(jbudorick): Add support for more test types.
  'gtest',
  'instrumentation',
  'uirobot',
]


def RunTestsInPlatformMode(args, parser):

  if args.command not in _SUPPORTED_IN_PLATFORM_MODE:
    parser.error('%s is not yet supported in platform mode' % args.command)

  with environment_factory.CreateEnvironment(args, parser.error) as env:
    with test_instance_factory.CreateTestInstance(args, parser.error) as test:
      with test_run_factory.CreateTestRun(
          args, env, test, parser.error) as test_run:
        results = test_run.RunTests()

        if args.environment == 'remote_device' and args.trigger:
          return 0 # Not returning results, only triggering.

        report_results.LogFull(
            results=results,
            test_type=test.TestType(),
            test_package=test_run.TestPackage(),
            annotation=getattr(args, 'annotations', None),
            flakiness_server=getattr(args, 'flakiness_dashboard_server', None))

        if args.json_results_file:
          json_results.GenerateJsonResultsFile(
              results, args.json_results_file)

  return 0 if results.DidRunPass() else constants.ERROR_EXIT_CODE


CommandConfigTuple = collections.namedtuple(
    'CommandConfigTuple',
    ['add_options_func', 'help_txt'])
VALID_COMMANDS = {
    'gtest': CommandConfigTuple(
        AddGTestOptions,
        'googletest-based C++ tests'),
    'instrumentation': CommandConfigTuple(
        AddInstrumentationTestOptions,
        'InstrumentationTestCase-based Java tests'),
    'uiautomator': CommandConfigTuple(
        AddUIAutomatorTestOptions,
        "Tests that run via Android's uiautomator command"),
    'junit': CommandConfigTuple(
        AddJUnitTestOptions,
        'JUnit4-based Java tests'),
    'monkey': CommandConfigTuple(
        AddMonkeyTestOptions,
        "Tests based on Android's monkey"),
    'perf': CommandConfigTuple(
        AddPerfTestOptions,
        'Performance tests'),
    'python': CommandConfigTuple(
        AddPythonTestOptions,
        'Python tests based on unittest.TestCase'),
    'linker': CommandConfigTuple(
        AddLinkerTestOptions,
        'Linker tests'),
    'uirobot': CommandConfigTuple(
        AddUirobotTestOptions,
        'Uirobot test'),
}


def DumpThreadStacks(_signal, _frame):
  for thread in threading.enumerate():
    reraiser_thread.LogThreadStack(thread)


def main():
  signal.signal(signal.SIGUSR1, DumpThreadStacks)

  parser = argparse.ArgumentParser()
  command_parsers = parser.add_subparsers(title='test types',
                                          dest='command')

  for test_type, config in sorted(VALID_COMMANDS.iteritems(),
                                  key=lambda x: x[0]):
    subparser = command_parsers.add_parser(
        test_type, usage='%(prog)s [options]', help=config.help_txt)
    config.add_options_func(subparser)

  args = parser.parse_args()

  try:
    return RunTestsCommand(args, parser)
  except base_error.BaseError as e:
    logging.exception('Error occurred.')
    if e.is_infra_error:
      return constants.INFRA_EXIT_CODE
    return constants.ERROR_EXIT_CODE
  except: # pylint: disable=W0702
    logging.exception('Unrecognized error occurred.')
    return constants.ERROR_EXIT_CODE


if __name__ == '__main__':
  sys.exit(main())
