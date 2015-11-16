// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mac/platform_view_mac.h"

#include "sky/shell/gpu/direct/surface_notifications_direct.h"

namespace sky {
namespace shell {

PlatformView* PlatformView::Create(const Config& config) {
  return new PlatformViewMac(config);
}

PlatformViewMac::PlatformViewMac(const Config& config) : PlatformView(config) {}

PlatformViewMac::~PlatformViewMac() {}

void PlatformViewMac::SurfaceCreated(gfx::AcceleratedWidget widget) {
  DCHECK(window_ == 0);
  window_ = widget;
  SurfaceNotificationsDirect::NotifyCreated(config_, window_);
}

void PlatformViewMac::SurfaceDestroyed() {
  DCHECK(window_);
  window_ = 0;
  SurfaceNotificationsDirect::NotifyDestroyed(config_);
}

}  // namespace shell
}  // namespace sky
