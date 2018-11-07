// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef COMMON_PLATFORM_VIEW_H_
#define COMMON_PLATFORM_VIEW_H_

#include <memory>

#include "flutter/common/task_runners.h"
#include "flutter/flow/texture.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/lib/ui/semantics/custom_accessibility_action.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/shell/common/surface.h"
#include "flutter/shell/common/vsync_waiter.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace shell {

class Shell;

class PlatformView {
 public:
  class Delegate {
   public:
    virtual void OnPlatformViewCreated(std::unique_ptr<Surface> surface) = 0;

    virtual void OnPlatformViewDestroyed() = 0;

    virtual void OnPlatformViewSetNextFrameCallback(fml::closure closure) = 0;

    virtual void OnPlatformViewSetViewportMetrics(
        const blink::ViewportMetrics& metrics) = 0;

    virtual void OnPlatformViewDispatchPlatformMessage(
        fml::RefPtr<blink::PlatformMessage> message) = 0;

    virtual void OnPlatformViewDispatchPointerDataPacket(
        std::unique_ptr<blink::PointerDataPacket> packet) = 0;

    virtual void OnPlatformViewDispatchSemanticsAction(
        int32_t id,
        blink::SemanticsAction action,
        std::vector<uint8_t> args) = 0;

    virtual void OnPlatformViewSetSemanticsEnabled(bool enabled) = 0;

    virtual void OnPlatformViewSetAccessibilityFeatures(int32_t flags) = 0;

    virtual void OnPlatformViewRegisterTexture(
        std::shared_ptr<flow::Texture> texture) = 0;

    virtual void OnPlatformViewUnregisterTexture(int64_t texture_id) = 0;

    virtual void OnPlatformViewMarkTextureFrameAvailable(
        int64_t texture_id) = 0;
  };

  explicit PlatformView(Delegate& delegate, blink::TaskRunners task_runners);

  virtual ~PlatformView();

  virtual std::unique_ptr<VsyncWaiter> CreateVSyncWaiter();

  void DispatchPlatformMessage(fml::RefPtr<blink::PlatformMessage> message);

  void DispatchSemanticsAction(int32_t id,
                               blink::SemanticsAction action,
                               std::vector<uint8_t> args);

  virtual void SetSemanticsEnabled(bool enabled);

  virtual void SetAccessibilityFeatures(int32_t flags);

  void SetViewportMetrics(const blink::ViewportMetrics& metrics);

  void NotifyCreated();

  virtual void NotifyDestroyed();

  // Unlike all other methods on the platform view, this one may be called on a
  // non-platform task runner.
  virtual sk_sp<GrContext> CreateResourceContext() const;

  // Unlike all other methods on the platform view, this one may be called on a
  // non-platform task runner.
  virtual void ReleaseResourceContext() const;

  fml::WeakPtr<PlatformView> GetWeakPtr() const;

  virtual void UpdateSemantics(blink::SemanticsNodeUpdates updates,
                               blink::CustomAccessibilityActionUpdates actions);

  virtual void HandlePlatformMessage(
      fml::RefPtr<blink::PlatformMessage> message);

  virtual void OnPreEngineRestart() const;

  void SetNextFrameCallback(fml::closure closure);

  void DispatchPointerDataPacket(
      std::unique_ptr<blink::PointerDataPacket> packet);

  // Called once per texture, on the platform thread.
  void RegisterTexture(std::shared_ptr<flow::Texture> texture);

  // Called once per texture, on the platform thread.
  void UnregisterTexture(int64_t texture_id);

  // Called once per texture update (e.g. video frame), on the platform thread.
  void MarkTextureFrameAvailable(int64_t texture_id);

 protected:
  PlatformView::Delegate& delegate_;
  const blink::TaskRunners task_runners_;

  SkISize size_;
  fml::WeakPtrFactory<PlatformView> weak_factory_;

  virtual std::unique_ptr<Surface> CreateRenderingSurface();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(PlatformView);
};

}  // namespace shell

#endif  // COMMON_PLATFORM_VIEW_H_
