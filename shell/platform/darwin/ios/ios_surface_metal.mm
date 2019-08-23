// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_surface_metal.h"
#include "flutter/shell/gpu/gpu_surface_metal.h"

namespace flutter {

IOSSurfaceMetal::IOSSurfaceMetal(fml::scoped_nsobject<CAMetalLayer> layer,
                                 FlutterPlatformViewsController* platform_views_controller)
    : IOSSurface(platform_views_controller), layer_(std::move(layer)) {}

IOSSurfaceMetal::IOSSurfaceMetal(fml::scoped_nsobject<CAMetalLayer> layer)
    : IOSSurface(nullptr), layer_(std::move(layer)) {}

IOSSurfaceMetal::~IOSSurfaceMetal() = default;

// |IOSSurface|
bool IOSSurfaceMetal::IsValid() const {
  return layer_;
}

// |IOSSurface|
bool IOSSurfaceMetal::ResourceContextMakeCurrent() {
  return false;
}

// |IOSSurface|
void IOSSurfaceMetal::UpdateStorageSizeIfNecessary() {}

// |IOSSurface|
std::unique_ptr<Surface> IOSSurfaceMetal::CreateGPUSurface(GrContext* gr_context) {
  if (gr_context) {
    return std::make_unique<GPUSurfaceMetal>(this, sk_ref_sp(gr_context), layer_);
  }
  return std::make_unique<GPUSurfaceMetal>(this, layer_);
}

// |ExternalViewEmbedder|
sk_sp<SkSurface> IOSSurfaceMetal::GetRootSurface() {
  // On iOS, the root surface is created from the on-screen render target. Only the surfaces for the
  // various overlays are controlled by this class.
  return nullptr;
}

flutter::ExternalViewEmbedder* IOSSurfaceMetal::GetExternalViewEmbedder() {
  if (IsIosEmbeddedViewsPreviewEnabled()) {
    return this;
  } else {
    return nullptr;
  }
}

void IOSSurfaceMetal::CancelFrame() {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  platform_views_controller->CancelFrame();
  // Committing the current transaction as |BeginFrame| will create a nested
  // CATransaction otherwise.
  [CATransaction commit];
}

void IOSSurfaceMetal::BeginFrame(SkISize frame_size, GrContext* context) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  platform_views_controller->SetFrameSize(frame_size);
  [CATransaction begin];
}

void IOSSurfaceMetal::PrerollCompositeEmbeddedView(
    int view_id,
    std::unique_ptr<flutter::EmbeddedViewParams> params) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  platform_views_controller->PrerollCompositeEmbeddedView(view_id, std::move(params));
}

// |ExternalViewEmbedder|
PostPrerollResult IOSSurfaceMetal::PostPrerollAction(
    fml::RefPtr<fml::GpuThreadMerger> gpu_thread_merger) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  return platform_views_controller->PostPrerollAction(gpu_thread_merger);
}

std::vector<SkCanvas*> IOSSurfaceMetal::GetCurrentCanvases() {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  return platform_views_controller->GetCurrentCanvases();
}

SkCanvas* IOSSurfaceMetal::CompositeEmbeddedView(int view_id) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  return platform_views_controller->CompositeEmbeddedView(view_id);
}

bool IOSSurfaceMetal::SubmitFrame(GrContext* context) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  if (platform_views_controller == nullptr) {
    return true;
  }

  bool submitted = platform_views_controller->SubmitFrame(std::move(context), nullptr);
  [CATransaction commit];
  return submitted;
}

}  // namespace flutter
