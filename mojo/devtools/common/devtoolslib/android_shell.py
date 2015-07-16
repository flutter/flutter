# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import atexit
import hashlib
import json
import logging
import os
import os.path
import random
import re
import subprocess
import sys
import tempfile
import threading
import time

from devtoolslib.http_server import StartHttpServer
from devtoolslib.shell import Shell


# Tags used by mojo shell Java logging.
_LOGCAT_JAVA_TAGS = [
    'AndroidHandler',
    'MojoFileHelper',
    'MojoMain',
    'MojoShellActivity',
    'MojoShellApplication',
]

# Tags used by native logging reflected in the logcat.
_LOGCAT_NATIVE_TAGS = [
    'chromium',
    'sky',
]

_MOJO_SHELL_PACKAGE_NAME = 'org.chromium.mojo.shell'


_logger = logging.getLogger()


def _ExitIfNeeded(process):
  """Exits |process| if it is still alive."""
  if process.poll() is None:
    process.kill()


def _FindAvailablePort(netstat_output, max_attempts=10000):
  opened = [int(x.strip().split()[3].split(':')[1])
            for x in netstat_output if x.startswith(' tcp')]
  for _ in xrange(max_attempts):
    port = random.randint(4096, 16384)
    if port not in opened:
      return port
  else:
    raise Exception('Failed to identify an available port.')


def _FindAvailableHostPort():
  netstat_output = subprocess.check_output(['netstat'])
  return _FindAvailablePort(netstat_output)


class AndroidShell(Shell):
  """Wrapper around Mojo shell running on an Android device.

  Args:
    adb_path: Path to adb, optional if adb is in PATH.
    target_device: Device to run on, if multiple devices are connected.
    logcat_tags: Comma-separated list of additional logcat tags to use.
  """

  def __init__(self, adb_path="adb", target_device=None, logcat_tags=None,
               verbose_pipe=None):
    self.adb_path = adb_path
    self.target_device = target_device
    self.stop_shell_registered = False
    self.adb_running_as_root = None
    self.additional_logcat_tags = logcat_tags
    self.verbose_pipe = verbose_pipe if verbose_pipe else open(os.devnull, 'w')

  def _AdbCommand(self, args):
    """Forms an adb command from the given arguments, prepending the adb path
    and adding a target device specifier, if needed.
    """
    adb_command = [self.adb_path]
    if self.target_device:
      adb_command.extend(['-s', self.target_device])
    adb_command.extend(args)
    return adb_command

  def _ReadFifo(self, fifo_path, pipe, on_fifo_closed, max_attempts=5):
    """Reads |fifo_path| on the device and write the contents to |pipe|.

    Calls |on_fifo_closed| when the fifo is closed. This method will try to find
    the path up to |max_attempts|, waiting 1 second between each attempt. If it
    cannot find |fifo_path|, a exception will be raised.
    """
    fifo_command = self._AdbCommand(
        ['shell', 'test -e "%s"; echo $?' % fifo_path])

    def Run():
      def _WaitForFifo():
        for _ in xrange(max_attempts):
          if subprocess.check_output(fifo_command)[0] == '0':
            return
          time.sleep(1)
        if on_fifo_closed:
          on_fifo_closed()
        raise Exception("Unable to find fifo.")
      _WaitForFifo()
      stdout_cat = subprocess.Popen(
          self._AdbCommand(['shell', 'cat', fifo_path]), stdout=pipe)
      atexit.register(_ExitIfNeeded, stdout_cat)
      stdout_cat.wait()
      if on_fifo_closed:
        on_fifo_closed()

    thread = threading.Thread(target=Run, name="StdoutRedirector")
    thread.start()

  def _FindAvailableDevicePort(self):
    netstat_output = subprocess.check_output(
        self._AdbCommand(['shell', 'netstat']))
    return _FindAvailablePort(netstat_output)

  def _ForwardDevicePortToHost(self, device_port, host_port):
    """Maps the device port to the host port. If |device_port| is 0, a random
    available port is chosen.

    Returns:
      The device port.
    """
    assert host_port
    # Root is not required for `adb forward` (hence we don't check the return
    # value), but if we can run adb as root, we have to do it now, because
    # restarting adbd as root clears any port mappings. See
    # https://github.com/domokit/devtools/issues/20.
    self._RunAdbAsRoot()

    if device_port == 0:
      # TODO(ppi): Should we have a retry loop to handle the unlikely races?
      device_port = self._FindAvailableDevicePort()
    subprocess.check_call(self._AdbCommand([
        "reverse", "tcp:%d" % device_port, "tcp:%d" % host_port]))

    def _UnmapPort():
      unmap_command = self._AdbCommand([
          "reverse", "--remove", "tcp:%d" % device_port])
      subprocess.Popen(unmap_command)
    atexit.register(_UnmapPort)
    return device_port

  def _ForwardHostPortToDevice(self, host_port, device_port):
    """Maps the host port to the device port. If |host_port| is 0, a random
    available port is chosen.

    Returns:
      The host port.
    """
    assert device_port
    self._RunAdbAsRoot()

    if host_port == 0:
      # TODO(ppi): Should we have a retry loop to handle the unlikely races?
      host_port = _FindAvailableHostPort()
    subprocess.check_call(self._AdbCommand([
        "forward", 'tcp:%d' % host_port, 'tcp:%d' % device_port]))

    def _UnmapPort():
      unmap_command = self._AdbCommand([
          "forward", "--remove", "tcp:%d" % device_port])
      subprocess.Popen(unmap_command)
    atexit.register(_UnmapPort)
    return host_port

  def _RunAdbAsRoot(self):
    if self.adb_running_as_root is not None:
      return self.adb_running_as_root

    if ('cannot run as root' not in subprocess.check_output(
        self._AdbCommand(['root']))):
      # Wait for adbd to restart.
      subprocess.check_call(
          self._AdbCommand(['wait-for-device']),
          stdout=self.verbose_pipe)
      self.adb_running_as_root = True
    else:
      self.adb_running_as_root = False

    return self.adb_running_as_root

  def _IsShellPackageInstalled(self):
    # Adb should print one line if the package is installed and return empty
    # string otherwise.
    return len(subprocess.check_output(self._AdbCommand([
        'shell', 'pm', 'list', 'packages', _MOJO_SHELL_PACKAGE_NAME]))) > 0

  def CheckDevice(self):
    """Verifies if the device configuration allows adb to run.

    If a target device was indicated in the constructor, it checks that the
    device is available. Otherwise, it checks that there is exactly one
    available device.

    Returns:
      A tuple of (result, msg). |result| is True iff if the device is correctly
      configured and False otherwise. |msg| is the reason for failure if
      |result| is False and None otherwise.
    """
    adb_devices_output = subprocess.check_output(
        self._AdbCommand(['devices']))
    # Skip the header line, strip empty lines at the end.
    device_list = [line.strip() for line in adb_devices_output.split('\n')[1:]
                   if line.strip()]

    if self.target_device:
      if any([line.startswith(self.target_device) and
              line.endswith('device') for line in device_list]):
        return True, None
      else:
        return False, 'Cannot connect to the selected device.'

    if len(device_list) > 1:
      return False, ('More than one device connected and target device not '
                     'specified.')

    if not len(device_list):
      return False, 'No devices connected.'

    if not device_list[0].endswith('device'):
      return False, 'Connected device is not available.'

    return True, None

  def InstallApk(self, shell_apk_path):
    """Installs the apk on the device.

    This method computes checksum of the APK and skips the installation if the
    fingerprint matches the one saved on the device upon the previous
    installation.

    Args:
      shell_apk_path: Path to the shell Android binary.
    """
    device_sha1_path = '/sdcard/%s/%s.sha1' % (_MOJO_SHELL_PACKAGE_NAME,
                                               'MojoShell')
    apk_sha1 = hashlib.sha1(open(shell_apk_path, 'rb').read()).hexdigest()
    device_apk_sha1 = subprocess.check_output(self._AdbCommand([
        'shell', 'cat', device_sha1_path]))
    do_install = (apk_sha1 != device_apk_sha1 or
                  not self._IsShellPackageInstalled())

    if do_install:
      subprocess.check_call(
          self._AdbCommand(['install', '-r', shell_apk_path, '-i',
                            _MOJO_SHELL_PACKAGE_NAME]),
          stdout=self.verbose_pipe)

      # Update the stamp on the device.
      with tempfile.NamedTemporaryFile() as fp:
        fp.write(apk_sha1)
        fp.flush()
        subprocess.check_call(self._AdbCommand(['push', fp.name,
                                                device_sha1_path]),
                              stdout=self.verbose_pipe)
    else:
      # To ensure predictable state after running InstallApk(), we need to stop
      # the shell here, as this is what "adb install" implicitly does.
      self.StopShell()

  def StartShell(self,
                 arguments,
                 stdout=None,
                 on_application_stop=None):
    """Starts the mojo shell, passing it the given arguments.

    Args:
      arguments: List of arguments for the shell. It must contain the
          "--origin=" arg.  shell_arguments.ConfigureLocalOrigin() can be used
          to set up a local directory on the host machine as origin.
      stdout: Valid argument for subprocess.Popen() or None.
    """
    if not self.stop_shell_registered:
      atexit.register(self.StopShell)
      self.stop_shell_registered = True

    STDOUT_PIPE = "/data/data/%s/stdout.fifo" % _MOJO_SHELL_PACKAGE_NAME

    cmd = self._AdbCommand(['shell', 'am', 'start',
                            '-S',
                            '-a', 'android.intent.action.VIEW',
                            '-n', '%s/.MojoShellActivity' %
                            _MOJO_SHELL_PACKAGE_NAME])

    parameters = []
    if stdout or on_application_stop:
      # We need to run as root to access the fifo file we use for stdout
      # redirection.
      if self._RunAdbAsRoot():
        # Remove any leftover fifo file after the previous run.
        subprocess.check_call(self._AdbCommand(
            ['shell', 'rm', '-f', STDOUT_PIPE]))

        parameters.append('--fifo-path=%s' % STDOUT_PIPE)
        self._ReadFifo(STDOUT_PIPE, stdout, on_application_stop)
      else:
        _logger.warning("Running without root access, full stdout of the "
                        "shell won't be available.")
    # The origin has to be specified whether it's local or external.
    assert any("--origin=" in arg for arg in arguments)
    parameters.extend(arguments)

    if parameters:
      encodedParameters = json.dumps(parameters)
      cmd += ['--es', 'encodedParameters', encodedParameters]

    subprocess.check_call(cmd, stdout=self.verbose_pipe)

  def StopShell(self):
    """Stops the mojo shell."""
    subprocess.check_call(self._AdbCommand(['shell',
                                            'am',
                                            'force-stop',
                                            _MOJO_SHELL_PACKAGE_NAME]))

  def CleanLogs(self):
    """Cleans the logs on the device."""
    subprocess.check_call(self._AdbCommand(['logcat', '-c']))

  def ShowLogs(self, include_native_logs=True):
    """Displays the log for the mojo shell.

    Returns:
      The process responsible for reading the logs.
    """
    tags = _LOGCAT_JAVA_TAGS
    if include_native_logs:
      tags.extend(_LOGCAT_NATIVE_TAGS)
    if self.additional_logcat_tags is not None:
      tags.extend(self.additional_logcat_tags.split(","))
    logcat = subprocess.Popen(
        self._AdbCommand(['logcat', '-s', ' '.join(tags)]),
        stdout=sys.stdout)
    atexit.register(_ExitIfNeeded, logcat)
    return logcat

  def ForwardObservatoryPorts(self):
    """Forwards the ports used by the dart observatories to the host machine.
    """
    logcat = subprocess.Popen(self._AdbCommand(['logcat']),
                              stdout=subprocess.PIPE)
    atexit.register(_ExitIfNeeded, logcat)

    def _ForwardObservatoriesAsNeeded():
      while True:
        line = logcat.stdout.readline()
        if not line:
          break
        match = re.search(r'Observatory listening on http://127.0.0.1:(\d+)',
                          line)
        if match:
          device_port = int(match.group(1))
          host_port = self._ForwardHostPortToDevice(0, device_port)
          print ("Dart observatory available at the host at http://127.0.0.1:%d"
                 % host_port)

    logcat_watch_thread = threading.Thread(target=_ForwardObservatoriesAsNeeded)
    logcat_watch_thread.start()

  def ServeLocalDirectory(self, local_dir_path, port=0,
                          additional_mappings=None):
    """Serves the content of the local (host) directory, making it available to
    the shell under the url returned by the function.

    The server will run on a separate thread until the program terminates. The
    call returns immediately.

    Args:
      local_dir_path: path to the directory to be served
      port: port at which the server will be available to the shell
      additional_mappings: List of tuples (prefix, local_base_path) mapping
          URLs that start with |prefix| to local directory at |local_base_path|.
          The prefixes should skip the leading slash.

    Returns:
      The url that the shell can use to access the content of |local_dir_path|.
    """
    assert local_dir_path
    server_address = StartHttpServer(local_dir_path, host_port=port,
                                     additional_mappings=additional_mappings)

    return 'http://127.0.0.1:%d/' % self._ForwardDevicePortToHost(
        port, server_address[1])

  def ForwardHostPortToShell(self, host_port):
    """Forwards a port on the host machine to the same port wherever the shell
    is running.

    This is a no-op if the shell is running locally.
    """
    self._ForwardHostPortToDevice(host_port, host_port)

  def Run(self, arguments):
    """Runs the shell with given arguments until shell exits, passing the stdout
    mingled with stderr produced by the shell onto the stdout.

    Returns:
      Exit code retured by the shell or None if the exit code cannot be
      retrieved.
    """
    self.CleanLogs()
    self.ForwardObservatoryPorts()

    # If we are running as root, don't carry over the native logs from logcat -
    # we will have these in the stdout.
    p = self.ShowLogs(include_native_logs=(not self._RunAdbAsRoot()))
    self.StartShell(arguments, sys.stdout, p.terminate)
    p.wait()
    return None

  def RunAndGetOutput(self, arguments):
    """Runs the shell with given arguments until shell exits.

    Args:
      arguments: list of arguments for the shell

    Returns:
      A tuple of (return_code, output). |return_code| is the exit code returned
      by the shell or None if the exit code cannot be retrieved. |output| is the
      stdout mingled with the stderr produced by the shell.
    """
    (r, w) = os.pipe()
    with os.fdopen(r, "r") as rf:
      with os.fdopen(w, "w") as wf:
        self.StartShell(arguments, wf, wf.close)
        output = rf.read()
        return None, output
