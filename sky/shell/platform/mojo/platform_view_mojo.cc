// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mojo/platform_view_mojo.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/single_thread_task_runner.h"
#include "sky/shell/gpu/mojo/rasterizer_mojo.h"

namespace sky {
namespace shell {

PlatformViewMojo::PlatformViewMojo() : weak_factory_(this) {}

PlatformViewMojo::~PlatformViewMojo() = default;

void PlatformViewMojo::InitRasterizer(mojo::ApplicationConnectorPtr connector,
                                      mojo::gfx::composition::ScenePtr scene) {
  auto rasterizer_mojo = reinterpret_cast<RasterizerMojo*>(config_.rasterizer);
  auto continuation =
      base::Bind(&RasterizerMojo::Init,              // method
                 base::Unretained(rasterizer_mojo),  // target
                 base::Passed(&connector), base::Passed(&scene));
  NotifyCreated(continuation);
}

base::WeakPtr<sky::shell::PlatformView> PlatformViewMojo::GetWeakViewPtr() {
  return weak_factory_.GetWeakPtr();
}

uint64_t PlatformViewMojo::DefaultFramebuffer() const {
  return 0;
}

bool PlatformViewMojo::ContextMakeCurrent() {
  return false;
}

bool PlatformViewMojo::ResourceContextMakeCurrent() {
  return false;
}

bool PlatformViewMojo::SwapBuffers() {
  return false;
}

}  // namespace shell
}  // namespace sky
