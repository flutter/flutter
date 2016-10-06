// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/platform_view.h"

#include <utility>

#include "flutter/common/threads.h"
#include "flutter/glue/movable_wrapper.h"
#include "flutter/lib/ui/painting/resource_context.h"
#include "flutter/shell/common/rasterizer.h"
#include "lib/ftl/functional/wrap_lambda.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace shell {

PlatformView::Config::Config() : rasterizer(nullptr) {}

PlatformView::Config::~Config() = default;

PlatformView::PlatformView(std::unique_ptr<Rasterizer> rasterizer)
    : rasterizer_(std::move(rasterizer)), size_(SkISize::Make(0, 0)) {
  engine_.reset(new Engine(rasterizer_.get()));

  // Setup the platform config.
  config_.ui_delegate = engine_->GetWeakPtr();
  config_.rasterizer = rasterizer_.get();
}

PlatformView::~PlatformView() {
  blink::Threads::UI()->PostTask(
      []() { Shell::Shared().PurgePlatformViews(); });

  Rasterizer* rasterizer = rasterizer_.release();
  blink::Threads::Gpu()->PostTask([rasterizer]() { delete rasterizer; });

  Engine* engine = engine_.release();
  blink::Threads::UI()->PostTask([engine]() { delete engine; });
}

void PlatformView::ConnectToEngine(
    mojo::InterfaceRequest<sky::SkyEngine> request) {
  ftl::WeakPtr<UIDelegate> ui_delegate = config_.ui_delegate;
  auto wrapped_request = glue::WrapMovable(std::move(request));
  blink::Threads::UI()->PostTask([ui_delegate, wrapped_request]() mutable {
    if (ui_delegate)
      ui_delegate->ConnectToEngine(wrapped_request.Unwrap());
  });
  ftl::WeakPtr<PlatformView> view = GetWeakViewPtr();
  blink::Threads::UI()->PostTask(
      [view]() { Shell::Shared().AddPlatformView(view); });
}

void PlatformView::NotifyCreated(std::unique_ptr<Surface> surface) {
  NotifyCreated(std::move(surface), []() {});
}

void PlatformView::NotifyCreated(std::unique_ptr<Surface> surface,
                                 ftl::Closure caller_continuation) {
  FTL_CHECK(config_.rasterizer);

  ftl::AutoResetWaitableEvent latch;

  auto ui_continuation = ftl::WrapLambda([
    delegate = config_.ui_delegate,   //
    rasterizer = config_.rasterizer,  //
    surface = std::move(surface),     //
    caller_continuation,              //
    &latch
  ]() mutable {
    auto gpu_continuation = ftl::WrapLambda([
      rasterizer,                    //
      surface = std::move(surface),  //
      caller_continuation,           //
      &latch
    ]() mutable {
      // Runs on the GPU Thread. So does the Caller Continuation.
      surface->Setup();
      rasterizer->Setup(std::move(surface), caller_continuation, &latch);
    });
    // Runs on the UI Thread.
    delegate->OnOutputSurfaceCreated(std::move(gpu_continuation));
  });

  // Runs on the Platform Thread.
  blink::Threads::UI()->PostTask(std::move(ui_continuation));

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

  blink::Threads::UI()->PostTask([delegate, delegate_continuation]() {
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

  blink::Threads::IO()->PostTask(
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
    latch->Signal();
    return;
  }

  blink::ResourceContext::Set(GrContext::Create(
      GrBackend::kOpenGL_GrBackend,
      reinterpret_cast<GrBackendContext>(GrGLCreateNativeInterface())));
  latch->Signal();
}

}  // namespace shell
