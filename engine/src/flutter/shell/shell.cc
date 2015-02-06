// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/shell.h"

#include "base/bind.h"
#include "base/single_thread_task_runner.h"
#include "base/threading/thread.h"
#include "sky/shell/gpu/rasterizer.h"
#include "sky/shell/sky_view.h"
#include "sky/shell/ui/engine.h"

namespace sky {
namespace shell {

Shell::Shell(scoped_refptr<base::SingleThreadTaskRunner> java_task_runner)
    : java_task_runner_(java_task_runner) {
}

Shell::~Shell() {
}

void Shell::Init() {
  gpu_thread_.reset(new base::Thread("gpu_thread"));
  gpu_thread_->Start();
  rasterizer_.reset(new Rasterizer());

  ui_thread_.reset(new base::Thread("ui_thread"));
  ui_thread_->Start();
  engine_.reset(new Engine());

  ui_thread_->message_loop()->PostTask(
      FROM_HERE, base::Bind(&Engine::Init, engine_->GetWeakPtr()));

  SkyView::Config config;
  config.gpu_task_runner = gpu_thread_->message_loop()->task_runner();
  config.gpu_delegate = rasterizer_->GetWeakPtr();
  config.ui_task_runner = ui_thread_->message_loop()->task_runner();
  config.ui_delegate = engine_->GetWeakPtr();

  view_.reset(new SkyView(config));
}

}  // namespace shell
}  // namespace sky
