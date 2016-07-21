// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform_view.h"

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/location.h"
#include "base/single_thread_task_runner.h"
#include "sky/shell/rasterizer.h"

namespace sky {
namespace shell {

PlatformView::Config::Config() {}

PlatformView::Config::~Config() {}

PlatformView::PlatformView(const PlatformView::Config& config,
                           SurfaceConfig surface_config)
    : config_(config), surface_config_(surface_config),
      size_(SkISize::Make(0, 0)) {}

PlatformView::~PlatformView() {}

void PlatformView::ConnectToEngine(mojo::InterfaceRequest<SkyEngine> request) {
  config_.ui_task_runner->PostTask(
      FROM_HERE, base::Bind(&UIDelegate::ConnectToEngine, config_.ui_delegate,
                            base::Passed(&request)));
}

void PlatformView::NotifyCreated() {
  PlatformView::NotifyCreated(base::Bind(&base::DoNothing));
}

void PlatformView::NotifyCreated(base::Closure rasterizer_continuation) {
  CHECK(config_.rasterizer != nullptr);

  auto delegate = config_.ui_delegate;
  auto rasterizer = config_.rasterizer->GetWeakRasterizerPtr();

  base::WaitableEvent latch(false, false);

  auto delegate_continuation =
      base::Bind(&Rasterizer::Setup,  // method
                 rasterizer,          // target
                 base::Unretained(this), rasterizer_continuation,
                 base::Unretained(&latch));

  config_.ui_task_runner->PostTask(
      FROM_HERE, base::Bind(&UIDelegate::OnOutputSurfaceCreated, delegate,
                            delegate_continuation));

  latch.Wait();
}

void PlatformView::NotifyDestroyed() {
  CHECK(config_.rasterizer != nullptr);

  auto delegate = config_.ui_delegate;
  auto rasterizer = config_.rasterizer->GetWeakRasterizerPtr();

  base::WaitableEvent latch(false, false);

  auto delegate_continuation =
      base::Bind(&Rasterizer::Teardown, rasterizer, base::Unretained(&latch));

  config_.ui_task_runner->PostTask(
      FROM_HERE, base::Bind(&UIDelegate::OnOutputSurfaceDestroyed, delegate,
                            delegate_continuation));

  latch.Wait();
}

SkISize PlatformView::GetSize() {
  return size_;
}

void PlatformView::Resize(const SkISize& size) {
  size_ = size;
}

}  // namespace shell
}  // namespace sky
