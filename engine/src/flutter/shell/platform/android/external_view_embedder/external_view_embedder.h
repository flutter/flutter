// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_

#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>

#include "flutter/common/task_runners.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/fml/closure.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/external_view_embedder/surface_pool.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/surface/android_surface.h"

namespace flutter {

//------------------------------------------------------------------------------
/// Allows to embed Android views into a Flutter application.
///
/// This class calls Java methods via |PlatformViewAndroidJNI| to manage the
/// lifecycle of the Android view corresponding to |flutter::PlatformViewLayer|.
///
/// It also orchestrates overlay surfaces. These are Android views
/// that render above (by Z order) the Android view corresponding to
/// |flutter::PlatformViewLayer|.
///
class AndroidExternalViewEmbedder final : public ExternalViewEmbedder {
 public:
  AndroidExternalViewEmbedder(
      const AndroidContext& android_context,
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
      std::shared_ptr<AndroidSurfaceFactory> surface_factory,
      const TaskRunners& task_runners,
      fml::closure schedule_frame = {});

  ~AndroidExternalViewEmbedder() override;

  // |ExternalViewEmbedder|
  bool ReadyForNextFrame(const fml::closure& resume) override;

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
  DlCanvas* GetRootCanvas() override;

  // |ExternalViewEmbedder|
  void BeginFrame(GrDirectContext* context) override;

  // |ExternalViewEmbedder|
  void PrepareFlutterView(DlISize frame_size,
                          double device_pixel_ratio) override;

  // |ExternalViewEmbedder|
  void CancelFrame() override;

  // |ExternalViewEmbedder|
  void EndFrame() override;

  // |ExternalViewEmbedder|
  void Teardown() override;

  // Gets the rect based on the device pixel ratio of a platform view displayed
  // on the screen.
  DlRect GetViewRect(int64_t view_id) const;

 private:
  struct PlatformOp {
    enum class Type {
      kDisplayPlatformView,
      kDisplayOverlaySurface,
    };
    Type type = Type::kDisplayPlatformView;
    int64_t view_id = 0;
    int32_t surface_id = 0;
    int32_t x = 0;
    int32_t y = 0;
    int32_t width = 0;
    int32_t height = 0;
    int32_t view_width = 0;
    int32_t view_height = 0;
    MutatorsStack mutators_stack;
  };

  enum class PlatformWorkMode {
    kRetiredIdsOnly,
    kPresent,
    kDrainAborted,
  };

  struct State {
    std::atomic<bool> destroyed{false};
    std::atomic<uint64_t> generation{0};
    std::atomic<uint64_t> next_trace_flow_id{1};
    std::mutex mutex;
    bool in_flight = false;
    fml::closure pending_resume;
  };

  // Provides metadata to the Android surfaces.
  const AndroidContext& android_context_;

  // Allows to call methods in Java.
  const std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;

  // Allows to create surfaces.
  const std::shared_ptr<AndroidSurfaceFactory> surface_factory_;

  // Holds surfaces. Allows to recycle surfaces or allocate new ones.
  const std::shared_ptr<SurfacePool> surface_pool_;

  // The task runners.
  const TaskRunners task_runners_;

  // Platform-thread callback to request a follow-up frame after Frame 0 enters
  // Hybrid Composition mode.
  const fml::closure schedule_frame_;

  // Synchronization and lifetime state shared with asynchronous platform/raster
  // callbacks.
  const std::shared_ptr<State> state_;

  // The size of the root canvas.
  DlISize frame_size_;

  // The pixel ratio used to determinate the size of a platform view layer
  // relative to the device layout system.
  double device_pixel_ratio_ = 0.0;

  // The order of composition. Each entry contains a unique id for the platform
  // view.
  std::vector<int64_t> composition_order_;

  // The |EmbedderViewSlice| implementation keyed off the platform view id,
  // which contains any subsequent operations until the next platform view or
  // the end of the last leaf node in the layer tree.
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices_;

  // The params for a platform view, which contains the size, position and
  // mutation stack.
  std::unordered_map<int64_t, EmbeddedViewParams> view_params_;

  // Whether Java has been placed in Hybrid Composition platform-view mode for
  // the preceding frame (meaning overlay views and ImageView backing may be
  // active until transitioned back out). Raster thread only.
  bool presented_platform_views_ = false;

  // Whether Java overlay surfaces may have been created or scheduled for
  // async destruction since the last |Teardown|. Raster thread only.
  bool overlays_may_exist_ = false;

  // Overlay layer IDs retired on the raster thread (e.g. during resize) whose
  // Java counterparts still need to be destroyed on the platform thread.
  // Raster thread only.
  std::vector<int32_t> pending_retired_overlay_ids_;

  // Takes the overlay layers out of the pool on the raster thread and queues
  // their Java layer IDs into |pending_retired_overlay_ids_| for destruction
  // on the platform thread.
  void ReleaseOverlayLayers();

  // Posts queued retired overlay IDs (without presenting a frame) if any are
  // pending when a frame ends without reaching |SubmitFlutterView|.
  void FlushRetiredOverlayIds();

  // Posts platform-thread view/overlay presentation ops, aborted-frame buffer
  // draining, and retired overlay ID destruction. For |kPresent| and
  // |kDrainAborted|, marks work as in-flight so |ReadyForNextFrame| applies
  // backpressure until the platform thread finishes and signals the raster
  // thread.
  void PostPlatformWork(PlatformWorkMode mode,
                        std::vector<PlatformOp> ops,
                        std::vector<int32_t> retired_ids,
                        std::vector<int32_t> aborted_overlay_ids = {},
                        bool schedule_frame_after_present = false);

  // Resets the frame state.
  void Reset();

  // Whether the layer tree in the current frame has platform layers.
  bool FrameHasPlatformLayers();

  // Creates a Surface when needed or recycles an existing one, draws the
  // picture on the overlay frame's canvas, and sets |out_surface_id| to the
  // overlay's layer ID. Returns nullptr if layer allocation or acquiring a
  // frame from the overlay surface fails.
  std::unique_ptr<SurfaceFrame> CreateSurfaceIfNeeded(GrDirectContext* context,
                                                      int64_t view_id,
                                                      EmbedderViewSlice* slice,
                                                      const DlRect& rect,
                                                      int32_t* out_surface_id);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_
