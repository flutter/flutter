// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_BACKINGSTORE_PRODUCER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_BACKINGSTORE_PRODUCER_H_

#include <memory>
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_ptr_internal.h"
#include "flutter/shell/platform/embedder/embedder.h"

#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"

#ifdef SHELL_ENABLE_GL
#include "flutter/testing/test_gl_surface.h"
#endif

namespace flutter::testing {

class EmbedderTestBackingStoreProducer {
 public:
  struct UserData {
    UserData() : surface(nullptr), image(nullptr){};

    explicit UserData(sk_sp<SkSurface> surface)
        : surface(std::move(surface)), image(nullptr){};

    UserData(sk_sp<SkSurface> surface, FlutterVulkanImage* vk_image)
        : surface(std::move(surface)), image(vk_image){};

    sk_sp<SkSurface> surface;
    FlutterVulkanImage* image;
#ifdef SHELL_ENABLE_GL
    UserData(sk_sp<SkSurface> surface,
             FlutterVulkanImage* vk_image,
             std::unique_ptr<TestGLOnscreenOnlySurface> gl_surface)
        : surface(std::move(surface)),
          image(vk_image),
          gl_surface(std::move(gl_surface)){};

    std::unique_ptr<TestGLOnscreenOnlySurface> gl_surface;
#endif
  };

  enum class RenderTargetType {
    kSoftwareBuffer,
    kSoftwareBuffer2,
    kOpenGLFramebuffer,
    kOpenGLTexture,
    kOpenGLSurface,
    kMetalTexture,
    kVulkanImage,
  };

  EmbedderTestBackingStoreProducer(sk_sp<GrDirectContext> context,
                                   RenderTargetType type);
  virtual ~EmbedderTestBackingStoreProducer();

  virtual bool Create(const FlutterBackingStoreConfig* config,
                      FlutterBackingStore* backing_store_out) = 0;

 protected:
  sk_sp<GrDirectContext> context_;
  RenderTargetType type_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestBackingStoreProducer);
};

}  // namespace flutter::testing

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_BACKINGSTORE_PRODUCER_H_
