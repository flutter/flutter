// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/lazy_instance.h"
#include "base/location.h"
#include "base/single_thread_task_runner.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "sky/engine/wtf/Assertions.h"
#include "sky/services/ns_net/network_service_impl.h"
#include "sky/shell/service_provider.h"
#if !TARGET_OS_IPHONE
#include "sky/shell/testing/test_runner.h"
#endif

namespace sky {
namespace shell {

class PlatformServiceProvider : public mojo::ServiceProvider {
 public:
  PlatformServiceProvider(mojo::InterfaceRequest<mojo::ServiceProvider> request)
    : binding_(this, request.Pass())
  {
  }

  void ConnectToService(const mojo::String& service_name,
                        mojo::ScopedMessagePipeHandle client_handle) override {
    if (service_name == mojo::NetworkService::Name_) {
      network_.Create(nullptr,
        mojo::MakeRequest<mojo::NetworkService>(client_handle.Pass()));
    }
#if !TARGET_OS_IPHONE
    if (service_name == TestHarness::Name_) {
      TestRunner::Shared().Create(nullptr,
        mojo::MakeRequest<TestHarness>(client_handle.Pass()));
    }
#endif
  }

 private:
  mojo::StrongBinding<mojo::ServiceProvider> binding_;
  mojo::NetworkServiceFactory network_;
};

static void CreatePlatformServiceProvider(
    mojo::InterfaceRequest<mojo::ServiceProvider> request) {
  new PlatformServiceProvider(request.Pass());
}

mojo::ServiceProviderPtr CreateServiceProvider(
    ServiceProviderContext* context) {
  DCHECK(context);
  mojo::MessagePipe pipe;
  auto request = mojo::MakeRequest<mojo::ServiceProvider>(pipe.handle1.Pass());
  context->platform_task_runner->PostTask(
      FROM_HERE,
      base::Bind(CreatePlatformServiceProvider, base::Passed(request.Pass())));
  return mojo::MakeProxy(
      mojo::InterfacePtrInfo<mojo::ServiceProvider>(pipe.handle0.Pass(), 0u));
}

}  // namespace shell
}  // namespace sky
