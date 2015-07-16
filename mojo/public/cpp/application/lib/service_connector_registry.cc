// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/application/lib/service_connector_registry.h"

#include "mojo/public/cpp/application/service_connector.h"

namespace mojo {
namespace internal {

ServiceConnectorRegistry::ServiceConnectorRegistry() {
}

ServiceConnectorRegistry::~ServiceConnectorRegistry() {
  for (NameToServiceConnectorMap::iterator i =
           name_to_service_connector_.begin();
       i != name_to_service_connector_.end(); ++i) {
    delete i->second;
  }
  name_to_service_connector_.clear();
}

void ServiceConnectorRegistry::SetServiceConnectorForName(
    ServiceConnector* service_connector,
    const std::string& interface_name) {
  RemoveServiceConnectorForName(interface_name);
  name_to_service_connector_[interface_name] = service_connector;
}

void ServiceConnectorRegistry::RemoveServiceConnectorForName(
    const std::string& interface_name) {
  NameToServiceConnectorMap::iterator it =
      name_to_service_connector_.find(interface_name);
  if (it == name_to_service_connector_.end())
    return;
  delete it->second;
  name_to_service_connector_.erase(it);
}

bool ServiceConnectorRegistry::ConnectToService(
    ApplicationConnection* application_connection,
    const std::string& interface_name,
    ScopedMessagePipeHandle* client_handle) {
  auto iter = name_to_service_connector_.find(interface_name);
  if (iter != name_to_service_connector_.end()) {
    iter->second->ConnectToService(application_connection, interface_name,
                                   client_handle->Pass());
    return true;
  }
  return false;
}

}  // namespace internal
}  // namespace mojo
