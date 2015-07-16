// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_APPLICATION_INTERFACE_FACTORY_IMPL_H_
#define MOJO_PUBLIC_CPP_APPLICATION_INTERFACE_FACTORY_IMPL_H_

#include "mojo/public/cpp/application/interface_factory.h"

namespace mojo {

// Use this class to allocate and bind instances of Impl to interface requests.
// The lifetime of the constructed Impl is bound to the pipe.
template <typename Impl,
          typename Interface = typename Impl::ImplementedInterface>
class InterfaceFactoryImpl : public InterfaceFactory<Interface> {
 public:
  virtual ~InterfaceFactoryImpl() {}

  virtual void Create(ApplicationConnection* connection,
                      InterfaceRequest<Interface> request) override {
    BindToRequest(new Impl(), &request);
  }
};

// Use this class to allocate and bind instances of Impl constructed with a
// context parameter to interface requests. The lifetime of the constructed
// Impl is bound to the pipe.
template <typename Impl,
          typename Context,
          typename Interface = typename Impl::ImplementedInterface>
class InterfaceFactoryImplWithContext : public InterfaceFactory<Interface> {
 public:
  explicit InterfaceFactoryImplWithContext(Context* context)
      : context_(context) {}
  virtual ~InterfaceFactoryImplWithContext() {}

  virtual void Create(ApplicationConnection* connection,
                      InterfaceRequest<Interface> request) override {
    BindToRequest(new Impl(context_), &request);
  }

 private:
  Context* context_;
};

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_APPLICATION_INTERFACE_FACTORY_IMPL_H_
