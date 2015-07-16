# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Python implementation of the ServiceProvider interface."""

import logging

import service_provider_mojom

class ServiceProviderImpl(service_provider_mojom.ServiceProvider):
  def __init__(self, provider):
    self._provider = provider
    self._name_to_service_connector = {}

  def AddService(self, service_class):
    self._name_to_service_connector[service_class.manager.name] = service_class

  def ConnectToService(self, interface_name, pipe):
    if interface_name in self._name_to_service_connector:
      service = self._name_to_service_connector[interface_name]
      service.manager.Bind(service(), pipe)
    else:
      logging.error("Unable to find service " + interface_name)
