// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_TEST_METAL_CONTEXT_H_
#define FLUTTER_TESTING_TEST_METAL_CONTEXT_H_

#include <map>
#include <mutex>

#include "third_party/skia/include/gpu/GrDirectContext.h"
#include "third_party/skia/include/gpu/mtl/GrMtlTypes.h"

namespace flutter {

class TestMetalContext {
 public:
  struct TextureInfo {
    int64_t texture_id;
    void* texture;
  };

  TestMetalContext();

  ~TestMetalContext();

  void* GetMetalDevice() const;

  void* GetMetalCommandQueue() const;

  sk_sp<GrDirectContext> GetSkiaContext() const;

  /// Returns texture_id = -1 when texture creation fails.
  TextureInfo CreateMetalTexture(const SkISize& size);

  bool Present(int64_t texture_id);

  TextureInfo GetTextureInfo(int64_t texture_id);

 private:
  void* device_;
  void* command_queue_;
  sk_sp<GrDirectContext> skia_context_;
  std::mutex textures_mutex;
  int64_t texture_id_ctr_ = 1;                 // guarded by textures_mutex
  std::map<int64_t, sk_cfp<void*>> textures_;  // guarded by textures_mutex
};

}  // namespace flutter

#endif  // FLUTTER_TESTING_TEST_METAL_CONTEXT_H_
