// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_BACKINGSTORE_PRODUCER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_BACKINGSTORE_PRODUCER_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"

#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {
namespace testing {

class EmbedderTestBackingStoreProducer {
 public:
  enum class RenderTargetType {
    kSoftwareBuffer,
    kOpenGLFramebuffer,
    kOpenGLTexture,
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

  sk_sp<GrDirectContext> context_;
  RenderTargetType type_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestBackingStoreProducer);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_BACKINGSTORE_PRODUCER_H_
