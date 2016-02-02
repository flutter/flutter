// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "sky/shell/platform/mac/platform_service_provider.h"

namespace sky {
namespace shell {

PlatformServiceProvider::PlatformServiceProvider(
    mojo::InterfaceRequest<mojo::ServiceProvider> request)
    : binding_(this, request.Pass()) {}

PlatformServiceProvider::~PlatformServiceProvider() {}

void PlatformServiceProvider::ConnectToService(
    const mojo::String& service_name,
    mojo::ScopedMessagePipeHandle client_handle) {
  if (service_name == mojo::NetworkService::Name_) {
    network_.Create(
        nullptr, mojo::MakeRequest<mojo::NetworkService>(client_handle.Pass()));
    return;
  }
#if TARGET_OS_IPHONE
  if (service_name == ::editing::Keyboard::Name_) {
    keyboard_.Create(nullptr, mojo::MakeRequest<::editing::Keyboard>(
                                  client_handle.Pass()));
    return;
  }
  if (service_name == ::media::MediaPlayer::Name_) {
    media_player_.Create(
        nullptr, mojo::MakeRequest<::media::MediaPlayer>(client_handle.Pass()));
    return;
  }
  if (service_name == ::media::MediaService::Name_) {
    media_service_.Create(nullptr, mojo::MakeRequest<::media::MediaService>(
                                       client_handle.Pass()));
    return;
  }
  if (service_name == ::vsync::VSyncProvider::Name_) {
    vsync_.Create(nullptr, mojo::MakeRequest<::vsync::VSyncProvider>(
                               client_handle.Pass()));
    return;
  }
  if (service_name == ::activity::PathService::Name_) {
    path_.Create(nullptr, mojo::MakeRequest<::activity::PathService>(
                              client_handle.Pass()));
    return;
  }
  if (service_name == ::activity::Activity::Name_) {
    activity_.Create(
        nullptr, mojo::MakeRequest<::activity::Activity>(client_handle.Pass()));
    return;
  }
#endif

  LOG(INFO) << "The platform service provider cannot find a service for '"
            << service_name.data() << "'";
}

}  // namespace shell
}  // namespace sky
