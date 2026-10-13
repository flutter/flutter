// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"

#include <memory>
#include <utility>

#include "common/settings.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_wrapper.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"

namespace flutter {

namespace {

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
          MakeCreateSurfaceTransaction(jni_facade))) {}

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
      return self->CreateAndroidExternalViewEmbedder();
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
          MakeCreateSurfaceTransaction(jni_facade))) {}

PlatformViewAndroid::~PlatformViewAndroid() = default;

std::shared_ptr<ExternalViewEmbedder>
PlatformViewAndroid::CreateAndroidExternalViewEmbedder() {
  return std::make_shared<AndroidExternalViewEmbedderWrapper>(
      renderer_->MeetsHCPPCriteria(), *renderer_->GetAndroidContext(),
      jni_facade_, renderer_->GetSurfaceFactory(), task_runners_);
}

CreateSurfaceTransaction PlatformViewAndroid::MakeCreateSurfaceTransaction(
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
  // HCPP frames join the FlutterView's transaction.
  return [jni_facade]() { return jni_facade->createTransaction(); };
}

}  // namespace flutter
