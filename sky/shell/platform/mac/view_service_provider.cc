// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "sky/shell/platform/mac/view_service_provider.h"

namespace sky {
namespace shell {

ViewServiceProvider::ViewServiceProvider(
    AppMesssagesConnector connect_to_app_messages,
    mojo::InterfaceRequest<mojo::ServiceProvider> request)
  : binding_(this, request.Pass()),
    connect_to_app_messages_(connect_to_app_messages) {
}

ViewServiceProvider::~ViewServiceProvider() {
}

void ViewServiceProvider::ConnectToService(
    const mojo::String& service_name,
    mojo::ScopedMessagePipeHandle client_handle) {
  if (service_name == ::flutter::platform::ApplicationMessages::Name_ &&
      !connect_to_app_messages_.is_null()) {
    connect_to_app_messages_.Run(
        mojo::InterfaceRequest<::flutter::platform::ApplicationMessages>(
            client_handle.Pass()));
    return;
  }
#if TARGET_OS_IPHONE
  if (service_name == ::editing::Keyboard::Name_) {
    keyboard_.Create(
        nullptr, mojo::InterfaceRequest<::editing::Keyboard>(client_handle.Pass()));
    return;
  }
#endif
}

}  // namespace shell
}  // namespace sky
