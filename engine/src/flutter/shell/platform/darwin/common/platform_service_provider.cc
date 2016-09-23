// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/common/platform_service_provider.h"

#if TARGET_OS_IPHONE
#include "flutter/services/activity/ios/activity_impl.h"
#include "flutter/services/editing/ios/clipboard_impl.h"
#include "flutter/services/media/ios/media_player_impl.h"
#include "flutter/services/media/ios/media_service_impl.h"
#include "flutter/services/platform/ios/haptic_feedback_impl.h"
#include "flutter/services/platform/ios/path_provider_impl.h"
#include "flutter/services/platform/ios/system_chrome_impl.h"
#include "flutter/services/platform/ios/system_sound_impl.h"
#include "flutter/services/platform/ios/url_launcher_impl.h"
#include "flutter/services/vsync/ios/vsync_provider_ios_impl.h"
#else
#include "flutter/services/vsync/mac/vsync_provider_mac_impl.h"
#endif  // TARGET_OS_IPHONE

namespace shell {

PlatformServiceProvider::PlatformServiceProvider(
    mojo::InterfaceRequest<mojo::ServiceProvider> request,
    DynamicServiceProviderCallback callback)
    : dynamic_service_provider_(callback), binding_(this, request.Pass()) {}

PlatformServiceProvider::~PlatformServiceProvider() {}

void PlatformServiceProvider::ConnectToService(
    const mojo::String& service_name,
    mojo::ScopedMessagePipeHandle client_handle) {
#if TARGET_OS_IPHONE
  if (service_name == ::media::MediaPlayer::Name_) {
    new sky::services::media::MediaPlayerImpl(
        mojo::InterfaceRequest<::media::MediaPlayer>(client_handle.Pass()));
    return;
  }
  if (service_name == ::media::MediaService::Name_) {
    new sky::services::media::MediaServiceImpl(
        mojo::InterfaceRequest<::media::MediaService>(client_handle.Pass()));
    return;
  }
  if (service_name == ::activity::Activity::Name_) {
    new sky::services::activity::ActivityImpl(
        mojo::InterfaceRequest<::activity::Activity>(client_handle.Pass()));
    return;
  }
  if (service_name == ::editing::Clipboard::Name_) {
    new sky::services::editing::ClipboardImpl(
        mojo::InterfaceRequest<::editing::Clipboard>(client_handle.Pass()));
    return;
  }
  if (service_name == flutter::platform::HapticFeedback::Name_) {
    new flutter::platform::HapticFeedbackImpl(
        mojo::InterfaceRequest<flutter::platform::HapticFeedback>(
            client_handle.Pass()));
    return;
  }
  if (service_name == flutter::platform::PathProvider::Name_) {
    new flutter::platform::PathProviderImpl(
        mojo::InterfaceRequest<flutter::platform::PathProvider>(
            client_handle.Pass()));
    return;
  }
  if (service_name == flutter::platform::SystemChrome::Name_) {
    new flutter::platform::SystemChromeImpl(
        mojo::InterfaceRequest<flutter::platform::SystemChrome>(
            client_handle.Pass()));
    return;
  }
  if (service_name == flutter::platform::SystemSound::Name_) {
    new flutter::platform::SystemSoundImpl(
        mojo::InterfaceRequest<flutter::platform::SystemSound>(
            client_handle.Pass()));
    return;
  }
  if (service_name == flutter::platform::URLLauncher::Name_) {
    new flutter::platform::URLLauncherImpl(
        mojo::InterfaceRequest<flutter::platform::URLLauncher>(
            client_handle.Pass()));
    return;
  }
  if (service_name == ::vsync::VSyncProvider::Name_) {
    new sky::services::vsync::VsyncProviderIOSImpl(
        mojo::InterfaceRequest<::vsync::VSyncProvider>(client_handle.Pass()));
    return;
  }
#else   // TARGET_OS_IPHONE
  if (service_name == ::vsync::VSyncProvider::Name_) {
    new sky::services::vsync::VsyncProviderMacImpl(
        mojo::InterfaceRequest<::vsync::VSyncProvider>(client_handle.Pass()));
    return;
  }
#endif  // TARGET_OS_IPHONE

  dynamic_service_provider_.Run(service_name, client_handle.Pass());
}

}  // namespace shell
