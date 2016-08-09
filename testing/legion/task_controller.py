# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines the task controller library."""

import argparse
import datetime
import logging
import os
import socket
import subprocess
import sys
import tempfile
import threading

#pylint: disable=relative-import
import common_lib
import process
import ssl_util
import jsonrpclib

ISOLATE_PY = os.path.join(common_lib.SWARMING_DIR, 'isolate.py')
SWARMING_PY = os.path.join(common_lib.SWARMING_DIR, 'swarming.py')


class Error(Exception):
  pass


class ConnectionTimeoutError(Error):
  pass


class TaskController(object):
  """Provisions, configures, and controls a task machine.

  This class is an abstraction of a physical task machine. It provides an
  end to end API for controlling a task machine. Operations on the task machine
  are performed using the instance's "rpc" property. A simple end to end
  scenario is as follows:

  task = TaskController(...)
  task.Create()
  task.WaitForConnection()
  proc = task.rpc.subprocess.Popen(['ls'])
  print task.rpc.subprocess.GetStdout(proc)
  task.Release()
  """

  _task_count = 0
  _tasks = []

  def __init__(self, isolated_hash, dimensions, priority=100,
               idle_timeout_secs=common_lib.DEFAULT_TIMEOUT_SECS,
               connection_timeout_secs=common_lib.DEFAULT_TIMEOUT_SECS,
               verbosity='ERROR', name=None, run_id=None):
    assert isinstance(dimensions, dict)
    type(self)._tasks.append(self)
    type(self)._task_count += 1
    self.verbosity = verbosity
    self._name = name or 'Task%d' % type(self)._task_count
    self._priority = priority
    self._isolated_hash = isolated_hash
    self._idle_timeout_secs = idle_timeout_secs
    self._dimensions = dimensions
    self._connect_event = threading.Event()
    self._connected = False
    self._ip_address = None
    self._otp = self._CreateOTP()
    self._rpc = None
    self._output_dir = None

    run_id = run_id or datetime.datetime.now().strftime('%Y-%m-%d-%H-%M-%S')
    self._task_name = '%s/%s/%s' % (
        os.path.splitext(sys.argv[0])[0], self._name, run_id)

    parser = argparse.ArgumentParser()
    parser.add_argument('--isolate-server')
    parser.add_argument('--swarming-server')
    parser.add_argument('--task-connection-timeout-secs',
                        default=common_lib.DEFAULT_TIMEOUT_SECS)
    args, _ = parser.parse_known_args()

    self._isolate_server = args.isolate_server
    self._swarming_server = args.swarming_server
    self._connection_timeout_secs = (connection_timeout_secs or
                                    args.task_connection_timeout_secs)

  @property
  def name(self):
    return self._name

  @property
  def otp(self):
    return self._otp

  @property
  def connected(self):
    return self._connected

  @property
  def connect_event(self):
    return self._connect_event

  @property
  def rpc(self):
    return self._rpc

  @property
  def verbosity(self):
    return self._verbosity

  @verbosity.setter
  def verbosity(self, level):
    """Sets the verbosity level as a string.

    Either a string ('INFO', 'DEBUG', etc) or a logging level (logging.INFO,
    logging.DEBUG, etc) is allowed.
    """
    assert isinstance(level, (str, int))
    if isinstance(level, int):
      level = logging.getLevelName(level)
    self._verbosity = level  #pylint: disable=attribute-defined-outside-init

  @property
  def output_dir(self):
    if not self._output_dir:
      self._output_dir = self.rpc.GetOutputDir()
    return self._output_dir

  @classmethod
  def ReleaseAllTasks(cls):
    for task in cls._tasks:
      task.Release()

  def Process(self, cmd, *args, **kwargs):
    return process.ControllerProcessWrapper(self.rpc, cmd, *args, **kwargs)

  def _CreateOTP(self):
    """Creates the OTP."""
    controller_name = socket.gethostname()
    test_name = os.path.basename(sys.argv[0])
    creation_time = datetime.datetime.utcnow()
    otp = 'task:%s controller:%s test:%s creation:%s' % (
        self._name, controller_name, test_name, creation_time)
    return otp

  def Create(self):
    """Creates the task machine."""
    logging.info('Creating %s', self.name)
    self._connect_event.clear()
    self._ExecuteSwarming()

  def WaitForConnection(self):
    """Waits for the task machine to connect.

    Raises:
      ConnectionTimeoutError if the task doesn't connect in time.
    """
    logging.info('Waiting for %s to connect with a timeout of %d seconds',
                 self._name, self._connection_timeout_secs)
    self._connect_event.wait(self._connection_timeout_secs)
    if not self._connect_event.is_set():
      raise ConnectionTimeoutError('%s failed to connect' % self.name)

  def Release(self):
    """Quits the task's RPC server so it can release the machine."""
    if self._rpc is not None and self._connected:
      logging.info('Copying output-dir files to controller')
      self.RetrieveOutputFiles()
      logging.info('Releasing %s', self._name)
      try:
        self._rpc.Quit()
      except (socket.error, jsonrpclib.Fault):
        logging.error('Unable to connect to %s to call Quit', self.name)
      self._rpc = None
      self._connected = False

  def _ExecuteSwarming(self):
    """Executes swarming.py."""
    cmd = [
        'python',
        SWARMING_PY,
        'trigger',
        self._isolated_hash,
        '--priority', str(self._priority),
        '--task-name', self._task_name,
        ]

    if self._isolate_server:
      cmd.extend(['--isolate-server', self._isolate_server])
    if self._swarming_server:
      cmd.extend(['--swarming', self._swarming_server])
    for key, value in self._dimensions.iteritems():
      cmd.extend(['--dimension', key, value])

    cmd.extend([
        '--',
        '--controller', common_lib.MY_IP,
        '--otp', self._otp,
        '--verbosity', self._verbosity,
        '--idle-timeout', str(self._idle_timeout_secs),
        '--output-dir', '${ISOLATED_OUTDIR}'
        ])

    self._ExecuteProcess(cmd)

  def _ExecuteProcess(self, cmd):
    """Executes a process, waits for it to complete, and checks for success."""
    logging.debug('Running %s', ' '.join(cmd))
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    _, stderr = p.communicate()
    if p.returncode != 0:
      raise Error(stderr)

  def OnConnect(self, ip_address):
    """Receives task ip address on connection."""
    self._ip_address = ip_address
    self._connected = True
    self._rpc = ssl_util.SslRpcServer.Connect(self._ip_address)
    logging.info('%s connected from %s', self._name, ip_address)
    self._connect_event.set()

  def RetrieveOutputFiles(self):
    """Retrieves all files in the output-dir."""
    files = self.rpc.ListDir(self.output_dir)
    for fname in files:
      remote_path = self.rpc.PathJoin(self.output_dir, fname)
      local_name = os.path.join(common_lib.GetOutputDir(),
                                '%s.%s' % (self.name, fname))
      contents = self.rpc.ReadFile(remote_path)
      with open(local_name, 'wb+') as fh:
        fh.write(contents)
