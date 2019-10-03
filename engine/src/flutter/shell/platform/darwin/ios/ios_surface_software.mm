// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_surface_software.h"

#include <QuartzCore/CALayer.h>

#include <memory>

#include "flutter/fml/logging.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/utils/mac/SkCGUtils.h"

namespace flutter {

IOSSurfaceSoftware::IOSSurfaceSoftware(fml::scoped_nsobject<CALayer> layer,
                                       FlutterPlatformViewsController* platform_views_controller)
    : IOSSurface(platform_views_controller), layer_(std::move(layer)) {
  UpdateStorageSizeIfNecessary();
}

IOSSurfaceSoftware::~IOSSurfaceSoftware() = default;

bool IOSSurfaceSoftware::IsValid() const {
  return layer_;
}

bool IOSSurfaceSoftware::ResourceContextMakeCurrent() {
  return false;
}

void IOSSurfaceSoftware::UpdateStorageSizeIfNecessary() {
  // Nothing to do here. We don't need an external entity to tell us when our
  // backing store needs to be updated. Instead, we let the frame tell us its
  // size so we can update to match. This method was added to work around
  // Android oddities.
}

std::unique_ptr<Surface> IOSSurfaceSoftware::CreateGPUSurface(GrContext* gr_context) {
  if (!IsValid()) {
    return nullptr;
  }

  auto surface = std::make_unique<GPUSurfaceSoftware>(this, true /* render to surface */);

  if (!surface->IsValid()) {
    return nullptr;
  }

  return surface;
}

sk_sp<SkSurface> IOSSurfaceSoftware::AcquireBackingStore(const SkISize& size) {
  TRACE_EVENT0("flutter", "IOSSurfaceSoftware::AcquireBackingStore");
  if (!IsValid()) {
    return nullptr;
  }

  if (sk_surface_ != nullptr &&
      SkISize::Make(sk_surface_->width(), sk_surface_->height()) == size) {
    // The old and new surface sizes are the same. Nothing to do here.
    return sk_surface_;
  }

  SkImageInfo info = SkImageInfo::MakeN32(size.fWidth, size.fHeight, kPremul_SkAlphaType,
                                          SkColorSpace::MakeSRGB());
  sk_surface_ = SkSurface::MakeRaster(info, nullptr);
  return sk_surface_;
}

bool IOSSurfaceSoftware::PresentBackingStore(sk_sp<SkSurface> backing_store) {
  TRACE_EVENT0("flutter", "IOSSurfaceSoftware::PresentBackingStore");
  if (!IsValid() || backing_store == nullptr) {
    return false;
  }

  SkPixmap pixmap;
  if (!backing_store->peekPixels(&pixmap)) {
    return false;
  }

  // Some basic sanity checking.
  uint64_t expected_pixmap_data_size = pixmap.width() * pixmap.height() * 4;

  const size_t pixmap_size = pixmap.computeByteSize();

  if (expected_pixmap_data_size != pixmap_size) {
    return false;
  }

  fml::CFRef<CGColorSpaceRef> colorspace(CGColorSpaceCreateDeviceRGB());

  // Setup the data provider that gives CG a view into the pixmap.
  fml::CFRef<CGDataProviderRef> pixmap_data_provider(CGDataProviderCreateWithData(
      nullptr,          // info
      pixmap.addr32(),  // data
      pixmap_size,      // size
      nullptr           // release callback
      ));

  if (!pixmap_data_provider) {
    return false;
  }

  // Create the CGImageRef representation on the pixmap.
  fml::CFRef<CGImageRef> pixmap_image(CGImageCreate(pixmap.width(),     // width
                                                    pixmap.height(),    // height
                                                    8,                  // bits per component
                                                    32,                 // bits per pixel
                                                    pixmap.rowBytes(),  // bytes per row
                                                    colorspace,         // colorspace
                                                    kCGImageAlphaPremultipliedLast,  // bitmap info
                                                    pixmap_data_provider,      // data provider
                                                    nullptr,                   // decode array
                                                    false,                     // should interpolate
                                                    kCGRenderingIntentDefault  // rendering intent
                                                    ));

  if (!pixmap_image) {
    return false;
  }

  layer_.get().contents = reinterpret_cast<id>(static_cast<CGImageRef>(pixmap_image));

  return true;
}

ExternalViewEmbedder* IOSSurfaceSoftware::GetExternalViewEmbedder() {
  if (IsIosEmbeddedViewsPreviewEnabled()) {
    return this;
  } else {
    return nullptr;
  }
}

// |ExternalViewEmbedder|
sk_sp<SkSurface> IOSSurfaceSoftware::GetRootSurface() {
  // On iOS, the root surface is created using a managed allocation that is submitted to the
  // platform. Only the surfaces for the various overlays are controlled by this class.
  return nullptr;
}

// |ExternalViewEmbedder|
void IOSSurfaceSoftware::CancelFrame() {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  platform_views_controller->CancelFrame();
}

// |ExternalViewEmbedder|
void IOSSurfaceSoftware::BeginFrame(SkISize frame_size, GrContext* context) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  platform_views_controller->SetFrameSize(frame_size);
}

// |ExternalViewEmbedder|
void IOSSurfaceSoftware::PrerollCompositeEmbeddedView(int view_id,
                                                      std::unique_ptr<EmbeddedViewParams> params) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  platform_views_controller->PrerollCompositeEmbeddedView(view_id, std::move(params));
}

// |ExternalViewEmbedder|
std::vector<SkCanvas*> IOSSurfaceSoftware::GetCurrentCanvases() {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  return platform_views_controller->GetCurrentCanvases();
}

// |ExternalViewEmbedder|
SkCanvas* IOSSurfaceSoftware::CompositeEmbeddedView(int view_id) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  FML_CHECK(platform_views_controller != nullptr);
  return platform_views_controller->CompositeEmbeddedView(view_id);
}

// |ExternalViewEmbedder|
bool IOSSurfaceSoftware::SubmitFrame(GrContext* context) {
  FlutterPlatformViewsController* platform_views_controller = GetPlatformViewsController();
  if (platform_views_controller == nullptr) {
    return true;
  }
  return platform_views_controller->SubmitFrame(nullptr, nullptr);
}

}  // namespace flutter
