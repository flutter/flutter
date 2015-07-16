// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/application/service_provider_impl.h"

#include "mojo/public/cpp/application/service_connector.h"
#include "mojo/public/cpp/environment/logging.h"

namespace mojo {

ServiceProviderImpl::ServiceProviderImpl()
    : binding_(this), fallback_service_provider_(nullptr) {
}

ServiceProviderImpl::ServiceProviderImpl(
    InterfaceRequest<ServiceProvider> request)
    : binding_(this, request.Pass()), fallback_service_provider_(nullptr) {
}

ServiceProviderImpl::~ServiceProviderImpl() {
}

void ServiceProviderImpl::Bind(InterfaceRequest<ServiceProvider> request) {
  binding_.Bind(request.Pass());
}

void ServiceProviderImpl::Close() {
  if (binding_.is_bound())
    binding_.Close();
}

void ServiceProviderImpl::ConnectToService(
    const String& service_name,
    ScopedMessagePipeHandle client_handle) {
  // TODO(beng): perhaps take app connection thru ctor so that we can pass
  // ApplicationConnection through?
  bool service_found = service_connector_registry_.ConnectToService(
      nullptr, service_name, &client_handle);
  if (!service_found && fallback_service_provider_) {
    fallback_service_provider_->ConnectToService(service_name,
                                                 client_handle.Pass());
  }
}

void ServiceProviderImpl::SetServiceConnectorForName(
    ServiceConnector* service_connector,
    const std::string& interface_name) {
  service_connector_registry_.SetServiceConnectorForName(service_connector,
                                                         interface_name);
}

}  // namespace mojo
