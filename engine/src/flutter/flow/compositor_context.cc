// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flow/compositor_context.h"

#include "base/logging.h"
#include "base/trace_event/trace_event.h"
#include "flow/layers/layer_tree.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace flow {

CompositorContext::CompositorContext() {
}

CompositorContext::~CompositorContext() {
}

void CompositorContext::Preroll(GrContext* gr_context, LayerTree* layer_tree) {
  TRACE_EVENT0("flutter", "CompositorContext::Preroll");
  engine_time_.SetLapTime(layer_tree->construction_time());
  Layer::PrerollContext context = {
    raster_cache_,
    gr_context,
    SkRect::MakeEmpty(),
  };
  layer_tree->root_layer()->Preroll(&context, SkMatrix());
}

sk_sp<SkPicture> CompositorContext::Record(const SkRect& bounds, Layer* layer) {
  TRACE_EVENT0("flutter", "CompositorContext::Record");
  SkRTreeFactory rtree_factory;
  uint32_t flags = SkPictureRecorder::kComputeSaveLayerInfo_RecordFlag;
  SkPictureRecorder recorder;
  Layer::PaintContext paint_context{
    *recorder.beginRecording(bounds, &rtree_factory, flags),
    frame_time_,
    engine_time_,
  };
  layer->Paint(paint_context);
  return recorder.finishRecordingAsPicture();
}

CompositorContext::Scope::Scope(CompositorContext& context)
  : context_(context) {
  context_.frame_time_.Start();
}

CompositorContext::Scope::~Scope() {
  context_.raster_cache_.SweepAfterFrame();
  context_.frame_time_.Stop();
}

void CompositorContext::OnGrContextDestroyed() {
  raster_cache_.Clear();
}

}  // namespace flow
