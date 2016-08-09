# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Base class for running tests on a single device."""

# TODO(jbudorick) Deprecate and remove this class and all subclasses after
# any relevant parts have been ported to the new environment + test instance
# model.

import logging

from pylib import ports
from pylib.device import device_utils
from pylib.forwarder import Forwarder
from pylib.valgrind_tools import CreateTool
# TODO(frankf): Move this to pylib/utils
import lighttpd_server


# A file on device to store ports of net test server. The format of the file is
# test-spawner-server-port:test-server-port
NET_TEST_SERVER_PORT_INFO_FILE = 'net-test-server-ports'


class BaseTestRunner(object):
  """Base class for running tests on a single device."""

  def __init__(self, device, tool):
    """
      Args:
        device: An instance of DeviceUtils that the tests will run on.
        tool: Name of the Valgrind tool.
    """
    assert isinstance(device, device_utils.DeviceUtils)
    self.device = device
    self.device_serial = self.device.adb.GetDeviceSerial()
    self.tool = CreateTool(tool, self.device)
    self._http_server = None
    self._forwarder_device_port = 8000
    self.forwarder_base_url = ('http://localhost:%d' %
        self._forwarder_device_port)
    # We will allocate port for test server spawner when calling method
    # LaunchChromeTestServerSpawner and allocate port for test server when
    # starting it in TestServerThread.
    self.test_server_spawner_port = 0
    self.test_server_port = 0

  def _PushTestServerPortInfoToDevice(self):
    """Pushes the latest port information to device."""
    self.device.WriteFile(
        self.device.GetExternalStoragePath() + '/' +
            NET_TEST_SERVER_PORT_INFO_FILE,
        '%d:%d' % (self.test_server_spawner_port, self.test_server_port))

  def RunTest(self, test):
    """Runs a test. Needs to be overridden.

    Args:
      test: A test to run.

    Returns:
      Tuple containing:
        (base_test_result.TestRunResults, tests to rerun or None)
    """
    raise NotImplementedError

  def InstallTestPackage(self):
    """Installs the test package once before all tests are run."""
    pass

  def SetUp(self):
    """Run once before all tests are run."""
    self.InstallTestPackage()

  def TearDown(self):
    """Run once after all tests are run."""
    self.ShutdownHelperToolsForTestSuite()

  def LaunchTestHttpServer(self, document_root, port=None,
                           extra_config_contents=None):
    """Launches an HTTP server to serve HTTP tests.

    Args:
      document_root: Document root of the HTTP server.
      port: port on which we want to the http server bind.
      extra_config_contents: Extra config contents for the HTTP server.
    """
    self._http_server = lighttpd_server.LighttpdServer(
        document_root, port=port, extra_config_contents=extra_config_contents)
    if self._http_server.StartupHttpServer():
      logging.info('http server started: http://localhost:%s',
                   self._http_server.port)
    else:
      logging.critical('Failed to start http server')
    self._ForwardPortsForHttpServer()
    return (self._forwarder_device_port, self._http_server.port)

  def _ForwardPorts(self, port_pairs):
    """Forwards a port."""
    Forwarder.Map(port_pairs, self.device, self.tool)

  def _UnmapPorts(self, port_pairs):
    """Unmap previously forwarded ports."""
    for (device_port, _) in port_pairs:
      Forwarder.UnmapDevicePort(device_port, self.device)

  # Deprecated: Use ForwardPorts instead.
  def StartForwarder(self, port_pairs):
    """Starts TCP traffic forwarding for the given |port_pairs|.

    Args:
      host_port_pairs: A list of (device_port, local_port) tuples to forward.
    """
    self._ForwardPorts(port_pairs)

  def _ForwardPortsForHttpServer(self):
    """Starts a forwarder for the HTTP server.

    The forwarder forwards HTTP requests and responses between host and device.
    """
    self._ForwardPorts([(self._forwarder_device_port, self._http_server.port)])

  def _RestartHttpServerForwarderIfNecessary(self):
    """Restarts the forwarder if it's not open."""
    # Checks to see if the http server port is being used.  If not forwards the
    # request.
    # TODO(dtrainor): This is not always reliable because sometimes the port
    # will be left open even after the forwarder has been killed.
    if not ports.IsDevicePortUsed(self.device, self._forwarder_device_port):
      self._ForwardPortsForHttpServer()

  def ShutdownHelperToolsForTestSuite(self):
    """Shuts down the server and the forwarder."""
    if self._http_server:
      self._UnmapPorts([(self._forwarder_device_port, self._http_server.port)])
      self._http_server.ShutdownHttpServer()

