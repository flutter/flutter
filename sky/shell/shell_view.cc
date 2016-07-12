// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/shell_view.h"

#include "base/bind.h"
#include "base/single_thread_task_runner.h"
#include "sky/services/rasterizer/rasterizer.mojom.h"
#include "sky/shell/platform_view.h"
#include "sky/shell/rasterizer.h"
#include "sky/shell/shell.h"
#include "sky/shell/ui/engine.h"

namespace sky {
namespace shell {

ShellView::ShellView(Shell& shell)
    : shell_(shell) {
  rasterizer_ = Rasterizer::Create();
  CreateEngine();
  CreatePlatformView();
}

ShellView::~ShellView() {
  view_ = nullptr;
  shell_.gpu_task_runner()->DeleteSoon(FROM_HERE, rasterizer_.release());
  shell_.ui_task_runner()->DeleteSoon(FROM_HERE, engine_.release());
}

void ShellView::CreateEngine() {
  Engine::Config config;
  config.gpu_task_runner = shell_.gpu_task_runner();
  rasterizer::RasterizerPtr rasterizer;
  mojo::InterfaceRequest<rasterizer::Rasterizer> request = mojo::GetProxy(
      &rasterizer);
  shell_.gpu_task_runner()->PostTask(
      FROM_HERE,
      base::Bind(&Rasterizer::ConnectToRasterizer,
                 rasterizer_->GetWeakRasterizerPtr(), base::Passed(&request)));
  engine_.reset(new Engine(config, rasterizer.Pass()));
}

void ShellView::CreatePlatformView() {
  PlatformView::Config config;
  config.ui_task_runner = shell_.ui_task_runner();
  config.ui_delegate = engine_->GetWeakPtr();
  config.rasterizer = rasterizer_.get();
  view_.reset(PlatformView::Create(config, PlatformView::SurfaceConfig{}));
}

}  // namespace shell
}  // namespace sky
