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
#include "lib/ftl/logging.h"

namespace shell {

AndroidSurfaceSoftware::AndroidSurfaceSoftware() : AndroidSurface() {}

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

  sk_surface_ = SkSurface::MakeRasterN32Premul(
      size.fWidth, size.fHeight, nullptr /* SkSurfaceProps as out */);
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

  // Some basic sanity checking.
  uint64_t expected_pixmap_data_size = pixmap.width() * pixmap.height() * 4;

  if (expected_pixmap_data_size != pixmap.getSize64()) {
    return false;
  }

  // Pass the sk_surface buffer to the android FlutterView.
  JNIEnv* env = fml::jni::AttachCurrentThread();

  // Buffer will be copied into a Bitmap Java-side.
  fml::jni::ScopedJavaLocalRef<jobject> direct_buffer(
      env,
      env->NewDirectByteBuffer(pixmap.writable_addr(), pixmap.getSize64()));

  FlutterViewUpdateSoftwareBuffer(env, flutter_view_.get(env).obj(),
                                  direct_buffer.obj(), pixmap.width(),
                                  pixmap.height());

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
    ftl::RefPtr<AndroidNativeWindow> window,
    PlatformView::SurfaceConfig config) {
  return true;
}

void AndroidSurfaceSoftware::SetFlutterView(
    const fml::jni::JavaObjectWeakGlobalRef& flutter_view) {
  flutter_view_ = flutter_view;
}

}  // namespace shell
