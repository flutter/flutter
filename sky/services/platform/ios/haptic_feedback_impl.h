// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_PLATFORM_IOS_HAPTIC_FEEDBACK_IMPL_H_
#define SKY_SERVICES_PLATFORM_IOS_HAPTIC_FEEDBACK_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "sky/services/platform/haptic_feedback.mojom.h"

namespace flutter {
namespace platform {

class HapticFeedbackImpl : public HapticFeedback {
 public:
  explicit HapticFeedbackImpl(mojo::InterfaceRequest<HapticFeedback> request);

  ~HapticFeedbackImpl() override;

  void Vibrate(const VibrateCallback& callback) override;

 private:
  mojo::StrongBinding<HapticFeedback> binding_;

  DISALLOW_COPY_AND_ASSIGN(HapticFeedbackImpl);
};

class HapticFeedbackFactory : public mojo::InterfaceFactory<HapticFeedback> {
 public:
  void Create(mojo::ApplicationConnection* connection,
              mojo::InterfaceRequest<HapticFeedback> request) override;
};

}  // namespace platform
}  // namespace flutter

#endif  // SKY_SERVICES_PLATFORM_IOS_HAPTIC_FEEDBACK_IMPL_H_
