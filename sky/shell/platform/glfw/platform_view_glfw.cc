// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/platform/glfw/platform_view_glfw.h"

#include "flutter/sky/shell/gpu/direct/surface_notifications_direct.h"

namespace sky {
namespace shell {

PlatformViewGLFW::PlatformViewGLFW(const Config& config)
    : window_(gfx::kNullAcceleratedWidget) {}

PlatformViewGLFW::~PlatformViewGLFW() {}

void PlatformViewGLFW::SurfaceCreated(gfx::AcceleratedWidget widget) {
  DCHECK(window_ == gfx::kNullAcceleratedWidget);
  window_ = widget;
  SurfaceNotificationsDirect::NotifyCreated(config_, window_, nullptr);
}

void PlatformViewGLFW::SurfaceDestroyed() {
  DCHECK(window_ != gfx::kNullAcceleratedWidget);
  window_ = gfx::kNullAcceleratedWidget;
  SurfaceNotificationsDirect::NotifyDestroyed(config_);
}

}  // namespace shell
}  // namespace sky
