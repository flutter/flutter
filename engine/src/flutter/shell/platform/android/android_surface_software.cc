// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_software.h"
#include "flutter/common/threads.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/shell/platform/android/platform_view_android_jni.h"

#include <memory>
#include <vector>

#include "flutter/fml/trace_event.h"
#include "lib/fxl/logging.h"

namespace shell {

namespace {

bool GetSkColorType(int32_t buffer_format, SkColorType* color_type) {
  switch (buffer_format) {
    case WINDOW_FORMAT_RGB_565:
      *color_type = kRGB_565_SkColorType;
      return true;
    case WINDOW_FORMAT_RGBA_8888:
      *color_type = kRGBA_8888_SkColorType;
      return true;
    default:
      return false;
  }
}

}  // anonymous namespace

AndroidSurfaceSoftware::AndroidSurfaceSoftware()
    : AndroidSurface(),
      target_color_type_(kRGBA_8888_SkColorType) {}

AndroidSurfaceSoftware::~AndroidSurfaceSoftware() = default;

bool AndroidSurfaceSoftware::IsValid() const {
  return true;
}

bool AndroidSurfaceSoftware::ResourceContextMakeCurrent() {
  // Resource Context always not available on software backend.
  return false;
}

std::unique_ptr<Surface> AndroidSurfaceSoftware::CreateGPUSurface() {
  if (!IsValid()) {
    return nullptr;
  }

  auto surface = std::make_unique<GPUSurfaceSoftware>(this);

  if (!surface->IsValid()) {
    return nullptr;
  }

  return surface;
}

sk_sp<SkSurface> AndroidSurfaceSoftware::AcquireBackingStore(
    const SkISize& size) {
  TRACE_EVENT0("flutter", "AndroidSurfaceSoftware::AcquireBackingStore");
  if (!IsValid()) {
    return nullptr;
  }

  if (sk_surface_ != nullptr &&
      SkISize::Make(sk_surface_->width(), sk_surface_->height()) == size) {
    // The old and new surface sizes are the same. Nothing to do here.
    return sk_surface_;
  }

  SkImageInfo image_info = SkImageInfo::Make(
      size.fWidth, size.fHeight, target_color_type_, kPremul_SkAlphaType);

  sk_surface_ = SkSurface::MakeRaster(image_info);

  return sk_surface_;
}

bool AndroidSurfaceSoftware::PresentBackingStore(
    sk_sp<SkSurface> backing_store) {
  TRACE_EVENT0("flutter", "AndroidSurfaceSoftware::PresentBackingStore");
  if (!IsValid() || backing_store == nullptr) {
    return false;
  }

  SkPixmap pixmap;
  if (!backing_store->peekPixels(&pixmap)) {
    return false;
  }

  ANativeWindow_Buffer native_buffer;
  if (ANativeWindow_lock(native_window_->handle(), &native_buffer, nullptr)) {
    return false;
  }

  SkColorType color_type;
  if (GetSkColorType(native_buffer.format, &color_type)) {
    SkImageInfo native_image_info = SkImageInfo::Make(
        native_buffer.width, native_buffer.height, color_type, kPremul_SkAlphaType);

    std::unique_ptr<SkCanvas> canvas = SkCanvas::MakeRasterDirect(
        native_image_info,
        native_buffer.bits,
        native_buffer.stride * SkColorTypeBytesPerPixel(color_type));

    if (canvas) {
      SkBitmap bitmap;
      if (bitmap.installPixels(pixmap)) {
        canvas->drawBitmapRect(
            bitmap,
            SkRect::MakeIWH(native_buffer.width, native_buffer.height),
            nullptr);
      }
    }
  }

  ANativeWindow_unlockAndPost(native_window_->handle());

  return true;
}

void AndroidSurfaceSoftware::TeardownOnScreenContext() {}

SkISize AndroidSurfaceSoftware::OnScreenSurfaceSize() const {
  return SkISize();
}

bool AndroidSurfaceSoftware::OnScreenSurfaceResize(const SkISize& size) const {
  return true;
}

bool AndroidSurfaceSoftware::SetNativeWindow(
    fxl::RefPtr<AndroidNativeWindow> window,
    PlatformView::SurfaceConfig config) {
  native_window_ = std::move(window);
  if (!(native_window_ && native_window_->IsValid()))
    return false;
  int32_t window_format = ANativeWindow_getFormat(native_window_->handle());
  if (window_format < 0)
    return false;
  if (!GetSkColorType(window_format, &target_color_type_))
    return false;
  return true;
}

void AndroidSurfaceSoftware::SetFlutterView(
    const fml::jni::JavaObjectWeakGlobalRef& flutter_view) {
  flutter_view_ = flutter_view;
}

}  // namespace shell
