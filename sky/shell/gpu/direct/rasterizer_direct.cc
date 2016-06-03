// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/gpu/direct/rasterizer_direct.h"

#include "base/trace_event/trace_event.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/shell/gpu/picture_serializer.h"
#include "sky/shell/shell.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_bindings_skia_in_process.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_share_group.h"
#include "ui/gl/gl_surface.h"

namespace sky {
namespace shell {

static const double kOneFrameDuration = 1e3 / 60.0;

std::unique_ptr<Rasterizer> Rasterizer::Create() {
  return std::unique_ptr<Rasterizer>(new RasterizerDirect());
}

RasterizerDirect::RasterizerDirect()
    : share_group_(new gfx::GLShareGroup()), binding_(this),
      weak_factory_(this) {
}

RasterizerDirect::~RasterizerDirect() {
  weak_factory_.InvalidateWeakPtrs();
  Shell::Shared().PurgeRasterizers();
}

base::WeakPtr<RasterizerDirect> RasterizerDirect::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

base::WeakPtr<Rasterizer> RasterizerDirect::GetWeakRasterizerPtr() {
  return GetWeakPtr();
}

void RasterizerDirect::ConnectToRasterizer(
    mojo::InterfaceRequest<rasterizer::Rasterizer> request) {
  binding_.Bind(request.Pass());

  Shell::Shared().AddRasterizer(GetWeakRasterizerPtr());
}

void RasterizerDirect::OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget,
                                                    base::WaitableEvent* did_draw) {
  gfx::SurfaceConfiguration config;
  config.stencil_bits = 8;
  surface_ = gfx::GLSurface::CreateViewGLSurface(widget, config);
  CHECK(surface_) << "GLSurface required.";
  // Eagerly create the GL context. For a while after the accelerated widget
  // is first available (after startup), the process is busy setting up dart
  // isolates. During this time, we are free to create the context. Thus
  // avoiding a delay when the first frame is painted.
  EnsureGLContext();
  CHECK(context_->MakeCurrent(surface_.get()));
  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  surface_->SwapBuffers();
  if (did_draw)
    did_draw->Signal();
}

void RasterizerDirect::Draw(uint64_t layer_tree_ptr,
                            const DrawCallback& callback) {
  TRACE_EVENT0("flutter", "RasterizerDirect::Draw");

  std::unique_ptr<flow::LayerTree> layer_tree(
      reinterpret_cast<flow::LayerTree*>(layer_tree_ptr));

  if (!surface_ || !layer_tree->root_layer()) {
    callback.Run();
    return;
  }

  gfx::Size size(layer_tree->frame_size().width(),
                 layer_tree->frame_size().height());

  if (surface_->GetSize() != size)
    surface_->Resize(size);

  // There is no way for the compositor to know how long the layer tree
  // construction took. Fortunately, the layer tree does. Grab that time
  // for instrumentation.
  compositor_context_.engine_time().SetLapTime(layer_tree->construction_time());

  {
    EnsureGLContext();
    CHECK(context_->MakeCurrent(surface_.get()));
    SkCanvas* canvas = ganesh_canvas_.GetCanvas(
      surface_->GetBackingFrameBufferObject(), layer_tree->frame_size());
    flow::CompositorContext::ScopedFrame frame =
        compositor_context_.AcquireFrame(ganesh_canvas_.gr_context(), *canvas);
    canvas->clear(SK_ColorBLACK);
    layer_tree->Raster(frame);
    canvas->flush();
    surface_->SwapBuffers();
  }

  // Trace to a file if necessary
  bool frameExceededThreshold = false;
  uint32_t thresholdInterval = layer_tree->rasterizer_tracing_threshold();
  if (thresholdInterval != 0 &&
      compositor_context_.frame_time().LastLap().InMillisecondsF() >
          thresholdInterval * kOneFrameDuration) {
    // While rendering the last frame, if we exceeded the tracing threshold
    // specified in the layer tree, we force a trace to disk.
    frameExceededThreshold = true;
  }

  const auto& tracingController = Shell::Shared().tracing_controller();

  if (frameExceededThreshold || tracingController.picture_tracing_enabled()) {
    base::FilePath path = tracingController.PictureTracingPathForCurrentTime();

    SkPictureRecorder recoder;
    recoder.beginRecording(SkRect::MakeWH(size.width(), size.height()));

    {
      auto frame = compositor_context_.AcquireFrame(
          nullptr, *recoder.getRecordingCanvas(), false);
      layer_tree->Raster(frame);
    }

    sk_sp<SkPicture> picture = recoder.finishRecordingAsPicture();
    SerializePicture(path, picture.get());
  }

  callback.Run();

  last_layer_tree_ = std::move(layer_tree);
}

void RasterizerDirect::OnOutputSurfaceDestroyed() {
  if (context_) {
    CHECK(context_->MakeCurrent(surface_.get()));
    compositor_context_.OnGrContextDestroyed();
    ganesh_canvas_.SetGrGLInterface(nullptr);
    context_ = nullptr;
  }
  CHECK(!ganesh_canvas_.IsValid());
  CHECK(!context_);
  surface_ = nullptr;
}

void RasterizerDirect::EnsureGLContext() {
  if (context_)
    return;
  context_ = gfx::GLContext::CreateGLContext(share_group_.get(), surface_.get(),
                                             gfx::PreferIntegratedGpu);
  CHECK(context_) << "GLContext required.";
  CHECK(context_->MakeCurrent(surface_.get()));
  gr_gl_interface_ = skia::AdoptRef(gfx::CreateInProcessSkiaGLBinding());
  ganesh_canvas_.SetGrGLInterface(gr_gl_interface_.get());
}

flow::LayerTree* RasterizerDirect::GetLastLayerTree() {
  return last_layer_tree_.get();
}

}  // namespace shell
}  // namespace sky
