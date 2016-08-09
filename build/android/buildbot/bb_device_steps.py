#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import collections
import glob
import hashlib
import json
import os
import random
import re
import shutil
import sys

import bb_utils
import bb_annotations

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
import provision_devices
from pylib import constants
from pylib.device import device_utils
from pylib.gtest import gtest_config

CHROME_SRC_DIR = bb_utils.CHROME_SRC
DIR_BUILD_ROOT = os.path.dirname(CHROME_SRC_DIR)
CHROME_OUT_DIR = bb_utils.CHROME_OUT_DIR
BLINK_SCRIPTS_DIR = 'third_party/WebKit/Tools/Scripts'

SLAVE_SCRIPTS_DIR = os.path.join(bb_utils.BB_BUILD_DIR, 'scripts', 'slave')
LOGCAT_DIR = os.path.join(bb_utils.CHROME_OUT_DIR, 'logcat')
GS_URL = 'https://storage.googleapis.com'
GS_AUTH_URL = 'https://storage.cloud.google.com'

# Describes an instrumation test suite:
#   test: Name of test we're running.
#   apk: apk to be installed.
#   apk_package: package for the apk to be installed.
#   test_apk: apk to run tests on.
#   test_data: data folder in format destination:source.
#   host_driven_root: The host-driven test root directory.
#   annotation: Annotation of the tests to include.
#   exclude_annotation: The annotation of the tests to exclude.
I_TEST = collections.namedtuple('InstrumentationTest', [
    'name', 'apk', 'apk_package', 'test_apk', 'test_data', 'isolate_file_path',
    'host_driven_root', 'annotation', 'exclude_annotation', 'extra_flags'])


def SrcPath(*path):
  return os.path.join(CHROME_SRC_DIR, *path)


def I(name, apk, apk_package, test_apk, test_data, isolate_file_path=None,
      host_driven_root=None, annotation=None, exclude_annotation=None,
      extra_flags=None):
  return I_TEST(name, apk, apk_package, test_apk, test_data, isolate_file_path,
                host_driven_root, annotation, exclude_annotation, extra_flags)

INSTRUMENTATION_TESTS = dict((suite.name, suite) for suite in [
    I('ContentShell',
      'ContentShell.apk',
      'org.chromium.content_shell_apk',
      'ContentShellTest',
      'content:content/test/data/android/device_files',
      isolate_file_path='content/content_shell_test_apk.isolate'),
    I('ChromeShell',
      'ChromeShell.apk',
      'org.chromium.chrome.shell',
      'ChromeShellTest',
      'chrome:chrome/test/data/android/device_files',
      isolate_file_path='chrome/chrome_shell_test_apk.isolate',
      host_driven_root=constants.CHROME_SHELL_HOST_DRIVEN_DIR),
    I('AndroidWebView',
      'AndroidWebView.apk',
      'org.chromium.android_webview.shell',
      'AndroidWebViewTest',
      'webview:android_webview/test/data/device_files',
      isolate_file_path='android_webview/android_webview_test_apk.isolate'),
    I('ChromeSyncShell',
      'ChromeSyncShell.apk',
      'org.chromium.chrome.browser.sync',
      'ChromeSyncShellTest',
      None),
    ])

InstallablePackage = collections.namedtuple('InstallablePackage', [
    'name', 'apk', 'apk_package'])

INSTALLABLE_PACKAGES = dict((package.name, package) for package in (
    [InstallablePackage(i.name, i.apk, i.apk_package)
     for i in INSTRUMENTATION_TESTS.itervalues()] +
    [InstallablePackage('ChromeDriverWebViewShell',
                        'ChromeDriverWebViewShell.apk',
                        'org.chromium.chromedriver_webview_shell')]))

VALID_TESTS = set([
    'base_junit_tests',
    'chromedriver',
    'chrome_proxy',
    'components_browsertests',
    'gfx_unittests',
    'gl_unittests',
    'gpu',
    'python_unittests',
    'telemetry_unittests',
    'telemetry_perf_unittests',
    'ui',
    'unit',
    'webkit',
    'webkit_layout'
])

RunCmd = bb_utils.RunCmd


def _GetRevision(options):
  """Get the SVN revision number.

  Args:
    options: options object.

  Returns:
    The revision number.
  """
  revision = options.build_properties.get('got_revision')
  if not revision:
    revision = options.build_properties.get('revision', 'testing')
  return revision


def _RunTest(options, cmd, suite):
  """Run test command with runtest.py.

  Args:
    options: options object.
    cmd: the command to run.
    suite: test name.
  """
  property_args = bb_utils.EncodeProperties(options)
  args = [os.path.join(SLAVE_SCRIPTS_DIR, 'runtest.py')] + property_args
  args += ['--test-platform', 'android']
  if options.factory_properties.get('generate_gtest_json'):
    args.append('--generate-json-file')
    args += ['-o', 'gtest-results/%s' % suite,
             '--annotate', 'gtest',
             '--build-number', str(options.build_properties.get('buildnumber',
                                                                '')),
             '--builder-name', options.build_properties.get('buildername', '')]
  if options.target == 'Release':
    args += ['--target', 'Release']
  else:
    args += ['--target', 'Debug']
  if options.flakiness_server:
    args += ['--flakiness-dashboard-server=%s' %
                options.flakiness_server]
  args += cmd
  RunCmd(args, cwd=DIR_BUILD_ROOT)


def RunTestSuites(options, suites, suites_options=None):
  """Manages an invocation of test_runner.py for gtests.

  Args:
    options: options object.
    suites: List of suite names to run.
    suites_options: Command line options dictionary for particular suites.
                    For example,
                    {'content_browsertests', ['--num_retries=1', '--release']}
                    will add the options only to content_browsertests.
  """

  if not suites_options:
    suites_options = {}

  args = ['--verbose']
  if options.target == 'Release':
    args.append('--release')
  if options.asan:
    args.append('--tool=asan')
  if options.gtest_filter:
    args.append('--gtest-filter=%s' % options.gtest_filter)

  for suite in suites:
    bb_annotations.PrintNamedStep(suite)
    cmd = [suite] + args
    cmd += suites_options.get(suite, [])
    if suite == 'content_browsertests' or suite == 'components_browsertests':
      cmd.append('--num_retries=1')
    _RunTest(options, cmd, suite)


def RunJunitSuite(suite):
  bb_annotations.PrintNamedStep(suite)
  RunCmd(['build/android/test_runner.py', 'junit', '-s', suite])


def RunChromeDriverTests(options):
  """Run all the steps for running chromedriver tests."""
  bb_annotations.PrintNamedStep('chromedriver_annotation')
  RunCmd(['chrome/test/chromedriver/run_buildbot_steps.py',
          '--android-packages=%s,%s,%s,%s' %
          ('chrome_shell',
           'chrome_stable',
           'chrome_beta',
           'chromedriver_webview_shell'),
          '--revision=%s' % _GetRevision(options),
          '--update-log'])

def RunChromeProxyTests(options):
  """Run the chrome_proxy tests.

  Args:
    options: options object.
  """
  InstallApk(options, INSTRUMENTATION_TESTS['ChromeShell'], False)
  args = ['--browser', 'android-chrome-shell']
  devices = device_utils.DeviceUtils.HealthyDevices()
  if devices:
    args = args + ['--device', devices[0].adb.GetDeviceSerial()]
  bb_annotations.PrintNamedStep('chrome_proxy')
  RunCmd(['tools/chrome_proxy/run_tests'] + args)


def RunTelemetryTests(options, step_name, run_tests_path):
  """Runs either telemetry_perf_unittests or telemetry_unittests.

  Args:
    options: options object.
    step_name: either 'telemetry_unittests' or 'telemetry_perf_unittests'
    run_tests_path: path to run_tests script (tools/perf/run_tests for
                    perf_unittests and tools/telemetry/run_tests for
                    telemetry_unittests)
  """
  InstallApk(options, INSTRUMENTATION_TESTS['ChromeShell'], False)
  args = ['--browser', 'android-chrome-shell']
  devices = device_utils.DeviceUtils.HealthyDevices()
  if devices:
    args = args + ['--device', 'android']
  bb_annotations.PrintNamedStep(step_name)
  RunCmd([run_tests_path] + args)


def InstallApk(options, test, print_step=False):
  """Install an apk to all phones.

  Args:
    options: options object
    test: An I_TEST namedtuple
    print_step: Print a buildbot step
  """
  if print_step:
    bb_annotations.PrintNamedStep('install_%s' % test.name.lower())

  args = ['--apk_package', test.apk_package]
  if options.target == 'Release':
    args.append('--release')
  args.append(test.apk)

  RunCmd(['build/android/adb_install_apk.py'] + args, halt_on_failure=True)


def RunInstrumentationSuite(options, test, flunk_on_failure=True,
                            python_only=False, official_build=False):
  """Manages an invocation of test_runner.py for instrumentation tests.

  Args:
    options: options object
    test: An I_TEST namedtuple
    flunk_on_failure: Flunk the step if tests fail.
    Python: Run only host driven Python tests.
    official_build: Run official-build tests.
  """
  bb_annotations.PrintNamedStep('%s_instrumentation_tests' % test.name.lower())

  if test.apk:
    InstallApk(options, test)
  args = ['--test-apk', test.test_apk, '--verbose']
  if test.test_data:
    args.extend(['--test_data', test.test_data])
  if options.target == 'Release':
    args.append('--release')
  if options.asan:
    args.append('--tool=asan')
  if options.flakiness_server:
    args.append('--flakiness-dashboard-server=%s' %
                options.flakiness_server)
  if options.coverage_bucket:
    args.append('--coverage-dir=%s' % options.coverage_dir)
  if test.isolate_file_path:
    args.append('--isolate-file-path=%s' % test.isolate_file_path)
  if test.host_driven_root:
    args.append('--host-driven-root=%s' % test.host_driven_root)
  if test.annotation:
    args.extend(['-A', test.annotation])
  if test.exclude_annotation:
    args.extend(['-E', test.exclude_annotation])
  if test.extra_flags:
    args.extend(test.extra_flags)
  if python_only:
    args.append('-p')
  if official_build:
    # The option needs to be assigned 'True' as it does not have an action
    # associated with it.
    args.append('--official-build')

  RunCmd(['build/android/test_runner.py', 'instrumentation'] + args,
         flunk_on_failure=flunk_on_failure)


def RunWebkitLint():
  """Lint WebKit's TestExpectation files."""
  bb_annotations.PrintNamedStep('webkit_lint')
  RunCmd([SrcPath(os.path.join(BLINK_SCRIPTS_DIR, 'lint-test-expectations'))])


def RunWebkitLayoutTests(options):
  """Run layout tests on an actual device."""
  bb_annotations.PrintNamedStep('webkit_tests')
  cmd_args = [
      '--no-show-results',
      '--no-new-test-results',
      '--full-results-html',
      '--clobber-old-results',
      '--exit-after-n-failures', '5000',
      '--exit-after-n-crashes-or-timeouts', '100',
      '--debug-rwt-logging',
      '--results-directory', '../layout-test-results',
      '--target', options.target,
      '--builder-name', options.build_properties.get('buildername', ''),
      '--build-number', str(options.build_properties.get('buildnumber', '')),
      '--master-name', 'ChromiumWebkit',  # TODO: Get this from the cfg.
      '--build-name', options.build_properties.get('buildername', ''),
      '--platform=android']

  for flag in 'test_results_server', 'driver_name', 'additional_driver_flag':
    if flag in options.factory_properties:
      cmd_args.extend(['--%s' % flag.replace('_', '-'),
                       options.factory_properties.get(flag)])

  for f in options.factory_properties.get('additional_expectations', []):
    cmd_args.extend(
        ['--additional-expectations=%s' % os.path.join(CHROME_SRC_DIR, *f)])

  # TODO(dpranke): Remove this block after
  # https://codereview.chromium.org/12927002/ lands.
  for f in options.factory_properties.get('additional_expectations_files', []):
    cmd_args.extend(
        ['--additional-expectations=%s' % os.path.join(CHROME_SRC_DIR, *f)])

  exit_code = RunCmd(
      [SrcPath(os.path.join(BLINK_SCRIPTS_DIR, 'run-webkit-tests'))] + cmd_args)
  if exit_code == 255: # test_run_results.UNEXPECTED_ERROR_EXIT_STATUS
    bb_annotations.PrintMsg('?? (crashed or hung)')
  elif exit_code == 254: # test_run_results.NO_DEVICES_EXIT_STATUS
    bb_annotations.PrintMsg('?? (no devices found)')
  elif exit_code == 253: # test_run_results.NO_TESTS_EXIT_STATUS
    bb_annotations.PrintMsg('?? (no tests found)')
  else:
    full_results_path = os.path.join('..', 'layout-test-results',
                                     'full_results.json')
    if os.path.exists(full_results_path):
      full_results = json.load(open(full_results_path))
      unexpected_passes, unexpected_failures, unexpected_flakes = (
          _ParseLayoutTestResults(full_results))
      if unexpected_failures:
        _PrintDashboardLink('failed', unexpected_failures.keys(),
                            max_tests=25)
      elif unexpected_passes:
        _PrintDashboardLink('unexpected passes', unexpected_passes.keys(),
                            max_tests=10)
      if unexpected_flakes:
        _PrintDashboardLink('unexpected flakes', unexpected_flakes.keys(),
                            max_tests=10)

      if exit_code == 0 and (unexpected_passes or unexpected_flakes):
        # If exit_code != 0, RunCmd() will have already printed an error.
        bb_annotations.PrintWarning()
    else:
      bb_annotations.PrintError()
      bb_annotations.PrintMsg('?? (results missing)')

  if options.factory_properties.get('archive_webkit_results', False):
    bb_annotations.PrintNamedStep('archive_webkit_results')
    base = 'https://storage.googleapis.com/chromium-layout-test-archives'
    builder_name = options.build_properties.get('buildername', '')
    build_number = str(options.build_properties.get('buildnumber', ''))
    results_link = '%s/%s/%s/layout-test-results/results.html' % (
        base, EscapeBuilderName(builder_name), build_number)
    bb_annotations.PrintLink('results', results_link)
    bb_annotations.PrintLink('(zip)', '%s/%s/%s/layout-test-results.zip' % (
        base, EscapeBuilderName(builder_name), build_number))
    gs_bucket = 'gs://chromium-layout-test-archives'
    RunCmd([os.path.join(SLAVE_SCRIPTS_DIR, 'chromium',
                         'archive_layout_test_results.py'),
            '--results-dir', '../../layout-test-results',
            '--build-number', build_number,
            '--builder-name', builder_name,
            '--gs-bucket', gs_bucket],
            cwd=DIR_BUILD_ROOT)


def _ParseLayoutTestResults(results):
  """Extract the failures from the test run."""
  # Cloned from third_party/WebKit/Tools/Scripts/print-json-test-results
  tests = _ConvertTrieToFlatPaths(results['tests'])
  failures = {}
  flakes = {}
  passes = {}
  for (test, result) in tests.iteritems():
    if result.get('is_unexpected'):
      actual_results = result['actual'].split()
      expected_results = result['expected'].split()
      if len(actual_results) > 1:
        # We report the first failure type back, even if the second
        # was more severe.
        if actual_results[1] in expected_results:
          flakes[test] = actual_results[0]
        else:
          failures[test] = actual_results[0]
      elif actual_results[0] == 'PASS':
        passes[test] = result
      else:
        failures[test] = actual_results[0]

  return (passes, failures, flakes)


def _ConvertTrieToFlatPaths(trie, prefix=None):
  """Flatten the trie of failures into a list."""
  # Cloned from third_party/WebKit/Tools/Scripts/print-json-test-results
  result = {}
  for name, data in trie.iteritems():
    if prefix:
      name = prefix + '/' + name

    if len(data) and 'actual' not in data and 'expected' not in data:
      result.update(_ConvertTrieToFlatPaths(data, name))
    else:
      result[name] = data

  return result


def _PrintDashboardLink(link_text, tests, max_tests):
  """Add a link to the flakiness dashboard in the step annotations."""
  if len(tests) > max_tests:
    test_list_text = ' '.join(tests[:max_tests]) + ' and more'
  else:
    test_list_text = ' '.join(tests)

  dashboard_base = ('http://test-results.appspot.com'
                    '/dashboards/flakiness_dashboard.html#'
                    'master=ChromiumWebkit&tests=')

  bb_annotations.PrintLink('%d %s: %s' %
                           (len(tests), link_text, test_list_text),
                           dashboard_base + ','.join(tests))


def EscapeBuilderName(builder_name):
  return re.sub('[ ()]', '_', builder_name)


def SpawnLogcatMonitor():
  shutil.rmtree(LOGCAT_DIR, ignore_errors=True)
  bb_utils.SpawnCmd([
      os.path.join(CHROME_SRC_DIR, 'build', 'android', 'adb_logcat_monitor.py'),
      LOGCAT_DIR])

  # Wait for logcat_monitor to pull existing logcat
  RunCmd(['sleep', '5'])


def ProvisionDevices(options):
  bb_annotations.PrintNamedStep('provision_devices')

  if not bb_utils.TESTING:
    # Restart adb to work around bugs, sleep to wait for usb discovery.
    device_utils.RestartServer()
    RunCmd(['sleep', '1'])
  provision_cmd = ['build/android/provision_devices.py', '-t', options.target]
  if options.auto_reconnect:
    provision_cmd.append('--auto-reconnect')
  if options.skip_wipe:
    provision_cmd.append('--skip-wipe')
  if options.disable_location:
    provision_cmd.append('--disable-location')
  RunCmd(provision_cmd, halt_on_failure=True)


def DeviceStatusCheck(options):
  bb_annotations.PrintNamedStep('device_status_check')
  cmd = ['build/android/buildbot/bb_device_status_check.py']
  if options.restart_usb:
    cmd.append('--restart-usb')
  RunCmd(cmd, halt_on_failure=True)


def GetDeviceSetupStepCmds():
  return [
      ('device_status_check', DeviceStatusCheck),
      ('provision_devices', ProvisionDevices),
  ]


def RunUnitTests(options):
  suites = gtest_config.STABLE_TEST_SUITES
  if options.asan:
    suites = [s for s in suites
              if s not in gtest_config.ASAN_EXCLUDED_TEST_SUITES]
  RunTestSuites(options, suites)


def RunTelemetryUnitTests(options):
  RunTelemetryTests(options, 'telemetry_unittests', 'tools/telemetry/run_tests')


def RunTelemetryPerfUnitTests(options):
  RunTelemetryTests(options, 'telemetry_perf_unittests', 'tools/perf/run_tests')


def RunInstrumentationTests(options):
  for test in INSTRUMENTATION_TESTS.itervalues():
    RunInstrumentationSuite(options, test)


def RunWebkitTests(options):
  RunTestSuites(options, ['webkit_unit_tests', 'blink_heap_unittests'])
  RunWebkitLint()


def RunGPUTests(options):
  revision = _GetRevision(options)
  builder_name = options.build_properties.get('buildername', 'noname')

  bb_annotations.PrintNamedStep('pixel_tests')
  RunCmd(['content/test/gpu/run_gpu_test.py',
          'pixel', '-v',
          '--browser',
          'android-content-shell',
          '--build-revision',
          str(revision),
          '--upload-refimg-to-cloud-storage',
          '--refimg-cloud-storage-bucket',
          'chromium-gpu-archive/reference-images',
          '--os-type',
          'android',
          '--test-machine-name',
          EscapeBuilderName(builder_name)])

  bb_annotations.PrintNamedStep('webgl_conformance_tests')
  RunCmd(['content/test/gpu/run_gpu_test.py', '-v',
          '--browser=android-content-shell', 'webgl_conformance',
          '--webgl-conformance-version=1.0.1'])

  bb_annotations.PrintNamedStep('android_webview_webgl_conformance_tests')
  RunCmd(['content/test/gpu/run_gpu_test.py', '-v',
          '--browser=android-webview-shell', 'webgl_conformance',
          '--webgl-conformance-version=1.0.1'])

  bb_annotations.PrintNamedStep('gpu_rasterization_tests')
  RunCmd(['content/test/gpu/run_gpu_test.py',
          'gpu_rasterization', '-v',
          '--browser',
          'android-content-shell',
          '--build-revision',
          str(revision),
          '--test-machine-name',
          EscapeBuilderName(builder_name)])


def RunPythonUnitTests(_options):
  for suite in constants.PYTHON_UNIT_TEST_SUITES:
    bb_annotations.PrintNamedStep(suite)
    RunCmd(['build/android/test_runner.py', 'python', '-s', suite])


def GetTestStepCmds():
  return [
      ('base_junit_tests',
          lambda _options: RunJunitSuite('base_junit_tests')),
      ('chromedriver', RunChromeDriverTests),
      ('chrome_proxy', RunChromeProxyTests),
      ('components_browsertests',
          lambda options: RunTestSuites(options, ['components_browsertests'])),
      ('gfx_unittests',
          lambda options: RunTestSuites(options, ['gfx_unittests'])),
      ('gl_unittests',
          lambda options: RunTestSuites(options, ['gl_unittests'])),
      ('gpu', RunGPUTests),
      ('python_unittests', RunPythonUnitTests),
      ('telemetry_unittests', RunTelemetryUnitTests),
      ('telemetry_perf_unittests', RunTelemetryPerfUnitTests),
      ('ui', RunInstrumentationTests),
      ('unit', RunUnitTests),
      ('webkit', RunWebkitTests),
      ('webkit_layout', RunWebkitLayoutTests),
  ]


def MakeGSPath(options, gs_base_dir):
  revision = _GetRevision(options)
  bot_id = options.build_properties.get('buildername', 'testing')
  randhash = hashlib.sha1(str(random.random())).hexdigest()
  gs_path = '%s/%s/%s/%s' % (gs_base_dir, bot_id, revision, randhash)
  # remove double slashes, happens with blank revisions and confuses gsutil
  gs_path = re.sub('/+', '/', gs_path)
  return gs_path

def UploadHTML(options, gs_base_dir, dir_to_upload, link_text,
               link_rel_path='index.html', gs_url=GS_URL):
  """Uploads directory at |dir_to_upload| to Google Storage and output a link.

  Args:
    options: Command line options.
    gs_base_dir: The Google Storage base directory (e.g.
      'chromium-code-coverage/java')
    dir_to_upload: Absolute path to the directory to be uploaded.
    link_text: Link text to be displayed on the step.
    link_rel_path: Link path relative to |dir_to_upload|.
    gs_url: Google storage URL.
  """
  gs_path = MakeGSPath(options, gs_base_dir)
  RunCmd([bb_utils.GSUTIL_PATH, 'cp', '-R', dir_to_upload, 'gs://%s' % gs_path])
  bb_annotations.PrintLink(link_text,
                           '%s/%s/%s' % (gs_url, gs_path, link_rel_path))


def GenerateJavaCoverageReport(options):
  """Generates an HTML coverage report using EMMA and uploads it."""
  bb_annotations.PrintNamedStep('java_coverage_report')

  coverage_html = os.path.join(options.coverage_dir, 'coverage_html')
  RunCmd(['build/android/generate_emma_html.py',
          '--coverage-dir', options.coverage_dir,
          '--metadata-dir', os.path.join(CHROME_OUT_DIR, options.target),
          '--cleanup',
          '--output', os.path.join(coverage_html, 'index.html')])
  return coverage_html


def LogcatDump(options):
  # Print logcat, kill logcat monitor
  bb_annotations.PrintNamedStep('logcat_dump')
  logcat_file = os.path.join(CHROME_OUT_DIR, options.target, 'full_log.txt')
  RunCmd([SrcPath('build', 'android', 'adb_logcat_printer.py'),
          '--output-path', logcat_file, LOGCAT_DIR])
  gs_path = MakeGSPath(options, 'chromium-android/logcat_dumps')
  RunCmd([bb_utils.GSUTIL_PATH, 'cp', '-z', 'txt', logcat_file,
          'gs://%s' % gs_path])
  bb_annotations.PrintLink('logcat dump', '%s/%s' % (GS_AUTH_URL, gs_path))


def RunStackToolSteps(options):
  """Run stack tool steps.

  Stack tool is run for logcat dump, optionally for ASAN.
  """
  bb_annotations.PrintNamedStep('Run stack tool with logcat dump')
  logcat_file = os.path.join(CHROME_OUT_DIR, options.target, 'full_log.txt')
  RunCmd([os.path.join(CHROME_SRC_DIR, 'third_party', 'android_platform',
          'development', 'scripts', 'stack'),
          '--more-info', logcat_file])
  if options.asan_symbolize:
    bb_annotations.PrintNamedStep('Run stack tool for ASAN')
    RunCmd([
        os.path.join(CHROME_SRC_DIR, 'build', 'android', 'asan_symbolize.py'),
        '-l', logcat_file])


def GenerateTestReport(options):
  bb_annotations.PrintNamedStep('test_report')
  for report in glob.glob(
      os.path.join(CHROME_OUT_DIR, options.target, 'test_logs', '*.log')):
    RunCmd(['cat', report])
    os.remove(report)


def MainTestWrapper(options):
  try:
    # Spawn logcat monitor
    SpawnLogcatMonitor()

    # Run all device setup steps
    for _, cmd in GetDeviceSetupStepCmds():
      cmd(options)

    if options.install:
      for i in options.install:
        install_obj = INSTALLABLE_PACKAGES[i]
        InstallApk(options, install_obj, print_step=True)

    if options.test_filter:
      bb_utils.RunSteps(options.test_filter, GetTestStepCmds(), options)

    if options.coverage_bucket:
      coverage_html = GenerateJavaCoverageReport(options)
      UploadHTML(options, '%s/java' % options.coverage_bucket, coverage_html,
                 'Coverage Report')
      shutil.rmtree(coverage_html, ignore_errors=True)

    if options.experimental:
      RunTestSuites(options, gtest_config.EXPERIMENTAL_TEST_SUITES)

  finally:
    # Run all post test steps
    LogcatDump(options)
    if not options.disable_stack_tool:
      RunStackToolSteps(options)
    GenerateTestReport(options)
    # KillHostHeartbeat() has logic to check if heartbeat process is running,
    # and kills only if it finds the process is running on the host.
    provision_devices.KillHostHeartbeat()
    if options.cleanup:
      shutil.rmtree(os.path.join(CHROME_OUT_DIR, options.target),
          ignore_errors=True)


def GetDeviceStepsOptParser():
  parser = bb_utils.GetParser()
  parser.add_option('--experimental', action='store_true',
                    help='Run experiemental tests')
  parser.add_option('-f', '--test-filter', metavar='<filter>', default=[],
                    action='append',
                    help=('Run a test suite. Test suites: "%s"' %
                          '", "'.join(VALID_TESTS)))
  parser.add_option('--gtest-filter',
                    help='Filter for running a subset of tests of a gtest test')
  parser.add_option('--asan', action='store_true', help='Run tests with asan.')
  parser.add_option('--install', metavar='<apk name>', action="append",
                    help='Install an apk by name')
  parser.add_option('--no-reboot', action='store_true',
                    help='Do not reboot devices during provisioning.')
  parser.add_option('--coverage-bucket',
                    help=('Bucket name to store coverage results. Coverage is '
                          'only run if this is set.'))
  parser.add_option('--restart-usb', action='store_true',
                    help='Restart usb ports before device status check.')
  parser.add_option(
      '--flakiness-server',
      help=('The flakiness dashboard server to which the results should be '
            'uploaded.'))
  parser.add_option(
      '--auto-reconnect', action='store_true',
      help='Push script to device which restarts adbd on disconnections.')
  parser.add_option('--skip-wipe', action='store_true',
                    help='Do not wipe devices during provisioning.')
  parser.add_option('--disable-location', action='store_true',
                    help='Disable location settings.')
  parser.add_option(
      '--logcat-dump-output',
      help='The logcat dump output will be "tee"-ed into this file')
  # During processing perf bisects, a seperate working directory created under
  # which builds are produced. Therefore we should look for relevent output
  # file under this directory.(/b/build/slave/<slave_name>/build/bisect/src/out)
  parser.add_option(
      '--chrome-output-dir',
      help='Chrome output directory to be used while bisecting.')

  parser.add_option('--disable-stack-tool', action='store_true',
      help='Do not run stack tool.')
  parser.add_option('--asan-symbolize', action='store_true',
      help='Run stack tool for ASAN')
  parser.add_option('--cleanup', action='store_true',
      help='Delete out/<target> directory at the end of the run.')
  return parser


def main(argv):
  parser = GetDeviceStepsOptParser()
  options, args = parser.parse_args(argv[1:])

  if args:
    return sys.exit('Unused args %s' % args)

  unknown_tests = set(options.test_filter) - VALID_TESTS
  if unknown_tests:
    return sys.exit('Unknown tests %s' % list(unknown_tests))

  setattr(options, 'target', options.factory_properties.get('target', 'Debug'))

  if options.chrome_output_dir:
    global CHROME_OUT_DIR
    global LOGCAT_DIR
    CHROME_OUT_DIR = options.chrome_output_dir
    LOGCAT_DIR = os.path.join(CHROME_OUT_DIR, 'logcat')

  if options.coverage_bucket:
    setattr(options, 'coverage_dir',
            os.path.join(CHROME_OUT_DIR, options.target, 'coverage'))

  MainTestWrapper(options)


if __name__ == '__main__':
  sys.exit(main(sys.argv))
