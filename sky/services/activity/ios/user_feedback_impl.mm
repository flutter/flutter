// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include "sky/services/activity/ios/user_feedback_impl.h"

#include <AudioToolbox/AudioToolbox.h>
#include <UIKit/UIKit.h>

namespace sky {
namespace services {
namespace activity {

UserFeedbackImpl::UserFeedbackImpl(
    mojo::InterfaceRequest<::activity::UserFeedback> request)
    : binding_(this, request.Pass()) {}

UserFeedbackImpl::~UserFeedbackImpl() {}

void UserFeedbackImpl::PerformHapticFeedback(
    ::activity::HapticFeedbackType type) {
  // All feedback types are specific to Android and are treated as equal on iOS
  AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}

void UserFeedbackImpl::PerformAuralFeedback(
    ::activity::AuralFeedbackType type) {
  base::mac::ScopedNSAutoreleasePool pool;
  // All feedback types are specific to Android and are treated as equal on iOS
  // The surface must (and does) adopt the UIInputViewAudioFeedback protocol
  [[UIDevice currentDevice] playInputClick];
}

}  // namespace activity
}  // namespace services
}  // namespace sky
