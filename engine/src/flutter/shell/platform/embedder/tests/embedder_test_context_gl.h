// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_GL_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_GL_H_

#include "flutter/shell/platform/embedder/tests/embedder_test_context.h"
#include "flutter/testing/test_gl_surface.h"

namespace flutter {
namespace testing {

class EmbedderTestContextGL : public EmbedderTestContext {
 public:
  using GLGetFBOCallback = std::function<void(FlutterFrameInfo frame_info)>;
  using GLPresentCallback = std::function<void(uint32_t fbo_id)>;

  EmbedderTestContextGL(std::string assets_path = "");

  ~EmbedderTestContextGL() override;

  size_t GetSurfacePresentCount() const override;

  //----------------------------------------------------------------------------
  /// @brief      Sets a callback that will be invoked (on the raster task
  ///             runner) when the engine asks the embedder for a new FBO ID at
  ///             the updated size.
  ///
  /// @attention  The callback will be invoked on the raster task runner. The
  ///             callback can be set on the tests host thread.
  ///
  /// @param[in]  callback  The callback to set. The previous callback will be
  ///                       un-registered.
  ///
  void SetGLGetFBOCallback(GLGetFBOCallback callback);

  uint32_t GetWindowFBOId() const;

  //----------------------------------------------------------------------------
  /// @brief      Sets a callback that will be invoked (on the raster task
  ///             runner) when the engine presents an fbo that was given by the
  ///             embedder.
  ///
  /// @attention  The callback will be invoked on the raster task runner. The
  ///             callback can be set on the tests host thread.
  ///
  /// @param[in]  callback  The callback to set. The previous callback will be
  ///                       un-registered.
  ///
  void SetGLPresentCallback(GLPresentCallback callback);

 protected:
  virtual void SetupCompositor() override;

 private:
  // This allows the builder to access the hooks.
  friend class EmbedderConfigBuilder;

  std::unique_ptr<TestGLSurface> gl_surface_;
  size_t gl_surface_present_count_ = 0;
  std::mutex gl_callback_mutex_;
  GLGetFBOCallback gl_get_fbo_callback_;
  GLPresentCallback gl_present_callback_;

  void SetupSurface(SkISize surface_size) override;

  bool GLMakeCurrent();

  bool GLClearCurrent();

  bool GLPresent(uint32_t fbo_id);

  uint32_t GLGetFramebuffer(FlutterFrameInfo frame_info);

  bool GLMakeResourceCurrent();

  void* GLGetProcAddress(const char* name);

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestContextGL);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_GL_H_
