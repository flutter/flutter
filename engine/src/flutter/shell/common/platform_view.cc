// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// FLUTTER_NOLINT

#include "flutter/shell/common/platform_view.h"

#include <utility>

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/vsync_waiter_fallback.h"
#include "third_party/skia/include/gpu/GrContextOptions.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace flutter {

PlatformView::PlatformView(Delegate& delegate, TaskRunners task_runners)
    : delegate_(delegate),
      task_runners_(std::move(task_runners)),
      size_(SkISize::Make(0, 0)),
      weak_factory_(this) {}

PlatformView::~PlatformView() = default;

std::unique_ptr<VsyncWaiter> PlatformView::CreateVSyncWaiter() {
  FML_DLOG(WARNING)
      << "This platform does not provide a Vsync waiter implementation. A "
         "simple timer based fallback is being used.";
  return std::make_unique<VsyncWaiterFallback>(task_runners_);
}

void PlatformView::DispatchPlatformMessage(
    fml::RefPtr<PlatformMessage> message) {
  delegate_.OnPlatformViewDispatchPlatformMessage(std::move(message));
}

void PlatformView::DispatchPointerDataPacket(
    std::unique_ptr<PointerDataPacket> packet) {
  delegate_.OnPlatformViewDispatchPointerDataPacket(
      pointer_data_packet_converter_.Convert(std::move(packet)));
}

void PlatformView::DispatchSemanticsAction(int32_t id,
                                           SemanticsAction action,
                                           std::vector<uint8_t> args) {
  delegate_.OnPlatformViewDispatchSemanticsAction(id, action, std::move(args));
}

void PlatformView::SetSemanticsEnabled(bool enabled) {
  delegate_.OnPlatformViewSetSemanticsEnabled(enabled);
}

void PlatformView::SetAccessibilityFeatures(int32_t flags) {
  delegate_.OnPlatformViewSetAccessibilityFeatures(flags);
}

void PlatformView::SetViewportMetrics(const ViewportMetrics& metrics) {
  delegate_.OnPlatformViewSetViewportMetrics(metrics);
}

void PlatformView::NotifyCreated() {
  std::unique_ptr<Surface> surface;

  // Threading: We want to use the platform view on the non-platform thread.
  // Using the weak pointer is illegal. But, we are going to introduce a latch
  // so that the platform view is not collected till the surface is obtained.
  auto* platform_view = this;
  fml::ManualResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(), [platform_view, &surface, &latch]() {
        surface = platform_view->CreateRenderingSurface();
        latch.Signal();
      });
  latch.Wait();
  delegate_.OnPlatformViewCreated(std::move(surface));
}

void PlatformView::NotifyDestroyed() {
  delegate_.OnPlatformViewDestroyed();
}

sk_sp<GrDirectContext> PlatformView::CreateResourceContext() const {
  FML_DLOG(WARNING) << "This platform does not setup the resource "
                       "context on the IO thread for async texture uploads.";
  return nullptr;
}

void PlatformView::ReleaseResourceContext() const {}

PointerDataDispatcherMaker PlatformView::GetDispatcherMaker() {
  return [](DefaultPointerDataDispatcher::Delegate& delegate) {
    return std::make_unique<DefaultPointerDataDispatcher>(delegate);
  };
}

fml::WeakPtr<PlatformView> PlatformView::GetWeakPtr() const {
  return weak_factory_.GetWeakPtr();
}

void PlatformView::UpdateSemantics(SemanticsNodeUpdates update,
                                   CustomAccessibilityActionUpdates actions) {}

void PlatformView::HandlePlatformMessage(fml::RefPtr<PlatformMessage> message) {
  if (auto response = message->response())
    response->CompleteEmpty();
}

void PlatformView::OnPreEngineRestart() const {}

void PlatformView::RegisterTexture(std::shared_ptr<flutter::Texture> texture) {
  delegate_.OnPlatformViewRegisterTexture(std::move(texture));
}

void PlatformView::UnregisterTexture(int64_t texture_id) {
  delegate_.OnPlatformViewUnregisterTexture(texture_id);
}

void PlatformView::MarkTextureFrameAvailable(int64_t texture_id) {
  delegate_.OnPlatformViewMarkTextureFrameAvailable(texture_id);
}

std::unique_ptr<Surface> PlatformView::CreateRenderingSurface() {
  // We have a default implementation because tests create a platform view but
  // never a rendering surface.
  FML_DCHECK(false) << "This platform does not provide a rendering surface but "
                       "it was notified of surface rendering surface creation.";
  return nullptr;
}

void PlatformView::SetNextFrameCallback(const fml::closure& closure) {
  if (!closure) {
    return;
  }

  delegate_.OnPlatformViewSetNextFrameCallback(closure);
}

std::unique_ptr<std::vector<std::string>>
PlatformView::ComputePlatformResolvedLocales(
    const std::vector<std::string>& supported_locale_data) {
  std::unique_ptr<std::vector<std::string>> out =
      std::make_unique<std::vector<std::string>>();
  return out;
}

}  // namespace flutter
