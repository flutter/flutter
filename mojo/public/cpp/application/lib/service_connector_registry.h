// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_APPLICATION_LIB_SERVICE_CONNECTOR_REGISTRY_H_
#define MOJO_PUBLIC_CPP_APPLICATION_LIB_SERVICE_CONNECTOR_REGISTRY_H_

#include <map>
#include <string>

#include "mojo/public/cpp/system/message_pipe.h"

namespace mojo {

class ApplicationConnection;
class ServiceConnector;

namespace internal {

// ServiceConnectorRegistry maintains a default ServiceConnector as well as at
// most one ServiceConnector per interface name. When ConnectToService() is
// invoked the ServiceConnector registered by name is given the request.
class ServiceConnectorRegistry {
 public:
  ServiceConnectorRegistry();
  ~ServiceConnectorRegistry();

  // Returns true if non ServiceConnectors have been registered by name.
  bool empty() const { return name_to_service_connector_.empty(); }

  // Sets a ServiceConnector by name. This deletes the existing ServiceConnector
  // and takes ownership of |service_connector|.
  void SetServiceConnectorForName(ServiceConnector* service_connector,
                                  const std::string& interface_name);
  void RemoveServiceConnectorForName(const std::string& interface_name);

  // ConnectToService returns true if this registery has an entry for
  // |interface_name|. In that case, the |client_handle| is passed along
  // to the |ServiceConnector|. Otherwise, this function returns false and
  // |client_handle| is untouched.
  bool ConnectToService(ApplicationConnection* application_connection,
                        const std::string& interface_name,
                        ScopedMessagePipeHandle* client_handle);

 private:
  using NameToServiceConnectorMap = std::map<std::string, ServiceConnector*>;

  NameToServiceConnectorMap name_to_service_connector_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ServiceConnectorRegistry);
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_APPLICATION_LIB_SERVICE_CONNECTOR_REGISTRY_H_
