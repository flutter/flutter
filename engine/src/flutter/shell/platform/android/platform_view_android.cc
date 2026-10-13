// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"

#include <memory>
#include <utility>

#include "common/settings.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"

namespace flutter {

namespace {

FlutterNativeWindowCompositor MakeNativeWindowCompositor(
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

AndroidRenderingAPI ToAndroidRenderingAPI(FlutterNativeWindowBackend backend) {
  switch (backend) {
    case kFlutterNativeWindowBackendImpellerAutoselect:
      return AndroidRenderingAPI::kImpellerAutoselect;
    case kFlutterNativeWindowBackendImpellerVulkan:
      return AndroidRenderingAPI::kImpellerVulkan;
    case kFlutterNativeWindowBackendImpellerOpenGLES:
      return AndroidRenderingAPI::kImpellerOpenGLES;
    case kFlutterNativeWindowBackendSkiaOpenGLES:
#if !SLIMPELLER
      return AndroidRenderingAPI::kSkiaOpenGLES;
#else
      return AndroidRenderingAPI::kImpellerAutoselect;
#endif
    case kFlutterNativeWindowBackendSoftware:
#if !SLIMPELLER
      return AndroidRenderingAPI::kSoftware;
#else
      return AndroidRenderingAPI::kImpellerAutoselect;
#endif
  }
  return AndroidRenderingAPI::kImpellerAutoselect;
}

}  // namespace

PlatformViewAndroid::PlatformViewAndroid(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    FlutterNativeWindowBackend rendering_backend,
    PlatformDispatchTable platform_dispatch_table)
    : PlatformViewEmbedder(
          delegate,
          task_runners,
          WithAndroidCallbacks(this, std::move(platform_dispatch_table))),
      jni_facade_(jni_facade),
      renderer_(std::make_shared<AndroidRenderer>(
          task_runners,
          delegate.OnPlatformViewGetSettings(),
          ToAndroidRenderingAPI(rendering_backend),
          delegate.OnPlatformViewGetShutdownSafeIOTaskRunner(),
          MakeCreateSurfaceTransaction(jni_facade))) {
  if (jni_facade_) {
    FlutterNativeWindowCompositor compositor =
        MakeNativeWindowCompositor(jni_facade_.get());
    renderer_->SetCompositor(&compositor, jni_facade_.get());
  }
}

PlatformViewEmbedder::PlatformDispatchTable
PlatformViewAndroid::WithAndroidCallbacks(
    PlatformViewAndroid* self,
    PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table) {
  if (!platform_dispatch_table.create_rendering_surface_callback) {
    platform_dispatch_table.create_rendering_surface_callback = [self]() {
      return self->renderer_->CreateRenderingSurface();
    };
  }
  if (!platform_dispatch_table.create_external_view_embedder_callback) {
    platform_dispatch_table.create_external_view_embedder_callback = [self]() {
      return self->renderer_->CreateExternalViewEmbedder();
    };
  }
  if (!platform_dispatch_table.create_snapshot_surface_producer_callback) {
    platform_dispatch_table.create_snapshot_surface_producer_callback =
        [self]() { return self->renderer_->CreateSnapshotSurfaceProducer(); };
  }
  if (!platform_dispatch_table.create_resource_context_callback &&
      !platform_dispatch_table.make_resource_current_callback) {
    platform_dispatch_table.make_resource_current_callback = [self]() {
      return self->renderer_->MakeResourceContextCurrent();
    };
  }
  if (!platform_dispatch_table.release_resource_context_callback) {
    platform_dispatch_table.release_resource_context_callback = [self]() {
      self->renderer_->ReleaseResourceContext();
    };
  }
  if (!platform_dispatch_table.get_impeller_context_callback) {
    platform_dispatch_table.get_impeller_context_callback = [self]() {
      return self->renderer_->GetImpellerContext();
    };
  }
  if (!platform_dispatch_table.setup_impeller_context_callback) {
    platform_dispatch_table.setup_impeller_context_callback = [self]() {
      self->renderer_->SetupImpellerContext();
    };
  }
  return platform_dispatch_table;
}

PlatformViewAndroid::PlatformViewAndroid(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<flutter::AndroidContext>& android_context,
    PlatformDispatchTable platform_dispatch_table)
    : PlatformViewEmbedder(
          delegate,
          task_runners,
          WithAndroidCallbacks(this, std::move(platform_dispatch_table))),
      jni_facade_(jni_facade),
      renderer_(std::make_shared<AndroidRenderer>(
          task_runners,
          delegate.OnPlatformViewGetSettings(),
          android_context,
          MakeCreateSurfaceTransaction(jni_facade))) {
  if (jni_facade_) {
    FlutterNativeWindowCompositor compositor =
        MakeNativeWindowCompositor(jni_facade_.get());
    renderer_->SetCompositor(&compositor, jni_facade_.get());
  }
}

PlatformViewAndroid::~PlatformViewAndroid() = default;

CreateSurfaceTransaction PlatformViewAndroid::MakeCreateSurfaceTransaction(
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
  // HCPP frames join the FlutterView's transaction.
  return [jni_facade]() { return jni_facade->createTransaction(); };
}

}  // namespace flutter
