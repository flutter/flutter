// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/rasterizer.h"

#include <algorithm>
#include <memory>
#include <utility>

#include "flow/frame_timings.h"
#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/flow/layers/offscreen_surface.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/shell/common/serialization_callbacks.h"
#include "fml/make_copyable.h"
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

Rasterizer::Rasterizer(Delegate& delegate,
                       MakeGpuImageBehavior gpu_image_behavior)
    : delegate_(delegate),
      gpu_image_behavior_(gpu_image_behavior),
      compositor_context_(std::make_unique<flutter::CompositorContext>(*this)),
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

  auto context_switch = surface_->MakeRenderContextCurrent();
  if (context_switch->GetResult()) {
    compositor_context_->OnGrContextCreated();
  }

  if (external_view_embedder_ &&
      external_view_embedder_->SupportsDynamicThreadMerging() &&
      !raster_thread_merger_) {
    const auto platform_id =
        delegate_.GetTaskRunners().GetPlatformTaskRunner()->GetTaskQueueId();
    const auto gpu_id =
        delegate_.GetTaskRunners().GetRasterTaskRunner()->GetTaskQueueId();
    raster_thread_merger_ = fml::RasterThreadMerger::CreateOrShareThreadMerger(
        delegate_.GetParentRasterThreadMerger(), platform_id, gpu_id);
  }
  if (raster_thread_merger_) {
    raster_thread_merger_->SetMergeUnmergeCallback([=]() {
      // Clear the GL context after the thread configuration has changed.
      if (surface_) {
        surface_->ClearRenderContext();
      }
    });
  }
}

void Rasterizer::TeardownExternalViewEmbedder() {
  if (external_view_embedder_) {
    external_view_embedder_->Teardown();
  }
}

void Rasterizer::Teardown() {
  if (surface_) {
    auto context_switch = surface_->MakeRenderContextCurrent();
    if (context_switch->GetResult()) {
      compositor_context_->OnGrContextDestroyed();
      if (auto* context = surface_->GetContext()) {
        context->purgeUnlockedResources(/*scratchResourcesOnly=*/false);
      }
    }
    surface_.reset();
  }

  last_layer_tree_.reset();

  if (raster_thread_merger_.get() != nullptr &&
      raster_thread_merger_.get()->IsMerged()) {
    FML_DCHECK(raster_thread_merger_->IsEnabled());
    raster_thread_merger_->UnMergeNowIfLastOne();
    raster_thread_merger_->SetMergeUnmergeCallback(nullptr);
  }
}

void Rasterizer::EnableThreadMergerIfNeeded() {
  if (raster_thread_merger_) {
    raster_thread_merger_->Enable();
  }
}

void Rasterizer::DisableThreadMergerIfNeeded() {
  if (raster_thread_merger_) {
    raster_thread_merger_->Disable();
  }
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
  auto context_switch = surface_->MakeRenderContextCurrent();
  if (!context_switch->GetResult()) {
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

void Rasterizer::DrawLastLayerTree(
    std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder) {
  if (!last_layer_tree_ || !surface_) {
    return;
  }
  RasterStatus raster_status =
      DrawToSurface(*frame_timings_recorder, *last_layer_tree_);

  // EndFrame should perform cleanups for the external_view_embedder.
  if (external_view_embedder_ && external_view_embedder_->GetUsedThisFrame()) {
    bool should_resubmit_frame = ShouldResubmitFrame(raster_status);
    external_view_embedder_->SetUsedThisFrame(false);
    external_view_embedder_->EndFrame(should_resubmit_frame,
                                      raster_thread_merger_);
  }
}

RasterStatus Rasterizer::Draw(std::shared_ptr<LayerTreePipeline> pipeline,
                              LayerTreeDiscardCallback discard_callback) {
  TRACE_EVENT0("flutter", "GPURasterizer::Draw");
  if (raster_thread_merger_ &&
      !raster_thread_merger_->IsOnRasterizingThread()) {
    // we yield and let this frame be serviced on the right thread.
    return RasterStatus::kYielded;
  }
  FML_DCHECK(delegate_.GetTaskRunners()
                 .GetRasterTaskRunner()
                 ->RunsTasksOnCurrentThread());

  RasterStatus raster_status = RasterStatus::kFailed;
  LayerTreePipeline::Consumer consumer =
      [&](std::unique_ptr<LayerTreeItem> item) {
        std::unique_ptr<LayerTree> layer_tree = std::move(item->layer_tree);
        std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder =
            std::move(item->frame_timings_recorder);
        if (discard_callback(*layer_tree.get())) {
          raster_status = RasterStatus::kDiscarded;
        } else {
          raster_status =
              DoDraw(std::move(frame_timings_recorder), std::move(layer_tree));
        }
      };

  PipelineConsumeResult consume_result = pipeline->Consume(consumer);
  if (consume_result == PipelineConsumeResult::NoneAvailable) {
    return RasterStatus::kFailed;
  }
  // if the raster status is to resubmit the frame, we push the frame to the
  // front of the queue and also change the consume status to more available.

  bool should_resubmit_frame = ShouldResubmitFrame(raster_status);
  if (should_resubmit_frame) {
    auto resubmitted_layer_tree_item = std::make_unique<LayerTreeItem>(
        std::move(resubmitted_layer_tree_), std::move(resubmitted_recorder_));
    auto front_continuation = pipeline->ProduceIfEmpty();
    PipelineProduceResult result =
        front_continuation.Complete(std::move(resubmitted_layer_tree_item));
    if (result.success) {
      consume_result = PipelineConsumeResult::MoreAvailable;
    }
  } else if (raster_status == RasterStatus::kEnqueuePipeline) {
    consume_result = PipelineConsumeResult::MoreAvailable;
  }

  // EndFrame should perform cleanups for the external_view_embedder.
  if (surface_ && external_view_embedder_ &&
      external_view_embedder_->GetUsedThisFrame()) {
    external_view_embedder_->SetUsedThisFrame(false);
    external_view_embedder_->EndFrame(should_resubmit_frame,
                                      raster_thread_merger_);
  }

  // Consume as many pipeline items as possible. But yield the event loop
  // between successive tries.
  switch (consume_result) {
    case PipelineConsumeResult::MoreAvailable: {
      delegate_.GetTaskRunners().GetRasterTaskRunner()->PostTask(
          fml::MakeCopyable(
              [weak_this = weak_factory_.GetWeakPtr(), pipeline,
               discard_callback = std::move(discard_callback)]() mutable {
                if (weak_this) {
                  weak_this->Draw(pipeline, std::move(discard_callback));
                }
              }));
      break;
    }
    default:
      break;
  }

  return raster_status;
}

bool Rasterizer::ShouldResubmitFrame(const RasterStatus& raster_status) {
  return raster_status == RasterStatus::kResubmit ||
         raster_status == RasterStatus::kSkipAndRetry;
}

namespace {
std::pair<sk_sp<SkImage>, std::string> MakeBitmapImage(
    sk_sp<DisplayList> display_list,
    const SkImageInfo& image_info) {
  FML_DCHECK(display_list);
  // Use 16384 as a proxy for the maximum texture size for a GPU image.
  // This is meant to be large enough to avoid false positives in test contexts,
  // but not so artificially large to be completely unrealistic on any platform.
  // This limit is taken from the Metal specification. D3D, Vulkan, and GL
  // generally have lower limits.
  if (image_info.width() > 16384 || image_info.height() > 16384) {
    return {nullptr, "unable to create render target at specified size"};
  }

  sk_sp<SkSurface> surface = SkSurface::MakeRaster(image_info);
  SkCanvas* canvas = surface->getCanvas();
  canvas->clear(SK_ColorTRANSPARENT);
  display_list->RenderTo(canvas);

  sk_sp<SkImage> image = surface->makeImageSnapshot();
  return {image, image ? "" : "Unable to create image"};
}
}  // namespace

std::pair<sk_sp<SkImage>, std::string> Rasterizer::MakeGpuImage(
    sk_sp<DisplayList> display_list,
    SkISize picture_size) {
  TRACE_EVENT0("flutter", "Rasterizer::MakeGpuImage");
  FML_DCHECK(display_list);

  const SkImageInfo image_info = SkImageInfo::MakeN32Premul(picture_size);
  std::pair<sk_sp<SkImage>, std::string> result;
  delegate_.GetIsGpuDisabledSyncSwitch()->Execute(
      fml::SyncSwitch::Handlers()
          .SetIfTrue([&result, &image_info, &display_list] {
            result = MakeBitmapImage(std::move(display_list), image_info);
          })
          .SetIfFalse([&result, &image_info, &display_list,
                       surface = surface_.get(),
                       gpu_image_behavior = gpu_image_behavior_] {
            if (!surface ||
                gpu_image_behavior == MakeGpuImageBehavior::kBitmap) {
              result = MakeBitmapImage(std::move(display_list), image_info);
              return;
            }

            auto* context = surface->GetContext();
            if (!context) {
              result = MakeBitmapImage(std::move(display_list), image_info);
              return;
            }

            sk_sp<SkSurface> sk_surface = SkSurface::MakeRenderTarget(
                context, SkBudgeted::kYes, image_info);
            if (!sk_surface) {
              result = {nullptr,
                        "unable to create render target at specified size"};
              return;
            }

            SkCanvas* canvas = sk_surface->getCanvas();
            canvas->clear(SK_ColorTRANSPARENT);
            display_list->RenderTo(canvas);

            sk_sp<SkImage> image = sk_surface->makeImageSnapshot();
            result = {image, image ? "" : "Unable to create image"};
          }));
  return result;
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

  std::unique_ptr<Surface> pbuffer_surface;
  Surface* snapshot_surface = nullptr;
  if (surface_ && surface_->GetContext()) {
    snapshot_surface = surface_.get();
  } else if (snapshot_surface_producer_) {
    pbuffer_surface = snapshot_surface_producer_->CreateSnapshotSurface();
    if (pbuffer_surface && pbuffer_surface->GetContext()) {
      snapshot_surface = pbuffer_surface.get();
    }
  }

  if (!snapshot_surface) {
    // Raster surface is fine if there is no on screen surface. This might
    // happen in case of software rendering.
    sk_sp<SkSurface> sk_surface = SkSurface::MakeRaster(image_info);
    result = DrawSnapshot(sk_surface, draw_callback);
  } else {
    delegate_.GetIsGpuDisabledSyncSwitch()->Execute(
        fml::SyncSwitch::Handlers()
            .SetIfTrue([&] {
              sk_sp<SkSurface> surface = SkSurface::MakeRaster(image_info);
              result = DrawSnapshot(surface, draw_callback);
            })
            .SetIfFalse([&] {
              FML_DCHECK(snapshot_surface);
              auto context_switch =
                  snapshot_surface->MakeRenderContextCurrent();
              if (!context_switch->GetResult()) {
                return;
              }

              GrRecordingContext* context = snapshot_surface->GetContext();
              auto max_size = context->maxRenderTargetSize();
              double scale_factor = std::min(
                  1.0, static_cast<double>(max_size) /
                           static_cast<double>(std::max(image_info.width(),
                                                        image_info.height())));

              // Scale down the render target size to the max supported by the
              // GPU if necessary. Exceeding the max would otherwise cause a
              // null result.
              if (scale_factor < 1.0) {
                image_info = image_info.makeWH(
                    static_cast<double>(image_info.width()) * scale_factor,
                    static_cast<double>(image_info.height()) * scale_factor);
              }

              // When there is an on screen surface, we need a render target
              // SkSurface because we want to access texture backed images.
              sk_sp<SkSurface> sk_surface =
                  SkSurface::MakeRenderTarget(context,          // context
                                              SkBudgeted::kNo,  // budgeted
                                              image_info        // image info
                  );
              if (!sk_surface) {
                FML_LOG(ERROR)
                    << "DoMakeRasterSnapshot can not create GPU render target";
                return;
              }

              sk_surface->getCanvas()->scale(scale_factor, scale_factor);
              result = DrawSnapshot(sk_surface, draw_callback);
            }));
  }

  return result;
}

sk_sp<SkImage> Rasterizer::MakeRasterSnapshot(
    std::function<void(SkCanvas*)> draw_callback,
    SkISize picture_size) {
  return DoMakeRasterSnapshot(picture_size, draw_callback);
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

  SkISize image_size = image->dimensions();
  return DoMakeRasterSnapshot(image_size,
                              [image = std::move(image)](SkCanvas* canvas) {
                                canvas->drawImage(image, 0, 0);
                              });
}

fml::Milliseconds Rasterizer::GetFrameBudget() const {
  return delegate_.GetFrameBudget();
};

RasterStatus Rasterizer::DoDraw(
    std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder,
    std::unique_ptr<flutter::LayerTree> layer_tree) {
  TRACE_EVENT_WITH_FRAME_NUMBER(frame_timings_recorder, "flutter",
                                "Rasterizer::DoDraw");
  FML_DCHECK(delegate_.GetTaskRunners()
                 .GetRasterTaskRunner()
                 ->RunsTasksOnCurrentThread());

  if (!layer_tree || !surface_) {
    return RasterStatus::kFailed;
  }

  PersistentCache* persistent_cache = PersistentCache::GetCacheForProcess();
  persistent_cache->ResetStoredNewShaders();

  RasterStatus raster_status =
      DrawToSurface(*frame_timings_recorder, *layer_tree);
  if (raster_status == RasterStatus::kSuccess) {
    last_layer_tree_ = std::move(layer_tree);
  } else if (ShouldResubmitFrame(raster_status)) {
    resubmitted_layer_tree_ = std::move(layer_tree);
    resubmitted_recorder_ = frame_timings_recorder->CloneUntil(
        FrameTimingsRecorder::State::kBuildEnd);
    return raster_status;
  } else if (raster_status == RasterStatus::kDiscarded) {
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
  delegate_.OnFrameRasterized(frame_timings_recorder->GetRecordedTime());

// SceneDisplayLag events are disabled on Fuchsia.
// see: https://github.com/flutter/flutter/issues/56598
#if !defined(OS_FUCHSIA)
  const fml::TimePoint raster_finish_time =
      frame_timings_recorder->GetRasterEndTime();
  fml::TimePoint frame_target_time =
      frame_timings_recorder->GetVsyncTargetTime();
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

RasterStatus Rasterizer::DrawToSurface(
    FrameTimingsRecorder& frame_timings_recorder,
    flutter::LayerTree& layer_tree) {
  FML_DCHECK(surface_);

  RasterStatus raster_status;
  if (surface_->AllowsDrawingWhenGpuDisabled()) {
    raster_status = DrawToSurfaceUnsafe(frame_timings_recorder, layer_tree);
  } else {
    delegate_.GetIsGpuDisabledSyncSwitch()->Execute(
        fml::SyncSwitch::Handlers()
            .SetIfTrue([&] { raster_status = RasterStatus::kDiscarded; })
            .SetIfFalse([&] {
              raster_status =
                  DrawToSurfaceUnsafe(frame_timings_recorder, layer_tree);
            }));
  }

  return raster_status;
}

/// Unsafe because it assumes we have access to the GPU which isn't the case
/// when iOS is backgrounded, for example.
/// \see Rasterizer::DrawToSurface
RasterStatus Rasterizer::DrawToSurfaceUnsafe(
    FrameTimingsRecorder& frame_timings_recorder,
    flutter::LayerTree& layer_tree) {
  FML_DCHECK(surface_);

  compositor_context_->ui_time().SetLapTime(
      frame_timings_recorder.GetBuildDuration());

  SkCanvas* embedder_root_canvas = nullptr;
  if (external_view_embedder_) {
    FML_DCHECK(!external_view_embedder_->GetUsedThisFrame());
    external_view_embedder_->SetUsedThisFrame(true);
    external_view_embedder_->BeginFrame(
        layer_tree.frame_size(), surface_->GetContext(),
        layer_tree.device_pixel_ratio(), raster_thread_merger_);
    embedder_root_canvas = external_view_embedder_->GetRootCanvas();
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
      surface_->GetContext(),         // skia GrContext
      root_surface_canvas,            // root surface canvas
      external_view_embedder_.get(),  // external view embedder
      root_surface_transformation,    // root surface transformation
      true,                           // instrumentation enabled
      frame->framebuffer_info()
          .supports_readback,               // surface supports pixel reads
      raster_thread_merger_,                // thread merger
      frame->GetDisplayListBuilder().get()  // display list builder
  );
  if (compositor_frame) {
    compositor_context_->raster_cache().PrepareNewFrame();
    frame_timings_recorder.RecordRasterStart(fml::TimePoint::Now());

    std::unique_ptr<FrameDamage> damage;
    // when leaf layer tracing is enabled we wish to repaing the whole frame for
    // accurate performance metrics.
    if (frame->framebuffer_info().supports_partial_repaint &&
        !layer_tree.is_leaf_layer_tracing_enabled()) {
      // Disable partial repaint if external_view_embedder_ SubmitFrame is
      // involved - ExternalViewEmbedder unconditionally clears the entire
      // surface and also partial repaint with platform view present is
      // something that still need to be figured out.
      bool force_full_repaint =
          external_view_embedder_ &&
          (!raster_thread_merger_ || raster_thread_merger_->IsMerged());

      damage = std::make_unique<FrameDamage>();
      if (frame->framebuffer_info().existing_damage && !force_full_repaint) {
        damage->SetPreviousLayerTree(last_layer_tree_.get());
        damage->AddAdditonalDamage(*frame->framebuffer_info().existing_damage);
        damage->SetClipAlignment(
            frame->framebuffer_info().horizontal_clip_alignment,
            frame->framebuffer_info().vertical_clip_alignment);
      }
    }

    bool ignore_raster_cache = true;
    if (surface_->EnableRasterCache() &&
        !layer_tree.is_leaf_layer_tracing_enabled()) {
      ignore_raster_cache = false;
    }

    RasterStatus raster_status =
        compositor_frame->Raster(layer_tree,           // layer tree
                                 ignore_raster_cache,  // ignore raster cache
                                 damage.get()          // frame damage
        );
    if (raster_status == RasterStatus::kFailed ||
        raster_status == RasterStatus::kSkipAndRetry) {
      return raster_status;
    }

    SurfaceFrame::SubmitInfo submit_info;
    // TODO (https://github.com/flutter/flutter/issues/105596): this can be in
    // the past and might need to get snapped to future as this frame could have
    // been resubmitted. `presentation_time` on `submit_info` is not set in this
    // case.
    const auto presentation_time = frame_timings_recorder.GetVsyncTargetTime();
    if (presentation_time > fml::TimePoint::Now()) {
      submit_info.presentation_time = presentation_time;
    }
    if (damage) {
      submit_info.frame_damage = damage->GetFrameDamage();
      submit_info.buffer_damage = damage->GetBufferDamage();
    }

    frame->set_submit_info(submit_info);

    if (external_view_embedder_ &&
        (!raster_thread_merger_ || raster_thread_merger_->IsMerged())) {
      FML_DCHECK(!frame->IsSubmitted());
      external_view_embedder_->SubmitFrame(surface_->GetContext(),
                                           std::move(frame));
    } else {
      frame->Submit();
    }

    compositor_context_->raster_cache().CleanupAfterFrame();
    frame_timings_recorder.RecordRasterEnd(
        &compositor_context_->raster_cache());
    FireNextFrameCallbackIfPresent();

    if (surface_->GetContext()) {
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

  // TODO(amirh): figure out how to take a screenshot with embedded UIView.
  // https://github.com/flutter/flutter/issues/23435
  auto frame = compositor_context.AcquireFrame(
      nullptr, recorder.getRecordingCanvas(), nullptr,
      root_surface_transformation, false, true, nullptr, nullptr);
  frame->Raster(*tree, true, nullptr);

#if defined(OS_FUCHSIA)
  SkSerialProcs procs = {0};
  procs.fImageProc = SerializeImageWithoutData;
  procs.fTypefaceProc = SerializeTypefaceWithoutData;
#else
  SkSerialProcs procs = {0};
  procs.fTypefaceProc = SerializeTypefaceWithData;
#endif

  return recorder.finishRecordingAsPicture()->serialize(&procs);
}

sk_sp<SkData> Rasterizer::ScreenshotLayerTreeAsImage(
    flutter::LayerTree* tree,
    flutter::CompositorContext& compositor_context,
    GrDirectContext* surface_context,
    bool compressed) {
  // Attempt to create a snapshot surface depending on whether we have access to
  // a valid GPU rendering context.
  std::unique_ptr<OffscreenSurface> snapshot_surface =
      std::make_unique<OffscreenSurface>(surface_context, tree->frame_size());

  if (!snapshot_surface->IsValid()) {
    FML_LOG(ERROR) << "Screenshot: unable to create snapshot surface";
    return nullptr;
  }

  // Draw the current layer tree into the snapshot surface.
  auto* canvas = snapshot_surface->GetCanvas();

  // There is no root surface transformation for the screenshot layer. Reset the
  // matrix to identity.
  SkMatrix root_surface_transformation;
  root_surface_transformation.reset();

  // snapshot_surface->makeImageSnapshot needs the GL context to be set if the
  // render context is GL. frame->Raster() pops the gl context in platforms that
  // gl context switching are used. (For example, older iOS that uses GL) We
  // reset the GL context using the context switch.
  auto context_switch = surface_->MakeRenderContextCurrent();
  if (!context_switch->GetResult()) {
    FML_LOG(ERROR) << "Screenshot: unable to make image screenshot";
    return nullptr;
  }

  auto frame = compositor_context.AcquireFrame(
      surface_context,              // skia context
      canvas,                       // canvas
      nullptr,                      // view embedder
      root_surface_transformation,  // root surface transformation
      false,                        // instrumentation enabled
      true,                         // render buffer readback supported
      nullptr,                      // thread merger
      nullptr                       // display list builder
  );
  canvas->clear(SK_ColorTRANSPARENT);
  frame->Raster(*tree, true, nullptr);
  canvas->flush();

  return snapshot_surface->GetRasterData(compressed);
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

void Rasterizer::SetExternalViewEmbedder(
    const std::shared_ptr<ExternalViewEmbedder>& view_embedder) {
  external_view_embedder_ = view_embedder;
}

void Rasterizer::SetSnapshotSurfaceProducer(
    std::unique_ptr<SnapshotSurfaceProducer> producer) {
  snapshot_surface_producer_ = std::move(producer);
}

fml::RefPtr<fml::RasterThreadMerger> Rasterizer::GetRasterThreadMerger() {
  return raster_thread_merger_;
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
    auto context_switch = surface_->MakeRenderContextCurrent();
    if (!context_switch->GetResult()) {
      return;
    }

    context->setResourceCacheLimit(max_bytes);
  }
}

std::optional<size_t> Rasterizer::GetResourceCacheMaxBytes() const {
  if (!surface_) {
    return std::nullopt;
  }
  GrDirectContext* context = surface_->GetContext();
  if (context) {
    return context->getResourceCacheLimit();
  }
  return std::nullopt;
}

Rasterizer::Screenshot::Screenshot() {}

Rasterizer::Screenshot::Screenshot(sk_sp<SkData> p_data, SkISize p_size)
    : data(std::move(p_data)), frame_size(p_size) {}

Rasterizer::Screenshot::Screenshot(const Screenshot& other) = default;

Rasterizer::Screenshot::~Screenshot() = default;

}  // namespace flutter
