// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MAC_PLATFORM_SERVICE_PROVIDER_H_
#define SKY_SHELL_PLATFORM_MAC_PLATFORM_SERVICE_PROVIDER_H_

#include "base/bind.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "sky/engine/wtf/Assertions.h"
#include "sky/services/ns_net/network_service_impl.h"

#if TARGET_OS_IPHONE
#include "sky/services/activity/ios/activity_impl.h"
#include "sky/services/editing/ios/clipboard_impl.h"
#include "sky/services/media/ios/media_player_impl.h"
#include "sky/services/media/ios/media_service_impl.h"
#include "sky/services/platform/ios/haptic_feedback_impl.h"
#include "sky/services/platform/ios/path_provider_impl.h"
#include "sky/services/platform/ios/system_chrome_impl.h"
#include "sky/services/platform/ios/system_sound_impl.h"
#include "sky/services/vsync/ios/vsync_provider_impl.h"
#endif

#if !TARGET_OS_IPHONE
#include "sky/shell/testing/test_runner.h"
#endif

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
  mojo::NetworkServiceFactory network_;
#if TARGET_OS_IPHONE
  flutter::platform::HapticFeedbackFactory haptic_feedback_;
  flutter::platform::PathProviderFactory path_provider_;
  flutter::platform::SystemChromeFactory system_chrome_;
  flutter::platform::SystemSoundFactory system_sound_;
  sky::services::activity::ActivityFactory activity_;
  sky::services::editing::ClipboardFactory clipboard_;
  sky::services::media::MediaPlayerFactory media_player_;
  sky::services::media::MediaServiceFactory media_service_;
  sky::services::vsync::VSyncProviderFactory vsync_;
#endif

  DISALLOW_COPY_AND_ASSIGN(PlatformServiceProvider);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MAC_PLATFORM_SERVICE_PROVIDER_H_
