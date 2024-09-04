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

#ifdef SHELL_ENABLE_METAL
#include "flutter/testing/test_metal_context.h"
#endif

#ifdef SHELL_ENABLE_VULKAN
#include "flutter/testing/test_vulkan_context.h"  // nogncheck
#endif

#ifdef SHELL_ENABLE_GL
#include "flutter/testing/test_gl_surface.h"
#endif

namespace flutter {
namespace testing {

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
                                   RenderTargetType type,
                                   FlutterSoftwarePixelFormat software_pixfmt =
                                       kFlutterSoftwarePixelFormatNative32);
  ~EmbedderTestBackingStoreProducer();

#ifdef SHELL_ENABLE_GL
  void SetEGLContext(std::shared_ptr<TestEGLContext> context);
#endif

  bool Create(const FlutterBackingStoreConfig* config,
              FlutterBackingStore* renderer_out);

 private:
  bool CreateFramebuffer(const FlutterBackingStoreConfig* config,
                         FlutterBackingStore* renderer_out);

  bool CreateTexture(const FlutterBackingStoreConfig* config,
                     FlutterBackingStore* renderer_out);

  bool CreateSurface(const FlutterBackingStoreConfig* config,
                     FlutterBackingStore* renderer_out);

  bool CreateSoftware(const FlutterBackingStoreConfig* config,
                      FlutterBackingStore* backing_store_out);

  bool CreateSoftware2(const FlutterBackingStoreConfig* config,
                       FlutterBackingStore* backing_store_out);

  bool CreateMTLTexture(const FlutterBackingStoreConfig* config,
                        FlutterBackingStore* renderer_out);

  bool CreateVulkanImage(const FlutterBackingStoreConfig* config,
                         FlutterBackingStore* renderer_out);

  sk_sp<GrDirectContext> context_;
  RenderTargetType type_;
  FlutterSoftwarePixelFormat software_pixfmt_;

#ifdef SHELL_ENABLE_GL
  std::shared_ptr<TestEGLContext> test_egl_context_;
#endif

#ifdef SHELL_ENABLE_METAL
  std::unique_ptr<TestMetalContext> test_metal_context_;
#endif

#ifdef SHELL_ENABLE_VULKAN
  fml::RefPtr<TestVulkanContext> test_vulkan_context_;
#endif

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestBackingStoreProducer);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_BACKINGSTORE_PRODUCER_H_
