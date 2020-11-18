// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "compositor_context.h"

#include <algorithm>
#include <vector>

#include "flutter/flow/layers/layer_tree.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter_runner {

class ScopedFrame final : public flutter::CompositorContext::ScopedFrame {
 public:
  ScopedFrame(CompositorContext& context,
              GrDirectContext* gr_context,
              SkCanvas* canvas,
              flutter::ExternalViewEmbedder* view_embedder,
              const SkMatrix& root_surface_transformation,
              bool instrumentation_enabled,
              bool surface_supports_readback,
              fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger,
              SessionConnection& session_connection,
              VulkanSurfaceProducer& surface_producer,
              std::shared_ptr<flutter::SceneUpdateContext> scene_update_context)
      : flutter::CompositorContext::ScopedFrame(context,
                                                surface_producer.gr_context(),
                                                canvas,
                                                view_embedder,
                                                root_surface_transformation,
                                                instrumentation_enabled,
                                                surface_supports_readback,
                                                raster_thread_merger),
        session_connection_(session_connection),
        surface_producer_(surface_producer),
        scene_update_context_(scene_update_context) {}

 private:
  SessionConnection& session_connection_;
  VulkanSurfaceProducer& surface_producer_;
  std::shared_ptr<flutter::SceneUpdateContext> scene_update_context_;

  flutter::RasterStatus Raster(flutter::LayerTree& layer_tree,
                               bool ignore_raster_cache) override {
    std::vector<flutter::SceneUpdateContext::PaintTask> frame_paint_tasks;
    std::vector<std::unique_ptr<SurfaceProducerSurface>> frame_surfaces;

    {
      // Preroll the Flutter layer tree. This allows Flutter to perform
      // pre-paint optimizations.
      TRACE_EVENT0("flutter", "Preroll");
      layer_tree.Preroll(*this, ignore_raster_cache);
    }

    {
      // Traverse the Flutter layer tree so that the necessary session ops to
      // represent the frame are enqueued in the underlying session.
      TRACE_EVENT0("flutter", "UpdateScene");
      layer_tree.UpdateScene(scene_update_context_);
    }

    {
      // Flush all pending session ops: create surfaces and enqueue session
      // Image ops for the frame's paint tasks, then Present.
      TRACE_EVENT0("flutter", "SessionPresent");
      frame_paint_tasks = scene_update_context_->GetPaintTasks();

      const SkISize& frame_size = layer_tree.frame_size();
      for (auto& task : frame_paint_tasks) {
        // Clamp the logical size to the logical frame size in order to avoid
        // huge surfaces.
        const SkISize logical_size = SkISize::Make(
            std::clamp(task.scale_x * task.paint_bounds.width(), 0.f,
                       static_cast<float>(frame_size.width())),
            std::clamp(task.scale_y * task.paint_bounds.height(), 0.f,
                       static_cast<float>(frame_size.height())));

        SkISize physical_size = SkISize::Make(
            layer_tree.device_pixel_ratio() * logical_size.width(),
            layer_tree.device_pixel_ratio() * logical_size.height());
        if (physical_size.width() == 0 || physical_size.height() == 0) {
          frame_surfaces.emplace_back(nullptr);
          continue;
        }

        std::unique_ptr<SurfaceProducerSurface> surface =
            surface_producer_.ProduceSurface(physical_size);
        if (!surface) {
          FML_LOG(ERROR)
              << "Could not acquire a surface from the surface producer "
                 "of size: "
              << physical_size.width() << "x" << physical_size.height();
        } else {
          task.material.SetTexture(*(surface->GetImage()));
        }

        frame_surfaces.emplace_back(std::move(surface));
      }

      session_connection_.Present();
    }

    {
      // Execute paint tasks in parallel with Scenic's side of the Present, then
      // signal fences.
      TRACE_EVENT0("flutter", "ExecutePaintTasks");
      size_t surface_index = 0;
      for (auto& task : frame_paint_tasks) {
        std::unique_ptr<SurfaceProducerSurface>& task_surface =
            frame_surfaces[surface_index++];
        if (!task_surface) {
          continue;
        }

        SkCanvas* canvas = task_surface->GetSkiaSurface()->getCanvas();
        flutter::Layer::PaintContext paint_context = {
            canvas,
            canvas,
            gr_context(),
            nullptr,
            context().raster_time(),
            context().ui_time(),
            context().texture_registry(),
            &context().raster_cache(),
            false,
            layer_tree.device_pixel_ratio()};
        canvas->restoreToCount(1);
        canvas->save();
        canvas->clear(task.background_color);
        canvas->scale(layer_tree.device_pixel_ratio() * task.scale_x,
                      layer_tree.device_pixel_ratio() * task.scale_y);
        canvas->translate(-task.paint_bounds.left(), -task.paint_bounds.top());
        for (flutter::Layer* layer : task.layers) {
          layer->Paint(paint_context);
        }
      }

      // Tell the surface producer that a present has occurred so it can perform
      // book-keeping on buffer caches.
      surface_producer_.OnSurfacesPresented(std::move(frame_surfaces));
    }

    return flutter::RasterStatus::kSuccess;
  }

  FML_DISALLOW_COPY_AND_ASSIGN(ScopedFrame);
};

CompositorContext::CompositorContext(
    SessionConnection& session_connection,
    VulkanSurfaceProducer& surface_producer,
    std::shared_ptr<flutter::SceneUpdateContext> scene_update_context)
    : session_connection_(session_connection),
      surface_producer_(surface_producer),
      scene_update_context_(scene_update_context) {
  SkISize size = SkISize::Make(1024, 600);
  skp_warmup_surface_ = surface_producer_.ProduceOffscreenSurface(size);
  if (!skp_warmup_surface_) {
    FML_LOG(ERROR) << "SkSurface::MakeRenderTarget returned null";
  }
}

CompositorContext::~CompositorContext() = default;

std::unique_ptr<flutter::CompositorContext::ScopedFrame>
CompositorContext::AcquireFrame(
    GrDirectContext* gr_context,
    SkCanvas* canvas,
    flutter::ExternalViewEmbedder* view_embedder,
    const SkMatrix& root_surface_transformation,
    bool instrumentation_enabled,
    bool surface_supports_readback,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  return std::make_unique<flutter_runner::ScopedFrame>(
      *this, gr_context, canvas, view_embedder, root_surface_transformation,
      instrumentation_enabled, surface_supports_readback, raster_thread_merger,
      session_connection_, surface_producer_, scene_update_context_);
}

void CompositorContext::WarmupSkp(const sk_sp<SkPicture> picture) {
  skp_warmup_surface_->getCanvas()->drawPicture(picture);
  surface_producer_.gr_context()->flush();
}

}  // namespace flutter_runner
