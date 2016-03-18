// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MAC_VIEW_SERVICE_PROVIDER_H_
#define SKY_SHELL_PLATFORM_MAC_VIEW_SERVICE_PROVIDER_H_

#include "base/bind.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "sky/engine/wtf/Assertions.h"

#if TARGET_OS_IPHONE
#include "sky/services/editing/ios/keyboard_impl.h"
#endif

namespace sky {
namespace shell {

class ViewServiceProvider : public mojo::ServiceProvider {
 public:
  ViewServiceProvider(mojo::InterfaceRequest<mojo::ServiceProvider> request);
  ~ViewServiceProvider() override;

  void ConnectToService(const mojo::String& service_name,
                        mojo::ScopedMessagePipeHandle client_handle) override;

 private:
  mojo::StrongBinding<mojo::ServiceProvider> binding_;
#if TARGET_OS_IPHONE
  sky::services::editing::KeyboardFactory keyboard_;
#endif

  DISALLOW_COPY_AND_ASSIGN(ViewServiceProvider);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MAC_VIEW_SERVICE_PROVIDER_H_
