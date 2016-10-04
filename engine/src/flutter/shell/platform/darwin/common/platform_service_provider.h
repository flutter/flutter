// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_MAC_PLATFORM_SERVICE_PROVIDER_H_
#define SHELL_PLATFORM_MAC_PLATFORM_SERVICE_PROVIDER_H_

#include "base/callback.h"
#include "lib/ftl/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"

namespace shell {

class PlatformServiceProvider : public mojo::ServiceProvider {
 public:
  PlatformServiceProvider(mojo::InterfaceRequest<mojo::ServiceProvider> request);

  ~PlatformServiceProvider() override;

  void ConnectToService(const mojo::String& service_name,
                        mojo::ScopedMessagePipeHandle client_handle) override;

 private:
  mojo::StrongBinding<mojo::ServiceProvider> binding_;

  FTL_DISALLOW_COPY_AND_ASSIGN(PlatformServiceProvider);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_MAC_PLATFORM_SERVICE_PROVIDER_H_
