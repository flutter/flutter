// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_DIRECT_SURFACE_NOTIFICATIONS_DIRECT_H_
#define SKY_SHELL_GPU_DIRECT_SURFACE_NOTIFICATIONS_DIRECT_H_

#include "base/synchronization/waitable_event.h"
#include "sky/shell/platform_view.h"

namespace sky {
namespace shell {

class SurfaceNotificationsDirect {
 public:
  static void NotifyCreated(const PlatformView::Config& config,
                            gfx::AcceleratedWidget widget,
                            base::WaitableEvent* did_draw);
  static void NotifyDestroyed(const PlatformView::Config& config);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_DIRECT_SURFACE_NOTIFICATIONS_DIRECT_H_
