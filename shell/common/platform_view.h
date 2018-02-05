// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef COMMON_PLATFORM_VIEW_H_
#define COMMON_PLATFORM_VIEW_H_

#include <memory>

#include "flutter/flow/texture.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/surface.h"
#include "flutter/shell/common/vsync_waiter.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/weak_ptr.h"
#include "lib/fxl/synchronization/waitable_event.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace shell {

class Rasterizer;

class PlatformView : public std::enable_shared_from_this<PlatformView> {
 public:
  struct SurfaceConfig {
    uint8_t red_bits = 8;
    uint8_t green_bits = 8;
    uint8_t blue_bits = 8;
    uint8_t alpha_bits = 8;
    uint8_t depth_bits = 0;
    uint8_t stencil_bits = 8;
  };

  void SetupResourceContextOnIOThread();

  virtual ~PlatformView();

  virtual void Attach() = 0;

  void DispatchPlatformMessage(fxl::RefPtr<blink::PlatformMessage> message);
  void DispatchSemanticsAction(int32_t id,
                               blink::SemanticsAction action,
                               std::vector<uint8_t> args);
  void SetSemanticsEnabled(bool enabled);

  void NotifyCreated(std::unique_ptr<Surface> surface);

  void NotifyCreated(std::unique_ptr<Surface> surface,
                     fxl::Closure continuation);

  void NotifyDestroyed();

  std::weak_ptr<PlatformView> GetWeakPtr();

  // The VsyncWaiter will live at least as long as the PlatformView.
  virtual VsyncWaiter* GetVsyncWaiter();

  virtual bool ResourceContextMakeCurrent() = 0;

  virtual void UpdateSemantics(blink::SemanticsNodeUpdates update);
  virtual void HandlePlatformMessage(
      fxl::RefPtr<blink::PlatformMessage> message);

  // Called once per texture, on the platform thread.
  void RegisterTexture(std::shared_ptr<flow::Texture> texture);

  // Called once per texture, on the platform thread.
  void UnregisterTexture(int64_t texture_id);

  // Called once per texture update (e.g. video frame), on the platform thread.
  virtual void MarkTextureFrameAvailable(int64_t texture_id);

  void SetRasterizer(std::unique_ptr<Rasterizer> rasterizer);

  Rasterizer& rasterizer() { return *rasterizer_; }
  Engine& engine() { return *engine_; }

  virtual void RunFromSource(const std::string& assets_directory,
                             const std::string& main,
                             const std::string& packages) = 0;

  virtual void SetAssetBundlePath(const std::string& assets_directory) = 0;

 protected:
  explicit PlatformView(std::unique_ptr<Rasterizer> rasterizer);

  void CreateEngine();

  void SetupResourceContextOnIOThreadPerform(
      fxl::AutoResetWaitableEvent* event);

  SurfaceConfig surface_config_;
  std::unique_ptr<Rasterizer> rasterizer_;
  flow::TextureRegistry texture_registry_;
  std::unique_ptr<Engine> engine_;
  std::unique_ptr<VsyncWaiter> vsync_waiter_;
  SkISize size_;

 private:
  FXL_DISALLOW_COPY_AND_ASSIGN(PlatformView);
};

}  // namespace shell

#endif  // COMMON_PLATFORM_VIEW_H_
