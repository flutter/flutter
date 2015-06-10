// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "platform_view_ios.h"

namespace sky {
namespace shell {

void PlatformViewIOS::SurfaceCreated(gfx::AcceleratedWidget widget) {
  DCHECK(window_ == 0);
  window_ = widget;
  SurfaceWasCreated();
}

void PlatformViewIOS::SurfaceDestroyed() {
  DCHECK(window_);
  window_ = 0;
  SurfaceWasDestroyed();
}

}  // namespace shell
}  // namespace sky
