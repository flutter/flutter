// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/platform/ios/system_chrome_impl.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include <UIKit/UIKit.h>

namespace flutter {
namespace platform {

SystemChromeImpl::SystemChromeImpl(mojo::InterfaceRequest<SystemChrome> request)
    : binding_(this, request.Pass()) {}

SystemChromeImpl::~SystemChromeImpl() {}

void SystemChromeFactory::Create(mojo::ApplicationConnection* connection,
                                 mojo::InterfaceRequest<SystemChrome> request) {
  new SystemChromeImpl(request.Pass());
}

/// Desugars a typed enum value and checks if it is set in a mask
template <class T,
          class = typename std::enable_if<std::is_enum<T>::value>::type>
static constexpr bool IsSet(uint32_t mask, T orientation) {
  return (static_cast<int32_t>(orientation) & mask) != 0;
}

void SystemChromeImpl::SetPreferredOrientations(
    uint32_t interface,
    uint32_t device,
    const SetPreferredOrientationsCallback& callback) {
  UIInterfaceOrientationMask mask = 0;

  if (IsSet(interface, InterfaceOrientation::Portrait)) {
    if (IsSet(device, DeviceOrientation::PortraitUp)) {
      mask |= UIInterfaceOrientationMaskPortrait;
    }
    if (IsSet(device, DeviceOrientation::PortraitDown)) {
      mask |= UIInterfaceOrientationMaskPortraitUpsideDown;
    }
  }

  if (IsSet(interface, InterfaceOrientation::Landscape)) {
    if (IsSet(device, DeviceOrientation::LandscapeLeft)) {
      mask |= UIInterfaceOrientationMaskLandscapeLeft;
    }
    if (IsSet(device, DeviceOrientation::LandscapeRight)) {
      mask |= UIInterfaceOrientationMaskLandscapeRight;
    }
  }

  if (mask == 0) {
    // An impossible configuration was requested. Bail.
    callback.Run(false);
    return;
  }

  base::mac::ScopedNSAutoreleasePool pool;
  // This notification is respected by the iOS embedder
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@(kOrientationUpdateNotificationName)
                    object:nil
                  userInfo:@{
                    @(kOrientationUpdateNotificationKey) : @(mask)
                  }];
  callback.Run(true);
}

void SystemChromeImpl::SetEnabledSystemUIOverlays(
    uint32_t overlays,
    const SetEnabledSystemUIOverlaysCallback& callback) {
  // Checks if the top status bar should be visible. This platform ignores all
  // other overlays

  base::mac::ScopedNSAutoreleasePool pool;

  // We opt out of view controller based status bar visibility since we want
  // to be able to modify this on the fly. The key used is
  // UIViewControllerBasedStatusBarAppearance
  [UIApplication sharedApplication].statusBarHidden =
      !IsSet(overlays, SystemUIOverlay::Top);

  callback.Run(true);
}

const char* const kOrientationUpdateNotificationName =
    "SystemChromeOrientationNotificationName";
const char* const kOrientationUpdateNotificationKey =
    "SystemChromeOrientationNotificationName";

}  // namespace platform
}  // namespace flutter
