// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flatbuffers/stl_emulation.h"
#include "flutter/impeller/renderer/backend/gles/test/mock_gles.h"
#include "flutter/shell/platform/embedder/embedder_surface_gl_impeller.h"
#include "impeller/renderer/backend/gles/shader_function_gles.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

using ::testing::Not;
using ::testing::StartsWith;

namespace {
EmbedderSurfaceGLSkia::GLDispatchTable StubDispatchTable(
    std::string_view version) {
  impeller::testing::MockGLES::Init(flatbuffers::nullopt, version.data());
  static constexpr auto dummy_always_true = [] { return true; };
  return EmbedderSurfaceGLSkia::GLDispatchTable{
      .gl_make_current_callback = dummy_always_true,
      .gl_clear_current_callback = dummy_always_true,
      .gl_present_callback = [](const auto) { return true; },
      .gl_fbo_callback = [](const auto) { return 0; },
      .gl_make_resource_current_callback = dummy_always_true,
      .gl_surface_transformation_callback = [] { return DlMatrix{}; },
      .gl_proc_resolver = impeller::testing::kMockResolverGLES,
      .gl_populate_existing_damage = [](const auto) { return GLFBOInfo{}; },
  };
}
}  // namespace

TEST(EmbedderSurfaceGLImpellerTest, GLES3ContextHasGLES3Shaders) {
  const auto gl_dispatch_table =
      StubDispatchTable(/* version */ "OpenGL ES 3.0");
  const auto surface = EmbedderSurfaceGLImpeller(
      gl_dispatch_table, /* fbo_reset_after_present */ false,
      /* external_view_embedder */ nullptr,
      /* io_task_runner */ nullptr);

  const std::shared_ptr<impeller::Context> context =
      surface.CreateImpellerContext();
  const std::shared_ptr<impeller::ShaderLibrary> shaders =
      context->GetShaderLibrary();
  const std::shared_ptr<const impeller::ShaderFunction> func =
      shaders->GetFunction("imp_uber_sdf_fragment_main",
                           impeller::ShaderStage::kFragment);
  const auto gles_func = impeller::ShaderFunctionGLES::Cast(func.get());
  const std::shared_ptr<const fml::Mapping> source =
      gles_func->GetSourceMapping();
  const auto text =
      std::string_view(reinterpret_cast<const char*>(source->GetMapping()));
  EXPECT_THAT(text, StartsWith("#version 300 es"));
}

TEST(EmbedderSurfaceGLImpellerTest, GLES2ContextDoesNotHaveGLES3Shaders) {
  const auto gl_dispatch_table =
      StubDispatchTable(/* version */ "OpenGL ES 2.0");
  const auto surface = EmbedderSurfaceGLImpeller(
      gl_dispatch_table, /* fbo_reset_after_present */ false,
      /* external_view_embedder */ nullptr,
      /* io_task_runner */ nullptr);

  const std::shared_ptr<impeller::Context> context =
      surface.CreateImpellerContext();
  const std::shared_ptr<impeller::ShaderLibrary> shaders =
      context->GetShaderLibrary();
  const std::shared_ptr<const impeller::ShaderFunction> func =
      shaders->GetFunction("imp_uber_sdf_fragment_main",
                           impeller::ShaderStage::kFragment);
  const auto gles_func = impeller::ShaderFunctionGLES::Cast(func.get());
  const std::shared_ptr<const fml::Mapping> source =
      gles_func->GetSourceMapping();
  const auto text =
      std::string_view(reinterpret_cast<const char*>(source->GetMapping()));
  EXPECT_THAT(text, StartsWith("#version 100"));
}

TEST(EmbedderSurfaceGLImpellerTest, CreateGPUSurfaceSharesAiksContext) {
  auto mock_gles_impl =
      std::make_unique<::testing::NiceMock<impeller::testing::MockGLESImpl>>();
  ON_CALL(*mock_gles_impl, CreateShader(::testing::_))
      .WillByDefault(::testing::Return(1));
  ON_CALL(*mock_gles_impl, CreateProgram()).WillByDefault(::testing::Return(1));
  ON_CALL(*mock_gles_impl, IsProgram(::testing::_))
      .WillByDefault(::testing::Return(GL_TRUE));
  ON_CALL(*mock_gles_impl, IsTexture(::testing::_))
      .WillByDefault(::testing::Return(GL_TRUE));
  ON_CALL(*mock_gles_impl,
          GetShaderiv(::testing::_, ::testing::_, ::testing::_))
      .WillByDefault([](GLuint shader, GLenum pname, GLint* params) {
        *params = pname == GL_COMPILE_STATUS ? GL_TRUE : 0;
      });
  ON_CALL(*mock_gles_impl,
          GetProgramiv(::testing::_, ::testing::_, ::testing::_))
      .WillByDefault([](GLuint program, GLenum pname, GLint* params) {
        *params = pname == GL_LINK_STATUS ? GL_TRUE : 0;
      });
  ON_CALL(*mock_gles_impl, GenTextures(::testing::_, ::testing::_))
      .WillByDefault([](GLsizei n, GLuint* names) {
        for (GLsizei i = 0; i < n; i++) {
          names[i] = i + 1;
        }
      });
  auto mock_gles = impeller::testing::MockGLES::Init(
      std::move(mock_gles_impl), std::nullopt, "OpenGL ES 3.0");

  bool can_make_current = true;
  EmbedderSurfaceGLSkia::GLDispatchTable gl_dispatch_table{
      .gl_make_current_callback =
          [&can_make_current]() { return can_make_current; },
      .gl_clear_current_callback = [] { return true; },
      .gl_present_callback = [](const auto) { return true; },
      .gl_fbo_callback = [](const auto) { return 0; },
      .gl_make_resource_current_callback = [] { return true; },
      .gl_surface_transformation_callback = [] { return DlMatrix{}; },
      .gl_proc_resolver = impeller::testing::kMockResolverGLES,
      .gl_populate_existing_damage = [](const auto) { return GLFBOInfo{}; },
  };
  auto embedder_surface = EmbedderSurfaceGLImpeller(
      gl_dispatch_table, /* fbo_reset_after_present */ false,
      /* external_view_embedder */ nullptr,
      /* io_task_runner */ nullptr);
  ASSERT_TRUE(embedder_surface.IsValid());

  // If the GL context cannot be made current on first initialization,
  // CreateGPUSurface must fail cleanly without initializing `aiks_context_`.
  can_make_current = false;
  EXPECT_EQ(embedder_surface.CreateGPUSurface(), nullptr);

  can_make_current = true;
  std::unique_ptr<Surface> first_surface = embedder_surface.CreateGPUSurface();
  ASSERT_NE(first_surface, nullptr);
  EXPECT_TRUE(first_surface->IsValid());
  ASSERT_NE(first_surface->GetAiksContext(), nullptr);

  std::unique_ptr<Surface> second_surface = embedder_surface.CreateGPUSurface();
  ASSERT_NE(second_surface, nullptr);
  EXPECT_TRUE(second_surface->IsValid());
  EXPECT_EQ(first_surface->GetAiksContext(), second_surface->GetAiksContext());
}
}  // namespace testing
}  // namespace flutter
