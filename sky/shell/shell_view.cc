// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/shell_view.h"

#include "base/bind.h"
#include "base/single_thread_task_runner.h"
#include "sky/shell/platform_view.h"
#include "sky/shell/rasterizer.h"
#include "sky/shell/shell.h"
#include "sky/shell/ui/engine.h"

namespace sky {
namespace shell {
namespace {

template<typename T>
void Drop(scoped_ptr<T> ptr) { }

}  // namespace

ShellView::ShellView(Shell& shell)
    : shell_(shell) {
  rasterizer_ = Rasterizer::Create();
  CreateEngine();
  CreatePlatformView();
}

ShellView::~ShellView() {
  view_ = nullptr;
  shell_.gpu_task_runner()->PostTask(FROM_HERE,
      base::Bind(&Drop<Rasterizer>, base::Passed(&rasterizer_)));
  shell_.ui_task_runner()->PostTask(FROM_HERE,
      base::Bind(&Drop<Engine>, base::Passed(&engine_)));
}

void ShellView::CreateEngine() {
  Engine::Config config;
  config.gpu_task_runner = shell_.gpu_task_runner();
  config.raster_callback = rasterizer_->GetRasterCallback();
  engine_.reset(new Engine(config));
}

void ShellView::CreatePlatformView() {
  PlatformView::Config config;
  config.ui_task_runner = shell_.ui_task_runner();
  config.ui_delegate = engine_->GetWeakPtr();
  config.rasterizer = rasterizer_.get();
  view_.reset(PlatformView::Create(config));
}

}  // namespace shell
}  // namespace sky
