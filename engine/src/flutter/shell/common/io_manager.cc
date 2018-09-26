// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/io_manager.h"

#include "flutter/fml/message_loop.h"
#include "flutter/shell/common/persistent_cache.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace shell {

sk_sp<GrContext> IOManager::CreateCompatibleResourceLoadingContext(
    GrBackend backend) {
  if (backend != GrBackend::kOpenGL_GrBackend) {
    return nullptr;
  }

  GrContextOptions options = {};

  options.fPersistentCache = PersistentCache::GetCacheForProcess();

  // There is currently a bug with doing GPU YUV to RGB conversions on the IO
  // thread. The necessary work isn't being flushed or synchronized with the
  // other threads correctly, so the textures end up blank.  For now, suppress
  // that feature, which will cause texture uploads to do CPU YUV conversion.
  options.fDisableGpuYUVConversion = true;

  // To get video playback on the widest range of devices, we limit Skia to
  // ES2 shading language when the ES3 external image extension is missing.
  options.fPreferExternalImagesOverES3 = true;

  if (auto context = GrContext::MakeGL(GrGLMakeNativeInterface(), options)) {
    // Do not cache textures created by the image decoder.  These textures
    // should be deleted when they are no longer referenced by an SkImage.
    context->setResourceCacheLimits(0, 0);
    return context;
  }

  return nullptr;
}

IOManager::IOManager(sk_sp<GrContext> resource_context,
                     fml::RefPtr<fml::TaskRunner> unref_queue_task_runner)
    : resource_context_(std::move(resource_context)),
      resource_context_weak_factory_(
          resource_context_ ? std::make_unique<fml::WeakPtrFactory<GrContext>>(
                                  resource_context_.get())
                            : nullptr),
      unref_queue_(fml::MakeRefCounted<flow::SkiaUnrefQueue>(
          std::move(unref_queue_task_runner),
          fml::TimeDelta::FromMilliseconds(250))),
      weak_factory_(this) {
  if (!resource_context_) {
    FML_DLOG(WARNING) << "The IO manager was initialized without a resource "
                         "context. Async texture uploads will be disabled. "
                         "Expect performance degradation.";
  }
}

IOManager::~IOManager() {
  // Last chance to drain the IO queue as the platform side reference to the
  // underlying OpenGL context may be going away.
  unref_queue_->Drain();
}

fml::WeakPtr<GrContext> IOManager::GetResourceContext() const {
  return resource_context_weak_factory_
             ? resource_context_weak_factory_->GetWeakPtr()
             : fml::WeakPtr<GrContext>();
}

fml::RefPtr<flow::SkiaUnrefQueue> IOManager::GetSkiaUnrefQueue() const {
  return unref_queue_;
}

}  // namespace shell
