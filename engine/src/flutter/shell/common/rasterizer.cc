// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/rasterizer.h"

#include <algorithm>
#include <memory>
#include <utility>

#include "display_list/dl_builder.h"
#include "flow/frame_timings.h"
#include "flutter/common/constants.h"
#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/flow/layers/offscreen_surface.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/shell/common/base64.h"
#include "flutter/shell/common/serialization_callbacks.h"
#include "fml/closure.h"
#include "fml/make_copyable.h"
#include "fml/synchronization/waitable_event.h"
#include "impeller/renderer/context.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkSerialProcs.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/encode/SkPngEncoder.h"
#include "third_party/skia/include/gpu/GpuTypes.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/GrTypes.h"
#include "third_party/skia/include/gpu/ganesh/SkSurfaceGanesh.h"

#if IMPELLER_SUPPORTS_RENDERING
#include "impeller/core/formats.h"                // nogncheck
#include "impeller/display_list/aiks_context.h"   // nogncheck
#include "impeller/display_list/dl_dispatcher.h"  // nogncheck
#endif

namespace flutter {

// The rasterizer will tell Skia to purge cached resources that have not been
// used within this interval.
[[maybe_unused]] static constexpr std::chrono::milliseconds
    kSkiaCleanupExpiration(15000);

Rasterizer::Rasterizer(Delegate& delegate,
                       MakeGpuImageBehavior gpu_image_behavior)
    : delegate_(delegate),
      gpu_image_behavior_(gpu_image_behavior),
      compositor_context_(std::make_unique<flutter::CompositorContext>(*this)),
      snapshot_controller_(
          SnapshotController::Make(*this, delegate.GetSettings())),
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

void Rasterizer::SetImpellerContext(
    std::shared_ptr<impeller::ImpellerContextFuture> impeller_context) {
  impeller_context_ = std::move(impeller_context);
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
}

void Rasterizer::TeardownExternalViewEmbedder() {
  if (external_view_embedder_) {
    external_view_embedder_->Teardown();
  }
}

void Rasterizer::Teardown() {
  is_torn_down_ = true;
  if (surface_) {
    auto context_switch = surface_->MakeRenderContextCurrent();
    if (context_switch->GetResult()) {
      compositor_context_->OnGrContextDestroyed();
#if !SLIMPELLER
      if (auto* context = surface_->GetContext()) {
        context->purgeUnlockedResources(GrPurgeResourceOptions::kAllResources);
      }
#endif  //  !SLIMPELLER
    }
    context_switch.reset();
    surface_->ClearRenderContext();
    surface_.reset();
  }

  view_records_.clear();
  deferred_last_layer_trees_recorder_.reset();
  if (has_deferred_pipeline_) {
    has_deferred_pipeline_ = false;
    std::shared_ptr<FramePipeline> pipeline = deferred_pipeline_.lock();
    deferred_pipeline_.reset();
    if (pipeline) {
      // Drain the deferred frame while surface_ is null so the pipeline is not
      // left wedged and first-frame waiters are flushed synchronously before
      // Teardown() returns.
      Draw(pipeline);
    } else {
      delegate_.OnDrawFinished(DrawStatus::kNotSetUp);
    }
  }
}

bool Rasterizer::IsTornDown() {
  return is_torn_down_;
}

std::optional<DrawSurfaceStatus> Rasterizer::GetLastDrawStatus(
    int64_t view_id) {
  auto found = view_records_.find(view_id);
  if (found != view_records_.end()) {
    return found->second.last_draw_status;
  } else {
    return std::optional<DrawSurfaceStatus>();
  }
}

void Rasterizer::NotifyLowMemoryWarning() const {
  ClearRenderTargetCache();
}

void Rasterizer::ClearRenderTargetCache() const {
  if (!surface_) {
    FML_DLOG(INFO)
        << "Rasterizer::ClearRenderTargetCache called with no surface.";
    return;
  }
#if IMPELLER_SUPPORTS_RENDERING
  if (auto aiks_context = surface_->GetAiksContext()) {
    auto context_switch = surface_->MakeRenderContextCurrent();
    if (context_switch->GetResult()) {
      aiks_context->ClearRenderTargetCache();
      aiks_context->ClearCachedTextures();
    }
    return;
  }
#endif  // IMPELLER_SUPPORTS_RENDERING
#if !SLIMPELLER
  auto context = surface_->GetContext();
  if (!context) {
    FML_DLOG(INFO)
        << "Rasterizer::ClearRenderTargetCache called with no GrContext.";
    return;
  }
  auto context_switch = surface_->MakeRenderContextCurrent();
  if (!context_switch->GetResult()) {
    return;
  }
  context->performDeferredCleanup(std::chrono::milliseconds(0));
#endif  // !SLIMPELLER
}

void Rasterizer::CollectView(int64_t view_id) {
  if (external_view_embedder_) {
    external_view_embedder_->CollectView(view_id);
  }
  view_records_.erase(view_id);
}

std::shared_ptr<flutter::TextureRegistry> Rasterizer::GetTextureRegistry() {
  return compositor_context_->texture_registry();
}

GrDirectContext* Rasterizer::GetGrContext() {
  return surface_ ? surface_->GetContext() : nullptr;
}

flutter::LayerTree* Rasterizer::GetLastLayerTree(int64_t view_id) {
  auto found = view_records_.find(view_id);
  if (found == view_records_.end()) {
    return nullptr;
  }
  auto& last_task = found->second.last_successful_task;
  if (last_task == nullptr) {
    return nullptr;
  }
  return last_task->layer_tree.get();
}

fml::closure Rasterizer::MakeResumeDeferredDrawCallback() {
  return [weak_this = weak_factory_.GetWeakPtr()]() {
    if (weak_this) {
      weak_this->ResumeDeferredDraw();
    }
  };
}

void Rasterizer::ResumeDeferredDraw() {
  FML_DCHECK(delegate_.GetTaskRunners()
                 .GetRasterTaskRunner()
                 ->RunsTasksOnCurrentThread());
  if (has_deferred_pipeline_) {
    has_deferred_pipeline_ = false;
    std::shared_ptr<FramePipeline> pipeline = deferred_pipeline_.lock();
    deferred_pipeline_.reset();
    deferred_last_layer_trees_recorder_.reset();
    if (pipeline) {
      Draw(pipeline);
    } else {
      delegate_.OnDrawFinished(DrawStatus::kPipelineEmpty);
    }
    return;
  }
  if (deferred_last_layer_trees_recorder_) {
    DrawLastLayerTrees(std::move(deferred_last_layer_trees_recorder_));
  }
}

void Rasterizer::DrawLastLayerTrees(
    std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder) {
  if (!surface_) {
    return;
  }
  if (has_deferred_pipeline_) {
    // A newer FramePipeline draw is already deferred and supersedes redrawing
    // the previous layer trees.
    return;
  }
  if (external_view_embedder_ && !external_view_embedder_->ReadyForNextFrame(
                                     MakeResumeDeferredDrawCallback())) {
    TRACE_EVENT0("flutter", "Rasterizer::DrawLastLayerTreesDeferred");
    deferred_last_layer_trees_recorder_ = std::move(frame_timings_recorder);
    return;
  }
  deferred_last_layer_trees_recorder_.reset();
  std::vector<std::unique_ptr<LayerTreeTask>> tasks;
  for (auto& [view_id, view_record] : view_records_) {
    if (view_record.last_successful_task) {
      tasks.push_back(std::move(view_record.last_successful_task));
    }
  }
  if (tasks.empty()) {
    return;
  }

  DrawToSurfaces(*frame_timings_recorder, tasks);

  // Restore any tasks that were not consumed by a successful draw (for example
  // on kGpuUnavailable or kFailed) so subsequent DrawLastLayerTrees calls do
  // not lose the last successful layer tree.
  for (auto& task : tasks) {
    if (task) {
      auto& view_record = EnsureViewRecord(task->view_id);
      if (!view_record.last_successful_task) {
        view_record.last_successful_task = std::move(task);
      }
    }
  }

  // EndFrame should perform cleanups for the external_view_embedder.
  if (external_view_embedder_ && external_view_embedder_->GetUsedThisFrame()) {
    external_view_embedder_->SetUsedThisFrame(false);
    external_view_embedder_->EndFrame();
  }
}

DrawStatus Rasterizer::Draw(const std::shared_ptr<FramePipeline>& pipeline) {
  TRACE_EVENT0("flutter", "GPURasterizer::Draw");
  auto finish = [&](DrawStatus status) {
    delegate_.OnDrawFinished(status);
    return status;
  };
  FML_DCHECK(delegate_.GetTaskRunners()
                 .GetRasterTaskRunner()
                 ->RunsTasksOnCurrentThread());

  // Leave the frame in the pipeline while the embedder isn't ready for it. The
  // embedder resumes drawing instead of blocking the raster thread. Only query
  // the embedder when a surface is set up so torn-down draws drain as kNotSetUp
  // without racing TeardownExternalViewEmbedder() on the platform thread.
  if (surface_ && external_view_embedder_ &&
      !external_view_embedder_->ReadyForNextFrame(
          MakeResumeDeferredDrawCallback())) {
    TRACE_EVENT0("flutter", "Rasterizer::DrawDeferred");
    deferred_last_layer_trees_recorder_.reset();
    deferred_pipeline_ = pipeline;
    has_deferred_pipeline_ = true;
    return finish(DrawStatus::kDeferred);
  }
  has_deferred_pipeline_ = false;
  deferred_pipeline_.reset();

  DoDrawStatus draw_status = DoDrawStatus::kDone;
  FramePipeline::Consumer consumer = [&draw_status,
                                      this](std::unique_ptr<FrameItem> item) {
    draw_status = DoDraw(std::move(item->frame_timings_recorder),
                         std::move(item->layer_tree_tasks));
  };

  PipelineConsumeResult consume_result = pipeline->Consume(consumer);
  if (consume_result == PipelineConsumeResult::NoneAvailable) {
    return finish(DrawStatus::kPipelineEmpty);
  }

  // EndFrame should perform cleanups for the external_view_embedder.
  if (external_view_embedder_ && external_view_embedder_->GetUsedThisFrame()) {
    external_view_embedder_->SetUsedThisFrame(false);
    external_view_embedder_->EndFrame();
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

  return finish(ToDrawStatus(draw_status));
}

DrawStatus Rasterizer::ToDrawStatus(DoDrawStatus status) {
  switch (status) {
    case DoDrawStatus::kNotSetUp:
      return DrawStatus::kNotSetUp;
    case DoDrawStatus::kGpuUnavailable:
      return DrawStatus::kGpuUnavailable;
    case DoDrawStatus::kDone:
      return DrawStatus::kDone;
  }
  FML_UNREACHABLE();
}

#if !SLIMPELLER
namespace {
std::unique_ptr<SnapshotDelegate::GpuImageResult> MakeBitmapImage(
    const sk_sp<DisplayList>& display_list,
    const SkImageInfo& image_info) {
  FML_DCHECK(display_list);
  // Use 16384 as a proxy for the maximum texture size for a GPU image.
  // This is meant to be large enough to avoid false positives in test contexts,
  // but not so artificially large to be completely unrealistic on any platform.
  // This limit is taken from the Metal specification. D3D, Vulkan, and GL
  // generally have lower limits.
  if (image_info.width() > 16384 || image_info.height() > 16384) {
    return std::make_unique<SnapshotDelegate::GpuImageResult>(
        GrBackendTexture(), nullptr, nullptr,
        "unable to create bitmap render target at specified size " +
            std::to_string(image_info.width()) + "x" +
            std::to_string(image_info.height()));
  };

  sk_sp<SkSurface> surface = SkSurfaces::Raster(image_info);
  auto canvas = DlSkCanvasAdapter(surface->getCanvas());
  canvas.Clear(DlColor::kTransparent());
  canvas.DrawDisplayList(display_list);

  sk_sp<SkImage> image = surface->makeImageSnapshot();
  return std::make_unique<SnapshotDelegate::GpuImageResult>(
      GrBackendTexture(), nullptr, image,
      image ? "" : "Unable to create image");
}
}  // namespace
#endif  //  !SLIMPELLER

std::unique_ptr<Rasterizer::GpuImageResult> Rasterizer::MakeSkiaGpuImage(
    sk_sp<DisplayList> display_list,
    const SkImageInfo& image_info) {
#if SLIMPELLER
  FML_LOG(FATAL) << "Impeller opt-out unavailable.";
  return nullptr;
#else   // SLIMPELLER
  TRACE_EVENT0("flutter", "Rasterizer::MakeGpuImage");
  FML_DCHECK(display_list);

  std::unique_ptr<SnapshotDelegate::GpuImageResult> result;
  delegate_.GetIsGpuDisabledSyncSwitch()->Execute(
      fml::SyncSwitch::Handlers()
          .SetIfTrue([&result, &image_info, &display_list] {
            // TODO(dnfield): This isn't safe if display_list contains any GPU
            // resources like an SkImage_gpu.
            result = MakeBitmapImage(display_list, image_info);
          })
          .SetIfFalse([&result, &image_info, &display_list,
                       surface = surface_.get(),
                       gpu_image_behavior = gpu_image_behavior_] {
            if (!surface ||
                gpu_image_behavior == MakeGpuImageBehavior::kBitmap) {
              // TODO(dnfield): This isn't safe if display_list contains any GPU
              // resources like an SkImage_gpu.
              result = MakeBitmapImage(display_list, image_info);
              return;
            }

            auto context_switch = surface->MakeRenderContextCurrent();
            if (!context_switch->GetResult()) {
              result = MakeBitmapImage(display_list, image_info);
              return;
            }

            auto* context = surface->GetContext();
            if (!context) {
              result = MakeBitmapImage(display_list, image_info);
              return;
            }

            GrBackendTexture texture = context->createBackendTexture(
                image_info.width(), image_info.height(), image_info.colorType(),
                skgpu::Mipmapped::kNo, GrRenderable::kYes);
            if (!texture.isValid()) {
              result = std::make_unique<SnapshotDelegate::GpuImageResult>(
                  GrBackendTexture(), nullptr, nullptr,
                  "unable to create texture render target at specified size " +
                      std::to_string(image_info.width()) + "x" +
                      std::to_string(image_info.height()));
              return;
            }

            sk_sp<SkSurface> sk_surface = SkSurfaces::WrapBackendTexture(
                context, texture, kTopLeft_GrSurfaceOrigin, /*sampleCnt=*/0,
                image_info.colorType(), image_info.refColorSpace(), nullptr);
            if (!sk_surface) {
              result = std::make_unique<SnapshotDelegate::GpuImageResult>(
                  GrBackendTexture(), nullptr, nullptr,
                  "unable to create rendering surface for image");
              return;
            }

            auto canvas = DlSkCanvasAdapter(sk_surface->getCanvas());
            canvas.Clear(DlColor::kTransparent());
            canvas.DrawDisplayList(display_list);

            result = std::make_unique<SnapshotDelegate::GpuImageResult>(
                texture, sk_ref_sp(context), nullptr, "");
          }));
  return result;
#endif  //  !SLIMPELLER
}

void Rasterizer::MakeSkiaSnapshot(sk_sp<DisplayList> display_list,
                                  DlISize picture_size,
                                  std::function<void(sk_sp<SkImage>)> callback,
                                  SnapshotPixelFormat pixel_format) {
  return snapshot_controller_->MakeSkiaSnapshot(
      display_list, picture_size, std::move(callback), pixel_format);
}

sk_sp<SkImage> Rasterizer::MakeSkiaSnapshotSync(
    sk_sp<DisplayList> display_list,
    DlISize picture_size,
    SnapshotPixelFormat pixel_format) {
  return snapshot_controller_->MakeSkiaSnapshotSync(std::move(display_list),
                                                    picture_size, pixel_format);
}

void Rasterizer::MakeImpellerSnapshot(
    SnapshotDisplayListProvider provider,
    DlISize picture_size,
    std::function<void(std::shared_ptr<impeller::Texture>)> callback,
    SnapshotPixelFormat pixel_format) {
  return snapshot_controller_->MakeImpellerSnapshot(
      std::move(provider), picture_size, std::move(callback), pixel_format);
}

std::shared_ptr<impeller::Texture> Rasterizer::MakeImpellerSnapshotSync(
    SnapshotDisplayListProvider provider,
    DlISize picture_size,
    SnapshotPixelFormat pixel_format) {
  return snapshot_controller_->MakeImpellerSnapshotSync(
      std::move(provider), picture_size, pixel_format);
}

sk_sp<SkImage> Rasterizer::ConvertToRasterImage(sk_sp<SkImage> image) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  return snapshot_controller_->ConvertToRasterImage(image);
}

sk_sp<SkImage> Rasterizer::MakeSkiaTextureImage(
    sk_sp<SkImage> image,
    SnapshotPixelFormat pixel_format) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  return snapshot_controller_->MakeSkiaTextureImage(image, pixel_format);
}

std::shared_ptr<impeller::Texture> Rasterizer::MakeImpellerTextureImage(
    sk_sp<SkImage> image,
    SnapshotPixelFormat pixel_format) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  return snapshot_controller_->MakeImpellerTextureImage(image, pixel_format);
}

// |SnapshotDelegate|
void Rasterizer::CacheRuntimeStage(
    const std::shared_ptr<impeller::RuntimeStage>& runtime_stage) {
  if (snapshot_controller_) {
    snapshot_controller_->CacheRuntimeStage(runtime_stage);
  }
}

// |SnapshotDelegate|
bool Rasterizer::MakeRenderContextCurrent() {
  return snapshot_controller_->MakeRenderContextCurrent();
}

fml::Milliseconds Rasterizer::GetFrameBudget() const {
  return delegate_.GetFrameBudget();
};

Rasterizer::DoDrawStatus Rasterizer::DoDraw(
    std::unique_ptr<FrameTimingsRecorder> frame_timings_recorder,
    std::vector<std::unique_ptr<LayerTreeTask>> tasks) {
  TRACE_EVENT_WITH_FRAME_NUMBER(frame_timings_recorder, "flutter",
                                "Rasterizer::DoDraw", /*flow_id_count=*/0,
                                /*flow_ids=*/nullptr);
  FML_DCHECK(delegate_.GetTaskRunners()
                 .GetRasterTaskRunner()
                 ->RunsTasksOnCurrentThread());
  frame_timings_recorder->AssertInState(FrameTimingsRecorder::State::kBuildEnd);
  deferred_last_layer_trees_recorder_.reset();

  if (tasks.empty()) {
    return DoDrawStatus::kDone;
  }
  if (!surface_) {
    return DoDrawStatus::kNotSetUp;
  }

#if !SLIMPELLER
  PersistentCache* persistent_cache = PersistentCache::GetCacheForProcess();
  persistent_cache->ResetStoredNewShaders();
#endif  //  !SLIMPELLER

  DoDrawStatus status = DrawToSurfaces(*frame_timings_recorder, tasks);
  if (status == DoDrawStatus::kGpuUnavailable) {
    return DoDrawStatus::kGpuUnavailable;
  }

#if !SLIMPELLER
  if (persistent_cache->IsDumpingSkp() &&
      persistent_cache->StoredNewShaders()) {
    auto screenshot =
        ScreenshotLastLayerTree(ScreenshotType::SkiaPicture, false);
    persistent_cache->DumpSkp(*screenshot.data);
  }
#endif  //  !SLIMPELLER

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

  return status;
}

Rasterizer::DoDrawStatus Rasterizer::DrawToSurfaces(
    FrameTimingsRecorder& frame_timings_recorder,
    std::vector<std::unique_ptr<LayerTreeTask>>& tasks) {
  TRACE_EVENT0("flutter", "Rasterizer::DrawToSurfaces");
  FML_DCHECK(surface_);
  frame_timings_recorder.AssertInState(FrameTimingsRecorder::State::kBuildEnd);

  DoDrawStatus status = DoDrawStatus::kDone;
  if (surface_->AllowsDrawingWhenGpuDisabled()) {
    DrawToSurfacesUnsafe(frame_timings_recorder, tasks);
  } else {
    delegate_.GetIsGpuDisabledSyncSwitch()->Execute(
        fml::SyncSwitch::Handlers()
            .SetIfTrue([&] {
              status = DoDrawStatus::kGpuUnavailable;
              frame_timings_recorder.RecordRasterStart(fml::TimePoint::Now());
              frame_timings_recorder.RecordRasterEnd();
            })
            .SetIfFalse(
                [&] { DrawToSurfacesUnsafe(frame_timings_recorder, tasks); }));
  }
  frame_timings_recorder.AssertInState(FrameTimingsRecorder::State::kRasterEnd);

  return status;
}

void Rasterizer::DrawToSurfacesUnsafe(
    FrameTimingsRecorder& frame_timings_recorder,
    std::vector<std::unique_ptr<LayerTreeTask>>& tasks) {
  compositor_context_->ui_time().SetLapTime(
      frame_timings_recorder.GetBuildDuration());

  // First traverse: Filter out discarded trees
  auto task_iter = tasks.begin();
  while (task_iter != tasks.end()) {
    LayerTreeTask& task = **task_iter;
    if (delegate_.ShouldDiscardLayerTree(task.view_id, *task.layer_tree)) {
      EnsureViewRecord(task.view_id).last_draw_status =
          DrawSurfaceStatus::kDiscarded;
      task_iter = tasks.erase(task_iter);
    } else {
      ++task_iter;
    }
  }
  if (tasks.empty()) {
    frame_timings_recorder.RecordRasterStart(fml::TimePoint::Now());
    frame_timings_recorder.RecordRasterEnd();
    return;
  }

  if (external_view_embedder_) {
    FML_DCHECK(!external_view_embedder_->GetUsedThisFrame());
    external_view_embedder_->SetUsedThisFrame(true);
    external_view_embedder_->BeginFrame(surface_->GetContext());
  }

  std::optional<fml::TimePoint> presentation_time = std::nullopt;
  {
    const auto vsync_target_time = frame_timings_recorder.GetVsyncTargetTime();
    if (vsync_target_time > fml::TimePoint::Now()) {
      presentation_time = vsync_target_time;
    }
  }

  frame_timings_recorder.RecordRasterStart(fml::TimePoint::Now());

  // Second traverse: draw all layer trees.
  for (std::unique_ptr<LayerTreeTask>& task : tasks) {
    int64_t view_id = task->view_id;
    float device_pixel_ratio = task->device_pixel_ratio;

    DrawSurfaceStatus status = DrawToSurfaceUnsafe(
        view_id, *task->layer_tree, device_pixel_ratio, presentation_time);
    FML_DCHECK(status != DrawSurfaceStatus::kDiscarded);

    auto& view_record = EnsureViewRecord(view_id);
    view_record.last_draw_status = status;
    if (status == DrawSurfaceStatus::kSuccess) {
      view_record.last_successful_task = std::move(task);
    }
  }
  // TODO(dkwingsmt): Pass in raster cache(s) for all views.
  // See https://github.com/flutter/flutter/issues/135530, item 4.
  frame_timings_recorder.RecordRasterEnd(
      NOT_SLIMPELLER(&compositor_context_->raster_cache()));

  FireNextFrameCallbackIfPresent();

#if !SLIMPELLER
  if (surface_->GetContext()) {
    surface_->GetContext()->performDeferredCleanup(kSkiaCleanupExpiration);
  }
#endif  //  !SLIMPELLER
}

/// \see Rasterizer::DrawToSurfaces
DrawSurfaceStatus Rasterizer::DrawToSurfaceUnsafe(
    int64_t view_id,
    flutter::LayerTree& layer_tree,
    float device_pixel_ratio,
    std::optional<fml::TimePoint> presentation_time) {
  FML_DCHECK(surface_);

  DlCanvas* embedder_root_canvas = nullptr;
  if (external_view_embedder_) {
    external_view_embedder_->PrepareFlutterView(layer_tree.frame_size(),
                                                device_pixel_ratio);
    // TODO(dkwingsmt): Add view ID here.
    embedder_root_canvas = external_view_embedder_->GetRootCanvas();
  }

  // On Android, the external view embedder deletes surfaces in `BeginFrame`.
  //
  // Deleting a surface also clears the GL context. Therefore, acquire the
  // frame after calling `BeginFrame` as this operation resets the GL context.
  auto frame = surface_->AcquireFrame(layer_tree.frame_size());
  if (frame == nullptr) {
    return DrawSurfaceStatus::kFailed;
  }

  // If the external view embedder has specified an optional root surface, the
  // root surface transformation is set by the embedder instead of
  // having to apply it here.
  DlMatrix root_surface_transformation =
      embedder_root_canvas ? DlMatrix() : surface_->GetRootTransformation();

  auto root_surface_canvas =
      embedder_root_canvas ? embedder_root_canvas : frame->Canvas();
  auto compositor_frame = compositor_context_->AcquireFrame(
      surface_->GetContext(),         // skia GrContext
      root_surface_canvas,            // root surface canvas
      external_view_embedder_.get(),  // external view embedder
      root_surface_transformation,    // root surface transformation
      true,                           // instrumentation enabled
      frame->framebuffer_info()
          .supports_readback,           // surface supports pixel reads
      surface_->GetAiksContext().get()  // aiks context
  );
  if (compositor_frame) {
    NOT_SLIMPELLER(compositor_context_->raster_cache().BeginFrame());

    std::unique_ptr<FrameDamage> damage;
    // when leaf layer tracing is enabled we wish to repaint the whole frame
    // for accurate performance metrics.
    if (frame->framebuffer_info().supports_partial_repaint) {
      // Disable partial repaint if external_view_embedder_ SubmitFlutterView is
      // involved - ExternalViewEmbedder unconditionally clears the entire
      // surface and also partial repaint with platform view present is
      // something that still need to be figured out.
      bool force_full_repaint = external_view_embedder_ != nullptr;

      damage = std::make_unique<FrameDamage>();
      auto existing_damage = frame->framebuffer_info().existing_damage;
      if (existing_damage.has_value() && !force_full_repaint) {
        damage->SetPreviousLayerTree(GetLastLayerTree(view_id));
        damage->AddAdditionalDamage(existing_damage.value());
        damage->SetClipAlignment(
            frame->framebuffer_info().horizontal_clip_alignment,
            frame->framebuffer_info().vertical_clip_alignment);
      }
    }

    bool ignore_raster_cache = true;
    if (surface_->EnableRasterCache()) {
      ignore_raster_cache = false;
    }

    compositor_frame->Raster(layer_tree,           // layer tree
                             ignore_raster_cache,  // ignore raster cache
                             damage.get()          // frame damage
    );

    SurfaceFrame::SubmitInfo submit_info;
    submit_info.presentation_time = presentation_time;
    if (damage) {
      submit_info.frame_damage = damage->GetFrameDamage();
      submit_info.buffer_damage = damage->GetBufferDamage();
    }

    frame->set_submit_info(submit_info);

    if (external_view_embedder_) {
      FML_DCHECK(!frame->IsSubmitted());
      external_view_embedder_->SubmitFlutterView(
          view_id, surface_->GetContext(), surface_->GetAiksContext(),
          std::move(frame));
    } else {
      frame->Submit();
    }

#if !SLIMPELLER
    compositor_context_->raster_cache().EndFrame();
#endif  //  !SLIMPELLER

    return DrawSurfaceStatus::kSuccess;
  }

  return DrawSurfaceStatus::kFailed;
}

Rasterizer::ViewRecord& Rasterizer::EnsureViewRecord(int64_t view_id) {
  return view_records_[view_id];
}

static sk_sp<SkData> ScreenshotLayerTreeAsPicture(
    flutter::LayerTree* tree,
    flutter::CompositorContext& compositor_context) {
#if SLIMPELLER
  return nullptr;
#else  // SLIMPELLER
  FML_DCHECK(tree != nullptr);
  SkPictureRecorder recorder;
  recorder.beginRecording(
      SkRect::MakeWH(tree->frame_size().width, tree->frame_size().height));

  DlMatrix root_surface_transformation;
  DlSkCanvasAdapter canvas(recorder.getRecordingCanvas());

  // TODO(amirh): figure out how to take a screenshot with embedded UIView.
  // https://github.com/flutter/flutter/issues/23435
  auto frame = compositor_context.AcquireFrame(nullptr, &canvas, nullptr,
                                               root_surface_transformation,
                                               false, true, nullptr);
  frame->Raster(*tree, true, nullptr);

#if defined(OS_FUCHSIA)
  SkSerialProcs procs = {0};
  procs.fImageProc = SerializeImageWithoutData;
  procs.fTypefaceProc = SerializeTypefaceWithoutData;
#else
  SkSerialProcs procs = {0};
  procs.fTypefaceProc = SerializeTypefaceWithData;
  procs.fImageProc = [](SkImage* img, void*) -> SkSerialReturnType {
    return SkPngEncoder::Encode(nullptr, img, SkPngEncoder::Options{});
  };
#endif

  return recorder.finishRecordingAsPicture()->serialize(&procs);
#endif  //  SLIMPELLER
}

static void RenderFrameForScreenshot(
    flutter::CompositorContext& compositor_context,
    DlCanvas* canvas,
    flutter::LayerTree* tree,
    GrDirectContext* surface_context,
    const std::shared_ptr<impeller::AiksContext>& aiks_context) {
  // There is no root surface transformation for the screenshot layer. Reset
  // the matrix to identity.
  DlMatrix root_surface_transformation;

  auto frame = compositor_context.AcquireFrame(
      /*gr_context=*/surface_context,
      /*canvas=*/canvas,
      /*view_embedder=*/nullptr,
      /*root_surface_transformation=*/root_surface_transformation,
      /*instrumentation_enabled=*/false,
      /*surface_supports_readback=*/true,
      /*aiks_context=*/aiks_context.get());
  canvas->Clear(DlColor::kTransparent());
  frame->Raster(*tree, true, nullptr);
  canvas->Flush();
}

#if IMPELLER_SUPPORTS_RENDERING
Rasterizer::ScreenshotFormat ToScreenshotFormat(impeller::PixelFormat format) {
  switch (format) {
    case impeller::PixelFormat::kUnknown:
    case impeller::PixelFormat::kA8UNormInt:
    case impeller::PixelFormat::kR8UNormInt:
    case impeller::PixelFormat::kR8G8UNormInt:
    case impeller::PixelFormat::kR8G8B8A8UNormIntSRGB:
    case impeller::PixelFormat::kB8G8R8A8UNormIntSRGB:
    case impeller::PixelFormat::kB10G10R10XRSRGB:
    case impeller::PixelFormat::kS8UInt:
    case impeller::PixelFormat::kD24UnormS8Uint:
    case impeller::PixelFormat::kD32FloatS8UInt:
    case impeller::PixelFormat::kR32G32B32A32Float:
    case impeller::PixelFormat::kB10G10R10XR:
    case impeller::PixelFormat::kB10G10R10A10XR:
    case impeller::PixelFormat::kR32Float:
    case impeller::PixelFormat::kBC1RGBAUNormInt:
    case impeller::PixelFormat::kBC1RGBAUNormIntSRGB:
    case impeller::PixelFormat::kBC3RGBAUNormInt:
    case impeller::PixelFormat::kBC3RGBAUNormIntSRGB:
    case impeller::PixelFormat::kBC5RGUNormInt:
    case impeller::PixelFormat::kBC7RGBAUNormInt:
    case impeller::PixelFormat::kBC7RGBAUNormIntSRGB:
    case impeller::PixelFormat::kETC2RGB8UNormInt:
    case impeller::PixelFormat::kETC2RGB8UNormIntSRGB:
    case impeller::PixelFormat::kETC2RGBA8UNormInt:
    case impeller::PixelFormat::kETC2RGBA8UNormIntSRGB:
    case impeller::PixelFormat::kASTC4x4LDR:
    case impeller::PixelFormat::kASTC4x4LDRSRGB:
    case impeller::PixelFormat::kASTC8x8LDR:
    case impeller::PixelFormat::kASTC8x8LDRSRGB:
    case impeller::PixelFormat::kASTC4x4HDR:
    case impeller::PixelFormat::kASTC8x8HDR:
      FML_DCHECK(false);
      return Rasterizer::ScreenshotFormat::kUnknown;
    case impeller::PixelFormat::kR8G8B8A8UNormInt:
      return Rasterizer::ScreenshotFormat::kR8G8B8A8UNormInt;
    case impeller::PixelFormat::kB8G8R8A8UNormInt:
      return Rasterizer::ScreenshotFormat::kB8G8R8A8UNormInt;
    case impeller::PixelFormat::kR16G16B16A16Float:
      return Rasterizer::ScreenshotFormat::kR16G16B16A16Float;
  }
}

static std::pair<sk_sp<SkData>, Rasterizer::ScreenshotFormat>
ScreenshotLayerTreeAsImageImpeller(
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    flutter::LayerTree* tree,
    flutter::CompositorContext& compositor_context,
    bool compressed) {
  if (compressed) {
    FML_LOG(ERROR) << "Compressed screenshots not supported for Impeller";
    return {nullptr, Rasterizer::ScreenshotFormat::kUnknown};
  }

  DisplayListBuilder builder(DlRect::MakeSize(tree->frame_size()));

  RenderFrameForScreenshot(compositor_context, &builder, tree, nullptr,
                           aiks_context);

  std::shared_ptr<impeller::Texture> texture = impeller::DisplayListToTexture(
      builder.Build(), impeller::ISize(tree->frame_size()), *aiks_context);
  if (!texture) {
    FML_LOG(ERROR) << "Failed to render to texture";
    return {nullptr, Rasterizer::ScreenshotFormat::kUnknown};
  }

  impeller::DeviceBufferDescriptor buffer_desc;
  buffer_desc.storage_mode = impeller::StorageMode::kHostVisible;
  buffer_desc.size =
      texture->GetTextureDescriptor().GetByteSizeOfBaseMipLevel();
  auto impeller_context = aiks_context->GetContext();
  auto buffer =
      impeller_context->GetResourceAllocator()->CreateBuffer(buffer_desc);
  auto command_buffer = impeller_context->CreateCommandBuffer();
  command_buffer->SetLabel("BlitTextureToBuffer Command Buffer");
  auto pass = command_buffer->CreateBlitPass();
  pass->AddCopy(texture, buffer);
  pass->EncodeCommands();
  fml::AutoResetWaitableEvent latch;
  sk_sp<SkData> sk_data;
  auto completion = [buffer, &buffer_desc, &sk_data,
                     &latch](impeller::CommandBuffer::Status status) {
    fml::ScopedCleanupClosure cleanup([&latch]() { latch.Signal(); });
    if (status != impeller::CommandBuffer::Status::kCompleted) {
      FML_LOG(ERROR) << "Failed to complete blit pass.";
      return;
    }
    sk_data = SkData::MakeWithCopy(buffer->OnGetContents(), buffer_desc.size);
  };

  if (!impeller_context->GetCommandQueue()
           ->Submit({command_buffer}, completion)
           .ok()) {
    FML_LOG(ERROR) << "Failed to submit commands.";
  }
  latch.Wait();
  return std::make_pair(
      sk_data, ToScreenshotFormat(texture->GetTextureDescriptor().format));
}
#endif

std::pair<sk_sp<SkData>, Rasterizer::ScreenshotFormat>
Rasterizer::ScreenshotLayerTreeAsImage(
    flutter::LayerTree* tree,
    flutter::CompositorContext& compositor_context,
    bool compressed) {
#if IMPELLER_SUPPORTS_RENDERING
  if (delegate_.GetSettings().enable_impeller) {
    return ScreenshotLayerTreeAsImageImpeller(GetAiksContext(), tree,
                                              compositor_context, compressed);
  }
#endif  // IMPELLER_SUPPORTS_RENDERING

#if SLIMPELLER
  FML_LOG(FATAL) << "Impeller opt-out unavailable.";
  return {nullptr, ScreenshotFormat::kUnknown};
#else   // SLIMPELLER
  GrDirectContext* surface_context = GetGrContext();
  // Attempt to create a snapshot surface depending on whether we have access
  // to a valid GPU rendering context.
  std::unique_ptr<OffscreenSurface> snapshot_surface =
      std::make_unique<OffscreenSurface>(surface_context, tree->frame_size());

  if (!snapshot_surface->IsValid()) {
    FML_LOG(ERROR) << "Screenshot: unable to create snapshot surface";
    return {nullptr, ScreenshotFormat::kUnknown};
  }

  // Draw the current layer tree into the snapshot surface.
  DlCanvas* canvas = snapshot_surface->GetCanvas();

  // snapshot_surface->makeImageSnapshot needs the GL context to be set if the
  // render context is GL. frame->Raster() pops the gl context in platforms
  // that gl context switching are used. (For example, older iOS that uses GL)
  // We reset the GL context using the context switch.
  auto context_switch = surface_->MakeRenderContextCurrent();
  if (!context_switch->GetResult()) {
    FML_LOG(ERROR) << "Screenshot: unable to make image screenshot";
    return {nullptr, ScreenshotFormat::kUnknown};
  }

  RenderFrameForScreenshot(compositor_context, canvas, tree, surface_context,
                           nullptr);

  return std::make_pair(snapshot_surface->GetRasterData(compressed),
                        ScreenshotFormat::kUnknown);
#endif  //  !SLIMPELLER
}

Rasterizer::Screenshot Rasterizer::ScreenshotLastLayerTree(
    Rasterizer::ScreenshotType type,
    bool base64_encode) {
  if (delegate_.GetSettings().enable_impeller &&
      type == ScreenshotType::SkiaPicture) {
    FML_DCHECK(false);
    FML_LOG(ERROR) << "Last layer tree cannot be screenshotted as a "
                      "SkiaPicture when using Impeller.";
    return {};
  }
  // TODO(dkwingsmt): Support screenshotting all last layer trees
  // when the shell protocol supports multi-views.
  // https://github.com/flutter/flutter/issues/135534
  // https://github.com/flutter/flutter/issues/135535
  auto* layer_tree = GetLastLayerTree(kFlutterImplicitViewId);
  if (layer_tree == nullptr) {
    FML_LOG(ERROR) << "Last layer tree was null when screenshotting.";
    return {};
  }

  std::pair<sk_sp<SkData>, ScreenshotFormat> data{nullptr,
                                                  ScreenshotFormat::kUnknown};
  std::string format;

  switch (type) {
    case ScreenshotType::SkiaPicture:
      format = "ScreenshotType::SkiaPicture";
      data.first =
          ScreenshotLayerTreeAsPicture(layer_tree, *compositor_context_);
      break;
    case ScreenshotType::UncompressedImage:
      format = "ScreenshotType::UncompressedImage";
      data =
          ScreenshotLayerTreeAsImage(layer_tree, *compositor_context_, false);
      break;
    case ScreenshotType::CompressedImage:
      format = "ScreenshotType::CompressedImage";
      data = ScreenshotLayerTreeAsImage(layer_tree, *compositor_context_, true);
      break;
    case ScreenshotType::SurfaceData: {
      Surface::SurfaceData surface_data = surface_->GetSurfaceData();
      format = surface_data.pixel_format;
      data.first = surface_data.data;
      break;
    }
  }

  if (data.first == nullptr) {
    FML_LOG(ERROR) << "Screenshot data was null.";
    return {};
  }

  if (base64_encode) {
    size_t b64_size = Base64::EncodedSize(data.first->size());
    auto b64_data = SkData::MakeUninitialized(b64_size);
    Base64::Encode(data.first->data(), data.first->size(),
                   b64_data->writable_data());
    return Rasterizer::Screenshot{b64_data, layer_tree->frame_size(), format,
                                  data.second};
  }

  return Rasterizer::Screenshot{data.first, layer_tree->frame_size(), format,
                                data.second};
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
#if !SLIMPELLER
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
#endif  //  !SLIMPELLER
}

std::optional<size_t> Rasterizer::GetResourceCacheMaxBytes() const {
#if SLIMPELLER
  return std::nullopt;
#else   // SLIMPELLER
  if (!surface_) {
    return std::nullopt;
  }
  GrDirectContext* context = surface_->GetContext();
  if (context) {
    return context->getResourceCacheLimit();
  }
  return std::nullopt;
#endif  //  SLIMPELLER
}

Rasterizer::Screenshot::Screenshot() {}

Rasterizer::Screenshot::Screenshot(sk_sp<SkData> p_data,
                                   DlISize p_size,
                                   const std::string& p_format,
                                   ScreenshotFormat p_pixel_format)
    : data(std::move(p_data)),
      frame_size(p_size),
      format(p_format),
      pixel_format(p_pixel_format) {}

Rasterizer::Screenshot::Screenshot(const Screenshot& other) = default;

Rasterizer::Screenshot::~Screenshot() = default;

}  // namespace flutter
