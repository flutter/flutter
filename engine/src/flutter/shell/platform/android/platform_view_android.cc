// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"

#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"

namespace flutter {

FlutterNativeWindowCompositor PlatformViewAndroid::MakeNativeWindowCompositor(
    PlatformViewAndroidJNI* jni_facade) {
  FlutterNativeWindowCompositor c = {};
  c.struct_size = sizeof(FlutterNativeWindowCompositor);
  c.user_data = jni_facade;
  c.begin_frame_callback = [](void* ud) {
    static_cast<PlatformViewAndroidJNI*>(ud)->FlutterViewBeginFrame();
  };
  c.end_frame_callback = [](void* ud) {
    static_cast<PlatformViewAndroidJNI*>(ud)->FlutterViewEndFrame();
  };
  c.create_overlay_surface_callback = [](void* ud,
                                         FlutterNativeWindowOverlay* out) {
    auto meta = static_cast<PlatformViewAndroidJNI*>(ud)
                    ->FlutterViewCreateOverlaySurface();
    if (!meta) {
      return false;
    }
    out->id = meta->id;
    out->window = meta->window ? meta->window->handle() : nullptr;
    return true;
  };
  c.destroy_overlay_surfaces_callback = [](void* ud) {
    static_cast<PlatformViewAndroidJNI*>(ud)
        ->FlutterViewDestroyOverlaySurfaces();
  };
  c.display_overlay_surface_callback = [](void* ud, int32_t id, int32_t x,
                                          int32_t y, int32_t w, int32_t h) {
    static_cast<PlatformViewAndroidJNI*>(ud)->FlutterViewDisplayOverlaySurface(
        id, x, y, w, h);
  };
  c.display_platform_view_callback =
      [](void* ud, int32_t id, int32_t x, int32_t y, int32_t w, int32_t h,
         int32_t vw, int32_t vh, const FlutterPlatformViewMutation* const* m,
         size_t count) {
        static_cast<PlatformViewAndroidJNI*>(ud)
            ->FlutterViewOnDisplayPlatformView(id, x, y, w, h, vw, vh, m,
                                               count);
      };
  c.swap_transaction_callback = [](void* ud) {
    static_cast<PlatformViewAndroidJNI*>(ud)->swapTransaction();
  };
  c.create_overlay_surface2_callback = [](void* ud,
                                          FlutterNativeWindowOverlay* out) {
    auto meta =
        static_cast<PlatformViewAndroidJNI*>(ud)->createOverlaySurface2();
    if (!meta) {
      return false;
    }
    out->id = meta->id;
    out->window = meta->window ? meta->window->handle() : nullptr;
    return true;
  };
  c.destroy_overlay_surface2_callback = [](void* ud) {
    static_cast<PlatformViewAndroidJNI*>(ud)->destroyOverlaySurface2();
  };
  c.end_frame2_callback = [](void* ud) {
    static_cast<PlatformViewAndroidJNI*>(ud)->onEndFrame2();
  };
  c.show_overlay_surface2_callback = [](void* ud) {
    static_cast<PlatformViewAndroidJNI*>(ud)->showOverlaySurface2();
  };
  c.hide_overlay_surface2_callback = [](void* ud) {
    static_cast<PlatformViewAndroidJNI*>(ud)->hideOverlaySurface2();
  };
  c.display_platform_view2_callback =
      [](void* ud, int32_t id, int32_t x, int32_t y, int32_t w, int32_t h,
         int32_t vw, int32_t vh, const FlutterPlatformViewMutation* const* m,
         size_t count) {
        static_cast<PlatformViewAndroidJNI*>(ud)->onDisplayPlatformView2(
            id, x, y, w, h, vw, vh, m, count);
      };
  c.hide_platform_view2_callback = [](void* ud, int32_t id) {
    static_cast<PlatformViewAndroidJNI*>(ud)->hidePlatformView2(id);
  };
  c.maybe_resize_surface_view_callback = [](void* ud, int32_t w, int32_t h) {
    static_cast<PlatformViewAndroidJNI*>(ud)->MaybeResizeSurfaceView(w, h);
  };
  return c;
}

}  // namespace flutter
