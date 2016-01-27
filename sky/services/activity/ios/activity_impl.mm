// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include "sky/services/activity/ios/activity_impl.h"
#include "sky/services/activity/ios/user_feedback_impl.h"

#include <UIKit/UIKit.h>

namespace sky {
namespace services {
namespace activity {

ActivityImpl::ActivityImpl(mojo::InterfaceRequest<::activity::Activity> request)
    : binding_(this, request.Pass()) {}

ActivityImpl::~ActivityImpl() {}

void ActivityImpl::GetUserFeedback(
    mojo::InterfaceRequest<::activity::UserFeedback> request) {
  new UserFeedbackImpl(request.Pass());
}

void ActivityImpl::StartActivity(::activity::IntentPtr intent) {
  CHECK(false) << "Cannot start activities on iOS";
}

void ActivityImpl::FinishCurrentActivity() {
  CHECK(false) << "Cannot finish activities on iOS";
}

void ActivityImpl::SetTaskDescription(
    ::activity::TaskDescriptionPtr description) {
  // No counterpart on iOS but is a benign operation. So no asserts.
}

void ActivityImpl::SetSystemUIVisibility(
    ::activity::SystemUiVisibility visibility) {
  using Visibility = ::activity::SystemUiVisibility;

  bool visible = true;
  switch (visibility) {
    case Visibility::STANDARD:
      visible = true;
      break;
    case Visibility::IMMERSIVE:
    // There is no difference between fullscreen and immersive on iOS
    case Visibility::FULLSCREEN:
      visible = false;
      break;
  }

  base::mac::ScopedNSAutoreleasePool pool;

  // We opt out of view controller based status bar visibility since we want
  // to be able to modify this on the fly. The key used is
  // UIViewControllerBasedStatusBarAppearance
  [UIApplication sharedApplication].statusBarHidden = !visible;
}

void ActivityImpl::SetRequestedOrientation(
    ::activity::ScreenOrientation orientation) {
  base::mac::ScopedNSAutoreleasePool pool;

  // TODO: This needs to be wired up to communicate with the root view
  //       controller in the embedder. The current implementation is a stopgap
  //       measure
  [[UIDevice currentDevice]
      setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait]
        forKey:@"orientation"];
}

void ActivityFactory::Create(
    mojo::ApplicationConnection* connection,
    mojo::InterfaceRequest<::activity::Activity> request) {
  new ActivityImpl(request.Pass());
}

}  // namespace activity
}  // namespace services
}  // namespace sky
