// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/platform_view.h"

#include <utility>

#include "flutter/lib/ui/painting/resource_context.h"
#include "flutter/glue/movable_wrapper.h"
#include "flutter/sky/shell/rasterizer.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace sky {
namespace shell {

PlatformView::Config::Config() : rasterizer(nullptr) {}

PlatformView::Config::~Config() = default;

PlatformView::PlatformView()
    : rasterizer_(Rasterizer::Create()), size_(SkISize::Make(0, 0)) {
  Shell& shell = Shell::Shared();

  // Create the engine for this platform view.
  Engine::Config engine_config;
  engine_config.gpu_task_runner =
      ftl::RefPtr<ftl::TaskRunner>(shell.gpu_ftl_task_runner());

  ftl::WeakPtr<Rasterizer> rasterizer_impl =
      rasterizer_->GetWeakRasterizerPtr();
  rasterizer::RasterizerPtr rasterizer;
  auto request = glue::WrapMovable(mojo::GetProxy(&rasterizer));

  shell.gpu_ftl_task_runner()->PostTask([rasterizer_impl, request]() mutable {
    if (rasterizer_impl)
      rasterizer_impl->ConnectToRasterizer(request.Unwrap());
  });

  engine_.reset(new Engine(engine_config, rasterizer.Pass()));

  // Setup the platform config.
  config_.ui_task_runner =
      ftl::RefPtr<ftl::TaskRunner>(shell.ui_ftl_task_runner());
  config_.ui_delegate = engine_->GetWeakPtr();
  config_.rasterizer = rasterizer_.get();
}

PlatformView::~PlatformView() {
  Shell& shell = Shell::Shared();

  shell.ui_ftl_task_runner()->PostTask(
      []() { Shell::Shared().PurgePlatformViews(); });

  Rasterizer* rasterizer = rasterizer_.release();
  shell.gpu_ftl_task_runner()->PostTask([rasterizer]() { delete rasterizer; });

  Engine* engine = engine_.release();
  shell.ui_ftl_task_runner()->PostTask([engine]() { delete engine; });
}

void PlatformView::ConnectToEngine(mojo::InterfaceRequest<SkyEngine> request) {
  ftl::WeakPtr<UIDelegate> ui_delegate = config_.ui_delegate;
  auto wrapped_request = glue::WrapMovable(std::move(request));
  config_.ui_task_runner->PostTask([ui_delegate, wrapped_request]() mutable {
    if (ui_delegate)
      ui_delegate->ConnectToEngine(wrapped_request.Unwrap());
  });
  ftl::WeakPtr<PlatformView> view = GetWeakViewPtr();
  config_.ui_task_runner->PostTask(
      [view]() { Shell::Shared().AddPlatformView(view); });
}

void PlatformView::NotifyCreated() {
  PlatformView::NotifyCreated([]() {});
}

void PlatformView::NotifyCreated(ftl::Closure rasterizer_continuation) {
  CHECK(config_.rasterizer != nullptr);

  auto rasterizer = config_.rasterizer->GetWeakRasterizerPtr();

  ftl::AutoResetWaitableEvent latch;
  auto delegate_continuation = [rasterizer, this, rasterizer_continuation,
                                &latch]() {
    if (rasterizer)
      rasterizer->Setup(this, rasterizer_continuation, &latch);
    // TODO(abarth): We should signal the latch if the rasterizer is gone.
  };

  auto delegate = config_.ui_delegate;
  config_.ui_task_runner->PostTask([delegate, delegate_continuation]() {
    if (delegate)
      delegate->OnOutputSurfaceCreated(delegate_continuation);
    // TODO(abarth): We should signal the latch if the delegate is gone.
  });

  latch.Wait();
}

void PlatformView::NotifyDestroyed() {
  FTL_CHECK(config_.rasterizer != nullptr);

  auto delegate = config_.ui_delegate;
  auto rasterizer = config_.rasterizer->GetWeakRasterizerPtr();

  ftl::AutoResetWaitableEvent latch;

  auto delegate_continuation = [rasterizer, &latch]() {
    if (rasterizer)
      rasterizer->Teardown(&latch);
    // TODO(abarth): We should signal the latch if the rasterizer is gone.
  };

  config_.ui_task_runner->PostTask([delegate, delegate_continuation]() {
    if (delegate)
      delegate->OnOutputSurfaceDestroyed(delegate_continuation);
    // TODO(abarth): We should signal the latch if the delegate is gone.
  });

  latch.Wait();
}

SkISize PlatformView::GetSize() {
  return size_;
}

void PlatformView::Resize(const SkISize& size) {
  size_ = size;
}

void PlatformView::SetupResourceContextOnIOThread() {
  ftl::AutoResetWaitableEvent latch;

  Shell::Shared().io_ftl_task_runner()->PostTask(
      [this, &latch]() { SetupResourceContextOnIOThreadPerform(&latch); });

  latch.Wait();
}

void PlatformView::SetupResourceContextOnIOThreadPerform(
    ftl::AutoResetWaitableEvent* latch) {
  if (blink::ResourceContext::Get() != nullptr) {
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

  blink::ResourceContext::Set(GrContext::Create(
      GrBackend::kOpenGL_GrBackend,
      reinterpret_cast<GrBackendContext>(GrGLCreateNativeInterface())));

  latch->Signal();
}

}  // namespace shell
}  // namespace sky
