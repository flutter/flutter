// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_

#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <optional>
#include <unordered_map>
#include <vector>

#include "flutter/common/task_runners.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/external_view_embedder/frame_packet_mailbox.h"
#include "flutter/shell/platform/android/external_view_embedder/image_layer_pool.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/surface/android_surface.h"
#include "flutter/shell/platform/android/surface/deferred_root_surface.h"

namespace flutter {

// Shared raster-thread-only slot holding the current |DeferredRootSurface|
// weak pointer across `NotifyCreated` / `NotifyDestroyed` surface lifecycles.
// Wrapped in `std::optional` so constructing the slot on the platform thread
// never default-constructs a thread-bound `fml::WeakPtr`.
using DeferredRootSurfaceSlot =
    std::optional<fml::WeakPtr<DeferredRootSurface>>;

//------------------------------------------------------------------------------
/// Embeds Classic Hybrid Composition Android views into a Flutter scene without
/// merging the raster thread onto the Android UI (`main`) thread.
///
/// All layer rasterization, GPU submission, and `HybridImageReader` /
/// `SyncFence` acquisition execute on `1.raster`. Completed buffers, platform
/// view bounds, and mutator stacks are published as an immutable |FramePacket|
/// into a single-slot |FramePacketMailbox| and applied atomically in a single
/// `main` Looper turn.
///
class AndroidExternalViewEmbedder final : public ExternalViewEmbedder {
 public:
  using ScheduleFrameCallback = std::function<void()>;

  AndroidExternalViewEmbedder(
      const AndroidContext& android_context,
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
      std::shared_ptr<AndroidSurfaceFactory> surface_factory,
      const TaskRunners& task_runners,
      std::shared_ptr<HybridCompositionState> hc_state = nullptr,
      std::shared_ptr<DeferredRootSurfaceSlot> deferred_root_surface_slot =
          nullptr,
      ScheduleFrameCallback schedule_frame_callback = {});

  ~AndroidExternalViewEmbedder() override;

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(
      int64_t view_id,
      std::unique_ptr<flutter::EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  DlCanvas* CompositeEmbeddedView(int64_t view_id) override;

  // |ExternalViewEmbedder|
  void SubmitFlutterView(
      int64_t flutter_view_id,
      GrDirectContext* context,
      const std::shared_ptr<impeller::AiksContext>& aiks_context,
      std::unique_ptr<SurfaceFrame> frame) override;

  // |ExternalViewEmbedder|
  PostPrerollResult PostPrerollAction(
      const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger)
      override;

  // |ExternalViewEmbedder|
  DlCanvas* GetRootCanvas() override;

  // |ExternalViewEmbedder|
  void BeginFrame(GrDirectContext* context,
                  const fml::RefPtr<fml::RasterThreadMerger>&
                      raster_thread_merger) override;

  // |ExternalViewEmbedder|
  void PrepareFlutterView(DlISize frame_size,
                          double device_pixel_ratio) override;

  // |ExternalViewEmbedder|
  void CancelFrame() override;

  // |ExternalViewEmbedder|
  void EndFrame(bool should_resubmit_frame,
                const fml::RefPtr<fml::RasterThreadMerger>&
                    raster_thread_merger) override;

  // |ExternalViewEmbedder|
  bool SupportsDynamicThreadMerging() override;

  // |ExternalViewEmbedder|
  bool SupportsPartialRepaint() const override;

  // |ExternalViewEmbedder|
  bool DidLastSubmitSucceed() const override;

  // |ExternalViewEmbedder|
  void Teardown() override;

  // Gets the rect based on the device pixel ratio of a platform view displayed
  // on the screen.
  DlRect GetViewRect(int64_t view_id) const;

 private:
  static void DrainMailboxOnPlatformThread(
      const std::shared_ptr<FramePacketMailbox>& mailbox,
      const std::shared_ptr<HybridCompositionState>& hc_state,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  DeferredRootSurface* GetDeferredRootSurface() const;

  sk_sp<DisplayList> GetRootDisplayList(SurfaceFrame& frame) const;

  void RestoreRootRenderContextIfNeeded(bool destroyed_any_layer) const;

  void FlattenSlicesIntoCanvas(DlCanvas* canvas,
                               std::optional<DlIRect> clip_damage) const;

  void PublishPacket(std::unique_ptr<FramePacket> packet);

  void AbortFrameAndScheduleRetry(
      const std::vector<ImageLayer*>& unacquired_submitted_layers,
      bool destroyed_any_layer);

  void ScheduleRetryFrameIfAllowed();

  void Reset();

  bool FrameHasPlatformLayers() const;

  const AndroidContext& android_context_;
  const std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
  const std::shared_ptr<AndroidSurfaceFactory> surface_factory_;
  const TaskRunners task_runners_;
  const std::shared_ptr<HybridCompositionState> hc_state_;
  const std::shared_ptr<DeferredRootSurfaceSlot> deferred_root_surface_slot_;
  const ScheduleFrameCallback schedule_frame_callback_;
  const std::shared_ptr<FramePacketMailbox> mailbox_;

  ImageLayerPool image_layer_pool_;
  DlISize frame_size_;
  double device_pixel_ratio_ = 0.0;
  std::vector<int64_t> composition_order_;
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices_;
  std::unordered_map<int64_t, EmbeddedViewParams> view_params_;

  uint64_t current_frame_hc_epoch_ = 0;
  bool frame_began_ = false;
  bool hc_background_synchronized_ = false;
  bool last_submit_succeeded_ = true;
  int consecutive_abort_retries_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidExternalViewEmbedder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_
