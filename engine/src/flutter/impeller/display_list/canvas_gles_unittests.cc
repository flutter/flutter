// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include <cstring>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <string_view>
#include <vector>

#include "flutter/fml/mapping.h"
#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/display_list/canvas.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/gles/entity_shaders_gles.h"
#include "impeller/entity/gles/framebuffer_blend_shaders_gles.h"
#include "impeller/entity/gles/modern_shaders_gles.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/render_target.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"

namespace impeller {
namespace testing {

namespace {

using ::testing::_;
using ::testing::IsEmpty;
using ::testing::NiceMock;
using ::testing::Return;
using ::testing::SetArgPointee;

class MockReactorWorker final : public ReactorGLES::Worker {
 public:
  // |ReactorGLES::Worker|
  bool CanReactorReactOnCurrentThreadNow(
      const ReactorGLES& reactor) const override {
    return true;
  }
};

std::vector<std::shared_ptr<fml::Mapping>> ShaderLibraryMappings() {
  return {
      std::make_shared<fml::NonOwnedMapping>(
          impeller_entity_shaders_gles_data,
          impeller_entity_shaders_gles_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_modern_shaders_gles_data,
          impeller_modern_shaders_gles_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_framebuffer_blend_shaders_gles_data,
          impeller_framebuffer_blend_shaders_gles_length),
  };
}

/// The sampler uniforms every mocked program reports as active, so the backend
/// binds the textures the entity shaders sample from.
constexpr std::array<std::string_view, 4> kSamplerUniforms = {
    "texture_sampler",
    "texture_sampler_dst",
    "texture_sampler_src",
    "color_source_sampler",
};

/// Drives a |MockGLESImpl| with just enough OpenGL ES state tracking to tell
/// which textures each draw samples and which texture it renders into.
///
/// A draw that samples the color attachment of the framebuffer it renders to
/// is a feedback loop, which is undefined behavior. ANGLE on Direct3D 11, for
/// example, samples zeros.
class FeedbackLoopDetector {
 public:
  explicit FeedbackLoopDetector(NiceMock<MockGLESImpl>& gl) {
    // Pipelines compile, link, and report the sampler uniforms as active.
    ON_CALL(gl, CreateShader(_)).WillByDefault(Return(1));
    ON_CALL(gl, CreateProgram()).WillByDefault(Return(1));
    ON_CALL(gl, IsProgram(_)).WillByDefault(Return(GL_TRUE));
    ON_CALL(gl, GetShaderiv(_, GL_COMPILE_STATUS, _))
        .WillByDefault(SetArgPointee<2>(GL_TRUE));
    ON_CALL(gl, GetProgramiv(_, _, _))
        .WillByDefault([](GLuint program, GLenum pname, GLint* params) {
          switch (pname) {
            case GL_LINK_STATUS:
              *params = GL_TRUE;
              break;
            case GL_ACTIVE_UNIFORMS:
              *params = kSamplerUniforms.size();
              break;
            case GL_ACTIVE_UNIFORM_MAX_LENGTH:
              *params = 64;
              break;
          }
        });
    ON_CALL(gl, GetActiveUniform(_, _, _, _, _, _, _))
        .WillByDefault([](GLuint program, GLuint index, GLsizei buf_size,
                          GLsizei* length, GLint* size, GLenum* type,
                          GLchar* name) {
          std::string_view uniform = kSamplerUniforms[index];
          std::memcpy(name, uniform.data(), uniform.size());
          name[uniform.size()] = '\0';
          *length = uniform.size();
          *size = 1;
          *type = GL_SAMPLER_2D;
        });
    ON_CALL(gl, GetUniformLocation(_, _))
        .WillByDefault([](GLuint program, const GLchar* name) -> GLint {
          for (size_t i = 0; i < kSamplerUniforms.size(); i++) {
            if (kSamplerUniforms[i] == name) {
              return i;
            }
          }
          return -1;
        });
    ON_CALL(gl, GetIntegerv(_, _)).WillByDefault([](GLenum name, GLint* value) {
      if (name == GL_MAX_TEXTURE_IMAGE_UNITS ||
          name == GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS) {
        *value = 8;
      }
    });

    // Every texture and framebuffer gets a distinct name.
    ON_CALL(gl, GenTextures(_, _))
        .WillByDefault(
            [this](GLsizei n, GLuint* names) { GenNames(n, names); });
    ON_CALL(gl, GenFramebuffers(_, _))
        .WillByDefault(
            [this](GLsizei n, GLuint* names) { GenNames(n, names); });
    ON_CALL(gl, IsTexture(_)).WillByDefault(Return(GL_TRUE));
    ON_CALL(gl, CheckFramebufferStatus(_))
        .WillByDefault(Return(GL_FRAMEBUFFER_COMPLETE));

    // Track the framebuffer being rendered to and its color attachment.
    ON_CALL(gl, BindFramebuffer(_, _))
        .WillByDefault([this](GLenum target, GLuint framebuffer) {
          if (target == GL_FRAMEBUFFER || target == GL_DRAW_FRAMEBUFFER) {
            std::scoped_lock lock(mutex_);
            draw_framebuffer_ = framebuffer;
          }
        });
    ON_CALL(gl, FramebufferTexture2D(_, GL_COLOR_ATTACHMENT0, _, _, _))
        .WillByDefault([this](GLenum target, GLenum attachment,
                              GLenum textarget, GLuint texture, GLint level) {
          std::scoped_lock lock(mutex_);
          color_attachments_[draw_framebuffer_] = texture;
        });

    // Track the textures bound to sampler uniforms.
    ON_CALL(gl, ActiveTexture(_)).WillByDefault([this](GLenum texture) {
      std::scoped_lock lock(mutex_);
      active_unit_ = texture - GL_TEXTURE0;
    });
    ON_CALL(gl, BindTexture(_, _))
        .WillByDefault([this](GLenum target, GLuint texture) {
          std::scoped_lock lock(mutex_);
          texture_units_[active_unit_] = texture;
        });
    ON_CALL(gl, Uniform1i(_, _))
        .WillByDefault([this](GLint location, GLint v0) {
          std::scoped_lock lock(mutex_);
          sampled_textures_.insert(texture_units_[v0]);
        });

    ON_CALL(gl, DrawArrays(_, _, _)).WillByDefault([this](auto...) { Draw(); });
    ON_CALL(gl, DrawElements(_, _, _, _)).WillByDefault([this](auto...) {
      Draw();
    });
  }

  /// The number of draws that sampled at least one texture.
  size_t GetSamplingDrawCount() const {
    std::scoped_lock lock(mutex_);
    return sampling_draw_count_;
  }

  /// The textures that were sampled by a draw rendering into them.
  std::vector<GLuint> GetFeedbackLoopTextures() const {
    std::scoped_lock lock(mutex_);
    return feedback_loop_textures_;
  }

 private:
  mutable std::mutex mutex_;
  GLuint next_name_ = 1;
  GLuint draw_framebuffer_ = 0;
  GLenum active_unit_ = 0;
  std::map<GLuint, GLuint> color_attachments_;
  std::map<GLenum, GLuint> texture_units_;
  std::set<GLuint> sampled_textures_;
  size_t sampling_draw_count_ = 0;
  std::vector<GLuint> feedback_loop_textures_;

  void GenNames(GLsizei n, GLuint* names) {
    std::scoped_lock lock(mutex_);
    for (GLsizei i = 0; i < n; i++) {
      names[i] = next_name_++;
    }
  }

  void Draw() {
    std::scoped_lock lock(mutex_);
    if (!sampled_textures_.empty()) {
      sampling_draw_count_++;
    }
    auto target = color_attachments_.find(draw_framebuffer_);
    if (target != color_attachments_.end() &&
        sampled_textures_.contains(target->second)) {
      feedback_loop_textures_.push_back(target->second);
    }
    sampled_textures_.clear();
  }
};

}  // namespace

// Emulates a device without offscreen MSAA and without framebuffer fetch, for
// example ANGLE on a Direct3D 11 feature level 10_0 device. The mock driver
// advertises neither GL_EXT_multisampled_render_to_texture nor
// GL_EXT_shader_framebuffer_fetch, so the capabilities come from the real
// OpenGL ES backend instead of being overridden.
TEST(CanvasGLESTest, AdvancedBlendWithoutOffscreenMSAAHasNoFeedbackLoop) {
  auto mock_gles_impl = std::make_unique<NiceMock<MockGLESImpl>>();
  FeedbackLoopDetector detector(*mock_gles_impl);
  std::shared_ptr<MockGLES> mock_gles = MockGLES::Init(
      std::move(mock_gles_impl), /*extensions=*/std::nullopt, "OpenGL ES 2.0");

  std::shared_ptr<ContextGLES> context_gles = ContextGLES::Create(
      Flags{}, std::make_unique<ProcTableGLES>(kMockResolverGLES),
      ShaderLibraryMappings(),
      /*enable_gpu_tracing=*/false);
  ASSERT_TRUE(context_gles);
  auto worker = std::make_shared<MockReactorWorker>();
  context_gles->AddReactorWorker(worker);
  std::shared_ptr<Context> context = context_gles;
  ASSERT_TRUE(context->IsValid());

  const std::shared_ptr<const Capabilities>& capabilities =
      context->GetCapabilities();
  ASSERT_FALSE(capabilities->SupportsOffscreenMSAA());
  ASSERT_FALSE(capabilities->SupportsFramebufferFetch());

  ContentContext content_context(context, TypographerContextSkia::Make());
  ASSERT_TRUE(content_context.IsValid());

  TextureDescriptor onscreen_desc;
  onscreen_desc.size = {100, 100};
  onscreen_desc.format = capabilities->GetDefaultColorFormat();
  onscreen_desc.usage = TextureUsage::kRenderTarget | TextureUsage::kShaderRead;
  onscreen_desc.storage_mode = StorageMode::kDevicePrivate;
  std::shared_ptr<Texture> onscreen =
      context->GetResourceAllocator()->CreateTexture(onscreen_desc);
  ASSERT_TRUE(onscreen);

  ColorAttachment color0;
  color0.texture = onscreen;
  color0.load_action = LoadAction::kClear;
  color0.store_action = StoreAction::kStore;
  RenderTarget render_target;
  render_target.SetColorAttachment(color0, 0);

  Canvas canvas(content_context, render_target, /*is_onscreen=*/true,
                /*requires_readback=*/true, Rect::MakeLTRB(0, 0, 100, 100));
  canvas.Save(/*total_content_depth=*/2);
  canvas.DrawRect(Rect::MakeXYWH(10, 10, 40, 40),
                  Paint{.color = Color::Blue()});
  // An advanced blend without framebuffer fetch flips the backdrop. Without
  // offscreen MSAA the pass after the flip renders into the same texture the
  // backdrop is read from.
  canvas.DrawRect(
      Rect::MakeXYWH(20, 20, 40, 40),
      Paint{.color = Color::Orange(), .blend_mode = BlendMode::kScreen});
  canvas.Restore();
  canvas.EndReplay();

  // The blend samples the backdrop, so the detector must have seen it.
  EXPECT_GT(detector.GetSamplingDrawCount(), 0u);
  EXPECT_THAT(detector.GetFeedbackLoopTextures(), IsEmpty());
}

}  // namespace testing
}  // namespace impeller
