// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_SURFACE_DEFERRED_ROOT_SURFACE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_SURFACE_DEFERRED_ROOT_SURFACE_H_

#include <functional>
#include <memory>
#include <vector>

#include "flutter/flow/surface.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"

namespace flutter {

// Decorates the root Android rendering |Surface| so frames during an active or
// pending Hybrid Composition session record into an intermediate |DisplayList|
// without acquiring a swapchain buffer from |inner_| up front.
//
// When |should_defer| returns false, |AcquireFrame| delegates directly to
// |inner_->AcquireFrame| with zero extra copies or allocations, clearing stale
// |existing_damage| on the first direct frame following a deferred session.
//
// When |should_defer| returns true, |AcquireFrame| binds |inner_|'s render
// context onto the returned |SurfaceFrame| (so |TextureLayer| sampling during
// |LayerTree::Paint| sees an active GL context) and records into a
// |DisplayList|. If the caller later submits the deferred |SurfaceFrame| (for
// example, offstage platform views or dual-render Hybrid Composition exit
// frames), |inner_->AcquireFrame| is lazily invoked at |Encode| time and the
// cached |DisplayList| is replayed and submitted. If the caller instead routes
// the cached |DisplayList| to a |HybridImageReader| surface and drops the root
// |SurfaceFrame| unsubmitted, |inner_| is never acquired or swapped.
//
// Threading: Constructed, used, and destroyed exclusively on the raster thread.
class DeferredRootSurface final : public Surface {
 public:
  using ShouldDeferFn = std::function<bool()>;

  DeferredRootSurface(std::unique_ptr<Surface> inner,
                      ShouldDeferFn should_defer);

  ~DeferredRootSurface() override;

  fml::WeakPtr<DeferredRootSurface> GetWeakPtr() const;

  // Directly acquires a |SurfaceFrame| from |inner_| regardless of
  // |should_defer_| (used to clear transparent root SurfaceViews on Hybrid
  // Composition entry while keeping post-deferral full-repaint tracking armed).
  std::unique_ptr<SurfaceFrame> AcquireInnerFrame(const DlISize& size);

  // Returns true if |frame| is the active deferred frame created by this
  // |DeferredRootSurface| (recording into a |DisplayList| without having
  // acquired |inner_|), and false if |frame| is a direct |inner_| frame.
  bool IsDeferredFrame(const SurfaceFrame& frame) const;

  // Builds and caches the recorded |DisplayList| for |frame| so callers that
  // render the root |DisplayList| to multiple targets (such as a Hybrid
  // Composition exit frame rendering to both the background |ImageReader| and
  // |inner_| via |frame.Submit()|) never invoke destructive
  // |SurfaceFrame::BuildDisplayList()| twice.
  sk_sp<DisplayList> GetOrBuildDisplayList(SurfaceFrame& frame);

  // |Surface|
  bool IsValid() override;

  // |Surface|
  std::unique_ptr<SurfaceFrame> AcquireFrame(const DlISize& size) override;

  // |Surface|
  DlMatrix GetRootTransformation() const override;

  // |Surface|
  GrDirectContext* GetContext() override;

  // |Surface|
  std::unique_ptr<GLContextResult> MakeRenderContextCurrent() override;

  // |Surface|
  bool ClearRenderContext() override;

  // |Surface|
  bool AllowsDrawingWhenGpuDisabled() const override;

  // |Surface|
  bool EnableRasterCache() const override;

  // |Surface|
  std::shared_ptr<impeller::AiksContext> GetAiksContext() const override;

  // |Surface|
  SurfaceData GetSurfaceData() const override;

 private:
  struct DeferredFrameState;

  ShouldDeferFn should_defer_;
  std::unique_ptr<Surface> inner_;
  std::weak_ptr<DeferredFrameState> active_deferred_frame_state_;
  std::vector<std::weak_ptr<DeferredFrameState>> live_deferred_frames_;
  bool had_deferred_frame_ = false;
  fml::WeakPtrFactory<DeferredRootSurface> weak_factory_;

  FML_DISALLOW_COPY_AND_ASSIGN(DeferredRootSurface);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_SURFACE_DEFERRED_ROOT_SURFACE_H_
