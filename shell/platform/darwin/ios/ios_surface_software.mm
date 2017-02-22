// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_surface_software.h"

#include <QuartzCore/CALayer.h>

#include <memory>

#include "flutter/fml/platform/darwin/cf_utils.h"
#include "lib/ftl/logging.h"
#include "third_party/skia/include/utils/mac/SkCGUtils.h"

namespace shell {

IOSSurfaceSoftware::IOSSurfaceSoftware(
    PlatformView::SurfaceConfig surface_config,
    CALayer* layer)
    : IOSSurface(surface_config, layer) {
  UpdateStorageSizeIfNecessary();
}

IOSSurfaceSoftware::~IOSSurfaceSoftware() = default;

bool IOSSurfaceSoftware::IsValid() const {
  return GetLayer() != nullptr;
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

std::unique_ptr<Surface> IOSSurfaceSoftware::CreateGPUSurface() {
  if (!IsValid()) {
    return nullptr;
  }

  auto surface = std::make_unique<GPUSurfaceSoftware>(this);

  if (!surface->IsValid()) {
    return nullptr;
  }

  return surface;
}

sk_sp<SkSurface> IOSSurfaceSoftware::AcquireBackingStore(const SkISize& size) {
  if (!IsValid()) {
    return nullptr;
  }

  if (sk_surface_ != nullptr &&
      SkISize::Make(sk_surface_->width(), sk_surface_->height()) == size) {
    // The old and new surface sizes are the same. Nothing to do here.
    return sk_surface_;
  }

  sk_surface_ = SkSurface::MakeRasterN32Premul(
      size.fWidth, size.fHeight, nullptr /* SkSurfaceProps as out */);
  return sk_surface_;
}

bool IOSSurfaceSoftware::PresentBackingStore(sk_sp<SkSurface> backing_store) {
  if (!IsValid() || backing_store == nullptr) {
    return false;
  }

  SkPixmap pixmap;
  if (!backing_store->peekPixels(&pixmap)) {
    return false;
  }

  uint64_t expected_pixmap_data_size = pixmap.width() * pixmap.height() * 4;

  if (expected_pixmap_data_size != pixmap.getSize64()) {
    return false;
  }

  fml::CFRef<CGColorSpaceRef> colorspace(CGColorSpaceCreateDeviceRGB());

  fml::CFRef<CGContextRef> bitmap(CGBitmapContextCreate(
      const_cast<uint32_t*>(pixmap.addr32()),  // data managed pixmap
      pixmap.width(),                          // width
      pixmap.height(),                         // height
      8,                                       // bits per component
      4 * pixmap.width(),                      // bytes per row
      colorspace,                              // colorspace
      kCGImageAlphaPremultipliedLast           // bitmap info
      ));

  if (!bitmap) {
    return false;
  }

  fml::CFRef<CGImageRef> image(CGBitmapContextCreateImage(bitmap));

  if (!image) {
    return false;
  }

  [GetLayer() setContents:reinterpret_cast<id>(static_cast<CGImageRef>(image))];

  return true;
}

}  // namespace shell
