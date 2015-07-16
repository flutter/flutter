// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gles2_cmd_clear_framebuffer.h"

#include "base/basictypes.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"

namespace {

#define SHADER(src)            \
  "#ifdef GL_ES\n"             \
  "precision mediump float;\n" \
  "#endif\n" #src

const char* g_vertex_shader_source = {
  SHADER(
    uniform float u_clear_depth;
    attribute vec4 a_position;
    void main(void) {
      gl_Position = vec4(a_position.x, a_position.y, u_clear_depth, 1.0);
    }
  ),
};

const char* g_fragment_shader_source = {
  SHADER(
    uniform vec4 u_clear_color;
    void main(void) {
      gl_FragColor = u_clear_color;
    }
  ),
};

void CompileShader(GLuint shader, const char* shader_source) {
  glShaderSource(shader, 1, &shader_source, 0);
  glCompileShader(shader);
#if DCHECK_IS_ON()
  GLint compile_status = GL_FALSE;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compile_status);
  if (GL_TRUE != compile_status) {
    char buffer[1024];
    GLsizei length = 0;
    glGetShaderInfoLog(shader, sizeof(buffer), &length, buffer);
    std::string log(buffer, length);
    DLOG(ERROR) << "Error compiling shader: " << log;
    DLOG(ERROR) << "Shader compilation failure.";
  }
#endif
}

}  // namespace

namespace gpu {

ClearFramebufferResourceManager::ClearFramebufferResourceManager(
    const gles2::GLES2Decoder* decoder)
    : initialized_(false), program_(0u), buffer_id_(0u) {
  Initialize(decoder);
}

ClearFramebufferResourceManager::~ClearFramebufferResourceManager() {
  Destroy();
  DCHECK(!buffer_id_);
}

void ClearFramebufferResourceManager::Initialize(
    const gles2::GLES2Decoder* decoder) {
  static_assert(
      kVertexPositionAttrib == 0u,
      "kVertexPositionAttrib must be 0");
  DCHECK(!buffer_id_);

  glGenBuffersARB(1, &buffer_id_);
  glBindBuffer(GL_ARRAY_BUFFER, buffer_id_);
  const GLfloat kQuadVertices[] = {-1.0f, -1.0f,
                                    1.0f, -1.0f,
                                    1.0f,  1.0f,
                                   -1.0f,  1.0f};
  glBufferData(
      GL_ARRAY_BUFFER, sizeof(kQuadVertices), kQuadVertices, GL_STATIC_DRAW);
  decoder->RestoreBufferBindings();
  initialized_ = true;
}

void ClearFramebufferResourceManager::Destroy() {
  if (!initialized_)
    return;

  glDeleteProgram(program_);
  glDeleteBuffersARB(1, &buffer_id_);
  buffer_id_ = 0;
}

void ClearFramebufferResourceManager::ClearFramebuffer(
    const gles2::GLES2Decoder* decoder,
    const gfx::Size& framebuffer_size,
    GLbitfield mask,
    GLfloat clear_color_red,
    GLfloat clear_color_green,
    GLfloat clear_color_blue,
    GLfloat clear_color_alpha,
    GLfloat clear_depth_value,
    GLint clear_stencil_value) {
  if (!initialized_) {
    DLOG(ERROR) << "Uninitialized manager.";
    return;
  }

  if (!program_) {
    program_ = glCreateProgram();
    GLuint vertex_shader = glCreateShader(GL_VERTEX_SHADER);
    CompileShader(vertex_shader, g_vertex_shader_source);
    glAttachShader(program_, vertex_shader);
    GLuint fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
    CompileShader(fragment_shader, g_fragment_shader_source);
    glAttachShader(program_, fragment_shader);
    glBindAttribLocation(program_, kVertexPositionAttrib, "a_position");
    glLinkProgram(program_);
#if DCHECK_IS_ON()
    GLint linked = GL_FALSE;
    glGetProgramiv(program_, GL_LINK_STATUS, &linked);
    if (GL_TRUE != linked)
      DLOG(ERROR) << "Program link failure.";
#endif
    depth_handle_ = glGetUniformLocation(program_, "u_clear_depth");
    color_handle_ = glGetUniformLocation(program_, "u_clear_color");
    glDeleteShader(fragment_shader);
    glDeleteShader(vertex_shader);
  }
  glUseProgram(program_);

#if DCHECK_IS_ON()
  glValidateProgram(program_);
  GLint validation_status = GL_FALSE;
  glGetProgramiv(program_, GL_VALIDATE_STATUS, &validation_status);
  if (GL_TRUE != validation_status)
    DLOG(ERROR) << "Invalid shader.";
#endif

  decoder->ClearAllAttributes();
  glEnableVertexAttribArray(kVertexPositionAttrib);

  glBindBuffer(GL_ARRAY_BUFFER, buffer_id_);
  glVertexAttribPointer(kVertexPositionAttrib, 2, GL_FLOAT, GL_FALSE, 0, 0);

  glUniform1f(depth_handle_, clear_depth_value);
  glUniform4f(color_handle_, clear_color_red, clear_color_green,
              clear_color_blue, clear_color_alpha);

  if (!(mask & GL_COLOR_BUFFER_BIT)) {
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
  }

  if (mask & GL_DEPTH_BUFFER_BIT) {
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_ALWAYS);
  } else {
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
  }

  if (mask & GL_STENCIL_BUFFER_BIT) {
    glEnable(GL_STENCIL_TEST);
    glStencilFunc(GL_ALWAYS, clear_stencil_value, 0xFF);
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);
  } else {
    glDisable(GL_STENCIL_TEST);
    glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
    glStencilMask(0);
  }

  glDisable(GL_CULL_FACE);
  glDisable(GL_BLEND);
  glDisable(GL_POLYGON_OFFSET_FILL);

  glViewport(0, 0, framebuffer_size.width(), framebuffer_size.height());
  glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

  decoder->RestoreAllAttributes();
  decoder->RestoreProgramBindings();
  decoder->RestoreBufferBindings();
  decoder->RestoreGlobalState();
}

}  // namespace gpu
