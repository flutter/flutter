// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_MAC_VIEW_SERVICE_PROVIDER_H_
#define SHELL_PLATFORM_MAC_VIEW_SERVICE_PROVIDER_H_

#include <functional>

#include "flutter/services/platform/app_messages.mojom.h"
#include "flutter/sky/engine/wtf/Assertions.h"
#include "lib/ftl/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"

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

#endif  // SHELL_PLATFORM_MAC_VIEW_SERVICE_PROVIDER_H_
