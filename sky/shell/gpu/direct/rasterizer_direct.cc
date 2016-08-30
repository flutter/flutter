// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/gpu/direct/rasterizer_direct.h"

#include <string>
#include <utility>

#include "flutter/common/threads.h"
#include "flutter/glue/trace_event.h"
#include "flutter/sky/engine/wtf/PassRefPtr.h"
#include "flutter/sky/engine/wtf/RefPtr.h"
#include "flutter/sky/shell/gpu/picture_serializer.h"
#include "flutter/sky/shell/platform_view.h"
#include "flutter/sky/shell/shell.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace sky {
namespace shell {

RasterizerDirect::RasterizerDirect()
    : platform_view_(nullptr), weak_factory_(this) {
  auto weak_ptr = weak_factory_.GetWeakPtr();
  blink::Threads::Gpu()->PostTask(
      [weak_ptr]() { Shell::Shared().AddRasterizer(weak_ptr); });
}

RasterizerDirect::~RasterizerDirect() {
  weak_factory_.InvalidateWeakPtrs();
  Shell::Shared().PurgeRasterizers();
}

// Implementation of declaration in sky/shell/rasterizer.h.
std::unique_ptr<Rasterizer> Rasterizer::Create() {
  return std::unique_ptr<Rasterizer>(new RasterizerDirect());
}

// sky::shell::Rasterizer override.
ftl::WeakPtr<Rasterizer> RasterizerDirect::GetWeakRasterizerPtr() {
  return weak_factory_.GetWeakPtr();
}

// sky::shell::Rasterizer override.
void RasterizerDirect::Setup(
    PlatformView* platform_view,
    ftl::Closure continuation,
    ftl::AutoResetWaitableEvent* setup_completion_event) {
  CHECK(platform_view) << "Must be able to acquire the view.";

  // The context needs to be made current before the GrGL interface can be
  // setup.
  bool success = platform_view->ContextMakeCurrent();
  if (success) {
    success = ganesh_canvas_.SetupGrGLInterface();
    if (!success)
      LOG(ERROR) << "Could not create the GL interface";
  } else {
    LOG(ERROR) << "Could not make the context current for initial GL setup";
  }

  if (success) {
    platform_view_ = platform_view;
  } else {
    LOG(ERROR) << "WARNING: Flutter will be unable to render to the display";
  }

  continuation();

  setup_completion_event->Signal();
}

// sky::shell::Rasterizer override.
void RasterizerDirect::Teardown(
    ftl::AutoResetWaitableEvent* teardown_completion_event) {
  platform_view_ = nullptr;
  last_layer_tree_.reset();
  compositor_context_.OnGrContextDestroyed();
  teardown_completion_event->Signal();
}

// sky::shell::Rasterizer override.
flow::LayerTree* RasterizerDirect::GetLastLayerTree() {
  return last_layer_tree_.get();
}

void RasterizerDirect::Draw(
    ftl::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) {
  TRACE_EVENT0("flutter", "RasterizerDirect::Draw");

  if (platform_view_ == nullptr) {
    return;
  }

  flutter::Pipeline<flow::LayerTree>::Consumer consumer =
      std::bind(&RasterizerDirect::DoDraw, this, std::placeholders::_1);

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
    } break;
    default:
      break;
  }
}

void RasterizerDirect::DoDraw(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (layer_tree == nullptr) {
    return;
  }

  // There is no way for the compositor to know how long the layer tree
  // construction took. Fortunately, the layer tree does. Grab that time
  // for instrumentation.
  compositor_context_.engine_time().SetLapTime(layer_tree->construction_time());

  SkISize size = layer_tree->frame_size();
  if (platform_view_->GetSize() != size) {
    platform_view_->Resize(size);
  }

  if (!platform_view_->ContextMakeCurrent() || !layer_tree->root_layer()) {
    return;
  }

  {
    SkCanvas* canvas = ganesh_canvas_.GetCanvas(
        platform_view_->DefaultFramebuffer(), layer_tree->frame_size());
    flow::CompositorContext::ScopedFrame frame =
        compositor_context_.AcquireFrame(ganesh_canvas_.gr_context(), *canvas);
    canvas->clear(SK_ColorBLACK);
    layer_tree->Raster(frame);

    {
      TRACE_EVENT0("flutter", "SkCanvas::Flush");
      canvas->flush();
    }

    platform_view_->SwapBuffers();
  }

  // Trace to a file if necessary
  static const double kOneFrameDuration = 1e3 / 60.0;
  bool frameExceededThreshold = false;
  uint32_t thresholdInterval = layer_tree->rasterizer_tracing_threshold();
  if (thresholdInterval != 0 &&
      compositor_context_.frame_time().LastLap().ToMillisecondsF() >
          thresholdInterval * kOneFrameDuration) {
    // While rendering the last frame, if we exceeded the tracing threshold
    // specified in the layer tree, we force a trace to disk.
    frameExceededThreshold = true;
  }

  const auto& tracingController = Shell::Shared().tracing_controller();

  if (frameExceededThreshold || tracingController.picture_tracing_enabled()) {
    std::string path = tracingController.PictureTracingPathForCurrentTime();
    LOG(INFO) << "Frame threshold exceeded. Capturing SKP to " << path;

    SkPictureRecorder recorder;
    recorder.beginRecording(SkRect::MakeWH(size.width(), size.height()));

    {
      auto frame = compositor_context_.AcquireFrame(
          nullptr, *recorder.getRecordingCanvas(), false);
      layer_tree->Raster(frame, true);
    }

    sk_sp<SkPicture> picture = recorder.finishRecordingAsPicture();
    SerializePicture(path, picture.get());
  }

  last_layer_tree_ = std::move(layer_tree);
}

}  // namespace shell
}  // namespace sky
