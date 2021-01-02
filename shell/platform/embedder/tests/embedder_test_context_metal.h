// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_METAL_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_METAL_H_

#include "flutter/shell/platform/embedder/tests/embedder_test_context.h"
#include "flutter/testing/test_metal_context.h"
#include "flutter/testing/test_metal_surface.h"

namespace flutter {
namespace testing {

class EmbedderTestContextMetal : public EmbedderTestContext {
 public:
  explicit EmbedderTestContextMetal(std::string assets_path = "");

  ~EmbedderTestContextMetal() override;

  // |EmbedderTestContext|
  EmbedderTestContextType GetContextType() const override;

  // |EmbedderTestContext|
  size_t GetSurfacePresentCount() const override;

  // |EmbedderTestContext|
  void SetupCompositor() override;

  bool Present(int64_t texture_id);

  TestMetalContext* GetTestMetalContext();

 private:
  // This allows the builder to access the hooks.
  friend class EmbedderConfigBuilder;

  SkISize surface_size_ = SkISize::MakeEmpty();
  std::unique_ptr<TestMetalContext> metal_context_;
  size_t present_count_ = 0;

  void SetupSurface(SkISize surface_size) override;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestContextMetal);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_METAL_H_
