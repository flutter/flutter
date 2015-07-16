# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Base class for linker-specific test cases.

   The custom dynamic linker can only be tested through a custom test case
   for various technical reasons:

     - It's an 'invisible feature', i.e. it doesn't expose a new API or
       behaviour, all it does is save RAM when loading native libraries.

     - Checking that it works correctly requires several things that do not
       fit the existing GTest-based and instrumentation-based tests:

         - Native test code needs to be run in both the browser and renderer
           process at the same time just after loading native libraries, in
           a completely asynchronous way.

         - Each test case requires restarting a whole new application process
           with a different command-line.

         - Enabling test support in the Linker code requires building a special
           APK with a flag to activate special test-only support code in the
           Linker code itself.

       Host-driven tests have also been tried, but since they're really
       sub-classes of instrumentation tests, they didn't work well either.

   To build and run the linker tests, do the following:

     ninja -C out/Debug chromium_linker_test_apk
     build/android/test_runner.py linker

"""
# pylint: disable=R0201

import logging
import os
import re
import time

from pylib import constants
from pylib.base import base_test_result
from pylib.device import device_errors
from pylib.device import intent


ResultType = base_test_result.ResultType

_PACKAGE_NAME = 'org.chromium.chromium_linker_test_apk'
_ACTIVITY_NAME = '.ChromiumLinkerTestActivity'
_COMMAND_LINE_FILE = '/data/local/tmp/chromium-linker-test-command-line'

# Path to the Linker.java source file.
_LINKER_JAVA_SOURCE_PATH = (
    'base/android/java/src/org/chromium/base/library_loader/Linker.java')

# A regular expression used to extract the browser shared RELRO configuration
# from the Java source file above.
_RE_LINKER_BROWSER_CONFIG = re.compile(
    r'.*BROWSER_SHARED_RELRO_CONFIG\s+=\s+' +
        r'BROWSER_SHARED_RELRO_CONFIG_(\S+)\s*;.*',
    re.MULTILINE | re.DOTALL)

# Logcat filters used during each test. Only the 'chromium' one is really
# needed, but the logs are added to the TestResult in case of error, and
# it is handy to have the 'chromium_android_linker' ones as well when
# troubleshooting.
_LOGCAT_FILTERS = ['*:s', 'chromium:v', 'chromium_android_linker:v']
#_LOGCAT_FILTERS = ['*:v']  ## DEBUG

# Regular expression used to match status lines in logcat.
_RE_BROWSER_STATUS_LINE = re.compile(r' BROWSER_LINKER_TEST: (FAIL|SUCCESS)$')
_RE_RENDERER_STATUS_LINE = re.compile(r' RENDERER_LINKER_TEST: (FAIL|SUCCESS)$')

# Regular expression used to mach library load addresses in logcat.
_RE_LIBRARY_ADDRESS = re.compile(
    r'(BROWSER|RENDERER)_LIBRARY_ADDRESS: (\S+) ([0-9A-Fa-f]+)')


def _GetBrowserSharedRelroConfig():
  """Returns a string corresponding to the Linker's configuration of shared
     RELRO sections in the browser process. This parses the Java linker source
     file to get the appropriate information.
  Return:
      None in case of error (e.g. could not locate the source file).
     'NEVER' if the browser process shall never use shared RELROs.
     'LOW_RAM_ONLY' if if uses it only on low-end devices.
     'ALWAYS' if it always uses a shared RELRO.
  """
  source_path = \
      os.path.join(constants.DIR_SOURCE_ROOT, _LINKER_JAVA_SOURCE_PATH)
  if not os.path.exists(source_path):
    logging.error('Could not find linker source file: ' + source_path)
    return None

  with open(source_path) as f:
    configs = _RE_LINKER_BROWSER_CONFIG.findall(f.read())
    if not configs:
      logging.error(
          'Can\'t find browser shared RELRO configuration value in ' + \
          source_path)
      return None

    if configs[0] not in ['NEVER', 'LOW_RAM_ONLY', 'ALWAYS']:
      logging.error('Unexpected browser config value: ' + configs[0])
      return None

    logging.info('Found linker browser shared RELRO config: ' + configs[0])
    return configs[0]


def _StartActivityAndWaitForLinkerTestStatus(device, timeout):
  """Force-start an activity and wait up to |timeout| seconds until the full
     linker test status lines appear in the logcat, recorded through |device|.
  Args:
    device: A DeviceUtils instance.
    timeout: Timeout in seconds
  Returns:
    A (status, logs) tuple, where status is a ResultType constant, and logs
    if the final logcat output as a string.
  """

  # 1. Start recording logcat with appropriate filters.
  with device.GetLogcatMonitor(filter_specs=_LOGCAT_FILTERS) as logmon:

    # 2. Force-start activity.
    device.StartActivity(
        intent.Intent(package=_PACKAGE_NAME, activity=_ACTIVITY_NAME),
        force_stop=True)

    # 3. Wait up to |timeout| seconds until the test status is in the logcat.
    result = ResultType.PASS
    try:
      browser_match = logmon.WaitFor(_RE_BROWSER_STATUS_LINE, timeout=timeout)
      logging.debug('Found browser match: %s', browser_match.group(0))
      renderer_match = logmon.WaitFor(_RE_RENDERER_STATUS_LINE,
                                      timeout=timeout)
      logging.debug('Found renderer match: %s', renderer_match.group(0))
      if (browser_match.group(1) != 'SUCCESS'
          or renderer_match.group(1) != 'SUCCESS'):
        result = ResultType.FAIL
    except device_errors.CommandTimeoutError:
      result = ResultType.TIMEOUT

    return result, '\n'.join(device.adb.Logcat(dump=True))


class LibraryLoadMap(dict):
  """A helper class to pretty-print a map of library names to load addresses."""
  def __str__(self):
    items = ['\'%s\': 0x%x' % (name, address) for \
        (name, address) in self.iteritems()]
    return '{%s}' % (', '.join(items))

  def __repr__(self):
    return 'LibraryLoadMap(%s)' % self.__str__()


class AddressList(list):
  """A helper class to pretty-print a list of load addresses."""
  def __str__(self):
    items = ['0x%x' % address for address in self]
    return '[%s]' % (', '.join(items))

  def __repr__(self):
    return 'AddressList(%s)' % self.__str__()


def _ExtractLibraryLoadAddressesFromLogcat(logs):
  """Extract the names and addresses of shared libraries loaded in the
     browser and renderer processes.
  Args:
    logs: A string containing logcat output.
  Returns:
    A tuple (browser_libs, renderer_libs), where each item is a map of
    library names (strings) to library load addresses (ints), for the
    browser and renderer processes, respectively.
  """
  browser_libs = LibraryLoadMap()
  renderer_libs = LibraryLoadMap()
  for m in _RE_LIBRARY_ADDRESS.finditer(logs):
    process_type, lib_name, lib_address = m.groups()
    lib_address = int(lib_address, 16)
    if process_type == 'BROWSER':
      browser_libs[lib_name] = lib_address
    elif process_type == 'RENDERER':
      renderer_libs[lib_name] = lib_address
    else:
      assert False, 'Invalid process type'

  return browser_libs, renderer_libs


def _CheckLoadAddressRandomization(lib_map_list, process_type):
  """Check that a map of library load addresses is random enough.
  Args:
    lib_map_list: a list of dictionaries that map library names (string)
      to load addresses (int). Each item in the list corresponds to a
      different run / process start.
    process_type: a string describing the process type.
  Returns:
    (status, logs) tuple, where <status> is True iff the load addresses are
    randomized, False otherwise, and <logs> is a string containing an error
    message detailing the libraries that are not randomized properly.
  """
  # Collect, for each library, its list of load addresses.
  lib_addr_map = {}
  for lib_map in lib_map_list:
    for lib_name, lib_address in lib_map.iteritems():
      if lib_name not in lib_addr_map:
        lib_addr_map[lib_name] = AddressList()
      lib_addr_map[lib_name].append(lib_address)

  logging.info('%s library load map: %s', process_type, lib_addr_map)

  # For each library, check the randomness of its load addresses.
  bad_libs = {}
  for lib_name, lib_address_list in lib_addr_map.iteritems():
    # If all addresses are different, skip to next item.
    lib_address_set = set(lib_address_list)
    # Consider that if there is more than one pair of identical addresses in
    # the list, then randomization is broken.
    if len(lib_address_set) < len(lib_address_list) - 1:
      bad_libs[lib_name] = lib_address_list


  if bad_libs:
    return False, '%s libraries failed randomization: %s' % \
        (process_type, bad_libs)

  return True, '%s libraries properly randomized: %s' % \
      (process_type, lib_addr_map)


class LinkerTestCaseBase(object):
  """Base class for linker test cases."""

  def __init__(self, is_low_memory=False):
    """Create a test case.
    Args:
      is_low_memory: True to simulate a low-memory device, False otherwise.
    """
    self.is_low_memory = is_low_memory
    if is_low_memory:
      test_suffix = 'ForLowMemoryDevice'
    else:
      test_suffix = 'ForRegularDevice'
    class_name = self.__class__.__name__
    self.qualified_name = '%s.%s' % (class_name, test_suffix)
    self.tagged_name = self.qualified_name

  def _RunTest(self, _device):
    """Run the test, must be overriden.
    Args:
      _device: A DeviceUtils interface.
    Returns:
      A (status, log) tuple, where <status> is a ResultType constant, and <log>
      is the logcat output captured during the test in case of error, or None
      in case of success.
    """
    return ResultType.FAIL, 'Unimplemented _RunTest() method!'

  def Run(self, device):
    """Run the test on a given device.
    Args:
      device: Name of target device where to run the test.
    Returns:
      A base_test_result.TestRunResult() instance.
    """
    margin = 8
    print '[ %-*s ] %s' % (margin, 'RUN', self.tagged_name)
    logging.info('Running linker test: %s', self.tagged_name)

    # Create command-line file on device.
    command_line_flags = ''
    if self.is_low_memory:
      command_line_flags = '--low-memory-device'
    device.WriteFile(_COMMAND_LINE_FILE, command_line_flags)

    # Run the test.
    status, logs = self._RunTest(device)

    result_text = 'OK'
    if status == ResultType.FAIL:
      result_text = 'FAILED'
    elif status == ResultType.TIMEOUT:
      result_text = 'TIMEOUT'
    print '[ %*s ] %s' % (margin, result_text, self.tagged_name)

    results = base_test_result.TestRunResults()
    results.AddResult(
        base_test_result.BaseTestResult(
            self.tagged_name,
            status,
            log=logs))

    return results

  def __str__(self):
    return self.tagged_name

  def __repr__(self):
    return self.tagged_name


class LinkerSharedRelroTest(LinkerTestCaseBase):
  """A linker test case to check the status of shared RELRO sections.

    The core of the checks performed here are pretty simple:

      - Clear the logcat and start recording with an appropriate set of filters.
      - Create the command-line appropriate for the test-case.
      - Start the activity (always forcing a cold start).
      - Every second, look at the current content of the filtered logcat lines
        and look for instances of the following:

            BROWSER_LINKER_TEST: <status>
            RENDERER_LINKER_TEST: <status>

        where <status> can be either FAIL or SUCCESS. These lines can appear
        in any order in the logcat. Once both browser and renderer status are
        found, stop the loop. Otherwise timeout after 30 seconds.

        Note that there can be other lines beginning with BROWSER_LINKER_TEST:
        and RENDERER_LINKER_TEST:, but are not followed by a <status> code.

      - The test case passes if the <status> for both the browser and renderer
        process are SUCCESS. Otherwise its a fail.
  """
  def _RunTest(self, device):
    # Wait up to 30 seconds until the linker test status is in the logcat.
    return _StartActivityAndWaitForLinkerTestStatus(device, timeout=30)


class LinkerLibraryAddressTest(LinkerTestCaseBase):
  """A test case that verifies library load addresses.

     The point of this check is to ensure that the libraries are loaded
     according to the following rules:

     - For low-memory devices, they should always be loaded at the same address
       in both browser and renderer processes, both below 0x4000_0000.

     - For regular devices, the browser process should load libraries above
       0x4000_0000, and renderer ones below it.
  """
  def _RunTest(self, device):
    result, logs = _StartActivityAndWaitForLinkerTestStatus(device, timeout=30)

    # Return immediately in case of timeout.
    if result == ResultType.TIMEOUT:
      return result, logs

    # Collect the library load addresses in the browser and renderer processes.
    browser_libs, renderer_libs = _ExtractLibraryLoadAddressesFromLogcat(logs)

    logging.info('Browser libraries: %s', browser_libs)
    logging.info('Renderer libraries: %s', renderer_libs)

    # Check that the same libraries are loaded into both processes:
    browser_set = set(browser_libs.keys())
    renderer_set = set(renderer_libs.keys())
    if browser_set != renderer_set:
      logging.error('Library set mistmach browser=%s renderer=%s',
          browser_libs.keys(), renderer_libs.keys())
      return ResultType.FAIL, logs

    # And that there are not empty.
    if not browser_set:
      logging.error('No libraries loaded in any process!')
      return ResultType.FAIL, logs

    # Check that the renderer libraries are loaded at 'low-addresses'. i.e.
    # below 0x4000_0000, for every kind of device.
    memory_boundary = 0x40000000
    bad_libs = []
    for lib_name, lib_address in renderer_libs.iteritems():
      if lib_address >= memory_boundary:
        bad_libs.append((lib_name, lib_address))

    if bad_libs:
      logging.error('Renderer libraries loaded at high addresses: %s', bad_libs)
      return ResultType.FAIL, logs

    browser_config = _GetBrowserSharedRelroConfig()
    if not browser_config:
      return ResultType.FAIL, 'Bad linker source configuration'

    if browser_config == 'ALWAYS' or \
        (browser_config == 'LOW_RAM_ONLY' and self.is_low_memory):
      # The libraries must all be loaded at the same addresses. This also
      # implicitly checks that the browser libraries are at low addresses.
      addr_mismatches = []
      for lib_name, lib_address in browser_libs.iteritems():
        lib_address2 = renderer_libs[lib_name]
        if lib_address != lib_address2:
          addr_mismatches.append((lib_name, lib_address, lib_address2))

      if addr_mismatches:
        logging.error('Library load address mismatches: %s',
            addr_mismatches)
        return ResultType.FAIL, logs

    # Otherwise, check that libraries are loaded at 'high-addresses'.
    # Note that for low-memory devices, the previous checks ensure that they
    # were loaded at low-addresses.
    else:
      bad_libs = []
      for lib_name, lib_address in browser_libs.iteritems():
        if lib_address < memory_boundary:
          bad_libs.append((lib_name, lib_address))

      if bad_libs:
        logging.error('Browser libraries loaded at low addresses: %s', bad_libs)
        return ResultType.FAIL, logs

    # Everything's ok.
    return ResultType.PASS, logs


class LinkerRandomizationTest(LinkerTestCaseBase):
  """A linker test case to check that library load address randomization works
     properly between successive starts of the test program/activity.

     This starts the activity several time (each time forcing a new process
     creation) and compares the load addresses of the libraries in them to
     detect that they have changed.

     In theory, two successive runs could (very rarely) use the same load
     address, so loop 5 times and compare the values there. It is assumed
     that if there are more than one pair of identical addresses, then the
     load addresses are not random enough for this test.
  """
  def _RunTest(self, device):
    max_loops = 5
    browser_lib_map_list = []
    renderer_lib_map_list = []
    logs_list = []
    for _ in range(max_loops):
      # Start the activity.
      result, logs = _StartActivityAndWaitForLinkerTestStatus(
          device, timeout=30)
      if result == ResultType.TIMEOUT:
        # Something bad happened. Return immediately.
        return result, logs

      # Collect library addresses.
      browser_libs, renderer_libs = _ExtractLibraryLoadAddressesFromLogcat(logs)
      browser_lib_map_list.append(browser_libs)
      renderer_lib_map_list.append(renderer_libs)
      logs_list.append(logs)

    # Check randomization in the browser libraries.
    logs = '\n'.join(logs_list)

    browser_status, browser_logs = _CheckLoadAddressRandomization(
        browser_lib_map_list, 'Browser')

    renderer_status, renderer_logs = _CheckLoadAddressRandomization(
        renderer_lib_map_list, 'Renderer')

    browser_config = _GetBrowserSharedRelroConfig()
    if not browser_config:
      return ResultType.FAIL, 'Bad linker source configuration'

    if not browser_status:
      if browser_config == 'ALWAYS' or \
          (browser_config == 'LOW_RAM_ONLY' and self.is_low_memory):
        return ResultType.FAIL, browser_logs

      # IMPORTANT NOTE: The system's ASLR implementation seems to be very poor
      # when starting an activity process in a loop with "adb shell am start".
      #
      # When simulating a regular device, loading libraries in the browser
      # process uses a simple mmap(NULL, ...) to let the kernel device where to
      # load the file (this is similar to what System.loadLibrary() does).
      #
      # Unfortunately, at least in the context of this test, doing so while
      # restarting the activity with the activity manager very, very, often
      # results in the system using the same load address for all 5 runs, or
      # sometimes only 4 out of 5.
      #
      # This has been tested experimentally on both Android 4.1.2 and 4.3.
      #
      # Note that this behaviour doesn't seem to happen when starting an
      # application 'normally', i.e. when using the application launcher to
      # start the activity.
      logging.info('Ignoring system\'s low randomization of browser libraries' +
                   ' for regular devices')

    if not renderer_status:
      return ResultType.FAIL, renderer_logs

    return ResultType.PASS, logs
