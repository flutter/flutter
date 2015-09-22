// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/gpu/rasterizer.h"

#include "base/trace_event/trace_event.h"
#include "sky/compositor/container_layer.h"
#include "sky/compositor/layer.h"
#include "sky/compositor/paint_context.h"
#include "sky/compositor/picture_layer.h"
#include "sky/shell/gpu/ganesh_context.h"
#include "sky/shell/gpu/ganesh_surface.h"
#include "sky/shell/shell.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_share_group.h"
#include "ui/gl/gl_surface.h"
#include "mojo/public/cpp/system/data_pipe.h"

namespace sky {
namespace shell {

Rasterizer::Rasterizer()
    : share_group_(new gfx::GLShareGroup()), weak_factory_(this) {
}

Rasterizer::~Rasterizer() {
}

base::WeakPtr<Rasterizer> Rasterizer::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void Rasterizer::OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget) {
  surface_ =
      gfx::GLSurface::CreateViewGLSurface(widget, gfx::SurfaceConfiguration());
  CHECK(surface_) << "GLSurface required.";
}

void Rasterizer::Draw(scoped_ptr<compositor::LayerTree> layer_tree) {
  TRACE_EVENT0("sky", "Rasterizer::Draw");

  if (!surface_)
    return;

  gfx::Size size(layer_tree->frame_size().width(),
                 layer_tree->frame_size().height());

  if (surface_->GetSize() != size)
    surface_->Resize(size);

  // Use the canvas from the Ganesh Surface to render the current frame into

  EnsureGLContext();
  CHECK(context_->MakeCurrent(surface_.get()));
  EnsureGaneshSurface(surface_->GetBackingFrameBufferObject(), size);
  SkCanvas* canvas = ganesh_surface_->canvas();

  canvas->clear(SK_ColorBLACK);
  {
    sky::compositor::PaintContext::ScopedFrame frame =
        paint_context_.AcquireFrame(*canvas);
    layer_tree->root_layer()->Paint(frame);
  }
  canvas->flush();
  surface_->SwapBuffers();

  // Optionally, if the user has specified tracing the current scene to a file,
  // acquire another frame and draw into it to obtain an SkPicture to serialize

  auto options = Shell::Shared().tracing_controller().picture_tracing_options();
  if (options.first) {
    sky::compositor::PaintContext::ScopedFrame to_file_frame =
        paint_context_.AcquireFrame(options.second, size);
    layer_tree->root_layer()->Paint(to_file_frame);
  }
}

void Rasterizer::OnOutputSurfaceDestroyed() {
  if (context_) {
    CHECK(context_->MakeCurrent(surface_.get()));
    ganesh_surface_.reset();
    ganesh_context_.reset();
    context_ = nullptr;
  }
  CHECK(!ganesh_surface_);
  CHECK(!ganesh_context_);
  CHECK(!context_);
  surface_ = nullptr;
}

void Rasterizer::EnsureGLContext() {
  if (context_)
    return;
  context_ = gfx::GLContext::CreateGLContext(share_group_.get(), surface_.get(),
                                             gfx::PreferIntegratedGpu);
  CHECK(context_) << "GLContext required.";
  CHECK(context_->MakeCurrent(surface_.get()));
  ganesh_context_.reset(new GaneshContext(context_.get()));
}

void Rasterizer::EnsureGaneshSurface(intptr_t window_fbo,
                                     const gfx::Size& size) {
  if (!ganesh_surface_ || ganesh_surface_->size() != size)
    ganesh_surface_.reset(
        new GaneshSurface(window_fbo, ganesh_context_.get(), size));
}

}  // namespace shell
}  // namespace sky
