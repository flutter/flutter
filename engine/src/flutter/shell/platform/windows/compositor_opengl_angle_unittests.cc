// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <optional>

#include "flutter/impeller/renderer/backend/gles/gles.h"
#include "flutter/shell/platform/windows/compositor_opengl.h"
#include "flutter/shell/platform/windows/egl/manager.h"
#include "flutter/shell/platform/windows/flutter_window.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

// Resolves OpenGL procedures through EGL, as the engine does.
const impeller::ProcTableGLES::Resolver kEGLResolver =
    [](const char* name) -> void* {
  return reinterpret_cast<void*>(::eglGetProcAddress(name));
};

// Verifies that |framebuffer| is complete on the current context.
void ExpectFramebufferComplete(GLuint framebuffer) {
  impeller::ProcTableGLES gl{kEGLResolver};
  ASSERT_TRUE(gl.IsValid());

  gl.BindFramebuffer(GL_FRAMEBUFFER, framebuffer);
  EXPECT_EQ(gl.CheckFramebufferStatus(GL_FRAMEBUFFER),
            static_cast<GLenum>(GL_FRAMEBUFFER_COMPLETE));
}

// Verifies that no GL error is pending on the current context. GL reports
// failed calls this way rather than through return values.
void ExpectNoGLError() {
  auto get_error =
      reinterpret_cast<PFNGLGETERRORPROC>(kEGLResolver("glGetError"));
  ASSERT_NE(get_error, nullptr);
  EXPECT_EQ(get_error(), static_cast<GLenum>(GL_NO_ERROR));
}

struct TestParams {
  // The test's name suffix.
  const char* name;
  // Whether the compositor is configured for Impeller rather than Skia.
  bool enable_impeller;
  // Caps the D3D11 feature level ANGLE may use. At 10_0 it only creates OpenGL
  // ES 2.0 contexts, like the GPUs where
  // https://github.com/flutter/flutter/issues/191978 left the window black.
  std::optional<egl::D3DFeatureLevel> max_feature_level;
};

// Tests the compositor against ANGLE, unlike CompositorOpenGLTest in
// compositor_opengl_unittests.cc, which uses mocked EGL and OpenGL.
class CompositorOpenGLANGLETest
    : public WindowsTest,
      public ::testing::WithParamInterface<TestParams> {
 public:
  CompositorOpenGLANGLETest() = default;
  virtual ~CompositorOpenGLANGLETest() = default;

 protected:
  void TearDown() override {
    // The compositor leaves the render context current on this thread.
    // Release it before the engine destroys it, or ANGLE crashes the next test
    // that reuses the display.
    if (engine_ && engine_->egl_manager() &&
        engine_->egl_manager()->render_context()) {
      engine_->egl_manager()->render_context()->ClearCurrent();
    }
    WindowsTest::TearDown();
  }

  FlutterWindowsEngine* engine() { return engine_.get(); }
  FlutterWindowsView* view() { return view_.get(); }

  void UseHeadlessEngine() {
    auto egl_manager = egl::Manager::Create(egl::GpuPreference::NoPreference,
                                            /*allow_inverted_surface=*/false,
                                            GetParam().max_feature_level);
    EXPECT_NE(egl_manager, nullptr);

    FlutterWindowsEngineBuilder builder{GetContext()};

    engine_ = builder.Build();
    EngineModifier modifier{engine_.get()};
    modifier.SetEGLManager(std::move(egl_manager));
  }

  // Adds a view with a real window and surface to the engine.
  void UseEngineWithView() {
    UseHeadlessEngine();

    auto window = std::make_unique<FlutterWindow>(
        320, 240, engine_->display_manager(), engine_->windows_proc_table());
    view_ = std::make_unique<FlutterWindowsView>(kImplicitViewId, engine_.get(),
                                                 std::move(window), false,
                                                 BoxConstraints());
    view_->CreateRenderSurface();
  }

 private:
  std::unique_ptr<FlutterWindowsEngine> engine_;
  std::unique_ptr<FlutterWindowsView> view_;

  FML_DISALLOW_COPY_AND_ASSIGN(CompositorOpenGLANGLETest);
};

}  // namespace

INSTANTIATE_TEST_SUITE_P(
    RendererAndFeatureLevel,
    CompositorOpenGLANGLETest,
    ::testing::Values(
        TestParams{.name = "SkiaFeatureLevelDefault",
                   .enable_impeller = false,
                   .max_feature_level = std::nullopt},
        TestParams{.name = "ImpellerFeatureLevelDefault",
                   .enable_impeller = true,
                   .max_feature_level = std::nullopt},
        TestParams{.name = "SkiaFeatureLevel10_0",
                   .enable_impeller = false,
                   .max_feature_level = egl::D3DFeatureLevel{10, 0}},
        TestParams{.name = "ImpellerFeatureLevel10_0",
                   .enable_impeller = true,
                   .max_feature_level = egl::D3DFeatureLevel{10, 0}}),
    [](const ::testing::TestParamInfo<TestParams>& info) {
      return std::string(info.param.name);
    });

TEST_P(CompositorOpenGLANGLETest, CreateBackingStore) {
  UseHeadlessEngine();

  auto compositor =
      CompositorOpenGL{engine(), kEGLResolver, GetParam().enable_impeller};
  FlutterBackingStoreConfig config = {};
  config.size = {320, 240};
  FlutterBackingStore backing_store = {};

  ASSERT_TRUE(compositor.CreateBackingStore(config, &backing_store));
  ExpectNoGLError();
  ExpectFramebufferComplete(backing_store.open_gl.framebuffer.name);
  ASSERT_TRUE(compositor.CollectBackingStore(&backing_store));
}

TEST_P(CompositorOpenGLANGLETest, Present) {
  UseEngineWithView();

  auto compositor =
      CompositorOpenGL{engine(), kEGLResolver, GetParam().enable_impeller};
  FlutterBackingStoreConfig config = {};
  config.size = {320, 240};
  FlutterBackingStore backing_store = {};

  ASSERT_TRUE(compositor.CreateBackingStore(config, &backing_store));
  ExpectNoGLError();

  FlutterLayer layer = {};
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &backing_store;
  layer.size = {320, 240};
  const FlutterLayer* layer_ptr = &layer;

  EXPECT_TRUE(compositor.Present(view(), &layer_ptr, 1));
  ExpectNoGLError();

  ASSERT_TRUE(compositor.CollectBackingStore(&backing_store));
}

}  // namespace testing
}  // namespace flutter
