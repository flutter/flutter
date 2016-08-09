// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MAC_PLATFORM_SERVICE_PROVIDER_H_
#define SKY_SHELL_PLATFORM_MAC_PLATFORM_SERVICE_PROVIDER_H_

#include "lib/ftl/macros.h"
#include "base/callback.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"

namespace sky {
namespace shell {

class PlatformServiceProvider : public mojo::ServiceProvider {
 public:
  using DynamicServiceProviderCallback =
      base::Callback<void(const mojo::String& service_name,
                          mojo::ScopedMessagePipeHandle)>;

  PlatformServiceProvider(mojo::InterfaceRequest<mojo::ServiceProvider> request,
                          DynamicServiceProviderCallback callback);
  ~PlatformServiceProvider() override;

  void ConnectToService(const mojo::String& service_name,
                        mojo::ScopedMessagePipeHandle client_handle) override;

 private:
  DynamicServiceProviderCallback dynamic_service_provider_;
  mojo::StrongBinding<mojo::ServiceProvider> binding_;

  FTL_DISALLOW_COPY_AND_ASSIGN(PlatformServiceProvider);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MAC_PLATFORM_SERVICE_PROVIDER_H_
