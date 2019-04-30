// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_SYS_CPP_TESTING_COMPONENT_CONTEXT_PROVIDER_H_
#define LIB_SYS_CPP_TESTING_COMPONENT_CONTEXT_PROVIDER_H_

#include <fuchsia/sys/cpp/fidl.h>
#include <lib/fdio/directory.h>
#include <lib/sys/cpp/component_context.h>
#include <lib/sys/cpp/testing/service_directory_provider.h>

namespace sys {
namespace testing {

// Provides fake |ComponentContext| for unit testing.
// Provides access to services that have been added to this object.
// The object of this class should be kept alive for fake |ComponentContext| to
// work.
class ComponentContextProvider {
 public:
  explicit ComponentContextProvider(async_dispatcher_t* dispatcher = nullptr);

  ~ComponentContextProvider();

  // Points to outgoing root directory of outgoing directory, test can get it
  // and try to connect to internal directories/objects/files/services to test
  // code which published them.
  fuchsia::io::DirectoryPtr& outgoing_directory_ptr() {
    return outgoing_directory_ptr_;
  }

  // Connect to public service which was published in "public" directory by
  // code under test.
  template <typename Interface>
  fidl::InterfacePtr<Interface> ConnectToPublicService(
      const std::string& name = Interface::Name_,
      async_dispatcher_t* dispatcher = nullptr) const {
    fidl::InterfacePtr<Interface> ptr;
    ConnectToPublicService(ptr.NewRequest(dispatcher), name);
    return ptr;
  }

  // Connect to public service which was published in "public" directory by
  // code under test.
  template <typename Interface>
  void ConnectToPublicService(
      fidl::InterfaceRequest<Interface> request,
      const std::string& name = Interface::Name_) const {
    fdio_service_connect_at(public_directory_ptr_.channel().get(), name.c_str(),
                            request.TakeChannel().release());
  }

  // This can be used to get fake service directory provider and inject services
  // which can be accessed by code under test.
  //
  // # Example
  //
  // ```
  // fidl::BindingSet<fuchsia::foo::Controller> bindings;
  // context()->service_directory_provider()->AddService(bindings.GetHandler(this));
  // auto services = context()->service_directory_provider();
  // ...
  // ...
  // ...
  // services->Connect(...);
  // ```
  const std::shared_ptr<ServiceDirectoryProvider>& service_directory_provider()
      const {
    return svc_provider_;
  };

  // Relinquishes the ownership of fake context. This object should be alive for
  // lifetime of returned context.
  std::unique_ptr<sys::ComponentContext> TakeContext() {
    return std::move(component_context_);
  }

  sys::ComponentContext* context() { return component_context_.get(); }

 private:
  fuchsia::io::DirectoryPtr outgoing_directory_ptr_;
  fuchsia::io::DirectoryPtr public_directory_ptr_;
  std::shared_ptr<ServiceDirectoryProvider> svc_provider_;
  std::unique_ptr<sys::ComponentContext> component_context_;
};

}  // namespace testing
}  // namespace sys

#endif  // LIB_SYS_CPP_TESTING_COMPONENT_CONTEXT_PROVIDER_H_
