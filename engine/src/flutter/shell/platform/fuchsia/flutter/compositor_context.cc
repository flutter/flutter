// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "compositor_context.h"

#include "flutter/flow/layers/layer_tree.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter_runner {

class ScopedFrame final : public flutter::CompositorContext::ScopedFrame {
 public:
  ScopedFrame(flutter::CompositorContext& context,
              const SkMatrix& root_surface_transformation,
              flutter::ExternalViewEmbedder* view_embedder,
              bool instrumentation_enabled,
              SessionConnection& session_connection)
      : flutter::CompositorContext::ScopedFrame(
            context,
            session_connection.vulkan_surface_producer()->gr_context(),
            nullptr,
            view_embedder,
            root_surface_transformation,
            instrumentation_enabled,
            true,
            nullptr),
        session_connection_(session_connection) {}

 private:
  SessionConnection& session_connection_;

  flutter::RasterStatus Raster(flutter::LayerTree& layer_tree,
                               bool ignore_raster_cache) override {
    if (!session_connection_.has_metrics()) {
      return flutter::RasterStatus::kSuccess;
    }

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
      layer_tree.UpdateScene(session_connection_.scene_update_context(),
                             session_connection_.root_node());
    }

    {
      // Flush all pending session ops.
      TRACE_EVENT0("flutter", "SessionPresent");

      session_connection_.Present(this);
    }

    return flutter::RasterStatus::kSuccess;
  }

  FML_DISALLOW_COPY_AND_ASSIGN(ScopedFrame);
};

CompositorContext::CompositorContext(
    std::string debug_label,
    fuchsia::ui::views::ViewToken view_token,
    scenic::ViewRefPair view_ref_pair,
    fidl::InterfaceHandle<fuchsia::ui::scenic::Session> session,
    fml::closure session_error_callback,
    zx_handle_t vsync_event_handle)
    : debug_label_(std::move(debug_label)),
      session_connection_(
          debug_label_,
          std::move(view_token),
          std::move(view_ref_pair),
          std::move(session),
          session_error_callback,
          [](auto) {},
          vsync_event_handle) {}

void CompositorContext::OnSessionMetricsDidChange(
    const fuchsia::ui::gfx::Metrics& metrics) {
  session_connection_.set_metrics(metrics);
}

void CompositorContext::OnSessionSizeChangeHint(float width_change_factor,
                                                float height_change_factor) {
  session_connection_.OnSessionSizeChangeHint(width_change_factor,
                                              height_change_factor);
}

void CompositorContext::OnWireframeEnabled(bool enabled) {
  session_connection_.set_enable_wireframe(enabled);
}

void CompositorContext::OnCreateView(int64_t view_id,
                                     bool hit_testable,
                                     bool focusable) {
  session_connection_.scene_update_context().CreateView(view_id, hit_testable,
                                                        focusable);
}

void CompositorContext::OnDestroyView(int64_t view_id) {
  session_connection_.scene_update_context().DestroyView(view_id);
}

CompositorContext::~CompositorContext() {
  OnGrContextDestroyed();
}

std::unique_ptr<flutter::CompositorContext::ScopedFrame>
CompositorContext::AcquireFrame(
    GrDirectContext* gr_context,
    SkCanvas* canvas,
    flutter::ExternalViewEmbedder* view_embedder,
    const SkMatrix& root_surface_transformation,
    bool instrumentation_enabled,
    bool surface_supports_readback,
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  // TODO: The AcquireFrame interface is too broad and must be refactored to get
  // rid of the context and canvas arguments as those seem to be only used for
  // colorspace correctness purposes on the mobile shells.
  return std::make_unique<flutter_runner::ScopedFrame>(
      *this,                        //
      root_surface_transformation,  //
      view_embedder,
      instrumentation_enabled,  //
      session_connection_       //
  );
}

}  // namespace flutter_runner
