// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_PLATFORM_IOS_SYSTEM_CHROME_IMPL_H_
#define SKY_SERVICES_PLATFORM_IOS_SYSTEM_CHROME_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "sky/services/platform/system_chrome.mojom.h"

namespace flutter {
namespace platform {

class SystemChromeImpl : public SystemChrome {
 public:
  explicit SystemChromeImpl(mojo::InterfaceRequest<SystemChrome> request);

  ~SystemChromeImpl() override;

  void SetPreferredOrientations(
      uint32_t device_orientation_mask,
      const SetPreferredOrientationsCallback& callback) override;

  void SetApplicationSwitcherDescription(
      ApplicationSwitcherDescriptionPtr description,
      const SetApplicationSwitcherDescriptionCallback& callback) override;

  void SetEnabledSystemUIOverlays(
      uint32_t overlays,
      const SetEnabledSystemUIOverlaysCallback& callback) override;

  void SetSystemUIOverlayStyle(
      SystemUIOverlayStyle style,
      const SetSystemUIOverlayStyleCallback& callback) override;

 private:
  mojo::StrongBinding<SystemChrome> binding_;

  DISALLOW_COPY_AND_ASSIGN(SystemChromeImpl);
};

extern const char* const kOrientationUpdateNotificationName;
extern const char* const kOrientationUpdateNotificationKey;
extern const char* const kOverlayStyleUpdateNotificationName;
extern const char* const kOverlayStyleUpdateNotificationKey;

}  // namespace platform
}  // namespace flutter

#endif  // SKY_SERVICES_PLATFORM_IOS_SYSTEM_CHROME_IMPL_H_
