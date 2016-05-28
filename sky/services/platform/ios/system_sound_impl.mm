// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/platform/ios/system_sound_impl.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include <UIKit/UIKit.h>

namespace flutter {
namespace platform {

SystemSoundImpl::SystemSoundImpl(mojo::InterfaceRequest<SystemSound> request)
    : binding_(this, request.Pass()) {}

SystemSoundImpl::~SystemSoundImpl() {}

void SystemSoundImpl::Play(SystemSoundType type, const PlayCallback& callback) {
  base::mac::ScopedNSAutoreleasePool pool;

  switch (type) {
    case SystemSoundType::Click:

      // All feedback types are specific to Android and are treated as equal on
      // iOS. The surface must (and does) adopt the UIInputViewAudioFeedback
      // protocol
      [[UIDevice currentDevice] playInputClick];
      callback.Run(true);
      return;

      // Add more system types here as they are introduced
  }

  callback.Run(false);
}

}  // namespace platform
}  // namespace flutter
