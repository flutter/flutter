// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/bitmap_platform_device_cairo.h"
#include "skia/ext/platform_canvas.h"

#if defined(OS_OPENBSD)
#include <cairo.h>
#else
#include <cairo/cairo.h>
#endif

namespace skia {

namespace {

void CairoSurfaceReleaseProc(void*, void* context) {
  SkASSERT(context);
  cairo_surface_destroy(static_cast<cairo_surface_t*>(context));
}

// Back the destination bitmap by a Cairo surface.  The bitmap's
// pixelRef takes ownership of the passed-in surface and will call
// cairo_surface_destroy() upon destruction.
//
// Note: it may immediately destroy the surface, if it fails to create a bitmap
// with pixels, thus the caller must either ref() the surface before hand, or
// it must not refer to the surface after this call.
bool InstallCairoSurfacePixels(SkBitmap* dst,
                               cairo_surface_t* surface,
                               bool is_opaque) {
  SkASSERT(dst);
  if (!surface) {
    return false;
  }
  SkImageInfo info
      = SkImageInfo::MakeN32Premul(cairo_image_surface_get_width(surface),
                                   cairo_image_surface_get_height(surface));
  return dst->installPixels(info,
                            cairo_image_surface_get_data(surface),
                            cairo_image_surface_get_stride(surface),
                            NULL,
                            &CairoSurfaceReleaseProc,
                            static_cast<void*>(surface));
}

void LoadMatrixToContext(cairo_t* context, const SkMatrix& matrix) {
  cairo_matrix_t cairo_matrix;
  cairo_matrix_init(&cairo_matrix,
                    SkScalarToFloat(matrix.getScaleX()),
                    SkScalarToFloat(matrix.getSkewY()),
                    SkScalarToFloat(matrix.getSkewX()),
                    SkScalarToFloat(matrix.getScaleY()),
                    SkScalarToFloat(matrix.getTranslateX()),
                    SkScalarToFloat(matrix.getTranslateY()));
  cairo_set_matrix(context, &cairo_matrix);
}

void LoadClipToContext(cairo_t* context, const SkRegion& clip) {
  cairo_reset_clip(context);

  // TODO(brettw) support non-rect clips.
  SkIRect bounding = clip.getBounds();
  cairo_rectangle(context, bounding.fLeft, bounding.fTop,
                  bounding.fRight - bounding.fLeft,
                  bounding.fBottom - bounding.fTop);
  cairo_clip(context);
}

}  // namespace

void BitmapPlatformDevice::SetMatrixClip(
    const SkMatrix& transform,
    const SkRegion& region) {
  transform_ = transform;
  clip_region_ = region;
  config_dirty_ = true;
}

void BitmapPlatformDevice::LoadConfig() {
  if (!config_dirty_ || !cairo_)
    return;  // Nothing to do.
  config_dirty_ = false;

  // Load the identity matrix since this is what our clip is relative to.
  cairo_matrix_t cairo_matrix;
  cairo_matrix_init_identity(&cairo_matrix);
  cairo_set_matrix(cairo_, &cairo_matrix);

  LoadClipToContext(cairo_, clip_region_);
  LoadMatrixToContext(cairo_, transform_);
}

// We use this static factory function instead of the regular constructor so
// that we can create the pixel data before calling the constructor. This is
// required so that we can call the base class' constructor with the pixel
// data.
BitmapPlatformDevice* BitmapPlatformDevice::Create(int width, int height,
                                                   bool is_opaque,
                                                   cairo_surface_t* surface) {
  if (cairo_surface_status(surface) != CAIRO_STATUS_SUCCESS) {
    cairo_surface_destroy(surface);
    return NULL;
  }

  // must call this before trying to install the surface, since that may result
  // in the surface being destroyed.
  cairo_t* cairo = cairo_create(surface);

  SkBitmap bitmap;
  if (!InstallCairoSurfacePixels(&bitmap, surface, is_opaque)) {
    cairo_destroy(cairo);
    return NULL;
  }

  // The device object will take ownership of the graphics context.
  return new BitmapPlatformDevice(bitmap, cairo);
}

BitmapPlatformDevice* BitmapPlatformDevice::Create(int width, int height,
                                                   bool is_opaque) {
  // This initializes the bitmap to all zeros.
  cairo_surface_t* surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                        width, height);

  BitmapPlatformDevice* device = Create(width, height, is_opaque, surface);

#ifndef NDEBUG
    if (device && is_opaque)  // Fill with bright bluish green
        SkCanvas(device).drawColor(0xFF00FF80);
#endif

  return device;
}

BitmapPlatformDevice* BitmapPlatformDevice::CreateAndClear(int width,
                                                           int height,
                                                           bool is_opaque) {
  // The Linux port always constructs initialized bitmaps, so there is no extra
  // work to perform here.
  return Create(width, height, is_opaque);
}

BitmapPlatformDevice* BitmapPlatformDevice::Create(int width, int height,
                                                   bool is_opaque,
                                                   uint8_t* data) {
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      data, CAIRO_FORMAT_ARGB32, width, height,
      cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width));

  return Create(width, height, is_opaque, surface);
}

// Ownership of the cairo object is transferred.
BitmapPlatformDevice::BitmapPlatformDevice(
    const SkBitmap& bitmap,
    cairo_t* cairo)
    : SkBitmapDevice(bitmap),
      cairo_(cairo),
      config_dirty_(true),
      transform_(SkMatrix::I()) {  // Want to load the config next time.
  SetPlatformDevice(this, this);
}

BitmapPlatformDevice::~BitmapPlatformDevice() {
  cairo_destroy(cairo_);
}

SkBaseDevice* BitmapPlatformDevice::onCreateDevice(const CreateInfo& info,
                                                   const SkPaint*) {
  SkASSERT(info.fInfo.colorType() == kN32_SkColorType);
  return BitmapPlatformDevice::Create(info.fInfo.width(), info.fInfo.height(),
                                      info.fInfo.isOpaque());
}

cairo_t* BitmapPlatformDevice::BeginPlatformPaint() {
  LoadConfig();
  cairo_surface_t* surface = cairo_get_target(cairo_);
  // Tell cairo to flush anything it has pending.
  cairo_surface_flush(surface);
  // Tell Cairo that we (probably) modified (actually, will modify) its pixel
  // buffer directly.
  cairo_surface_mark_dirty(surface);
  return cairo_;
}

void BitmapPlatformDevice::setMatrixClip(const SkMatrix& transform,
                                         const SkRegion& region,
                                         const SkClipStack&) {
  SetMatrixClip(transform, region);
}

// PlatformCanvas impl

SkCanvas* CreatePlatformCanvas(int width, int height, bool is_opaque,
                               uint8_t* data, OnFailureType failureType) {
  skia::RefPtr<SkBaseDevice> dev = skia::AdoptRef(
      BitmapPlatformDevice::Create(width, height, is_opaque, data));
  return CreateCanvas(dev, failureType);
}

// Port of PlatformBitmap to linux
PlatformBitmap::~PlatformBitmap() {
  cairo_destroy(surface_);
}

bool PlatformBitmap::Allocate(int width, int height, bool is_opaque) {
  // The SkBitmap allocates and owns the bitmap memory; PlatformBitmap owns the
  // cairo drawing context tied to the bitmap. The SkBitmap's pixelRef can
  // outlive the PlatformBitmap if additional copies are made.
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);

  cairo_surface_t* surf = cairo_image_surface_create(
      CAIRO_FORMAT_ARGB32,
      width,
      height);
  if (cairo_surface_status(surf) != CAIRO_STATUS_SUCCESS) {
    cairo_surface_destroy(surf);
    return false;
  }
  return InstallCairoSurfacePixels(&bitmap_, surf, is_opaque);
}

}  // namespace skia
