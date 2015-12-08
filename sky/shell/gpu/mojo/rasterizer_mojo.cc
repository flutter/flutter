// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/gpu/mojo/rasterizer_mojo.h"

#include "base/trace_event/trace_event.h"
#include "mojo/public/c/gpu/MGL/mgl.h"
#include "mojo/public/c/gpu/MGL/mgl_onscreen.h"
#include "mojo/skia/gl_bindings_skia.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace sky {
namespace shell {
namespace {

void ContextLostThunk(void* closure) {
  static_cast<RasterizerMojo*>(closure)->OnContextLost();
}

}  // namespace

scoped_ptr<Rasterizer> Rasterizer::Create() {
  return make_scoped_ptr(new RasterizerMojo());
}

RasterizerMojo::RasterizerMojo() : binding_(this), weak_factory_(this) {
}

RasterizerMojo::~RasterizerMojo() {
}

base::WeakPtr<RasterizerMojo> RasterizerMojo::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

base::WeakPtr<Rasterizer> RasterizerMojo::GetWeakRasterizerPtr() {
  return GetWeakPtr();
}

void RasterizerMojo::ConnectToRasterizer (
    mojo::InterfaceRequest<rasterizer::Rasterizer> request ) {
  binding_.Bind(request.Pass());
}

void RasterizerMojo::Draw(uint64_t layer_tree_ptr,
                          const DrawCallback& callback) {
  TRACE_EVENT0("flutter", "RasterizerMojo::Draw");
  if (!MGLGetCurrentContext()) {
    callback.Run();
    return;
  }

  scoped_ptr<compositor::LayerTree> layer_tree(
      reinterpret_cast<compositor::LayerTree*>(layer_tree_ptr));

  if (layer_tree->frame_size().isEmpty()) {
    callback.Run();
    return;
  }

  MGLResizeSurface(layer_tree->frame_size().width(),
                   layer_tree->frame_size().height());
  SkCanvas* canvas = ganesh_canvas_.GetCanvas(0, layer_tree->frame_size());
  sky::compositor::PaintContext::ScopedFrame frame =
      paint_context_.AcquireFrame(*canvas);
  canvas->clear(SK_ColorBLACK);
  layer_tree->root_layer()->Paint(frame);
  canvas->flush();
  MGLSwapBuffers();
  callback.Run();
}

void RasterizerMojo::OnContextProviderAvailable(
    mojo::InterfacePtrInfo<mojo::ContextProvider> context_provider) {
  context_provider_ = mojo::MakeProxy(context_provider.Pass());
  context_provider_->Create(nullptr,
    base::Bind(&RasterizerMojo::OnContextCreated, base::Unretained(this)));
}

void RasterizerMojo::OnContextCreated(mojo::CommandBufferPtr command_buffer) {
  context_ = MGLCreateContext(
      MGL_API_VERSION_GLES2,
      command_buffer.PassInterface().PassHandle().release().value(),
      MGL_NO_CONTEXT, &ContextLostThunk, this,
      mojo::Environment::GetDefaultAsyncWaiter());
  MGLMakeCurrent(context_);
  if (!gr_gl_interface_)
    gr_gl_interface_ = skia::AdoptRef(skia_bindings::CreateMojoSkiaGLBinding());
  ganesh_canvas_.SetGrGLInterface(gr_gl_interface_.get());
}

void RasterizerMojo::OnContextLost() {
  ganesh_canvas_.SetGrGLInterface(nullptr);
  MGLDestroyContext(context_);
  context_ = nullptr;
  context_provider_->Create(nullptr,
    base::Bind(&RasterizerMojo::OnContextCreated, base::Unretained(this)));
}

}  // namespace shell
}  // namespace sky
