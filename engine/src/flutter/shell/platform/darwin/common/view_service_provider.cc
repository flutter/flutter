// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/common/view_service_provider.h"

#include <utility>

namespace shell {

ViewServiceProvider::ViewServiceProvider(
    AppMesssagesConnector connect_to_app_messages,
    mojo::InterfaceRequest<mojo::ServiceProvider> request)
    : binding_(this, request.Pass()),
      connect_to_app_messages_(connect_to_app_messages) {}

ViewServiceProvider::~ViewServiceProvider() {}

void ViewServiceProvider::ConnectToService(
    const mojo::String& service_name,
    mojo::ScopedMessagePipeHandle client_handle) {
  if (service_name == ::flutter::platform::ApplicationMessages::Name_) {
    connect_to_app_messages_(
        mojo::InterfaceRequest<::flutter::platform::ApplicationMessages>(
            std::move(client_handle)));
    return;
  }
}

}  // namespace shell
