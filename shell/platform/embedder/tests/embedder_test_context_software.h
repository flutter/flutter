// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_SOFTWARE_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_SOFTWARE_H_

#include "flutter/shell/platform/embedder/tests/embedder_test_context.h"

namespace flutter {
namespace testing {

class EmbedderTestContextSoftware : public EmbedderTestContext {
 public:
  EmbedderTestContextSoftware(std::string assets_path = "");

  ~EmbedderTestContextSoftware() override;

  size_t GetSurfacePresentCount() const override;

  bool Present(sk_sp<SkImage> image);

 protected:
  virtual void SetupCompositor() override;

 private:
  sk_sp<SkSurface> surface_;
  SkISize surface_size_;
  size_t software_surface_present_count_ = 0;
  void SetupSurface(SkISize surface_size) override;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestContextSoftware);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_SOFTWARE_H_
