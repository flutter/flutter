// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/test_helper.h"

#include <algorithm>
#include <string>

#include "base/strings/string_number_conversions.h"
#include "base/strings/string_tokenizer.h"
#include "gpu/command_buffer/service/buffer_manager.h"
#include "gpu/command_buffer/service/error_state_mock.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/command_buffer/service/gpu_switches.h"
#include "gpu/command_buffer/service/mocks.h"
#include "gpu/command_buffer/service/program_manager.h"
#include "gpu/command_buffer/service/texture_manager.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_mock.h"

using ::testing::_;
using ::testing::DoAll;
using ::testing::InSequence;
using ::testing::MatcherCast;
using ::testing::Pointee;
using ::testing::NotNull;
using ::testing::Return;
using ::testing::SetArrayArgument;
using ::testing::SetArgumentPointee;
using ::testing::StrEq;
using ::testing::StrictMock;

namespace gpu {
namespace gles2 {

namespace {

template<typename T>
T ConstructShaderVariable(
    GLenum type, GLint array_size, GLenum precision,
    bool static_use, const std::string& name) {
  T var;
  var.type = type;
  var.arraySize = array_size;
  var.precision = precision;
  var.staticUse = static_use;
  var.name = name;
  var.mappedName = name;  // No name hashing.
  return var;
}

}  // namespace anonymous

// GCC requires these declarations, but MSVC requires they not be present
#ifndef COMPILER_MSVC
const GLuint TestHelper::kServiceBlackTexture2dId;
const GLuint TestHelper::kServiceDefaultTexture2dId;
const GLuint TestHelper::kServiceBlackTextureCubemapId;
const GLuint TestHelper::kServiceDefaultTextureCubemapId;
const GLuint TestHelper::kServiceBlackExternalTextureId;
const GLuint TestHelper::kServiceDefaultExternalTextureId;
const GLuint TestHelper::kServiceBlackRectangleTextureId;
const GLuint TestHelper::kServiceDefaultRectangleTextureId;

const GLint TestHelper::kMaxSamples;
const GLint TestHelper::kMaxRenderbufferSize;
const GLint TestHelper::kMaxTextureSize;
const GLint TestHelper::kMaxCubeMapTextureSize;
const GLint TestHelper::kMaxRectangleTextureSize;
const GLint TestHelper::kNumVertexAttribs;
const GLint TestHelper::kNumTextureUnits;
const GLint TestHelper::kMaxTextureImageUnits;
const GLint TestHelper::kMaxVertexTextureImageUnits;
const GLint TestHelper::kMaxFragmentUniformVectors;
const GLint TestHelper::kMaxFragmentUniformComponents;
const GLint TestHelper::kMaxVaryingVectors;
const GLint TestHelper::kMaxVaryingFloats;
const GLint TestHelper::kMaxVertexUniformVectors;
const GLint TestHelper::kMaxVertexUniformComponents;
#endif

void TestHelper::SetupTextureInitializationExpectations(
    ::gfx::MockGLInterface* gl,
    GLenum target,
    bool use_default_textures) {
  InSequence sequence;

  bool needs_initialization = (target != GL_TEXTURE_EXTERNAL_OES);
  bool needs_faces = (target == GL_TEXTURE_CUBE_MAP);

  static GLuint texture_2d_ids[] = {
    kServiceBlackTexture2dId,
    kServiceDefaultTexture2dId };
  static GLuint texture_cube_map_ids[] = {
    kServiceBlackTextureCubemapId,
    kServiceDefaultTextureCubemapId };
  static GLuint texture_external_oes_ids[] = {
    kServiceBlackExternalTextureId,
    kServiceDefaultExternalTextureId };
  static GLuint texture_rectangle_arb_ids[] = {
    kServiceBlackRectangleTextureId,
    kServiceDefaultRectangleTextureId };

  const GLuint* texture_ids = NULL;
  switch (target) {
    case GL_TEXTURE_2D:
      texture_ids = &texture_2d_ids[0];
      break;
    case GL_TEXTURE_CUBE_MAP:
      texture_ids = &texture_cube_map_ids[0];
      break;
    case GL_TEXTURE_EXTERNAL_OES:
      texture_ids = &texture_external_oes_ids[0];
      break;
    case GL_TEXTURE_RECTANGLE_ARB:
      texture_ids = &texture_rectangle_arb_ids[0];
      break;
    default:
      NOTREACHED();
  }

  int array_size = use_default_textures ? 2 : 1;

  EXPECT_CALL(*gl, GenTextures(array_size, _))
      .WillOnce(SetArrayArgument<1>(texture_ids,
                                    texture_ids + array_size))
          .RetiresOnSaturation();
  for (int ii = 0; ii < array_size; ++ii) {
    EXPECT_CALL(*gl, BindTexture(target, texture_ids[ii]))
        .Times(1)
        .RetiresOnSaturation();
    if (needs_initialization) {
      if (needs_faces) {
        static GLenum faces[] = {
          GL_TEXTURE_CUBE_MAP_POSITIVE_X,
          GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
          GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
          GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
          GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
          GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
        };
        for (size_t ii = 0; ii < arraysize(faces); ++ii) {
          EXPECT_CALL(*gl, TexImage2D(faces[ii], 0, GL_RGBA, 1, 1, 0, GL_RGBA,
                                      GL_UNSIGNED_BYTE, _))
              .Times(1)
              .RetiresOnSaturation();
        }
      } else {
        EXPECT_CALL(*gl, TexImage2D(target, 0, GL_RGBA, 1, 1, 0, GL_RGBA,
                                    GL_UNSIGNED_BYTE, _))
            .Times(1)
            .RetiresOnSaturation();
      }
    }
  }
  EXPECT_CALL(*gl, BindTexture(target, 0))
      .Times(1)
      .RetiresOnSaturation();
}

void TestHelper::SetupTextureManagerInitExpectations(
    ::gfx::MockGLInterface* gl,
    const char* extensions,
    bool use_default_textures) {
  InSequence sequence;

  SetupTextureInitializationExpectations(
      gl, GL_TEXTURE_2D, use_default_textures);
  SetupTextureInitializationExpectations(
      gl, GL_TEXTURE_CUBE_MAP, use_default_textures);

  bool ext_image_external = false;
  bool arb_texture_rectangle = false;
  base::CStringTokenizer t(extensions, extensions + strlen(extensions), " ");
  while (t.GetNext()) {
    if (t.token() == "GL_OES_EGL_image_external") {
      ext_image_external = true;
      break;
    }
    if (t.token() == "GL_ARB_texture_rectangle") {
      arb_texture_rectangle = true;
      break;
    }
  }

  if (ext_image_external) {
    SetupTextureInitializationExpectations(
        gl, GL_TEXTURE_EXTERNAL_OES, use_default_textures);
  }
  if (arb_texture_rectangle) {
    SetupTextureInitializationExpectations(
        gl, GL_TEXTURE_RECTANGLE_ARB, use_default_textures);
  }
}

void TestHelper::SetupTextureDestructionExpectations(
    ::gfx::MockGLInterface* gl,
    GLenum target,
    bool use_default_textures) {
  if (!use_default_textures)
    return;

  GLuint texture_id = 0;
  switch (target) {
    case GL_TEXTURE_2D:
      texture_id = kServiceDefaultTexture2dId;
      break;
    case GL_TEXTURE_CUBE_MAP:
      texture_id = kServiceDefaultTextureCubemapId;
      break;
    case GL_TEXTURE_EXTERNAL_OES:
      texture_id = kServiceDefaultExternalTextureId;
      break;
    case GL_TEXTURE_RECTANGLE_ARB:
      texture_id = kServiceDefaultRectangleTextureId;
      break;
    default:
      NOTREACHED();
  }

  EXPECT_CALL(*gl, DeleteTextures(1, Pointee(texture_id)))
      .Times(1)
      .RetiresOnSaturation();
}

void TestHelper::SetupTextureManagerDestructionExpectations(
    ::gfx::MockGLInterface* gl,
    const char* extensions,
    bool use_default_textures) {
  SetupTextureDestructionExpectations(gl, GL_TEXTURE_2D, use_default_textures);
  SetupTextureDestructionExpectations(
      gl, GL_TEXTURE_CUBE_MAP, use_default_textures);

  bool ext_image_external = false;
  bool arb_texture_rectangle = false;
  base::CStringTokenizer t(extensions, extensions + strlen(extensions), " ");
  while (t.GetNext()) {
    if (t.token() == "GL_OES_EGL_image_external") {
      ext_image_external = true;
      break;
    }
    if (t.token() == "GL_ARB_texture_rectangle") {
      arb_texture_rectangle = true;
      break;
    }
  }

  if (ext_image_external) {
    SetupTextureDestructionExpectations(
        gl, GL_TEXTURE_EXTERNAL_OES, use_default_textures);
  }
  if (arb_texture_rectangle) {
    SetupTextureDestructionExpectations(
        gl, GL_TEXTURE_RECTANGLE_ARB, use_default_textures);
  }

  EXPECT_CALL(*gl, DeleteTextures(4, _))
      .Times(1)
      .RetiresOnSaturation();
}

void TestHelper::SetupContextGroupInitExpectations(
    ::gfx::MockGLInterface* gl,
    const DisallowedFeatures& disallowed_features,
    const char* extensions,
    const char* gl_version,
    bool bind_generates_resource) {
  InSequence sequence;

  SetupFeatureInfoInitExpectationsWithGLVersion(gl, extensions, "", gl_version);

  std::string l_version(base::StringToLowerASCII(std::string(gl_version)));
  bool is_es3 = (l_version.substr(0, 12) == "opengl es 3.");

  EXPECT_CALL(*gl, GetIntegerv(GL_MAX_RENDERBUFFER_SIZE, _))
      .WillOnce(SetArgumentPointee<1>(kMaxRenderbufferSize))
      .RetiresOnSaturation();
  if (strstr(extensions, "GL_EXT_framebuffer_multisample") ||
      strstr(extensions, "GL_EXT_multisampled_render_to_texture") || is_es3) {
    EXPECT_CALL(*gl, GetIntegerv(GL_MAX_SAMPLES, _))
        .WillOnce(SetArgumentPointee<1>(kMaxSamples))
        .RetiresOnSaturation();
  } else if (strstr(extensions, "GL_IMG_multisampled_render_to_texture")) {
    EXPECT_CALL(*gl, GetIntegerv(GL_MAX_SAMPLES_IMG, _))
        .WillOnce(SetArgumentPointee<1>(kMaxSamples))
        .RetiresOnSaturation();
  }
  EXPECT_CALL(*gl, GetIntegerv(GL_MAX_VERTEX_ATTRIBS, _))
      .WillOnce(SetArgumentPointee<1>(kNumVertexAttribs))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl, GetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, _))
      .WillOnce(SetArgumentPointee<1>(kNumTextureUnits))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl, GetIntegerv(GL_MAX_TEXTURE_SIZE, _))
      .WillOnce(SetArgumentPointee<1>(kMaxTextureSize))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl, GetIntegerv(GL_MAX_CUBE_MAP_TEXTURE_SIZE, _))
      .WillOnce(SetArgumentPointee<1>(kMaxCubeMapTextureSize))
      .RetiresOnSaturation();
  if (strstr(extensions, "GL_ARB_texture_rectangle")) {
    EXPECT_CALL(*gl, GetIntegerv(GL_MAX_RECTANGLE_TEXTURE_SIZE, _))
        .WillOnce(SetArgumentPointee<1>(kMaxRectangleTextureSize))
        .RetiresOnSaturation();
  }
  EXPECT_CALL(*gl, GetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, _))
      .WillOnce(SetArgumentPointee<1>(kMaxTextureImageUnits))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl, GetIntegerv(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS, _))
      .WillOnce(SetArgumentPointee<1>(kMaxVertexTextureImageUnits))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl, GetIntegerv(GL_MAX_FRAGMENT_UNIFORM_COMPONENTS, _))
      .WillOnce(SetArgumentPointee<1>(kMaxFragmentUniformComponents))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl, GetIntegerv(GL_MAX_VARYING_FLOATS, _))
      .WillOnce(SetArgumentPointee<1>(kMaxVaryingFloats))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl, GetIntegerv(GL_MAX_VERTEX_UNIFORM_COMPONENTS, _))
      .WillOnce(SetArgumentPointee<1>(kMaxVertexUniformComponents))
      .RetiresOnSaturation();

  bool use_default_textures = bind_generates_resource;
  SetupTextureManagerInitExpectations(gl, extensions, use_default_textures);
}

void TestHelper::SetupFeatureInfoInitExpectations(
      ::gfx::MockGLInterface* gl, const char* extensions) {
  SetupFeatureInfoInitExpectationsWithGLVersion(gl, extensions, "", "");
}

void TestHelper::SetupFeatureInfoInitExpectationsWithGLVersion(
     ::gfx::MockGLInterface* gl,
     const char* extensions,
     const char* gl_renderer,
     const char* gl_version) {
  InSequence sequence;

  EXPECT_CALL(*gl, GetString(GL_EXTENSIONS))
      .WillOnce(Return(reinterpret_cast<const uint8*>(extensions)))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl, GetString(GL_RENDERER))
      .WillOnce(Return(reinterpret_cast<const uint8*>(gl_renderer)))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl, GetString(GL_VERSION))
      .WillOnce(Return(reinterpret_cast<const uint8*>(gl_version)))
      .RetiresOnSaturation();

  std::string l_version(base::StringToLowerASCII(std::string(gl_version)));
  bool is_es3 = (l_version.substr(0, 12) == "opengl es 3.");

  if (strstr(extensions, "GL_ARB_texture_float") ||
      (is_es3 && strstr(extensions, "GL_EXT_color_buffer_float"))) {
    static const GLuint tx_ids[] = {101, 102};
    static const GLuint fb_ids[] = {103, 104};
    const GLsizei width = 16;
    EXPECT_CALL(*gl, GetIntegerv(GL_FRAMEBUFFER_BINDING, _))
        .WillOnce(SetArgumentPointee<1>(fb_ids[0]))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, GetIntegerv(GL_TEXTURE_BINDING_2D, _))
        .WillOnce(SetArgumentPointee<1>(tx_ids[0]))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, GenTextures(1, _))
        .WillOnce(SetArrayArgument<1>(tx_ids + 1, tx_ids + 2))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, GenFramebuffersEXT(1, _))
        .WillOnce(SetArrayArgument<1>(fb_ids + 1, fb_ids + 2))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, BindTexture(GL_TEXTURE_2D, tx_ids[1]))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, TexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
        GL_NEAREST))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, TexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, width, width, 0,
        GL_RGBA, GL_FLOAT, _))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, BindFramebufferEXT(GL_FRAMEBUFFER, fb_ids[1]))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, FramebufferTexture2DEXT(GL_FRAMEBUFFER,
        GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tx_ids[1], 0))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, CheckFramebufferStatusEXT(GL_FRAMEBUFFER))
        .WillOnce(Return(GL_FRAMEBUFFER_COMPLETE))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, TexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, width, width, 0,
        GL_RGB, GL_FLOAT, _))
        .Times(1)
        .RetiresOnSaturation();
    if (is_es3) {
      EXPECT_CALL(*gl, CheckFramebufferStatusEXT(GL_FRAMEBUFFER))
          .WillOnce(Return(GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT))
          .RetiresOnSaturation();
    } else {
      EXPECT_CALL(*gl, CheckFramebufferStatusEXT(GL_FRAMEBUFFER))
          .WillOnce(Return(GL_FRAMEBUFFER_COMPLETE))
          .RetiresOnSaturation();
    }
    EXPECT_CALL(*gl, DeleteFramebuffersEXT(1, _))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, DeleteTextures(1, _))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, BindFramebufferEXT(GL_FRAMEBUFFER, fb_ids[0]))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, BindTexture(GL_TEXTURE_2D, tx_ids[0]))
        .Times(1)
        .RetiresOnSaturation();
#if DCHECK_IS_ON()
    EXPECT_CALL(*gl, GetError())
        .WillOnce(Return(GL_NO_ERROR))
        .RetiresOnSaturation();
#endif
  }

  if (strstr(extensions, "GL_EXT_draw_buffers") ||
      strstr(extensions, "GL_ARB_draw_buffers") ||
      (is_es3 && strstr(extensions, "GL_NV_draw_buffers"))) {
    EXPECT_CALL(*gl, GetIntegerv(GL_MAX_COLOR_ATTACHMENTS_EXT, _))
        .WillOnce(SetArgumentPointee<1>(8))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, GetIntegerv(GL_MAX_DRAW_BUFFERS_ARB, _))
        .WillOnce(SetArgumentPointee<1>(8))
        .RetiresOnSaturation();
  }

  if (is_es3 || strstr(extensions, "GL_EXT_texture_rg") ||
      (strstr(extensions, "GL_ARB_texture_rg"))) {
    static const GLuint tx_ids[] = {101, 102};
    static const GLuint fb_ids[] = {103, 104};
    const GLsizei width = 1;
    EXPECT_CALL(*gl, GetIntegerv(GL_FRAMEBUFFER_BINDING, _))
        .WillOnce(SetArgumentPointee<1>(fb_ids[0]))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, GetIntegerv(GL_TEXTURE_BINDING_2D, _))
        .WillOnce(SetArgumentPointee<1>(tx_ids[0]))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, GenTextures(1, _))
        .WillOnce(SetArrayArgument<1>(tx_ids + 1, tx_ids + 2))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, BindTexture(GL_TEXTURE_2D, tx_ids[1]))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, TexImage2D(GL_TEXTURE_2D, 0, _, width, width, 0,
        GL_RED_EXT, GL_UNSIGNED_BYTE, _))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, GenFramebuffersEXT(1, _))
        .WillOnce(SetArrayArgument<1>(fb_ids + 1, fb_ids + 2))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, BindFramebufferEXT(GL_FRAMEBUFFER, fb_ids[1]))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, FramebufferTexture2DEXT(GL_FRAMEBUFFER,
        GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tx_ids[1], 0))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, CheckFramebufferStatusEXT(GL_FRAMEBUFFER))
        .WillOnce(Return(GL_FRAMEBUFFER_COMPLETE))
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, DeleteFramebuffersEXT(1, _))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, DeleteTextures(1, _))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, BindFramebufferEXT(GL_FRAMEBUFFER, fb_ids[0]))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, BindTexture(GL_TEXTURE_2D, tx_ids[0]))
        .Times(1)
        .RetiresOnSaturation();
#if DCHECK_IS_ON()
    EXPECT_CALL(*gl, GetError())
        .WillOnce(Return(GL_NO_ERROR))
        .RetiresOnSaturation();
#endif
  }
}

void TestHelper::SetupExpectationsForClearingUniforms(
    ::gfx::MockGLInterface* gl, UniformInfo* uniforms, size_t num_uniforms) {
  for (size_t ii = 0; ii < num_uniforms; ++ii) {
    const UniformInfo& info = uniforms[ii];
    switch (info.type) {
    case GL_FLOAT:
      EXPECT_CALL(*gl, Uniform1fv(info.real_location, info.size, _))
          .Times(1)
          .RetiresOnSaturation();
      break;
    case GL_FLOAT_VEC2:
      EXPECT_CALL(*gl, Uniform2fv(info.real_location, info.size, _))
          .Times(1)
          .RetiresOnSaturation();
      break;
    case GL_FLOAT_VEC3:
      EXPECT_CALL(*gl, Uniform3fv(info.real_location, info.size, _))
          .Times(1)
          .RetiresOnSaturation();
      break;
    case GL_FLOAT_VEC4:
      EXPECT_CALL(*gl, Uniform4fv(info.real_location, info.size, _))
          .Times(1)
          .RetiresOnSaturation();
      break;
    case GL_INT:
    case GL_BOOL:
    case GL_SAMPLER_2D:
    case GL_SAMPLER_CUBE:
    case GL_SAMPLER_EXTERNAL_OES:
    case GL_SAMPLER_3D_OES:
    case GL_SAMPLER_2D_RECT_ARB:
      EXPECT_CALL(*gl, Uniform1iv(info.real_location, info.size, _))
          .Times(1)
          .RetiresOnSaturation();
      break;
    case GL_INT_VEC2:
    case GL_BOOL_VEC2:
      EXPECT_CALL(*gl, Uniform2iv(info.real_location, info.size, _))
          .Times(1)
          .RetiresOnSaturation();
      break;
    case GL_INT_VEC3:
    case GL_BOOL_VEC3:
      EXPECT_CALL(*gl, Uniform3iv(info.real_location, info.size, _))
          .Times(1)
          .RetiresOnSaturation();
      break;
    case GL_INT_VEC4:
    case GL_BOOL_VEC4:
      EXPECT_CALL(*gl, Uniform4iv(info.real_location, info.size, _))
          .Times(1)
          .RetiresOnSaturation();
      break;
    case GL_FLOAT_MAT2:
      EXPECT_CALL(*gl, UniformMatrix2fv(
          info.real_location, info.size, false, _))
          .Times(1)
          .RetiresOnSaturation();
      break;
    case GL_FLOAT_MAT3:
      EXPECT_CALL(*gl, UniformMatrix3fv(
          info.real_location, info.size, false, _))
          .Times(1)
          .RetiresOnSaturation();
      break;
    case GL_FLOAT_MAT4:
      EXPECT_CALL(*gl, UniformMatrix4fv(
          info.real_location, info.size, false, _))
          .Times(1)
          .RetiresOnSaturation();
      break;
    default:
      NOTREACHED();
      break;
    }
  }
}

void TestHelper::SetupProgramSuccessExpectations(
    ::gfx::MockGLInterface* gl,
    AttribInfo* attribs, size_t num_attribs,
    UniformInfo* uniforms, size_t num_uniforms,
    GLuint service_id) {
  EXPECT_CALL(*gl,
      GetProgramiv(service_id, GL_LINK_STATUS, _))
      .WillOnce(SetArgumentPointee<2>(1))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl,
      GetProgramiv(service_id, GL_INFO_LOG_LENGTH, _))
      .WillOnce(SetArgumentPointee<2>(0))
      .RetiresOnSaturation();
  EXPECT_CALL(*gl,
      GetProgramiv(service_id, GL_ACTIVE_ATTRIBUTES, _))
      .WillOnce(SetArgumentPointee<2>(num_attribs))
      .RetiresOnSaturation();
  size_t max_attrib_len = 0;
  for (size_t ii = 0; ii < num_attribs; ++ii) {
    size_t len = strlen(attribs[ii].name) + 1;
    max_attrib_len = std::max(max_attrib_len, len);
  }
  EXPECT_CALL(*gl,
      GetProgramiv(service_id, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, _))
      .WillOnce(SetArgumentPointee<2>(max_attrib_len))
      .RetiresOnSaturation();

  for (size_t ii = 0; ii < num_attribs; ++ii) {
    const AttribInfo& info = attribs[ii];
    EXPECT_CALL(*gl,
        GetActiveAttrib(service_id, ii,
                        max_attrib_len, _, _, _, _))
        .WillOnce(DoAll(
            SetArgumentPointee<3>(strlen(info.name)),
            SetArgumentPointee<4>(info.size),
            SetArgumentPointee<5>(info.type),
            SetArrayArgument<6>(info.name,
                                info.name + strlen(info.name) + 1)))
        .RetiresOnSaturation();
    if (!ProgramManager::IsInvalidPrefix(info.name, strlen(info.name))) {
      EXPECT_CALL(*gl, GetAttribLocation(service_id, StrEq(info.name)))
          .WillOnce(Return(info.location))
          .RetiresOnSaturation();
    }
  }
  EXPECT_CALL(*gl,
      GetProgramiv(service_id, GL_ACTIVE_UNIFORMS, _))
      .WillOnce(SetArgumentPointee<2>(num_uniforms))
      .RetiresOnSaturation();

  size_t max_uniform_len = 0;
  for (size_t ii = 0; ii < num_uniforms; ++ii) {
    size_t len = strlen(uniforms[ii].name) + 1;
    max_uniform_len = std::max(max_uniform_len, len);
  }
  EXPECT_CALL(*gl,
      GetProgramiv(service_id, GL_ACTIVE_UNIFORM_MAX_LENGTH, _))
      .WillOnce(SetArgumentPointee<2>(max_uniform_len))
      .RetiresOnSaturation();
  for (size_t ii = 0; ii < num_uniforms; ++ii) {
    const UniformInfo& info = uniforms[ii];
    EXPECT_CALL(*gl,
        GetActiveUniform(service_id, ii,
                         max_uniform_len, _, _, _, _))
        .WillOnce(DoAll(
            SetArgumentPointee<3>(strlen(info.name)),
            SetArgumentPointee<4>(info.size),
            SetArgumentPointee<5>(info.type),
            SetArrayArgument<6>(info.name,
                                info.name + strlen(info.name) + 1)))
        .RetiresOnSaturation();
  }

  for (int pass = 0; pass < 2; ++pass) {
    for (size_t ii = 0; ii < num_uniforms; ++ii) {
      const UniformInfo& info = uniforms[ii];
      if (ProgramManager::IsInvalidPrefix(info.name, strlen(info.name))) {
        continue;
      }
      if (pass == 0) {
        EXPECT_CALL(*gl, GetUniformLocation(service_id, StrEq(info.name)))
            .WillOnce(Return(info.real_location))
            .RetiresOnSaturation();
      }
      if ((pass == 0 && info.desired_location >= 0) ||
          (pass == 1 && info.desired_location < 0)) {
        if (info.size > 1) {
          std::string base_name = info.name;
          size_t array_pos = base_name.rfind("[0]");
          if (base_name.size() > 3 && array_pos == base_name.size() - 3) {
            base_name = base_name.substr(0, base_name.size() - 3);
          }
          for (GLsizei jj = 1; jj < info.size; ++jj) {
            std::string element_name(
                std::string(base_name) + "[" + base::IntToString(jj) + "]");
            EXPECT_CALL(*gl, GetUniformLocation(
                service_id, StrEq(element_name)))
                .WillOnce(Return(info.real_location + jj * 2))
                .RetiresOnSaturation();
          }
        }
      }
    }
  }
}

void TestHelper::SetupShader(
    ::gfx::MockGLInterface* gl,
    AttribInfo* attribs, size_t num_attribs,
    UniformInfo* uniforms, size_t num_uniforms,
    GLuint service_id) {
  InSequence s;

  EXPECT_CALL(*gl,
      LinkProgram(service_id))
      .Times(1)
      .RetiresOnSaturation();

  SetupProgramSuccessExpectations(
      gl, attribs, num_attribs, uniforms, num_uniforms, service_id);
}

void TestHelper::DoBufferData(
    ::gfx::MockGLInterface* gl, MockErrorState* error_state,
    BufferManager* manager, Buffer* buffer, GLsizeiptr size, GLenum usage,
    const GLvoid* data, GLenum error) {
  EXPECT_CALL(*error_state, CopyRealGLErrorsToWrapper(_, _, _))
      .Times(1)
      .RetiresOnSaturation();
  if (manager->IsUsageClientSideArray(usage)) {
    EXPECT_CALL(*gl, BufferData(
        buffer->target(), 0, _, usage))
        .Times(1)
        .RetiresOnSaturation();
  } else {
    EXPECT_CALL(*gl, BufferData(
        buffer->target(), size, _, usage))
        .Times(1)
        .RetiresOnSaturation();
  }
  EXPECT_CALL(*error_state, PeekGLError(_, _, _))
      .WillOnce(Return(error))
      .RetiresOnSaturation();
  manager->DoBufferData(error_state, buffer, size, usage, data);
}

void TestHelper::SetTexParameteriWithExpectations(
    ::gfx::MockGLInterface* gl, MockErrorState* error_state,
    TextureManager* manager, TextureRef* texture_ref,
    GLenum pname, GLint value, GLenum error) {
  if (error == GL_NO_ERROR) {
    if (pname != GL_TEXTURE_POOL_CHROMIUM) {
      EXPECT_CALL(*gl, TexParameteri(texture_ref->texture()->target(),
                                     pname, value))
          .Times(1)
          .RetiresOnSaturation();
    }
  } else if (error == GL_INVALID_ENUM) {
    EXPECT_CALL(*error_state, SetGLErrorInvalidEnum(_, _, _, value, _))
        .Times(1)
        .RetiresOnSaturation();
  } else {
    EXPECT_CALL(*error_state, SetGLErrorInvalidParami(_, _, error, _, _, _))
        .Times(1)
        .RetiresOnSaturation();
  }
  manager->SetParameteri("", error_state, texture_ref, pname, value);
}

// static
void TestHelper::SetShaderStates(
      ::gfx::MockGLInterface* gl, Shader* shader,
      bool expected_valid,
      const std::string* const expected_log_info,
      const std::string* const expected_translated_source,
      const AttributeMap* const expected_attrib_map,
      const UniformMap* const expected_uniform_map,
      const VaryingMap* const expected_varying_map,
      const NameMap* const expected_name_map) {
  const std::string empty_log_info;
  const std::string* log_info = (expected_log_info && !expected_valid) ?
      expected_log_info : &empty_log_info;
  const std::string empty_translated_source;
  const std::string* translated_source =
      (expected_translated_source && expected_valid) ?
          expected_translated_source : &empty_translated_source;
  const AttributeMap empty_attrib_map;
  const AttributeMap* attrib_map = (expected_attrib_map && expected_valid) ?
      expected_attrib_map : &empty_attrib_map;
  const UniformMap empty_uniform_map;
  const UniformMap* uniform_map = (expected_uniform_map && expected_valid) ?
      expected_uniform_map : &empty_uniform_map;
  const VaryingMap empty_varying_map;
  const VaryingMap* varying_map = (expected_varying_map && expected_valid) ?
      expected_varying_map : &empty_varying_map;
  const NameMap empty_name_map;
  const NameMap* name_map = (expected_name_map && expected_valid) ?
      expected_name_map : &empty_name_map;

  MockShaderTranslator* mock_translator = new MockShaderTranslator;
  scoped_refptr<ShaderTranslatorInterface> translator(mock_translator);
  EXPECT_CALL(*mock_translator, Translate(_,
                                          NotNull(),  // log_info
                                          NotNull(),  // translated_source
                                          NotNull(),  // attrib_map
                                          NotNull(),  // uniform_map
                                          NotNull(),  // varying_map
                                          NotNull()))  // name_map
      .WillOnce(DoAll(SetArgumentPointee<1>(*log_info),
                      SetArgumentPointee<2>(*translated_source),
                      SetArgumentPointee<3>(*attrib_map),
                      SetArgumentPointee<4>(*uniform_map),
                      SetArgumentPointee<5>(*varying_map),
                      SetArgumentPointee<6>(*name_map),
                      Return(expected_valid)))
      .RetiresOnSaturation();
  if (expected_valid) {
    EXPECT_CALL(*gl, ShaderSource(shader->service_id(), 1, _, NULL))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, CompileShader(shader->service_id()))
        .Times(1)
        .RetiresOnSaturation();
    EXPECT_CALL(*gl, GetShaderiv(shader->service_id(),
                                 GL_COMPILE_STATUS,
                                 NotNull()))  // status
        .WillOnce(SetArgumentPointee<2>(GL_TRUE))
        .RetiresOnSaturation();
  }
  shader->RequestCompile(translator, Shader::kGL);
  shader->DoCompile();
}

// static
void TestHelper::SetShaderStates(
      ::gfx::MockGLInterface* gl, Shader* shader, bool valid) {
  SetShaderStates(gl, shader, valid, NULL, NULL, NULL, NULL, NULL, NULL);
}

// static
sh::Attribute TestHelper::ConstructAttribute(
    GLenum type, GLint array_size, GLenum precision,
    bool static_use, const std::string& name) {
  return ConstructShaderVariable<sh::Attribute>(
      type, array_size, precision, static_use, name);
}

// static
sh::Uniform TestHelper::ConstructUniform(
    GLenum type, GLint array_size, GLenum precision,
    bool static_use, const std::string& name) {
  return ConstructShaderVariable<sh::Uniform>(
      type, array_size, precision, static_use, name);
}

// static
sh::Varying TestHelper::ConstructVarying(
    GLenum type, GLint array_size, GLenum precision,
    bool static_use, const std::string& name) {
  return ConstructShaderVariable<sh::Varying>(
      type, array_size, precision, static_use, name);
}

ScopedGLImplementationSetter::ScopedGLImplementationSetter(
    gfx::GLImplementation implementation)
    : old_implementation_(gfx::GetGLImplementation()) {
  gfx::SetGLImplementation(implementation);
}

ScopedGLImplementationSetter::~ScopedGLImplementationSetter() {
  gfx::SetGLImplementation(old_implementation_);
}

}  // namespace gles2
}  // namespace gpu

