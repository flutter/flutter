// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/platform_view.h"

#include <utility>

#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/vsync_waiter_fallback.h"
#include "lib/fxl/functional/make_copyable.h"
#include "lib/fxl/synchronization/waitable_event.h"
#include "third_party/skia/include/gpu/GrContextOptions.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace shell {

PlatformView::PlatformView(Delegate& delegate, blink::TaskRunners task_runners)
    : delegate_(delegate),
      task_runners_(std::move(task_runners)),
      size_(SkISize::Make(0, 0)),
      weak_factory_(this) {
  weak_prototype_ = weak_factory_.GetWeakPtr();
}

PlatformView::~PlatformView() = default;

std::unique_ptr<VsyncWaiter> PlatformView::CreateVSyncWaiter() {
  FXL_DLOG(WARNING)
      << "This platform does not provide a Vsync waiter implementation. A "
         "simple timer based fallback is being used.";
  return std::make_unique<VsyncWaiterFallback>(task_runners_);
}

void PlatformView::DispatchPlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  delegate_.OnPlatformViewDispatchPlatformMessage(*this, std::move(message));
}

void PlatformView::DispatchPointerDataPacket(
    std::unique_ptr<blink::PointerDataPacket> packet) {
  delegate_.OnPlatformViewDispatchPointerDataPacket(*this, std::move(packet));
}

void PlatformView::DispatchSemanticsAction(int32_t id,
                                           blink::SemanticsAction action,
                                           std::vector<uint8_t> args) {
  delegate_.OnPlatformViewDispatchSemanticsAction(*this, id, action,
                                                  std::move(args));
}

void PlatformView::SetSemanticsEnabled(bool enabled) {
  delegate_.OnPlatformViewSetSemanticsEnabled(*this, enabled);
}

void PlatformView::SetViewportMetrics(const blink::ViewportMetrics& metrics) {
  delegate_.OnPlatformViewSetViewportMetrics(*this, metrics);
}

void PlatformView::NotifyCreated() {
  delegate_.OnPlatformViewCreated(*this, CreateRenderingSurface());
}

void PlatformView::NotifyDestroyed() {
  delegate_.OnPlatformViewDestroyed(*this);
}

sk_sp<GrContext> PlatformView::CreateResourceContext() const {
  FXL_DLOG(WARNING) << "This platform does not setup the resource "
                       "context on the IO thread for async texture uploads.";
  return nullptr;
}

fml::WeakPtr<PlatformView> PlatformView::GetWeakPtr() const {
  return weak_prototype_;
}

void PlatformView::UpdateSemantics(blink::SemanticsNodeUpdates update) {}

void PlatformView::HandlePlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  if (auto response = message->response())
    response->CompleteEmpty();
}

void PlatformView::RegisterTexture(std::shared_ptr<flow::Texture> texture) {
  delegate_.OnPlatformViewRegisterTexture(*this, std::move(texture));
}

void PlatformView::UnregisterTexture(int64_t texture_id) {
  delegate_.OnPlatformViewUnregisterTexture(*this, texture_id);
}

void PlatformView::MarkTextureFrameAvailable(int64_t texture_id) {
  delegate_.OnPlatformViewMarkTextureFrameAvailable(*this, texture_id);
}

std::unique_ptr<Surface> PlatformView::CreateRenderingSurface() {
  // We have a default implementation because tests create a platform view but
  // never a rendering surface.
  FXL_DCHECK(false) << "This platform does not provide a rendering surface but "
                       "it was notified of surface rendering surface creation.";
  return nullptr;
}

void PlatformView::SetNextFrameCallback(fxl::Closure closure) {
  if (!closure) {
    return;
  }

  delegate_.OnPlatformViewSetNextFrameCallback(*this, std::move(closure));
}

}  // namespace shell
