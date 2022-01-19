// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_GL_H_
#define FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_GL_H_

#include "flutter/display_list/display_list_benchmarks_canvas_provider.h"
#include "flutter/testing/test_gl_surface.h"

namespace flutter {
namespace testing {

class OpenGLCanvasProvider : public CanvasProvider {
 public:
  virtual ~OpenGLCanvasProvider() = default;
  void InitializeSurface(const size_t width, const size_t height) override;
  sk_sp<SkSurface> GetSurface() override;
  sk_sp<SkSurface> MakeOffscreenSurface(const size_t width,
                                        const size_t height) override;
  const std::string BackendName() override { return "OpenGL"; }

 private:
  SkISize surface_size_;
  sk_sp<SkSurface> surface_;
  std::unique_ptr<TestGLSurface> gl_surface_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_GL_H_
