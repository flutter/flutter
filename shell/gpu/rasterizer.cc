// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/gpu/rasterizer.h"

#include "sky/shell/gpu/ganesh_context.h"
#include "sky/shell/gpu/ganesh_surface.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_share_group.h"
#include "ui/gl/gl_surface.h"

namespace sky {
namespace shell {
namespace {

gfx::Size GetSize(SkPicture* picture) {
  const SkRect& rect = picture->cullRect();
  return gfx::Size(rect.width(), rect.height());
}

}  // namespace

Rasterizer::Rasterizer()
    : share_group_(new gfx::GLShareGroup()), weak_factory_(this) {
}

Rasterizer::~Rasterizer() {
}

base::WeakPtr<Rasterizer> Rasterizer::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void Rasterizer::OnAcceleratedWidgetAvailable(gfx::AcceleratedWidget widget) {
  surface_ = gfx::GLSurface::CreateViewGLSurface(widget);
  CHECK(surface_) << "GLSurface required.";
}

void Rasterizer::Draw(skia::RefPtr<SkPicture> picture) {
  if (!surface_)
    return;

  gfx::Size size = GetSize(picture.get());
  if (size.IsEmpty())
    return;

  EnsureGLContext();
  CHECK(context_->MakeCurrent(surface_.get()));
  EnsureGaneshSurface(size);

  SkCanvas* canvas = ganesh_surface_->canvas();
  canvas->drawPicture(picture.get());
  canvas->flush();

  surface_->SwapBuffers();
}

void Rasterizer::OnOutputSurfaceDestroyed() {
  ganesh_surface_.reset();
  ganesh_context_.reset();
  context_ = nullptr;
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

void Rasterizer::EnsureGaneshSurface(const gfx::Size& size) {
  if (!ganesh_surface_ || ganesh_surface_->size() != size)
    ganesh_surface_.reset(new GaneshSurface(ganesh_context_.get(), size));
}

}  // namespace shell
}  // namespace sky
