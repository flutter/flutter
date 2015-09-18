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
#include "sky/shell/gpu/picture_serializer.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_share_group.h"
#include "ui/gl/gl_surface.h"

// Set this value to 1 to serialize the layer tree to disk.
#define SERIALIZE_LAYER_TREE 0

namespace sky {
namespace shell {
namespace {

#if SERIALIZE_LAYER_TREE

void SketchySerializeLayerTree(const char* path,
                               compositor::LayerTree* layer_tree) {
  const auto& layers =
      static_cast<compositor::ContainerLayer*>(layer_tree->root_layer())
          ->layers();
  if (layers.empty())
    return;
  SerializePicture(
      path, static_cast<compositor::PictureLayer*>(layers[0].get())->picture());
}

#endif

}  // namespace

Rasterizer::Rasterizer()
    : share_group_(new gfx::GLShareGroup()),
      weak_factory_(this) {}

Rasterizer::~Rasterizer() {
}

base::WeakPtr<Rasterizer> Rasterizer::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void Rasterizer::OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget) {
  surface_ = gfx::GLSurface::CreateViewGLSurface(widget,
                                                 gfx::SurfaceConfiguration());
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

  EnsureGLContext();
  CHECK(context_->MakeCurrent(surface_.get()));
  EnsureGaneshSurface(surface_->GetBackingFrameBufferObject(), size);
  SkCanvas* canvas = ganesh_surface_->canvas();

  canvas->clear(SK_ColorBLACK);
  {
    auto frame = paint_context_.AcquireFrame(*canvas);
    layer_tree->root_layer()->Paint(frame);
  }
  canvas->flush();
  surface_->SwapBuffers();

#if SERIALIZE_LAYER_TREE
  SketchySerializeLayerTree("/data/data/org.domokit.sky.shell/cache/layer0.skp",
                            layer_tree.get());
#endif
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
