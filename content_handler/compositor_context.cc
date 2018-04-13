// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "compositor_context.h"

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/glue/trace_event.h"

namespace flutter {

class ScopedFrame final : public flow::CompositorContext::ScopedFrame {
 public:
  ScopedFrame(flow::CompositorContext& context,
              bool instrumentation_enabled,
              SessionConnection& session_connection)
      : flow::CompositorContext::ScopedFrame(context,
                                             nullptr,
                                             nullptr,
                                             instrumentation_enabled),
        session_connection_(session_connection) {}

 private:
  SessionConnection& session_connection_;

  bool Raster(flow::LayerTree& layer_tree, bool ignore_raster_cache) override {
    if (!session_connection_.has_metrics()) {
      return true;
    }

    {
      // Preroll the Flutter layer tree. This allows Flutter to perform
      // pre-paint optimizations.
      TRACE_EVENT0("flutter", "Preroll");
      layer_tree.Preroll(*this, true /* ignore raster cache */);
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
      session_connection_.Present(*this);
    }

    return true;
  }

  FXL_DISALLOW_COPY_AND_ASSIGN(ScopedFrame);
};

CompositorContext::CompositorContext(
    const ui::ScenicPtr& scenic,
    std::string debug_label,
    zx::eventpair import_token,
    OnMetricsUpdate session_metrics_did_change_callback,
    fxl::Closure session_error_callback)
    : debug_label_(std::move(debug_label)),
      session_connection_(scenic,
                          debug_label_,
                          std::move(import_token),
                          std::move(session_metrics_did_change_callback),
                          std::move(session_error_callback)) {}

CompositorContext::~CompositorContext() = default;

std::unique_ptr<flow::CompositorContext::ScopedFrame>
CompositorContext::AcquireFrame(GrContext* gr_context,
                                SkCanvas* canvas,
                                bool instrumentation_enabled) {
  // TODO: The AcquireFrame interface is too broad and must be refactored to get
  // rid of the context and canvas arguments as those seem to be only used for
  // colorspace correctness purposes on the mobile shells.
  return std::make_unique<flutter::ScopedFrame>(*this,                    //
                                                instrumentation_enabled,  //
                                                session_connection_       //
  );
}

}  // namespace flutter
