// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include <memory>
#include <optional>

#include "flutter/display_list/dl_builder.h"
#include "flutter/fml/closure.h"
#include "flutter/impeller/display_list/aiks_context.h"
#include "flutter/impeller/display_list/dl_dispatcher.h"
#include "flutter/impeller/renderer/backend/gles/gles.h"
#include "flutter/impeller/renderer/backend/gles/surface_gles.h"
#include "flutter/impeller/renderer/backend/gles/windows_backdrop_target.h"
#include "flutter/shell/platform/embedder/embedder_render_target_impeller.h"
#include "flutter/shell/platform/embedder/embedder_surface_gl_impeller.h"
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

TEST_P(CompositorOpenGLANGLETest, VerifyExternalBackdropFramebuffer) {
  UseHeadlessEngine();
  CompositorOpenGL compositor(engine(), kEGLResolver,
                              GetParam().enable_impeller);
  FlutterBackingStoreConfig config = {};
  config.size = {32, 24};
  FlutterBackingStore store = {};
  ASSERT_TRUE(compositor.CreateBackingStore(config, &store));
  fml::ScopedCleanupClosure release(
      [&] { EXPECT_TRUE(compositor.CollectBackingStore(&store)); });
  impeller::ProcTableGLES gl{kEGLResolver};
  ASSERT_TRUE(gl.IsValid());
  if (gl.GetDescription()->GetGlVersion().major_version < 3) {
    GTEST_SKIP() << "The external framebuffer guard requires GLES 3.";
  }
  const auto fbo = store.open_gl.framebuffer.name;
  if (!GetParam().enable_impeller) {
    EXPECT_FALSE(impeller::IsCompatibleWindowsBackdropTarget(gl, fbo, 32, 24));
    return;
  }
  if (gl.GetCapabilities()->SupportsImplicitResolvingMSAA() ||
      !gl.GetCapabilities()->SupportsOffscreenMSAA() ||
      store.open_gl.framebuffer.target != GL_BGRA8_EXT) {
    GTEST_SKIP()
        << "The framebuffer mutations require a BGRA8 MSAA renderbuffer.";
  }
  auto* egl_context = engine()->egl_manager()->render_context();
  EmbedderSurfaceGLSkia::GLDispatchTable dispatch = {};
  dispatch.gl_make_current_callback = [&] {
    return egl_context->MakeCurrent();
  };
  dispatch.gl_clear_current_callback = [&] {
    return egl_context->ClearCurrent();
  };
  dispatch.gl_present_callback = [](auto) { return true; };
  dispatch.gl_fbo_callback = [fbo](auto) { return fbo; };
  dispatch.gl_populate_existing_damage = [](auto) { return GLFBOInfo{}; };
  dispatch.gl_proc_resolver = kEGLResolver;
  const std::unique_ptr<EmbedderSurface> surface =
      std::make_unique<EmbedderSurfaceGLImpeller>(
          std::move(dispatch), false, nullptr, nullptr,
          impeller::Flags{.top_left_default_framebuffer_origin = true});
  ASSERT_TRUE(surface->IsValid());
  auto gpu_surface = surface->CreateGPUSurface();
  ASSERT_TRUE(gpu_surface->IsValid());
  auto wrapped = impeller::SurfaceGLES::WrapFBO(
      surface->CreateImpellerContext(), [] { return true; }, fbo,
      impeller::PixelFormat::kB8G8R8A8UNormInt, {32, 24});
  ASSERT_TRUE(wrapped);
  EmbedderRenderTargetImpeller cached(
      store, gpu_surface->GetAiksContext(),
      std::make_unique<impeller::RenderTarget>(wrapped->GetRenderTarget()),
      nullptr, nullptr);
  DisplayListBuilder builder;
  builder.DrawPaint(DlPaint());
  auto plain = builder.Build();
  const auto blur = DlImageFilter::MakeBlur(3, 3, DlTileMode::kClamp);
  builder.DrawPaint(
      DlPaint(DlColor(0x800000ff)).setBlendMode(DlBlendMode::kSrc));
  builder.DrawRect(DlRect::MakeLTRB(0, 0, 12, 24), DlPaint(DlColor::kRed()));
  builder.Save();
  builder.ClipOval(DlRect::MakeLTRB(4, 4, 28, 20), DlClipOp::kIntersect, true);
  builder.SaveLayer(std::nullopt, nullptr, blur.get());
  builder.DrawPaint(DlPaint(DlColor(0x8000ff00)));
  builder.Restore();
  builder.DrawCircle({18, 12}, 8, DlPaint(DlColor(0x40ffffff)));
  builder.Restore();
  auto backdrop = builder.Build();
  ASSERT_TRUE(backdrop->root_has_backdrop_filter());
  ASSERT_FALSE(cached.GetImpellerRenderTargetForDisplayList(*plain)
                   .HasVerifiedExternalMSAA4());
  GLuint framebuffers[3], renderbuffers[3];
  gl.GenFramebuffers(3, framebuffers);
  gl.GenRenderbuffers(3, renderbuffers);
  fml::ScopedCleanupClosure clean([&] {
    gl.DeleteFramebuffers(3, framebuffers);
    gl.DeleteRenderbuffers(3, renderbuffers);
  });
  gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffers[2]);
  gl.BindRenderbuffer(GL_RENDERBUFFER, renderbuffers[2]);
  gl.RenderbufferStorage(GL_RENDERBUFFER, GL_BGRA8_EXT, 32, 24);
  gl.FramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                             GL_RENDERBUFFER, renderbuffers[2]);
  ASSERT_EQ(gl.CheckFramebufferStatus(GL_DRAW_FRAMEBUFFER),
            static_cast<GLenum>(GL_FRAMEBUFFER_COMPLETE));
  using Pixels = std::array<uint8_t, 32 * 24 * 4>;
  auto render_and_read = [&](Pixels& pixels) {
    gl.BindFramebuffer(GL_FRAMEBUFFER, fbo);
    gl.Disable(GL_SCISSOR_TEST);
    gl.ColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    gl.ClearColor(1, 0, 1, 1);
    gl.Clear(GL_COLOR_BUFFER_BIT);
    ASSERT_TRUE(impeller::RenderToTarget(
        cached.GetAiksContext()->GetContentContext(),
        cached.GetImpellerRenderTargetForDisplayList(*backdrop), backdrop,
        DlRect::MakeLTRB(0, 0, 32, 24), /*reset_host_buffer=*/true,
        /*is_onscreen=*/false));
    gl.Disable(GL_SCISSOR_TEST);
    gl.BindFramebuffer(GL_READ_FRAMEBUFFER, fbo);
    gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffers[2]);
    gl.BlitFramebuffer(0, 0, 32, 24, 0, 0, 32, 24, GL_COLOR_BUFFER_BIT,
                       GL_NEAREST);
    gl.BindFramebuffer(GL_READ_FRAMEBUFFER, framebuffers[2]);
    gl.ReadPixels(0, 0, 32, 24, GL_RGBA, GL_UNSIGNED_BYTE, pixels.data());
    gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, fbo);
    ExpectNoGLError();
  };
  auto binding = [&](GLenum key) {
    GLint value;
    gl.GetIntegerv(key, &value);
    return static_cast<GLuint>(value);
  };
  auto check = [&](bool expected) {
    ASSERT_EQ(gl.CheckFramebufferStatus(GL_DRAW_FRAMEBUFFER),
              static_cast<GLenum>(GL_FRAMEBUFFER_COMPLETE));
    gl.BindFramebuffer(GL_READ_FRAMEBUFFER, framebuffers[0]);
    gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffers[1]);
    gl.BindRenderbuffer(GL_RENDERBUFFER, renderbuffers[0]);
    EXPECT_EQ(cached.GetImpellerRenderTargetForDisplayList(*backdrop)
                  .HasVerifiedExternalMSAA4(),
              expected);
    EXPECT_FALSE(cached.GetImpellerRenderTarget()->HasVerifiedExternalMSAA4());
    EXPECT_EQ(binding(GL_READ_FRAMEBUFFER_BINDING), framebuffers[0]);
    EXPECT_EQ(binding(GL_DRAW_FRAMEBUFFER_BINDING), framebuffers[1]);
    EXPECT_EQ(binding(GL_RENDERBUFFER_BINDING), renderbuffers[0]);
    gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, fbo);
  };
  gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, fbo);
  check(true);
  Pixels original{}, fallback{}, repaired{};
  render_and_read(original);
  EXPECT_EQ(original[0], 255u);           // Opaque red at the left edge.
  EXPECT_EQ(original[31 * 4 + 3], 128u);  // Translucent blue at the right.
  EXPECT_GT(original[(12 * 32 + 16) * 4 + 1], 32u);  // Green inside the clip.

  GLint stencil = 0;
  gl.GetFramebufferAttachmentParameteriv(
      GL_DRAW_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
      GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME, &stencil);
  gl.FramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                             GL_RENDERBUFFER, 0);
  check(false);
  gl.FramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                             GL_RENDERBUFFER, 0);
  check(false);
  render_and_read(fallback);
  EXPECT_EQ(original, fallback);
  gl.FramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT,
                             GL_RENDERBUFFER, stencil);
  check(true);
  render_and_read(repaired);
  EXPECT_EQ(original, repaired);

  gl.BindRenderbuffer(GL_RENDERBUFFER, renderbuffers[1]);
  gl.RenderbufferStorageMultisample(GL_RENDERBUFFER, 4, GL_RGBA8, 32, 24);
  gl.FramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT1,
                             GL_RENDERBUFFER, renderbuffers[1]);
  check(true);
  const GLenum outputs[] = {GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1};
  auto draw_buffers =
      reinterpret_cast<PFNGLDRAWBUFFERSPROC>(kEGLResolver("glDrawBuffers"));
  ASSERT_NE(draw_buffers, nullptr);
  draw_buffers(2, outputs);
  check(false);
  draw_buffers(1, outputs);
  gl.FramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT1,
                             GL_RENDERBUFFER, 0);
  gl.FramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                             GL_RENDERBUFFER, renderbuffers[1]);
  check(false);
  ExpectNoGLError();
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
