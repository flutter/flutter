// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_APPLICATION_SERVICE_CONNECTOR_H_
#define MOJO_PUBLIC_APPLICATION_SERVICE_CONNECTOR_H_

#include <string>

#include "mojo/public/cpp/system/message_pipe.h"

namespace mojo {

class ApplicationConnection;

class ServiceConnector {
 public:
  virtual ~ServiceConnector() {}

  // Asks the ServiceConnector to connect to the specified service. If the
  // ServiceConnector connects to the service it should take ownership of
  // the handle in |handle|.
  virtual void ConnectToService(ApplicationConnection* application_connection,
                                const std::string& interface_name,
                                ScopedMessagePipeHandle handle) = 0;
};

}  // namespace mojo

#endif  // MOJO_PUBLIC_APPLICATION_SERVICE_CONNECTOR_H_
