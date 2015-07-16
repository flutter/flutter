// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_STRONG_BINDING_H_
#define MOJO_PUBLIC_CPP_BINDINGS_STRONG_BINDING_H_

#include <assert.h>

#include "mojo/public/c/environment/async_waiter.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/bindings/interface_ptr.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/bindings/lib/filter_chain.h"
#include "mojo/public/cpp/bindings/lib/message_header_validator.h"
#include "mojo/public/cpp/bindings/lib/router.h"
#include "mojo/public/cpp/system/core.h"

namespace mojo {

// This connects an interface implementation strongly to a pipe. When a
// connection error is detected the implementation is deleted. Deleting the
// connector also closes the pipe.
//
// Example of an implementation that is always bound strongly to a pipe
//
//   class StronglyBound : public Foo {
//    public:
//     explicit StronglyBound(InterfaceRequest<Foo> request)
//         : binding_(this, request.Pass()) {}
//
//     // Foo implementation here
//
//    private:
//     StrongBinding<Foo> binding_;
//   };
//
//   class MyFooFactory : public InterfaceFactory<Foo> {
//    public:
//     void Create(..., InterfaceRequest<Foo> request) override {
//       new StronglyBound(request.Pass());  // The binding now owns the
//                                           // instance of StronglyBound.
//     }
//   };
template <typename Interface>
class StrongBinding {
  MOJO_MOVE_ONLY_TYPE(StrongBinding)

 public:
  explicit StrongBinding(Interface* impl) : binding_(impl) {
    binding_.set_connection_error_handler([this]() { OnConnectionError(); });
  }

  StrongBinding(
      Interface* impl,
      ScopedMessagePipeHandle handle,
      const MojoAsyncWaiter* waiter = Environment::GetDefaultAsyncWaiter())
      : StrongBinding(impl) {
    binding_.Bind(handle.Pass(), waiter);
  }

  StrongBinding(
      Interface* impl,
      InterfacePtr<Interface>* ptr,
      const MojoAsyncWaiter* waiter = Environment::GetDefaultAsyncWaiter())
      : StrongBinding(impl) {
    binding_.Bind(ptr, waiter);
  }

  StrongBinding(
      Interface* impl,
      InterfaceRequest<Interface> request,
      const MojoAsyncWaiter* waiter = Environment::GetDefaultAsyncWaiter())
      : StrongBinding(impl) {
    binding_.Bind(request.Pass(), waiter);
  }

  ~StrongBinding() {}

  void Bind(
      ScopedMessagePipeHandle handle,
      const MojoAsyncWaiter* waiter = Environment::GetDefaultAsyncWaiter()) {
    assert(!binding_.is_bound());
    binding_.Bind(handle.Pass(), waiter);
  }

  void Bind(
      InterfacePtr<Interface>* ptr,
      const MojoAsyncWaiter* waiter = Environment::GetDefaultAsyncWaiter()) {
    assert(!binding_.is_bound());
    binding_.Bind(ptr, waiter);
  }

  void Bind(
      InterfaceRequest<Interface> request,
      const MojoAsyncWaiter* waiter = Environment::GetDefaultAsyncWaiter()) {
    assert(!binding_.is_bound());
    binding_.Bind(request.Pass(), waiter);
  }

  bool WaitForIncomingMethodCall() {
    return binding_.WaitForIncomingMethodCall();
  }

  // Note: The error handler must not delete the interface implementation.
  void set_connection_error_handler(const Closure& error_handler) {
    connection_error_handler_ = error_handler;
  }

  Interface* impl() { return binding_.impl(); }
  // Exposed for testing, should not generally be used.
  internal::Router* internal_router() { return binding_.internal_router(); }

  void OnConnectionError() {
    connection_error_handler_.Run();
    delete binding_.impl();
  }

 private:
  Closure connection_error_handler_;
  Binding<Interface> binding_;
};

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_STRONG_BINDING_H_
