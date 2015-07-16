# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Provides a variety of device interactions based on adb.

Eventually, this will be based on adb_wrapper.
"""
# pylint: disable=unused-argument

import collections
import contextlib
import itertools
import logging
import multiprocessing
import os
import posixpath
import re
import shutil
import sys
import tempfile
import time
import zipfile

import pylib.android_commands
from pylib import cmd_helper
from pylib import constants
from pylib import device_signal
from pylib.constants import keyevent
from pylib.device import adb_wrapper
from pylib.device import decorators
from pylib.device import device_blacklist
from pylib.device import device_errors
from pylib.device import intent
from pylib.device import logcat_monitor
from pylib.device.commands import install_commands
from pylib.sdk import split_select
from pylib.utils import apk_helper
from pylib.utils import base_error
from pylib.utils import device_temp_file
from pylib.utils import host_utils
from pylib.utils import md5sum
from pylib.utils import parallelizer
from pylib.utils import timeout_retry
from pylib.utils import zip_utils

_DEFAULT_TIMEOUT = 30
_DEFAULT_RETRIES = 3

# A sentinel object for default values
# TODO(jbudorick,perezju): revisit how default values are handled by
# the timeout_retry decorators.
DEFAULT = object()

_CONTROL_CHARGING_COMMANDS = [
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


@decorators.WithExplicitTimeoutAndRetries(
    _DEFAULT_TIMEOUT, _DEFAULT_RETRIES)
def GetAVDs():
  """Returns a list of Android Virtual Devices.

  Returns:
    A list containing the configured AVDs.
  """
  lines = cmd_helper.GetCmdOutput([
      os.path.join(constants.ANDROID_SDK_ROOT, 'tools', 'android'),
      'list', 'avd']).splitlines()
  avds = []
  for line in lines:
    if 'Name:' not in line:
      continue
    key, value = (s.strip() for s in line.split(':', 1))
    if key == 'Name':
      avds.append(value)
  return avds


@decorators.WithExplicitTimeoutAndRetries(
    _DEFAULT_TIMEOUT, _DEFAULT_RETRIES)
def RestartServer():
  """Restarts the adb server.

  Raises:
    CommandFailedError if we fail to kill or restart the server.
  """
  def adb_killed():
    return not adb_wrapper.AdbWrapper.IsServerOnline()

  def adb_started():
    return adb_wrapper.AdbWrapper.IsServerOnline()

  adb_wrapper.AdbWrapper.KillServer()
  if not timeout_retry.WaitFor(adb_killed, wait_period=1, max_tries=5):
    # TODO(perezju): raise an exception after fixng http://crbug.com/442319
    logging.warning('Failed to kill adb server')
  adb_wrapper.AdbWrapper.StartServer()
  if not timeout_retry.WaitFor(adb_started, wait_period=1, max_tries=5):
    raise device_errors.CommandFailedError('Failed to start adb server')


def _GetTimeStamp():
  """Return a basic ISO 8601 time stamp with the current local time."""
  return time.strftime('%Y%m%dT%H%M%S', time.localtime())


def _JoinLines(lines):
  # makes sure that the last line is also terminated, and is more memory
  # efficient than first appending an end-line to each line and then joining
  # all of them together.
  return ''.join(s for line in lines for s in (line, '\n'))


class DeviceUtils(object):

  _MAX_ADB_COMMAND_LENGTH = 512
  _MAX_ADB_OUTPUT_LENGTH = 32768
  _LAUNCHER_FOCUSED_RE = re.compile(
      '\s*mCurrentFocus.*(Launcher|launcher).*')
  _VALID_SHELL_VARIABLE = re.compile('^[a-zA-Z_][a-zA-Z0-9_]*$')

  # Property in /data/local.prop that controls Java assertions.
  JAVA_ASSERT_PROPERTY = 'dalvik.vm.enableassertions'

  def __init__(self, device, default_timeout=_DEFAULT_TIMEOUT,
               default_retries=_DEFAULT_RETRIES):
    """DeviceUtils constructor.

    Args:
      device: Either a device serial, an existing AdbWrapper instance, or an
              an existing AndroidCommands instance.
      default_timeout: An integer containing the default number of seconds to
                       wait for an operation to complete if no explicit value
                       is provided.
      default_retries: An integer containing the default number or times an
                       operation should be retried on failure if no explicit
                       value is provided.
    """
    self.adb = None
    self.old_interface = None
    if isinstance(device, basestring):
      self.adb = adb_wrapper.AdbWrapper(device)
      self.old_interface = pylib.android_commands.AndroidCommands(device)
    elif isinstance(device, adb_wrapper.AdbWrapper):
      self.adb = device
      self.old_interface = pylib.android_commands.AndroidCommands(str(device))
    elif isinstance(device, pylib.android_commands.AndroidCommands):
      self.adb = adb_wrapper.AdbWrapper(device.GetDevice())
      self.old_interface = device
    else:
      raise ValueError('Unsupported device value: %r' % device)
    self._commands_installed = None
    self._default_timeout = default_timeout
    self._default_retries = default_retries
    self._cache = {}
    self._client_caches = {}
    assert hasattr(self, decorators.DEFAULT_TIMEOUT_ATTR)
    assert hasattr(self, decorators.DEFAULT_RETRIES_ATTR)

  def __eq__(self, other):
    """Checks whether |other| refers to the same device as |self|.

    Args:
      other: The object to compare to. This can be a basestring, an instance
        of adb_wrapper.AdbWrapper, or an instance of DeviceUtils.
    Returns:
      Whether |other| refers to the same device as |self|.
    """
    return self.adb.GetDeviceSerial() == str(other)

  def __lt__(self, other):
    """Compares two instances of DeviceUtils.

    This merely compares their serial numbers.

    Args:
      other: The instance of DeviceUtils to compare to.
    Returns:
      Whether |self| is less than |other|.
    """
    return self.adb.GetDeviceSerial() < other.adb.GetDeviceSerial()

  def __str__(self):
    """Returns the device serial."""
    return self.adb.GetDeviceSerial()

  @decorators.WithTimeoutAndRetriesFromInstance()
  def IsOnline(self, timeout=None, retries=None):
    """Checks whether the device is online.

    Args:
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      True if the device is online, False otherwise.

    Raises:
      CommandTimeoutError on timeout.
    """
    try:
      return self.adb.GetState() == 'device'
    except base_error.BaseError as exc:
      logging.info('Failed to get state: %s', exc)
      return False

  @decorators.WithTimeoutAndRetriesFromInstance()
  def HasRoot(self, timeout=None, retries=None):
    """Checks whether or not adbd has root privileges.

    Args:
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      True if adbd has root privileges, False otherwise.

    Raises:
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    try:
      self.RunShellCommand('ls /root', check_return=True)
      return True
    except device_errors.AdbCommandFailedError:
      return False

  def NeedsSU(self, timeout=DEFAULT, retries=DEFAULT):
    """Checks whether 'su' is needed to access protected resources.

    Args:
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      True if 'su' is available on the device and is needed to to access
        protected resources; False otherwise if either 'su' is not available
        (e.g. because the device has a user build), or not needed (because adbd
        already has root privileges).

    Raises:
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    if 'needs_su' not in self._cache:
      try:
        self.RunShellCommand(
            'su -c ls /root && ! ls /root', check_return=True,
            timeout=self._default_timeout if timeout is DEFAULT else timeout,
            retries=self._default_retries if retries is DEFAULT else retries)
        self._cache['needs_su'] = True
      except device_errors.AdbCommandFailedError:
        self._cache['needs_su'] = False
    return self._cache['needs_su']


  @decorators.WithTimeoutAndRetriesFromInstance()
  def EnableRoot(self, timeout=None, retries=None):
    """Restarts adbd with root privileges.

    Args:
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandFailedError if root could not be enabled.
      CommandTimeoutError on timeout.
    """
    if self.IsUserBuild():
      raise device_errors.CommandFailedError(
          'Cannot enable root in user builds.', str(self))
    if 'needs_su' in self._cache:
      del self._cache['needs_su']
    self.adb.Root()
    self.WaitUntilFullyBooted()

  @decorators.WithTimeoutAndRetriesFromInstance()
  def IsUserBuild(self, timeout=None, retries=None):
    """Checks whether or not the device is running a user build.

    Args:
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      True if the device is running a user build, False otherwise (i.e. if
        it's running a userdebug build).

    Raises:
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    return self.build_type == 'user'

  @decorators.WithTimeoutAndRetriesFromInstance()
  def GetExternalStoragePath(self, timeout=None, retries=None):
    """Get the device's path to its SD card.

    Args:
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      The device's path to its SD card.

    Raises:
      CommandFailedError if the external storage path could not be determined.
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    if 'external_storage' in self._cache:
      return self._cache['external_storage']

    value = self.RunShellCommand('echo $EXTERNAL_STORAGE',
                                 single_line=True,
                                 check_return=True)
    if not value:
      raise device_errors.CommandFailedError('$EXTERNAL_STORAGE is not set',
                                             str(self))
    self._cache['external_storage'] = value
    return value

  @decorators.WithTimeoutAndRetriesFromInstance()
  def GetApplicationPaths(self, package, timeout=None, retries=None):
    """Get the paths of the installed apks on the device for the given package.

    Args:
      package: Name of the package.

    Returns:
      List of paths to the apks on the device for the given package.
    """
    # 'pm path' is liable to incorrectly exit with a nonzero number starting
    # in Lollipop.
    # TODO(jbudorick): Check if this is fixed as new Android versions are
    # released to put an upper bound on this.
    should_check_return = (self.build_version_sdk <
                           constants.ANDROID_SDK_VERSION_CODES.LOLLIPOP)
    output = self.RunShellCommand(
        ['pm', 'path', package], check_return=should_check_return)
    apks = []
    for line in output:
      if not line.startswith('package:'):
        raise device_errors.CommandFailedError(
            'pm path returned: %r' % '\n'.join(output), str(self))
      apks.append(line[len('package:'):])
    return apks

  @decorators.WithTimeoutAndRetriesFromInstance()
  def GetApplicationDataDirectory(self, package, timeout=None, retries=None):
    """Get the data directory on the device for the given package.

    Args:
      package: Name of the package.

    Returns:
      The package's data directory, or None if the package doesn't exist on the
      device.
    """
    try:
      output = self._RunPipedShellCommand(
          'pm dump %s | grep dataDir=' % cmd_helper.SingleQuote(package))
      for line in output:
        _, _, dataDir = line.partition('dataDir=')
        if dataDir:
          return dataDir
    except device_errors.CommandFailedError:
      logging.exception('Could not find data directory for %s', package)
    return None

  @decorators.WithTimeoutAndRetriesFromInstance()
  def WaitUntilFullyBooted(self, wifi=False, timeout=None, retries=None):
    """Wait for the device to fully boot.

    This means waiting for the device to boot, the package manager to be
    available, and the SD card to be ready. It can optionally mean waiting
    for wifi to come up, too.

    Args:
      wifi: A boolean indicating if we should wait for wifi to come up or not.
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandFailedError on failure.
      CommandTimeoutError if one of the component waits times out.
      DeviceUnreachableError if the device becomes unresponsive.
    """
    def sd_card_ready():
      try:
        self.RunShellCommand(['test', '-d', self.GetExternalStoragePath()],
                             check_return=True)
        return True
      except device_errors.AdbCommandFailedError:
        return False

    def pm_ready():
      try:
        return self.GetApplicationPaths('android')
      except device_errors.CommandFailedError:
        return False

    def boot_completed():
      return self.GetProp('sys.boot_completed') == '1'

    def wifi_enabled():
      return 'Wi-Fi is enabled' in self.RunShellCommand(['dumpsys', 'wifi'],
                                                        check_return=False)

    self.adb.WaitForDevice()
    timeout_retry.WaitFor(sd_card_ready)
    timeout_retry.WaitFor(pm_ready)
    timeout_retry.WaitFor(boot_completed)
    if wifi:
      timeout_retry.WaitFor(wifi_enabled)

  REBOOT_DEFAULT_TIMEOUT = 10 * _DEFAULT_TIMEOUT
  REBOOT_DEFAULT_RETRIES = _DEFAULT_RETRIES

  @decorators.WithTimeoutAndRetriesDefaults(
      REBOOT_DEFAULT_TIMEOUT,
      REBOOT_DEFAULT_RETRIES)
  def Reboot(self, block=True, wifi=False, timeout=None, retries=None):
    """Reboot the device.

    Args:
      block: A boolean indicating if we should wait for the reboot to complete.
      wifi: A boolean indicating if we should wait for wifi to be enabled after
        the reboot. The option has no effect unless |block| is also True.
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    def device_offline():
      return not self.IsOnline()

    self.adb.Reboot()
    self._ClearCache()
    timeout_retry.WaitFor(device_offline, wait_period=1)
    if block:
      self.WaitUntilFullyBooted(wifi=wifi)

  INSTALL_DEFAULT_TIMEOUT = 4 * _DEFAULT_TIMEOUT
  INSTALL_DEFAULT_RETRIES = _DEFAULT_RETRIES

  @decorators.WithTimeoutAndRetriesDefaults(
      INSTALL_DEFAULT_TIMEOUT,
      INSTALL_DEFAULT_RETRIES)
  def Install(self, apk_path, reinstall=False, timeout=None, retries=None):
    """Install an APK.

    Noop if an identical APK is already installed.

    Args:
      apk_path: A string containing the path to the APK to install.
      reinstall: A boolean indicating if we should keep any existing app data.
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandFailedError if the installation fails.
      CommandTimeoutError if the installation times out.
      DeviceUnreachableError on missing device.
    """
    package_name = apk_helper.GetPackageName(apk_path)
    device_paths = self.GetApplicationPaths(package_name)
    if device_paths:
      if len(device_paths) > 1:
        logging.warning(
            'Installing single APK (%s) when split APKs (%s) are currently '
            'installed.', apk_path, ' '.join(device_paths))
      (files_to_push, _) = self._GetChangedAndStaleFiles(
          apk_path, device_paths[0])
      should_install = bool(files_to_push)
      if should_install and not reinstall:
        self.adb.Uninstall(package_name)
    else:
      should_install = True
    if should_install:
      self.adb.Install(apk_path, reinstall=reinstall)

  @decorators.WithTimeoutAndRetriesDefaults(
      INSTALL_DEFAULT_TIMEOUT,
      INSTALL_DEFAULT_RETRIES)
  def InstallSplitApk(self, base_apk, split_apks, reinstall=False,
                      timeout=None, retries=None):
    """Install a split APK.

    Noop if all of the APK splits are already installed.

    Args:
      base_apk: A string of the path to the base APK.
      split_apks: A list of strings of paths of all of the APK splits.
      reinstall: A boolean indicating if we should keep any existing app data.
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandFailedError if the installation fails.
      CommandTimeoutError if the installation times out.
      DeviceUnreachableError on missing device.
      DeviceVersionError if device SDK is less than Android L.
    """
    self._CheckSdkLevel(constants.ANDROID_SDK_VERSION_CODES.LOLLIPOP)

    all_apks = [base_apk] + split_select.SelectSplits(
        self, base_apk, split_apks)
    package_name = apk_helper.GetPackageName(base_apk)
    device_apk_paths = self.GetApplicationPaths(package_name)

    if device_apk_paths:
      partial_install_package = package_name
      device_checksums = md5sum.CalculateDeviceMd5Sums(device_apk_paths, self)
      host_checksums = md5sum.CalculateHostMd5Sums(all_apks)
      apks_to_install = [k for (k, v) in host_checksums.iteritems()
                         if v not in device_checksums.values()]
      if apks_to_install and not reinstall:
        self.adb.Uninstall(package_name)
        partial_install_package = None
        apks_to_install = all_apks
    else:
      partial_install_package = None
      apks_to_install = all_apks
    if apks_to_install:
      self.adb.InstallMultiple(
          apks_to_install, partial=partial_install_package, reinstall=reinstall)

  def _CheckSdkLevel(self, required_sdk_level):
    """Raises an exception if the device does not have the required SDK level.
    """
    if self.build_version_sdk < required_sdk_level:
      raise device_errors.DeviceVersionError(
          ('Requires SDK level %s, device is SDK level %s' %
           (required_sdk_level, self.build_version_sdk)),
           device_serial=self.adb.GetDeviceSerial())


  @decorators.WithTimeoutAndRetriesFromInstance()
  def RunShellCommand(self, cmd, check_return=False, cwd=None, env=None,
                      as_root=False, single_line=False, large_output=False,
                      timeout=None, retries=None):
    """Run an ADB shell command.

    The command to run |cmd| should be a sequence of program arguments or else
    a single string.

    When |cmd| is a sequence, it is assumed to contain the name of the command
    to run followed by its arguments. In this case, arguments are passed to the
    command exactly as given, without any further processing by the shell. This
    allows to easily pass arguments containing spaces or special characters
    without having to worry about getting quoting right. Whenever possible, it
    is recomended to pass |cmd| as a sequence.

    When |cmd| is given as a string, it will be interpreted and run by the
    shell on the device.

    This behaviour is consistent with that of command runners in cmd_helper as
    well as Python's own subprocess.Popen.

    TODO(perezju) Change the default of |check_return| to True when callers
      have switched to the new behaviour.

    Args:
      cmd: A string with the full command to run on the device, or a sequence
        containing the command and its arguments.
      check_return: A boolean indicating whether or not the return code should
        be checked.
      cwd: The device directory in which the command should be run.
      env: The environment variables with which the command should be run.
      as_root: A boolean indicating whether the shell command should be run
        with root privileges.
      single_line: A boolean indicating if only a single line of output is
        expected.
      large_output: Uses a work-around for large shell command output. Without
        this large output will be truncated.
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      If single_line is False, the output of the command as a list of lines,
      otherwise, a string with the unique line of output emmited by the command
      (with the optional newline at the end stripped).

    Raises:
      AdbCommandFailedError if check_return is True and the exit code of
        the command run on the device is non-zero.
      CommandFailedError if single_line is True but the output contains two or
        more lines.
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    def env_quote(key, value):
      if not DeviceUtils._VALID_SHELL_VARIABLE.match(key):
        raise KeyError('Invalid shell variable name %r' % key)
      # using double quotes here to allow interpolation of shell variables
      return '%s=%s' % (key, cmd_helper.DoubleQuote(value))

    def run(cmd):
      return self.adb.Shell(cmd)

    def handle_check_return(cmd):
      try:
        return run(cmd)
      except device_errors.AdbCommandFailedError as exc:
        if check_return:
          raise
        else:
          return exc.output

    def handle_large_command(cmd):
      if len(cmd) < self._MAX_ADB_COMMAND_LENGTH:
        return handle_check_return(cmd)
      else:
        with device_temp_file.DeviceTempFile(self.adb, suffix='.sh') as script:
          self._WriteFileWithPush(script.name, cmd)
          logging.info('Large shell command will be run from file: %s ...',
                       cmd[:100])
          return handle_check_return('sh %s' % script.name_quoted)

    def handle_large_output(cmd, large_output_mode):
      if large_output_mode:
        with device_temp_file.DeviceTempFile(self.adb) as large_output_file:
          cmd = '%s > %s' % (cmd, large_output_file.name)
          logging.debug('Large output mode enabled. Will write output to '
                        'device and read results from file.')
          handle_large_command(cmd)
          return self.ReadFile(large_output_file.name, force_pull=True)
      else:
        try:
          return handle_large_command(cmd)
        except device_errors.AdbCommandFailedError as exc:
          if exc.status is None:
            logging.exception('No output found for %s', cmd)
            logging.warning('Attempting to run in large_output mode.')
            logging.warning('Use RunShellCommand(..., large_output=True) for '
                            'shell commands that expect a lot of output.')
            return handle_large_output(cmd, True)
          else:
            raise

    if not isinstance(cmd, basestring):
      cmd = ' '.join(cmd_helper.SingleQuote(s) for s in cmd)
    if env:
      env = ' '.join(env_quote(k, v) for k, v in env.iteritems())
      cmd = '%s %s' % (env, cmd)
    if cwd:
      cmd = 'cd %s && %s' % (cmd_helper.SingleQuote(cwd), cmd)
    if as_root and self.NeedsSU():
      # "su -c sh -c" allows using shell features in |cmd|
      cmd = 'su -c sh -c %s' % cmd_helper.SingleQuote(cmd)

    output = handle_large_output(cmd, large_output).splitlines()

    if single_line:
      if not output:
        return ''
      elif len(output) == 1:
        return output[0]
      else:
        msg = 'one line of output was expected, but got: %s'
        raise device_errors.CommandFailedError(msg % output, str(self))
    else:
      return output

  def _RunPipedShellCommand(self, script, **kwargs):
    PIPESTATUS_LEADER = 'PIPESTATUS: '

    script += '; echo "%s${PIPESTATUS[@]}"' % PIPESTATUS_LEADER
    kwargs['check_return'] = True
    output = self.RunShellCommand(script, **kwargs)
    pipestatus_line = output[-1]

    if not pipestatus_line.startswith(PIPESTATUS_LEADER):
      logging.error('Pipe exit statuses of shell script missing.')
      raise device_errors.AdbShellCommandFailedError(
          script, output, status=None,
          device_serial=self.adb.GetDeviceSerial())

    output = output[:-1]
    statuses = [
        int(s) for s in pipestatus_line[len(PIPESTATUS_LEADER):].split()]
    if any(statuses):
      raise device_errors.AdbShellCommandFailedError(
          script, output, status=statuses,
          device_serial=self.adb.GetDeviceSerial())
    return output

  @decorators.WithTimeoutAndRetriesFromInstance()
  def KillAll(self, process_name, signum=device_signal.SIGKILL, as_root=False,
              blocking=False, quiet=False, timeout=None, retries=None):
    """Kill all processes with the given name on the device.

    Args:
      process_name: A string containing the name of the process to kill.
      signum: An integer containing the signal number to send to kill. Defaults
              to SIGKILL (9).
      as_root: A boolean indicating whether the kill should be executed with
               root privileges.
      blocking: A boolean indicating whether we should wait until all processes
                with the given |process_name| are dead.
      quiet: A boolean indicating whether to ignore the fact that no processes
             to kill were found.
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      The number of processes attempted to kill.

    Raises:
      CommandFailedError if no process was killed and |quiet| is False.
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    pids = self.GetPids(process_name)
    if not pids:
      if quiet:
        return 0
      else:
        raise device_errors.CommandFailedError(
            'No process "%s"' % process_name, str(self))

    cmd = ['kill', '-%d' % signum] + pids.values()
    self.RunShellCommand(cmd, as_root=as_root, check_return=True)

    if blocking:
      # TODO(perezu): use timeout_retry.WaitFor
      wait_period = 0.1
      while self.GetPids(process_name):
        time.sleep(wait_period)

    return len(pids)

  @decorators.WithTimeoutAndRetriesFromInstance()
  def StartActivity(self, intent_obj, blocking=False, trace_file_name=None,
                    force_stop=False, timeout=None, retries=None):
    """Start package's activity on the device.

    Args:
      intent_obj: An Intent object to send.
      blocking: A boolean indicating whether we should wait for the activity to
                finish launching.
      trace_file_name: If present, a string that both indicates that we want to
                       profile the activity and contains the path to which the
                       trace should be saved.
      force_stop: A boolean indicating whether we should stop the activity
                  before starting it.
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandFailedError if the activity could not be started.
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    cmd = ['am', 'start']
    if blocking:
      cmd.append('-W')
    if trace_file_name:
      cmd.extend(['--start-profiler', trace_file_name])
    if force_stop:
      cmd.append('-S')
    cmd.extend(intent_obj.am_args)
    for line in self.RunShellCommand(cmd, check_return=True):
      if line.startswith('Error:'):
        raise device_errors.CommandFailedError(line, str(self))

  @decorators.WithTimeoutAndRetriesFromInstance()
  def StartInstrumentation(self, component, finish=True, raw=False,
                           extras=None, timeout=None, retries=None):
    if extras is None:
      extras = {}

    cmd = ['am', 'instrument']
    if finish:
      cmd.append('-w')
    if raw:
      cmd.append('-r')
    for k, v in extras.iteritems():
      cmd.extend(['-e', str(k), str(v)])
    cmd.append(component)
    return self.RunShellCommand(cmd, check_return=True, large_output=True)

  @decorators.WithTimeoutAndRetriesFromInstance()
  def BroadcastIntent(self, intent_obj, timeout=None, retries=None):
    """Send a broadcast intent.

    Args:
      intent: An Intent to broadcast.
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    cmd = ['am', 'broadcast'] + intent_obj.am_args
    self.RunShellCommand(cmd, check_return=True)

  @decorators.WithTimeoutAndRetriesFromInstance()
  def GoHome(self, timeout=None, retries=None):
    """Return to the home screen and obtain launcher focus.

    This command launches the home screen and attempts to obtain
    launcher focus until the timeout is reached.

    Args:
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    def is_launcher_focused():
      output = self.RunShellCommand(['dumpsys', 'window', 'windows'],
                                    check_return=True, large_output=True)
      return any(self._LAUNCHER_FOCUSED_RE.match(l) for l in output)

    def dismiss_popups():
      # There is a dialog present; attempt to get rid of it.
      # Not all dialogs can be dismissed with back.
      self.SendKeyEvent(keyevent.KEYCODE_ENTER)
      self.SendKeyEvent(keyevent.KEYCODE_BACK)
      return is_launcher_focused()

    # If Home is already focused, return early to avoid unnecessary work.
    if is_launcher_focused():
      return

    self.StartActivity(
        intent.Intent(action='android.intent.action.MAIN',
                      category='android.intent.category.HOME'),
        blocking=True)

    if not is_launcher_focused():
      timeout_retry.WaitFor(dismiss_popups, wait_period=1)

  @decorators.WithTimeoutAndRetriesFromInstance()
  def ForceStop(self, package, timeout=None, retries=None):
    """Close the application.

    Args:
      package: A string containing the name of the package to stop.
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    self.RunShellCommand(['am', 'force-stop', package], check_return=True)

  @decorators.WithTimeoutAndRetriesFromInstance()
  def ClearApplicationState(self, package, timeout=None, retries=None):
    """Clear all state for the given package.

    Args:
      package: A string containing the name of the package to stop.
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    # Check that the package exists before clearing it for android builds below
    # JB MR2. Necessary because calling pm clear on a package that doesn't exist
    # may never return.
    if ((self.build_version_sdk >=
         constants.ANDROID_SDK_VERSION_CODES.JELLY_BEAN_MR2)
        or self.GetApplicationPaths(package)):
      self.RunShellCommand(['pm', 'clear', package], check_return=True)

  @decorators.WithTimeoutAndRetriesFromInstance()
  def SendKeyEvent(self, keycode, timeout=None, retries=None):
    """Sends a keycode to the device.

    See the pylib.constants.keyevent module for suitable keycode values.

    Args:
      keycode: A integer keycode to send to the device.
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    self.RunShellCommand(['input', 'keyevent', format(keycode, 'd')],
                         check_return=True)

  PUSH_CHANGED_FILES_DEFAULT_TIMEOUT = 10 * _DEFAULT_TIMEOUT
  PUSH_CHANGED_FILES_DEFAULT_RETRIES = _DEFAULT_RETRIES

  @decorators.WithTimeoutAndRetriesDefaults(
      PUSH_CHANGED_FILES_DEFAULT_TIMEOUT,
      PUSH_CHANGED_FILES_DEFAULT_RETRIES)
  def PushChangedFiles(self, host_device_tuples, timeout=None,
                       retries=None, delete_device_stale=False):
    """Push files to the device, skipping files that don't need updating.

    When a directory is pushed, it is traversed recursively on the host and
    all files in it are pushed to the device as needed.
    Additionally, if delete_device_stale option is True,
    files that exist on the device but don't exist on the host are deleted.

    Args:
      host_device_tuples: A list of (host_path, device_path) tuples, where
        |host_path| is an absolute path of a file or directory on the host
        that should be minimially pushed to the device, and |device_path| is
        an absolute path of the destination on the device.
      timeout: timeout in seconds
      retries: number of retries
      delete_device_stale: option to delete stale files on device

    Raises:
      CommandFailedError on failure.
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """

    all_changed_files = []
    all_stale_files = []
    for h, d in host_device_tuples:
      if os.path.isdir(h):
        self.RunShellCommand(['mkdir', '-p', d], check_return=True)
      (changed_files, stale_files) = self._GetChangedAndStaleFiles(h, d)
      all_changed_files += changed_files
      all_stale_files += stale_files

    if delete_device_stale:
      self.RunShellCommand(['rm', '-f'] + all_stale_files,
                             check_return=True)

    if not all_changed_files:
      return

    self._PushFilesImpl(host_device_tuples, all_changed_files)

  def _GetChangedAndStaleFiles(self, host_path, device_path):
    """Get files to push and delete

    Args:
      host_path: an absolute path of a file or directory on the host
      device_path: an absolute path of a file or directory on the device

    Returns:
      a two-element tuple
      1st element: a list of (host_files_path, device_files_path) tuples to push
      2nd element: a list of stale files under device_path
    """
    real_host_path = os.path.realpath(host_path)
    try:
      real_device_path = self.RunShellCommand(
          ['realpath', device_path], single_line=True, check_return=True)
    except device_errors.CommandFailedError:
      real_device_path = None
    if not real_device_path:
      return ([(host_path, device_path)], [])

    try:
      host_checksums = md5sum.CalculateHostMd5Sums([real_host_path])
      device_checksums = md5sum.CalculateDeviceMd5Sums(
        [real_device_path], self)
    except EnvironmentError as e:
      logging.warning('Error calculating md5: %s', e)
      return ([(host_path, device_path)], [])

    if os.path.isfile(host_path):
      host_checksum = host_checksums.get(real_host_path)
      device_checksum = device_checksums.get(real_device_path)
      if host_checksum != device_checksum:
        return ([(host_path, device_path)], [])
      else:
        return ([], [])
    else:
      to_push = []
      for host_abs_path, host_checksum in host_checksums.iteritems():
        device_abs_path = '%s/%s' % (
            real_device_path, os.path.relpath(host_abs_path, real_host_path))
        device_checksum = device_checksums.pop(device_abs_path, None)
        if device_checksum != host_checksum:
          to_push.append((host_abs_path, device_abs_path))
      to_delete = device_checksums.keys()
      return (to_push, to_delete)

  def _PushFilesImpl(self, host_device_tuples, files):
    size = sum(host_utils.GetRecursiveDiskUsage(h) for h, _ in files)
    file_count = len(files)
    dir_size = sum(host_utils.GetRecursiveDiskUsage(h)
                   for h, _ in host_device_tuples)
    dir_file_count = 0
    for h, _ in host_device_tuples:
      if os.path.isdir(h):
        dir_file_count += sum(len(f) for _r, _d, f in os.walk(h))
      else:
        dir_file_count += 1

    push_duration = self._ApproximateDuration(
        file_count, file_count, size, False)
    dir_push_duration = self._ApproximateDuration(
        len(host_device_tuples), dir_file_count, dir_size, False)
    zip_duration = self._ApproximateDuration(1, 1, size, True)

    self._InstallCommands()

    if dir_push_duration < push_duration and (
        dir_push_duration < zip_duration or not self._commands_installed):
      self._PushChangedFilesIndividually(host_device_tuples)
    elif push_duration < zip_duration or not self._commands_installed:
      self._PushChangedFilesIndividually(files)
    else:
      self._PushChangedFilesZipped(files)
      self.RunShellCommand(
          ['chmod', '-R', '777'] + [d for _, d in host_device_tuples],
          as_root=True, check_return=True)

  def _InstallCommands(self):
    if self._commands_installed is None:
      try:
        if not install_commands.Installed(self):
          install_commands.InstallCommands(self)
        self._commands_installed = True
      except Exception as e:
        logging.warning('unzip not available: %s' % str(e))
        self._commands_installed = False

  @staticmethod
  def _ApproximateDuration(adb_calls, file_count, byte_count, is_zipping):
    # We approximate the time to push a set of files to a device as:
    #   t = c1 * a + c2 * f + c3 + b / c4 + b / (c5 * c6), where
    #     t: total time (sec)
    #     c1: adb call time delay (sec)
    #     a: number of times adb is called (unitless)
    #     c2: push time delay (sec)
    #     f: number of files pushed via adb (unitless)
    #     c3: zip time delay (sec)
    #     c4: zip rate (bytes/sec)
    #     b: total number of bytes (bytes)
    #     c5: transfer rate (bytes/sec)
    #     c6: compression ratio (unitless)

    # All of these are approximations.
    ADB_CALL_PENALTY = 0.1 # seconds
    ADB_PUSH_PENALTY = 0.01 # seconds
    ZIP_PENALTY = 2.0 # seconds
    ZIP_RATE = 10000000.0 # bytes / second
    TRANSFER_RATE = 2000000.0 # bytes / second
    COMPRESSION_RATIO = 2.0 # unitless

    adb_call_time = ADB_CALL_PENALTY * adb_calls
    adb_push_setup_time = ADB_PUSH_PENALTY * file_count
    if is_zipping:
      zip_time = ZIP_PENALTY + byte_count / ZIP_RATE
      transfer_time = byte_count / (TRANSFER_RATE * COMPRESSION_RATIO)
    else:
      zip_time = 0
      transfer_time = byte_count / TRANSFER_RATE
    return adb_call_time + adb_push_setup_time + zip_time + transfer_time

  def _PushChangedFilesIndividually(self, files):
    for h, d in files:
      self.adb.Push(h, d)

  def _PushChangedFilesZipped(self, files):
    if not files:
      return

    with tempfile.NamedTemporaryFile(suffix='.zip') as zip_file:
      zip_proc = multiprocessing.Process(
          target=DeviceUtils._CreateDeviceZip,
          args=(zip_file.name, files))
      zip_proc.start()
      zip_proc.join()

      zip_on_device = '%s/tmp.zip' % self.GetExternalStoragePath()
      try:
        self.adb.Push(zip_file.name, zip_on_device)
        self.RunShellCommand(
            ['unzip', zip_on_device],
            as_root=True,
            env={'PATH': '%s:$PATH' % install_commands.BIN_DIR},
            check_return=True)
      finally:
        if zip_proc.is_alive():
          zip_proc.terminate()
        if self.IsOnline():
          self.RunShellCommand(['rm', zip_on_device], check_return=True)

  @staticmethod
  def _CreateDeviceZip(zip_path, host_device_tuples):
    with zipfile.ZipFile(zip_path, 'w') as zip_file:
      for host_path, device_path in host_device_tuples:
        zip_utils.WriteToZipFile(zip_file, host_path, device_path)

  @decorators.WithTimeoutAndRetriesFromInstance()
  def FileExists(self, device_path, timeout=None, retries=None):
    """Checks whether the given file exists on the device.

    Args:
      device_path: A string containing the absolute path to the file on the
                   device.
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      True if the file exists on the device, False otherwise.

    Raises:
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    try:
      self.RunShellCommand(['test', '-e', device_path], check_return=True)
      return True
    except device_errors.AdbCommandFailedError:
      return False

  @decorators.WithTimeoutAndRetriesFromInstance()
  def PullFile(self, device_path, host_path, timeout=None, retries=None):
    """Pull a file from the device.

    Args:
      device_path: A string containing the absolute path of the file to pull
                   from the device.
      host_path: A string containing the absolute path of the destination on
                 the host.
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandFailedError on failure.
      CommandTimeoutError on timeout.
    """
    # Create the base dir if it doesn't exist already
    dirname = os.path.dirname(host_path)
    if dirname and not os.path.exists(dirname):
      os.makedirs(dirname)
    self.adb.Pull(device_path, host_path)

  def _ReadFileWithPull(self, device_path):
    try:
      d = tempfile.mkdtemp()
      host_temp_path = os.path.join(d, 'tmp_ReadFileWithPull')
      self.adb.Pull(device_path, host_temp_path)
      with open(host_temp_path, 'r') as host_temp:
        return host_temp.read()
    finally:
      if os.path.exists(d):
        shutil.rmtree(d)

  _LS_RE = re.compile(
      r'(?P<perms>\S+) +(?P<owner>\S+) +(?P<group>\S+) +(?:(?P<size>\d+) +)?'
      + r'(?P<date>\S+) +(?P<time>\S+) +(?P<name>.+)$')

  @decorators.WithTimeoutAndRetriesFromInstance()
  def ReadFile(self, device_path, as_root=False, force_pull=False,
               timeout=None, retries=None):
    """Reads the contents of a file from the device.

    Args:
      device_path: A string containing the absolute path of the file to read
                   from the device.
      as_root: A boolean indicating whether the read should be executed with
               root privileges.
      force_pull: A boolean indicating whether to force the operation to be
          performed by pulling a file from the device. The default is, when the
          contents are short, to retrieve the contents using cat instead.
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      The contents of |device_path| as a string. Contents are intepreted using
      universal newlines, so the caller will see them encoded as '\n'. Also,
      all lines will be terminated.

    Raises:
      AdbCommandFailedError if the file can't be read.
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    def get_size(path):
      # TODO(jbudorick): Implement a generic version of Stat() that handles
      # as_root=True, then switch this implementation to use that.
      ls_out = self.RunShellCommand(['ls', '-l', device_path], as_root=as_root,
                                    check_return=True)
      for line in ls_out:
        m = self._LS_RE.match(line)
        if m and m.group('name') == posixpath.basename(device_path):
          return int(m.group('size'))
      logging.warning('Could not determine size of %s.', device_path)
      return None

    if (not force_pull
        and 0 < get_size(device_path) <= self._MAX_ADB_OUTPUT_LENGTH):
      return _JoinLines(self.RunShellCommand(
          ['cat', device_path], as_root=as_root, check_return=True))
    elif as_root and self.NeedsSU():
      with device_temp_file.DeviceTempFile(self.adb) as device_temp:
        self.RunShellCommand(['cp', device_path, device_temp.name],
                             as_root=True, check_return=True)
        return self._ReadFileWithPull(device_temp.name)
    else:
      return self._ReadFileWithPull(device_path)

  def _WriteFileWithPush(self, device_path, contents):
    with tempfile.NamedTemporaryFile() as host_temp:
      host_temp.write(contents)
      host_temp.flush()
      self.adb.Push(host_temp.name, device_path)

  @decorators.WithTimeoutAndRetriesFromInstance()
  def WriteFile(self, device_path, contents, as_root=False, force_push=False,
                timeout=None, retries=None):
    """Writes |contents| to a file on the device.

    Args:
      device_path: A string containing the absolute path to the file to write
          on the device.
      contents: A string containing the data to write to the device.
      as_root: A boolean indicating whether the write should be executed with
          root privileges (if available).
      force_push: A boolean indicating whether to force the operation to be
          performed by pushing a file to the device. The default is, when the
          contents are short, to pass the contents using a shell script instead.
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandFailedError if the file could not be written on the device.
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    if not force_push and len(contents) < self._MAX_ADB_COMMAND_LENGTH:
      # If the contents are small, for efficieny we write the contents with
      # a shell command rather than pushing a file.
      cmd = 'echo -n %s > %s' % (cmd_helper.SingleQuote(contents),
                                 cmd_helper.SingleQuote(device_path))
      self.RunShellCommand(cmd, as_root=as_root, check_return=True)
    elif as_root and self.NeedsSU():
      # Adb does not allow to "push with su", so we first push to a temp file
      # on a safe location, and then copy it to the desired location with su.
      with device_temp_file.DeviceTempFile(self.adb) as device_temp:
        self._WriteFileWithPush(device_temp.name, contents)
        # Here we need 'cp' rather than 'mv' because the temp and
        # destination files might be on different file systems (e.g.
        # on internal storage and an external sd card).
        self.RunShellCommand(['cp', device_temp.name, device_path],
                             as_root=True, check_return=True)
    else:
      # If root is not needed, we can push directly to the desired location.
      self._WriteFileWithPush(device_path, contents)

  @decorators.WithTimeoutAndRetriesFromInstance()
  def Ls(self, device_path, timeout=None, retries=None):
    """Lists the contents of a directory on the device.

    Args:
      device_path: A string containing the path of the directory on the device
                   to list.
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      A list of pairs (filename, stat) for each file found in the directory,
      where the stat object has the properties: st_mode, st_size, and st_time.

    Raises:
      AdbCommandFailedError if |device_path| does not specify a valid and
          accessible directory in the device.
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    return self.adb.Ls(device_path)

  @decorators.WithTimeoutAndRetriesFromInstance()
  def Stat(self, device_path, timeout=None, retries=None):
    """Get the stat attributes of a file or directory on the device.

    Args:
      device_path: A string containing the path of from which to get attributes
                   on the device.
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      A stat object with the properties: st_mode, st_size, and st_time

    Raises:
      CommandFailedError if device_path cannot be found on the device.
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    dirname, target = device_path.rsplit('/', 1)
    for filename, stat in self.adb.Ls(dirname):
      if filename == target:
        return stat
    raise device_errors.CommandFailedError(
        'Cannot find file or directory: %r' % device_path, str(self))

  @decorators.WithTimeoutAndRetriesFromInstance()
  def SetJavaAsserts(self, enabled, timeout=None, retries=None):
    """Enables or disables Java asserts.

    Args:
      enabled: A boolean indicating whether Java asserts should be enabled
               or disabled.
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      True if the device-side property changed and a restart is required as a
      result, False otherwise.

    Raises:
      CommandTimeoutError on timeout.
    """
    def find_property(lines, property_name):
      for index, line in enumerate(lines):
        if line.strip() == '':
          continue
        key, value = (s.strip() for s in line.split('=', 1))
        if key == property_name:
          return index, value
      return None, ''

    new_value = 'all' if enabled else ''

    # First ensure the desired property is persisted.
    try:
      properties = self.ReadFile(
          constants.DEVICE_LOCAL_PROPERTIES_PATH).splitlines()
    except device_errors.CommandFailedError:
      properties = []
    index, value = find_property(properties, self.JAVA_ASSERT_PROPERTY)
    if new_value != value:
      if new_value:
        new_line = '%s=%s' % (self.JAVA_ASSERT_PROPERTY, new_value)
        if index is None:
          properties.append(new_line)
        else:
          properties[index] = new_line
      else:
        assert index is not None # since new_value == '' and new_value != value
        properties.pop(index)
      self.WriteFile(constants.DEVICE_LOCAL_PROPERTIES_PATH,
                     _JoinLines(properties))

    # Next, check the current runtime value is what we need, and
    # if not, set it and report that a reboot is required.
    value = self.GetProp(self.JAVA_ASSERT_PROPERTY)
    if new_value != value:
      self.SetProp(self.JAVA_ASSERT_PROPERTY, new_value)
      return True
    else:
      return False

  @property
  def language(self):
    """Returns the language setting on the device."""
    return self.GetProp('persist.sys.language', cache=False)

  @property
  def country(self):
    """Returns the country setting on the device."""
    return self.GetProp('persist.sys.country', cache=False)

  @property
  def screen_density(self):
    """Returns the screen density of the device."""
    DPI_TO_DENSITY = {
      120: 'ldpi',
      160: 'mdpi',
      240: 'hdpi',
      320: 'xhdpi',
      480: 'xxhdpi',
      640: 'xxxhdpi',
    }
    dpi = int(self.GetProp('ro.sf.lcd_density', cache=True))
    return DPI_TO_DENSITY.get(dpi, 'tvdpi')

  @property
  def build_description(self):
    """Returns the build description of the system.

    For example:
      nakasi-user 4.4.4 KTU84P 1227136 release-keys
    """
    return self.GetProp('ro.build.description', cache=True)

  @property
  def build_fingerprint(self):
    """Returns the build fingerprint of the system.

    For example:
      google/nakasi/grouper:4.4.4/KTU84P/1227136:user/release-keys
    """
    return self.GetProp('ro.build.fingerprint', cache=True)

  @property
  def build_id(self):
    """Returns the build ID of the system (e.g. 'KTU84P')."""
    return self.GetProp('ro.build.id', cache=True)

  @property
  def build_product(self):
    """Returns the build product of the system (e.g. 'grouper')."""
    return self.GetProp('ro.build.product', cache=True)

  @property
  def build_type(self):
    """Returns the build type of the system (e.g. 'user')."""
    return self.GetProp('ro.build.type', cache=True)

  @property
  def build_version_sdk(self):
    """Returns the build version sdk of the system as a number (e.g. 19).

    For version code numbers see:
    http://developer.android.com/reference/android/os/Build.VERSION_CODES.html

    For named constants see:
    pylib.constants.ANDROID_SDK_VERSION_CODES

    Raises:
      CommandFailedError if the build version sdk is not a number.
    """
    value = self.GetProp('ro.build.version.sdk', cache=True)
    try:
      return int(value)
    except ValueError:
      raise device_errors.CommandFailedError(
          'Invalid build version sdk: %r' % value)

  @property
  def product_cpu_abi(self):
    """Returns the product cpu abi of the device (e.g. 'armeabi-v7a')."""
    return self.GetProp('ro.product.cpu.abi', cache=True)

  @property
  def product_model(self):
    """Returns the name of the product model (e.g. 'Nexus 7')."""
    return self.GetProp('ro.product.model', cache=True)

  @property
  def product_name(self):
    """Returns the product name of the device (e.g. 'nakasi')."""
    return self.GetProp('ro.product.name', cache=True)

  def GetProp(self, property_name, cache=False, timeout=DEFAULT,
              retries=DEFAULT):
    """Gets a property from the device.

    Args:
      property_name: A string containing the name of the property to get from
                     the device.
      cache: A boolean indicating whether to cache the value of this property.
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      The value of the device's |property_name| property.

    Raises:
      CommandTimeoutError on timeout.
    """
    assert isinstance(property_name, basestring), (
        "property_name is not a string: %r" % property_name)

    cache_key = '_prop:' + property_name
    if cache and cache_key in self._cache:
      return self._cache[cache_key]
    else:
      # timeout and retries are handled down at run shell, because we don't
      # want to apply them in the other branch when reading from the cache
      value = self.RunShellCommand(
          ['getprop', property_name], single_line=True, check_return=True,
          timeout=self._default_timeout if timeout is DEFAULT else timeout,
          retries=self._default_retries if retries is DEFAULT else retries)
      if cache or cache_key in self._cache:
        self._cache[cache_key] = value
      return value

  @decorators.WithTimeoutAndRetriesFromInstance()
  def SetProp(self, property_name, value, check=False, timeout=None,
              retries=None):
    """Sets a property on the device.

    Args:
      property_name: A string containing the name of the property to set on
                     the device.
      value: A string containing the value to set to the property on the
             device.
      check: A boolean indicating whether to check that the property was
             successfully set on the device.
      timeout: timeout in seconds
      retries: number of retries

    Raises:
      CommandFailedError if check is true and the property was not correctly
        set on the device (e.g. because it is not rooted).
      CommandTimeoutError on timeout.
    """
    assert isinstance(property_name, basestring), (
        "property_name is not a string: %r" % property_name)
    assert isinstance(value, basestring), "value is not a string: %r" % value

    self.RunShellCommand(['setprop', property_name, value], check_return=True)
    if property_name in self._cache:
      del self._cache[property_name]
    # TODO(perezju) remove the option and make the check mandatory, but using a
    # single shell script to both set- and getprop.
    if check and value != self.GetProp(property_name):
      raise device_errors.CommandFailedError(
          'Unable to set property %r on the device to %r'
          % (property_name, value), str(self))

  @decorators.WithTimeoutAndRetriesFromInstance()
  def GetABI(self, timeout=None, retries=None):
    """Gets the device main ABI.

    Args:
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      The device's main ABI name.

    Raises:
      CommandTimeoutError on timeout.
    """
    return self.GetProp('ro.product.cpu.abi')

  @decorators.WithTimeoutAndRetriesFromInstance()
  def GetPids(self, process_name, timeout=None, retries=None):
    """Returns the PIDs of processes with the given name.

    Note that the |process_name| is often the package name.

    Args:
      process_name: A string containing the process name to get the PIDs for.
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      A dict mapping process name to PID for each process that contained the
      provided |process_name|.

    Raises:
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    procs_pids = {}
    try:
      ps_output = self._RunPipedShellCommand(
          'ps | grep -F %s' % cmd_helper.SingleQuote(process_name))
    except device_errors.AdbShellCommandFailedError as e:
      if e.status and isinstance(e.status, list) and not e.status[0]:
        # If ps succeeded but grep failed, there were no processes with the
        # given name.
        return procs_pids
      else:
        raise

    for line in ps_output:
      try:
        ps_data = line.split()
        if process_name in ps_data[-1]:
          procs_pids[ps_data[-1]] = ps_data[1]
      except IndexError:
        pass
    return procs_pids

  @decorators.WithTimeoutAndRetriesFromInstance()
  def TakeScreenshot(self, host_path=None, timeout=None, retries=None):
    """Takes a screenshot of the device.

    Args:
      host_path: A string containing the path on the host to save the
                 screenshot to. If None, a file name in the current
                 directory will be generated.
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      The name of the file on the host to which the screenshot was saved.

    Raises:
      CommandFailedError on failure.
      CommandTimeoutError on timeout.
      DeviceUnreachableError on missing device.
    """
    if not host_path:
      host_path = os.path.abspath('screenshot-%s.png' % _GetTimeStamp())
    with device_temp_file.DeviceTempFile(self.adb, suffix='.png') as device_tmp:
      self.RunShellCommand(['/system/bin/screencap', '-p', device_tmp.name],
                           check_return=True)
      self.PullFile(device_tmp.name, host_path)
    return host_path

  @decorators.WithTimeoutAndRetriesFromInstance()
  def GetMemoryUsageForPid(self, pid, timeout=None, retries=None):
    """Gets the memory usage for the given PID.

    Args:
      pid: PID of the process.
      timeout: timeout in seconds
      retries: number of retries

    Returns:
      A dict containing memory usage statistics for the PID. May include:
        Size, Rss, Pss, Shared_Clean, Shared_Dirty, Private_Clean,
        Private_Dirty, VmHWM

    Raises:
      CommandTimeoutError on timeout.
    """
    result = collections.defaultdict(int)

    try:
      result.update(self._GetMemoryUsageForPidFromSmaps(pid))
    except device_errors.CommandFailedError:
      logging.exception('Error getting memory usage from smaps')

    try:
      result.update(self._GetMemoryUsageForPidFromStatus(pid))
    except device_errors.CommandFailedError:
      logging.exception('Error getting memory usage from status')

    return result

  def _GetMemoryUsageForPidFromSmaps(self, pid):
    SMAPS_COLUMNS = (
        'Size', 'Rss', 'Pss', 'Shared_Clean', 'Shared_Dirty', 'Private_Clean',
        'Private_Dirty')

    showmap_out = self._RunPipedShellCommand(
        'showmap %d | grep TOTAL' % int(pid), as_root=True)

    split_totals = showmap_out[-1].split()
    if (not split_totals
        or len(split_totals) != 9
        or split_totals[-1] != 'TOTAL'):
      raise device_errors.CommandFailedError(
          'Invalid output from showmap: %s' % '\n'.join(showmap_out))

    return dict(itertools.izip(SMAPS_COLUMNS, (int(n) for n in split_totals)))

  def _GetMemoryUsageForPidFromStatus(self, pid):
    for line in self.ReadFile(
        '/proc/%s/status' % str(pid), as_root=True).splitlines():
      if line.startswith('VmHWM:'):
        return {'VmHWM': int(line.split()[1])}
    else:
      raise device_errors.CommandFailedError(
          'Could not find memory peak value for pid %s', str(pid))

  @decorators.WithTimeoutAndRetriesFromInstance()
  def GetLogcatMonitor(self, timeout=None, retries=None, *args, **kwargs):
    """Returns a new LogcatMonitor associated with this device.

    Parameters passed to this function are passed directly to
    |logcat_monitor.LogcatMonitor| and are documented there.

    Args:
      timeout: timeout in seconds
      retries: number of retries
    """
    return logcat_monitor.LogcatMonitor(self.adb, *args, **kwargs)

  def GetClientCache(self, client_name):
    """Returns client cache."""
    if client_name not in self._client_caches:
      self._client_caches[client_name] = {}
    return self._client_caches[client_name]

  def _ClearCache(self):
    """Clears all caches."""
    for client in self._client_caches:
      self._client_caches[client].clear()
    self._cache.clear()

  @classmethod
  def parallel(cls, devices=None, async=False):
    """Creates a Parallelizer to operate over the provided list of devices.

    If |devices| is either |None| or an empty list, the Parallelizer will
    operate over all attached devices that have not been blacklisted.

    Args:
      devices: A list of either DeviceUtils instances or objects from
               from which DeviceUtils instances can be constructed. If None,
               all attached devices will be used.
      async: If true, returns a Parallelizer that runs operations
             asynchronously.

    Returns:
      A Parallelizer operating over |devices|.
    """
    if not devices:
      devices = cls.HealthyDevices()
      if not devices:
        raise device_errors.NoDevicesError()

    devices = [d if isinstance(d, cls) else cls(d) for d in devices]
    if async:
      return parallelizer.Parallelizer(devices)
    else:
      return parallelizer.SyncParallelizer(devices)

  @classmethod
  def HealthyDevices(cls):
    blacklist = device_blacklist.ReadBlacklist()
    def blacklisted(adb):
      if adb.GetDeviceSerial() in blacklist:
        logging.warning('Device %s is blacklisted.', adb.GetDeviceSerial())
        return True
      return False

    return [cls(adb) for adb in adb_wrapper.AdbWrapper.Devices()
            if not blacklisted(adb)]
