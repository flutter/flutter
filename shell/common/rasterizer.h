// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_RASTERIZER_H_
#define SHELL_COMMON_RASTERIZER_H_

#include <memory>
#include <optional>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/flow/compositor_context.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/flow/frame_timings.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/surface.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/raster_thread_merger.h"
#include "flutter/fml/synchronization/sync_switch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/lib/ui/snapshot_delegate.h"
#include "flutter/shell/common/pipeline.h"
#include "flutter/shell/common/snapshot_surface_producer.h"
#include "third_party/skia/include/core/SkImage.h"

namespace flutter {

//------------------------------------------------------------------------------
/// The rasterizer is a component owned by the shell that resides on the raster
/// task runner. Each shell owns exactly one instance of a rasterizer. The
/// rasterizer may only be created, used and collected on the raster task
/// runner.
///
/// The rasterizer owns the instance of the currently active on-screen render
/// surface. On this surface, it renders the contents of layer trees submitted
/// to it by the `Engine` (which lives on the UI task runner).
///
/// The primary components owned by the rasterizer are the compositor context
/// and the on-screen render surface. The compositor context has all the GPU
/// state necessary to render frames to the render surface.
///
class Rasterizer final : public SnapshotDelegate,
                         public Stopwatch::RefreshRateUpdater {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Used to forward events from the rasterizer to interested
  ///             subsystems. Currently, the shell sets itself up as the
  ///             rasterizer delegate to listen for frame rasterization events.
  ///             It can then forward these events to the engine.
  ///
  ///             Like all rasterizer operation, the rasterizer delegate call
  ///             are made on the raster task runner. Any delegate must ensure
  ///             that they can handle the threading implications.
  ///
  class Delegate {
   public:
    //--------------------------------------------------------------------------
    /// @brief      Notifies the delegate that a frame has been rendered. The
    ///             rasterizer collects profiling information for each part of
    ///             the frame workload. This profiling information is made
    ///             available to the delegate for forwarding to subsystems
    ///             interested in collecting such profiles. Currently, the shell
    ///             (the delegate) forwards this to the engine where Dart code
    ///             can react to this information.
    ///
    /// @see        `FrameTiming`
    ///
    /// @param[in]  frame_timing  Instrumentation information for each phase of
    ///                           the frame workload.
    ///
    virtual void OnFrameRasterized(const FrameTiming& frame_timing) = 0;

    /// Time limit for a smooth frame.
    ///
    /// See: `DisplayManager::GetMainDisplayRefreshRate`.
    virtual fml::Milliseconds GetFrameBudget() = 0;

    /// Target time for the latest frame. See also `Shell::OnAnimatorBeginFrame`
    /// for when this time gets updated.
    virtual fml::TimePoint GetLatestFrameTargetTime() const = 0;

    /// Task runners used by the shell.
    virtual const TaskRunners& GetTaskRunners() const = 0;

    /// The raster thread merger from parent shell's rasterizer.
    virtual const fml::RefPtr<fml::RasterThreadMerger>
    GetParentRasterThreadMerger() const = 0;

    /// Accessor for the shell's GPU sync switch, which determines whether GPU
    /// operations are allowed on the current thread.
    ///
    /// For example, on some platforms when the application is backgrounded it
    /// is critical that GPU operations are not processed.
    virtual std::shared_ptr<const fml::SyncSwitch> GetIsGpuDisabledSyncSwitch()
        const = 0;
  };

  //----------------------------------------------------------------------------
  /// @brief     How to handle calls to MakeGpuImage.
  enum class MakeGpuImageBehavior {
    /// MakeGpuImage returns a GPU resident image, if possible.
    kGpu,
    /// MakeGpuImage returns a checkerboard bitmap. This is useful in test
    /// contexts where no GPU surface is available.
    kBitmap,
  };

  //----------------------------------------------------------------------------
  /// @brief      Creates a new instance of a rasterizer. Rasterizers may only
  ///             be created on the raster task runner. Rasterizers are
  ///             currently only created by the shell (which also sets itself up
  ///             as the rasterizer delegate).
  ///
  /// @param[in]  delegate                   The rasterizer delegate.
  /// @param[in]  gpu_image_behavior         How to handle calls to
  ///                                        MakeGpuImage.
  ///
  explicit Rasterizer(
      Delegate& delegate,
      MakeGpuImageBehavior gpu_image_behavior = MakeGpuImageBehavior::kGpu);

  //----------------------------------------------------------------------------
  /// @brief      Destroys the rasterizer. This must happen on the raster task
  ///             runner. All GPU resources are collected before this call
  ///             returns. Any context set up by the embedder to hold these
  ///             resources can be immediately collected as well.
  ///
  ~Rasterizer();

  //----------------------------------------------------------------------------
  /// @brief      Rasterizers may be created well before an on-screen surface is
  ///             available for rendering. Shells usually create a rasterizer in
  ///             their constructors. Once an on-screen surface is available
  ///             however, one may be provided to the rasterizer using this
  ///             call. No rendering may occur before this call. The surface is
  ///             held till the balancing call to `Rasterizer::Teardown` is
  ///             made. Calling a setup before tearing down the previous surface
  ///             (if this is not the first time the surface has been set up) is
  ///             user error.
  ///
  /// @see        `Rasterizer::Teardown`
  ///
  /// @param[in]  surface  The on-screen render surface.
  ///
  void Setup(std::unique_ptr<Surface> surface);

  //----------------------------------------------------------------------------
  /// @brief      Releases the previously set up on-screen render surface and
  ///             collects associated resources. No more rendering may occur
  ///             till the next call to `Rasterizer::Setup` with a new render
  ///             surface. Calling a teardown without a setup is user error.
  ///
  void Teardown();

  //----------------------------------------------------------------------------
  /// @brief      Releases any resource used by the external view embedder.
  ///             For example, overlay surfaces or Android views.
  ///             On Android, this method post a task to the platform thread,
  ///             and waits until it completes.
  void TeardownExternalViewEmbedder();

  //----------------------------------------------------------------------------
  /// @brief      Notifies the rasterizer that there is a low memory situation
  ///             and it must purge as many unnecessary resources as possible.
  ///             Currently, the Skia context associated with onscreen rendering
  ///             is told to free GPU resources.
  ///
  void NotifyLowMemoryWarning() const;

  //----------------------------------------------------------------------------
  /// @brief      Gets a weak pointer to the rasterizer. The rasterizer may only
  ///             be accessed on the raster task runner.
  ///
  /// @return     The weak pointer to the rasterizer.
  ///
  fml::TaskRunnerAffineWeakPtr<Rasterizer> GetWeakPtr() const;

  fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> GetSnapshotDelegate() const;

  //----------------------------------------------------------------------------
  /// @brief      Sometimes, it may be necessary to render the same frame again
  ///             without having to wait for the framework to build a whole new
  ///             layer tree describing the same contents. One such case is when
  ///             external textures (video or camera streams for example) are
  ///             updated in an otherwise static layer tree. To support this use
  ///             case, the rasterizer holds onto the last rendered layer tree.
  ///
  /// @bug        https://github.com/flutter/flutter/issues/33939
  ///
  /// @return     A pointer to the last layer or `nullptr` if this rasterizer
  ///             has never rendered a frame.
  ///
  flutter::LayerTree* GetLastLayerTree();

  //----------------------------------------------------------------------------
  /// @brief      Draws a last layer tree to the render surface. This may seem
  ///             entirely redundant at first glance. After all, on surface loss
  ///             and re-acquisition, the framework generates a new layer tree.
  ///             Otherwise, why render the same contents to the screen again?
  ///             This is used as an optimization in cases where there are
  ///             external textures (video or camera streams for example) in
  ///             referenced in the layer tree. These textures may be updated at
  ///             a cadence different from that of the Flutter application.
  ///             Flutter can re-render the layer tree with just the updated
  ///             textures instead of waiting for the framework to do the work
  ///             to generate the layer tree describing the same contents.
  ///
  void DrawLastLayerTree(
      std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder);

  //----------------------------------------------------------------------------
  /// @brief      Gets the registry of external textures currently in use by the
  ///             rasterizer. These textures may be updated at a cadence
  ///             different from that of the Flutter application. When an
  ///             external texture is referenced in the Flutter layer tree, that
  ///             texture is composited within the Flutter layer tree.
  ///
  /// @return     A pointer to the external texture registry.
  ///
  flutter::TextureRegistry* GetTextureRegistry();

  using LayerTreeDiscardCallback = std::function<bool(flutter::LayerTree&)>;

  //----------------------------------------------------------------------------
  /// @brief      Takes the next item from the layer tree pipeline and executes
  ///             the raster thread frame workload for that pipeline item to
  ///             render a frame on the on-screen surface.
  ///
  ///             Why does the draw call take a layer tree pipeline and not the
  ///             layer tree directly?
  ///
  ///             The pipeline is the way book-keeping of frame workloads
  ///             distributed across the multiple threads is managed. The
  ///             rasterizer deals with the pipelines directly (instead of layer
  ///             trees which is what it actually renders) because the pipeline
  ///             consumer's workload must be accounted for within the pipeline
  ///             itself. If the rasterizer took the layer tree directly, it
  ///             would have to be taken out of the pipeline. That would signal
  ///             the end of the frame workload and the pipeline would be ready
  ///             for new frames. But the last frame has not been rendered by
  ///             the frame yet! On the other hand, the pipeline must own the
  ///             layer tree it renders because it keeps a reference to the last
  ///             layer tree around till a new frame is rendered. So a simple
  ///             reference wont work either. The `Rasterizer::DoDraw` method
  ///             actually performs the GPU operations within the layer tree
  ///             pipeline.
  ///
  /// @see        `Rasterizer::DoDraw`
  ///
  /// @param[in]  pipeline  The layer tree pipeline to take the next layer tree
  ///                       to render from.
  /// @param[in]  discard_callback if specified and returns true, the layer tree
  ///                             is discarded instead of being rendered
  ///
  RasterStatus Draw(std::shared_ptr<LayerTreePipeline> pipeline,
                    LayerTreeDiscardCallback discard_callback = NoDiscard);

  //----------------------------------------------------------------------------
  /// @brief      The type of the screenshot to obtain of the previously
  ///             rendered layer tree.
  ///
  enum class ScreenshotType {
    //--------------------------------------------------------------------------
    /// A format used to denote a Skia picture. A Skia picture is a serialized
    /// representation of an `SkPicture` that can be used to introspect the
    /// series of commands used to draw that picture.
    ///
    /// Skia pictures are typically stored as files with the .skp extension on
    /// disk. These files may be viewed in an interactive debugger available at
    /// https://debugger.skia.org/
    ///
    SkiaPicture,

    //--------------------------------------------------------------------------
    /// A format used to denote uncompressed image data. This format
    /// is 32 bits per pixel, 8 bits per component and
    /// denoted by the `kN32_SkColorType ` Skia color type.
    ///
    UncompressedImage,

    //--------------------------------------------------------------------------
    /// A format used to denote compressed image data. The PNG compressed
    /// container is used.
    ///
    CompressedImage,
  };

  //----------------------------------------------------------------------------
  /// @brief      A POD type used to return the screenshot data along with the
  ///             size of the frame.
  ///
  struct Screenshot {
    //--------------------------------------------------------------------------
    /// The data used to describe the screenshot. The data format depends on the
    /// type of screenshot taken and any further encoding done to the same.
    ///
    /// @see      `ScreenshotType`
    ///
    sk_sp<SkData> data;

    //--------------------------------------------------------------------------
    /// The size of the screenshot in texels.
    ///
    SkISize frame_size = SkISize::MakeEmpty();

    //--------------------------------------------------------------------------
    /// @brief      Creates an empty screenshot
    ///
    Screenshot();

    //--------------------------------------------------------------------------
    /// @brief      Creates a screenshot with the specified data and size.
    ///
    /// @param[in]  p_data  The screenshot data
    /// @param[in]  p_size  The screenshot size.
    ///
    Screenshot(sk_sp<SkData> p_data, SkISize p_size);

    //--------------------------------------------------------------------------
    /// @brief      The copy constructor for a screenshot.
    ///
    /// @param[in]  other  The screenshot to copy from.
    ///
    Screenshot(const Screenshot& other);

    //--------------------------------------------------------------------------
    /// @brief      Destroys the screenshot object and releases underlying data.
    ///
    ~Screenshot();
  };

  //----------------------------------------------------------------------------
  /// @brief      Screenshots the last layer tree to one of the supported
  ///             screenshot types and optionally Base 64 encodes that data for
  ///             easier transmission and packaging (usually over the service
  ///             protocol for instrumentation tools running on the host).
  ///
  /// @param[in]  type           The type of the screenshot to gather.
  /// @param[in]  base64_encode  Whether Base 64 encoding must be applied to the
  ///                            data after a screenshot has been captured.
  ///
  /// @return     A non-empty screenshot if one could be captured. A screenshot
  ///             capture may fail if there were no layer trees previously
  ///             rendered by this rasterizer, or, due to an unspecified
  ///             internal error. Internal error will be logged to the console.
  ///
  Screenshot ScreenshotLastLayerTree(ScreenshotType type, bool base64_encode);

  //----------------------------------------------------------------------------
  /// @brief      Sets a callback that will be executed when the next layer tree
  ///             in rendered to the on-screen surface. This is used by
  ///             embedders to listen for one time operations like listening for
  ///             when the first frame is rendered so that they may hide splash
  ///             screens.
  ///
  ///             The callback is only executed once and dropped on the GPU
  ///             thread when executed (lambda captures must be able to deal
  ///             with the threading repercussions of this behavior).
  ///
  /// @param[in]  callback  The callback to execute when the next layer tree is
  ///                       rendered on-screen.
  ///
  void SetNextFrameCallback(const fml::closure& callback);

  //----------------------------------------------------------------------------
  /// @brief Set the External View Embedder. This is done on shell
  ///        initialization. This is non-null on platforms that support
  ///        embedding externally composited views.
  ///
  /// @param[in] view_embedder The external view embedder object.
  ///
  void SetExternalViewEmbedder(
      const std::shared_ptr<ExternalViewEmbedder>& view_embedder);

  //----------------------------------------------------------------------------
  /// @brief Set the snapshot surface producer. This is done on shell
  ///        initialization. This is non-null on platforms that support taking
  ///        GPU accelerated raster snapshots in the background.
  ///
  /// @param[in]  producer  A surface producer for raster snapshotting when the
  ///                       onscreen surface is not available.
  ///
  void SetSnapshotSurfaceProducer(
      std::unique_ptr<SnapshotSurfaceProducer> producer);

  //----------------------------------------------------------------------------
  /// @brief      Returns a pointer to the compositor context used by this
  ///             rasterizer. This pointer will never be `nullptr`.
  ///
  /// @return     The compositor context used by this rasterizer.
  ///
  flutter::CompositorContext* compositor_context() {
    return compositor_context_.get();
  }

  //----------------------------------------------------------------------------
  /// @brief      Returns the raster thread merger used by this rasterizer.
  ///             This may be `nullptr`.
  ///
  /// @return     The raster thread merger used by this rasterizer.
  ///
  fml::RefPtr<fml::RasterThreadMerger> GetRasterThreadMerger();

  //----------------------------------------------------------------------------
  /// @brief      Skia has no notion of time. To work around the performance
  ///             implications of this, it may cache GPU resources to reference
  ///             them from one frame to the next. Using this call, embedders
  ///             may set the maximum bytes cached by Skia in its caches
  ///             dedicated to on-screen rendering.
  ///
  /// @attention  This cache setting will be invalidated when the surface is
  ///             torn down via `Rasterizer::Teardown`. This call must be made
  ///             again with new limits after surface re-acquisition.
  ///
  /// @attention  This cache does not describe the entirety of GPU resources
  ///             that may be cached. The `RasterCache` also holds very large
  ///             GPU resources.
  ///
  /// @see        `RasterCache`
  ///
  /// @param[in]  max_bytes  The maximum byte size of resource that may be
  ///                        cached for GPU rendering.
  /// @param[in]  from_user  Whether this request was from user code, e.g. via
  ///                        the flutter/skia message channel, in which case
  ///                        it should not be overridden by the platform.
  ///
  void SetResourceCacheMaxBytes(size_t max_bytes, bool from_user);

  //----------------------------------------------------------------------------
  /// @brief      The current value of Skia's resource cache size, if a surface
  ///             is present.
  ///
  /// @attention  This cache does not describe the entirety of GPU resources
  ///             that may be cached. The `RasterCache` also holds very large
  ///             GPU resources.
  ///
  /// @see        `RasterCache`
  ///
  /// @return     The size of Skia's resource cache, if available.
  ///
  std::optional<size_t> GetResourceCacheMaxBytes() const;

  //----------------------------------------------------------------------------
  /// @brief      Enables the thread merger if the external view embedder
  ///             supports dynamic thread merging.
  ///
  /// @attention  This method is thread-safe. When the thread merger is enabled,
  ///             the raster task queue can run in the platform thread at any
  ///             time.
  ///
  /// @see        `ExternalViewEmbedder`
  ///
  void EnableThreadMergerIfNeeded();

  //----------------------------------------------------------------------------
  /// @brief      Disables the thread merger if the external view embedder
  ///             supports dynamic thread merging.
  ///
  /// @attention  This method is thread-safe. When the thread merger is
  ///             disabled, the raster task queue will continue to run in the
  ///             same thread until |EnableThreadMergerIfNeeded| is called.
  ///
  /// @see        `ExternalViewEmbedder`
  ///
  void DisableThreadMergerIfNeeded();

 private:
  // |SnapshotDelegate|
  std::pair<sk_sp<SkImage>, std::string> MakeGpuImage(
      sk_sp<DisplayList> display_list,
      SkISize picture_size) override;

  // |SnapshotDelegate|
  sk_sp<SkImage> MakeRasterSnapshot(
      std::function<void(SkCanvas*)> draw_callback,
      SkISize picture_size) override;

  // |SnapshotDelegate|
  sk_sp<SkImage> MakeRasterSnapshot(sk_sp<SkPicture> picture,
                                    SkISize picture_size) override;

  // |SnapshotDelegate|
  sk_sp<SkImage> ConvertToRasterImage(sk_sp<SkImage> image) override;

  // |Stopwatch::Delegate|
  /// Time limit for a smooth frame.
  ///
  /// See: `DisplayManager::GetMainDisplayRefreshRate`.
  fml::Milliseconds GetFrameBudget() const override;

  sk_sp<SkData> ScreenshotLayerTreeAsImage(
      flutter::LayerTree* tree,
      flutter::CompositorContext& compositor_context,
      GrDirectContext* surface_context,
      bool compressed);

  sk_sp<SkImage> DoMakeRasterSnapshot(
      SkISize size,
      std::function<void(SkCanvas*)> draw_callback);

  RasterStatus DoDraw(
      std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder,
      std::unique_ptr<flutter::LayerTree> layer_tree);

  RasterStatus DrawToSurface(FrameTimingsRecorder& frame_timings_recorder,
                             flutter::LayerTree& layer_tree);

  RasterStatus DrawToSurfaceUnsafe(FrameTimingsRecorder& frame_timings_recorder,
                                   flutter::LayerTree& layer_tree);

  void FireNextFrameCallbackIfPresent();

  static bool NoDiscard(const flutter::LayerTree& layer_tree) { return false; }
  static bool ShouldResubmitFrame(const RasterStatus& raster_status);

  Delegate& delegate_;
  MakeGpuImageBehavior gpu_image_behavior_;
  std::unique_ptr<Surface> surface_;
  std::unique_ptr<SnapshotSurfaceProducer> snapshot_surface_producer_;
  std::unique_ptr<flutter::CompositorContext> compositor_context_;
  // This is the last successfully rasterized layer tree.
  std::unique_ptr<flutter::LayerTree> last_layer_tree_;
  // Set when we need attempt to rasterize the layer tree again. This layer_tree
  // has not successfully rasterized. This can happen due to the change in the
  // thread configuration. This will be inserted to the front of the pipeline.
  std::unique_ptr<flutter::LayerTree> resubmitted_layer_tree_;
  std::unique_ptr<FrameTimingsRecorder> resubmitted_recorder_;
  fml::closure next_frame_callback_;
  bool user_override_resource_cache_bytes_;
  std::optional<size_t> max_cache_bytes_;
  fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger_;
  std::shared_ptr<ExternalViewEmbedder> external_view_embedder_;

  // WeakPtrFactory must be the last member.
  fml::TaskRunnerAffineWeakPtrFactory<Rasterizer> weak_factory_;
  FML_DISALLOW_COPY_AND_ASSIGN(Rasterizer);
};

}  // namespace flutter

#endif  // SHELL_COMMON_RASTERIZER_H_
