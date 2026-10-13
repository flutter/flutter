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

class JNIExternalViewEmbedderDelegate final
    : public AndroidExternalViewEmbedderDelegate {
 public:
  explicit JNIExternalViewEmbedderDelegate(
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade)
      : jni_facade_(std::move(jni_facade)) {}

  void FlutterViewBeginFrame() override {
    jni_facade_->FlutterViewBeginFrame();
  }

  void FlutterViewOnDisplayPlatformView(int view_id,
                                        int x,
                                        int y,
                                        int width,
                                        int height,
                                        int viewWidth,
                                        int viewHeight,
                                        MutatorsStack mutators_stack) override {
    jni_facade_->FlutterViewOnDisplayPlatformView(view_id, x, y, width, height,
                                                  viewWidth, viewHeight,
                                                  std::move(mutators_stack));
  }

  void FlutterViewDisplayOverlaySurface(int surface_id,
                                        int x,
                                        int y,
                                        int width,
                                        int height) override {
    jni_facade_->FlutterViewDisplayOverlaySurface(surface_id, x, y, width,
                                                  height);
  }

  void FlutterViewEndFrame() override { jni_facade_->FlutterViewEndFrame(); }

  std::unique_ptr<OverlayMetadata> FlutterViewCreateOverlaySurface() override {
    auto meta = jni_facade_->FlutterViewCreateOverlaySurface();
    if (!meta) {
      return nullptr;
    }
    return std::make_unique<OverlayMetadata>(meta->id, meta->window);
  }

  void FlutterViewDestroyOverlaySurfaces() override {
    jni_facade_->FlutterViewDestroyOverlaySurfaces();
  }

  void swapTransaction() override { jni_facade_->swapTransaction(); }

  std::unique_ptr<OverlayMetadata> createOverlaySurface2() override {
    auto meta = jni_facade_->createOverlaySurface2();
    if (!meta) {
      return nullptr;
    }
    return std::make_unique<OverlayMetadata>(meta->id, meta->window);
  }

  void destroyOverlaySurface2() override {
    jni_facade_->destroyOverlaySurface2();
  }

  void onEndFrame2() override { jni_facade_->onEndFrame2(); }

  void showOverlaySurface2() override { jni_facade_->showOverlaySurface2(); }

  void hideOverlaySurface2() override { jni_facade_->hideOverlaySurface2(); }

  void onDisplayPlatformView2(int32_t view_id,
                              int32_t x,
                              int32_t y,
                              int32_t width,
                              int32_t height,
                              int32_t viewWidth,
                              int32_t viewHeight,
                              MutatorsStack mutators_stack) override {
    jni_facade_->onDisplayPlatformView2(view_id, x, y, width, height, viewWidth,
                                        viewHeight, std::move(mutators_stack));
  }

  void hidePlatformView2(int32_t view_id) override {
    jni_facade_->hidePlatformView2(view_id);
  }

  void MaybeResizeSurfaceView(int32_t width, int32_t height) const override {
    jni_facade_->MaybeResizeSurfaceView(width, height);
  }

 private:
  const std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
};

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
    renderer_->SetExternalViewEmbedderDelegate(
        std::make_shared<JNIExternalViewEmbedderDelegate>(jni_facade_));
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
    renderer_->SetExternalViewEmbedderDelegate(
        std::make_shared<JNIExternalViewEmbedderDelegate>(jni_facade_));
  }
}

PlatformViewAndroid::~PlatformViewAndroid() = default;

CreateSurfaceTransaction PlatformViewAndroid::MakeCreateSurfaceTransaction(
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
  // HCPP frames join the FlutterView's transaction.
  return [jni_facade]() { return jni_facade->createTransaction(); };
}

}  // namespace flutter
