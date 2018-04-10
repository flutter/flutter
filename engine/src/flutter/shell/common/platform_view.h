// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef COMMON_PLATFORM_VIEW_H_
#define COMMON_PLATFORM_VIEW_H_

#include <memory>

#include "flutter/common/task_runners.h"
#include "flutter/flow/texture.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/shell/common/surface.h"
#include "flutter/shell/common/vsync_waiter.h"
#include "lib/fxl/macros.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace shell {

class Shell;

class PlatformView {
 public:
  class Delegate {
   public:
    virtual void OnPlatformViewCreated(const PlatformView& view,
                                       std::unique_ptr<Surface> surface) = 0;

    virtual void OnPlatformViewDestroyed(const PlatformView& view) = 0;

    virtual void OnPlatformViewSetNextFrameCallback(const PlatformView& view,
                                                    fxl::Closure closure) = 0;

    virtual void OnPlatformViewSetViewportMetrics(
        const PlatformView& view,
        const blink::ViewportMetrics& metrics) = 0;

    virtual void OnPlatformViewDispatchPlatformMessage(
        const PlatformView& view,
        fxl::RefPtr<blink::PlatformMessage> message) = 0;

    virtual void OnPlatformViewDispatchPointerDataPacket(
        const PlatformView& view,
        std::unique_ptr<blink::PointerDataPacket> packet) = 0;

    virtual void OnPlatformViewDispatchSemanticsAction(
        const PlatformView& view,
        int32_t id,
        blink::SemanticsAction action,
        std::vector<uint8_t> args) = 0;

    virtual void OnPlatformViewSetSemanticsEnabled(const PlatformView& view,
                                                   bool enabled) = 0;

    virtual void OnPlatformViewRegisterTexture(
        const PlatformView& view,
        std::shared_ptr<flow::Texture> texture) = 0;

    virtual void OnPlatformViewUnregisterTexture(const PlatformView& view,
                                                 int64_t texture_id) = 0;

    virtual void OnPlatformViewMarkTextureFrameAvailable(
        const PlatformView& view,
        int64_t texture_id) = 0;
  };

  explicit PlatformView(Delegate& delegate, blink::TaskRunners task_runners);

  virtual ~PlatformView();

  virtual std::unique_ptr<VsyncWaiter> CreateVSyncWaiter();

  void DispatchPlatformMessage(fxl::RefPtr<blink::PlatformMessage> message);

  void DispatchSemanticsAction(int32_t id,
                               blink::SemanticsAction action,
                               std::vector<uint8_t> args);

  virtual void SetSemanticsEnabled(bool enabled);

  void SetViewportMetrics(const blink::ViewportMetrics& metrics);

  void NotifyCreated();

  virtual void NotifyDestroyed();

  // Unlike all other methods on the platform view, this one may be called on a
  // non-platform task runner.
  virtual sk_sp<GrContext> CreateResourceContext() const;

  fml::WeakPtr<PlatformView> GetWeakPtr() const;

  virtual void UpdateSemantics(blink::SemanticsNodeUpdates update);

  virtual void HandlePlatformMessage(
      fxl::RefPtr<blink::PlatformMessage> message);

  void SetNextFrameCallback(fxl::Closure closure);

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
  std::unique_ptr<VsyncWaiter> vsync_waiter_;

  SkISize size_;
  fml::WeakPtr<PlatformView> weak_prototype_;
  fml::WeakPtrFactory<PlatformView> weak_factory_;

  virtual std::unique_ptr<Surface> CreateRenderingSurface();

 private:
  FXL_DISALLOW_COPY_AND_ASSIGN(PlatformView);
};

}  // namespace shell

#endif  // COMMON_PLATFORM_VIEW_H_
