// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"

#include <memory>
#include <utility>

#include "common/settings.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_wrapper.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/embedder/android/android_rendering_selector.h"
#include "flutter/shell/platform/embedder/android/context/android_context.h"

namespace flutter {

PlatformViewAndroid::PlatformViewAndroid(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    AndroidRenderingAPI rendering_api,
    PlatformDispatchTable platform_dispatch_table)
    : PlatformViewEmbedder(
          delegate,
          task_runners,
          WithAndroidCallbacks(this, std::move(platform_dispatch_table))),
      jni_facade_(jni_facade),
      renderer_(std::make_shared<AndroidRenderer>(
          task_runners,
          delegate.OnPlatformViewGetSettings(),
          rendering_api,
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

bool PlatformViewAndroid::SetNativeWindow(
    fml::RefPtr<AndroidNativeWindow> native_window) {
  return renderer_->SetNativeWindow(std::move(native_window));
}

void PlatformViewAndroid::SwapNativeWindow(
    fml::RefPtr<AndroidNativeWindow> native_window) {
  renderer_->SwapNativeWindow(std::move(native_window));
}

void PlatformViewAndroid::ResizeSurface(const DlISize& size) {
  renderer_->ResizeSurface(size);
}

void PlatformViewAndroid::TeardownSurface() {
  renderer_->TeardownSurface();
}

bool PlatformViewAndroid::IsSurfaceControlEnabled() const {
  return renderer_->IsSurfaceControlEnabled();
}

CreateSurfaceTransaction PlatformViewAndroid::MakeCreateSurfaceTransaction(
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
  // HCPP frames join the FlutterView's transaction.
  return [jni_facade]() { return jni_facade->createTransaction(); };
}

}  // namespace flutter
