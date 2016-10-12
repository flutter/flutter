// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/platform_view.h"

#include <utility>

#include "flutter/common/threads.h"
#include "flutter/lib/ui/painting/resource_context.h"
#include "flutter/shell/common/rasterizer.h"
#include "lib/ftl/functional/make_copyable.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace shell {

PlatformView::PlatformView(std::unique_ptr<Rasterizer> rasterizer)
    : rasterizer_(std::move(rasterizer)),
      size_(SkISize::Make(0, 0)),
      weak_factory_(this) {
  engine_.reset(new Engine(this));
}

PlatformView::~PlatformView() {
  blink::Threads::UI()->PostTask(
      []() { Shell::Shared().PurgePlatformViews(); });

  Rasterizer* rasterizer = rasterizer_.release();
  blink::Threads::Gpu()->PostTask([rasterizer]() { delete rasterizer; });

  Engine* engine = engine_.release();
  blink::Threads::UI()->PostTask([engine]() { delete engine; });
}

void PlatformView::DispatchSemanticsAction(int32_t id,
                                           blink::SemanticsAction action) {
  blink::Threads::UI()->PostTask(
      [ engine = engine_->GetWeakPtr(), id, action ] {
        if (engine.get()) {
          engine->DispatchSemanticsAction(
              id, static_cast<blink::SemanticsAction>(action));
        }
      });
}

void PlatformView::SetSemanticsEnabled(bool enabled) {
  blink::Threads::UI()->PostTask([ engine = engine_->GetWeakPtr(), enabled ] {
    if (engine.get())
      engine->SetSemanticsEnabled(enabled);
  });
}

void PlatformView::ConnectToEngine(
    mojo::InterfaceRequest<sky::SkyEngine> request) {
  blink::Threads::UI()->PostTask(ftl::MakeCopyable([
    view = GetWeakPtr(), engine = engine().GetWeakPtr(),
    request = std::move(request)
  ]() mutable {
    if (engine.get())
      engine->ConnectToEngine(std::move(request));
    Shell::Shared().AddPlatformView(view);
  }));
}

void PlatformView::NotifyCreated(std::unique_ptr<Surface> surface) {
  NotifyCreated(std::move(surface), []() {});
}

void PlatformView::NotifyCreated(std::unique_ptr<Surface> surface,
                                 ftl::Closure caller_continuation) {
  ftl::AutoResetWaitableEvent latch;

  auto ui_continuation = ftl::MakeCopyable([
    this,                          //
    surface = std::move(surface),  //
    caller_continuation,           //
    &latch
  ]() mutable {
    auto gpu_continuation = ftl::MakeCopyable([
      this,                          //
      surface = std::move(surface),  //
      caller_continuation,           //
      &latch
    ]() mutable {
      // Runs on the GPU Thread. So does the Caller Continuation.
      surface->Setup();
      rasterizer_->Setup(std::move(surface), caller_continuation, &latch);
    });
    // Runs on the UI Thread.
    engine_->OnOutputSurfaceCreated(std::move(gpu_continuation));
  });

  // Runs on the Platform Thread.
  blink::Threads::UI()->PostTask(std::move(ui_continuation));

  latch.Wait();
}

void PlatformView::NotifyDestroyed() {
  ftl::AutoResetWaitableEvent latch;

  auto engine_continuation = [this, &latch]() {
    rasterizer_->Teardown(&latch);
  };

  blink::Threads::UI()->PostTask([this, engine_continuation]() {
    engine_->OnOutputSurfaceDestroyed(engine_continuation);
  });

  latch.Wait();
}

ftl::WeakPtr<PlatformView> PlatformView::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void PlatformView::UpdateSemantics(std::vector<blink::SemanticsNode> update) {}

void PlatformView::HandlePlatformMessage(
    ftl::RefPtr<blink::PlatformMessage> message) {
  message->InvokeCallbackWithError();
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
