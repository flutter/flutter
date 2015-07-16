// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/lazy_instance.h"
#include "base/location.h"
#include "base/single_thread_task_runner.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "sky/shell/service_provider.h"
#include "sky/shell/testing/test_runner.h"

namespace sky {
namespace shell {
namespace {

base::LazyInstance<scoped_ptr<mojo::ServiceProviderImpl>> g_service_provider =
    LAZY_INSTANCE_INITIALIZER;

static void CreateServiceProviderImpl(
    mojo::InterfaceRequest<mojo::ServiceProvider> request) {
  g_service_provider.Get().reset(new mojo::ServiceProviderImpl(request.Pass()));
  g_service_provider.Get()->AddService(&TestRunner::Shared());
}

}  // namespace

mojo::ServiceProviderPtr CreateServiceProvider(
    ServiceProviderContext* context) {
  DCHECK(context);
  mojo::MessagePipe pipe;
  auto request = mojo::MakeRequest<mojo::ServiceProvider>(pipe.handle1.Pass());
  context->platform_task_runner->PostTask(
      FROM_HERE, base::Bind(CreateServiceProviderImpl, base::Passed(&request)));
  return mojo::MakeProxy(
      mojo::InterfacePtrInfo<mojo::ServiceProvider>(pipe.handle0.Pass(), 0u));
}

}  // namespace shell
}  // namespace sky
