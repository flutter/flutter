// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/macros.h"
#include "base/threading/sequenced_worker_pool.h"
#include "mojo/application/application_runner_chromium.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_connection.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/services/native_viewport/interfaces/native_viewport.mojom.h"
#include "services/keyboard/linux/keyboard_service_impl.h"

namespace keyboard {

class KeyboardServiceFactoryImpl : public keyboard::KeyboardServiceFactory {
public:
  explicit KeyboardServiceFactoryImpl(
      mojo::InterfaceRequest<KeyboardServiceFactory> request)
    : binding_(this, request.Pass()) {}

  // |InterfaceFactory<KeyboardService>| implementation:
  void CreateKeyboardService(
      mojo::InterfaceRequest<mojo::NativeViewportEventDispatcher> dispatcher,
      mojo::InterfaceRequest<KeyboardService> request) override {
    new LinuxKeyboardServiceImpl(request.Pass(), dispatcher.Pass());
  }

private:
  mojo::StrongBinding<keyboard::KeyboardServiceFactory> binding_;

  DISALLOW_COPY_AND_ASSIGN(KeyboardServiceFactoryImpl);
};

class KeyboardServiceApp
  : public mojo::ApplicationDelegate,
    public mojo::InterfaceFactory<KeyboardServiceFactory> {
 public:
  KeyboardServiceApp() {}
  ~KeyboardServiceApp() override {}

 private:

  // |ApplicationDelegate| override:
  bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    connection->AddService<KeyboardServiceFactory>(this);
    return true;
  }

  // |InterfaceFactory<KeyboardService>| implementation:
  void Create(
      mojo::ApplicationConnection* connection,
      mojo::InterfaceRequest<KeyboardServiceFactory> request) override {
    new KeyboardServiceFactoryImpl(request.Pass());
  }

 private:

  DISALLOW_COPY_AND_ASSIGN(KeyboardServiceApp);
};

}  // namespace keyboard

MojoResult MojoMain(MojoHandle application_request) {
  mojo::ApplicationRunnerChromium runner(
      new keyboard::KeyboardServiceApp());
  return runner.Run(application_request);
}
