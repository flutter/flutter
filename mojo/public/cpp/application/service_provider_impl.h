// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_APPLICATION_SERVICE_PROVIDER_IMPL_H_
#define MOJO_PUBLIC_APPLICATION_SERVICE_PROVIDER_IMPL_H_

#include <string>

#include "mojo/public/cpp/application/lib/interface_factory_connector.h"
#include "mojo/public/cpp/application/lib/service_connector_registry.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"

namespace mojo {

// Implements a registry that can be used to expose services to another app.
class ServiceProviderImpl : public ServiceProvider {
 public:
  ServiceProviderImpl();
  explicit ServiceProviderImpl(InterfaceRequest<ServiceProvider> request);
  ~ServiceProviderImpl() override;

  void Bind(InterfaceRequest<ServiceProvider> request);
  // Disconnect this service provider and put it in a state where it can be
  // rebound to a new request.
  void Close();

  template <typename Interface>
  void AddService(InterfaceFactory<Interface>* factory) {
    SetServiceConnectorForName(
        new internal::InterfaceFactoryConnector<Interface>(factory),
        Interface::Name_);
  }

  // ServiceProviderImpl uses the fallback_service_provider_ whenever someone
  // asks a service that doesn't exist in the service_connector_registry_.
  //
  // Note: ServiceProviderImpl does not take ownership of |fallback|. The caller
  //       must ensure that |fallback| outlives the ServiceProviderImpl.
  //
  void set_fallback_service_provider(ServiceProvider* fallback) {
    fallback_service_provider_ = fallback;
  }

 private:
  // Overridden from ServiceProvider:
  void ConnectToService(const String& service_name,
                        ScopedMessagePipeHandle client_handle) override;

  void SetServiceConnectorForName(ServiceConnector* service_connector,
                                  const std::string& interface_name);

  Binding<ServiceProvider> binding_;

  internal::ServiceConnectorRegistry service_connector_registry_;
  ServiceProvider* fallback_service_provider_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ServiceProviderImpl);
};

}  // namespace mojo

#endif  // MOJO_PUBLIC_APPLICATION_SERVICE_PROVIDER_IMPL_H_
