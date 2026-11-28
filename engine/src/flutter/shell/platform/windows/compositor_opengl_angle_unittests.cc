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

// Equal filters sharing an ID can draw their children directly into the parent
// pass. The independent backdrop can be the last one that needs a fresh read
// even though a grouped child still needs the destination afterwards.
sk_sp<DisplayList> MakeGroupedBackdropScene(bool interleaved,
                                            bool blend_child) {
  DisplayListBuilder builder;
  builder.DrawPaint(DlPaint(DlColor(0xff204087)));
  builder.DrawRect(DlRect::MakeLTRB(1, 0, 13, 24),
                   DlPaint(DlColor(0xffe72c15)));
  builder.DrawRect(DlRect::MakeLTRB(10, 16, 31, 21),
                   DlPaint(DlColor(0xff25a849)));
  const auto blur = DlImageFilter::MakeBlur(2, 2, DlTileMode::kClamp);
  auto panel = [&](DlRect clip, std::optional<int64_t> backdrop_id) {
    builder.Save();
    builder.ClipRect(clip, DlClipOp::kIntersect, false);
    builder.SaveLayer(std::nullopt, nullptr, blur.get(), backdrop_id);
    if (blend_child && backdrop_id.has_value()) {
      builder.DrawRect(
          DlRect::MakeLTRB(4, 5, 28, 20),
          DlPaint(DlColor(0xff49c3e1)).setBlendMode(DlBlendMode::kDifference));
    }
    builder.DrawRect(clip, DlPaint(DlColor(0x10141414)));
    builder.Restore();
    builder.Restore();
  };
  panel(DlRect::MakeLTRB(2, 2, 21, 18), 7);
  if (interleaved) {
    panel(DlRect::MakeLTRB(0, 0, 8, 8), std::nullopt);
  }
  panel(DlRect::MakeLTRB(12, 8, 29, 23), 7);
  return builder.Build();
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
  store.struct_size = sizeof(store);
  ASSERT_TRUE(compositor.CreateBackingStore(config, &store));
  fml::ScopedCleanupClosure release(
      [&] { EXPECT_TRUE(compositor.CollectBackingStore(&store)); });
  impeller::ProcTableGLES gl{kEGLResolver};
  ASSERT_TRUE(gl.IsValid());
  if (!GetParam().enable_impeller) {
    EXPECT_FALSE(compositor.SupportsDirectMSAA4Rendering(store));
    return;
  }
  if (gl.GetDescription()->GetGlVersion().major_version < 3 ||
      gl.GetCapabilities()->SupportsImplicitResolvingMSAA() ||
      !gl.GetCapabilities()->SupportsOffscreenMSAA() ||
      store.open_gl.framebuffer.target != GL_BGRA8_EXT) {
    GTEST_SKIP()
        << "Requires the Windows compositor's explicit BGRA8 MSAA target.";
  }
  const auto fbo = store.open_gl.framebuffer.name;
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
  auto wrap_store = [&](const FlutterBackingStore& backing_store,
                        bool supports_direct_msaa4_rendering) {
    auto wrapped = impeller::SurfaceGLES::WrapFBO(
        surface->CreateImpellerContext(), [] { return true; },
        backing_store.open_gl.framebuffer.name,
        impeller::PixelFormat::kB8G8R8A8UNormInt, {32, 24});
    if (!wrapped) {
      return std::unique_ptr<EmbedderRenderTargetImpeller>{};
    }
    return std::make_unique<EmbedderRenderTargetImpeller>(
        backing_store, gpu_surface->GetAiksContext(),
        std::make_unique<impeller::RenderTarget>(wrapped->GetRenderTarget()),
        nullptr, nullptr, supports_direct_msaa4_rendering);
  };
  auto owned =
      wrap_store(store, compositor.SupportsDirectMSAA4Rendering(store));
  // A custom embedder can report the same format and FBO name. Its attachment
  // lifetime is independent of the Windows compositor's.
  auto external_store = store;
  auto external = wrap_store(external_store, false);
  ASSERT_TRUE(owned && external);
  DisplayListBuilder builder;
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
  ASSERT_TRUE(owned->GetImpellerRenderTarget()->HasVerifiedExternalMSAA4());
  ASSERT_FALSE(external->GetImpellerRenderTarget()->HasVerifiedExternalMSAA4());

  GLuint readback_fbo;
  std::array<GLuint, 2> readback_buffers;
  gl.GenFramebuffers(1, &readback_fbo);
  gl.GenRenderbuffers(2, readback_buffers.data());
  fml::ScopedCleanupClosure clean([&] {
    gl.DeleteFramebuffers(1, &readback_fbo);
    gl.DeleteRenderbuffers(2, readback_buffers.data());
  });
  gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, readback_fbo);
  gl.BindRenderbuffer(GL_RENDERBUFFER, readback_buffers[0]);
  gl.RenderbufferStorage(GL_RENDERBUFFER, GL_BGRA8_EXT, 32, 24);
  gl.FramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                             GL_RENDERBUFFER, readback_buffers[0]);
  ASSERT_EQ(gl.CheckFramebufferStatus(GL_DRAW_FRAMEBUFFER),
            static_cast<GLenum>(GL_FRAMEBUFFER_COMPLETE));
  using Pixels = std::array<uint8_t, 32 * 24 * 4>;
  auto render_and_read = [&](EmbedderRenderTargetImpeller& target,
                             const sk_sp<DisplayList>& scene, Pixels& pixels) {
    gl.BindFramebuffer(GL_FRAMEBUFFER, fbo);
    gl.Disable(GL_SCISSOR_TEST);
    gl.ColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    gl.ClearColor(1, 0, 1, 1);
    gl.Clear(GL_COLOR_BUFFER_BIT);
    ASSERT_TRUE(impeller::RenderToTarget(
        target.GetAiksContext()->GetContentContext(),
        *target.GetImpellerRenderTarget(), scene,
        DlRect::MakeLTRB(0, 0, 32, 24), /*reset_host_buffer=*/true,
        /*is_onscreen=*/false));
    gl.Disable(GL_SCISSOR_TEST);
    gl.BindFramebuffer(GL_READ_FRAMEBUFFER, fbo);
    gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, readback_fbo);
    gl.BlitFramebuffer(0, 0, 32, 24, 0, 0, 32, 24, GL_COLOR_BUFFER_BIT,
                       GL_NEAREST);
    gl.BindFramebuffer(GL_READ_FRAMEBUFFER, readback_fbo);
    gl.ReadPixels(0, 0, 32, 24, GL_RGBA, GL_UNSIGNED_BYTE, pixels.data());
    gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, fbo);
    ExpectNoGLError();
  };
  Pixels original{}, fallback{};
  ASSERT_NO_FATAL_FAILURE(render_and_read(*owned, backdrop, original));
  ASSERT_NO_FATAL_FAILURE(render_and_read(*external, backdrop, fallback));
  EXPECT_EQ(original, fallback);
  EXPECT_EQ(original[0], 255u);           // Opaque red at the left edge.
  EXPECT_EQ(original[31 * 4 + 3], 128u);  // Translucent blue at the right.
  EXPECT_GT(original[(12 * 32 + 16) * 4 + 1], 32u);  // Green inside the clip.

  for (bool interleaved : {false, true}) {
    SCOPED_TRACE(interleaved);
    auto grouped = MakeGroupedBackdropScene(interleaved, /*blend_child=*/true);
    auto control = MakeGroupedBackdropScene(interleaved, /*blend_child=*/false);
    ASSERT_TRUE(grouped->root_has_backdrop_filter());
    ASSERT_LE(grouped->max_root_blend_mode(), DlBlendMode::kModulate);
    Pixels without_child{};
    ASSERT_NO_FATAL_FAILURE(render_and_read(*external, control, without_child));
    ASSERT_NO_FATAL_FAILURE(render_and_read(*external, grouped, fallback));
    ASSERT_NE(fallback, without_child);
    ASSERT_NO_FATAL_FAILURE(render_and_read(*owned, grouped, original));
    EXPECT_EQ(original, fallback);
  }

  // Deleting the attachments of an unbound FBO retires their names while the
  // FBO retains their storage. Importing the FBO must never rebind those names.
  gl.BindFramebuffer(GL_FRAMEBUFFER, readback_fbo);
  gl.BindRenderbuffer(GL_RENDERBUFFER, readback_buffers[1]);
  gl.RenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, 32, 24);
  gl.FramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT,
                             GL_RENDERBUFFER, readback_buffers[1]);
  gl.BindFramebuffer(GL_FRAMEBUFFER, fbo);
  const auto retired = readback_buffers;
  gl.DeleteRenderbuffers(2, retired.data());
  readback_buffers.fill(0);
  external_store.open_gl.framebuffer.name = readback_fbo;
  auto retired_target = wrap_store(external_store, false);
  ASSERT_TRUE(retired_target);
  EXPECT_FALSE(
      retired_target->GetImpellerRenderTarget()->HasVerifiedExternalMSAA4());
  EXPECT_FALSE(gl.IsRenderbuffer(retired[0]));
  EXPECT_FALSE(gl.IsRenderbuffer(retired[1]));
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
