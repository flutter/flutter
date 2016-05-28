// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/platform/ios/haptic_feedback_impl.h"
#include <AudioToolbox/AudioToolbox.h>

namespace flutter {
namespace platform {

HapticFeedbackImpl::HapticFeedbackImpl(
    mojo::InterfaceRequest<HapticFeedback> request)
    : binding_(this, request.Pass()) {}

HapticFeedbackImpl::~HapticFeedbackImpl() {}

void HapticFeedbackImpl::Vibrate(const VibrateCallback& callback) {
  AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}

}  // namespace platform
}  // namespace flutter
