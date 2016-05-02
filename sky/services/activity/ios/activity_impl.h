// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_ACTIVITY_IOS_ACTIVITY_IMPL_H_
#define SKY_SERVICES_ACTIVITY_IOS_ACTIVITY_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "sky/services/activity/activity.mojom.h"

namespace sky {
namespace services {
namespace activity {

class ActivityImpl : public ::activity::Activity {
 public:
  explicit ActivityImpl(mojo::InterfaceRequest<::activity::Activity> request);
  ~ActivityImpl() override;

  // From activity::Activity:
  void StartActivity(::activity::IntentPtr intent) override;
  void FinishCurrentActivity() override;
  void SetTaskDescription(::activity::TaskDescriptionPtr description) override;

 private:
  mojo::StrongBinding<::activity::Activity> binding_;

  DISALLOW_COPY_AND_ASSIGN(ActivityImpl);
};

class ActivityFactory
    : public mojo::InterfaceFactory<::activity::Activity> {
 public:
  void Create(mojo::ApplicationConnection* connection,
              mojo::InterfaceRequest<::activity::Activity> request) override;
};

}  // namespace activity
}  // namespace services
}  // namespace sky

#endif  // SKY_SERVICES_ACTIVITY_IOS_ACTIVITY_IMPL_H_
