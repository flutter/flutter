// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_SYS_CPP_TESTING_SERVICE_DIRECTORY_PROVIDER_H_
#define LIB_SYS_CPP_TESTING_SERVICE_DIRECTORY_PROVIDER_H_

#include "lib/sys/cpp/service_directory.h"

#include <lib/vfs/cpp/pseudo_dir.h>
#include <lib/vfs/cpp/service.h>
#include <memory>

namespace sys {
namespace testing {

// This provides a fake |ServiceDirectory| for unit testing.
// Provides access to services that have been added to this object.
// The object of this class should be kept alive for fake |ServiceDirectory| to
// work.
class ServiceDirectoryProvider {
 public:
  explicit ServiceDirectoryProvider(async_dispatcher_t* dispatcher = nullptr);

  ~ServiceDirectoryProvider();

  // Injects a service which can be accessed by calling Connect on
  // |sys::ServiceDirectory| by code under test.
  //
  // Adds a supported service with the given |service_name|, using the given
  // |interface_request_handler|. |interface_request_handler| should
  // remain valid for the lifetime of this object.
  //
  // # Errors
  //
  // ZX_ERR_ALREADY_EXISTS: This already contains an entry for
  // this service.
  //
  // # Example
  //
  // ```
  // fidl::BindingSet<fuchsia::foo::Controller> bindings;
  // svc->AddService(bindings.GetHandler(this));
  // ```
  template <typename Interface>
  zx_status_t AddService(fidl::InterfaceRequestHandler<Interface> handler,
                         const std::string& name = Interface::Name_) const {
    return AddService(std::make_unique<vfs::Service>(std::move(handler)), name);
  }

  // Injects a service which can be accessed by calling Connect on
  // |sys::ServiceDirectory| by code under test.
  //
  // Adds a supported service with the given |service_name|, using the given
  // |service|. |service| closure should
  // remain valid for the lifetime of this object.
  //
  // # Errors
  //
  // ZX_ERR_ALREADY_EXISTS: This already contains an entry for
  // this service.
  zx_status_t AddService(std::unique_ptr<vfs::Service> service,
                         const std::string& name) const;

  std::shared_ptr<ServiceDirectory>& service_directory() {
    return service_directory_;
  }

 private:
  std::shared_ptr<ServiceDirectory> service_directory_;
  std::unique_ptr<vfs::PseudoDir> svc_dir_;
};

}  // namespace testing
}  // namespace sys

#endif  // LIB_SYS_CPP_TESTING_SERVICE_DIRECTORY_PROVIDER_H_
