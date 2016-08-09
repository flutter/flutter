// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include "flutter/services/activity/ios/activity_impl.h"

#include <UIKit/UIKit.h>

namespace sky {
namespace services {
namespace activity {

ActivityImpl::ActivityImpl(mojo::InterfaceRequest<::activity::Activity> request)
    : binding_(this, request.Pass()) {}

ActivityImpl::~ActivityImpl() {}

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

}  // namespace activity
}  // namespace services
}  // namespace sky
