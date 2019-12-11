// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/shell_io_manager.h"

#include "flutter/fml/build_config.h"
#include "flutter/fml/message_loop.h"
#include "flutter/shell/common/persistent_cache.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace flutter {

sk_sp<GrContext> ShellIOManager::CreateCompatibleResourceLoadingContext(
    GrBackend backend,
    sk_sp<const GrGLInterface> gl_interface) {
  if (backend != GrBackend::kOpenGL_GrBackend) {
    return nullptr;
  }

  GrContextOptions options = {};

  if (PersistentCache::cache_sksl()) {
    FML_LOG(INFO) << "Cache SkSL";
    options.fShaderCacheStrategy = GrContextOptions::ShaderCacheStrategy::kSkSL;
  }
  PersistentCache::MarkStrategySet();

  options.fPersistentCache = PersistentCache::GetCacheForProcess();

  // There is currently a bug with doing GPU YUV to RGB conversions on the IO
  // thread. The necessary work isn't being flushed or synchronized with the
  // other threads correctly, so the textures end up blank.  For now, suppress
  // that feature, which will cause texture uploads to do CPU YUV conversion.
  // A similar work-around is also used in shell/gpu/gpu_surface_gl.cc.
  options.fDisableGpuYUVConversion = true;

  // To get video playback on the widest range of devices, we limit Skia to
  // ES2 shading language when the ES3 external image extension is missing.
  options.fPreferExternalImagesOverES3 = true;

#if !OS_FUCHSIA
  if (auto context = GrContext::MakeGL(gl_interface, options)) {
    // Do not cache textures created by the image decoder.  These textures
    // should be deleted when they are no longer referenced by an SkImage.
    context->setResourceCacheLimits(0, 0);
    return context;
  }
#endif

  return nullptr;
}

ShellIOManager::ShellIOManager(
    sk_sp<GrContext> resource_context,
    std::shared_ptr<fml::SyncSwitch> is_gpu_disabled_sync_switch,
    fml::RefPtr<fml::TaskRunner> unref_queue_task_runner)
    : resource_context_(std::move(resource_context)),
      resource_context_weak_factory_(
          resource_context_ ? std::make_unique<fml::WeakPtrFactory<GrContext>>(
                                  resource_context_.get())
                            : nullptr),
      unref_queue_(fml::MakeRefCounted<flutter::SkiaUnrefQueue>(
          std::move(unref_queue_task_runner),
          fml::TimeDelta::FromMilliseconds(8),
          GetResourceContext())),
      weak_factory_(this),
      is_gpu_disabled_sync_switch_(is_gpu_disabled_sync_switch) {
  if (!resource_context_) {
#ifndef OS_FUCHSIA
    FML_DLOG(WARNING) << "The IO manager was initialized without a resource "
                         "context. Async texture uploads will be disabled. "
                         "Expect performance degradation.";
#endif  // OS_FUCHSIA
  }
}

ShellIOManager::~ShellIOManager() {
  // Last chance to drain the IO queue as the platform side reference to the
  // underlying OpenGL context may be going away.
  is_gpu_disabled_sync_switch_->Execute(
      fml::SyncSwitch::Handlers().SetIfFalse([&] { unref_queue_->Drain(); }));
}

void ShellIOManager::NotifyResourceContextAvailable(
    sk_sp<GrContext> resource_context) {
  // The resource context needs to survive as long as we have Dart objects
  // referencing. We shouldn't ever need to replace it if we have one - unless
  // we've somehow shut down the Dart VM and started a new one fresh.
  if (!resource_context_) {
    UpdateResourceContext(std::move(resource_context));
  }
}

void ShellIOManager::UpdateResourceContext(sk_sp<GrContext> resource_context) {
  resource_context_ = std::move(resource_context);
  resource_context_weak_factory_ =
      resource_context_ ? std::make_unique<fml::WeakPtrFactory<GrContext>>(
                              resource_context_.get())
                        : nullptr;
}

fml::WeakPtr<ShellIOManager> ShellIOManager::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

// |IOManager|
fml::WeakPtr<GrContext> ShellIOManager::GetResourceContext() const {
  return resource_context_weak_factory_
             ? resource_context_weak_factory_->GetWeakPtr()
             : fml::WeakPtr<GrContext>();
}

// |IOManager|
fml::RefPtr<flutter::SkiaUnrefQueue> ShellIOManager::GetSkiaUnrefQueue() const {
  return unref_queue_;
}

// |IOManager|
fml::WeakPtr<IOManager> ShellIOManager::GetWeakIOManager() const {
  return weak_factory_.GetWeakPtr();
}

// |IOManager|
std::shared_ptr<fml::SyncSwitch> ShellIOManager::GetIsGpuDisabledSyncSwitch() {
  return is_gpu_disabled_sync_switch_;
}

}  // namespace flutter
