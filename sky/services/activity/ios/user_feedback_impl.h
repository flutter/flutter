// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_ACTIVITY_IOS_USER_FEEDBACK_IMPL_H_
#define SKY_SERVICES_ACTIVITY_IOS_USER_FEEDBACK_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "sky/services/activity/activity.mojom.h"

namespace sky {
namespace services {
namespace activity {

class UserFeedbackImpl : public ::activity::UserFeedback {
 public:
  explicit UserFeedbackImpl(
      mojo::InterfaceRequest<::activity::UserFeedback> request);

  ~UserFeedbackImpl() override;

  void PerformHapticFeedback(::activity::HapticFeedbackType type) override;

  void PerformAuralFeedback(::activity::AuralFeedbackType type) override;

 private:
  mojo::StrongBinding<::activity::UserFeedback> binding_;

  DISALLOW_COPY_AND_ASSIGN(UserFeedbackImpl);
};

}  // namespace activity
}  // namespace services
}  // namespace sky

#endif  // SKY_SERVICES_ACTIVITY_IOS_USER_FEEDBACK_IMPL_H_
