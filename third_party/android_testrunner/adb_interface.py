#!/usr/bin/python2.4
#
#
# Copyright 2008, The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Provides an interface to communicate with the device via the adb command.

Assumes adb binary is currently on system path.
"""
# Python imports
import os
import string
import time

# local imports
import am_instrument_parser
import errors
import logger
import run_command


class AdbInterface:
  """Helper class for communicating with Android device via adb."""

  DEVICE_TRACE_DIR = "/data/test_results/"

  def __init__(self, adb_path='adb'):
    """Constructor.

    Args:
      adb_path: Absolute path to the adb binary that should be used. Defaults
                to the adb in the environment path.
    """
    self._adb_path = adb_path
    # argument to pass to adb, to direct command to specific device
    self._target_arg = ""

  def SetEmulatorTarget(self):
    """Direct all future commands to the only running emulator."""
    self._target_arg = "-e"

  def SetDeviceTarget(self):
    """Direct all future commands to the only connected USB device."""
    self._target_arg = "-d"

  def SetTargetSerial(self, serial):
    """Direct all future commands to Android target with the given serial."""
    self._target_arg = "-s %s" % serial

  def SendCommand(self, command_string, timeout_time=20, retry_count=3):
    """Send a command via adb.

    Args:
      command_string: adb command to run
      timeout_time: number of seconds to wait for command to respond before
        retrying
      retry_count: number of times to retry command before raising
        WaitForResponseTimedOutError
    Returns:
      string output of command

    Raises:
      WaitForResponseTimedOutError if device does not respond to command within time
    """
    adb_cmd = "%s %s %s" % (self._adb_path, self._target_arg, command_string)
    logger.SilentLog("about to run %s" % adb_cmd)
    return run_command.RunCommand(adb_cmd, timeout_time=timeout_time,
                                  retry_count=retry_count)

  def SendShellCommand(self, cmd, timeout_time=20, retry_count=3):
    """Send a adb shell command.

    Args:
      cmd: adb shell command to run
      timeout_time: number of seconds to wait for command to respond before
        retrying
      retry_count: number of times to retry command before raising
        WaitForResponseTimedOutError

    Returns:
      string output of command

    Raises:
      WaitForResponseTimedOutError: if device does not respond to command
    """
    return self.SendCommand("shell %s" % cmd, timeout_time=timeout_time,
                            retry_count=retry_count)

  def BugReport(self, path):
    """Dumps adb bugreport to the file specified by the path.

    Args:
      path: Path of the file where adb bugreport is dumped to.
    """
    bug_output = self.SendShellCommand("bugreport", timeout_time=60)
    bugreport_file = open(path, "w")
    bugreport_file.write(bug_output)
    bugreport_file.close()

  def Push(self, src, dest):
    """Pushes the file src onto the device at dest.

    Args:
      src: file path of host file to push
      dest: destination absolute file path on device
    """
    self.SendCommand("push %s %s" % (src, dest), timeout_time=60)

  def Pull(self, src, dest):
    """Pulls the file src on the device onto dest on the host.

    Args:
      src: absolute file path of file on device to pull
      dest: destination file path on host

    Returns:
      True if success and False otherwise.
    """
    # Create the base dir if it doesn't exist already
    if not os.path.exists(os.path.dirname(dest)):
      os.makedirs(os.path.dirname(dest))

    if self.DoesFileExist(src):
      self.SendCommand("pull %s %s" % (src, dest), timeout_time=60)
      return True
    else:
      logger.Log("ADB Pull Failed: Source file %s does not exist." % src)
      return False

  def DoesFileExist(self, src):
    """Checks if the given path exists on device target.

    Args:
      src: file path to be checked.

    Returns:
      True if file exists
    """

    output = self.SendShellCommand("ls %s" % src)
    error = "No such file or directory"

    if error in output:
      return False
    return True

  def EnableAdbRoot(self):
    """Enable adb root on device."""
    output = self.SendCommand("root")
    if "adbd is already running as root" in output:
      return True
    elif "restarting adbd as root" in output:
      # device will disappear from adb, wait for it to come back
      self.SendCommand("wait-for-device")
      return True
    else:
      logger.Log("Unrecognized output from adb root: %s" % output)
      return False

  def StartInstrumentationForPackage(
      self, package_name, runner_name, timeout_time=60*10,
      no_window_animation=False, instrumentation_args={}):
    """Run instrumentation test for given package and runner.

    Equivalent to StartInstrumentation, except instrumentation path is
    separated into its package and runner components.
    """
    instrumentation_path = "%s/%s" % (package_name, runner_name)
    return self.StartInstrumentation(instrumentation_path, timeout_time=timeout_time,
                                     no_window_animation=no_window_animation,
                                     instrumentation_args=instrumentation_args)

  def StartInstrumentation(
      self, instrumentation_path, timeout_time=60*10, no_window_animation=False,
      profile=False, instrumentation_args={}, silent_log=False):

    """Runs an instrumentation class on the target.

    Returns a dictionary containing the key value pairs from the
    instrumentations result bundle and a list of TestResults. Also handles the
    interpreting of error output from the device and raises the necessary
    exceptions.

    Args:
      instrumentation_path: string. It should be the fully classified package
      name, and instrumentation test runner, separated by "/"
        e.g. com.android.globaltimelaunch/.GlobalTimeLaunch
      timeout_time: Timeout value for the am command.
      no_window_animation: boolean, Whether you want window animations enabled
        or disabled
      profile: If True, profiling will be turned on for the instrumentation.
      instrumentation_args: Dictionary of key value bundle arguments to pass to
      instrumentation.
      silent_log: If True, the invocation of the instrumentation test runner
        will not be logged.

    Returns:
      (test_results, inst_finished_bundle)

      test_results: a list of TestResults
      inst_finished_bundle (dict): Key/value pairs contained in the bundle that
        is passed into ActivityManager.finishInstrumentation(). Included in this
        bundle is the return code of the Instrumentation process, any error
        codes reported by the activity manager, and any results explicitly added
        by the instrumentation code.

     Raises:
       WaitForResponseTimedOutError: if timeout occurred while waiting for
         response to adb instrument command
       DeviceUnresponsiveError: if device system process is not responding
       InstrumentationError: if instrumentation failed to run
    """

    command_string = self._BuildInstrumentationCommandPath(
        instrumentation_path, no_window_animation=no_window_animation,
        profile=profile, raw_mode=True,
        instrumentation_args=instrumentation_args)
    if silent_log:
      logger.SilentLog(command_string)
    else:
      logger.Log(command_string)
    (test_results, inst_finished_bundle) = (
        am_instrument_parser.ParseAmInstrumentOutput(
            self.SendShellCommand(command_string, timeout_time=timeout_time,
                                  retry_count=2)))
    if "code" not in inst_finished_bundle:
      logger.Log('No code available. inst_finished_bundle contains: %s '
                 % inst_finished_bundle)
      raise errors.InstrumentationError("no test results... device setup "
                                        "correctly?")

    if inst_finished_bundle["code"] == "0":
      long_msg_result = "no error message"
      if "longMsg" in inst_finished_bundle:
        long_msg_result = inst_finished_bundle["longMsg"]
        logger.Log("Error! Test run failed: %s" % long_msg_result)
      raise errors.InstrumentationError(long_msg_result)

    if "INSTRUMENTATION_ABORTED" in inst_finished_bundle:
      logger.Log("INSTRUMENTATION ABORTED!")
      raise errors.DeviceUnresponsiveError

    return (test_results, inst_finished_bundle)

  def StartInstrumentationNoResults(
      self, package_name, runner_name, no_window_animation=False,
      raw_mode=False, instrumentation_args={}):
    """Runs instrumentation and dumps output to stdout.

    Equivalent to StartInstrumentation, but will dump instrumentation
    'normal' output to stdout, instead of parsing return results. Command will
    never timeout.
    """
    adb_command_string = self.PreviewInstrumentationCommand(
        package_name, runner_name, no_window_animation=no_window_animation,
        raw_mode=raw_mode, instrumentation_args=instrumentation_args)
    logger.Log(adb_command_string)
    run_command.RunCommand(adb_command_string, return_output=False)

  def PreviewInstrumentationCommand(
      self, package_name, runner_name, no_window_animation=False,
      raw_mode=False, instrumentation_args={}):
    """Returns a string of adb command that will be executed."""
    inst_command_string = self._BuildInstrumentationCommand(
        package_name, runner_name, no_window_animation=no_window_animation,
        raw_mode=raw_mode, instrumentation_args=instrumentation_args)
    command_string = "adb %s shell %s" % (self._target_arg, inst_command_string)
    return command_string

  def _BuildInstrumentationCommand(
      self, package, runner_name, no_window_animation=False, profile=False,
      raw_mode=True, instrumentation_args={}):
    instrumentation_path = "%s/%s" % (package, runner_name)

    return self._BuildInstrumentationCommandPath(
        instrumentation_path, no_window_animation=no_window_animation,
        profile=profile, raw_mode=raw_mode,
        instrumentation_args=instrumentation_args)

  def _BuildInstrumentationCommandPath(
      self, instrumentation_path, no_window_animation=False, profile=False,
      raw_mode=True, instrumentation_args={}):
    command_string = "am instrument"
    if no_window_animation:
      command_string += " --no_window_animation"
    if profile:
      self._CreateTraceDir()
      command_string += (
          " -p %s/%s.dmtrace" %
          (self.DEVICE_TRACE_DIR, instrumentation_path.split(".")[-1]))

    for key, value in instrumentation_args.items():
      command_string += " -e %s '%s'" % (key, value)
    if raw_mode:
      command_string += " -r"
    command_string += " -w %s" % instrumentation_path
    return command_string

  def _CreateTraceDir(self):
    ls_response = self.SendShellCommand("ls /data/trace")
    if ls_response.strip("#").strip(string.whitespace) != "":
      self.SendShellCommand("create /data/trace", "mkdir /data/trace")
      self.SendShellCommand("make /data/trace world writeable",
                            "chmod 777 /data/trace")

  def WaitForDevicePm(self, wait_time=120):
    """Waits for targeted device's package manager to be up.

    Args:
      wait_time: time in seconds to wait

    Raises:
      WaitForResponseTimedOutError if wait_time elapses and pm still does not
      respond.
    """
    logger.Log("Waiting for device package manager...")
    self.SendCommand("wait-for-device", timeout_time=wait_time, retry_count=0)
    # Now the device is there, but may not be running.
    # Query the package manager with a basic command
    try:
      self._WaitForShellCommandContents("pm path android", "package:",
                                        wait_time)
    except errors.WaitForResponseTimedOutError:
      raise errors.WaitForResponseTimedOutError(
          "Package manager did not respond after %s seconds" % wait_time)

  def WaitForInstrumentation(self, package_name, runner_name, wait_time=120):
    """Waits for given instrumentation to be present on device

    Args:
      wait_time: time in seconds to wait

    Raises:
      WaitForResponseTimedOutError if wait_time elapses and instrumentation
      still not present.
    """
    instrumentation_path = "%s/%s" % (package_name, runner_name)
    logger.Log("Waiting for instrumentation to be present")
    # Query the package manager
    try:
      command = "pm list instrumentation | grep %s" % instrumentation_path
      self._WaitForShellCommandContents(command, "instrumentation:", wait_time,
                                        raise_abort=False)
    except errors.WaitForResponseTimedOutError :
      logger.Log(
          "Could not find instrumentation %s on device. Does the "
          "instrumentation in test's AndroidManifest.xml match definition"
          "in test_defs.xml?" % instrumentation_path)
      raise

  def WaitForProcess(self, name, wait_time=120):
    """Wait until a process is running on the device.

    Args:
      name: the process name as it appears in `ps`
      wait_time: time in seconds to wait

    Raises:
      WaitForResponseTimedOutError if wait_time elapses and the process is
          still not running
    """
    logger.Log("Waiting for process %s" % name)
    self.SendCommand("wait-for-device")
    self._WaitForShellCommandContents("ps", name, wait_time)

  def WaitForProcessEnd(self, name, wait_time=120):
    """Wait until a process is no longer running on the device.

    Args:
      name: the process name as it appears in `ps`
      wait_time: time in seconds to wait

    Raises:
      WaitForResponseTimedOutError if wait_time elapses and the process is
          still running
    """
    logger.Log("Waiting for process %s to end" % name)
    self._WaitForShellCommandContents("ps", name, wait_time, invert=True)

  def _WaitForShellCommandContents(self, command, expected, wait_time,
                                   raise_abort=True, invert=False):
    """Wait until the response to a command contains a given output.

    Assumes that a only successful execution of "adb shell <command>" contains
    the substring expected. Assumes that a device is present.

    Args:
      command: adb shell command to execute
      expected: the string that should appear to consider the
          command successful.
      wait_time: time in seconds to wait
      raise_abort: if False, retry when executing the command raises an
          AbortError, rather than failing.
      invert: if True, wait until the command output no longer contains the
          expected contents.

    Raises:
      WaitForResponseTimedOutError: If wait_time elapses and the command has not
          returned an output containing expected yet.
    """
    # Query the device with the command
    success = False
    attempts = 0
    wait_period = 5
    while not success and (attempts*wait_period) < wait_time:
      # assume the command will always contain expected in the success case
      try:
        output = self.SendShellCommand(command, retry_count=1,
                                       timeout_time=wait_time)
        if ((not invert and expected in output)
            or (invert and expected not in output)):
          success = True
      except errors.AbortError, e:
        if raise_abort:
          raise
        # ignore otherwise

      if not success:
        time.sleep(wait_period)
        attempts += 1

    if not success:
      raise errors.WaitForResponseTimedOutError()

  def WaitForBootComplete(self, wait_time=120):
    """Waits for targeted device's bootcomplete flag to be set.

    Args:
      wait_time: time in seconds to wait

    Raises:
      WaitForResponseTimedOutError if wait_time elapses and pm still does not
      respond.
    """
    logger.Log("Waiting for boot complete...")
    self.SendCommand("wait-for-device")
    # Now the device is there, but may not be running.
    # Query the package manager with a basic command
    boot_complete = False
    attempts = 0
    wait_period = 5
    while not boot_complete and (attempts*wait_period) < wait_time:
      output = self.SendShellCommand("getprop dev.bootcomplete", retry_count=1)
      output = output.strip()
      if output == "1":
        boot_complete = True
      else:
        time.sleep(wait_period)
        attempts += 1
    if not boot_complete:
      raise errors.WaitForResponseTimedOutError(
          "dev.bootcomplete flag was not set after %s seconds" % wait_time)

  def Sync(self, retry_count=3, runtime_restart=False):
    """Perform a adb sync.

    Blocks until device package manager is responding.

    Args:
      retry_count: number of times to retry sync before failing
      runtime_restart: stop runtime during sync and restart afterwards, useful
        for syncing system libraries (core, framework etc)

    Raises:
      WaitForResponseTimedOutError if package manager does not respond
      AbortError if unrecoverable error occurred
    """
    output = ""
    error = None
    if runtime_restart:
      self.SendShellCommand("setprop ro.monkey 1", retry_count=retry_count)
      # manual rest bootcomplete flag
      self.SendShellCommand("setprop dev.bootcomplete 0",
                            retry_count=retry_count)
      self.SendShellCommand("stop", retry_count=retry_count)

    try:
      output = self.SendCommand("sync", retry_count=retry_count)
    except errors.AbortError, e:
      error = e
      output = e.msg
    if "Read-only file system" in output:
      logger.SilentLog(output)
      logger.Log("Remounting read-only filesystem")
      self.SendCommand("remount")
      output = self.SendCommand("sync", retry_count=retry_count)
    elif "No space left on device" in output:
      logger.SilentLog(output)
      logger.Log("Restarting device runtime")
      self.SendShellCommand("stop", retry_count=retry_count)
      output = self.SendCommand("sync", retry_count=retry_count)
      self.SendShellCommand("start", retry_count=retry_count)
    elif error is not None:
      # exception occurred that cannot be recovered from
      raise error
    logger.SilentLog(output)
    if runtime_restart:
      # start runtime and wait till boot complete flag is set
      self.SendShellCommand("start", retry_count=retry_count)
      self.WaitForBootComplete()
      # press the MENU key, this will disable key guard if runtime is started
      # with ro.monkey set to 1
      self.SendShellCommand("input keyevent 82", retry_count=retry_count)
    else:
      self.WaitForDevicePm()
    return output

  def GetSerialNumber(self):
    """Returns the serial number of the targeted device."""
    return self.SendCommand("get-serialno").strip()
