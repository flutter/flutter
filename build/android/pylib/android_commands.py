# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Provides an interface to communicate with the device via the adb command.

Assumes adb binary is currently on system path.

Note that this module is deprecated.
"""
# TODO(jbudorick): Delete this file once no clients use it.

# pylint: skip-file

import collections
import datetime
import inspect
import logging
import os
import random
import re
import shlex
import signal
import subprocess
import sys
import tempfile
import time

import cmd_helper
import constants
import system_properties
from utils import host_utils

try:
  from pylib import pexpect
except ImportError:
  pexpect = None

sys.path.append(os.path.join(
    constants.DIR_SOURCE_ROOT, 'third_party', 'android_testrunner'))
import adb_interface
import am_instrument_parser
import errors

from pylib.device import device_blacklist
from pylib.device import device_errors

# Pattern to search for the next whole line of pexpect output and capture it
# into a match group. We can't use ^ and $ for line start end with pexpect,
# see http://www.noah.org/python/pexpect/#doc for explanation why.
PEXPECT_LINE_RE = re.compile('\n([^\r]*)\r')

# Set the adb shell prompt to be a unique marker that will [hopefully] not
# appear at the start of any line of a command's output.
SHELL_PROMPT = '~+~PQ\x17RS~+~'

# Java properties file
LOCAL_PROPERTIES_PATH = constants.DEVICE_LOCAL_PROPERTIES_PATH

# Property in /data/local.prop that controls Java assertions.
JAVA_ASSERT_PROPERTY = 'dalvik.vm.enableassertions'

# Keycode "enum" suitable for passing to AndroidCommands.SendKey().
KEYCODE_HOME = 3
KEYCODE_BACK = 4
KEYCODE_DPAD_UP = 19
KEYCODE_DPAD_DOWN = 20
KEYCODE_DPAD_RIGHT = 22
KEYCODE_ENTER = 66
KEYCODE_MENU = 82

MD5SUM_DEVICE_FOLDER = constants.TEST_EXECUTABLE_DIR + '/md5sum/'
MD5SUM_DEVICE_PATH = MD5SUM_DEVICE_FOLDER + 'md5sum_bin'

PIE_WRAPPER_PATH = constants.TEST_EXECUTABLE_DIR + '/run_pie'

CONTROL_USB_CHARGING_COMMANDS = [
  {
    # Nexus 4
    'witness_file': '/sys/module/pm8921_charger/parameters/disabled',
    'enable_command': 'echo 0 > /sys/module/pm8921_charger/parameters/disabled',
    'disable_command':
        'echo 1 > /sys/module/pm8921_charger/parameters/disabled',
  },
  {
    # Nexus 5
    # Setting the HIZ bit of the bq24192 causes the charger to actually ignore
    # energy coming from USB. Setting the power_supply offline just updates the
    # Android system to reflect that.
    'witness_file': '/sys/kernel/debug/bq24192/INPUT_SRC_CONT',
    'enable_command': (
        'echo 0x4A > /sys/kernel/debug/bq24192/INPUT_SRC_CONT && '
        'echo 1 > /sys/class/power_supply/usb/online'),
    'disable_command': (
        'echo 0xCA > /sys/kernel/debug/bq24192/INPUT_SRC_CONT && '
        'chmod 644 /sys/class/power_supply/usb/online && '
        'echo 0 > /sys/class/power_supply/usb/online'),
  },
]

class DeviceTempFile(object):
  def __init__(self, android_commands, prefix='temp_file', suffix=''):
    """Find an unused temporary file path in the devices external directory.

    When this object is closed, the file will be deleted on the device.
    """
    self.android_commands = android_commands
    while True:
      # TODO(cjhopman): This could actually return the same file in multiple
      # calls if the caller doesn't write to the files immediately. This is
      # expected to never happen.
      i = random.randint(0, 1000000)
      self.name = '%s/%s-%d-%010d%s' % (
          android_commands.GetExternalStorage(),
          prefix, int(time.time()), i, suffix)
      if not android_commands.FileExistsOnDevice(self.name):
        break

  def __enter__(self):
    return self

  def __exit__(self, type, value, traceback):
    self.close()

  def close(self):
    self.android_commands.RunShellCommand('rm ' + self.name)


def GetAVDs():
  """Returns a list of AVDs."""
  re_avd = re.compile('^[ ]+Name: ([a-zA-Z0-9_:.-]+)', re.MULTILINE)
  avds = re_avd.findall(cmd_helper.GetCmdOutput(['android', 'list', 'avd']))
  return avds

def ResetBadDevices():
  """Removes the blacklist that keeps track of bad devices for a current
     build.
  """
  device_blacklist.ResetBlacklist()

def ExtendBadDevices(devices):
  """Adds devices to the blacklist that keeps track of bad devices for a
     current build.

  The devices listed in the bad devices file will not be returned by
  GetAttachedDevices.

  Args:
    devices: list of bad devices to be added to the bad devices file.
  """
  device_blacklist.ExtendBlacklist(devices)


def GetAttachedDevices(hardware=True, emulator=True, offline=False):
  """Returns a list of attached, android devices and emulators.

  If a preferred device has been set with ANDROID_SERIAL, it will be first in
  the returned list. The arguments specify what devices to include in the list.

  Example output:

    * daemon not running. starting it now on port 5037 *
    * daemon started successfully *
    List of devices attached
    027c10494100b4d7        device
    emulator-5554   offline

  Args:
    hardware: Include attached actual devices that are online.
    emulator: Include emulators (i.e. AVD's) currently on host.
    offline: Include devices and emulators that are offline.

  Returns: List of devices.
  """
  adb_devices_output = cmd_helper.GetCmdOutput([constants.GetAdbPath(),
                                                'devices'])

  re_device = re.compile('^([a-zA-Z0-9_:.-]+)\tdevice$', re.MULTILINE)
  online_devices = re_device.findall(adb_devices_output)

  re_device = re.compile('^(emulator-[0-9]+)\tdevice', re.MULTILINE)
  emulator_devices = re_device.findall(adb_devices_output)

  re_device = re.compile('^([a-zA-Z0-9_:.-]+)\t(?:offline|unauthorized)$',
                         re.MULTILINE)
  offline_devices = re_device.findall(adb_devices_output)

  devices = []
  # First determine list of online devices (e.g. hardware and/or emulator).
  if hardware and emulator:
    devices = online_devices
  elif hardware:
    devices = [device for device in online_devices
               if device not in emulator_devices]
  elif emulator:
    devices = emulator_devices

  # Now add offline devices if offline is true
  if offline:
    devices = devices + offline_devices

  # Remove any devices in the blacklist.
  blacklist = device_blacklist.ReadBlacklist()
  if len(blacklist):
    logging.info('Avoiding bad devices %s', ' '.join(blacklist))
    devices = [device for device in devices if device not in blacklist]

  preferred_device = os.environ.get('ANDROID_SERIAL')
  if preferred_device in devices:
    devices.remove(preferred_device)
    devices.insert(0, preferred_device)
  return devices


def IsDeviceAttached(device):
  """Return true if the device is attached and online."""
  return device in GetAttachedDevices()


def _GetFilesFromRecursiveLsOutput(path, ls_output, re_file, utc_offset=None):
  """Gets a list of files from `ls` command output.

  Python's os.walk isn't used because it doesn't work over adb shell.

  Args:
    path: The path to list.
    ls_output: A list of lines returned by an `ls -lR` command.
    re_file: A compiled regular expression which parses a line into named groups
        consisting of at minimum "filename", "date", "time", "size" and
        optionally "timezone".
    utc_offset: A 5-character string of the form +HHMM or -HHMM, where HH is a
        2-digit string giving the number of UTC offset hours, and MM is a
        2-digit string giving the number of UTC offset minutes. If the input
        utc_offset is None, will try to look for the value of "timezone" if it
        is specified in re_file.

  Returns:
    A dict of {"name": (size, lastmod), ...} where:
      name: The file name relative to |path|'s directory.
      size: The file size in bytes (0 for directories).
      lastmod: The file last modification date in UTC.
  """
  re_directory = re.compile('^%s/(?P<dir>[^:]+):$' % re.escape(path))
  path_dir = os.path.dirname(path)

  current_dir = ''
  files = {}
  for line in ls_output:
    directory_match = re_directory.match(line)
    if directory_match:
      current_dir = directory_match.group('dir')
      continue
    file_match = re_file.match(line)
    if file_match:
      filename = os.path.join(current_dir, file_match.group('filename'))
      if filename.startswith(path_dir):
        filename = filename[len(path_dir) + 1:]
      lastmod = datetime.datetime.strptime(
          file_match.group('date') + ' ' + file_match.group('time')[:5],
          '%Y-%m-%d %H:%M')
      if not utc_offset and 'timezone' in re_file.groupindex:
        utc_offset = file_match.group('timezone')
      if isinstance(utc_offset, str) and len(utc_offset) == 5:
        utc_delta = datetime.timedelta(hours=int(utc_offset[1:3]),
                                       minutes=int(utc_offset[3:5]))
        if utc_offset[0:1] == '-':
          utc_delta = -utc_delta
        lastmod -= utc_delta
      files[filename] = (int(file_match.group('size')), lastmod)
  return files


def _ParseMd5SumOutput(md5sum_output):
  """Returns a list of tuples from the provided md5sum output.

  Args:
    md5sum_output: output directly from md5sum binary.

  Returns:
    List of namedtuples with attributes |hash| and |path|, where |path| is the
    absolute path to the file with an Md5Sum of |hash|.
  """
  HashAndPath = collections.namedtuple('HashAndPath', ['hash', 'path'])
  split_lines = [line.split('  ') for line in md5sum_output]
  return [HashAndPath._make(s) for s in split_lines if len(s) == 2]


def _HasAdbPushSucceeded(command_output):
  """Returns whether adb push has succeeded from the provided output."""
  # TODO(frankf): We should look at the return code instead of the command
  # output for many of the commands in this file.
  if not command_output:
    return True
  # Success looks like this: "3035 KB/s (12512056 bytes in 4.025s)"
  # Errors look like this: "failed to copy  ... "
  if not re.search('^[0-9]', command_output.splitlines()[-1]):
    logging.critical('PUSH FAILED: ' + command_output)
    return False
  return True


def GetLogTimestamp(log_line, year):
  """Returns the timestamp of the given |log_line| in the given year."""
  try:
    return datetime.datetime.strptime('%s-%s' % (year, log_line[:18]),
                                      '%Y-%m-%d %H:%M:%S.%f')
  except (ValueError, IndexError):
    logging.critical('Error reading timestamp from ' + log_line)
    return None


class AndroidCommands(object):
  """Helper class for communicating with Android device via adb."""

  def __init__(self, device=None):
    """Constructor.

    Args:
      device: If given, adb commands are only send to the device of this ID.
          Otherwise commands are sent to all attached devices.
    """
    self._adb = adb_interface.AdbInterface(constants.GetAdbPath())
    if device:
      self._adb.SetTargetSerial(device)
    self._device = device
    self._logcat = None
    self.logcat_process = None
    self._logcat_tmpoutfile = None
    self._pushed_files = []
    self._device_utc_offset = None
    self._potential_push_size = 0
    self._actual_push_size = 0
    self._external_storage = ''
    self._util_wrapper = ''
    self._system_properties = system_properties.SystemProperties(self.Adb())
    self._push_if_needed_cache = {}
    self._control_usb_charging_command = {
        'command': None,
        'cached': False,
    }
    self._protected_file_access_method_initialized = None
    self._privileged_command_runner = None
    self._pie_wrapper = None

  @property
  def system_properties(self):
    return self._system_properties

  def _LogShell(self, cmd):
    """Logs the adb shell command."""
    if self._device:
      device_repr = self._device[-4:]
    else:
      device_repr = '????'
    logging.info('[%s]> %s', device_repr, cmd)

  def Adb(self):
    """Returns our AdbInterface to avoid us wrapping all its methods."""
    # TODO(tonyg): Goal should be to git rid of this method by making this API
    # complete and alleviating the need.
    return self._adb

  def GetDevice(self):
    """Returns the device serial."""
    return self._device

  def IsOnline(self):
    """Checks whether the device is online.

    Returns:
      True if device is in 'device' mode, False otherwise.
    """
    # TODO(aurimas): revert to using adb get-state when android L adb is fixed.
    #out = self._adb.SendCommand('get-state')
    #return out.strip() == 'device'

    out = self._adb.SendCommand('devices')
    for line in out.split('\n'):
      if self._device in line and 'device' in line:
        return True
    return False

  def IsRootEnabled(self):
    """Checks if root is enabled on the device."""
    root_test_output = self.RunShellCommand('ls /root') or ['']
    return not 'Permission denied' in root_test_output[0]

  def EnableAdbRoot(self):
    """Enables adb root on the device.

    Returns:
      True: if output from executing adb root was as expected.
      False: otherwise.
    """
    if self.GetBuildType() == 'user':
      logging.warning("Can't enable root in production builds with type user")
      return False
    else:
      return_value = self._adb.EnableAdbRoot()
      # EnableAdbRoot inserts a call for wait-for-device only when adb logcat
      # output matches what is expected. Just to be safe add a call to
      # wait-for-device.
      self._adb.SendCommand('wait-for-device')
      return return_value

  def GetDeviceYear(self):
    """Returns the year information of the date on device."""
    return self.RunShellCommand('date +%Y')[0]

  def GetExternalStorage(self):
    if not self._external_storage:
      self._external_storage = self.RunShellCommand('echo $EXTERNAL_STORAGE')[0]
      if not self._external_storage:
        raise device_errors.CommandFailedError(
            ['shell', "'echo $EXTERNAL_STORAGE'"],
            'Unable to find $EXTERNAL_STORAGE')
    return self._external_storage

  def WaitForDevicePm(self, timeout=120):
    """Blocks until the device's package manager is available.

    To workaround http://b/5201039, we restart the shell and retry if the
    package manager isn't back after 120 seconds.

    Raises:
      errors.WaitForResponseTimedOutError after max retries reached.
    """
    last_err = None
    retries = 3
    while retries:
      try:
        self._adb.WaitForDevicePm(wait_time=timeout)
        return  # Success
      except errors.WaitForResponseTimedOutError as e:
        last_err = e
        logging.warning('Restarting and retrying after timeout: %s', e)
        retries -= 1
        self.RestartShell()
    raise last_err # Only reached after max retries, re-raise the last error.

  def RestartShell(self):
    """Restarts the shell on the device. Does not block for it to return."""
    self.RunShellCommand('stop')
    self.RunShellCommand('start')

  def Reboot(self, full_reboot=True):
    """Reboots the device and waits for the package manager to return.

    Args:
      full_reboot: Whether to fully reboot the device or just restart the shell.
    """
    # TODO(torne): hive can't reboot the device either way without breaking the
    # connection; work out if we can handle this better
    if os.environ.get('USING_HIVE'):
      logging.warning('Ignoring reboot request as we are on hive')
      return
    if full_reboot or not self.IsRootEnabled():
      self._adb.SendCommand('reboot')
      self._system_properties = system_properties.SystemProperties(self.Adb())
      timeout = 300
      retries = 1
      # Wait for the device to disappear.
      while retries < 10 and self.IsOnline():
        time.sleep(1)
        retries += 1
    else:
      self.RestartShell()
      timeout = 120
    # To run tests we need at least the package manager and the sd card (or
    # other external storage) to be ready.
    self.WaitForDevicePm(timeout)
    self.WaitForSdCardReady(timeout)

  def Shutdown(self):
    """Shuts down the device."""
    self._adb.SendCommand('reboot -p')
    self._system_properties = system_properties.SystemProperties(self.Adb())

  def Uninstall(self, package):
    """Uninstalls the specified package from the device.

    Args:
      package: Name of the package to remove.

    Returns:
      A status string returned by adb uninstall
    """
    uninstall_command = 'uninstall %s' % package

    self._LogShell(uninstall_command)
    return self._adb.SendCommand(uninstall_command, timeout_time=60)

  def Install(self, package_file_path, reinstall=False):
    """Installs the specified package to the device.

    Args:
      package_file_path: Path to .apk file to install.
      reinstall: Reinstall an existing apk, keeping the data.

    Returns:
      A status string returned by adb install
    """
    assert os.path.isfile(package_file_path), ('<%s> is not file' %
                                               package_file_path)

    install_cmd = ['install']

    if reinstall:
      install_cmd.append('-r')

    install_cmd.append(package_file_path)
    install_cmd = ' '.join(install_cmd)

    self._LogShell(install_cmd)
    return self._adb.SendCommand(install_cmd,
                                 timeout_time=2 * 60,
                                 retry_count=0)

  def ManagedInstall(self, apk_path, keep_data=False, package_name=None,
                     reboots_on_timeout=2):
    """Installs specified package and reboots device on timeouts.

    If package_name is supplied, checks if the package is already installed and
    doesn't reinstall if the apk md5sums match.

    Args:
      apk_path: Path to .apk file to install.
      keep_data: Reinstalls instead of uninstalling first, preserving the
        application data.
      package_name: Package name (only needed if keep_data=False).
      reboots_on_timeout: number of time to reboot if package manager is frozen.
    """
    # Check if package is already installed and up to date.
    if package_name:
      installed_apk_path = self.GetApplicationPath(package_name)
      if (installed_apk_path and
          not self.GetFilesChanged(apk_path, installed_apk_path,
                                   ignore_filenames=True)):
        logging.info('Skipped install: identical %s APK already installed' %
            package_name)
        return
    # Install.
    reboots_left = reboots_on_timeout
    while True:
      try:
        if not keep_data:
          assert package_name
          self.Uninstall(package_name)
        install_status = self.Install(apk_path, reinstall=keep_data)
        if 'Success' in install_status:
          return
        else:
          raise Exception('Install failure: %s' % install_status)
      except errors.WaitForResponseTimedOutError:
        print '@@@STEP_WARNINGS@@@'
        logging.info('Timeout on installing %s on device %s', apk_path,
                     self._device)

        if reboots_left <= 0:
          raise Exception('Install timed out')

        # Force a hard reboot on last attempt
        self.Reboot(full_reboot=(reboots_left == 1))
        reboots_left -= 1

  def MakeSystemFolderWritable(self):
    """Remounts the /system folder rw."""
    out = self._adb.SendCommand('remount')
    if out.strip() != 'remount succeeded':
      raise errors.MsgException('Remount failed: %s' % out)

  def RestartAdbdOnDevice(self):
    logging.info('Restarting adbd on the device...')
    with DeviceTempFile(self, suffix=".sh") as temp_script_file:
      host_script_path = os.path.join(constants.DIR_SOURCE_ROOT,
                                      'build',
                                      'android',
                                      'pylib',
                                      'restart_adbd.sh')
      self._adb.Push(host_script_path, temp_script_file.name)
      self.RunShellCommand('. %s' % temp_script_file.name)
      self._adb.SendCommand('wait-for-device')

  def RestartAdbServer(self):
    """Restart the adb server."""
    ret = self.KillAdbServer()
    if ret != 0:
      raise errors.MsgException('KillAdbServer: %d' % ret)

    ret = self.StartAdbServer()
    if ret != 0:
      raise errors.MsgException('StartAdbServer: %d' % ret)

  @staticmethod
  def KillAdbServer():
    """Kill adb server."""
    adb_cmd = [constants.GetAdbPath(), 'kill-server']
    ret = cmd_helper.RunCmd(adb_cmd)
    retry = 0
    while retry < 3:
      ret, _ = cmd_helper.GetCmdStatusAndOutput(['pgrep', 'adb'])
      if ret != 0:
        # pgrep didn't find adb, kill-server succeeded.
        return 0
      retry += 1
      time.sleep(retry)
    return ret

  def StartAdbServer(self):
    """Start adb server."""
    adb_cmd = ['taskset', '-c', '0', constants.GetAdbPath(), 'start-server']
    ret, _ = cmd_helper.GetCmdStatusAndOutput(adb_cmd)
    retry = 0
    while retry < 3:
      ret, _ = cmd_helper.GetCmdStatusAndOutput(['pgrep', 'adb'])
      if ret == 0:
        # pgrep found adb, start-server succeeded.
        # Waiting for device to reconnect before returning success.
        self._adb.SendCommand('wait-for-device')
        return 0
      retry += 1
      time.sleep(retry)
    return ret

  def WaitForSystemBootCompleted(self, wait_time):
    """Waits for targeted system's boot_completed flag to be set.

    Args:
      wait_time: time in seconds to wait

    Raises:
      WaitForResponseTimedOutError if wait_time elapses and flag still not
      set.
    """
    logging.info('Waiting for system boot completed...')
    self._adb.SendCommand('wait-for-device')
    # Now the device is there, but system not boot completed.
    # Query the sys.boot_completed flag with a basic command
    boot_completed = False
    attempts = 0
    wait_period = 5
    while not boot_completed and (attempts * wait_period) < wait_time:
      output = self.system_properties['sys.boot_completed']
      output = output.strip()
      if output == '1':
        boot_completed = True
      else:
        # If 'error: xxx' returned when querying the flag, it means
        # adb server lost the connection to the emulator, so restart the adb
        # server.
        if 'error:' in output:
          self.RestartAdbServer()
        time.sleep(wait_period)
        attempts += 1
    if not boot_completed:
      raise errors.WaitForResponseTimedOutError(
          'sys.boot_completed flag was not set after %s seconds' % wait_time)

  def WaitForSdCardReady(self, timeout_time):
    """Wait for the SD card ready before pushing data into it."""
    logging.info('Waiting for SD card ready...')
    sdcard_ready = False
    attempts = 0
    wait_period = 5
    external_storage = self.GetExternalStorage()
    while not sdcard_ready and attempts * wait_period < timeout_time:
      output = self.RunShellCommand('ls ' + external_storage)
      if output:
        sdcard_ready = True
      else:
        time.sleep(wait_period)
        attempts += 1
    if not sdcard_ready:
      raise errors.WaitForResponseTimedOutError(
          'SD card not ready after %s seconds' % timeout_time)

  def GetAndroidToolStatusAndOutput(self, command, lib_path=None, *args, **kw):
    """Runs a native Android binary, wrapping the command as necessary.

    This is a specialization of GetShellCommandStatusAndOutput, which is meant
    for running tools/android/ binaries and handle properly: (1) setting the
    lib path (for component=shared_library), (2) using the PIE wrapper on ICS.
    See crbug.com/373219 for more context.

    Args:
      command: String containing the command to send.
      lib_path: (optional) path to the folder containing the dependent libs.
      Same other arguments of GetCmdStatusAndOutput.
    """
    # The first time this command is run the device is inspected to check
    # whether a wrapper for running PIE executable is needed (only Android ICS)
    # or not. The results is cached, so the wrapper is pushed only once.
    if self._pie_wrapper is None:
      # None: did not check; '': did check and not needed; '/path': use /path.
      self._pie_wrapper = ''
      if self.GetBuildId().startswith('I'):  # Ixxxx = Android ICS.
        run_pie_dist_path = os.path.join(constants.GetOutDirectory(), 'run_pie')
        assert os.path.exists(run_pie_dist_path), 'Please build run_pie'
        # The PIE loader must be pushed manually (i.e. no PushIfNeeded) because
        # PushIfNeeded requires md5sum and md5sum requires the wrapper as well.
        adb_command = 'push %s %s' % (run_pie_dist_path, PIE_WRAPPER_PATH)
        assert _HasAdbPushSucceeded(self._adb.SendCommand(adb_command))
        self._pie_wrapper = PIE_WRAPPER_PATH

    if self._pie_wrapper:
      command = '%s %s' % (self._pie_wrapper, command)
    if lib_path:
      command = 'LD_LIBRARY_PATH=%s %s' % (lib_path, command)
    return self.GetShellCommandStatusAndOutput(command, *args, **kw)

  # It is tempting to turn this function into a generator, however this is not
  # possible without using a private (local) adb_shell instance (to ensure no
  # other command interleaves usage of it), which would defeat the main aim of
  # being able to reuse the adb shell instance across commands.
  def RunShellCommand(self, command, timeout_time=20, log_result=False):
    """Send a command to the adb shell and return the result.

    Args:
      command: String containing the shell command to send.
      timeout_time: Number of seconds to wait for command to respond before
        retrying, used by AdbInterface.SendShellCommand.
      log_result: Boolean to indicate whether we should log the result of the
                  shell command.

    Returns:
      list containing the lines of output received from running the command
    """
    self._LogShell(command)
    if "'" in command:
      command = command.replace('\'', '\'\\\'\'')
    result = self._adb.SendShellCommand(
        "'%s'" % command, timeout_time).splitlines()
    # TODO(b.kelemen): we should really be able to drop the stderr of the
    # command or raise an exception based on what the caller wants.
    result = [ l for l in result if not l.startswith('WARNING') ]
    if ['error: device not found'] == result:
      raise errors.DeviceUnresponsiveError('device not found')
    if log_result:
      self._LogShell('\n'.join(result))
    return result

  def GetShellCommandStatusAndOutput(self, command, timeout_time=20,
                                     log_result=False):
    """See RunShellCommand() above.

    Returns:
      The tuple (exit code, list of output lines).
    """
    lines = self.RunShellCommand(
        command + '; echo %$?', timeout_time, log_result)
    last_line = lines[-1]
    status_pos = last_line.rfind('%')
    assert status_pos >= 0
    status = int(last_line[status_pos + 1:])
    if status_pos == 0:
      lines = lines[:-1]
    else:
      lines = lines[:-1] + [last_line[:status_pos]]
    return (status, lines)

  def KillAll(self, process, signum=9, with_su=False):
    """Android version of killall, connected via adb.

    Args:
      process: name of the process to kill off.
      signum: signal to use, 9 (SIGKILL) by default.
      with_su: wether or not to use su to kill the processes.

    Returns:
      the number of processes killed
    """
    pids = self.ExtractPid(process)
    if pids:
      cmd = 'kill -%d %s' % (signum, ' '.join(pids))
      if with_su:
        self.RunShellCommandWithSU(cmd)
      else:
        self.RunShellCommand(cmd)
    return len(pids)

  def KillAllBlocking(self, process, timeout_sec, signum=9, with_su=False):
    """Blocking version of killall, connected via adb.

    This waits until no process matching the corresponding name appears in ps'
    output anymore.

    Args:
      process: name of the process to kill off
      timeout_sec: the timeout in seconds
      signum: same as |KillAll|
      with_su: same as |KillAll|
    Returns:
      the number of processes killed
    """
    processes_killed = self.KillAll(process, signum=signum, with_su=with_su)
    if processes_killed:
      elapsed = 0
      wait_period = 0.1
      # Note that this doesn't take into account the time spent in ExtractPid().
      while self.ExtractPid(process) and elapsed < timeout_sec:
        time.sleep(wait_period)
        elapsed += wait_period
      if elapsed >= timeout_sec:
        return processes_killed - self.ExtractPid(process)
    return processes_killed

  @staticmethod
  def _GetActivityCommand(package, activity, wait_for_completion, action,
                          category, data, extras, trace_file_name, force_stop,
                          flags):
    """Creates command to start |package|'s activity on the device.

    Args - as for StartActivity

    Returns:
      the command to run on the target to start the activity
    """
    cmd = 'am start -a %s' % action
    if force_stop:
      cmd += ' -S'
    if wait_for_completion:
      cmd += ' -W'
    if category:
      cmd += ' -c %s' % category
    if package and activity:
      cmd += ' -n %s/%s' % (package, activity)
    if data:
      cmd += ' -d "%s"' % data
    if extras:
      for key in extras:
        value = extras[key]
        if isinstance(value, str):
          cmd += ' --es'
        elif isinstance(value, bool):
          cmd += ' --ez'
        elif isinstance(value, int):
          cmd += ' --ei'
        else:
          raise NotImplementedError(
              'Need to teach StartActivity how to pass %s extras' % type(value))
        cmd += ' %s %s' % (key, value)
    if trace_file_name:
      cmd += ' --start-profiler ' + trace_file_name
    if flags:
      cmd += ' -f %s' % flags
    return cmd

  def StartActivity(self, package, activity, wait_for_completion=False,
                    action='android.intent.action.VIEW',
                    category=None, data=None,
                    extras=None, trace_file_name=None,
                    force_stop=False, flags=None):
    """Starts |package|'s activity on the device.

    Args:
      package: Name of package to start (e.g. 'com.google.android.apps.chrome').
      activity: Name of activity (e.g. '.Main' or
        'com.google.android.apps.chrome.Main').
      wait_for_completion: wait for the activity to finish launching (-W flag).
      action: string (e.g. "android.intent.action.MAIN"). Default is VIEW.
      category: string (e.g. "android.intent.category.HOME")
      data: Data string to pass to activity (e.g. 'http://www.example.com/').
      extras: Dict of extras to pass to activity. Values are significant.
      trace_file_name: If used, turns on and saves the trace to this file name.
      force_stop: force stop the target app before starting the activity (-S
        flag).
    Returns:
      The output of the underlying command as a list of lines.
    """
    cmd = self._GetActivityCommand(package, activity, wait_for_completion,
                                   action, category, data, extras,
                                   trace_file_name, force_stop, flags)
    return self.RunShellCommand(cmd)

  def StartActivityTimed(self, package, activity, wait_for_completion=False,
                         action='android.intent.action.VIEW',
                         category=None, data=None,
                         extras=None, trace_file_name=None,
                         force_stop=False, flags=None):
    """Starts |package|'s activity on the device, returning the start time

    Args - as for StartActivity

    Returns:
      A tuple containing:
        - the output of the underlying command as a list of lines, and
        - a timestamp string for the time at which the activity started
    """
    cmd = self._GetActivityCommand(package, activity, wait_for_completion,
                                   action, category, data, extras,
                                   trace_file_name, force_stop, flags)
    self.StartMonitoringLogcat()
    out = self.RunShellCommand('log starting activity; ' + cmd)
    activity_started_re = re.compile('.*starting activity.*')
    m = self.WaitForLogMatch(activity_started_re, None)
    assert m
    start_line = m.group(0)
    return (out, GetLogTimestamp(start_line, self.GetDeviceYear()))

  def StartCrashUploadService(self, package):
    # TODO(frankf): We really need a python wrapper around Intent
    # to be shared with StartActivity/BroadcastIntent.
    cmd = (
      'am startservice -a %s.crash.ACTION_FIND_ALL -n '
      '%s/%s.crash.MinidumpUploadService' %
      (constants.PACKAGE_INFO['chrome'].package,
       package,
       constants.PACKAGE_INFO['chrome'].package))
    am_output = self.RunShellCommandWithSU(cmd)
    assert am_output and 'Starting' in am_output[-1], (
        'Service failed to start: %s' % am_output)
    time.sleep(15)

  def BroadcastIntent(self, package, intent, *args):
    """Send a broadcast intent.

    Args:
      package: Name of package containing the intent.
      intent: Name of the intent.
      args: Optional extra arguments for the intent.
    """
    cmd = 'am broadcast -a %s.%s %s' % (package, intent, ' '.join(args))
    self.RunShellCommand(cmd)

  def GoHome(self):
    """Tell the device to return to the home screen. Blocks until completion."""
    self.RunShellCommand('am start -W '
        '-a android.intent.action.MAIN -c android.intent.category.HOME')

  def CloseApplication(self, package):
    """Attempt to close down the application, using increasing violence.

    Args:
      package: Name of the process to kill off, e.g.
      com.google.android.apps.chrome
    """
    self.RunShellCommand('am force-stop ' + package)

  def GetApplicationPath(self, package):
    """Get the installed apk path on the device for the given package.

    Args:
      package: Name of the package.

    Returns:
      Path to the apk on the device if it exists, None otherwise.
    """
    pm_path_output  = self.RunShellCommand('pm path ' + package)
    # The path output contains anything if and only if the package
    # exists.
    if pm_path_output:
      # pm_path_output is of the form: "package:/path/to/foo.apk"
      return pm_path_output[0].split(':')[1]
    else:
      return None

  def ClearApplicationState(self, package):
    """Closes and clears all state for the given |package|."""
    # Check that the package exists before clearing it. Necessary because
    # calling pm clear on a package that doesn't exist may never return.
    pm_path_output  = self.RunShellCommand('pm path ' + package)
    # The path output only contains anything if and only if the package exists.
    if pm_path_output:
      self.RunShellCommand('pm clear ' + package)

  def SendKeyEvent(self, keycode):
    """Sends keycode to the device.

    Args:
      keycode: Numeric keycode to send (see "enum" at top of file).
    """
    self.RunShellCommand('input keyevent %d' % keycode)

  def _RunMd5Sum(self, host_path, device_path):
    """Gets the md5sum of a host path and device path.

    Args:
      host_path: Path (file or directory) on the host.
      device_path: Path on the device.

    Returns:
      A tuple containing lists of the host and device md5sum results as
      created by _ParseMd5SumOutput().
    """
    md5sum_dist_path = os.path.join(constants.GetOutDirectory(),
                                    'md5sum_dist')
    assert os.path.exists(md5sum_dist_path), 'Please build md5sum.'
    md5sum_dist_mtime = os.stat(md5sum_dist_path).st_mtime
    if (md5sum_dist_path not in self._push_if_needed_cache or
        self._push_if_needed_cache[md5sum_dist_path] != md5sum_dist_mtime):
      command = 'push %s %s' % (md5sum_dist_path, MD5SUM_DEVICE_FOLDER)
      assert _HasAdbPushSucceeded(self._adb.SendCommand(command))
      self._push_if_needed_cache[md5sum_dist_path] = md5sum_dist_mtime

    (_, md5_device_output) = self.GetAndroidToolStatusAndOutput(
        self._util_wrapper + ' ' + MD5SUM_DEVICE_PATH + ' ' + device_path,
        lib_path=MD5SUM_DEVICE_FOLDER,
        timeout_time=2 * 60)
    device_hash_tuples = _ParseMd5SumOutput(md5_device_output)
    assert os.path.exists(host_path), 'Local path not found %s' % host_path
    md5sum_output = cmd_helper.GetCmdOutput(
        [os.path.join(constants.GetOutDirectory(), 'md5sum_bin_host'),
         host_path])
    host_hash_tuples = _ParseMd5SumOutput(md5sum_output.splitlines())
    return (host_hash_tuples, device_hash_tuples)

  def GetFilesChanged(self, host_path, device_path, ignore_filenames=False):
    """Compares the md5sum of a host path against a device path.

    Note: Ignores extra files on the device.

    Args:
      host_path: Path (file or directory) on the host.
      device_path: Path on the device.
      ignore_filenames: If True only the file contents are considered when
          checking whether a file has changed, otherwise the relative path
          must also match.

    Returns:
      A list of tuples of the form (host_path, device_path) for files whose
      md5sums do not match.
    """

    # Md5Sum resolves symbolic links in path names so the calculation of
    # relative path names from its output will need the real path names of the
    # base directories. Having calculated these they are used throughout the
    # function since this makes us less subject to any future changes to Md5Sum.
    real_host_path = os.path.realpath(host_path)
    real_device_path = self.RunShellCommand('realpath "%s"' % device_path)[0]

    host_hash_tuples, device_hash_tuples = self._RunMd5Sum(
        real_host_path, real_device_path)

    if len(host_hash_tuples) > len(device_hash_tuples):
      logging.info('%s files do not exist on the device' %
                   (len(host_hash_tuples) - len(device_hash_tuples)))

    host_rel = [(os.path.relpath(os.path.normpath(t.path), real_host_path),
                 t.hash)
                for t in host_hash_tuples]

    if os.path.isdir(real_host_path):
      def RelToRealPaths(rel_path):
        return (os.path.join(real_host_path, rel_path),
                os.path.join(real_device_path, rel_path))
    else:
      assert len(host_rel) == 1
      def RelToRealPaths(_):
        return (real_host_path, real_device_path)

    if ignore_filenames:
      # If we are ignoring file names, then we want to push any file for which
      # a file with an equivalent MD5 sum does not exist on the device.
      device_hashes = set([h.hash for h in device_hash_tuples])
      ShouldPush = lambda p, h: h not in device_hashes
    else:
      # Otherwise, we want to push any file on the host for which a file with
      # an equivalent MD5 sum does not exist at the same relative path on the
      # device.
      device_rel = dict([(os.path.relpath(os.path.normpath(t.path),
                                          real_device_path),
                          t.hash)
                         for t in device_hash_tuples])
      ShouldPush = lambda p, h: p not in device_rel or h != device_rel[p]

    return [RelToRealPaths(path) for path, host_hash in host_rel
            if ShouldPush(path, host_hash)]

  def PushIfNeeded(self, host_path, device_path):
    """Pushes |host_path| to |device_path|.

    Works for files and directories. This method skips copying any paths in
    |test_data_paths| that already exist on the device with the same hash.

    All pushed files can be removed by calling RemovePushedFiles().
    """
    MAX_INDIVIDUAL_PUSHES = 50
    if not os.path.exists(host_path):
      raise device_errors.CommandFailedError(
          'Local path not found %s' % host_path, device=str(self))

    # See if the file on the host changed since the last push (if any) and
    # return early if it didn't. Note that this shortcut assumes that the tests
    # on the device don't modify the files.
    if not os.path.isdir(host_path):
      if host_path in self._push_if_needed_cache:
        host_path_mtime = self._push_if_needed_cache[host_path]
        if host_path_mtime == os.stat(host_path).st_mtime:
          return

    size = host_utils.GetRecursiveDiskUsage(host_path)
    self._pushed_files.append(device_path)
    self._potential_push_size += size

    if os.path.isdir(host_path):
      self.RunShellCommand('mkdir -p "%s"' % device_path)

    changed_files = self.GetFilesChanged(host_path, device_path)
    logging.info('Found %d files that need to be pushed to %s',
        len(changed_files), device_path)
    if not changed_files:
      return

    def Push(host, device):
      # NOTE: We can't use adb_interface.Push() because it hardcodes a timeout
      # of 60 seconds which isn't sufficient for a lot of users of this method.
      push_command = 'push %s %s' % (host, device)
      self._LogShell(push_command)

      # Retry push with increasing backoff if the device is busy.
      retry = 0
      while True:
        output = self._adb.SendCommand(push_command, timeout_time=30 * 60)
        if _HasAdbPushSucceeded(output):
          if not os.path.isdir(host_path):
            self._push_if_needed_cache[host] = os.stat(host).st_mtime
          return
        if retry < 3:
          retry += 1
          wait_time = 5 * retry
          logging.error('Push failed, retrying in %d seconds: %s' %
                        (wait_time, output))
          time.sleep(wait_time)
        else:
          raise Exception('Push failed: %s' % output)

    diff_size = 0
    if len(changed_files) <= MAX_INDIVIDUAL_PUSHES:
      diff_size = sum(host_utils.GetRecursiveDiskUsage(f[0])
                      for f in changed_files)

    # TODO(craigdh): Replace this educated guess with a heuristic that
    # approximates the push time for each method.
    if len(changed_files) > MAX_INDIVIDUAL_PUSHES or diff_size > 0.5 * size:
      self._actual_push_size += size
      Push(host_path, device_path)
    else:
      for f in changed_files:
        Push(f[0], f[1])
      self._actual_push_size += diff_size

  def GetPushSizeInfo(self):
    """Get total size of pushes to the device done via PushIfNeeded()

    Returns:
      A tuple:
        1. Total size of push requests to PushIfNeeded (MB)
        2. Total size that was actually pushed (MB)
    """
    return (self._potential_push_size, self._actual_push_size)

  def GetFileContents(self, filename, log_result=False):
    """Gets contents from the file specified by |filename|."""
    return self.RunShellCommand('cat "%s" 2>/dev/null' % filename,
                                log_result=log_result)

  def SetFileContents(self, filename, contents):
    """Writes |contents| to the file specified by |filename|."""
    with tempfile.NamedTemporaryFile() as f:
      f.write(contents)
      f.flush()
      self._adb.Push(f.name, filename)

  def RunShellCommandWithSU(self, command, timeout_time=20, log_result=False):
    return self.RunShellCommand('su -c %s' % command, timeout_time, log_result)

  def CanAccessProtectedFileContents(self):
    """Returns True if Get/SetProtectedFileContents would work via "su" or adb
    shell running as root.

    Devices running user builds don't have adb root, but may provide "su" which
    can be used for accessing protected files.
    """
    return (self._GetProtectedFileCommandRunner() != None)

  def _GetProtectedFileCommandRunner(self):
    """Finds the best method to access protected files on the device.

    Returns:
      1. None when privileged files cannot be accessed on the device.
      2. Otherwise: A function taking a single parameter: a string with command
         line arguments. Running that function executes the command with
         the appropriate method.
    """
    if self._protected_file_access_method_initialized:
      return self._privileged_command_runner

    self._privileged_command_runner = None
    self._protected_file_access_method_initialized = True

    for cmd in [self.RunShellCommand, self.RunShellCommandWithSU]:
      # Get contents of the auxv vector for the init(8) process from a small
      # binary file that always exists on linux and is always read-protected.
      contents = cmd('cat /proc/1/auxv')
      # The leading 4 or 8-bytes of auxv vector is a_type. There are not many
      # reserved a_type values, hence byte 2 must always be '\0' for a realistic
      # auxv. See /usr/include/elf.h.
      if len(contents) > 0 and (contents[0][2] == '\0'):
        self._privileged_command_runner = cmd
        break
    return self._privileged_command_runner

  def GetProtectedFileContents(self, filename):
    """Gets contents from the protected file specified by |filename|.

    This is potentially less efficient than GetFileContents.
    """
    command = 'cat "%s" 2> /dev/null' % filename
    command_runner = self._GetProtectedFileCommandRunner()
    if command_runner:
      return command_runner(command)
    else:
      logging.warning('Could not access protected file: %s' % filename)
      return []

  def SetProtectedFileContents(self, filename, contents):
    """Writes |contents| to the protected file specified by |filename|.

    This is less efficient than SetFileContents.
    """
    with DeviceTempFile(self) as temp_file:
      with DeviceTempFile(self, suffix=".sh") as temp_script:
        # Put the contents in a temporary file
        self.SetFileContents(temp_file.name, contents)
        # Create a script to copy the file contents to its final destination
        self.SetFileContents(temp_script.name,
                             'cat %s > %s' % (temp_file.name, filename))

        command = 'sh %s' % temp_script.name
        command_runner = self._GetProtectedFileCommandRunner()
        if command_runner:
          return command_runner(command)
        else:
          logging.warning(
              'Could not set contents of protected file: %s' % filename)


  def RemovePushedFiles(self):
    """Removes all files pushed with PushIfNeeded() from the device."""
    for p in self._pushed_files:
      self.RunShellCommand('rm -r %s' % p, timeout_time=2 * 60)

  def ListPathContents(self, path):
    """Lists files in all subdirectories of |path|.

    Args:
      path: The path to list.

    Returns:
      A dict of {"name": (size, lastmod), ...}.
    """
    # Example output:
    # /foo/bar:
    # -rw-r----- user group   102 2011-05-12 12:29:54.131623387 +0100 baz.txt
    re_file = re.compile('^-(?P<perms>[^\s]+)\s+'
                         '(?P<user>[^\s]+)\s+'
                         '(?P<group>[^\s]+)\s+'
                         '(?P<size>[^\s]+)\s+'
                         '(?P<date>[^\s]+)\s+'
                         '(?P<time>[^\s]+)\s+'
                         '(?P<filename>[^\s]+)$')
    return _GetFilesFromRecursiveLsOutput(
        path, self.RunShellCommand('ls -lR %s' % path), re_file,
        self.GetUtcOffset())

  def GetUtcOffset(self):
    if not self._device_utc_offset:
      self._device_utc_offset = self.RunShellCommand('date +%z')[0]
    return self._device_utc_offset

  def SetJavaAssertsEnabled(self, enable):
    """Sets or removes the device java assertions property.

    Args:
      enable: If True the property will be set.

    Returns:
      True if the file was modified (reboot is required for it to take effect).
    """
    # First ensure the desired property is persisted.
    temp_props_file = tempfile.NamedTemporaryFile()
    properties = ''
    if self._adb.Pull(LOCAL_PROPERTIES_PATH, temp_props_file.name):
      with open(temp_props_file.name) as f:
        properties = f.read()
    re_search = re.compile(r'^\s*' + re.escape(JAVA_ASSERT_PROPERTY) +
                           r'\s*=\s*all\s*$', re.MULTILINE)
    if enable != bool(re.search(re_search, properties)):
      re_replace = re.compile(r'^\s*' + re.escape(JAVA_ASSERT_PROPERTY) +
                              r'\s*=\s*\w+\s*$', re.MULTILINE)
      properties = re.sub(re_replace, '', properties)
      if enable:
        properties += '\n%s=all\n' % JAVA_ASSERT_PROPERTY

      file(temp_props_file.name, 'w').write(properties)
      self._adb.Push(temp_props_file.name, LOCAL_PROPERTIES_PATH)

    # Next, check the current runtime value is what we need, and
    # if not, set it and report that a reboot is required.
    was_set = 'all' in self.system_properties[JAVA_ASSERT_PROPERTY]
    if was_set == enable:
      return False
    self.system_properties[JAVA_ASSERT_PROPERTY] = enable and 'all' or ''
    return True

  def GetBuildId(self):
    """Returns the build ID of the system (e.g. JRM79C)."""
    build_id = self.system_properties['ro.build.id']
    assert build_id
    return build_id

  def GetBuildType(self):
    """Returns the build type of the system (e.g. eng)."""
    build_type = self.system_properties['ro.build.type']
    assert build_type
    return build_type

  def GetBuildProduct(self):
    """Returns the build product of the device (e.g. maguro)."""
    build_product = self.system_properties['ro.build.product']
    assert build_product
    return build_product

  def GetProductName(self):
    """Returns the product name of the device (e.g. takju)."""
    name = self.system_properties['ro.product.name']
    assert name
    return name

  def GetBuildFingerprint(self):
    """Returns the build fingerprint of the device."""
    build_fingerprint = self.system_properties['ro.build.fingerprint']
    assert build_fingerprint
    return build_fingerprint

  def GetDescription(self):
    """Returns the description of the system.

    For example, "yakju-userdebug 4.1 JRN54F 364167 dev-keys".
    """
    description = self.system_properties['ro.build.description']
    assert description
    return description

  def GetProductModel(self):
    """Returns the name of the product model (e.g. "Galaxy Nexus") """
    model = self.system_properties['ro.product.model']
    assert model
    return model

  def GetWifiIP(self):
    """Returns the wifi IP on the device."""
    wifi_ip = self.system_properties['dhcp.wlan0.ipaddress']
    # Do not assert here. Devices (e.g. emulators) may not have a WifiIP.
    return wifi_ip

  def GetSubscriberInfo(self):
    """Returns the device subscriber info (e.g. GSM and device ID) as string."""
    iphone_sub = self.RunShellCommand('dumpsys iphonesubinfo')
    # Do not assert here. Devices (e.g. Nakasi on K) may not have iphonesubinfo.
    return '\n'.join(iphone_sub)

  def GetBatteryInfo(self):
    """Returns a {str: str} dict of battery info (e.g. status, level, etc)."""
    battery = self.RunShellCommand('dumpsys battery')
    assert battery
    battery_info = {}
    for line in battery[1:]:
      k, _, v = line.partition(': ')
      battery_info[k.strip()] = v.strip()
    return battery_info

  def GetSetupWizardStatus(self):
    """Returns the status of the device setup wizard (e.g. DISABLED)."""
    status = self.system_properties['ro.setupwizard.mode']
    # On some devices, the status is empty if not otherwise set. In such cases
    # the caller should expect an empty string to be returned.
    return status

  def StartMonitoringLogcat(self, clear=True, logfile=None, filters=None):
    """Starts monitoring the output of logcat, for use with WaitForLogMatch.

    Args:
      clear: If True the existing logcat output will be cleared, to avoiding
             matching historical output lurking in the log.
      filters: A list of logcat filters to be used.
    """
    if clear:
      self.RunShellCommand('logcat -c')
    args = []
    if self._adb._target_arg:
      args += shlex.split(self._adb._target_arg)
    args += ['logcat', '-v', 'threadtime']
    if filters:
      args.extend(filters)
    else:
      args.append('*:v')

    if logfile:
      logfile = NewLineNormalizer(logfile)

    # Spawn logcat and synchronize with it.
    for _ in range(4):
      self._logcat = pexpect.spawn(constants.GetAdbPath(), args, timeout=10,
                                   logfile=logfile)
      if not clear or self.SyncLogCat():
        break
      self._logcat.close(force=True)
    else:
      logging.critical('Error reading from logcat: ' + str(self._logcat.match))
      sys.exit(1)

  def SyncLogCat(self):
    """Synchronize with logcat.

    Synchronize with the monitored logcat so that WaitForLogMatch will only
    consider new message that are received after this point in time.

    Returns:
      True if the synchronization succeeded.
    """
    assert self._logcat
    tag = 'logcat_sync_%s' % time.time()
    self.RunShellCommand('log ' + tag)
    return self._logcat.expect([tag, pexpect.EOF, pexpect.TIMEOUT]) == 0

  def GetMonitoredLogCat(self):
    """Returns an "adb logcat" command as created by pexpected.spawn."""
    if not self._logcat:
      self.StartMonitoringLogcat(clear=False)
    return self._logcat

  def WaitForLogMatch(self, success_re, error_re, clear=False, timeout=10):
    """Blocks until a matching line is logged or a timeout occurs.

    Args:
      success_re: A compiled re to search each line for.
      error_re: A compiled re which, if found, terminates the search for
          |success_re|. If None is given, no error condition will be detected.
      clear: If True the existing logcat output will be cleared, defaults to
          false.
      timeout: Timeout in seconds to wait for a log match.

    Raises:
      pexpect.TIMEOUT after |timeout| seconds without a match for |success_re|
      or |error_re|.

    Returns:
      The re match object if |success_re| is matched first or None if |error_re|
      is matched first.
    """
    logging.info('<<< Waiting for logcat:' + str(success_re.pattern))
    t0 = time.time()
    while True:
      if not self._logcat:
        self.StartMonitoringLogcat(clear)
      try:
        while True:
          # Note this will block for upto the timeout _per log line_, so we need
          # to calculate the overall timeout remaining since t0.
          time_remaining = t0 + timeout - time.time()
          if time_remaining < 0:
            raise pexpect.TIMEOUT(self._logcat)
          self._logcat.expect(PEXPECT_LINE_RE, timeout=time_remaining)
          line = self._logcat.match.group(1)
          if error_re:
            error_match = error_re.search(line)
            if error_match:
              return None
          success_match = success_re.search(line)
          if success_match:
            return success_match
          logging.info('<<< Skipped Logcat Line:' + str(line))
      except pexpect.TIMEOUT:
        raise pexpect.TIMEOUT(
            'Timeout (%ds) exceeded waiting for pattern "%s" (tip: use -vv '
            'to debug)' %
            (timeout, success_re.pattern))
      except pexpect.EOF:
        # It seems that sometimes logcat can end unexpectedly. This seems
        # to happen during Chrome startup after a reboot followed by a cache
        # clean. I don't understand why this happens, but this code deals with
        # getting EOF in logcat.
        logging.critical('Found EOF in adb logcat. Restarting...')
        # Rerun spawn with original arguments. Note that self._logcat.args[0] is
        # the path of adb, so we don't want it in the arguments.
        self._logcat = pexpect.spawn(constants.GetAdbPath(),
                                     self._logcat.args[1:],
                                     timeout=self._logcat.timeout,
                                     logfile=self._logcat.logfile)

  def StartRecordingLogcat(self, clear=True, filters=None):
    """Starts recording logcat output to eventually be saved as a string.

    This call should come before some series of tests are run, with either
    StopRecordingLogcat or SearchLogcatRecord following the tests.

    Args:
      clear: True if existing log output should be cleared.
      filters: A list of logcat filters to be used.
    """
    if not filters:
      filters = ['*:v']
    if clear:
      self._adb.SendCommand('logcat -c')
    logcat_command = 'adb %s logcat -v threadtime %s' % (self._adb._target_arg,
                                                         ' '.join(filters))
    self._logcat_tmpoutfile = tempfile.NamedTemporaryFile(bufsize=0)
    self.logcat_process = subprocess.Popen(logcat_command, shell=True,
                                           stdout=self._logcat_tmpoutfile)

  def GetCurrentRecordedLogcat(self):
    """Return the current content of the logcat being recorded.
       Call this after StartRecordingLogcat() and before StopRecordingLogcat().
       This can be useful to perform timed polling/parsing.
    Returns:
       Current logcat output as a single string, or None if
       StopRecordingLogcat() was already called.
    """
    if not self._logcat_tmpoutfile:
      return None

    with open(self._logcat_tmpoutfile.name) as f:
      return f.read()

  def StopRecordingLogcat(self):
    """Stops an existing logcat recording subprocess and returns output.

    Returns:
      The logcat output as a string or an empty string if logcat was not
      being recorded at the time.
    """
    if not self.logcat_process:
      return ''
    # Cannot evaluate directly as 0 is a possible value.
    # Better to read the self.logcat_process.stdout before killing it,
    # Otherwise the communicate may return incomplete output due to pipe break.
    if self.logcat_process.poll() is None:
      self.logcat_process.kill()
    self.logcat_process.wait()
    self.logcat_process = None
    self._logcat_tmpoutfile.seek(0)
    output = self._logcat_tmpoutfile.read()
    self._logcat_tmpoutfile.close()
    self._logcat_tmpoutfile = None
    return output

  @staticmethod
  def SearchLogcatRecord(record, message, thread_id=None, proc_id=None,
                         log_level=None, component=None):
    """Searches the specified logcat output and returns results.

    This method searches through the logcat output specified by record for a
    certain message, narrowing results by matching them against any other
    specified criteria.  It returns all matching lines as described below.

    Args:
      record: A string generated by Start/StopRecordingLogcat to search.
      message: An output string to search for.
      thread_id: The thread id that is the origin of the message.
      proc_id: The process that is the origin of the message.
      log_level: The log level of the message.
      component: The name of the component that would create the message.

    Returns:
      A list of dictionaries represeting matching entries, each containing keys
      thread_id, proc_id, log_level, component, and message.
    """
    if thread_id:
      thread_id = str(thread_id)
    if proc_id:
      proc_id = str(proc_id)
    results = []
    reg = re.compile('(\d+)\s+(\d+)\s+([A-Z])\s+([A-Za-z]+)\s*:(.*)$',
                     re.MULTILINE)
    log_list = reg.findall(record)
    for (tid, pid, log_lev, comp, msg) in log_list:
      if ((not thread_id or thread_id == tid) and
          (not proc_id or proc_id == pid) and
          (not log_level or log_level == log_lev) and
          (not component or component == comp) and msg.find(message) > -1):
        match = dict({'thread_id': tid, 'proc_id': pid,
                      'log_level': log_lev, 'component': comp,
                      'message': msg})
        results.append(match)
    return results

  def ExtractPid(self, process_name):
    """Extracts Process Ids for a given process name from Android Shell.

    Args:
      process_name: name of the process on the device.

    Returns:
      List of all the process ids (as strings) that match the given name.
      If the name of a process exactly matches the given name, the pid of
      that process will be inserted to the front of the pid list.
    """
    pids = []
    for line in self.RunShellCommand('ps', log_result=False):
      data = line.split()
      try:
        if process_name in data[-1]:  # name is in the last column
          if process_name == data[-1]:
            pids.insert(0, data[1])  # PID is in the second column
          else:
            pids.append(data[1])
      except IndexError:
        pass
    return pids

  def GetIoStats(self):
    """Gets cumulative disk IO stats since boot (for all processes).

    Returns:
      Dict of {num_reads, num_writes, read_ms, write_ms} or None if there
      was an error.
    """
    IoStats = collections.namedtuple(
        'IoStats',
        ['device',
         'num_reads_issued',
         'num_reads_merged',
         'num_sectors_read',
         'ms_spent_reading',
         'num_writes_completed',
         'num_writes_merged',
         'num_sectors_written',
         'ms_spent_writing',
         'num_ios_in_progress',
         'ms_spent_doing_io',
         'ms_spent_doing_io_weighted',
        ])

    for line in self.GetFileContents('/proc/diskstats', log_result=False):
      fields = line.split()
      stats = IoStats._make([fields[2]] + [int(f) for f in fields[3:]])
      if stats.device == 'mmcblk0':
        return {
            'num_reads': stats.num_reads_issued,
            'num_writes': stats.num_writes_completed,
            'read_ms': stats.ms_spent_reading,
            'write_ms': stats.ms_spent_writing,
        }
    logging.warning('Could not find disk IO stats.')
    return None

  def GetMemoryUsageForPid(self, pid):
    """Returns the memory usage for given pid.

    Args:
      pid: The pid number of the specific process running on device.

    Returns:
      Dict of {metric:usage_kb}, for the process which has specified pid.
      The metric keys which may be included are: Size, Rss, Pss, Shared_Clean,
      Shared_Dirty, Private_Clean, Private_Dirty, VmHWM.
    """
    showmap = self.RunShellCommand('showmap %d' % pid)
    if not showmap or not showmap[-1].endswith('TOTAL'):
      logging.warning('Invalid output for showmap %s', str(showmap))
      return {}
    items = showmap[-1].split()
    if len(items) != 9:
      logging.warning('Invalid TOTAL for showmap %s', str(items))
      return {}
    usage_dict = collections.defaultdict(int)
    usage_dict.update({
        'Size': int(items[0].strip()),
        'Rss': int(items[1].strip()),
        'Pss': int(items[2].strip()),
        'Shared_Clean': int(items[3].strip()),
        'Shared_Dirty': int(items[4].strip()),
        'Private_Clean': int(items[5].strip()),
        'Private_Dirty': int(items[6].strip()),
    })
    peak_value_kb = 0
    for line in self.GetProtectedFileContents('/proc/%s/status' % pid):
      if not line.startswith('VmHWM:'):  # Format: 'VmHWM: +[0-9]+ kB'
        continue
      peak_value_kb = int(line.split(':')[1].strip().split(' ')[0])
      break
    usage_dict['VmHWM'] = peak_value_kb
    if not peak_value_kb:
      logging.warning('Could not find memory peak value for pid ' + str(pid))

    return usage_dict

  def ProcessesUsingDevicePort(self, device_port):
    """Lists processes using the specified device port on loopback interface.

    Args:
      device_port: Port on device we want to check.

    Returns:
      A list of (pid, process_name) tuples using the specified port.
    """
    tcp_results = self.RunShellCommand('cat /proc/net/tcp', log_result=False)
    tcp_address = '0100007F:%04X' % device_port
    pids = []
    for single_connect in tcp_results:
      connect_results = single_connect.split()
      # Column 1 is the TCP port, and Column 9 is the inode of the socket
      if connect_results[1] == tcp_address:
        socket_inode = connect_results[9]
        socket_name = 'socket:[%s]' % socket_inode
        lsof_results = self.RunShellCommand('lsof', log_result=False)
        for single_process in lsof_results:
          process_results = single_process.split()
          # Ignore the line if it has less than nine columns in it, which may
          # be the case when a process stops while lsof is executing.
          if len(process_results) <= 8:
            continue
          # Column 0 is the executable name
          # Column 1 is the pid
          # Column 8 is the Inode in use
          if process_results[8] == socket_name:
            pids.append((int(process_results[1]), process_results[0]))
        break
    logging.info('PidsUsingDevicePort: %s', pids)
    return pids

  def FileExistsOnDevice(self, file_name):
    """Checks whether the given file exists on the device.

    Args:
      file_name: Full path of file to check.

    Returns:
      True if the file exists, False otherwise.
    """
    assert '"' not in file_name, 'file_name cannot contain double quotes'
    try:
      status = self._adb.SendShellCommand(
          '\'test -e "%s"; echo $?\'' % (file_name))
      if 'test: not found' not in status:
        return int(status) == 0

      status = self._adb.SendShellCommand(
          '\'ls "%s" >/dev/null 2>&1; echo $?\'' % (file_name))
      return int(status) == 0
    except ValueError:
      if IsDeviceAttached(self._device):
        raise errors.DeviceUnresponsiveError('Device may be offline.')

      return False

  def IsFileWritableOnDevice(self, file_name):
    """Checks whether the given file (or directory) is writable on the device.

    Args:
      file_name: Full path of file/directory to check.

    Returns:
      True if writable, False otherwise.
    """
    assert '"' not in file_name, 'file_name cannot contain double quotes'
    try:
      status = self._adb.SendShellCommand(
          '\'test -w "%s"; echo $?\'' % (file_name))
      if 'test: not found' not in status:
        return int(status) == 0
      raise errors.AbortError('"test" binary not found. OS too old.')

    except ValueError:
      if IsDeviceAttached(self._device):
        raise errors.DeviceUnresponsiveError('Device may be offline.')

      return False

  @staticmethod
  def GetTimestamp():
    return time.strftime('%Y-%m-%d-%H%M%S', time.localtime())

  @staticmethod
  def EnsureHostDirectory(host_file):
    host_dir = os.path.dirname(os.path.abspath(host_file))
    if not os.path.exists(host_dir):
      os.makedirs(host_dir)

  def TakeScreenshot(self, host_file=None):
    """Saves a screenshot image to |host_file| on the host.

    Args:
      host_file: Absolute path to the image file to store on the host or None to
                 use an autogenerated file name.

    Returns:
      Resulting host file name of the screenshot.
    """
    host_file = os.path.abspath(host_file or
                                'screenshot-%s.png' % self.GetTimestamp())
    self.EnsureHostDirectory(host_file)
    device_file = '%s/screenshot.png' % self.GetExternalStorage()
    self.RunShellCommand(
        '/system/bin/screencap -p %s' % device_file)
    self.PullFileFromDevice(device_file, host_file)
    self.RunShellCommand('rm -f "%s"' % device_file)
    return host_file

  def PullFileFromDevice(self, device_file, host_file):
    """Download |device_file| on the device from to |host_file| on the host.

    Args:
      device_file: Absolute path to the file to retrieve from the device.
      host_file: Absolute path to the file to store on the host.
    """
    if not self._adb.Pull(device_file, host_file):
      raise device_errors.AdbCommandFailedError(
          ['pull', device_file, host_file], 'Failed to pull file from device.')
    assert os.path.exists(host_file)

  def SetUtilWrapper(self, util_wrapper):
    """Sets a wrapper prefix to be used when running a locally-built
    binary on the device (ex.: md5sum_bin).
    """
    self._util_wrapper = util_wrapper

  def RunUIAutomatorTest(self, test, test_package, timeout):
    """Runs a single uiautomator test.

    Args:
      test: Test class/method.
      test_package: Name of the test jar.
      timeout: Timeout time in seconds.

    Returns:
      An instance of am_instrument_parser.TestResult object.
    """
    cmd = 'uiautomator runtest %s -e class %s' % (test_package, test)
    self._LogShell(cmd)
    output = self._adb.SendShellCommand(cmd, timeout_time=timeout)
    # uiautomator doesn't fully conform to the instrumenation test runner
    # convention and doesn't terminate with INSTRUMENTATION_CODE.
    # Just assume the first result is valid.
    (test_results, _) = am_instrument_parser.ParseAmInstrumentOutput(output)
    if not test_results:
      raise errors.InstrumentationError(
          'no test results... device setup correctly?')
    return test_results[0]

  def DismissCrashDialogIfNeeded(self):
    """Dismiss the error/ANR dialog if present.

    Returns: Name of the crashed package if a dialog is focused,
             None otherwise.
    """
    re_focus = re.compile(
        r'\s*mCurrentFocus.*Application (Error|Not Responding): (\S+)}')

    def _FindFocusedWindow():
      match = None
      for line in self.RunShellCommand('dumpsys window windows'):
        match = re.match(re_focus, line)
        if match:
          break
      return match

    match = _FindFocusedWindow()
    if not match:
      return
    package = match.group(2)
    logging.warning('Trying to dismiss %s dialog for %s' % match.groups())
    self.SendKeyEvent(KEYCODE_DPAD_RIGHT)
    self.SendKeyEvent(KEYCODE_DPAD_RIGHT)
    self.SendKeyEvent(KEYCODE_ENTER)
    match = _FindFocusedWindow()
    if match:
      logging.error('Still showing a %s dialog for %s' % match.groups())
    return package

  def EfficientDeviceDirectoryCopy(self, source, dest):
    """ Copy a directory efficiently on the device

    Uses a shell script running on the target to copy new and changed files the
    source directory to the destination directory and remove added files. This
    is in some cases much faster than cp -r.

    Args:
      source: absolute path of source directory
      dest: absolute path of destination directory
    """
    logging.info('In EfficientDeviceDirectoryCopy %s %s', source, dest)
    with DeviceTempFile(self, suffix=".sh") as temp_script_file:
      host_script_path = os.path.join(constants.DIR_SOURCE_ROOT,
                                      'build',
                                      'android',
                                      'pylib',
                                      'efficient_android_directory_copy.sh')
      self._adb.Push(host_script_path, temp_script_file.name)
      out = self.RunShellCommand(
          'sh %s %s %s' % (temp_script_file.name, source, dest),
          timeout_time=120)
      if self._device:
        device_repr = self._device[-4:]
      else:
        device_repr = '????'
      for line in out:
        logging.info('[%s]> %s', device_repr, line)

  def _GetControlUsbChargingCommand(self):
    if self._control_usb_charging_command['cached']:
      return self._control_usb_charging_command['command']
    self._control_usb_charging_command['cached'] = True
    if not self.IsRootEnabled():
      return None
    for command in CONTROL_USB_CHARGING_COMMANDS:
      # Assert command is valid.
      assert 'disable_command' in command
      assert 'enable_command' in command
      assert 'witness_file' in command
      witness_file = command['witness_file']
      if self.FileExistsOnDevice(witness_file):
        self._control_usb_charging_command['command'] = command
        return command
    return None

  def CanControlUsbCharging(self):
    return self._GetControlUsbChargingCommand() is not None

  def DisableUsbCharging(self, timeout=10):
    command = self._GetControlUsbChargingCommand()
    if not command:
      raise Exception('Unable to act on usb charging.')
    disable_command = command['disable_command']
    t0 = time.time()
    # Do not loop directly on self.IsDeviceCharging to cut the number of calls
    # to the device.
    while True:
      if t0 + timeout - time.time() < 0:
        raise pexpect.TIMEOUT('Unable to disable USB charging in time: %s' % (
            self.GetBatteryInfo()))
      self.RunShellCommand(disable_command)
      if not self.IsDeviceCharging():
        break

  def EnableUsbCharging(self, timeout=10):
    command = self._GetControlUsbChargingCommand()
    if not command:
      raise Exception('Unable to act on usb charging.')
    disable_command = command['enable_command']
    t0 = time.time()
    # Do not loop directly on self.IsDeviceCharging to cut the number of calls
    # to the device.
    while True:
      if t0 + timeout - time.time() < 0:
        raise pexpect.TIMEOUT('Unable to enable USB charging in time.')
      self.RunShellCommand(disable_command)
      if self.IsDeviceCharging():
        break

  def IsDeviceCharging(self):
    for line in self.RunShellCommand('dumpsys battery'):
      if 'powered: ' in line:
        if line.split('powered: ')[1] == 'true':
          return True


class NewLineNormalizer(object):
  """A file-like object to normalize EOLs to '\n'.

  Pexpect runs adb within a pseudo-tty device (see
  http://www.noah.org/wiki/pexpect), so any '\n' printed by adb is written
  as '\r\n' to the logfile. Since adb already uses '\r\n' to terminate
  lines, the log ends up having '\r\r\n' at the end of each line. This
  filter replaces the above with a single '\n' in the data stream.
  """
  def __init__(self, output):
    self._output = output

  def write(self, data):
    data = data.replace('\r\r\n', '\n')
    self._output.write(data)

  def flush(self):
    self._output.flush()
