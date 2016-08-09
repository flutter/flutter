// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MAC_VIEW_SERVICE_PROVIDER_H_
#define SKY_SHELL_PLATFORM_MAC_VIEW_SERVICE_PROVIDER_H_

#include <functional>

#include "lib/ftl/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "sky/engine/wtf/Assertions.h"
#include "sky/services/platform/app_messages.mojom.h"

#if TARGET_OS_IPHONE
#include "sky/services/editing/ios/keyboard_impl.h"
#endif

namespace sky {
namespace shell {

typedef std::function<void(
    mojo::InterfaceRequest<flutter::platform::ApplicationMessages>)>
    AppMesssagesConnector;

class ViewServiceProvider : public mojo::ServiceProvider {
 public:
  ViewServiceProvider(AppMesssagesConnector connect_to_app_messages,
                      mojo::InterfaceRequest<mojo::ServiceProvider> request);
  ~ViewServiceProvider() override;

  void ConnectToService(const mojo::String& service_name,
                        mojo::ScopedMessagePipeHandle client_handle) override;

 private:
  mojo::StrongBinding<mojo::ServiceProvider> binding_;
  AppMesssagesConnector connect_to_app_messages_;

  FTL_DISALLOW_COPY_AND_ASSIGN(ViewServiceProvider);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MAC_VIEW_SERVICE_PROVIDER_H_
