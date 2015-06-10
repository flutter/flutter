// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform_view.h"
#include "base/bind.h"
#include "base/location.h"
#include "sky/shell/shell.h"
#include "base/single_thread_task_runner.h"

namespace sky {
namespace shell {

PlatformView::PlatformView(const PlatformView::Config& config)
    : config_(config), window_(0) {
}

PlatformView::~PlatformView() {
}

void PlatformView::ConnectToViewportObserver(
    mojo::InterfaceRequest<ViewportObserver> request) {
  config_.ui_task_runner->PostTask(
      FROM_HERE, base::Bind(&UIDelegate::ConnectToViewportObserver,
                            config_.ui_delegate, base::Passed(&request)));
}

void PlatformView::SurfaceWasCreated() {
  config_.ui_task_runner->PostTask(
      FROM_HERE, base::Bind(&UIDelegate::OnAcceleratedWidgetAvailable,
                            config_.ui_delegate, window_));
}

void PlatformView::SurfaceWasDestroyed() {
  config_.ui_task_runner->PostTask(
      FROM_HERE,
      base::Bind(&UIDelegate::OnOutputSurfaceDestroyed, config_.ui_delegate));
}

}  // namespace shell
}  // namespace sky
