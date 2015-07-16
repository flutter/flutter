// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

// It is included by gles2_cmd_decoder.cc
#ifndef GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_AUTOGEN_H_
#define GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_AUTOGEN_H_

error::Error GLES2DecoderImpl::HandleActiveTexture(uint32_t immediate_data_size,
                                                   const void* cmd_data) {
  const gles2::cmds::ActiveTexture& c =
      *static_cast<const gles2::cmds::ActiveTexture*>(cmd_data);
  (void)c;
  GLenum texture = static_cast<GLenum>(c.texture);
  DoActiveTexture(texture);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleAttachShader(uint32_t immediate_data_size,
                                                  const void* cmd_data) {
  const gles2::cmds::AttachShader& c =
      *static_cast<const gles2::cmds::AttachShader*>(cmd_data);
  (void)c;
  GLuint program = c.program;
  GLuint shader = c.shader;
  DoAttachShader(program, shader);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBindBuffer(uint32_t immediate_data_size,
                                                const void* cmd_data) {
  const gles2::cmds::BindBuffer& c =
      *static_cast<const gles2::cmds::BindBuffer*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLuint buffer = c.buffer;
  if (!validators_->buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBindBuffer", target, "target");
    return error::kNoError;
  }
  DoBindBuffer(target, buffer);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBindBufferBase(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::BindBufferBase& c =
      *static_cast<const gles2::cmds::BindBufferBase*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLuint index = static_cast<GLuint>(c.index);
  GLuint buffer = c.buffer;
  if (!group_->GetBufferServiceId(buffer, &buffer)) {
    if (!group_->bind_generates_resource()) {
      LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glBindBufferBase",
                         "invalid buffer id");
      return error::kNoError;
    }
    GLuint client_id = buffer;
    glGenBuffersARB(1, &buffer);
    CreateBuffer(client_id, buffer);
  }
  glBindBufferBase(target, index, buffer);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBindBufferRange(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::BindBufferRange& c =
      *static_cast<const gles2::cmds::BindBufferRange*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLuint index = static_cast<GLuint>(c.index);
  GLuint buffer = c.buffer;
  GLintptr offset = static_cast<GLintptr>(c.offset);
  GLsizeiptr size = static_cast<GLsizeiptr>(c.size);
  if (!group_->GetBufferServiceId(buffer, &buffer)) {
    if (!group_->bind_generates_resource()) {
      LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glBindBufferRange",
                         "invalid buffer id");
      return error::kNoError;
    }
    GLuint client_id = buffer;
    glGenBuffersARB(1, &buffer);
    CreateBuffer(client_id, buffer);
  }
  glBindBufferRange(target, index, buffer, offset, size);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBindFramebuffer(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::BindFramebuffer& c =
      *static_cast<const gles2::cmds::BindFramebuffer*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLuint framebuffer = c.framebuffer;
  if (!validators_->frame_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBindFramebuffer", target, "target");
    return error::kNoError;
  }
  DoBindFramebuffer(target, framebuffer);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBindRenderbuffer(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::BindRenderbuffer& c =
      *static_cast<const gles2::cmds::BindRenderbuffer*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLuint renderbuffer = c.renderbuffer;
  if (!validators_->render_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBindRenderbuffer", target, "target");
    return error::kNoError;
  }
  DoBindRenderbuffer(target, renderbuffer);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBindSampler(uint32_t immediate_data_size,
                                                 const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::BindSampler& c =
      *static_cast<const gles2::cmds::BindSampler*>(cmd_data);
  (void)c;
  GLuint unit = static_cast<GLuint>(c.unit);
  GLuint sampler = c.sampler;
  if (!group_->GetSamplerServiceId(sampler, &sampler)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glBindSampler",
                       "invalid sampler id");
    return error::kNoError;
  }
  glBindSampler(unit, sampler);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBindTexture(uint32_t immediate_data_size,
                                                 const void* cmd_data) {
  const gles2::cmds::BindTexture& c =
      *static_cast<const gles2::cmds::BindTexture*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLuint texture = c.texture;
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBindTexture", target, "target");
    return error::kNoError;
  }
  DoBindTexture(target, texture);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBindTransformFeedback(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::BindTransformFeedback& c =
      *static_cast<const gles2::cmds::BindTransformFeedback*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLuint transformfeedback = c.transformfeedback;
  if (!group_->GetTransformFeedbackServiceId(transformfeedback,
                                             &transformfeedback)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glBindTransformFeedback",
                       "invalid transformfeedback id");
    return error::kNoError;
  }
  glBindTransformFeedback(target, transformfeedback);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBlendColor(uint32_t immediate_data_size,
                                                const void* cmd_data) {
  const gles2::cmds::BlendColor& c =
      *static_cast<const gles2::cmds::BlendColor*>(cmd_data);
  (void)c;
  GLclampf red = static_cast<GLclampf>(c.red);
  GLclampf green = static_cast<GLclampf>(c.green);
  GLclampf blue = static_cast<GLclampf>(c.blue);
  GLclampf alpha = static_cast<GLclampf>(c.alpha);
  if (state_.blend_color_red != red || state_.blend_color_green != green ||
      state_.blend_color_blue != blue || state_.blend_color_alpha != alpha) {
    state_.blend_color_red = red;
    state_.blend_color_green = green;
    state_.blend_color_blue = blue;
    state_.blend_color_alpha = alpha;
    glBlendColor(red, green, blue, alpha);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBlendEquation(uint32_t immediate_data_size,
                                                   const void* cmd_data) {
  const gles2::cmds::BlendEquation& c =
      *static_cast<const gles2::cmds::BlendEquation*>(cmd_data);
  (void)c;
  GLenum mode = static_cast<GLenum>(c.mode);
  if (!validators_->equation.IsValid(mode)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBlendEquation", mode, "mode");
    return error::kNoError;
  }
  if (state_.blend_equation_rgb != mode ||
      state_.blend_equation_alpha != mode) {
    state_.blend_equation_rgb = mode;
    state_.blend_equation_alpha = mode;
    glBlendEquation(mode);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBlendEquationSeparate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::BlendEquationSeparate& c =
      *static_cast<const gles2::cmds::BlendEquationSeparate*>(cmd_data);
  (void)c;
  GLenum modeRGB = static_cast<GLenum>(c.modeRGB);
  GLenum modeAlpha = static_cast<GLenum>(c.modeAlpha);
  if (!validators_->equation.IsValid(modeRGB)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBlendEquationSeparate", modeRGB,
                                    "modeRGB");
    return error::kNoError;
  }
  if (!validators_->equation.IsValid(modeAlpha)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBlendEquationSeparate", modeAlpha,
                                    "modeAlpha");
    return error::kNoError;
  }
  if (state_.blend_equation_rgb != modeRGB ||
      state_.blend_equation_alpha != modeAlpha) {
    state_.blend_equation_rgb = modeRGB;
    state_.blend_equation_alpha = modeAlpha;
    glBlendEquationSeparate(modeRGB, modeAlpha);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBlendFunc(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::BlendFunc& c =
      *static_cast<const gles2::cmds::BlendFunc*>(cmd_data);
  (void)c;
  GLenum sfactor = static_cast<GLenum>(c.sfactor);
  GLenum dfactor = static_cast<GLenum>(c.dfactor);
  if (!validators_->src_blend_factor.IsValid(sfactor)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBlendFunc", sfactor, "sfactor");
    return error::kNoError;
  }
  if (!validators_->dst_blend_factor.IsValid(dfactor)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBlendFunc", dfactor, "dfactor");
    return error::kNoError;
  }
  if (state_.blend_source_rgb != sfactor || state_.blend_dest_rgb != dfactor ||
      state_.blend_source_alpha != sfactor ||
      state_.blend_dest_alpha != dfactor) {
    state_.blend_source_rgb = sfactor;
    state_.blend_dest_rgb = dfactor;
    state_.blend_source_alpha = sfactor;
    state_.blend_dest_alpha = dfactor;
    glBlendFunc(sfactor, dfactor);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBlendFuncSeparate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::BlendFuncSeparate& c =
      *static_cast<const gles2::cmds::BlendFuncSeparate*>(cmd_data);
  (void)c;
  GLenum srcRGB = static_cast<GLenum>(c.srcRGB);
  GLenum dstRGB = static_cast<GLenum>(c.dstRGB);
  GLenum srcAlpha = static_cast<GLenum>(c.srcAlpha);
  GLenum dstAlpha = static_cast<GLenum>(c.dstAlpha);
  if (!validators_->src_blend_factor.IsValid(srcRGB)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBlendFuncSeparate", srcRGB, "srcRGB");
    return error::kNoError;
  }
  if (!validators_->dst_blend_factor.IsValid(dstRGB)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBlendFuncSeparate", dstRGB, "dstRGB");
    return error::kNoError;
  }
  if (!validators_->src_blend_factor.IsValid(srcAlpha)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBlendFuncSeparate", srcAlpha,
                                    "srcAlpha");
    return error::kNoError;
  }
  if (!validators_->dst_blend_factor.IsValid(dstAlpha)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBlendFuncSeparate", dstAlpha,
                                    "dstAlpha");
    return error::kNoError;
  }
  if (state_.blend_source_rgb != srcRGB || state_.blend_dest_rgb != dstRGB ||
      state_.blend_source_alpha != srcAlpha ||
      state_.blend_dest_alpha != dstAlpha) {
    state_.blend_source_rgb = srcRGB;
    state_.blend_dest_rgb = dstRGB;
    state_.blend_source_alpha = srcAlpha;
    state_.blend_dest_alpha = dstAlpha;
    glBlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBufferSubData(uint32_t immediate_data_size,
                                                   const void* cmd_data) {
  const gles2::cmds::BufferSubData& c =
      *static_cast<const gles2::cmds::BufferSubData*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLintptr offset = static_cast<GLintptr>(c.offset);
  GLsizeiptr size = static_cast<GLsizeiptr>(c.size);
  uint32_t data_size = size;
  const void* data = GetSharedMemoryAs<const void*>(
      c.data_shm_id, c.data_shm_offset, data_size);
  if (!validators_->buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBufferSubData", target, "target");
    return error::kNoError;
  }
  if (size < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glBufferSubData", "size < 0");
    return error::kNoError;
  }
  if (data == NULL) {
    return error::kOutOfBounds;
  }
  DoBufferSubData(target, offset, size, data);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCheckFramebufferStatus(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::CheckFramebufferStatus& c =
      *static_cast<const gles2::cmds::CheckFramebufferStatus*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  typedef cmds::CheckFramebufferStatus::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  if (!validators_->frame_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glCheckFramebufferStatus", target,
                                    "target");
    return error::kNoError;
  }
  *result_dst = DoCheckFramebufferStatus(target);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleClear(uint32_t immediate_data_size,
                                           const void* cmd_data) {
  const gles2::cmds::Clear& c =
      *static_cast<const gles2::cmds::Clear*>(cmd_data);
  (void)c;
  error::Error error;
  error = WillAccessBoundFramebufferForDraw();
  if (error != error::kNoError)
    return error;
  GLbitfield mask = static_cast<GLbitfield>(c.mask);
  DoClear(mask);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleClearBufferfi(uint32_t immediate_data_size,
                                                   const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::ClearBufferfi& c =
      *static_cast<const gles2::cmds::ClearBufferfi*>(cmd_data);
  (void)c;
  GLenum buffer = static_cast<GLenum>(c.buffer);
  GLint drawbuffers = static_cast<GLint>(c.drawbuffers);
  GLfloat depth = static_cast<GLfloat>(c.depth);
  GLint stencil = static_cast<GLint>(c.stencil);
  glClearBufferfi(buffer, drawbuffers, depth, stencil);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleClearBufferfvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::ClearBufferfvImmediate& c =
      *static_cast<const gles2::cmds::ClearBufferfvImmediate*>(cmd_data);
  (void)c;
  GLenum buffer = static_cast<GLenum>(c.buffer);
  GLint drawbuffers = static_cast<GLint>(c.drawbuffers);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLfloat), 4, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* value =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (value == NULL) {
    return error::kOutOfBounds;
  }
  glClearBufferfv(buffer, drawbuffers, value);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleClearBufferivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::ClearBufferivImmediate& c =
      *static_cast<const gles2::cmds::ClearBufferivImmediate*>(cmd_data);
  (void)c;
  GLenum buffer = static_cast<GLenum>(c.buffer);
  GLint drawbuffers = static_cast<GLint>(c.drawbuffers);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLint), 4, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLint* value =
      GetImmediateDataAs<const GLint*>(c, data_size, immediate_data_size);
  if (value == NULL) {
    return error::kOutOfBounds;
  }
  glClearBufferiv(buffer, drawbuffers, value);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleClearBufferuivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::ClearBufferuivImmediate& c =
      *static_cast<const gles2::cmds::ClearBufferuivImmediate*>(cmd_data);
  (void)c;
  GLenum buffer = static_cast<GLenum>(c.buffer);
  GLint drawbuffers = static_cast<GLint>(c.drawbuffers);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLuint), 4, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLuint* value =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (value == NULL) {
    return error::kOutOfBounds;
  }
  glClearBufferuiv(buffer, drawbuffers, value);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleClearColor(uint32_t immediate_data_size,
                                                const void* cmd_data) {
  const gles2::cmds::ClearColor& c =
      *static_cast<const gles2::cmds::ClearColor*>(cmd_data);
  (void)c;
  GLclampf red = static_cast<GLclampf>(c.red);
  GLclampf green = static_cast<GLclampf>(c.green);
  GLclampf blue = static_cast<GLclampf>(c.blue);
  GLclampf alpha = static_cast<GLclampf>(c.alpha);
  if (state_.color_clear_red != red || state_.color_clear_green != green ||
      state_.color_clear_blue != blue || state_.color_clear_alpha != alpha) {
    state_.color_clear_red = red;
    state_.color_clear_green = green;
    state_.color_clear_blue = blue;
    state_.color_clear_alpha = alpha;
    glClearColor(red, green, blue, alpha);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleClearDepthf(uint32_t immediate_data_size,
                                                 const void* cmd_data) {
  const gles2::cmds::ClearDepthf& c =
      *static_cast<const gles2::cmds::ClearDepthf*>(cmd_data);
  (void)c;
  GLclampf depth = static_cast<GLclampf>(c.depth);
  if (state_.depth_clear != depth) {
    state_.depth_clear = depth;
    glClearDepth(depth);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleClearStencil(uint32_t immediate_data_size,
                                                  const void* cmd_data) {
  const gles2::cmds::ClearStencil& c =
      *static_cast<const gles2::cmds::ClearStencil*>(cmd_data);
  (void)c;
  GLint s = static_cast<GLint>(c.s);
  if (state_.stencil_clear != s) {
    state_.stencil_clear = s;
    glClearStencil(s);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleColorMask(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::ColorMask& c =
      *static_cast<const gles2::cmds::ColorMask*>(cmd_data);
  (void)c;
  GLboolean red = static_cast<GLboolean>(c.red);
  GLboolean green = static_cast<GLboolean>(c.green);
  GLboolean blue = static_cast<GLboolean>(c.blue);
  GLboolean alpha = static_cast<GLboolean>(c.alpha);
  if (state_.color_mask_red != red || state_.color_mask_green != green ||
      state_.color_mask_blue != blue || state_.color_mask_alpha != alpha) {
    state_.color_mask_red = red;
    state_.color_mask_green = green;
    state_.color_mask_blue = blue;
    state_.color_mask_alpha = alpha;
    framebuffer_state_.clear_state_dirty = true;
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCompileShader(uint32_t immediate_data_size,
                                                   const void* cmd_data) {
  const gles2::cmds::CompileShader& c =
      *static_cast<const gles2::cmds::CompileShader*>(cmd_data);
  (void)c;
  GLuint shader = c.shader;
  DoCompileShader(shader);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCompressedTexSubImage2D(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::CompressedTexSubImage2D& c =
      *static_cast<const gles2::cmds::CompressedTexSubImage2D*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  GLint xoffset = static_cast<GLint>(c.xoffset);
  GLint yoffset = static_cast<GLint>(c.yoffset);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLenum format = static_cast<GLenum>(c.format);
  GLsizei imageSize = static_cast<GLsizei>(c.imageSize);
  uint32_t data_size = imageSize;
  const void* data = GetSharedMemoryAs<const void*>(
      c.data_shm_id, c.data_shm_offset, data_size);
  if (!validators_->texture_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glCompressedTexSubImage2D", target,
                                    "target");
    return error::kNoError;
  }
  if (width < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glCompressedTexSubImage2D",
                       "width < 0");
    return error::kNoError;
  }
  if (height < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glCompressedTexSubImage2D",
                       "height < 0");
    return error::kNoError;
  }
  if (!validators_->compressed_texture_format.IsValid(format)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glCompressedTexSubImage2D", format,
                                    "format");
    return error::kNoError;
  }
  if (imageSize < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glCompressedTexSubImage2D",
                       "imageSize < 0");
    return error::kNoError;
  }
  if (data == NULL) {
    return error::kOutOfBounds;
  }
  DoCompressedTexSubImage2D(target, level, xoffset, yoffset, width, height,
                            format, imageSize, data);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCopyBufferSubData(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::CopyBufferSubData& c =
      *static_cast<const gles2::cmds::CopyBufferSubData*>(cmd_data);
  (void)c;
  GLenum readtarget = static_cast<GLenum>(c.readtarget);
  GLenum writetarget = static_cast<GLenum>(c.writetarget);
  GLintptr readoffset = static_cast<GLintptr>(c.readoffset);
  GLintptr writeoffset = static_cast<GLintptr>(c.writeoffset);
  GLsizeiptr size = static_cast<GLsizeiptr>(c.size);
  glCopyBufferSubData(readtarget, writetarget, readoffset, writeoffset, size);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCopyTexImage2D(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::CopyTexImage2D& c =
      *static_cast<const gles2::cmds::CopyTexImage2D*>(cmd_data);
  (void)c;
  error::Error error;
  error = WillAccessBoundFramebufferForRead();
  if (error != error::kNoError)
    return error;
  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  GLenum internalformat = static_cast<GLenum>(c.internalformat);
  GLint x = static_cast<GLint>(c.x);
  GLint y = static_cast<GLint>(c.y);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLint border = static_cast<GLint>(c.border);
  if (!validators_->texture_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glCopyTexImage2D", target, "target");
    return error::kNoError;
  }
  if (!validators_->texture_internal_format.IsValid(internalformat)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glCopyTexImage2D", internalformat,
                                    "internalformat");
    return error::kNoError;
  }
  if (width < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glCopyTexImage2D", "width < 0");
    return error::kNoError;
  }
  if (height < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glCopyTexImage2D", "height < 0");
    return error::kNoError;
  }
  DoCopyTexImage2D(target, level, internalformat, x, y, width, height, border);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCopyTexSubImage2D(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::CopyTexSubImage2D& c =
      *static_cast<const gles2::cmds::CopyTexSubImage2D*>(cmd_data);
  (void)c;
  error::Error error;
  error = WillAccessBoundFramebufferForRead();
  if (error != error::kNoError)
    return error;
  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  GLint xoffset = static_cast<GLint>(c.xoffset);
  GLint yoffset = static_cast<GLint>(c.yoffset);
  GLint x = static_cast<GLint>(c.x);
  GLint y = static_cast<GLint>(c.y);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  if (!validators_->texture_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glCopyTexSubImage2D", target, "target");
    return error::kNoError;
  }
  if (width < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glCopyTexSubImage2D", "width < 0");
    return error::kNoError;
  }
  if (height < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glCopyTexSubImage2D", "height < 0");
    return error::kNoError;
  }
  DoCopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCopyTexSubImage3D(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::CopyTexSubImage3D& c =
      *static_cast<const gles2::cmds::CopyTexSubImage3D*>(cmd_data);
  (void)c;
  error::Error error;
  error = WillAccessBoundFramebufferForRead();
  if (error != error::kNoError)
    return error;
  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  GLint xoffset = static_cast<GLint>(c.xoffset);
  GLint yoffset = static_cast<GLint>(c.yoffset);
  GLint zoffset = static_cast<GLint>(c.zoffset);
  GLint x = static_cast<GLint>(c.x);
  GLint y = static_cast<GLint>(c.y);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  glCopyTexSubImage3D(target, level, xoffset, yoffset, zoffset, x, y, width,
                      height);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCreateProgram(uint32_t immediate_data_size,
                                                   const void* cmd_data) {
  const gles2::cmds::CreateProgram& c =
      *static_cast<const gles2::cmds::CreateProgram*>(cmd_data);
  (void)c;
  uint32_t client_id = c.client_id;
  if (GetProgram(client_id)) {
    return error::kInvalidArguments;
  }
  GLuint service_id = glCreateProgram();
  if (service_id) {
    CreateProgram(client_id, service_id);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCreateShader(uint32_t immediate_data_size,
                                                  const void* cmd_data) {
  const gles2::cmds::CreateShader& c =
      *static_cast<const gles2::cmds::CreateShader*>(cmd_data);
  (void)c;
  GLenum type = static_cast<GLenum>(c.type);
  if (!validators_->shader_type.IsValid(type)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glCreateShader", type, "type");
    return error::kNoError;
  }
  uint32_t client_id = c.client_id;
  if (GetShader(client_id)) {
    return error::kInvalidArguments;
  }
  GLuint service_id = glCreateShader(type);
  if (service_id) {
    CreateShader(client_id, service_id, type);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCullFace(uint32_t immediate_data_size,
                                              const void* cmd_data) {
  const gles2::cmds::CullFace& c =
      *static_cast<const gles2::cmds::CullFace*>(cmd_data);
  (void)c;
  GLenum mode = static_cast<GLenum>(c.mode);
  if (!validators_->face_type.IsValid(mode)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glCullFace", mode, "mode");
    return error::kNoError;
  }
  if (state_.cull_mode != mode) {
    state_.cull_mode = mode;
    glCullFace(mode);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDeleteBuffersImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::DeleteBuffersImmediate& c =
      *static_cast<const gles2::cmds::DeleteBuffersImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  const GLuint* buffers =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (buffers == NULL) {
    return error::kOutOfBounds;
  }
  DeleteBuffersHelper(n, buffers);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDeleteFramebuffersImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::DeleteFramebuffersImmediate& c =
      *static_cast<const gles2::cmds::DeleteFramebuffersImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  const GLuint* framebuffers =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (framebuffers == NULL) {
    return error::kOutOfBounds;
  }
  DeleteFramebuffersHelper(n, framebuffers);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDeleteRenderbuffersImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::DeleteRenderbuffersImmediate& c =
      *static_cast<const gles2::cmds::DeleteRenderbuffersImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  const GLuint* renderbuffers =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (renderbuffers == NULL) {
    return error::kOutOfBounds;
  }
  DeleteRenderbuffersHelper(n, renderbuffers);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDeleteSamplersImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::DeleteSamplersImmediate& c =
      *static_cast<const gles2::cmds::DeleteSamplersImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  const GLuint* samplers =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (samplers == NULL) {
    return error::kOutOfBounds;
  }
  for (GLsizei ii = 0; ii < n; ++ii) {
    GLuint service_id = 0;
    if (group_->GetSamplerServiceId(samplers[ii], &service_id)) {
      glDeleteSamplers(1, &service_id);
      group_->RemoveSamplerId(samplers[ii]);
    }
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDeleteSync(uint32_t immediate_data_size,
                                                const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::DeleteSync& c =
      *static_cast<const gles2::cmds::DeleteSync*>(cmd_data);
  (void)c;
  GLuint sync = c.sync;
  GLsync service_id = 0;
  if (group_->GetSyncServiceId(sync, &service_id)) {
    glDeleteSync(service_id);
    group_->RemoveSyncId(sync);
  } else {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glDeleteSync", "unknown sync");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDeleteTexturesImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::DeleteTexturesImmediate& c =
      *static_cast<const gles2::cmds::DeleteTexturesImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  const GLuint* textures =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (textures == NULL) {
    return error::kOutOfBounds;
  }
  DeleteTexturesHelper(n, textures);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDeleteTransformFeedbacksImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::DeleteTransformFeedbacksImmediate& c =
      *static_cast<const gles2::cmds::DeleteTransformFeedbacksImmediate*>(
          cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  const GLuint* ids =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (ids == NULL) {
    return error::kOutOfBounds;
  }
  for (GLsizei ii = 0; ii < n; ++ii) {
    GLuint service_id = 0;
    if (group_->GetTransformFeedbackServiceId(ids[ii], &service_id)) {
      glDeleteTransformFeedbacks(1, &service_id);
      group_->RemoveTransformFeedbackId(ids[ii]);
    }
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDepthFunc(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::DepthFunc& c =
      *static_cast<const gles2::cmds::DepthFunc*>(cmd_data);
  (void)c;
  GLenum func = static_cast<GLenum>(c.func);
  if (!validators_->cmp_function.IsValid(func)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glDepthFunc", func, "func");
    return error::kNoError;
  }
  if (state_.depth_func != func) {
    state_.depth_func = func;
    glDepthFunc(func);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDepthMask(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::DepthMask& c =
      *static_cast<const gles2::cmds::DepthMask*>(cmd_data);
  (void)c;
  GLboolean flag = static_cast<GLboolean>(c.flag);
  if (state_.depth_mask != flag) {
    state_.depth_mask = flag;
    framebuffer_state_.clear_state_dirty = true;
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDepthRangef(uint32_t immediate_data_size,
                                                 const void* cmd_data) {
  const gles2::cmds::DepthRangef& c =
      *static_cast<const gles2::cmds::DepthRangef*>(cmd_data);
  (void)c;
  GLclampf zNear = static_cast<GLclampf>(c.zNear);
  GLclampf zFar = static_cast<GLclampf>(c.zFar);
  DoDepthRangef(zNear, zFar);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDetachShader(uint32_t immediate_data_size,
                                                  const void* cmd_data) {
  const gles2::cmds::DetachShader& c =
      *static_cast<const gles2::cmds::DetachShader*>(cmd_data);
  (void)c;
  GLuint program = c.program;
  GLuint shader = c.shader;
  DoDetachShader(program, shader);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDisable(uint32_t immediate_data_size,
                                             const void* cmd_data) {
  const gles2::cmds::Disable& c =
      *static_cast<const gles2::cmds::Disable*>(cmd_data);
  (void)c;
  GLenum cap = static_cast<GLenum>(c.cap);
  if (!validators_->capability.IsValid(cap)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glDisable", cap, "cap");
    return error::kNoError;
  }
  DoDisable(cap);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDisableVertexAttribArray(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::DisableVertexAttribArray& c =
      *static_cast<const gles2::cmds::DisableVertexAttribArray*>(cmd_data);
  (void)c;
  GLuint index = static_cast<GLuint>(c.index);
  DoDisableVertexAttribArray(index);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleEnable(uint32_t immediate_data_size,
                                            const void* cmd_data) {
  const gles2::cmds::Enable& c =
      *static_cast<const gles2::cmds::Enable*>(cmd_data);
  (void)c;
  GLenum cap = static_cast<GLenum>(c.cap);
  if (!validators_->capability.IsValid(cap)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glEnable", cap, "cap");
    return error::kNoError;
  }
  DoEnable(cap);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleEnableVertexAttribArray(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::EnableVertexAttribArray& c =
      *static_cast<const gles2::cmds::EnableVertexAttribArray*>(cmd_data);
  (void)c;
  GLuint index = static_cast<GLuint>(c.index);
  DoEnableVertexAttribArray(index);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleFenceSync(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::FenceSync& c =
      *static_cast<const gles2::cmds::FenceSync*>(cmd_data);
  (void)c;
  GLenum condition = static_cast<GLenum>(c.condition);
  GLbitfield flags = static_cast<GLbitfield>(c.flags);
  uint32_t client_id = c.client_id;
  GLsync service_id = 0;
  if (group_->GetSyncServiceId(client_id, &service_id)) {
    return error::kInvalidArguments;
  }
  service_id = glFenceSync(condition, flags);
  if (service_id) {
    group_->AddSyncId(client_id, service_id);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleFinish(uint32_t immediate_data_size,
                                            const void* cmd_data) {
  const gles2::cmds::Finish& c =
      *static_cast<const gles2::cmds::Finish*>(cmd_data);
  (void)c;
  error::Error error;
  error = WillAccessBoundFramebufferForRead();
  if (error != error::kNoError)
    return error;
  DoFinish();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleFlush(uint32_t immediate_data_size,
                                           const void* cmd_data) {
  const gles2::cmds::Flush& c =
      *static_cast<const gles2::cmds::Flush*>(cmd_data);
  (void)c;
  DoFlush();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleFramebufferRenderbuffer(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::FramebufferRenderbuffer& c =
      *static_cast<const gles2::cmds::FramebufferRenderbuffer*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum attachment = static_cast<GLenum>(c.attachment);
  GLenum renderbuffertarget = static_cast<GLenum>(c.renderbuffertarget);
  GLuint renderbuffer = c.renderbuffer;
  if (!validators_->frame_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glFramebufferRenderbuffer", target,
                                    "target");
    return error::kNoError;
  }
  if (!validators_->attachment.IsValid(attachment)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glFramebufferRenderbuffer", attachment,
                                    "attachment");
    return error::kNoError;
  }
  if (!validators_->render_buffer_target.IsValid(renderbuffertarget)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glFramebufferRenderbuffer",
                                    renderbuffertarget, "renderbuffertarget");
    return error::kNoError;
  }
  DoFramebufferRenderbuffer(target, attachment, renderbuffertarget,
                            renderbuffer);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleFramebufferTexture2D(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::FramebufferTexture2D& c =
      *static_cast<const gles2::cmds::FramebufferTexture2D*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum attachment = static_cast<GLenum>(c.attachment);
  GLenum textarget = static_cast<GLenum>(c.textarget);
  GLuint texture = c.texture;
  GLint level = static_cast<GLint>(c.level);
  if (!validators_->frame_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glFramebufferTexture2D", target, "target");
    return error::kNoError;
  }
  if (!validators_->attachment.IsValid(attachment)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glFramebufferTexture2D", attachment,
                                    "attachment");
    return error::kNoError;
  }
  if (!validators_->texture_target.IsValid(textarget)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glFramebufferTexture2D", textarget,
                                    "textarget");
    return error::kNoError;
  }
  DoFramebufferTexture2D(target, attachment, textarget, texture, level);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleFramebufferTextureLayer(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::FramebufferTextureLayer& c =
      *static_cast<const gles2::cmds::FramebufferTextureLayer*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum attachment = static_cast<GLenum>(c.attachment);
  GLuint texture = c.texture;
  GLint level = static_cast<GLint>(c.level);
  GLint layer = static_cast<GLint>(c.layer);
  DoFramebufferTextureLayer(target, attachment, texture, level, layer);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleFrontFace(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::FrontFace& c =
      *static_cast<const gles2::cmds::FrontFace*>(cmd_data);
  (void)c;
  GLenum mode = static_cast<GLenum>(c.mode);
  if (!validators_->face_mode.IsValid(mode)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glFrontFace", mode, "mode");
    return error::kNoError;
  }
  if (state_.front_face != mode) {
    state_.front_face = mode;
    glFrontFace(mode);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGenBuffersImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GenBuffersImmediate& c =
      *static_cast<const gles2::cmds::GenBuffersImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  GLuint* buffers =
      GetImmediateDataAs<GLuint*>(c, data_size, immediate_data_size);
  if (buffers == NULL) {
    return error::kOutOfBounds;
  }
  if (!GenBuffersHelper(n, buffers)) {
    return error::kInvalidArguments;
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGenerateMipmap(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GenerateMipmap& c =
      *static_cast<const gles2::cmds::GenerateMipmap*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGenerateMipmap", target, "target");
    return error::kNoError;
  }
  DoGenerateMipmap(target);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGenFramebuffersImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GenFramebuffersImmediate& c =
      *static_cast<const gles2::cmds::GenFramebuffersImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  GLuint* framebuffers =
      GetImmediateDataAs<GLuint*>(c, data_size, immediate_data_size);
  if (framebuffers == NULL) {
    return error::kOutOfBounds;
  }
  if (!GenFramebuffersHelper(n, framebuffers)) {
    return error::kInvalidArguments;
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGenRenderbuffersImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GenRenderbuffersImmediate& c =
      *static_cast<const gles2::cmds::GenRenderbuffersImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  GLuint* renderbuffers =
      GetImmediateDataAs<GLuint*>(c, data_size, immediate_data_size);
  if (renderbuffers == NULL) {
    return error::kOutOfBounds;
  }
  if (!GenRenderbuffersHelper(n, renderbuffers)) {
    return error::kInvalidArguments;
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGenSamplersImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GenSamplersImmediate& c =
      *static_cast<const gles2::cmds::GenSamplersImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  GLuint* samplers =
      GetImmediateDataAs<GLuint*>(c, data_size, immediate_data_size);
  if (samplers == NULL) {
    return error::kOutOfBounds;
  }
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (group_->GetSamplerServiceId(samplers[ii], NULL)) {
      return error::kInvalidArguments;
    }
  }
  scoped_ptr<GLuint[]> service_ids(new GLuint[n]);
  glGenSamplers(n, service_ids.get());
  for (GLsizei ii = 0; ii < n; ++ii) {
    group_->AddSamplerId(samplers[ii], service_ids[ii]);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGenTexturesImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GenTexturesImmediate& c =
      *static_cast<const gles2::cmds::GenTexturesImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  GLuint* textures =
      GetImmediateDataAs<GLuint*>(c, data_size, immediate_data_size);
  if (textures == NULL) {
    return error::kOutOfBounds;
  }
  if (!GenTexturesHelper(n, textures)) {
    return error::kInvalidArguments;
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGenTransformFeedbacksImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GenTransformFeedbacksImmediate& c =
      *static_cast<const gles2::cmds::GenTransformFeedbacksImmediate*>(
          cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  GLuint* ids = GetImmediateDataAs<GLuint*>(c, data_size, immediate_data_size);
  if (ids == NULL) {
    return error::kOutOfBounds;
  }
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (group_->GetTransformFeedbackServiceId(ids[ii], NULL)) {
      return error::kInvalidArguments;
    }
  }
  scoped_ptr<GLuint[]> service_ids(new GLuint[n]);
  glGenTransformFeedbacks(n, service_ids.get());
  for (GLsizei ii = 0; ii < n; ++ii) {
    group_->AddTransformFeedbackId(ids[ii], service_ids[ii]);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetBooleanv(uint32_t immediate_data_size,
                                                 const void* cmd_data) {
  const gles2::cmds::GetBooleanv& c =
      *static_cast<const gles2::cmds::GetBooleanv*>(cmd_data);
  (void)c;
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetBooleanv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLboolean* params = result ? result->GetData() : NULL;
  if (!validators_->g_l_state.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetBooleanv", pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetBooleanv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetBooleanv(pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetBooleanv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetBufferParameteriv(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetBufferParameteriv& c =
      *static_cast<const gles2::cmds::GetBufferParameteriv*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetBufferParameteriv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLint* params = result ? result->GetData() : NULL;
  if (!validators_->buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetBufferParameteriv", target, "target");
    return error::kNoError;
  }
  if (!validators_->buffer_parameter.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetBufferParameteriv", pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetBufferParameteriv(target, pname, params);
  result->SetNumResults(num_values);
  return error::kNoError;
}
error::Error GLES2DecoderImpl::HandleGetError(uint32_t immediate_data_size,
                                              const void* cmd_data) {
  const gles2::cmds::GetError& c =
      *static_cast<const gles2::cmds::GetError*>(cmd_data);
  (void)c;
  typedef cmds::GetError::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  *result_dst = GetErrorState()->GetGLError();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetFloatv(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::GetFloatv& c =
      *static_cast<const gles2::cmds::GetFloatv*>(cmd_data);
  (void)c;
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetFloatv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLfloat* params = result ? result->GetData() : NULL;
  if (!validators_->g_l_state.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetFloatv", pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetFloatv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetFloatv(pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetFloatv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetFramebufferAttachmentParameteriv(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetFramebufferAttachmentParameteriv& c =
      *static_cast<const gles2::cmds::GetFramebufferAttachmentParameteriv*>(
          cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum attachment = static_cast<GLenum>(c.attachment);
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetFramebufferAttachmentParameteriv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLint* params = result ? result->GetData() : NULL;
  if (!validators_->frame_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetFramebufferAttachmentParameteriv",
                                    target, "target");
    return error::kNoError;
  }
  if (!validators_->attachment.IsValid(attachment)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetFramebufferAttachmentParameteriv",
                                    attachment, "attachment");
    return error::kNoError;
  }
  if (!validators_->frame_buffer_parameter.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetFramebufferAttachmentParameteriv",
                                    pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetFramebufferAttachmentParameteriv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetFramebufferAttachmentParameteriv(target, attachment, pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetFramebufferAttachmentParameteriv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetInteger64v(uint32_t immediate_data_size,
                                                   const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetInteger64v& c =
      *static_cast<const gles2::cmds::GetInteger64v*>(cmd_data);
  (void)c;
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetInteger64v::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLint64* params = result ? result->GetData() : NULL;
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetInteger64v");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetInteger64v(pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetInteger64v", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetIntegeri_v(uint32_t immediate_data_size,
                                                   const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetIntegeri_v& c =
      *static_cast<const gles2::cmds::GetIntegeri_v*>(cmd_data);
  (void)c;
  GLenum pname = static_cast<GLenum>(c.pname);
  GLuint index = static_cast<GLuint>(c.index);
  typedef cmds::GetIntegeri_v::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(c.data_shm_id, c.data_shm_offset,
                                              Result::ComputeSize(num_values));
  GLint* data = result ? result->GetData() : NULL;
  if (data == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetIntegeri_v");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  glGetIntegeri_v(pname, index, data);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetIntegeri_v", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetInteger64i_v(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetInteger64i_v& c =
      *static_cast<const gles2::cmds::GetInteger64i_v*>(cmd_data);
  (void)c;
  GLenum pname = static_cast<GLenum>(c.pname);
  GLuint index = static_cast<GLuint>(c.index);
  typedef cmds::GetInteger64i_v::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(c.data_shm_id, c.data_shm_offset,
                                              Result::ComputeSize(num_values));
  GLint64* data = result ? result->GetData() : NULL;
  if (data == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetInteger64i_v");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  glGetInteger64i_v(pname, index, data);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetInteger64i_v", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetIntegerv(uint32_t immediate_data_size,
                                                 const void* cmd_data) {
  const gles2::cmds::GetIntegerv& c =
      *static_cast<const gles2::cmds::GetIntegerv*>(cmd_data);
  (void)c;
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetIntegerv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLint* params = result ? result->GetData() : NULL;
  if (!validators_->g_l_state.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetIntegerv", pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetIntegerv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetIntegerv(pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetIntegerv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetInternalformativ(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetInternalformativ& c =
      *static_cast<const gles2::cmds::GetInternalformativ*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum format = static_cast<GLenum>(c.format);
  GLenum pname = static_cast<GLenum>(c.pname);
  GLsizei bufSize = static_cast<GLsizei>(c.bufSize);
  typedef cmds::GetInternalformativ::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLint* params = result ? result->GetData() : NULL;
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetInternalformativ");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  glGetInternalformativ(target, format, pname, bufSize, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetInternalformativ", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetProgramiv(uint32_t immediate_data_size,
                                                  const void* cmd_data) {
  const gles2::cmds::GetProgramiv& c =
      *static_cast<const gles2::cmds::GetProgramiv*>(cmd_data);
  (void)c;
  GLuint program = c.program;
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetProgramiv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLint* params = result ? result->GetData() : NULL;
  if (!validators_->program_parameter.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetProgramiv", pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetProgramiv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetProgramiv(program, pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetProgramiv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetRenderbufferParameteriv(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetRenderbufferParameteriv& c =
      *static_cast<const gles2::cmds::GetRenderbufferParameteriv*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetRenderbufferParameteriv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLint* params = result ? result->GetData() : NULL;
  if (!validators_->render_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetRenderbufferParameteriv", target,
                                    "target");
    return error::kNoError;
  }
  if (!validators_->render_buffer_parameter.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetRenderbufferParameteriv", pname,
                                    "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetRenderbufferParameteriv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetRenderbufferParameteriv(target, pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetRenderbufferParameteriv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetSamplerParameterfv(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetSamplerParameterfv& c =
      *static_cast<const gles2::cmds::GetSamplerParameterfv*>(cmd_data);
  (void)c;
  GLuint sampler = c.sampler;
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetSamplerParameterfv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLfloat* params = result ? result->GetData() : NULL;
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetSamplerParameterfv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  if (!group_->GetSamplerServiceId(sampler, &sampler)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glGetSamplerParameterfv",
                       "invalid sampler id");
    return error::kNoError;
  }
  glGetSamplerParameterfv(sampler, pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetSamplerParameterfv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetSamplerParameteriv(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetSamplerParameteriv& c =
      *static_cast<const gles2::cmds::GetSamplerParameteriv*>(cmd_data);
  (void)c;
  GLuint sampler = c.sampler;
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetSamplerParameteriv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLint* params = result ? result->GetData() : NULL;
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetSamplerParameteriv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  if (!group_->GetSamplerServiceId(sampler, &sampler)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glGetSamplerParameteriv",
                       "invalid sampler id");
    return error::kNoError;
  }
  glGetSamplerParameteriv(sampler, pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetSamplerParameteriv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetShaderiv(uint32_t immediate_data_size,
                                                 const void* cmd_data) {
  const gles2::cmds::GetShaderiv& c =
      *static_cast<const gles2::cmds::GetShaderiv*>(cmd_data);
  (void)c;
  GLuint shader = c.shader;
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetShaderiv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLint* params = result ? result->GetData() : NULL;
  if (!validators_->shader_parameter.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetShaderiv", pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetShaderiv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetShaderiv(shader, pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetShaderiv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetSynciv(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetSynciv& c =
      *static_cast<const gles2::cmds::GetSynciv*>(cmd_data);
  (void)c;
  GLuint sync = static_cast<GLuint>(c.sync);
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetSynciv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.values_shm_id, c.values_shm_offset, Result::ComputeSize(num_values));
  GLint* values = result ? result->GetData() : NULL;
  if (values == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetSynciv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  GLsync service_sync = 0;
  if (!group_->GetSyncServiceId(sync, &service_sync)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glGetSynciv", "invalid sync id");
    return error::kNoError;
  }
  glGetSynciv(service_sync, pname, num_values, nullptr, values);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetSynciv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetTexParameterfv(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetTexParameterfv& c =
      *static_cast<const gles2::cmds::GetTexParameterfv*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetTexParameterfv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLfloat* params = result ? result->GetData() : NULL;
  if (!validators_->get_tex_param_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetTexParameterfv", target, "target");
    return error::kNoError;
  }
  if (!validators_->texture_parameter.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetTexParameterfv", pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetTexParameterfv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetTexParameterfv(target, pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetTexParameterfv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetTexParameteriv(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetTexParameteriv& c =
      *static_cast<const gles2::cmds::GetTexParameteriv*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetTexParameteriv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLint* params = result ? result->GetData() : NULL;
  if (!validators_->get_tex_param_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetTexParameteriv", target, "target");
    return error::kNoError;
  }
  if (!validators_->texture_parameter.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetTexParameteriv", pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetTexParameteriv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetTexParameteriv(target, pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetTexParameteriv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetVertexAttribfv(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetVertexAttribfv& c =
      *static_cast<const gles2::cmds::GetVertexAttribfv*>(cmd_data);
  (void)c;
  GLuint index = static_cast<GLuint>(c.index);
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetVertexAttribfv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLfloat* params = result ? result->GetData() : NULL;
  if (!validators_->vertex_attribute.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetVertexAttribfv", pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetVertexAttribfv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetVertexAttribfv(index, pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetVertexAttribfv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetVertexAttribiv(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetVertexAttribiv& c =
      *static_cast<const gles2::cmds::GetVertexAttribiv*>(cmd_data);
  (void)c;
  GLuint index = static_cast<GLuint>(c.index);
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetVertexAttribiv::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLint* params = result ? result->GetData() : NULL;
  if (!validators_->vertex_attribute.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetVertexAttribiv", pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetVertexAttribiv");
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  DoGetVertexAttribiv(index, pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetVertexAttribiv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleHint(uint32_t immediate_data_size,
                                          const void* cmd_data) {
  const gles2::cmds::Hint& c = *static_cast<const gles2::cmds::Hint*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum mode = static_cast<GLenum>(c.mode);
  if (!validators_->hint_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glHint", target, "target");
    return error::kNoError;
  }
  if (!validators_->hint_mode.IsValid(mode)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glHint", mode, "mode");
    return error::kNoError;
  }
  switch (target) {
    case GL_GENERATE_MIPMAP_HINT:
      if (state_.hint_generate_mipmap != mode) {
        state_.hint_generate_mipmap = mode;
        glHint(target, mode);
      }
      break;
    case GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES:
      if (state_.hint_fragment_shader_derivative != mode) {
        state_.hint_fragment_shader_derivative = mode;
        glHint(target, mode);
      }
      break;
    default:
      NOTREACHED();
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleInvalidateFramebufferImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::InvalidateFramebufferImmediate& c =
      *static_cast<const gles2::cmds::InvalidateFramebufferImmediate*>(
          cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLenum), 1, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLenum* attachments =
      GetImmediateDataAs<const GLenum*>(c, data_size, immediate_data_size);
  if (attachments == NULL) {
    return error::kOutOfBounds;
  }
  glInvalidateFramebuffer(target, count, attachments);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleInvalidateSubFramebufferImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::InvalidateSubFramebufferImmediate& c =
      *static_cast<const gles2::cmds::InvalidateSubFramebufferImmediate*>(
          cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLenum), 1, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLenum* attachments =
      GetImmediateDataAs<const GLenum*>(c, data_size, immediate_data_size);
  GLint x = static_cast<GLint>(c.x);
  GLint y = static_cast<GLint>(c.y);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  if (attachments == NULL) {
    return error::kOutOfBounds;
  }
  glInvalidateSubFramebuffer(target, count, attachments, x, y, width, height);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleIsBuffer(uint32_t immediate_data_size,
                                              const void* cmd_data) {
  const gles2::cmds::IsBuffer& c =
      *static_cast<const gles2::cmds::IsBuffer*>(cmd_data);
  (void)c;
  GLuint buffer = c.buffer;
  typedef cmds::IsBuffer::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  *result_dst = DoIsBuffer(buffer);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleIsEnabled(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::IsEnabled& c =
      *static_cast<const gles2::cmds::IsEnabled*>(cmd_data);
  (void)c;
  GLenum cap = static_cast<GLenum>(c.cap);
  typedef cmds::IsEnabled::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  if (!validators_->capability.IsValid(cap)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glIsEnabled", cap, "cap");
    return error::kNoError;
  }
  *result_dst = DoIsEnabled(cap);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleIsFramebuffer(uint32_t immediate_data_size,
                                                   const void* cmd_data) {
  const gles2::cmds::IsFramebuffer& c =
      *static_cast<const gles2::cmds::IsFramebuffer*>(cmd_data);
  (void)c;
  GLuint framebuffer = c.framebuffer;
  typedef cmds::IsFramebuffer::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  *result_dst = DoIsFramebuffer(framebuffer);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleIsProgram(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::IsProgram& c =
      *static_cast<const gles2::cmds::IsProgram*>(cmd_data);
  (void)c;
  GLuint program = c.program;
  typedef cmds::IsProgram::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  *result_dst = DoIsProgram(program);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleIsRenderbuffer(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::IsRenderbuffer& c =
      *static_cast<const gles2::cmds::IsRenderbuffer*>(cmd_data);
  (void)c;
  GLuint renderbuffer = c.renderbuffer;
  typedef cmds::IsRenderbuffer::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  *result_dst = DoIsRenderbuffer(renderbuffer);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleIsSampler(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::IsSampler& c =
      *static_cast<const gles2::cmds::IsSampler*>(cmd_data);
  (void)c;
  GLuint sampler = c.sampler;
  typedef cmds::IsSampler::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  GLuint service_sampler = 0;
  *result_dst = group_->GetSamplerServiceId(sampler, &service_sampler);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleIsShader(uint32_t immediate_data_size,
                                              const void* cmd_data) {
  const gles2::cmds::IsShader& c =
      *static_cast<const gles2::cmds::IsShader*>(cmd_data);
  (void)c;
  GLuint shader = c.shader;
  typedef cmds::IsShader::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  *result_dst = DoIsShader(shader);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleIsSync(uint32_t immediate_data_size,
                                            const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::IsSync& c =
      *static_cast<const gles2::cmds::IsSync*>(cmd_data);
  (void)c;
  GLuint sync = c.sync;
  typedef cmds::IsSync::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  GLsync service_sync = 0;
  *result_dst = group_->GetSyncServiceId(sync, &service_sync);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleIsTexture(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::IsTexture& c =
      *static_cast<const gles2::cmds::IsTexture*>(cmd_data);
  (void)c;
  GLuint texture = c.texture;
  typedef cmds::IsTexture::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  *result_dst = DoIsTexture(texture);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleIsTransformFeedback(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::IsTransformFeedback& c =
      *static_cast<const gles2::cmds::IsTransformFeedback*>(cmd_data);
  (void)c;
  GLuint transformfeedback = c.transformfeedback;
  typedef cmds::IsTransformFeedback::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  GLuint service_transformfeedback = 0;
  *result_dst = group_->GetTransformFeedbackServiceId(
      transformfeedback, &service_transformfeedback);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleLineWidth(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::LineWidth& c =
      *static_cast<const gles2::cmds::LineWidth*>(cmd_data);
  (void)c;
  GLfloat width = static_cast<GLfloat>(c.width);
  if (width <= 0.0f || std::isnan(width)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "LineWidth", "width out of range");
    return error::kNoError;
  }
  if (state_.line_width != width) {
    state_.line_width = width;
    glLineWidth(width);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleLinkProgram(uint32_t immediate_data_size,
                                                 const void* cmd_data) {
  const gles2::cmds::LinkProgram& c =
      *static_cast<const gles2::cmds::LinkProgram*>(cmd_data);
  (void)c;
  GLuint program = c.program;
  DoLinkProgram(program);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandlePauseTransformFeedback(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::PauseTransformFeedback& c =
      *static_cast<const gles2::cmds::PauseTransformFeedback*>(cmd_data);
  (void)c;
  glPauseTransformFeedback();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandlePolygonOffset(uint32_t immediate_data_size,
                                                   const void* cmd_data) {
  const gles2::cmds::PolygonOffset& c =
      *static_cast<const gles2::cmds::PolygonOffset*>(cmd_data);
  (void)c;
  GLfloat factor = static_cast<GLfloat>(c.factor);
  GLfloat units = static_cast<GLfloat>(c.units);
  if (state_.polygon_offset_factor != factor ||
      state_.polygon_offset_units != units) {
    state_.polygon_offset_factor = factor;
    state_.polygon_offset_units = units;
    glPolygonOffset(factor, units);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleReadBuffer(uint32_t immediate_data_size,
                                                const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::ReadBuffer& c =
      *static_cast<const gles2::cmds::ReadBuffer*>(cmd_data);
  (void)c;
  GLenum src = static_cast<GLenum>(c.src);
  glReadBuffer(src);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleReleaseShaderCompiler(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::ReleaseShaderCompiler& c =
      *static_cast<const gles2::cmds::ReleaseShaderCompiler*>(cmd_data);
  (void)c;
  DoReleaseShaderCompiler();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleRenderbufferStorage(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::RenderbufferStorage& c =
      *static_cast<const gles2::cmds::RenderbufferStorage*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum internalformat = static_cast<GLenum>(c.internalformat);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  if (!validators_->render_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glRenderbufferStorage", target, "target");
    return error::kNoError;
  }
  if (!validators_->render_buffer_format.IsValid(internalformat)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glRenderbufferStorage", internalformat,
                                    "internalformat");
    return error::kNoError;
  }
  if (width < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glRenderbufferStorage", "width < 0");
    return error::kNoError;
  }
  if (height < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glRenderbufferStorage", "height < 0");
    return error::kNoError;
  }
  DoRenderbufferStorage(target, internalformat, width, height);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleResumeTransformFeedback(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::ResumeTransformFeedback& c =
      *static_cast<const gles2::cmds::ResumeTransformFeedback*>(cmd_data);
  (void)c;
  glResumeTransformFeedback();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleSampleCoverage(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::SampleCoverage& c =
      *static_cast<const gles2::cmds::SampleCoverage*>(cmd_data);
  (void)c;
  GLclampf value = static_cast<GLclampf>(c.value);
  GLboolean invert = static_cast<GLboolean>(c.invert);
  DoSampleCoverage(value, invert);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleSamplerParameterf(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::SamplerParameterf& c =
      *static_cast<const gles2::cmds::SamplerParameterf*>(cmd_data);
  (void)c;
  GLuint sampler = c.sampler;
  GLenum pname = static_cast<GLenum>(c.pname);
  GLfloat param = static_cast<GLfloat>(c.param);
  if (!group_->GetSamplerServiceId(sampler, &sampler)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glSamplerParameterf",
                       "invalid sampler id");
    return error::kNoError;
  }
  glSamplerParameterf(sampler, pname, param);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleSamplerParameterfvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::SamplerParameterfvImmediate& c =
      *static_cast<const gles2::cmds::SamplerParameterfvImmediate*>(cmd_data);
  (void)c;
  GLuint sampler = c.sampler;
  GLenum pname = static_cast<GLenum>(c.pname);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLfloat), 1, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* params =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  group_->GetSamplerServiceId(sampler, &sampler);
  DoSamplerParameterfv(sampler, pname, params);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleSamplerParameteri(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::SamplerParameteri& c =
      *static_cast<const gles2::cmds::SamplerParameteri*>(cmd_data);
  (void)c;
  GLuint sampler = c.sampler;
  GLenum pname = static_cast<GLenum>(c.pname);
  GLint param = static_cast<GLint>(c.param);
  if (!group_->GetSamplerServiceId(sampler, &sampler)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glSamplerParameteri",
                       "invalid sampler id");
    return error::kNoError;
  }
  glSamplerParameteri(sampler, pname, param);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleSamplerParameterivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::SamplerParameterivImmediate& c =
      *static_cast<const gles2::cmds::SamplerParameterivImmediate*>(cmd_data);
  (void)c;
  GLuint sampler = c.sampler;
  GLenum pname = static_cast<GLenum>(c.pname);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLint), 1, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLint* params =
      GetImmediateDataAs<const GLint*>(c, data_size, immediate_data_size);
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  DoSamplerParameteriv(sampler, pname, params);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleScissor(uint32_t immediate_data_size,
                                             const void* cmd_data) {
  const gles2::cmds::Scissor& c =
      *static_cast<const gles2::cmds::Scissor*>(cmd_data);
  (void)c;
  GLint x = static_cast<GLint>(c.x);
  GLint y = static_cast<GLint>(c.y);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  if (width < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glScissor", "width < 0");
    return error::kNoError;
  }
  if (height < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glScissor", "height < 0");
    return error::kNoError;
  }
  if (state_.scissor_x != x || state_.scissor_y != y ||
      state_.scissor_width != width || state_.scissor_height != height) {
    state_.scissor_x = x;
    state_.scissor_y = y;
    state_.scissor_width = width;
    state_.scissor_height = height;
    glScissor(x, y, width, height);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleShaderSourceBucket(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::ShaderSourceBucket& c =
      *static_cast<const gles2::cmds::ShaderSourceBucket*>(cmd_data);
  (void)c;
  GLuint shader = static_cast<GLuint>(c.shader);

  Bucket* bucket = GetBucket(c.str_bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  GLsizei count = 0;
  std::vector<char*> strs;
  std::vector<GLint> len;
  if (!bucket->GetAsStrings(&count, &strs, &len)) {
    return error::kInvalidArguments;
  }
  const char** str =
      strs.size() > 0 ? const_cast<const char**>(&strs[0]) : NULL;
  const GLint* length =
      len.size() > 0 ? const_cast<const GLint*>(&len[0]) : NULL;
  (void)length;
  DoShaderSource(shader, count, str, length);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleStencilFunc(uint32_t immediate_data_size,
                                                 const void* cmd_data) {
  const gles2::cmds::StencilFunc& c =
      *static_cast<const gles2::cmds::StencilFunc*>(cmd_data);
  (void)c;
  GLenum func = static_cast<GLenum>(c.func);
  GLint ref = static_cast<GLint>(c.ref);
  GLuint mask = static_cast<GLuint>(c.mask);
  if (!validators_->cmp_function.IsValid(func)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glStencilFunc", func, "func");
    return error::kNoError;
  }
  if (state_.stencil_front_func != func || state_.stencil_front_ref != ref ||
      state_.stencil_front_mask != mask || state_.stencil_back_func != func ||
      state_.stencil_back_ref != ref || state_.stencil_back_mask != mask) {
    state_.stencil_front_func = func;
    state_.stencil_front_ref = ref;
    state_.stencil_front_mask = mask;
    state_.stencil_back_func = func;
    state_.stencil_back_ref = ref;
    state_.stencil_back_mask = mask;
    glStencilFunc(func, ref, mask);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleStencilFuncSeparate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::StencilFuncSeparate& c =
      *static_cast<const gles2::cmds::StencilFuncSeparate*>(cmd_data);
  (void)c;
  GLenum face = static_cast<GLenum>(c.face);
  GLenum func = static_cast<GLenum>(c.func);
  GLint ref = static_cast<GLint>(c.ref);
  GLuint mask = static_cast<GLuint>(c.mask);
  if (!validators_->face_type.IsValid(face)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glStencilFuncSeparate", face, "face");
    return error::kNoError;
  }
  if (!validators_->cmp_function.IsValid(func)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glStencilFuncSeparate", func, "func");
    return error::kNoError;
  }
  bool changed = false;
  if (face == GL_FRONT || face == GL_FRONT_AND_BACK) {
    changed |= state_.stencil_front_func != func ||
               state_.stencil_front_ref != ref ||
               state_.stencil_front_mask != mask;
  }
  if (face == GL_BACK || face == GL_FRONT_AND_BACK) {
    changed |= state_.stencil_back_func != func ||
               state_.stencil_back_ref != ref ||
               state_.stencil_back_mask != mask;
  }
  if (changed) {
    if (face == GL_FRONT || face == GL_FRONT_AND_BACK) {
      state_.stencil_front_func = func;
      state_.stencil_front_ref = ref;
      state_.stencil_front_mask = mask;
    }
    if (face == GL_BACK || face == GL_FRONT_AND_BACK) {
      state_.stencil_back_func = func;
      state_.stencil_back_ref = ref;
      state_.stencil_back_mask = mask;
    }
    glStencilFuncSeparate(face, func, ref, mask);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleStencilMask(uint32_t immediate_data_size,
                                                 const void* cmd_data) {
  const gles2::cmds::StencilMask& c =
      *static_cast<const gles2::cmds::StencilMask*>(cmd_data);
  (void)c;
  GLuint mask = static_cast<GLuint>(c.mask);
  if (state_.stencil_front_writemask != mask ||
      state_.stencil_back_writemask != mask) {
    state_.stencil_front_writemask = mask;
    state_.stencil_back_writemask = mask;
    framebuffer_state_.clear_state_dirty = true;
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleStencilMaskSeparate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::StencilMaskSeparate& c =
      *static_cast<const gles2::cmds::StencilMaskSeparate*>(cmd_data);
  (void)c;
  GLenum face = static_cast<GLenum>(c.face);
  GLuint mask = static_cast<GLuint>(c.mask);
  if (!validators_->face_type.IsValid(face)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glStencilMaskSeparate", face, "face");
    return error::kNoError;
  }
  bool changed = false;
  if (face == GL_FRONT || face == GL_FRONT_AND_BACK) {
    changed |= state_.stencil_front_writemask != mask;
  }
  if (face == GL_BACK || face == GL_FRONT_AND_BACK) {
    changed |= state_.stencil_back_writemask != mask;
  }
  if (changed) {
    if (face == GL_FRONT || face == GL_FRONT_AND_BACK) {
      state_.stencil_front_writemask = mask;
    }
    if (face == GL_BACK || face == GL_FRONT_AND_BACK) {
      state_.stencil_back_writemask = mask;
    }
    framebuffer_state_.clear_state_dirty = true;
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleStencilOp(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::StencilOp& c =
      *static_cast<const gles2::cmds::StencilOp*>(cmd_data);
  (void)c;
  GLenum fail = static_cast<GLenum>(c.fail);
  GLenum zfail = static_cast<GLenum>(c.zfail);
  GLenum zpass = static_cast<GLenum>(c.zpass);
  if (!validators_->stencil_op.IsValid(fail)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glStencilOp", fail, "fail");
    return error::kNoError;
  }
  if (!validators_->stencil_op.IsValid(zfail)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glStencilOp", zfail, "zfail");
    return error::kNoError;
  }
  if (!validators_->stencil_op.IsValid(zpass)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glStencilOp", zpass, "zpass");
    return error::kNoError;
  }
  if (state_.stencil_front_fail_op != fail ||
      state_.stencil_front_z_fail_op != zfail ||
      state_.stencil_front_z_pass_op != zpass ||
      state_.stencil_back_fail_op != fail ||
      state_.stencil_back_z_fail_op != zfail ||
      state_.stencil_back_z_pass_op != zpass) {
    state_.stencil_front_fail_op = fail;
    state_.stencil_front_z_fail_op = zfail;
    state_.stencil_front_z_pass_op = zpass;
    state_.stencil_back_fail_op = fail;
    state_.stencil_back_z_fail_op = zfail;
    state_.stencil_back_z_pass_op = zpass;
    glStencilOp(fail, zfail, zpass);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleStencilOpSeparate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::StencilOpSeparate& c =
      *static_cast<const gles2::cmds::StencilOpSeparate*>(cmd_data);
  (void)c;
  GLenum face = static_cast<GLenum>(c.face);
  GLenum fail = static_cast<GLenum>(c.fail);
  GLenum zfail = static_cast<GLenum>(c.zfail);
  GLenum zpass = static_cast<GLenum>(c.zpass);
  if (!validators_->face_type.IsValid(face)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glStencilOpSeparate", face, "face");
    return error::kNoError;
  }
  if (!validators_->stencil_op.IsValid(fail)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glStencilOpSeparate", fail, "fail");
    return error::kNoError;
  }
  if (!validators_->stencil_op.IsValid(zfail)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glStencilOpSeparate", zfail, "zfail");
    return error::kNoError;
  }
  if (!validators_->stencil_op.IsValid(zpass)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glStencilOpSeparate", zpass, "zpass");
    return error::kNoError;
  }
  bool changed = false;
  if (face == GL_FRONT || face == GL_FRONT_AND_BACK) {
    changed |= state_.stencil_front_fail_op != fail ||
               state_.stencil_front_z_fail_op != zfail ||
               state_.stencil_front_z_pass_op != zpass;
  }
  if (face == GL_BACK || face == GL_FRONT_AND_BACK) {
    changed |= state_.stencil_back_fail_op != fail ||
               state_.stencil_back_z_fail_op != zfail ||
               state_.stencil_back_z_pass_op != zpass;
  }
  if (changed) {
    if (face == GL_FRONT || face == GL_FRONT_AND_BACK) {
      state_.stencil_front_fail_op = fail;
      state_.stencil_front_z_fail_op = zfail;
      state_.stencil_front_z_pass_op = zpass;
    }
    if (face == GL_BACK || face == GL_FRONT_AND_BACK) {
      state_.stencil_back_fail_op = fail;
      state_.stencil_back_z_fail_op = zfail;
      state_.stencil_back_z_pass_op = zpass;
    }
    glStencilOpSeparate(face, fail, zfail, zpass);
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleTexParameterf(uint32_t immediate_data_size,
                                                   const void* cmd_data) {
  const gles2::cmds::TexParameterf& c =
      *static_cast<const gles2::cmds::TexParameterf*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum pname = static_cast<GLenum>(c.pname);
  GLfloat param = static_cast<GLfloat>(c.param);
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glTexParameterf", target, "target");
    return error::kNoError;
  }
  if (!validators_->texture_parameter.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glTexParameterf", pname, "pname");
    return error::kNoError;
  }
  DoTexParameterf(target, pname, param);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleTexParameterfvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::TexParameterfvImmediate& c =
      *static_cast<const gles2::cmds::TexParameterfvImmediate*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum pname = static_cast<GLenum>(c.pname);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLfloat), 1, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* params =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glTexParameterfv", target, "target");
    return error::kNoError;
  }
  if (!validators_->texture_parameter.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glTexParameterfv", pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  DoTexParameterfv(target, pname, params);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleTexParameteri(uint32_t immediate_data_size,
                                                   const void* cmd_data) {
  const gles2::cmds::TexParameteri& c =
      *static_cast<const gles2::cmds::TexParameteri*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum pname = static_cast<GLenum>(c.pname);
  GLint param = static_cast<GLint>(c.param);
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glTexParameteri", target, "target");
    return error::kNoError;
  }
  if (!validators_->texture_parameter.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glTexParameteri", pname, "pname");
    return error::kNoError;
  }
  DoTexParameteri(target, pname, param);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleTexParameterivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::TexParameterivImmediate& c =
      *static_cast<const gles2::cmds::TexParameterivImmediate*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum pname = static_cast<GLenum>(c.pname);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLint), 1, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLint* params =
      GetImmediateDataAs<const GLint*>(c, data_size, immediate_data_size);
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glTexParameteriv", target, "target");
    return error::kNoError;
  }
  if (!validators_->texture_parameter.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glTexParameteriv", pname, "pname");
    return error::kNoError;
  }
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  DoTexParameteriv(target, pname, params);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleTexStorage3D(uint32_t immediate_data_size,
                                                  const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::TexStorage3D& c =
      *static_cast<const gles2::cmds::TexStorage3D*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLsizei levels = static_cast<GLsizei>(c.levels);
  GLenum internalFormat = static_cast<GLenum>(c.internalFormat);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLsizei depth = static_cast<GLsizei>(c.depth);
  glTexStorage3D(target, levels, internalFormat, width, height, depth);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleTransformFeedbackVaryingsBucket(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::TransformFeedbackVaryingsBucket& c =
      *static_cast<const gles2::cmds::TransformFeedbackVaryingsBucket*>(
          cmd_data);
  (void)c;
  GLuint program = static_cast<GLuint>(c.program);

  Bucket* bucket = GetBucket(c.varyings_bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  GLsizei count = 0;
  std::vector<char*> strs;
  std::vector<GLint> len;
  if (!bucket->GetAsStrings(&count, &strs, &len)) {
    return error::kInvalidArguments;
  }
  const char** varyings =
      strs.size() > 0 ? const_cast<const char**>(&strs[0]) : NULL;
  const GLint* length =
      len.size() > 0 ? const_cast<const GLint*>(&len[0]) : NULL;
  (void)length;
  GLenum buffermode = static_cast<GLenum>(c.buffermode);
  DoTransformFeedbackVaryings(program, count, varyings, buffermode);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform1f(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::Uniform1f& c =
      *static_cast<const gles2::cmds::Uniform1f*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLfloat x = static_cast<GLfloat>(c.x);
  GLfloat temp[1] = {
      x,
  };
  DoUniform1fv(location, 1, &temp[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform1fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::Uniform1fvImmediate& c =
      *static_cast<const gles2::cmds::Uniform1fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 1, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* v =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (v == NULL) {
    return error::kOutOfBounds;
  }
  DoUniform1fv(location, count, v);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform1i(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::Uniform1i& c =
      *static_cast<const gles2::cmds::Uniform1i*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLint x = static_cast<GLint>(c.x);
  DoUniform1i(location, x);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform1ivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::Uniform1ivImmediate& c =
      *static_cast<const gles2::cmds::Uniform1ivImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLint), 1, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLint* v =
      GetImmediateDataAs<const GLint*>(c, data_size, immediate_data_size);
  if (v == NULL) {
    return error::kOutOfBounds;
  }
  DoUniform1iv(location, count, v);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform1ui(uint32_t immediate_data_size,
                                                const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::Uniform1ui& c =
      *static_cast<const gles2::cmds::Uniform1ui*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLuint x = static_cast<GLuint>(c.x);
  GLuint temp[1] = {
      x,
  };
  glUniform1uiv(location, 1, &temp[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform1uivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::Uniform1uivImmediate& c =
      *static_cast<const gles2::cmds::Uniform1uivImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLuint), 1, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLuint* v =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (v == NULL) {
    return error::kOutOfBounds;
  }
  glUniform1uiv(location, count, v);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform2f(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::Uniform2f& c =
      *static_cast<const gles2::cmds::Uniform2f*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLfloat x = static_cast<GLfloat>(c.x);
  GLfloat y = static_cast<GLfloat>(c.y);
  GLfloat temp[2] = {
      x, y,
  };
  DoUniform2fv(location, 1, &temp[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform2fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::Uniform2fvImmediate& c =
      *static_cast<const gles2::cmds::Uniform2fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 2, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* v =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (v == NULL) {
    return error::kOutOfBounds;
  }
  DoUniform2fv(location, count, v);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform2i(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::Uniform2i& c =
      *static_cast<const gles2::cmds::Uniform2i*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLint x = static_cast<GLint>(c.x);
  GLint y = static_cast<GLint>(c.y);
  GLint temp[2] = {
      x, y,
  };
  DoUniform2iv(location, 1, &temp[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform2ivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::Uniform2ivImmediate& c =
      *static_cast<const gles2::cmds::Uniform2ivImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLint), 2, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLint* v =
      GetImmediateDataAs<const GLint*>(c, data_size, immediate_data_size);
  if (v == NULL) {
    return error::kOutOfBounds;
  }
  DoUniform2iv(location, count, v);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform2ui(uint32_t immediate_data_size,
                                                const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::Uniform2ui& c =
      *static_cast<const gles2::cmds::Uniform2ui*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLuint x = static_cast<GLuint>(c.x);
  GLuint y = static_cast<GLuint>(c.y);
  GLuint temp[2] = {
      x, y,
  };
  glUniform2uiv(location, 1, &temp[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform2uivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::Uniform2uivImmediate& c =
      *static_cast<const gles2::cmds::Uniform2uivImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLuint), 2, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLuint* v =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (v == NULL) {
    return error::kOutOfBounds;
  }
  glUniform2uiv(location, count, v);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform3f(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::Uniform3f& c =
      *static_cast<const gles2::cmds::Uniform3f*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLfloat x = static_cast<GLfloat>(c.x);
  GLfloat y = static_cast<GLfloat>(c.y);
  GLfloat z = static_cast<GLfloat>(c.z);
  GLfloat temp[3] = {
      x, y, z,
  };
  DoUniform3fv(location, 1, &temp[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform3fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::Uniform3fvImmediate& c =
      *static_cast<const gles2::cmds::Uniform3fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 3, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* v =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (v == NULL) {
    return error::kOutOfBounds;
  }
  DoUniform3fv(location, count, v);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform3i(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::Uniform3i& c =
      *static_cast<const gles2::cmds::Uniform3i*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLint x = static_cast<GLint>(c.x);
  GLint y = static_cast<GLint>(c.y);
  GLint z = static_cast<GLint>(c.z);
  GLint temp[3] = {
      x, y, z,
  };
  DoUniform3iv(location, 1, &temp[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform3ivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::Uniform3ivImmediate& c =
      *static_cast<const gles2::cmds::Uniform3ivImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLint), 3, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLint* v =
      GetImmediateDataAs<const GLint*>(c, data_size, immediate_data_size);
  if (v == NULL) {
    return error::kOutOfBounds;
  }
  DoUniform3iv(location, count, v);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform3ui(uint32_t immediate_data_size,
                                                const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::Uniform3ui& c =
      *static_cast<const gles2::cmds::Uniform3ui*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLuint x = static_cast<GLuint>(c.x);
  GLuint y = static_cast<GLuint>(c.y);
  GLuint z = static_cast<GLuint>(c.z);
  GLuint temp[3] = {
      x, y, z,
  };
  glUniform3uiv(location, 1, &temp[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform3uivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::Uniform3uivImmediate& c =
      *static_cast<const gles2::cmds::Uniform3uivImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLuint), 3, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLuint* v =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (v == NULL) {
    return error::kOutOfBounds;
  }
  glUniform3uiv(location, count, v);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform4f(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::Uniform4f& c =
      *static_cast<const gles2::cmds::Uniform4f*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLfloat x = static_cast<GLfloat>(c.x);
  GLfloat y = static_cast<GLfloat>(c.y);
  GLfloat z = static_cast<GLfloat>(c.z);
  GLfloat w = static_cast<GLfloat>(c.w);
  GLfloat temp[4] = {
      x, y, z, w,
  };
  DoUniform4fv(location, 1, &temp[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform4fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::Uniform4fvImmediate& c =
      *static_cast<const gles2::cmds::Uniform4fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 4, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* v =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (v == NULL) {
    return error::kOutOfBounds;
  }
  DoUniform4fv(location, count, v);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform4i(uint32_t immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::Uniform4i& c =
      *static_cast<const gles2::cmds::Uniform4i*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLint x = static_cast<GLint>(c.x);
  GLint y = static_cast<GLint>(c.y);
  GLint z = static_cast<GLint>(c.z);
  GLint w = static_cast<GLint>(c.w);
  GLint temp[4] = {
      x, y, z, w,
  };
  DoUniform4iv(location, 1, &temp[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform4ivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::Uniform4ivImmediate& c =
      *static_cast<const gles2::cmds::Uniform4ivImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLint), 4, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLint* v =
      GetImmediateDataAs<const GLint*>(c, data_size, immediate_data_size);
  if (v == NULL) {
    return error::kOutOfBounds;
  }
  DoUniform4iv(location, count, v);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform4ui(uint32_t immediate_data_size,
                                                const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::Uniform4ui& c =
      *static_cast<const gles2::cmds::Uniform4ui*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLuint x = static_cast<GLuint>(c.x);
  GLuint y = static_cast<GLuint>(c.y);
  GLuint z = static_cast<GLuint>(c.z);
  GLuint w = static_cast<GLuint>(c.w);
  GLuint temp[4] = {
      x, y, z, w,
  };
  glUniform4uiv(location, 1, &temp[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniform4uivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::Uniform4uivImmediate& c =
      *static_cast<const gles2::cmds::Uniform4uivImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLuint), 4, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLuint* v =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (v == NULL) {
    return error::kOutOfBounds;
  }
  glUniform4uiv(location, count, v);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniformMatrix2fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::UniformMatrix2fvImmediate& c =
      *static_cast<const gles2::cmds::UniformMatrix2fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  GLboolean transpose = static_cast<GLboolean>(c.transpose);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 4, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* value =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (value == NULL) {
    return error::kOutOfBounds;
  }
  DoUniformMatrix2fv(location, count, transpose, value);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniformMatrix2x3fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::UniformMatrix2x3fvImmediate& c =
      *static_cast<const gles2::cmds::UniformMatrix2x3fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  GLboolean transpose = static_cast<GLboolean>(c.transpose);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 6, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* value =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (value == NULL) {
    return error::kOutOfBounds;
  }
  glUniformMatrix2x3fv(location, count, transpose, value);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniformMatrix2x4fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::UniformMatrix2x4fvImmediate& c =
      *static_cast<const gles2::cmds::UniformMatrix2x4fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  GLboolean transpose = static_cast<GLboolean>(c.transpose);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 8, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* value =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (value == NULL) {
    return error::kOutOfBounds;
  }
  glUniformMatrix2x4fv(location, count, transpose, value);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniformMatrix3fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::UniformMatrix3fvImmediate& c =
      *static_cast<const gles2::cmds::UniformMatrix3fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  GLboolean transpose = static_cast<GLboolean>(c.transpose);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 9, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* value =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (value == NULL) {
    return error::kOutOfBounds;
  }
  DoUniformMatrix3fv(location, count, transpose, value);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniformMatrix3x2fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::UniformMatrix3x2fvImmediate& c =
      *static_cast<const gles2::cmds::UniformMatrix3x2fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  GLboolean transpose = static_cast<GLboolean>(c.transpose);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 6, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* value =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (value == NULL) {
    return error::kOutOfBounds;
  }
  glUniformMatrix3x2fv(location, count, transpose, value);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniformMatrix3x4fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::UniformMatrix3x4fvImmediate& c =
      *static_cast<const gles2::cmds::UniformMatrix3x4fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  GLboolean transpose = static_cast<GLboolean>(c.transpose);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 12, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* value =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (value == NULL) {
    return error::kOutOfBounds;
  }
  glUniformMatrix3x4fv(location, count, transpose, value);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniformMatrix4fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::UniformMatrix4fvImmediate& c =
      *static_cast<const gles2::cmds::UniformMatrix4fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  GLboolean transpose = static_cast<GLboolean>(c.transpose);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 16, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* value =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (value == NULL) {
    return error::kOutOfBounds;
  }
  DoUniformMatrix4fv(location, count, transpose, value);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniformMatrix4x2fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::UniformMatrix4x2fvImmediate& c =
      *static_cast<const gles2::cmds::UniformMatrix4x2fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  GLboolean transpose = static_cast<GLboolean>(c.transpose);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 8, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* value =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (value == NULL) {
    return error::kOutOfBounds;
  }
  glUniformMatrix4x2fv(location, count, transpose, value);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniformMatrix4x3fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::UniformMatrix4x3fvImmediate& c =
      *static_cast<const gles2::cmds::UniformMatrix4x3fvImmediate*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLsizei count = static_cast<GLsizei>(c.count);
  GLboolean transpose = static_cast<GLboolean>(c.transpose);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLfloat), 12, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* value =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (value == NULL) {
    return error::kOutOfBounds;
  }
  glUniformMatrix4x3fv(location, count, transpose, value);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUseProgram(uint32_t immediate_data_size,
                                                const void* cmd_data) {
  const gles2::cmds::UseProgram& c =
      *static_cast<const gles2::cmds::UseProgram*>(cmd_data);
  (void)c;
  GLuint program = c.program;
  DoUseProgram(program);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleValidateProgram(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::ValidateProgram& c =
      *static_cast<const gles2::cmds::ValidateProgram*>(cmd_data);
  (void)c;
  GLuint program = c.program;
  DoValidateProgram(program);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttrib1f(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::VertexAttrib1f& c =
      *static_cast<const gles2::cmds::VertexAttrib1f*>(cmd_data);
  (void)c;
  GLuint indx = static_cast<GLuint>(c.indx);
  GLfloat x = static_cast<GLfloat>(c.x);
  DoVertexAttrib1f(indx, x);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttrib1fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::VertexAttrib1fvImmediate& c =
      *static_cast<const gles2::cmds::VertexAttrib1fvImmediate*>(cmd_data);
  (void)c;
  GLuint indx = static_cast<GLuint>(c.indx);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLfloat), 1, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* values =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (values == NULL) {
    return error::kOutOfBounds;
  }
  DoVertexAttrib1fv(indx, values);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttrib2f(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::VertexAttrib2f& c =
      *static_cast<const gles2::cmds::VertexAttrib2f*>(cmd_data);
  (void)c;
  GLuint indx = static_cast<GLuint>(c.indx);
  GLfloat x = static_cast<GLfloat>(c.x);
  GLfloat y = static_cast<GLfloat>(c.y);
  DoVertexAttrib2f(indx, x, y);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttrib2fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::VertexAttrib2fvImmediate& c =
      *static_cast<const gles2::cmds::VertexAttrib2fvImmediate*>(cmd_data);
  (void)c;
  GLuint indx = static_cast<GLuint>(c.indx);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLfloat), 2, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* values =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (values == NULL) {
    return error::kOutOfBounds;
  }
  DoVertexAttrib2fv(indx, values);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttrib3f(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::VertexAttrib3f& c =
      *static_cast<const gles2::cmds::VertexAttrib3f*>(cmd_data);
  (void)c;
  GLuint indx = static_cast<GLuint>(c.indx);
  GLfloat x = static_cast<GLfloat>(c.x);
  GLfloat y = static_cast<GLfloat>(c.y);
  GLfloat z = static_cast<GLfloat>(c.z);
  DoVertexAttrib3f(indx, x, y, z);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttrib3fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::VertexAttrib3fvImmediate& c =
      *static_cast<const gles2::cmds::VertexAttrib3fvImmediate*>(cmd_data);
  (void)c;
  GLuint indx = static_cast<GLuint>(c.indx);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLfloat), 3, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* values =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (values == NULL) {
    return error::kOutOfBounds;
  }
  DoVertexAttrib3fv(indx, values);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttrib4f(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::VertexAttrib4f& c =
      *static_cast<const gles2::cmds::VertexAttrib4f*>(cmd_data);
  (void)c;
  GLuint indx = static_cast<GLuint>(c.indx);
  GLfloat x = static_cast<GLfloat>(c.x);
  GLfloat y = static_cast<GLfloat>(c.y);
  GLfloat z = static_cast<GLfloat>(c.z);
  GLfloat w = static_cast<GLfloat>(c.w);
  DoVertexAttrib4f(indx, x, y, z, w);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttrib4fvImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::VertexAttrib4fvImmediate& c =
      *static_cast<const gles2::cmds::VertexAttrib4fvImmediate*>(cmd_data);
  (void)c;
  GLuint indx = static_cast<GLuint>(c.indx);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLfloat), 4, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* values =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (values == NULL) {
    return error::kOutOfBounds;
  }
  DoVertexAttrib4fv(indx, values);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttribI4i(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::VertexAttribI4i& c =
      *static_cast<const gles2::cmds::VertexAttribI4i*>(cmd_data);
  (void)c;
  GLuint indx = static_cast<GLuint>(c.indx);
  GLint x = static_cast<GLint>(c.x);
  GLint y = static_cast<GLint>(c.y);
  GLint z = static_cast<GLint>(c.z);
  GLint w = static_cast<GLint>(c.w);
  glVertexAttribI4i(indx, x, y, z, w);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttribI4ivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::VertexAttribI4ivImmediate& c =
      *static_cast<const gles2::cmds::VertexAttribI4ivImmediate*>(cmd_data);
  (void)c;
  GLuint indx = static_cast<GLuint>(c.indx);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLint), 4, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLint* values =
      GetImmediateDataAs<const GLint*>(c, data_size, immediate_data_size);
  if (values == NULL) {
    return error::kOutOfBounds;
  }
  glVertexAttribI4iv(indx, values);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttribI4ui(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::VertexAttribI4ui& c =
      *static_cast<const gles2::cmds::VertexAttribI4ui*>(cmd_data);
  (void)c;
  GLuint indx = static_cast<GLuint>(c.indx);
  GLuint x = static_cast<GLuint>(c.x);
  GLuint y = static_cast<GLuint>(c.y);
  GLuint z = static_cast<GLuint>(c.z);
  GLuint w = static_cast<GLuint>(c.w);
  glVertexAttribI4ui(indx, x, y, z, w);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttribI4uivImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::VertexAttribI4uivImmediate& c =
      *static_cast<const gles2::cmds::VertexAttribI4uivImmediate*>(cmd_data);
  (void)c;
  GLuint indx = static_cast<GLuint>(c.indx);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLuint), 4, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLuint* values =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (values == NULL) {
    return error::kOutOfBounds;
  }
  glVertexAttribI4uiv(indx, values);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleViewport(uint32_t immediate_data_size,
                                              const void* cmd_data) {
  const gles2::cmds::Viewport& c =
      *static_cast<const gles2::cmds::Viewport*>(cmd_data);
  (void)c;
  GLint x = static_cast<GLint>(c.x);
  GLint y = static_cast<GLint>(c.y);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  if (width < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glViewport", "width < 0");
    return error::kNoError;
  }
  if (height < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glViewport", "height < 0");
    return error::kNoError;
  }
  DoViewport(x, y, width, height);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBlitFramebufferCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::BlitFramebufferCHROMIUM& c =
      *static_cast<const gles2::cmds::BlitFramebufferCHROMIUM*>(cmd_data);
  (void)c;
  if (!features().chromium_framebuffer_multisample) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glBlitFramebufferCHROMIUM",
                       "function not available");
    return error::kNoError;
  }

  error::Error error;
  error = WillAccessBoundFramebufferForDraw();
  if (error != error::kNoError)
    return error;
  error = WillAccessBoundFramebufferForRead();
  if (error != error::kNoError)
    return error;
  GLint srcX0 = static_cast<GLint>(c.srcX0);
  GLint srcY0 = static_cast<GLint>(c.srcY0);
  GLint srcX1 = static_cast<GLint>(c.srcX1);
  GLint srcY1 = static_cast<GLint>(c.srcY1);
  GLint dstX0 = static_cast<GLint>(c.dstX0);
  GLint dstY0 = static_cast<GLint>(c.dstY0);
  GLint dstX1 = static_cast<GLint>(c.dstX1);
  GLint dstY1 = static_cast<GLint>(c.dstY1);
  GLbitfield mask = static_cast<GLbitfield>(c.mask);
  GLenum filter = static_cast<GLenum>(c.filter);
  if (!validators_->blit_filter.IsValid(filter)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBlitFramebufferCHROMIUM", filter,
                                    "filter");
    return error::kNoError;
  }
  DoBlitFramebufferCHROMIUM(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1,
                            dstY1, mask, filter);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleRenderbufferStorageMultisampleCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::RenderbufferStorageMultisampleCHROMIUM& c =
      *static_cast<const gles2::cmds::RenderbufferStorageMultisampleCHROMIUM*>(
          cmd_data);
  (void)c;
  if (!features().chromium_framebuffer_multisample) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                       "glRenderbufferStorageMultisampleCHROMIUM",
                       "function not available");
    return error::kNoError;
  }

  GLenum target = static_cast<GLenum>(c.target);
  GLsizei samples = static_cast<GLsizei>(c.samples);
  GLenum internalformat = static_cast<GLenum>(c.internalformat);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  if (!validators_->render_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glRenderbufferStorageMultisampleCHROMIUM",
                                    target, "target");
    return error::kNoError;
  }
  if (samples < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE,
                       "glRenderbufferStorageMultisampleCHROMIUM",
                       "samples < 0");
    return error::kNoError;
  }
  if (!validators_->render_buffer_format.IsValid(internalformat)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glRenderbufferStorageMultisampleCHROMIUM",
                                    internalformat, "internalformat");
    return error::kNoError;
  }
  if (width < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE,
                       "glRenderbufferStorageMultisampleCHROMIUM", "width < 0");
    return error::kNoError;
  }
  if (height < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE,
                       "glRenderbufferStorageMultisampleCHROMIUM",
                       "height < 0");
    return error::kNoError;
  }
  DoRenderbufferStorageMultisampleCHROMIUM(target, samples, internalformat,
                                           width, height);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleRenderbufferStorageMultisampleEXT(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::RenderbufferStorageMultisampleEXT& c =
      *static_cast<const gles2::cmds::RenderbufferStorageMultisampleEXT*>(
          cmd_data);
  (void)c;
  if (!features().multisampled_render_to_texture) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                       "glRenderbufferStorageMultisampleEXT",
                       "function not available");
    return error::kNoError;
  }

  GLenum target = static_cast<GLenum>(c.target);
  GLsizei samples = static_cast<GLsizei>(c.samples);
  GLenum internalformat = static_cast<GLenum>(c.internalformat);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  if (!validators_->render_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glRenderbufferStorageMultisampleEXT",
                                    target, "target");
    return error::kNoError;
  }
  if (samples < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glRenderbufferStorageMultisampleEXT",
                       "samples < 0");
    return error::kNoError;
  }
  if (!validators_->render_buffer_format.IsValid(internalformat)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glRenderbufferStorageMultisampleEXT",
                                    internalformat, "internalformat");
    return error::kNoError;
  }
  if (width < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glRenderbufferStorageMultisampleEXT",
                       "width < 0");
    return error::kNoError;
  }
  if (height < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glRenderbufferStorageMultisampleEXT",
                       "height < 0");
    return error::kNoError;
  }
  DoRenderbufferStorageMultisampleEXT(target, samples, internalformat, width,
                                      height);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleFramebufferTexture2DMultisampleEXT(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::FramebufferTexture2DMultisampleEXT& c =
      *static_cast<const gles2::cmds::FramebufferTexture2DMultisampleEXT*>(
          cmd_data);
  (void)c;
  if (!features().multisampled_render_to_texture) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                       "glFramebufferTexture2DMultisampleEXT",
                       "function not available");
    return error::kNoError;
  }

  GLenum target = static_cast<GLenum>(c.target);
  GLenum attachment = static_cast<GLenum>(c.attachment);
  GLenum textarget = static_cast<GLenum>(c.textarget);
  GLuint texture = c.texture;
  GLint level = static_cast<GLint>(c.level);
  GLsizei samples = static_cast<GLsizei>(c.samples);
  if (!validators_->frame_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glFramebufferTexture2DMultisampleEXT",
                                    target, "target");
    return error::kNoError;
  }
  if (!validators_->attachment.IsValid(attachment)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glFramebufferTexture2DMultisampleEXT",
                                    attachment, "attachment");
    return error::kNoError;
  }
  if (!validators_->texture_target.IsValid(textarget)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glFramebufferTexture2DMultisampleEXT",
                                    textarget, "textarget");
    return error::kNoError;
  }
  if (samples < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glFramebufferTexture2DMultisampleEXT",
                       "samples < 0");
    return error::kNoError;
  }
  DoFramebufferTexture2DMultisample(target, attachment, textarget, texture,
                                    level, samples);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleTexStorage2DEXT(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::TexStorage2DEXT& c =
      *static_cast<const gles2::cmds::TexStorage2DEXT*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLsizei levels = static_cast<GLsizei>(c.levels);
  GLenum internalFormat = static_cast<GLenum>(c.internalFormat);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  if (!validators_->texture_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glTexStorage2DEXT", target, "target");
    return error::kNoError;
  }
  if (levels < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glTexStorage2DEXT", "levels < 0");
    return error::kNoError;
  }
  if (!validators_->texture_internal_format_storage.IsValid(internalFormat)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glTexStorage2DEXT", internalFormat,
                                    "internalFormat");
    return error::kNoError;
  }
  if (width < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glTexStorage2DEXT", "width < 0");
    return error::kNoError;
  }
  if (height < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glTexStorage2DEXT", "height < 0");
    return error::kNoError;
  }
  DoTexStorage2DEXT(target, levels, internalFormat, width, height);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGenQueriesEXTImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GenQueriesEXTImmediate& c =
      *static_cast<const gles2::cmds::GenQueriesEXTImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  GLuint* queries =
      GetImmediateDataAs<GLuint*>(c, data_size, immediate_data_size);
  if (queries == NULL) {
    return error::kOutOfBounds;
  }
  if (!GenQueriesEXTHelper(n, queries)) {
    return error::kInvalidArguments;
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDeleteQueriesEXTImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::DeleteQueriesEXTImmediate& c =
      *static_cast<const gles2::cmds::DeleteQueriesEXTImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  const GLuint* queries =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (queries == NULL) {
    return error::kOutOfBounds;
  }
  DeleteQueriesEXTHelper(n, queries);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBeginTransformFeedback(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::BeginTransformFeedback& c =
      *static_cast<const gles2::cmds::BeginTransformFeedback*>(cmd_data);
  (void)c;
  GLenum primitivemode = static_cast<GLenum>(c.primitivemode);
  glBeginTransformFeedback(primitivemode);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleEndTransformFeedback(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::EndTransformFeedback& c =
      *static_cast<const gles2::cmds::EndTransformFeedback*>(cmd_data);
  (void)c;
  glEndTransformFeedback();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleInsertEventMarkerEXT(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::InsertEventMarkerEXT& c =
      *static_cast<const gles2::cmds::InsertEventMarkerEXT*>(cmd_data);
  (void)c;

  GLuint bucket_id = static_cast<GLuint>(c.bucket_id);
  Bucket* bucket = GetBucket(bucket_id);
  if (!bucket || bucket->size() == 0) {
    return error::kInvalidArguments;
  }
  std::string str;
  if (!bucket->GetAsString(&str)) {
    return error::kInvalidArguments;
  }
  DoInsertEventMarkerEXT(0, str.c_str());
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandlePushGroupMarkerEXT(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::PushGroupMarkerEXT& c =
      *static_cast<const gles2::cmds::PushGroupMarkerEXT*>(cmd_data);
  (void)c;

  GLuint bucket_id = static_cast<GLuint>(c.bucket_id);
  Bucket* bucket = GetBucket(bucket_id);
  if (!bucket || bucket->size() == 0) {
    return error::kInvalidArguments;
  }
  std::string str;
  if (!bucket->GetAsString(&str)) {
    return error::kInvalidArguments;
  }
  DoPushGroupMarkerEXT(0, str.c_str());
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandlePopGroupMarkerEXT(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::PopGroupMarkerEXT& c =
      *static_cast<const gles2::cmds::PopGroupMarkerEXT*>(cmd_data);
  (void)c;
  DoPopGroupMarkerEXT();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGenVertexArraysOESImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GenVertexArraysOESImmediate& c =
      *static_cast<const gles2::cmds::GenVertexArraysOESImmediate*>(cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  GLuint* arrays =
      GetImmediateDataAs<GLuint*>(c, data_size, immediate_data_size);
  if (arrays == NULL) {
    return error::kOutOfBounds;
  }
  if (!GenVertexArraysOESHelper(n, arrays)) {
    return error::kInvalidArguments;
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDeleteVertexArraysOESImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::DeleteVertexArraysOESImmediate& c =
      *static_cast<const gles2::cmds::DeleteVertexArraysOESImmediate*>(
          cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  const GLuint* arrays =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (arrays == NULL) {
    return error::kOutOfBounds;
  }
  DeleteVertexArraysOESHelper(n, arrays);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleIsVertexArrayOES(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::IsVertexArrayOES& c =
      *static_cast<const gles2::cmds::IsVertexArrayOES*>(cmd_data);
  (void)c;
  GLuint array = c.array;
  typedef cmds::IsVertexArrayOES::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  *result_dst = DoIsVertexArrayOES(array);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBindVertexArrayOES(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::BindVertexArrayOES& c =
      *static_cast<const gles2::cmds::BindVertexArrayOES*>(cmd_data);
  (void)c;
  GLuint array = c.array;
  DoBindVertexArrayOES(array);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleSwapBuffers(uint32_t immediate_data_size,
                                                 const void* cmd_data) {
  const gles2::cmds::SwapBuffers& c =
      *static_cast<const gles2::cmds::SwapBuffers*>(cmd_data);
  (void)c;
  DoSwapBuffers();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetMaxValueInBufferCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetMaxValueInBufferCHROMIUM& c =
      *static_cast<const gles2::cmds::GetMaxValueInBufferCHROMIUM*>(cmd_data);
  (void)c;
  GLuint buffer_id = c.buffer_id;
  GLsizei count = static_cast<GLsizei>(c.count);
  GLenum type = static_cast<GLenum>(c.type);
  GLuint offset = static_cast<GLuint>(c.offset);
  typedef cmds::GetMaxValueInBufferCHROMIUM::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  if (count < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glGetMaxValueInBufferCHROMIUM",
                       "count < 0");
    return error::kNoError;
  }
  if (!validators_->get_max_index_type.IsValid(type)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetMaxValueInBufferCHROMIUM", type,
                                    "type");
    return error::kNoError;
  }
  *result_dst = DoGetMaxValueInBufferCHROMIUM(buffer_id, count, type, offset);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleTexImageIOSurface2DCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::TexImageIOSurface2DCHROMIUM& c =
      *static_cast<const gles2::cmds::TexImageIOSurface2DCHROMIUM*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLuint ioSurfaceId = static_cast<GLuint>(c.ioSurfaceId);
  GLuint plane = static_cast<GLuint>(c.plane);
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glTexImageIOSurface2DCHROMIUM", target,
                                    "target");
    return error::kNoError;
  }
  if (width < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glTexImageIOSurface2DCHROMIUM",
                       "width < 0");
    return error::kNoError;
  }
  if (height < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glTexImageIOSurface2DCHROMIUM",
                       "height < 0");
    return error::kNoError;
  }
  DoTexImageIOSurface2DCHROMIUM(target, width, height, ioSurfaceId, plane);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCopyTextureCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::CopyTextureCHROMIUM& c =
      *static_cast<const gles2::cmds::CopyTextureCHROMIUM*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum source_id = static_cast<GLenum>(c.source_id);
  GLenum dest_id = static_cast<GLenum>(c.dest_id);
  GLint internalformat = static_cast<GLint>(c.internalformat);
  GLenum dest_type = static_cast<GLenum>(c.dest_type);
  if (!validators_->texture_internal_format.IsValid(internalformat)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glCopyTextureCHROMIUM",
                       "internalformat GL_INVALID_VALUE");
    return error::kNoError;
  }
  if (!validators_->pixel_type.IsValid(dest_type)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glCopyTextureCHROMIUM", dest_type,
                                    "dest_type");
    return error::kNoError;
  }
  DoCopyTextureCHROMIUM(target, source_id, dest_id, internalformat, dest_type);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCopySubTextureCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::CopySubTextureCHROMIUM& c =
      *static_cast<const gles2::cmds::CopySubTextureCHROMIUM*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum source_id = static_cast<GLenum>(c.source_id);
  GLenum dest_id = static_cast<GLenum>(c.dest_id);
  GLint xoffset = static_cast<GLint>(c.xoffset);
  GLint yoffset = static_cast<GLint>(c.yoffset);
  DoCopySubTextureCHROMIUM(target, source_id, dest_id, xoffset, yoffset);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleProduceTextureCHROMIUMImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::ProduceTextureCHROMIUMImmediate& c =
      *static_cast<const gles2::cmds::ProduceTextureCHROMIUMImmediate*>(
          cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLbyte), 64, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLbyte* mailbox =
      GetImmediateDataAs<const GLbyte*>(c, data_size, immediate_data_size);
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glProduceTextureCHROMIUM", target,
                                    "target");
    return error::kNoError;
  }
  if (mailbox == NULL) {
    return error::kOutOfBounds;
  }
  DoProduceTextureCHROMIUM(target, mailbox);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleProduceTextureDirectCHROMIUMImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::ProduceTextureDirectCHROMIUMImmediate& c =
      *static_cast<const gles2::cmds::ProduceTextureDirectCHROMIUMImmediate*>(
          cmd_data);
  (void)c;
  GLuint texture = c.texture;
  GLenum target = static_cast<GLenum>(c.target);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLbyte), 64, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLbyte* mailbox =
      GetImmediateDataAs<const GLbyte*>(c, data_size, immediate_data_size);
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glProduceTextureDirectCHROMIUM", target,
                                    "target");
    return error::kNoError;
  }
  if (mailbox == NULL) {
    return error::kOutOfBounds;
  }
  DoProduceTextureDirectCHROMIUM(texture, target, mailbox);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleConsumeTextureCHROMIUMImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::ConsumeTextureCHROMIUMImmediate& c =
      *static_cast<const gles2::cmds::ConsumeTextureCHROMIUMImmediate*>(
          cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLbyte), 64, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLbyte* mailbox =
      GetImmediateDataAs<const GLbyte*>(c, data_size, immediate_data_size);
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glConsumeTextureCHROMIUM", target,
                                    "target");
    return error::kNoError;
  }
  if (mailbox == NULL) {
    return error::kOutOfBounds;
  }
  DoConsumeTextureCHROMIUM(target, mailbox);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGenValuebuffersCHROMIUMImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GenValuebuffersCHROMIUMImmediate& c =
      *static_cast<const gles2::cmds::GenValuebuffersCHROMIUMImmediate*>(
          cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  GLuint* buffers =
      GetImmediateDataAs<GLuint*>(c, data_size, immediate_data_size);
  if (buffers == NULL) {
    return error::kOutOfBounds;
  }
  if (!GenValuebuffersCHROMIUMHelper(n, buffers)) {
    return error::kInvalidArguments;
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDeleteValuebuffersCHROMIUMImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::DeleteValuebuffersCHROMIUMImmediate& c =
      *static_cast<const gles2::cmds::DeleteValuebuffersCHROMIUMImmediate*>(
          cmd_data);
  (void)c;
  GLsizei n = static_cast<GLsizei>(c.n);
  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  const GLuint* valuebuffers =
      GetImmediateDataAs<const GLuint*>(c, data_size, immediate_data_size);
  if (valuebuffers == NULL) {
    return error::kOutOfBounds;
  }
  DeleteValuebuffersCHROMIUMHelper(n, valuebuffers);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleIsValuebufferCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::IsValuebufferCHROMIUM& c =
      *static_cast<const gles2::cmds::IsValuebufferCHROMIUM*>(cmd_data);
  (void)c;
  GLuint valuebuffer = c.valuebuffer;
  typedef cmds::IsValuebufferCHROMIUM::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  *result_dst = DoIsValuebufferCHROMIUM(valuebuffer);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBindValuebufferCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::BindValuebufferCHROMIUM& c =
      *static_cast<const gles2::cmds::BindValuebufferCHROMIUM*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLuint valuebuffer = c.valuebuffer;
  if (!validators_->value_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBindValuebufferCHROMIUM", target,
                                    "target");
    return error::kNoError;
  }
  DoBindValueBufferCHROMIUM(target, valuebuffer);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleSubscribeValueCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::SubscribeValueCHROMIUM& c =
      *static_cast<const gles2::cmds::SubscribeValueCHROMIUM*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLenum subscription = static_cast<GLenum>(c.subscription);
  if (!validators_->value_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glSubscribeValueCHROMIUM", target,
                                    "target");
    return error::kNoError;
  }
  if (!validators_->subscription_target.IsValid(subscription)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glSubscribeValueCHROMIUM", subscription,
                                    "subscription");
    return error::kNoError;
  }
  DoSubscribeValueCHROMIUM(target, subscription);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandlePopulateSubscribedValuesCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::PopulateSubscribedValuesCHROMIUM& c =
      *static_cast<const gles2::cmds::PopulateSubscribedValuesCHROMIUM*>(
          cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  if (!validators_->value_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glPopulateSubscribedValuesCHROMIUM",
                                    target, "target");
    return error::kNoError;
  }
  DoPopulateSubscribedValuesCHROMIUM(target);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniformValuebufferCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::UniformValuebufferCHROMIUM& c =
      *static_cast<const gles2::cmds::UniformValuebufferCHROMIUM*>(cmd_data);
  (void)c;
  GLint location = static_cast<GLint>(c.location);
  GLenum target = static_cast<GLenum>(c.target);
  GLenum subscription = static_cast<GLenum>(c.subscription);
  if (!validators_->value_buffer_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glUniformValuebufferCHROMIUM", target,
                                    "target");
    return error::kNoError;
  }
  if (!validators_->subscription_target.IsValid(subscription)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glUniformValuebufferCHROMIUM",
                                    subscription, "subscription");
    return error::kNoError;
  }
  DoUniformValueBufferCHROMIUM(location, target, subscription);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBindTexImage2DCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::BindTexImage2DCHROMIUM& c =
      *static_cast<const gles2::cmds::BindTexImage2DCHROMIUM*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLint imageId = static_cast<GLint>(c.imageId);
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glBindTexImage2DCHROMIUM", target,
                                    "target");
    return error::kNoError;
  }
  DoBindTexImage2DCHROMIUM(target, imageId);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleReleaseTexImage2DCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::ReleaseTexImage2DCHROMIUM& c =
      *static_cast<const gles2::cmds::ReleaseTexImage2DCHROMIUM*>(cmd_data);
  (void)c;
  GLenum target = static_cast<GLenum>(c.target);
  GLint imageId = static_cast<GLint>(c.imageId);
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glReleaseTexImage2DCHROMIUM", target,
                                    "target");
    return error::kNoError;
  }
  DoReleaseTexImage2DCHROMIUM(target, imageId);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleTraceEndCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::TraceEndCHROMIUM& c =
      *static_cast<const gles2::cmds::TraceEndCHROMIUM*>(cmd_data);
  (void)c;
  DoTraceEndCHROMIUM();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDiscardFramebufferEXTImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::DiscardFramebufferEXTImmediate& c =
      *static_cast<const gles2::cmds::DiscardFramebufferEXTImmediate*>(
          cmd_data);
  (void)c;
  if (!features().ext_discard_framebuffer) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glDiscardFramebufferEXT",
                       "function not available");
    return error::kNoError;
  }

  GLenum target = static_cast<GLenum>(c.target);
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLenum), 1, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLenum* attachments =
      GetImmediateDataAs<const GLenum*>(c, data_size, immediate_data_size);
  if (count < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glDiscardFramebufferEXT",
                       "count < 0");
    return error::kNoError;
  }
  if (attachments == NULL) {
    return error::kOutOfBounds;
  }
  DoDiscardFramebufferEXT(target, count, attachments);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleLoseContextCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::LoseContextCHROMIUM& c =
      *static_cast<const gles2::cmds::LoseContextCHROMIUM*>(cmd_data);
  (void)c;
  GLenum current = static_cast<GLenum>(c.current);
  GLenum other = static_cast<GLenum>(c.other);
  if (!validators_->reset_status.IsValid(current)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glLoseContextCHROMIUM", current,
                                    "current");
    return error::kNoError;
  }
  if (!validators_->reset_status.IsValid(other)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glLoseContextCHROMIUM", other, "other");
    return error::kNoError;
  }
  DoLoseContextCHROMIUM(current, other);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDrawBuffersEXTImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::DrawBuffersEXTImmediate& c =
      *static_cast<const gles2::cmds::DrawBuffersEXTImmediate*>(cmd_data);
  (void)c;
  GLsizei count = static_cast<GLsizei>(c.count);
  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(GLenum), 1, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLenum* bufs =
      GetImmediateDataAs<const GLenum*>(c, data_size, immediate_data_size);
  if (count < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glDrawBuffersEXT", "count < 0");
    return error::kNoError;
  }
  if (bufs == NULL) {
    return error::kOutOfBounds;
  }
  DoDrawBuffersEXT(count, bufs);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleSwapInterval(uint32_t immediate_data_size,
                                                  const void* cmd_data) {
  const gles2::cmds::SwapInterval& c =
      *static_cast<const gles2::cmds::SwapInterval*>(cmd_data);
  (void)c;
  GLint interval = static_cast<GLint>(c.interval);
  DoSwapInterval(interval);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleMatrixLoadfCHROMIUMImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::MatrixLoadfCHROMIUMImmediate& c =
      *static_cast<const gles2::cmds::MatrixLoadfCHROMIUMImmediate*>(cmd_data);
  (void)c;
  if (!features().chromium_path_rendering) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glMatrixLoadfCHROMIUM",
                       "function not available");
    return error::kNoError;
  }

  GLenum matrixMode = static_cast<GLenum>(c.matrixMode);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLfloat), 16, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLfloat* m =
      GetImmediateDataAs<const GLfloat*>(c, data_size, immediate_data_size);
  if (!validators_->matrix_mode.IsValid(matrixMode)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glMatrixLoadfCHROMIUM", matrixMode,
                                    "matrixMode");
    return error::kNoError;
  }
  if (m == NULL) {
    return error::kOutOfBounds;
  }
  DoMatrixLoadfCHROMIUM(matrixMode, m);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleMatrixLoadIdentityCHROMIUM(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::MatrixLoadIdentityCHROMIUM& c =
      *static_cast<const gles2::cmds::MatrixLoadIdentityCHROMIUM*>(cmd_data);
  (void)c;
  if (!features().chromium_path_rendering) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glMatrixLoadIdentityCHROMIUM",
                       "function not available");
    return error::kNoError;
  }

  GLenum matrixMode = static_cast<GLenum>(c.matrixMode);
  if (!validators_->matrix_mode.IsValid(matrixMode)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glMatrixLoadIdentityCHROMIUM", matrixMode,
                                    "matrixMode");
    return error::kNoError;
  }
  DoMatrixLoadIdentityCHROMIUM(matrixMode);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBlendBarrierKHR(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::BlendBarrierKHR& c =
      *static_cast<const gles2::cmds::BlendBarrierKHR*>(cmd_data);
  (void)c;
  if (!features().blend_equation_advanced) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glBlendBarrierKHR",
                       "function not available");
    return error::kNoError;
  }

  glBlendBarrierKHR();
  return error::kNoError;
}

bool GLES2DecoderImpl::SetCapabilityState(GLenum cap, bool enabled) {
  switch (cap) {
    case GL_BLEND:
      state_.enable_flags.blend = enabled;
      if (state_.enable_flags.cached_blend != enabled ||
          state_.ignore_cached_state) {
        state_.enable_flags.cached_blend = enabled;
        return true;
      }
      return false;
    case GL_CULL_FACE:
      state_.enable_flags.cull_face = enabled;
      if (state_.enable_flags.cached_cull_face != enabled ||
          state_.ignore_cached_state) {
        state_.enable_flags.cached_cull_face = enabled;
        return true;
      }
      return false;
    case GL_DEPTH_TEST:
      state_.enable_flags.depth_test = enabled;
      if (state_.enable_flags.cached_depth_test != enabled ||
          state_.ignore_cached_state) {
        framebuffer_state_.clear_state_dirty = true;
      }
      return false;
    case GL_DITHER:
      state_.enable_flags.dither = enabled;
      if (state_.enable_flags.cached_dither != enabled ||
          state_.ignore_cached_state) {
        state_.enable_flags.cached_dither = enabled;
        return true;
      }
      return false;
    case GL_POLYGON_OFFSET_FILL:
      state_.enable_flags.polygon_offset_fill = enabled;
      if (state_.enable_flags.cached_polygon_offset_fill != enabled ||
          state_.ignore_cached_state) {
        state_.enable_flags.cached_polygon_offset_fill = enabled;
        return true;
      }
      return false;
    case GL_SAMPLE_ALPHA_TO_COVERAGE:
      state_.enable_flags.sample_alpha_to_coverage = enabled;
      if (state_.enable_flags.cached_sample_alpha_to_coverage != enabled ||
          state_.ignore_cached_state) {
        state_.enable_flags.cached_sample_alpha_to_coverage = enabled;
        return true;
      }
      return false;
    case GL_SAMPLE_COVERAGE:
      state_.enable_flags.sample_coverage = enabled;
      if (state_.enable_flags.cached_sample_coverage != enabled ||
          state_.ignore_cached_state) {
        state_.enable_flags.cached_sample_coverage = enabled;
        return true;
      }
      return false;
    case GL_SCISSOR_TEST:
      state_.enable_flags.scissor_test = enabled;
      if (state_.enable_flags.cached_scissor_test != enabled ||
          state_.ignore_cached_state) {
        state_.enable_flags.cached_scissor_test = enabled;
        return true;
      }
      return false;
    case GL_STENCIL_TEST:
      state_.enable_flags.stencil_test = enabled;
      if (state_.enable_flags.cached_stencil_test != enabled ||
          state_.ignore_cached_state) {
        framebuffer_state_.clear_state_dirty = true;
      }
      return false;
    case GL_RASTERIZER_DISCARD:
      state_.enable_flags.rasterizer_discard = enabled;
      if (state_.enable_flags.cached_rasterizer_discard != enabled ||
          state_.ignore_cached_state) {
        state_.enable_flags.cached_rasterizer_discard = enabled;
        return true;
      }
      return false;
    case GL_PRIMITIVE_RESTART_FIXED_INDEX:
      state_.enable_flags.primitive_restart_fixed_index = enabled;
      if (state_.enable_flags.cached_primitive_restart_fixed_index != enabled ||
          state_.ignore_cached_state) {
        state_.enable_flags.cached_primitive_restart_fixed_index = enabled;
        return true;
      }
      return false;
    default:
      NOTREACHED();
      return false;
  }
}
#endif  // GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_AUTOGEN_H_
