// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_BACKINGSTORE_PRODUCER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_BACKINGSTORE_PRODUCER_H_

#include <memory>
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_ptr_internal.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

#ifdef SHELL_ENABLE_METAL
#include "flutter/testing/test_metal_context.h"
#endif

#ifdef SHELL_ENABLE_VULKAN
#include "flutter/testing/test_vulkan_context.h"
#endif

namespace flutter {
namespace testing {

class EmbedderTestBackingStoreProducer {
 public:
  struct UserData {
    SkSurface* surface;
    FlutterVulkanImage* image;
  };

  enum class RenderTargetType {
    kSoftwareBuffer,
    kOpenGLFramebuffer,
    kOpenGLTexture,
    kMetalTexture,
    kVulkanImage,
  };

  EmbedderTestBackingStoreProducer(sk_sp<GrDirectContext> context,
                                   RenderTargetType type);
  ~EmbedderTestBackingStoreProducer();

  bool Create(const FlutterBackingStoreConfig* config,
              FlutterBackingStore* renderer_out);

 private:
  bool CreateFramebuffer(const FlutterBackingStoreConfig* config,
                         FlutterBackingStore* renderer_out);

  bool CreateTexture(const FlutterBackingStoreConfig* config,
                     FlutterBackingStore* renderer_out);

  bool CreateSoftware(const FlutterBackingStoreConfig* config,
                      FlutterBackingStore* backing_store_out);

  bool CreateMTLTexture(const FlutterBackingStoreConfig* config,
                        FlutterBackingStore* renderer_out);

  bool CreateVulkanImage(const FlutterBackingStoreConfig* config,
                         FlutterBackingStore* renderer_out);

  sk_sp<GrDirectContext> context_;
  RenderTargetType type_;

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
