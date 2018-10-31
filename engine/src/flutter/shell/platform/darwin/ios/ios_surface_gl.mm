// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_surface_gl.h"

#include "flutter/fml/trace_event.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"

namespace shell {

IOSSurfaceGL::IOSSurfaceGL(fml::scoped_nsobject<CAEAGLLayer> layer,
                           FlutterPlatformViewsController& platform_views_controller)
    : IOSSurface(platform_views_controller), context_(std::move(layer)) {}

IOSSurfaceGL::~IOSSurfaceGL() = default;

bool IOSSurfaceGL::IsValid() const {
  return context_.IsValid();
}

bool IOSSurfaceGL::ResourceContextMakeCurrent() {
  return IsValid() ? context_.ResourceMakeCurrent() : false;
}

void IOSSurfaceGL::UpdateStorageSizeIfNecessary() {
  if (IsValid()) {
    context_.UpdateStorageSizeIfNecessary();
  }
}

std::unique_ptr<Surface> IOSSurfaceGL::CreateGPUSurface() {
  return std::make_unique<GPUSurfaceGL>(this);
}

intptr_t IOSSurfaceGL::GLContextFBO() const {
  return IsValid() ? context_.framebuffer() : GL_NONE;
}

bool IOSSurfaceGL::UseOffscreenSurface() const {
  // The onscreen surface wraps a GL renderbuffer, which is extremely slow to read.
  // Certain filter effects require making a copy of the current destination, so we
  // always render to an offscreen surface, which will be much quicker to read/copy.
  return true;
}

bool IOSSurfaceGL::GLContextMakeCurrent() {
  return IsValid() ? context_.MakeCurrent() : false;
}

bool IOSSurfaceGL::GLContextClearCurrent() {
  [EAGLContext setCurrentContext:nil];
  return true;
}

bool IOSSurfaceGL::GLContextPresent() {
  TRACE_EVENT0("flutter", "IOSSurfaceGL::GLContextPresent");
  if (!IsValid() || !context_.PresentRenderBuffer()) {
    return false;
  }

  GetPlatformViewsController().Present();
  return true;
}

flow::ExternalViewEmbedder* IOSSurfaceGL::GetExternalViewEmbedder() {
  return this;
}

void IOSSurfaceGL::CompositeEmbeddedView(int view_id, const flow::EmbeddedViewParams& params) {
  GetPlatformViewsController().CompositeEmbeddedView(view_id, params);
}

}  // namespace shell
