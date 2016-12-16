// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu_rasterizer.h"

#include <string>
#include <utility>

#include "flutter/common/threads.h"
#include "flutter/glue/trace_event.h"
#include "flutter/shell/common/picture_serializer.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/shell.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace shell {

GPURasterizer::GPURasterizer() : weak_factory_(this) {
  auto weak_ptr = weak_factory_.GetWeakPtr();
  blink::Threads::Gpu()->PostTask(
      [weak_ptr]() { Shell::Shared().AddRasterizer(weak_ptr); });
}

GPURasterizer::~GPURasterizer() {
  weak_factory_.InvalidateWeakPtrs();
  Shell::Shared().PurgeRasterizers();
}

ftl::WeakPtr<Rasterizer> GPURasterizer::GetWeakRasterizerPtr() {
  return weak_factory_.GetWeakPtr();
}

void GPURasterizer::Setup(std::unique_ptr<Surface> surface,
                          ftl::Closure continuation,
                          ftl::AutoResetWaitableEvent* setup_completion_event) {
  surface_ = std::move(surface);

  continuation();

  setup_completion_event->Signal();
}

void GPURasterizer::Clear(SkColor color, const SkISize& size) {
  if (surface_ == nullptr) {
    return;
  }

  auto frame = surface_->AcquireFrame(size);

  if (frame == nullptr) {
    return;
  }

  SkCanvas* canvas = frame->SkiaCanvas();

  if (canvas == nullptr) {
    return;
  }

  canvas->clear(color);

  frame->Submit();
}

void GPURasterizer::Teardown(
    ftl::AutoResetWaitableEvent* teardown_completion_event) {
  if (surface_) {
    surface_->Teardown();
    surface_.reset();
  }
  last_layer_tree_.reset();
  compositor_context_.OnGrContextDestroyed();
  teardown_completion_event->Signal();
}

flow::LayerTree* GPURasterizer::GetLastLayerTree() {
  return last_layer_tree_.get();
}

void GPURasterizer::Draw(
    ftl::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) {
  TRACE_EVENT0("flutter", "GPURasterizer::Draw");

  flutter::Pipeline<flow::LayerTree>::Consumer consumer =
      std::bind(&GPURasterizer::DoDraw, this, std::placeholders::_1);

  // Consume as many pipeline items as possible. But yield the event loop
  // between successive tries.
  switch (pipeline->Consume(consumer)) {
    case flutter::PipelineConsumeResult::MoreAvailable: {
      auto weak_this = weak_factory_.GetWeakPtr();
      blink::Threads::Gpu()->PostTask([weak_this, pipeline]() {
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

void GPURasterizer::DoDraw(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (!layer_tree || !surface_) {
    return;
  }

  // There is no way for the compositor to know how long the layer tree
  // construction took. Fortunately, the layer tree does. Grab that time
  // for instrumentation.
  compositor_context_.engine_time().SetLapTime(layer_tree->construction_time());

  DrawToSurface(*layer_tree);

  DrawToTraceIfNecessary(*layer_tree);

  last_layer_tree_ = std::move(layer_tree);
}

void GPURasterizer::DrawToSurface(flow::LayerTree& layer_tree) {
  auto frame = surface_->AcquireFrame(layer_tree.frame_size());

  if (frame == nullptr) {
    return;
  }

  auto canvas = frame->SkiaCanvas();

  if (canvas == nullptr) {
    return;
  }

  auto compositor_frame =
      compositor_context_.AcquireFrame(surface_->GetContext(), canvas);

  canvas->clear(SK_ColorBLACK);

  layer_tree.Raster(compositor_frame);

  frame->Submit();
}

bool GPURasterizer::ShouldDrawToTrace(flow::LayerTree& layer_tree) {
  if (Shell::Shared().tracing_controller().picture_tracing_enabled()) {
    // Picture tracing is unconditionally enabled for all frames by the tracing
    // controller.
    return true;
  }

  const uint32_t threshold_interval = layer_tree.rasterizer_tracing_threshold();

  if (threshold_interval == 0) {
    // An interval of zero means tracing is disabled.
    return false;
  }

  return compositor_context_.frame_time().LastLap().ToMillisecondsF() >
         threshold_interval * 1e3 / 60.0;
}

void GPURasterizer::DrawToTraceIfNecessary(flow::LayerTree& layer_tree) {
  if (!ShouldDrawToTrace(layer_tree)) {
    return;
  }

  auto& tracing_controller = Shell::Shared().tracing_controller();

  std::string path = tracing_controller.PictureTracingPathForCurrentTime();
  LOG(INFO) << "Frame threshold exceeded. Capturing SKP to " << path;

  SkPictureRecorder recorder;

  recorder.beginRecording(layer_tree.frame_size().width(),
                          layer_tree.frame_size().height());

  auto compositor_frame = compositor_context_.AcquireFrame(
      nullptr, recorder.getRecordingCanvas(), false);
  layer_tree.Raster(compositor_frame, true /* ignore raster cache */);

  sk_sp<SkPicture> picture = recorder.finishRecordingAsPicture();

  SerializePicture(path, picture.get());
}

}  // namespace shell
