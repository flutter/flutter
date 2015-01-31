// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/gpu_driver.h"

#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_share_group.h"
#include "ui/gl/gl_surface.h"

namespace sky {
namespace shell {

GPUDriver::GPUDriver() : weak_factory_(this) {
}

GPUDriver::~GPUDriver() {
}

base::WeakPtr<GPUDriver> GPUDriver::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void GPUDriver::Init(gfx::AcceleratedWidget widget) {
  share_group_ = make_scoped_refptr(new gfx::GLShareGroup());

  surface_ = gfx::GLSurface::CreateViewGLSurface(widget);
  CHECK(surface_) << "GLSurface required.";

  context_ = gfx::GLContext::CreateGLContext(share_group_.get(), surface_.get(),
                                             gfx::PreferIntegratedGpu);
  CHECK(context_) << "GLContext required.";

  CHECK(context_->MakeCurrent(surface_.get()));

  glClearColor(0.0, 1.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT);

  surface_->SwapBuffers();
}

}  // namespace shell
}  // namespace sky
