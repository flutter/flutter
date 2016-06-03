// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/gpu/direct/surface_notifications_direct.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/single_thread_task_runner.h"
#include "sky/shell/gpu/direct/rasterizer_direct.h"
#include "sky/shell/shell.h"

namespace sky {
namespace shell {

void SurfaceNotificationsDirect::NotifyCreated(
    const PlatformView::Config& config,
    gfx::AcceleratedWidget widget,
    base::WaitableEvent* did_draw) {
  RasterizerDirect* rasterizer = static_cast<RasterizerDirect*>(config.rasterizer);
  config.ui_task_runner->PostTask(
      FROM_HERE, base::Bind(&UIDelegate::OnOutputSurfaceCreated,
                            config.ui_delegate,
                            base::Bind(&RasterizerDirect::OnAcceleratedWidgetAvailable,
                                       rasterizer->GetWeakPtr(), widget, did_draw)));
}

void SurfaceNotificationsDirect::NotifyDestroyed(
    const PlatformView::Config& config) {
  RasterizerDirect* rasterizer = static_cast<RasterizerDirect*>(config.rasterizer);
  config.ui_task_runner->PostTask(
      FROM_HERE, base::Bind(&UIDelegate::OnOutputSurfaceDestroyed,
                            config.ui_delegate,
                            base::Bind(&RasterizerDirect::OnOutputSurfaceDestroyed,
                                       rasterizer->GetWeakPtr())));
}

}  // namespace shell
}  // namespace sky
