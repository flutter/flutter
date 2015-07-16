# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Python implementation of the Application interface."""

import application_mojom
import service_provider_mojom
import shell_mojom
from mojo_application.service_provider_impl import ServiceProviderImpl

import mojo_system

class ApplicationImpl(application_mojom.Application):
  def __init__(self, delegate, app_request_handle):
    self.shell = None
    self.url = None
    self.args = None
    self._delegate = delegate
    self._providers = []
    application_mojom.Application.manager.Bind(self, app_request_handle)

  def Initialize(self, shell, url, args):
    self.shell = shell
    self.url = url
    self.args = args
    self._delegate.Initialize(shell, self)

  def AcceptConnection(self, requestor_url, services, exposed_services,
                       resolved_url):
    service_provider = ServiceProviderImpl(services)
    if self._delegate.OnAcceptConnection(requestor_url, resolved_url,
                                         service_provider, exposed_services):
      # We keep a reference to ServiceProviderImpl to ensure neither it nor
      # |services| gets garbage collected.
      services.Bind(service_provider)
      self._providers.append(service_provider)

      def removeServiceProvider():
        self._providers.remove(service_provider)
      service_provider.manager.AddOnErrorCallback(removeServiceProvider)

  def ConnectToService(self, application_url, service_class):
    """
    Helper method to connect to a service. |application_url| is the URL of the
    application to be connected to, and |service_class| is the class of the
    service to be connected to. Returns a proxy to the service.
    """
    application_proxy, request = (
        service_provider_mojom.ServiceProvider.manager.NewRequest())
    self.shell.ConnectToApplication(application_url, request, None)

    service_proxy, request = service_class.manager.NewRequest()
    application_proxy.ConnectToService(service_class.manager.name,
                                       request.PassMessagePipe())

    return service_proxy
