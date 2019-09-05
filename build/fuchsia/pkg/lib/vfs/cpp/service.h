// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_VFS_CPP_SERVICE_H_
#define LIB_VFS_CPP_SERVICE_H_

#include <fuchsia/io/cpp/fidl.h>
#include <lib/vfs/cpp/node.h>

namespace vfs {

// A |Node| which binds a channel to a service implementation when opened.
//
// Instances of this class are thread-safe.
class Service : public Node {
 public:
  // Handler called to bind the provided channel to an implementation
  // of the service.
  using Connector =
      fit::function<void(zx::channel channel, async_dispatcher_t* dispatcher)>;

  // Adds the specified interface to the set of public interfaces.
  //
  // Creates |Service| with a |connector| with the given |service_name|, using
  // the given |interface_request_handler|. |interface_request_handler| should
  // remain valid for the lifetime of this object.
  //
  // A typical usage may be:
  //
  //   vfs::Service foo_service(foobar_bindings_.GetHandler(this, dispatcher));
  //
  // For now this implementation ignores |dispatcher| that we get from |Serve|
  // call, if you want to use dispatcher call |Service(Connector)|.
  template <typename Interface>
  explicit Service(fidl::InterfaceRequestHandler<Interface> handler)
      : Service([handler = std::move(handler)](zx::channel channel,
                                               async_dispatcher_t* dispatcher) {
          handler(fidl::InterfaceRequest<Interface>(std::move(channel)));
        }) {}

  // Creates a service with the specified connector.
  //
  // If the |connector| is null, then incoming connection requests will be
  // dropped.
  explicit Service(Connector connector);

  // Destroys the services and releases its connector.
  ~Service() override;

  // |Node| implementation:
  zx_status_t GetAttr(fuchsia::io::NodeAttributes* out_attributes) const final;

  void Describe(fuchsia::io::NodeInfo* out_info) override final;

  const Connector& connector() const { return connector_; }

 protected:
  // |Node| implementations:
  zx_status_t CreateConnection(uint32_t flags,
                               std::unique_ptr<Connection>* connection) final;

  uint32_t GetAdditionalAllowedFlags() const override final;

  bool IsDirectory() const override final;

  zx_status_t Connect(uint32_t flags, zx::channel request,
                      async_dispatcher_t* dispatcher) override;

 private:
  Connector connector_;
};

}  // namespace vfs

#endif  // LIB_VFS_CPP_SERVICE_H_
