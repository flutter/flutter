// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_SYS_CPP_SERVICE_DIRECTORY_H_
#define LIB_SYS_CPP_SERVICE_DIRECTORY_H_

#include <fuchsia/io/cpp/fidl.h>
#include <lib/fidl/cpp/interface_ptr.h>
#include <lib/fidl/cpp/interface_request.h>
#include <lib/zx/channel.h>

#include <memory>
#include <string>
#include <utility>

namespace sys {

// A directory of services provided by another component.
//
// These services are typically received by the component through its namespace,
// specifically through the "/svc" entry.
//
// Instances of this class are thread-safe.
class ServiceDirectory final {
 public:
  // Create an directory of services backed by given |directory|.
  //
  // Requests for services are routed to entries in this directory.
  //
  // The directory is expected to implement the |fuchsia.io.Directory| protocol.
  explicit ServiceDirectory(zx::channel directory);
  explicit ServiceDirectory(
      fidl::InterfaceHandle<fuchsia::io::Directory> directory);

  ~ServiceDirectory();

  // ServiceDirectory objects cannot be copied.
  ServiceDirectory(const ServiceDirectory&) = delete;
  ServiceDirectory& operator=(const ServiceDirectory&) = delete;

  // ServiceDirectory objects can be moved.
  ServiceDirectory(ServiceDirectory&& other)
      : directory_(std::move(other.directory_)) {}
  ServiceDirectory& operator=(ServiceDirectory&& other) {
    directory_ = std::move(other.directory_);
    return *this;
  }

  // Create an directory of services from this component's namespace.
  //
  // Uses the "/svc" entry in the namespace as the backing directory for the
  // returned directory of services.
  //
  // Rather than creating a new |ServiceDirectory| consider passing |svc()| from
  // your |ComponentContext| around as that makes your code unit testable and
  // consumes one less kernel handle.
  static std::shared_ptr<ServiceDirectory> CreateFromNamespace();

  // Create a directory of services and return a request for an implementation
  // of the underlying directory in |out_request|.
  //
  // Useful when creating components.
  static std::shared_ptr<ServiceDirectory> CreateWithRequest(
      zx::channel* out_request);
  static std::shared_ptr<ServiceDirectory> CreateWithRequest(
      fidl::InterfaceRequest<fuchsia::io::Directory>* out_request);

  // Connect to an interface in the directory.
  //
  // The discovery name of the interface is inferred from the C++ type of the
  // interface. Callers can supply an interface name explicitly to override
  // the default name.
  //
  // This overload for |Connect| discards the status of the underlying
  // connection operation. Callers that wish to recieve that status should use
  // one of the other overloads that returns a |zx_status_t|.
  //
  // # Example
  //
  // ```
  // auto controller = directory.Connect<fuchsia::foo::Controller>();
  // ```
  template <typename Interface>
  fidl::InterfacePtr<Interface> Connect(
      const std::string& interface_name = Interface::Name_) const {
    fidl::InterfacePtr<Interface> result;
    Connect(result.NewRequest(), interface_name);
    return std::move(result);
  }

  // Connect to an interface in the directory.
  //
  // The discovery name of the interface is inferred from the C++ type of the
  // interface request. Callers can supply an interface name explicitly to
  // override the default name.
  //
  // Returns whether the request was successfully sent to the remote directory
  // backing this service bundle.
  //
  // # Errors
  //
  // ZX_ERR_UNAVAILABLE: The directory backing this service bundle is invalid.
  //
  // ZX_ERR_ACCESS_DENIED: This service bundle has insufficient rights to
  // connect to services.
  //
  // # Example
  //
  // ```
  // fuchsia::foo::ControllerPtr controller;
  // directory.Connect(controller.NewRequest());
  // ```
  template <typename Interface>
  zx_status_t Connect(
      fidl::InterfaceRequest<Interface> request,
      const std::string& interface_name = Interface::Name_) const {
    return Connect(interface_name, request.TakeChannel());
  }

  // Connect to an interface in the directory.
  //
  // The interface name and the channel must be supplied explicitly.
  //
  // Returns whether the request was successfully sent to the remote directory
  // backing this service bundle.
  //
  // # Errors
  //
  // ZX_ERR_UNAVAILABLE: The directory backing this service bundle is invalid.
  //
  // ZX_ERR_ACCESS_DENIED: This service bundle has insufficient rights to
  // connect to services.
  //
  // # Example
  //
  // ```
  // zx::channel controller, request;
  // zx_status_t status = zx::channel::create(0, &controller, &request);
  // if (status != ZX_OK) {
  //   [...]
  // }
  // directory.Connect("fuchsia.foo.Controller", std::move(request));
  // ```
  zx_status_t Connect(const std::string& interface_name,
                      zx::channel request) const;

  // Clone underlying directory channel.
  //
  // This overload for |CloneHandle| discards the status of the underlying
  // operation. Callers that wish to recieve that status should use
  // other overload that returns a |zx_status_t|.
  fidl::InterfaceHandle<fuchsia::io::Directory> CloneChannel() const;

  // Clone underlying directory channel.
  //
  // Returns whether the request was successfully sent to the remote directory
  // backing this service bundle.
  //
  // # Errors
  //
  // ZX_ERR_UNAVAILABLE: The directory backing this service bundle is invalid.
  //
  // Other transport and application-level errors associated with
  // |fuchsia.io.Node/Clone|.
  //
  // # Example
  //
  // ```
  // fuchsia::io::DirectoryPtr dir;
  // directory.CloneHandle(dir.NewRequest());
  // ```
  zx_status_t CloneChannel(
      fidl::InterfaceRequest<fuchsia::io::Directory>) const;

 private:
  // The directory to which connection requests are routed.
  //
  // Implements |fuchsia.io.Directory| protocol.
  zx::channel directory_;
};

}  // namespace sys

#endif  // LIB_SYS_CPP_SERVICE_DIRECTORY_H_
