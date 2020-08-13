// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// FLUTTER_NOLINT

#include "flutter/shell/common/rasterizer.h"

#include <utility>

#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/shell/common/persistent_cache.h"
#include "flutter/shell/common/serialization_callbacks.h"
#include "third_party/skia/include/core/SkEncodedImageFormat.h"
#include "third_party/skia/include/core/SkImageEncoder.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkSerialProcs.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/core/SkSurfaceCharacterization.h"
#include "third_party/skia/include/utils/SkBase64.h"

namespace flutter {

// The rasterizer will tell Skia to purge cached resources that have not been
// used within this interval.
static constexpr std::chrono::milliseconds kSkiaCleanupExpiration(15000);

Rasterizer::Rasterizer(Delegate& delegate)
    : Rasterizer(delegate,
                 std::make_unique<flutter::CompositorContext>(
                     delegate.GetFrameBudget())) {}

Rasterizer::Rasterizer(
    Delegate& delegate,
    std::unique_ptr<flutter::CompositorContext> compositor_context)
    : delegate_(delegate),
      compositor_context_(std::move(compositor_context)),
      user_override_resource_cache_bytes_(false),
      weak_factory_(this) {
  FML_DCHECK(compositor_context_);
}

Rasterizer::~Rasterizer() = default;

fml::TaskRunnerAffineWeakPtr<Rasterizer> Rasterizer::GetWeakPtr() const {
  return weak_factory_.GetWeakPtr();
}

fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> Rasterizer::GetSnapshotDelegate()
    const {
  return weak_factory_.GetWeakPtr();
}

void Rasterizer::Setup(std::unique_ptr<Surface> surface) {
  surface_ = std::move(surface);
  if (max_cache_bytes_.has_value()) {
    SetResourceCacheMaxBytes(max_cache_bytes_.value(),
                             user_override_resource_cache_bytes_);
  }
  compositor_context_->OnGrContextCreated();
#if !defined(OS_FUCHSIA)
  // TODO(sanjayc77): https://github.com/flutter/flutter/issues/53179. Add
  // support for raster thread merger for Fuchsia.
  if (surface_->GetExternalViewEmbedder()) {
    const auto platform_id =
        delegate_.GetTaskRunners().GetPlatformTaskRunner()->GetTaskQueueId();
    const auto gpu_id =
        delegate_.GetTaskRunners().GetRasterTaskRunner()->GetTaskQueueId();
    raster_thread_merger_ =
        fml::MakeRefCounted<fml::RasterThreadMerger>(platform_id, gpu_id);
  }
#endif
}

void Rasterizer::Teardown() {
  compositor_context_->OnGrContextDestroyed();
  surface_.reset();
  last_layer_tree_.reset();
}

void Rasterizer::NotifyLowMemoryWarning() const {
  if (!surface_) {
    FML_DLOG(INFO)
        << "Rasterizer::NotifyLowMemoryWarning called with no surface.";
    return;
  }
  auto context = surface_->GetContext();
  if (!context) {
    FML_DLOG(INFO)
        << "Rasterizer::NotifyLowMemoryWarning called with no GrContext.";
    return;
  }
  context->performDeferredCleanup(std::chrono::milliseconds(0));
}

flutter::TextureRegistry* Rasterizer::GetTextureRegistry() {
  return &compositor_context_->texture_registry();
}

flutter::LayerTree* Rasterizer::GetLastLayerTree() {
  return last_layer_tree_.get();
}

void Rasterizer::DrawLastLayerTree() {
  if (!last_layer_tree_ || !surface_) {
    return;
  }
  DrawToSurface(*last_layer_tree_);
}

void Rasterizer::Draw(fml::RefPtr<Pipeline<flutter::LayerTree>> pipeline) {
  TRACE_EVENT0("flutter", "GPURasterizer::Draw");
  if (raster_thread_merger_ &&
      !raster_thread_merger_->IsOnRasterizingThread()) {
    // we yield and let this frame be serviced on the right thread.
    return;
  }
  FML_DCHECK(delegate_.GetTaskRunners()
                 .GetRasterTaskRunner()
                 ->RunsTasksOnCurrentThread());

  RasterStatus raster_status = RasterStatus::kFailed;
  Pipeline<flutter::LayerTree>::Consumer consumer =
      [&](std::unique_ptr<LayerTree> layer_tree) {
        raster_status = DoDraw(std::move(layer_tree));
      };

  PipelineConsumeResult consume_result = pipeline->Consume(consumer);
  // if the raster status is to resubmit the frame, we push the frame to the
  // front of the queue and also change the consume status to more available.
  if (raster_status == RasterStatus::kResubmit) {
    auto front_continuation = pipeline->ProduceIfEmpty();
    bool result =
        front_continuation.Complete(std::move(resubmitted_layer_tree_));
    if (result) {
      consume_result = PipelineConsumeResult::MoreAvailable;
    }
  } else if (raster_status == RasterStatus::kEnqueuePipeline) {
    consume_result = PipelineConsumeResult::MoreAvailable;
  }

  // Merging the thread as we know the next `Draw` should be run on the platform
  // thread.
  if (surface_ != nullptr && surface_->GetExternalViewEmbedder() != nullptr) {
    auto should_resubmit_frame = raster_status == RasterStatus::kResubmit;
    surface_->GetExternalViewEmbedder()->EndFrame(should_resubmit_frame,
                                                  raster_thread_merger_);
  }

  // Consume as many pipeline items as possible. But yield the event loop
  // between successive tries.
  switch (consume_result) {
    case PipelineConsumeResult::MoreAvailable: {
      delegate_.GetTaskRunners().GetRasterTaskRunner()->PostTask(
          [weak_this = weak_factory_.GetWeakPtr(), pipeline]() {
            if (weak_this) {
              weak_this->Draw(pipeline);
            }
          });
      break;
    }
    default:
      break;
  }
}

namespace {
sk_sp<SkImage> DrawSnapshot(
    sk_sp<SkSurface> surface,
    const std::function<void(SkCanvas*)>& draw_callback) {
  if (surface == nullptr || surface->getCanvas() == nullptr) {
    return nullptr;
  }

  draw_callback(surface->getCanvas());
  surface->getCanvas()->flush();

  sk_sp<SkImage> device_snapshot;
  {
    TRACE_EVENT0("flutter", "MakeDeviceSnpashot");
    device_snapshot = surface->makeImageSnapshot();
  }

  if (device_snapshot == nullptr) {
    return nullptr;
  }

  {
    TRACE_EVENT0("flutter", "DeviceHostTransfer");
    if (auto raster_image = device_snapshot->makeRasterImage()) {
      return raster_image;
    }
  }

  return nullptr;
}
}  // namespace

sk_sp<SkImage> Rasterizer::DoMakeRasterSnapshot(
    SkISize size,
    std::function<void(SkCanvas*)> draw_callback) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  sk_sp<SkImage> result;
  SkImageInfo image_info = SkImageInfo::MakeN32Premul(
      size.width(), size.height(), SkColorSpace::MakeSRGB());
  if (surface_ == nullptr || surface_->GetContext() == nullptr) {
    // Raster surface is fine if there is no on screen surface. This might
    // happen in case of software rendering.
    sk_sp<SkSurface> surface = SkSurface::MakeRaster(image_info);
    result = DrawSnapshot(surface, draw_callback);
  } else {
    delegate_.GetIsGpuDisabledSyncSwitch()->Execute(
        fml::SyncSwitch::Handlers()
            .SetIfTrue([&] {
              sk_sp<SkSurface> surface = SkSurface::MakeRaster(image_info);
              result = DrawSnapshot(surface, draw_callback);
            })
            .SetIfFalse([&] {
              auto context_switch = surface_->MakeRenderContextCurrent();
              if (!context_switch->GetResult()) {
                return;
              }

              // When there is an on screen surface, we need a render target
              // SkSurface because we want to access texture backed images.
              sk_sp<SkSurface> surface = SkSurface::MakeRenderTarget(
                  surface_->GetContext(),  // context
                  SkBudgeted::kNo,         // budgeted
                  image_info               // image info
              );
              result = DrawSnapshot(surface, draw_callback);
            }));
  }

  return result;
}

sk_sp<SkImage> Rasterizer::MakeRasterSnapshot(sk_sp<SkPicture> picture,
                                              SkISize picture_size) {
  return DoMakeRasterSnapshot(picture_size,
                              [picture = std::move(picture)](SkCanvas* canvas) {
                                canvas->drawPicture(picture);
                              });
}

sk_sp<SkImage> Rasterizer::ConvertToRasterImage(sk_sp<SkImage> image) {
  TRACE_EVENT0("flutter", __FUNCTION__);

  // If the rasterizer does not have a surface with a GrContext, then it will
  // be unable to render a cross-context SkImage.  The caller will need to
  // create the raster image on the IO thread.
  if (surface_ == nullptr || surface_->GetContext() == nullptr) {
    return nullptr;
  }

  if (image == nullptr) {
    return nullptr;
  }

  return DoMakeRasterSnapshot(image->dimensions(),
                              [image = std::move(image)](SkCanvas* canvas) {
                                canvas->drawImage(image, 0, 0);
                              });
}

RasterStatus Rasterizer::DoDraw(
    std::unique_ptr<flutter::LayerTree> layer_tree) {
  FML_DCHECK(delegate_.GetTaskRunners()
                 .GetRasterTaskRunner()
                 ->RunsTasksOnCurrentThread());

  if (!layer_tree || !surface_) {
    return RasterStatus::kFailed;
  }

  FrameTiming timing;
#if !defined(OS_FUCHSIA)
  const fml::TimePoint frame_target_time = layer_tree->target_time();
#endif
  timing.Set(FrameTiming::kVsyncStart, layer_tree->vsync_start());
  timing.Set(FrameTiming::kBuildStart, layer_tree->build_start());
  timing.Set(FrameTiming::kBuildFinish, layer_tree->build_finish());
  timing.Set(FrameTiming::kRasterStart, fml::TimePoint::Now());

  PersistentCache* persistent_cache = PersistentCache::GetCacheForProcess();
  persistent_cache->ResetStoredNewShaders();

  RasterStatus raster_status = DrawToSurface(*layer_tree);
  if (raster_status == RasterStatus::kSuccess) {
    last_layer_tree_ = std::move(layer_tree);
  } else if (raster_status == RasterStatus::kResubmit) {
    resubmitted_layer_tree_ = std::move(layer_tree);
    return raster_status;
  }

  if (persistent_cache->IsDumpingSkp() &&
      persistent_cache->StoredNewShaders()) {
    auto screenshot =
        ScreenshotLastLayerTree(ScreenshotType::SkiaPicture, false);
    persistent_cache->DumpSkp(*screenshot.data);
  }

  // TODO(liyuqian): in Fuchsia, the rasterization doesn't finish when
  // Rasterizer::DoDraw finishes. Future work is needed to adapt the timestamp
  // for Fuchsia to capture SceneUpdateContext::ExecutePaintTasks.
  const auto raster_finish_time = fml::TimePoint::Now();
  timing.Set(FrameTiming::kRasterFinish, raster_finish_time);
  delegate_.OnFrameRasterized(timing);

// SceneDisplayLag events are disabled on Fuchsia.
// see: https://github.com/flutter/flutter/issues/56598
#if !defined(OS_FUCHSIA)
  if (raster_finish_time > frame_target_time) {
    fml::TimePoint latest_frame_target_time =
        delegate_.GetLatestFrameTargetTime();
    const auto frame_budget_millis = delegate_.GetFrameBudget().count();
    if (latest_frame_target_time < raster_finish_time) {
      latest_frame_target_time =
          latest_frame_target_time +
          fml::TimeDelta::FromMillisecondsF(frame_budget_millis);
    }
    const auto frame_lag =
        (latest_frame_target_time - frame_target_time).ToMillisecondsF();
    const int vsync_transitions_missed = round(frame_lag / frame_budget_millis);
    fml::tracing::TraceEventAsyncComplete(
        "flutter",                    // category
        "SceneDisplayLag",            // name
        raster_finish_time,           // begin_time
        latest_frame_target_time,     // end_time
        "frame_target_time",          // arg_key_1
        frame_target_time,            // arg_val_1
        "current_frame_target_time",  // arg_key_2
        latest_frame_target_time,     // arg_val_2
        "vsync_transitions_missed",   // arg_key_3
        vsync_transitions_missed      // arg_val_3
    );
  }
#endif

  // Pipeline pressure is applied from a couple of places:
  // rasterizer: When there are more items as of the time of Consume.
  // animator (via shell): Frame gets produces every vsync.
  // Enqueing here is to account for the following scenario:
  // T = 1
  //  - one item (A) in the pipeline
  //  - rasterizer starts (and merges the threads)
  //  - pipeline consume result says no items to process
  // T = 2
  //  - animator produces (B) to the pipeline
  //  - applies pipeline pressure via platform thread.
  // T = 3
  //   - rasterizes finished (and un-merges the threads)
  //   - |Draw| for B yields as its on the wrong thread.
  // This enqueue ensures that we attempt to consume from the right
  // thread one more time after un-merge.
  if (raster_thread_merger_) {
    if (raster_thread_merger_->DecrementLease() ==
        fml::RasterThreadStatus::kUnmergedNow) {
      return RasterStatus::kEnqueuePipeline;
    }
  }

  return raster_status;
}

RasterStatus Rasterizer::DrawToSurface(flutter::LayerTree& layer_tree) {
  TRACE_EVENT0("flutter", "Rasterizer::DrawToSurface");
  FML_DCHECK(surface_);

  // There is no way for the compositor to know how long the layer tree
  // construction took. Fortunately, the layer tree does. Grab that time
  // for instrumentation.
  compositor_context_->ui_time().SetLapTime(layer_tree.build_time());

  auto* external_view_embedder = surface_->GetExternalViewEmbedder();

  SkCanvas* embedder_root_canvas = nullptr;
  if (external_view_embedder != nullptr) {
    external_view_embedder->BeginFrame(
        layer_tree.frame_size(), surface_->GetContext(),
        layer_tree.device_pixel_ratio(), raster_thread_merger_);
    embedder_root_canvas = external_view_embedder->GetRootCanvas();
  }

  // On Android, the external view embedder deletes surfaces in `BeginFrame`.
  //
  // Deleting a surface also clears the GL context. Therefore, acquire the
  // frame after calling `BeginFrame` as this operation resets the GL context.
  auto frame = surface_->AcquireFrame(layer_tree.frame_size());

  if (frame == nullptr) {
    return RasterStatus::kFailed;
  }

  // If the external view embedder has specified an optional root surface, the
  // root surface transformation is set by the embedder instead of
  // having to apply it here.
  SkMatrix root_surface_transformation =
      embedder_root_canvas ? SkMatrix{} : surface_->GetRootTransformation();

  auto root_surface_canvas =
      embedder_root_canvas ? embedder_root_canvas : frame->SkiaCanvas();

  auto compositor_frame = compositor_context_->AcquireFrame(
      surface_->GetContext(),       // skia GrContext
      root_surface_canvas,          // root surface canvas
      external_view_embedder,       // external view embedder
      root_surface_transformation,  // root surface transformation
      true,                         // instrumentation enabled
      frame->supports_readback(),   // surface supports pixel reads
      raster_thread_merger_         // thread merger
  );

  if (compositor_frame) {
    RasterStatus raster_status = compositor_frame->Raster(layer_tree, false);
    if (raster_status == RasterStatus::kFailed) {
      return raster_status;
    }
    if (external_view_embedder != nullptr) {
      FML_DCHECK(!frame->IsSubmitted());
      external_view_embedder->SubmitFrame(surface_->GetContext(),
                                          std::move(frame));
    } else {
      frame->Submit();
    }

    FireNextFrameCallbackIfPresent();

    if (surface_->GetContext()) {
      TRACE_EVENT0("flutter", "PerformDeferredSkiaCleanup");
      surface_->GetContext()->performDeferredCleanup(kSkiaCleanupExpiration);
    }

    return raster_status;
  }

  return RasterStatus::kFailed;
}

static sk_sp<SkData> ScreenshotLayerTreeAsPicture(
    flutter::LayerTree* tree,
    flutter::CompositorContext& compositor_context) {
  FML_DCHECK(tree != nullptr);
  SkPictureRecorder recorder;
  recorder.beginRecording(
      SkRect::MakeWH(tree->frame_size().width(), tree->frame_size().height()));

  SkMatrix root_surface_transformation;
  root_surface_transformation.reset();

#if defined(LEGACY_FUCHSIA_EMBEDDER)
  // TODO(arbreng: fxb/55805) Our ScopedFrame implementation doesnt do the
  // right thing here so initialize the base class directly. This wont be
  // needed after we move to using the embedder API on Fuchsia.
  auto frame = std::make_unique<flutter::CompositorContext::ScopedFrame>(
      compositor_context, nullptr, recorder.getRecordingCanvas(), nullptr,
      root_surface_transformation, false, true, nullptr);
#else
  // TODO(amirh): figure out how to take a screenshot with embedded UIView.
  // https://github.com/flutter/flutter/issues/23435
  auto frame = compositor_context.AcquireFrame(
      nullptr, recorder.getRecordingCanvas(), nullptr,
      root_surface_transformation, false, true, nullptr);
#endif  // defined(LEGACY_FUCHSIA_EMBEDDER)

  frame->Raster(*tree, true);

#if defined(OS_FUCHSIA)
  SkSerialProcs procs = {0};
  procs.fImageProc = SerializeImageWithoutData;
#else
  SkSerialProcs procs = {0};
  procs.fTypefaceProc = SerializeTypefaceWithData;
#endif

  return recorder.finishRecordingAsPicture()->serialize(&procs);
}

static sk_sp<SkSurface> CreateSnapshotSurface(GrDirectContext* surface_context,
                                              const SkISize& size) {
  const auto image_info = SkImageInfo::MakeN32Premul(
      size.width(), size.height(), SkColorSpace::MakeSRGB());
  if (surface_context) {
    // There is a rendering surface that may contain textures that are going to
    // be referenced in the layer tree about to be drawn.
    return SkSurface::MakeRenderTarget(surface_context,  //
                                       SkBudgeted::kNo,  //
                                       image_info        //
    );
  }

  // There is no rendering surface, assume no GPU textures are present and
  // create a raster surface.
  return SkSurface::MakeRaster(image_info);
}

sk_sp<SkData> Rasterizer::ScreenshotLayerTreeAsImage(
    flutter::LayerTree* tree,
    flutter::CompositorContext& compositor_context,
    GrDirectContext* surface_context,
    bool compressed) {
  // Attempt to create a snapshot surface depending on whether we have access to
  // a valid GPU rendering context.
  auto snapshot_surface =
      CreateSnapshotSurface(surface_context, tree->frame_size());
  if (snapshot_surface == nullptr) {
    FML_LOG(ERROR) << "Screenshot: unable to create snapshot surface";
    return nullptr;
  }

  // Draw the current layer tree into the snapshot surface.
  auto* canvas = snapshot_surface->getCanvas();

  // There is no root surface transformation for the screenshot layer. Reset the
  // matrix to identity.
  SkMatrix root_surface_transformation;
  root_surface_transformation.reset();

  // We want to ensure we call the base method for
  // CompositorContext::AcquireFrame instead of the platform-specific method.
  // Specifically, Fuchsia's CompositorContext handles the rendering surface
  // itself which means that we will still continue to render to the onscreen
  // surface if we don't call the base method.
  auto frame = compositor_context.flutter::CompositorContext::AcquireFrame(
      surface_context, canvas, nullptr, root_surface_transformation, false,
      true, nullptr);
  canvas->clear(SK_ColorTRANSPARENT);
  frame->Raster(*tree, true);
  canvas->flush();

  // snapshot_surface->makeImageSnapshot needs the GL context to be set if the
  // render context is GL. frame->Raster() pops the gl context in platforms that
  // gl context switching are used. (For example, older iOS that uses GL) We
  // reset the GL context using the context switch.
  auto context_switch = surface_->MakeRenderContextCurrent();
  if (!context_switch->GetResult()) {
    FML_LOG(ERROR) << "Screenshot: unable to make image screenshot";
    return nullptr;
  }
  // Prepare an image from the surface, this image may potentially be on th GPU.
  auto potentially_gpu_snapshot = snapshot_surface->makeImageSnapshot();
  if (!potentially_gpu_snapshot) {
    FML_LOG(ERROR) << "Screenshot: unable to make image screenshot";
    return nullptr;
  }

  // Copy the GPU image snapshot into CPU memory.
  auto cpu_snapshot = potentially_gpu_snapshot->makeRasterImage();
  if (!cpu_snapshot) {
    FML_LOG(ERROR) << "Screenshot: unable to make raster image";
    return nullptr;
  }

  // If the caller want the pixels to be compressed, there is a Skia utility to
  // compress to PNG. Use that.
  if (compressed) {
    return cpu_snapshot->encodeToData();
  }

  // Copy it into a bitmap and return the same.
  SkPixmap pixmap;
  if (!cpu_snapshot->peekPixels(&pixmap)) {
    FML_LOG(ERROR) << "Screenshot: unable to obtain bitmap pixels";
    return nullptr;
  }
  return SkData::MakeWithCopy(pixmap.addr32(), pixmap.computeByteSize());
}

Rasterizer::Screenshot Rasterizer::ScreenshotLastLayerTree(
    Rasterizer::ScreenshotType type,
    bool base64_encode) {
  auto* layer_tree = GetLastLayerTree();
  if (layer_tree == nullptr) {
    FML_LOG(ERROR) << "Last layer tree was null when screenshotting.";
    return {};
  }

  sk_sp<SkData> data = nullptr;

  GrDirectContext* surface_context =
      surface_ ? surface_->GetContext() : nullptr;

  switch (type) {
    case ScreenshotType::SkiaPicture:
      data = ScreenshotLayerTreeAsPicture(layer_tree, *compositor_context_);
      break;
    case ScreenshotType::UncompressedImage:
      data = ScreenshotLayerTreeAsImage(layer_tree, *compositor_context_,
                                        surface_context, false);
      break;
    case ScreenshotType::CompressedImage:
      data = ScreenshotLayerTreeAsImage(layer_tree, *compositor_context_,
                                        surface_context, true);
      break;
  }

  if (data == nullptr) {
    FML_LOG(ERROR) << "Screenshot data was null.";
    return {};
  }

  if (base64_encode) {
    size_t b64_size = SkBase64::Encode(data->data(), data->size(), nullptr);
    auto b64_data = SkData::MakeUninitialized(b64_size);
    SkBase64::Encode(data->data(), data->size(), b64_data->writable_data());
    return Rasterizer::Screenshot{b64_data, layer_tree->frame_size()};
  }

  return Rasterizer::Screenshot{data, layer_tree->frame_size()};
}

void Rasterizer::SetNextFrameCallback(const fml::closure& callback) {
  next_frame_callback_ = callback;
}

void Rasterizer::FireNextFrameCallbackIfPresent() {
  if (!next_frame_callback_) {
    return;
  }
  // It is safe for the callback to set a new callback.
  auto callback = next_frame_callback_;
  next_frame_callback_ = nullptr;
  callback();
}

void Rasterizer::SetResourceCacheMaxBytes(size_t max_bytes, bool from_user) {
  user_override_resource_cache_bytes_ |= from_user;

  if (!from_user && user_override_resource_cache_bytes_) {
    // We should not update the setting here if a user has explicitly set a
    // value for this over the flutter/skia channel.
    return;
  }

  max_cache_bytes_ = max_bytes;
  if (!surface_) {
    return;
  }

  GrDirectContext* context = surface_->GetContext();
  if (context) {
    int max_resources;
    context->getResourceCacheLimits(&max_resources, nullptr);
    context->setResourceCacheLimits(max_resources, max_bytes);
  }
}

std::optional<size_t> Rasterizer::GetResourceCacheMaxBytes() const {
  if (!surface_) {
    return std::nullopt;
  }
  GrDirectContext* context = surface_->GetContext();
  if (context) {
    size_t max_bytes;
    context->getResourceCacheLimits(nullptr, &max_bytes);
    return max_bytes;
  }
  return std::nullopt;
}

Rasterizer::Screenshot::Screenshot() {}

Rasterizer::Screenshot::Screenshot(sk_sp<SkData> p_data, SkISize p_size)
    : data(std::move(p_data)), frame_size(p_size) {}

Rasterizer::Screenshot::Screenshot(const Screenshot& other) = default;

Rasterizer::Screenshot::~Screenshot() = default;

}  // namespace flutter
