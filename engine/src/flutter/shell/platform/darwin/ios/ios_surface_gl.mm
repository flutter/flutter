// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_surface_gl.h"

#include "flutter/fml/trace_event.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"

namespace flutter {

IOSSurfaceGL::IOSSurfaceGL(std::shared_ptr<IOSGLContext> context,
                           fml::scoped_nsobject<CAEAGLLayer> layer,
                           FlutterPlatformViewsController* platform_views_controller)
    : IOSSurface(platform_views_controller), context_(context) {
  render_target_ = context_->CreateRenderTarget(std::move(layer));
}

IOSSurfaceGL::IOSSurfaceGL(fml::scoped_nsobject<CAEAGLLayer> layer,
                           std::shared_ptr<IOSGLContext> context)
    : IOSSurface(nullptr), context_(context) {
  render_target_ = context_->CreateRenderTarget(std::move(layer));
}

IOSSurfaceGL::~IOSSurfaceGL() = default;

bool IOSSurfaceGL::IsValid() const {
  return render_target_->IsValid();
}

bool IOSSurfaceGL::ResourceContextMakeCurrent() {
  return context_->ResourceMakeCurrent();
}

void IOSSurfaceGL::UpdateStorageSizeIfNecessary() {
  if (IsValid()) {
    render_target_->UpdateStorageSizeIfNecessary();
  }
}

std::unique_ptr<Surface> IOSSurfaceGL::CreateGPUSurface(GrContext* gr_context) {
  if (gr_context) {
    return std::make_unique<GPUSurfaceGL>(sk_ref_sp(gr_context), this, true);
  }
  return std::make_unique<GPUSurfaceGL>(this, true);
}

intptr_t IOSSurfaceGL::GLContextFBO() const {
  return IsValid() ? render_target_->framebuffer() : GL_NONE;
}

bool IOSSurfaceGL::UseOffscreenSurface() const {
  // The onscreen surface wraps a GL renderbuffer, which is extremely slow to read.
  // Certain filter effects require making a copy of the current destination, so we
  // always render to an offscreen surface, which will be much quicker to read/copy.
  return true;
}

bool IOSSurfaceGL::GLContextMakeCurrent() {
  if (!IsValid()) {
    return false;
  }
  return render_target_->UpdateStorageSizeIfNecessary() && context_->MakeCurrent();
}

bool IOSSurfaceGL::GLContextClearCurrent() {
  [EAGLContext setCurrentContext:nil];
  return true;
}

bool IOSSurfaceGL::GLContextPresent() {
  TRACE_EVENT0("flutter", "IOSSurfaceGL::GLContextPresent");
  return IsValid() && render_target_->PresentRenderBuffer();
}

// |ExternalViewEmbedder|
sk_sp<SkSurface> IOSSurfaceGL::GetRootSurface() {
  // On iOS, the root surface is created from the on-screen render target. Only the surfaces for the
  // various overlays are controlled by this class.
  return nullptr;
}

// |ExternalViewEmbedder|
flutter::ExternalViewEmbedder* IOSSurfaceGL::GetExternalViewEmbedder() {
  if (IsIosEmbeddedViewsPreviewEnabled()) {
    return this;
  } else {
    return nullptr;
  }
}

// |ExternalViewEmbedder|
void IOSSurfaceGL::CancelFrame() {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  platform_views_controller->CancelFrame();
  // Committing the current transaction as |BeginFrame| will create a nested
  // CATransaction otherwise.
  [CATransaction commit];
}

// |ExternalViewEmbedder|
void IOSSurfaceGL::BeginFrame(SkISize frame_size, GrContext* context) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  platform_views_controller->SetFrameSize(frame_size);
  [CATransaction begin];
}

// |ExternalViewEmbedder|
void IOSSurfaceGL::PrerollCompositeEmbeddedView(
    int view_id,
    std::unique_ptr<flutter::EmbeddedViewParams> params) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  platform_views_controller->PrerollCompositeEmbeddedView(view_id, std::move(params));
}

// |ExternalViewEmbedder|
PostPrerollResult IOSSurfaceGL::PostPrerollAction(
    fml::RefPtr<fml::GpuThreadMerger> gpu_thread_merger) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  return platform_views_controller->PostPrerollAction(gpu_thread_merger);
}

// |ExternalViewEmbedder|
std::vector<SkCanvas*> IOSSurfaceGL::GetCurrentCanvases() {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  return platform_views_controller->GetCurrentCanvases();
}

// |ExternalViewEmbedder|
SkCanvas* IOSSurfaceGL::CompositeEmbeddedView(int view_id) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  return platform_views_controller->CompositeEmbeddedView(view_id);
}

// |ExternalViewEmbedder|
bool IOSSurfaceGL::SubmitFrame(GrContext* context) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  if (platform_views_controller == nullptr) {
    return true;
  }

  bool submitted = platform_views_controller->SubmitFrame(std::move(context), context_);
  [CATransaction commit];
  return submitted;
}

}  // namespace flutter
