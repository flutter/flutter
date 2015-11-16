// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform_view.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/single_thread_task_runner.h"

namespace sky {
namespace shell {

PlatformView::Config::Config() {
}

PlatformView::Config::~Config() {
}

PlatformView::PlatformView(const PlatformView::Config& config)
    : config_(config) {
}

PlatformView::~PlatformView() {
}

void PlatformView::ConnectToEngine(
    mojo::InterfaceRequest<SkyEngine> request) {
  config_.ui_task_runner->PostTask(
      FROM_HERE, base::Bind(&UIDelegate::ConnectToEngine,
                            config_.ui_delegate, base::Passed(&request)));
}

}  // namespace shell
}  // namespace sky
