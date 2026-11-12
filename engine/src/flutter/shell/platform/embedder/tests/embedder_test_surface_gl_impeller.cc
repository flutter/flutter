// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <optional>
#include <string>
#include <utility>

#include "flutter/fml/build_config.h"
#include "flutter/impeller/renderer/backend/gles/test/mock_gles.h"
#include "flutter/shell/platform/embedder/embedder_surface_gl_impeller.h"
#include "impeller/renderer/backend/gles/shader_function_gles.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

using ::testing::HasSubstr;
using ::testing::Not;
using ::testing::StartsWith;

namespace {
EmbedderSurfaceGLSkia::GLDispatchTable StubDispatchTable() {
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

std::string GetShaderSource(const EmbedderSurface& surface,
                            const char* name,
                            impeller::ShaderStage stage) {
  const auto context = surface.CreateImpellerContext();
  if (!context || !context->IsValid()) {
    ADD_FAILURE() << "Invalid Impeller context";
    return {};
  }
  const auto shaders = context->GetShaderLibrary();
  if (!shaders) {
    ADD_FAILURE() << "Missing shader library";
    return {};
  }
  const auto function = shaders->GetFunction(name, stage);
  if (!function) {
    ADD_FAILURE() << "Missing bundled shader: " << name;
    return {};
  }
  const auto source =
      impeller::ShaderFunctionGLES::Cast(function.get())->GetSourceMapping();
  if (!source || !source->GetMapping()) {
    ADD_FAILURE() << "Missing bundled shader source: " << name;
    return {};
  }
  return std::string(reinterpret_cast<const char*>(source->GetMapping()),
                     source->GetSize());
}
}  // namespace

TEST(EmbedderSurfaceGLImpellerTest, GLES3ContextHasGLES3Shaders) {
  const auto mock_gles =
      impeller::testing::MockGLES::Init(std::nullopt, "OpenGL ES 3.0");
  const auto gl_dispatch_table = StubDispatchTable();
  const auto surface = EmbedderSurfaceGLImpeller(
      gl_dispatch_table, /* fbo_reset_after_present */ false,
      /* external_view_embedder */ nullptr,
      /* io_task_runner */ nullptr);

  const auto text = GetShaderSource(surface, "imp_uber_sdf_fragment_main",
                                    impeller::ShaderStage::kFragment);
  EXPECT_THAT(text, StartsWith("#version 300 es"));
}

TEST(EmbedderSurfaceGLImpellerTest, GLES2ContextDoesNotHaveGLES3Shaders) {
  const auto mock_gles =
      impeller::testing::MockGLES::Init(std::nullopt, "OpenGL ES 2.0");
  const auto gl_dispatch_table = StubDispatchTable();
  const auto surface = EmbedderSurfaceGLImpeller(
      gl_dispatch_table, /* fbo_reset_after_present */ false,
      /* external_view_embedder */ nullptr,
      /* io_task_runner */ nullptr);

  const auto text = GetShaderSource(surface, "imp_uber_sdf_fragment_main",
                                    impeller::ShaderStage::kFragment);
  EXPECT_THAT(text, StartsWith("#version 100"));
}

#if FML_OS_LINUX && IMPELLER_ENABLE_OPENGLES
TEST(EmbedderSurfaceGLImpellerTest, SelectsBundledPlainFragmentUniforms) {
  constexpr char kVersion[] = "OpenGL ES 3.2 v1.g24p0-00eac0";
  struct TestCase {
    const char* renderer;
    GLint max_fragment_uniform_vectors;
    bool expect_plain_uniforms;
  };
  const TestCase test_cases[] = {
      {"Mali-G52", 4096, true},
      {"Adreno (TM) 740", 4096, false},
      {"Mali-G52", 4095, false},
  };
  for (const auto& test_case : test_cases) {
    SCOPED_TRACE(::testing::Message()
                 << test_case.renderer << ", "
                 << test_case.max_fragment_uniform_vectors);
    auto impl = std::make_unique<
        ::testing::NiceMock<impeller::testing::MockGLESImpl>>();
    ON_CALL(*impl, GetIntegerv(GL_MAX_FRAGMENT_UNIFORM_VECTORS, ::testing::_))
        .WillByDefault(::testing::SetArgPointee<1>(
            test_case.max_fragment_uniform_vectors));
    const auto mock_gles = impeller::testing::MockGLES::Init(
        std::move(impl), std::nullopt, kVersion, test_case.renderer);
    const auto surface = EmbedderSurfaceGLImpeller(
        StubDispatchTable(), /*fbo_reset_after_present=*/false,
        /*external_view_embedder=*/nullptr, /*io_task_runner=*/nullptr);
    for (const auto* name : {"imp_solid_fill_fragment_main",
                             "imp_framebuffer_blend_fragment_main"}) {
      SCOPED_TRACE(name);
      const auto source =
          GetShaderSource(surface, name, impeller::ShaderStage::kFragment);
      EXPECT_THAT(source, StartsWith("#version 300 es"));
      if (test_case.expect_plain_uniforms) {
        EXPECT_THAT(source, HasSubstr("uniform FragInfo frag_info;"));
        EXPECT_THAT(source, Not(HasSubstr("layout(std140)")));
      } else {
        EXPECT_THAT(source, HasSubstr("layout(std140)"));
        EXPECT_THAT(source, Not(HasSubstr("uniform FragInfo frag_info;")));
      }
    }

    const auto vertex = GetShaderSource(surface, "imp_solid_fill_vertex_main",
                                        impeller::ShaderStage::kVertex);
    EXPECT_THAT(vertex, HasSubstr("layout(std140)"));
    EXPECT_THAT(vertex, HasSubstr("uniform FrameInfo"));
    const auto ssbo =
        GetShaderSource(surface, "imp_linear_gradient_ssbo_fill_fragment_main",
                        impeller::ShaderStage::kFragment);
    EXPECT_THAT(ssbo, HasSubstr("buffer ColorData"));
    EXPECT_THAT(ssbo, HasSubstr("uniform FragInfo"));
    EXPECT_THAT(ssbo, Not(HasSubstr("uniform FragInfo frag_info;")));
  }
}
#endif  // FML_OS_LINUX && IMPELLER_ENABLE_OPENGLES
}  // namespace testing
}  // namespace flutter
