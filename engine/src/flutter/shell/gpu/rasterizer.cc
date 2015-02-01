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

Rasterizer::Rasterizer() : weak_factory_(this) {
}

Rasterizer::~Rasterizer() {
}

base::WeakPtr<Rasterizer> Rasterizer::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void Rasterizer::Init(gfx::AcceleratedWidget widget) {
  share_group_ = make_scoped_refptr(new gfx::GLShareGroup());
  surface_ = gfx::GLSurface::CreateViewGLSurface(widget);
  CHECK(surface_) << "GLSurface required.";
  CHECK(CreateGLContext()) << "GLContext required.";
}

void Rasterizer::Draw(skia::RefPtr<SkPicture> picture) {
  // TODO(abarth): We should handle losing the GL context.
  CHECK(context_->MakeCurrent(surface_.get()));
  EnsureGaneshSurface(GetSize(picture.get()));

  SkCanvas* canvas = ganesh_surface_->canvas();
  canvas->drawPicture(picture.get());
  canvas->flush();

  surface_->SwapBuffers();
}

bool Rasterizer::CreateGLContext() {
  context_ = gfx::GLContext::CreateGLContext(share_group_.get(), surface_.get(),
                                             gfx::PreferIntegratedGpu);
  if (!context_)
    return false;
  ganesh_context_.reset(new GaneshContext(context_.get()));
  return true;
}

void Rasterizer::EnsureGaneshSurface(const gfx::Size& size) {
  if (!ganesh_surface_ || ganesh_surface_->size() != size)
    ganesh_surface_.reset(new GaneshSurface(ganesh_context_.get(), size));
}

}  // namespace shell
}  // namespace sky
