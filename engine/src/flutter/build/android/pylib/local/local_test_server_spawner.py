# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

from pylib import chrome_test_server_spawner
from pylib import forwarder
from pylib.base import test_server


class LocalTestServerSpawner(test_server.TestServer):

  def __init__(self, port, device, tool):
    super(LocalTestServerSpawner, self).__init__()
    self._device = device
    self._spawning_server = chrome_test_server_spawner.SpawningServer(
        port, device, tool)
    self._tool = tool

  @property
  def server_address(self):
    return self._spawning_server.server.server_address

  @property
  def port(self):
    return self.server_address[1]

  #override
  def SetUp(self):
    self._device.WriteFile(
        '%s/net-test-server-ports' % self._device.GetExternalStoragePath(),
        '%s:0' % str(self.port))
    forwarder.Forwarder.Map(
        [(self.port, self.port)], self._device, self._tool)
    self._spawning_server.Start()

  #override
  def Reset(self):
    self._spawning_server.CleanupState()

  #override
  def TearDown(self):
    self.Reset()
    self._spawning_server.Stop()
    forwarder.Forwarder.UnmapDevicePort(self.port, self._device)

