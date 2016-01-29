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

PlatformView* PlatformView::Create(const Config& config) {
  return new PlatformViewMojo(config);
}

PlatformViewMojo::PlatformViewMojo(const Config& config)
  : PlatformView(config) {
}

PlatformViewMojo::~PlatformViewMojo() {
}

void PlatformViewMojo::InitRasterizer(mojo::ApplicationConnectorPtr connector,
                                      mojo::gfx::composition::ScenePtr scene) {
  RasterizerMojo* rasterizer = static_cast<RasterizerMojo*>(config_.rasterizer);
  config_.ui_task_runner->PostTask(FROM_HERE, base::Bind(
      &UIDelegate::OnOutputSurfaceCreated,
      config_.ui_delegate,
      base::Bind(&RasterizerMojo::Init,
                 rasterizer->GetWeakPtr(),
                 base::Passed(&connector),
                 base::Passed(&scene))));
}

}  // namespace shell
}  // namespace sky
