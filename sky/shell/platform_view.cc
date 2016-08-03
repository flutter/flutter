// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform_view.h"

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/location.h"
#include "base/single_thread_task_runner.h"
#include "sky/shell/rasterizer.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace sky {
namespace shell {

PlatformView::Config::Config() : rasterizer(nullptr) {}

PlatformView::Config::~Config() = default;

PlatformView::PlatformView()
    : rasterizer_(Rasterizer::Create()), size_(SkISize::Make(0, 0)) {
  if (!ResourceContext.initialized()) {
    ResourceContext.Initialize(
        [](void* context) { delete reinterpret_cast<GrContext*>(context); });
  }

  Shell& shell = Shell::Shared();

  // Create the engine for this platform view.
  Engine::Config engine_config;
  engine_config.gpu_task_runner = shell.gpu_task_runner();

  rasterizer::RasterizerPtr rasterizer;
  mojo::InterfaceRequest<rasterizer::Rasterizer> request =
      mojo::GetProxy(&rasterizer);

  shell.gpu_task_runner()->PostTask(
      FROM_HERE,
      base::Bind(&Rasterizer::ConnectToRasterizer,
                 rasterizer_->GetWeakRasterizerPtr(), base::Passed(&request)));

  engine_.reset(new Engine(engine_config, rasterizer.Pass()));

  // Setup the platform config.
  config_.ui_task_runner = shell.ui_task_runner();
  config_.ui_delegate = engine_->GetWeakPtr();
  config_.rasterizer = rasterizer_.get();
}

PlatformView::~PlatformView() {
  Shell& shell = Shell::Shared();
  // Purge dead PlatformViews.
  shell.ui_task_runner()->PostTask(
      FROM_HERE,
      base::Bind(&Shell::PurgePlatformViews, base::Unretained(&shell)));
  shell.gpu_task_runner()->DeleteSoon(FROM_HERE, rasterizer_.release());
  shell.ui_task_runner()->DeleteSoon(FROM_HERE, engine_.release());
}

void PlatformView::ConnectToEngine(mojo::InterfaceRequest<SkyEngine> request) {
  config_.ui_task_runner->PostTask(
      FROM_HERE, base::Bind(&UIDelegate::ConnectToEngine, config_.ui_delegate,
                            base::Passed(&request)));
  Shell& shell = Shell::Shared();
  shell.ui_task_runner()->PostTask(
      FROM_HERE,
      base::Bind(&Shell::AddPlatformView,
                 base::Unretained(&shell),
                 GetWeakViewPtr()));
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

void PlatformView::SetupResourceContextOnIOThread() {
  base::WaitableEvent latch(false, false);

  Shell::Shared().io_task_runner()->PostTask(
      FROM_HERE,
      base::Bind(&PlatformView::SetupResourceContextOnIOThreadPerform,
                 GetWeakViewPtr(), base::Unretained(&latch)));
  latch.Wait();
}

base::ThreadLocalStorage::StaticSlot PlatformView::ResourceContext =
    TLS_INITIALIZER;

void PlatformView::SetupResourceContextOnIOThreadPerform(
    base::WaitableEvent* latch) {
  if (ResourceContext.Get() != nullptr) {
    // The resource context was already setup. This could happen if platforms
    // try to setup a context multiple times, or, if there are multiple platform
    // views. In any case, there is nothing else to do. So just signal the
    // latch.
    latch->Signal();
    return;
  }

  bool current = ResourceContextMakeCurrent();

  if (!current) {
    LOG(WARNING)
        << "WARNING: Could not setup an OpenGL context on the resource loader.";
  }

  ResourceContext.Set(GrContext::Create(
      GrBackend::kOpenGL_GrBackend,
      reinterpret_cast<GrBackendContext>(GrGLCreateNativeInterface())));

  latch->Signal();
}

}  // namespace shell
}  // namespace sky
