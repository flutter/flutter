// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

// This file is included by gles2_trace_implementation.cc
#ifndef GPU_COMMAND_BUFFER_CLIENT_GLES2_TRACE_IMPLEMENTATION_IMPL_AUTOGEN_H_
#define GPU_COMMAND_BUFFER_CLIENT_GLES2_TRACE_IMPLEMENTATION_IMPL_AUTOGEN_H_

void GLES2TraceImplementation::ActiveTexture(GLenum texture) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ActiveTexture");
  gl_->ActiveTexture(texture);
}

void GLES2TraceImplementation::AttachShader(GLuint program, GLuint shader) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::AttachShader");
  gl_->AttachShader(program, shader);
}

void GLES2TraceImplementation::BindAttribLocation(GLuint program,
                                                  GLuint index,
                                                  const char* name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BindAttribLocation");
  gl_->BindAttribLocation(program, index, name);
}

void GLES2TraceImplementation::BindBuffer(GLenum target, GLuint buffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BindBuffer");
  gl_->BindBuffer(target, buffer);
}

void GLES2TraceImplementation::BindBufferBase(GLenum target,
                                              GLuint index,
                                              GLuint buffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BindBufferBase");
  gl_->BindBufferBase(target, index, buffer);
}

void GLES2TraceImplementation::BindBufferRange(GLenum target,
                                               GLuint index,
                                               GLuint buffer,
                                               GLintptr offset,
                                               GLsizeiptr size) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BindBufferRange");
  gl_->BindBufferRange(target, index, buffer, offset, size);
}

void GLES2TraceImplementation::BindFramebuffer(GLenum target,
                                               GLuint framebuffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BindFramebuffer");
  gl_->BindFramebuffer(target, framebuffer);
}

void GLES2TraceImplementation::BindRenderbuffer(GLenum target,
                                                GLuint renderbuffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BindRenderbuffer");
  gl_->BindRenderbuffer(target, renderbuffer);
}

void GLES2TraceImplementation::BindSampler(GLuint unit, GLuint sampler) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BindSampler");
  gl_->BindSampler(unit, sampler);
}

void GLES2TraceImplementation::BindTexture(GLenum target, GLuint texture) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BindTexture");
  gl_->BindTexture(target, texture);
}

void GLES2TraceImplementation::BindTransformFeedback(GLenum target,
                                                     GLuint transformfeedback) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BindTransformFeedback");
  gl_->BindTransformFeedback(target, transformfeedback);
}

void GLES2TraceImplementation::BlendColor(GLclampf red,
                                          GLclampf green,
                                          GLclampf blue,
                                          GLclampf alpha) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BlendColor");
  gl_->BlendColor(red, green, blue, alpha);
}

void GLES2TraceImplementation::BlendEquation(GLenum mode) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BlendEquation");
  gl_->BlendEquation(mode);
}

void GLES2TraceImplementation::BlendEquationSeparate(GLenum modeRGB,
                                                     GLenum modeAlpha) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BlendEquationSeparate");
  gl_->BlendEquationSeparate(modeRGB, modeAlpha);
}

void GLES2TraceImplementation::BlendFunc(GLenum sfactor, GLenum dfactor) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BlendFunc");
  gl_->BlendFunc(sfactor, dfactor);
}

void GLES2TraceImplementation::BlendFuncSeparate(GLenum srcRGB,
                                                 GLenum dstRGB,
                                                 GLenum srcAlpha,
                                                 GLenum dstAlpha) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BlendFuncSeparate");
  gl_->BlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
}

void GLES2TraceImplementation::BufferData(GLenum target,
                                          GLsizeiptr size,
                                          const void* data,
                                          GLenum usage) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BufferData");
  gl_->BufferData(target, size, data, usage);
}

void GLES2TraceImplementation::BufferSubData(GLenum target,
                                             GLintptr offset,
                                             GLsizeiptr size,
                                             const void* data) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BufferSubData");
  gl_->BufferSubData(target, offset, size, data);
}

GLenum GLES2TraceImplementation::CheckFramebufferStatus(GLenum target) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CheckFramebufferStatus");
  return gl_->CheckFramebufferStatus(target);
}

void GLES2TraceImplementation::Clear(GLbitfield mask) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Clear");
  gl_->Clear(mask);
}

void GLES2TraceImplementation::ClearBufferfi(GLenum buffer,
                                             GLint drawbuffers,
                                             GLfloat depth,
                                             GLint stencil) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ClearBufferfi");
  gl_->ClearBufferfi(buffer, drawbuffers, depth, stencil);
}

void GLES2TraceImplementation::ClearBufferfv(GLenum buffer,
                                             GLint drawbuffers,
                                             const GLfloat* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ClearBufferfv");
  gl_->ClearBufferfv(buffer, drawbuffers, value);
}

void GLES2TraceImplementation::ClearBufferiv(GLenum buffer,
                                             GLint drawbuffers,
                                             const GLint* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ClearBufferiv");
  gl_->ClearBufferiv(buffer, drawbuffers, value);
}

void GLES2TraceImplementation::ClearBufferuiv(GLenum buffer,
                                              GLint drawbuffers,
                                              const GLuint* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ClearBufferuiv");
  gl_->ClearBufferuiv(buffer, drawbuffers, value);
}

void GLES2TraceImplementation::ClearColor(GLclampf red,
                                          GLclampf green,
                                          GLclampf blue,
                                          GLclampf alpha) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ClearColor");
  gl_->ClearColor(red, green, blue, alpha);
}

void GLES2TraceImplementation::ClearDepthf(GLclampf depth) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ClearDepthf");
  gl_->ClearDepthf(depth);
}

void GLES2TraceImplementation::ClearStencil(GLint s) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ClearStencil");
  gl_->ClearStencil(s);
}

GLenum GLES2TraceImplementation::ClientWaitSync(GLsync sync,
                                                GLbitfield flags,
                                                GLuint64 timeout) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ClientWaitSync");
  return gl_->ClientWaitSync(sync, flags, timeout);
}

void GLES2TraceImplementation::ColorMask(GLboolean red,
                                         GLboolean green,
                                         GLboolean blue,
                                         GLboolean alpha) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ColorMask");
  gl_->ColorMask(red, green, blue, alpha);
}

void GLES2TraceImplementation::CompileShader(GLuint shader) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CompileShader");
  gl_->CompileShader(shader);
}

void GLES2TraceImplementation::CompressedTexImage2D(GLenum target,
                                                    GLint level,
                                                    GLenum internalformat,
                                                    GLsizei width,
                                                    GLsizei height,
                                                    GLint border,
                                                    GLsizei imageSize,
                                                    const void* data) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CompressedTexImage2D");
  gl_->CompressedTexImage2D(target, level, internalformat, width, height,
                            border, imageSize, data);
}

void GLES2TraceImplementation::CompressedTexSubImage2D(GLenum target,
                                                       GLint level,
                                                       GLint xoffset,
                                                       GLint yoffset,
                                                       GLsizei width,
                                                       GLsizei height,
                                                       GLenum format,
                                                       GLsizei imageSize,
                                                       const void* data) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CompressedTexSubImage2D");
  gl_->CompressedTexSubImage2D(target, level, xoffset, yoffset, width, height,
                               format, imageSize, data);
}

void GLES2TraceImplementation::CopyBufferSubData(GLenum readtarget,
                                                 GLenum writetarget,
                                                 GLintptr readoffset,
                                                 GLintptr writeoffset,
                                                 GLsizeiptr size) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CopyBufferSubData");
  gl_->CopyBufferSubData(readtarget, writetarget, readoffset, writeoffset,
                         size);
}

void GLES2TraceImplementation::CopyTexImage2D(GLenum target,
                                              GLint level,
                                              GLenum internalformat,
                                              GLint x,
                                              GLint y,
                                              GLsizei width,
                                              GLsizei height,
                                              GLint border) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CopyTexImage2D");
  gl_->CopyTexImage2D(target, level, internalformat, x, y, width, height,
                      border);
}

void GLES2TraceImplementation::CopyTexSubImage2D(GLenum target,
                                                 GLint level,
                                                 GLint xoffset,
                                                 GLint yoffset,
                                                 GLint x,
                                                 GLint y,
                                                 GLsizei width,
                                                 GLsizei height) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CopyTexSubImage2D");
  gl_->CopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
}

void GLES2TraceImplementation::CopyTexSubImage3D(GLenum target,
                                                 GLint level,
                                                 GLint xoffset,
                                                 GLint yoffset,
                                                 GLint zoffset,
                                                 GLint x,
                                                 GLint y,
                                                 GLsizei width,
                                                 GLsizei height) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CopyTexSubImage3D");
  gl_->CopyTexSubImage3D(target, level, xoffset, yoffset, zoffset, x, y, width,
                         height);
}

GLuint GLES2TraceImplementation::CreateProgram() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CreateProgram");
  return gl_->CreateProgram();
}

GLuint GLES2TraceImplementation::CreateShader(GLenum type) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CreateShader");
  return gl_->CreateShader(type);
}

void GLES2TraceImplementation::CullFace(GLenum mode) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CullFace");
  gl_->CullFace(mode);
}

void GLES2TraceImplementation::DeleteBuffers(GLsizei n, const GLuint* buffers) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DeleteBuffers");
  gl_->DeleteBuffers(n, buffers);
}

void GLES2TraceImplementation::DeleteFramebuffers(GLsizei n,
                                                  const GLuint* framebuffers) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DeleteFramebuffers");
  gl_->DeleteFramebuffers(n, framebuffers);
}

void GLES2TraceImplementation::DeleteProgram(GLuint program) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DeleteProgram");
  gl_->DeleteProgram(program);
}

void GLES2TraceImplementation::DeleteRenderbuffers(
    GLsizei n,
    const GLuint* renderbuffers) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DeleteRenderbuffers");
  gl_->DeleteRenderbuffers(n, renderbuffers);
}

void GLES2TraceImplementation::DeleteSamplers(GLsizei n,
                                              const GLuint* samplers) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DeleteSamplers");
  gl_->DeleteSamplers(n, samplers);
}

void GLES2TraceImplementation::DeleteSync(GLsync sync) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DeleteSync");
  gl_->DeleteSync(sync);
}

void GLES2TraceImplementation::DeleteShader(GLuint shader) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DeleteShader");
  gl_->DeleteShader(shader);
}

void GLES2TraceImplementation::DeleteTextures(GLsizei n,
                                              const GLuint* textures) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DeleteTextures");
  gl_->DeleteTextures(n, textures);
}

void GLES2TraceImplementation::DeleteTransformFeedbacks(GLsizei n,
                                                        const GLuint* ids) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DeleteTransformFeedbacks");
  gl_->DeleteTransformFeedbacks(n, ids);
}

void GLES2TraceImplementation::DepthFunc(GLenum func) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DepthFunc");
  gl_->DepthFunc(func);
}

void GLES2TraceImplementation::DepthMask(GLboolean flag) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DepthMask");
  gl_->DepthMask(flag);
}

void GLES2TraceImplementation::DepthRangef(GLclampf zNear, GLclampf zFar) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DepthRangef");
  gl_->DepthRangef(zNear, zFar);
}

void GLES2TraceImplementation::DetachShader(GLuint program, GLuint shader) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DetachShader");
  gl_->DetachShader(program, shader);
}

void GLES2TraceImplementation::Disable(GLenum cap) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Disable");
  gl_->Disable(cap);
}

void GLES2TraceImplementation::DisableVertexAttribArray(GLuint index) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DisableVertexAttribArray");
  gl_->DisableVertexAttribArray(index);
}

void GLES2TraceImplementation::DrawArrays(GLenum mode,
                                          GLint first,
                                          GLsizei count) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DrawArrays");
  gl_->DrawArrays(mode, first, count);
}

void GLES2TraceImplementation::DrawElements(GLenum mode,
                                            GLsizei count,
                                            GLenum type,
                                            const void* indices) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DrawElements");
  gl_->DrawElements(mode, count, type, indices);
}

void GLES2TraceImplementation::DrawRangeElements(GLenum mode,
                                                 GLuint start,
                                                 GLuint end,
                                                 GLsizei count,
                                                 GLenum type,
                                                 const void* indices) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DrawRangeElements");
  gl_->DrawRangeElements(mode, start, end, count, type, indices);
}

void GLES2TraceImplementation::Enable(GLenum cap) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Enable");
  gl_->Enable(cap);
}

void GLES2TraceImplementation::EnableVertexAttribArray(GLuint index) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::EnableVertexAttribArray");
  gl_->EnableVertexAttribArray(index);
}

GLsync GLES2TraceImplementation::FenceSync(GLenum condition, GLbitfield flags) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::FenceSync");
  return gl_->FenceSync(condition, flags);
}

void GLES2TraceImplementation::Finish() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Finish");
  gl_->Finish();
}

void GLES2TraceImplementation::Flush() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Flush");
  gl_->Flush();
}

void GLES2TraceImplementation::FramebufferRenderbuffer(
    GLenum target,
    GLenum attachment,
    GLenum renderbuffertarget,
    GLuint renderbuffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::FramebufferRenderbuffer");
  gl_->FramebufferRenderbuffer(target, attachment, renderbuffertarget,
                               renderbuffer);
}

void GLES2TraceImplementation::FramebufferTexture2D(GLenum target,
                                                    GLenum attachment,
                                                    GLenum textarget,
                                                    GLuint texture,
                                                    GLint level) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::FramebufferTexture2D");
  gl_->FramebufferTexture2D(target, attachment, textarget, texture, level);
}

void GLES2TraceImplementation::FramebufferTextureLayer(GLenum target,
                                                       GLenum attachment,
                                                       GLuint texture,
                                                       GLint level,
                                                       GLint layer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::FramebufferTextureLayer");
  gl_->FramebufferTextureLayer(target, attachment, texture, level, layer);
}

void GLES2TraceImplementation::FrontFace(GLenum mode) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::FrontFace");
  gl_->FrontFace(mode);
}

void GLES2TraceImplementation::GenBuffers(GLsizei n, GLuint* buffers) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GenBuffers");
  gl_->GenBuffers(n, buffers);
}

void GLES2TraceImplementation::GenerateMipmap(GLenum target) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GenerateMipmap");
  gl_->GenerateMipmap(target);
}

void GLES2TraceImplementation::GenFramebuffers(GLsizei n,
                                               GLuint* framebuffers) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GenFramebuffers");
  gl_->GenFramebuffers(n, framebuffers);
}

void GLES2TraceImplementation::GenRenderbuffers(GLsizei n,
                                                GLuint* renderbuffers) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GenRenderbuffers");
  gl_->GenRenderbuffers(n, renderbuffers);
}

void GLES2TraceImplementation::GenSamplers(GLsizei n, GLuint* samplers) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GenSamplers");
  gl_->GenSamplers(n, samplers);
}

void GLES2TraceImplementation::GenTextures(GLsizei n, GLuint* textures) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GenTextures");
  gl_->GenTextures(n, textures);
}

void GLES2TraceImplementation::GenTransformFeedbacks(GLsizei n, GLuint* ids) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GenTransformFeedbacks");
  gl_->GenTransformFeedbacks(n, ids);
}

void GLES2TraceImplementation::GetActiveAttrib(GLuint program,
                                               GLuint index,
                                               GLsizei bufsize,
                                               GLsizei* length,
                                               GLint* size,
                                               GLenum* type,
                                               char* name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetActiveAttrib");
  gl_->GetActiveAttrib(program, index, bufsize, length, size, type, name);
}

void GLES2TraceImplementation::GetActiveUniform(GLuint program,
                                                GLuint index,
                                                GLsizei bufsize,
                                                GLsizei* length,
                                                GLint* size,
                                                GLenum* type,
                                                char* name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetActiveUniform");
  gl_->GetActiveUniform(program, index, bufsize, length, size, type, name);
}

void GLES2TraceImplementation::GetActiveUniformBlockiv(GLuint program,
                                                       GLuint index,
                                                       GLenum pname,
                                                       GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetActiveUniformBlockiv");
  gl_->GetActiveUniformBlockiv(program, index, pname, params);
}

void GLES2TraceImplementation::GetActiveUniformBlockName(GLuint program,
                                                         GLuint index,
                                                         GLsizei bufsize,
                                                         GLsizei* length,
                                                         char* name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetActiveUniformBlockName");
  gl_->GetActiveUniformBlockName(program, index, bufsize, length, name);
}

void GLES2TraceImplementation::GetActiveUniformsiv(GLuint program,
                                                   GLsizei count,
                                                   const GLuint* indices,
                                                   GLenum pname,
                                                   GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetActiveUniformsiv");
  gl_->GetActiveUniformsiv(program, count, indices, pname, params);
}

void GLES2TraceImplementation::GetAttachedShaders(GLuint program,
                                                  GLsizei maxcount,
                                                  GLsizei* count,
                                                  GLuint* shaders) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetAttachedShaders");
  gl_->GetAttachedShaders(program, maxcount, count, shaders);
}

GLint GLES2TraceImplementation::GetAttribLocation(GLuint program,
                                                  const char* name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetAttribLocation");
  return gl_->GetAttribLocation(program, name);
}

void GLES2TraceImplementation::GetBooleanv(GLenum pname, GLboolean* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetBooleanv");
  gl_->GetBooleanv(pname, params);
}

void GLES2TraceImplementation::GetBufferParameteriv(GLenum target,
                                                    GLenum pname,
                                                    GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetBufferParameteriv");
  gl_->GetBufferParameteriv(target, pname, params);
}

GLenum GLES2TraceImplementation::GetError() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetError");
  return gl_->GetError();
}

void GLES2TraceImplementation::GetFloatv(GLenum pname, GLfloat* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetFloatv");
  gl_->GetFloatv(pname, params);
}

GLint GLES2TraceImplementation::GetFragDataLocation(GLuint program,
                                                    const char* name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetFragDataLocation");
  return gl_->GetFragDataLocation(program, name);
}

void GLES2TraceImplementation::GetFramebufferAttachmentParameteriv(
    GLenum target,
    GLenum attachment,
    GLenum pname,
    GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0(
      "gpu", "GLES2Trace::GetFramebufferAttachmentParameteriv");
  gl_->GetFramebufferAttachmentParameteriv(target, attachment, pname, params);
}

void GLES2TraceImplementation::GetInteger64v(GLenum pname, GLint64* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetInteger64v");
  gl_->GetInteger64v(pname, params);
}

void GLES2TraceImplementation::GetIntegeri_v(GLenum pname,
                                             GLuint index,
                                             GLint* data) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetIntegeri_v");
  gl_->GetIntegeri_v(pname, index, data);
}

void GLES2TraceImplementation::GetInteger64i_v(GLenum pname,
                                               GLuint index,
                                               GLint64* data) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetInteger64i_v");
  gl_->GetInteger64i_v(pname, index, data);
}

void GLES2TraceImplementation::GetIntegerv(GLenum pname, GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetIntegerv");
  gl_->GetIntegerv(pname, params);
}

void GLES2TraceImplementation::GetInternalformativ(GLenum target,
                                                   GLenum format,
                                                   GLenum pname,
                                                   GLsizei bufSize,
                                                   GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetInternalformativ");
  gl_->GetInternalformativ(target, format, pname, bufSize, params);
}

void GLES2TraceImplementation::GetProgramiv(GLuint program,
                                            GLenum pname,
                                            GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetProgramiv");
  gl_->GetProgramiv(program, pname, params);
}

void GLES2TraceImplementation::GetProgramInfoLog(GLuint program,
                                                 GLsizei bufsize,
                                                 GLsizei* length,
                                                 char* infolog) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetProgramInfoLog");
  gl_->GetProgramInfoLog(program, bufsize, length, infolog);
}

void GLES2TraceImplementation::GetRenderbufferParameteriv(GLenum target,
                                                          GLenum pname,
                                                          GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::GetRenderbufferParameteriv");
  gl_->GetRenderbufferParameteriv(target, pname, params);
}

void GLES2TraceImplementation::GetSamplerParameterfv(GLuint sampler,
                                                     GLenum pname,
                                                     GLfloat* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetSamplerParameterfv");
  gl_->GetSamplerParameterfv(sampler, pname, params);
}

void GLES2TraceImplementation::GetSamplerParameteriv(GLuint sampler,
                                                     GLenum pname,
                                                     GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetSamplerParameteriv");
  gl_->GetSamplerParameteriv(sampler, pname, params);
}

void GLES2TraceImplementation::GetShaderiv(GLuint shader,
                                           GLenum pname,
                                           GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetShaderiv");
  gl_->GetShaderiv(shader, pname, params);
}

void GLES2TraceImplementation::GetShaderInfoLog(GLuint shader,
                                                GLsizei bufsize,
                                                GLsizei* length,
                                                char* infolog) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetShaderInfoLog");
  gl_->GetShaderInfoLog(shader, bufsize, length, infolog);
}

void GLES2TraceImplementation::GetShaderPrecisionFormat(GLenum shadertype,
                                                        GLenum precisiontype,
                                                        GLint* range,
                                                        GLint* precision) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetShaderPrecisionFormat");
  gl_->GetShaderPrecisionFormat(shadertype, precisiontype, range, precision);
}

void GLES2TraceImplementation::GetShaderSource(GLuint shader,
                                               GLsizei bufsize,
                                               GLsizei* length,
                                               char* source) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetShaderSource");
  gl_->GetShaderSource(shader, bufsize, length, source);
}

const GLubyte* GLES2TraceImplementation::GetString(GLenum name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetString");
  return gl_->GetString(name);
}

void GLES2TraceImplementation::GetSynciv(GLsync sync,
                                         GLenum pname,
                                         GLsizei bufsize,
                                         GLsizei* length,
                                         GLint* values) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetSynciv");
  gl_->GetSynciv(sync, pname, bufsize, length, values);
}

void GLES2TraceImplementation::GetTexParameterfv(GLenum target,
                                                 GLenum pname,
                                                 GLfloat* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetTexParameterfv");
  gl_->GetTexParameterfv(target, pname, params);
}

void GLES2TraceImplementation::GetTexParameteriv(GLenum target,
                                                 GLenum pname,
                                                 GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetTexParameteriv");
  gl_->GetTexParameteriv(target, pname, params);
}

void GLES2TraceImplementation::GetTransformFeedbackVarying(GLuint program,
                                                           GLuint index,
                                                           GLsizei bufsize,
                                                           GLsizei* length,
                                                           GLsizei* size,
                                                           GLenum* type,
                                                           char* name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::GetTransformFeedbackVarying");
  gl_->GetTransformFeedbackVarying(program, index, bufsize, length, size, type,
                                   name);
}

GLuint GLES2TraceImplementation::GetUniformBlockIndex(GLuint program,
                                                      const char* name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetUniformBlockIndex");
  return gl_->GetUniformBlockIndex(program, name);
}

void GLES2TraceImplementation::GetUniformfv(GLuint program,
                                            GLint location,
                                            GLfloat* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetUniformfv");
  gl_->GetUniformfv(program, location, params);
}

void GLES2TraceImplementation::GetUniformiv(GLuint program,
                                            GLint location,
                                            GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetUniformiv");
  gl_->GetUniformiv(program, location, params);
}

void GLES2TraceImplementation::GetUniformIndices(GLuint program,
                                                 GLsizei count,
                                                 const char* const* names,
                                                 GLuint* indices) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetUniformIndices");
  gl_->GetUniformIndices(program, count, names, indices);
}

GLint GLES2TraceImplementation::GetUniformLocation(GLuint program,
                                                   const char* name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetUniformLocation");
  return gl_->GetUniformLocation(program, name);
}

void GLES2TraceImplementation::GetVertexAttribfv(GLuint index,
                                                 GLenum pname,
                                                 GLfloat* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetVertexAttribfv");
  gl_->GetVertexAttribfv(index, pname, params);
}

void GLES2TraceImplementation::GetVertexAttribiv(GLuint index,
                                                 GLenum pname,
                                                 GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetVertexAttribiv");
  gl_->GetVertexAttribiv(index, pname, params);
}

void GLES2TraceImplementation::GetVertexAttribPointerv(GLuint index,
                                                       GLenum pname,
                                                       void** pointer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetVertexAttribPointerv");
  gl_->GetVertexAttribPointerv(index, pname, pointer);
}

void GLES2TraceImplementation::Hint(GLenum target, GLenum mode) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Hint");
  gl_->Hint(target, mode);
}

void GLES2TraceImplementation::InvalidateFramebuffer(
    GLenum target,
    GLsizei count,
    const GLenum* attachments) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::InvalidateFramebuffer");
  gl_->InvalidateFramebuffer(target, count, attachments);
}

void GLES2TraceImplementation::InvalidateSubFramebuffer(
    GLenum target,
    GLsizei count,
    const GLenum* attachments,
    GLint x,
    GLint y,
    GLsizei width,
    GLsizei height) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::InvalidateSubFramebuffer");
  gl_->InvalidateSubFramebuffer(target, count, attachments, x, y, width,
                                height);
}

GLboolean GLES2TraceImplementation::IsBuffer(GLuint buffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsBuffer");
  return gl_->IsBuffer(buffer);
}

GLboolean GLES2TraceImplementation::IsEnabled(GLenum cap) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsEnabled");
  return gl_->IsEnabled(cap);
}

GLboolean GLES2TraceImplementation::IsFramebuffer(GLuint framebuffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsFramebuffer");
  return gl_->IsFramebuffer(framebuffer);
}

GLboolean GLES2TraceImplementation::IsProgram(GLuint program) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsProgram");
  return gl_->IsProgram(program);
}

GLboolean GLES2TraceImplementation::IsRenderbuffer(GLuint renderbuffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsRenderbuffer");
  return gl_->IsRenderbuffer(renderbuffer);
}

GLboolean GLES2TraceImplementation::IsSampler(GLuint sampler) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsSampler");
  return gl_->IsSampler(sampler);
}

GLboolean GLES2TraceImplementation::IsShader(GLuint shader) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsShader");
  return gl_->IsShader(shader);
}

GLboolean GLES2TraceImplementation::IsSync(GLsync sync) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsSync");
  return gl_->IsSync(sync);
}

GLboolean GLES2TraceImplementation::IsTexture(GLuint texture) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsTexture");
  return gl_->IsTexture(texture);
}

GLboolean GLES2TraceImplementation::IsTransformFeedback(
    GLuint transformfeedback) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsTransformFeedback");
  return gl_->IsTransformFeedback(transformfeedback);
}

void GLES2TraceImplementation::LineWidth(GLfloat width) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::LineWidth");
  gl_->LineWidth(width);
}

void GLES2TraceImplementation::LinkProgram(GLuint program) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::LinkProgram");
  gl_->LinkProgram(program);
}

void GLES2TraceImplementation::PauseTransformFeedback() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::PauseTransformFeedback");
  gl_->PauseTransformFeedback();
}

void GLES2TraceImplementation::PixelStorei(GLenum pname, GLint param) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::PixelStorei");
  gl_->PixelStorei(pname, param);
}

void GLES2TraceImplementation::PolygonOffset(GLfloat factor, GLfloat units) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::PolygonOffset");
  gl_->PolygonOffset(factor, units);
}

void GLES2TraceImplementation::ReadBuffer(GLenum src) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ReadBuffer");
  gl_->ReadBuffer(src);
}

void GLES2TraceImplementation::ReadPixels(GLint x,
                                          GLint y,
                                          GLsizei width,
                                          GLsizei height,
                                          GLenum format,
                                          GLenum type,
                                          void* pixels) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ReadPixels");
  gl_->ReadPixels(x, y, width, height, format, type, pixels);
}

void GLES2TraceImplementation::ReleaseShaderCompiler() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ReleaseShaderCompiler");
  gl_->ReleaseShaderCompiler();
}

void GLES2TraceImplementation::RenderbufferStorage(GLenum target,
                                                   GLenum internalformat,
                                                   GLsizei width,
                                                   GLsizei height) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::RenderbufferStorage");
  gl_->RenderbufferStorage(target, internalformat, width, height);
}

void GLES2TraceImplementation::ResumeTransformFeedback() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ResumeTransformFeedback");
  gl_->ResumeTransformFeedback();
}

void GLES2TraceImplementation::SampleCoverage(GLclampf value,
                                              GLboolean invert) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::SampleCoverage");
  gl_->SampleCoverage(value, invert);
}

void GLES2TraceImplementation::SamplerParameterf(GLuint sampler,
                                                 GLenum pname,
                                                 GLfloat param) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::SamplerParameterf");
  gl_->SamplerParameterf(sampler, pname, param);
}

void GLES2TraceImplementation::SamplerParameterfv(GLuint sampler,
                                                  GLenum pname,
                                                  const GLfloat* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::SamplerParameterfv");
  gl_->SamplerParameterfv(sampler, pname, params);
}

void GLES2TraceImplementation::SamplerParameteri(GLuint sampler,
                                                 GLenum pname,
                                                 GLint param) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::SamplerParameteri");
  gl_->SamplerParameteri(sampler, pname, param);
}

void GLES2TraceImplementation::SamplerParameteriv(GLuint sampler,
                                                  GLenum pname,
                                                  const GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::SamplerParameteriv");
  gl_->SamplerParameteriv(sampler, pname, params);
}

void GLES2TraceImplementation::Scissor(GLint x,
                                       GLint y,
                                       GLsizei width,
                                       GLsizei height) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Scissor");
  gl_->Scissor(x, y, width, height);
}

void GLES2TraceImplementation::ShaderBinary(GLsizei n,
                                            const GLuint* shaders,
                                            GLenum binaryformat,
                                            const void* binary,
                                            GLsizei length) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ShaderBinary");
  gl_->ShaderBinary(n, shaders, binaryformat, binary, length);
}

void GLES2TraceImplementation::ShaderSource(GLuint shader,
                                            GLsizei count,
                                            const GLchar* const* str,
                                            const GLint* length) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ShaderSource");
  gl_->ShaderSource(shader, count, str, length);
}

void GLES2TraceImplementation::ShallowFinishCHROMIUM() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ShallowFinishCHROMIUM");
  gl_->ShallowFinishCHROMIUM();
}

void GLES2TraceImplementation::ShallowFlushCHROMIUM() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ShallowFlushCHROMIUM");
  gl_->ShallowFlushCHROMIUM();
}

void GLES2TraceImplementation::OrderingBarrierCHROMIUM() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::OrderingBarrierCHROMIUM");
  gl_->OrderingBarrierCHROMIUM();
}

void GLES2TraceImplementation::StencilFunc(GLenum func,
                                           GLint ref,
                                           GLuint mask) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::StencilFunc");
  gl_->StencilFunc(func, ref, mask);
}

void GLES2TraceImplementation::StencilFuncSeparate(GLenum face,
                                                   GLenum func,
                                                   GLint ref,
                                                   GLuint mask) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::StencilFuncSeparate");
  gl_->StencilFuncSeparate(face, func, ref, mask);
}

void GLES2TraceImplementation::StencilMask(GLuint mask) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::StencilMask");
  gl_->StencilMask(mask);
}

void GLES2TraceImplementation::StencilMaskSeparate(GLenum face, GLuint mask) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::StencilMaskSeparate");
  gl_->StencilMaskSeparate(face, mask);
}

void GLES2TraceImplementation::StencilOp(GLenum fail,
                                         GLenum zfail,
                                         GLenum zpass) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::StencilOp");
  gl_->StencilOp(fail, zfail, zpass);
}

void GLES2TraceImplementation::StencilOpSeparate(GLenum face,
                                                 GLenum fail,
                                                 GLenum zfail,
                                                 GLenum zpass) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::StencilOpSeparate");
  gl_->StencilOpSeparate(face, fail, zfail, zpass);
}

void GLES2TraceImplementation::TexImage2D(GLenum target,
                                          GLint level,
                                          GLint internalformat,
                                          GLsizei width,
                                          GLsizei height,
                                          GLint border,
                                          GLenum format,
                                          GLenum type,
                                          const void* pixels) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TexImage2D");
  gl_->TexImage2D(target, level, internalformat, width, height, border, format,
                  type, pixels);
}

void GLES2TraceImplementation::TexImage3D(GLenum target,
                                          GLint level,
                                          GLint internalformat,
                                          GLsizei width,
                                          GLsizei height,
                                          GLsizei depth,
                                          GLint border,
                                          GLenum format,
                                          GLenum type,
                                          const void* pixels) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TexImage3D");
  gl_->TexImage3D(target, level, internalformat, width, height, depth, border,
                  format, type, pixels);
}

void GLES2TraceImplementation::TexParameterf(GLenum target,
                                             GLenum pname,
                                             GLfloat param) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TexParameterf");
  gl_->TexParameterf(target, pname, param);
}

void GLES2TraceImplementation::TexParameterfv(GLenum target,
                                              GLenum pname,
                                              const GLfloat* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TexParameterfv");
  gl_->TexParameterfv(target, pname, params);
}

void GLES2TraceImplementation::TexParameteri(GLenum target,
                                             GLenum pname,
                                             GLint param) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TexParameteri");
  gl_->TexParameteri(target, pname, param);
}

void GLES2TraceImplementation::TexParameteriv(GLenum target,
                                              GLenum pname,
                                              const GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TexParameteriv");
  gl_->TexParameteriv(target, pname, params);
}

void GLES2TraceImplementation::TexStorage3D(GLenum target,
                                            GLsizei levels,
                                            GLenum internalFormat,
                                            GLsizei width,
                                            GLsizei height,
                                            GLsizei depth) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TexStorage3D");
  gl_->TexStorage3D(target, levels, internalFormat, width, height, depth);
}

void GLES2TraceImplementation::TexSubImage2D(GLenum target,
                                             GLint level,
                                             GLint xoffset,
                                             GLint yoffset,
                                             GLsizei width,
                                             GLsizei height,
                                             GLenum format,
                                             GLenum type,
                                             const void* pixels) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TexSubImage2D");
  gl_->TexSubImage2D(target, level, xoffset, yoffset, width, height, format,
                     type, pixels);
}

void GLES2TraceImplementation::TexSubImage3D(GLenum target,
                                             GLint level,
                                             GLint xoffset,
                                             GLint yoffset,
                                             GLint zoffset,
                                             GLsizei width,
                                             GLsizei height,
                                             GLsizei depth,
                                             GLenum format,
                                             GLenum type,
                                             const void* pixels) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TexSubImage3D");
  gl_->TexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height,
                     depth, format, type, pixels);
}

void GLES2TraceImplementation::TransformFeedbackVaryings(
    GLuint program,
    GLsizei count,
    const char* const* varyings,
    GLenum buffermode) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TransformFeedbackVaryings");
  gl_->TransformFeedbackVaryings(program, count, varyings, buffermode);
}

void GLES2TraceImplementation::Uniform1f(GLint location, GLfloat x) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform1f");
  gl_->Uniform1f(location, x);
}

void GLES2TraceImplementation::Uniform1fv(GLint location,
                                          GLsizei count,
                                          const GLfloat* v) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform1fv");
  gl_->Uniform1fv(location, count, v);
}

void GLES2TraceImplementation::Uniform1i(GLint location, GLint x) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform1i");
  gl_->Uniform1i(location, x);
}

void GLES2TraceImplementation::Uniform1iv(GLint location,
                                          GLsizei count,
                                          const GLint* v) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform1iv");
  gl_->Uniform1iv(location, count, v);
}

void GLES2TraceImplementation::Uniform1ui(GLint location, GLuint x) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform1ui");
  gl_->Uniform1ui(location, x);
}

void GLES2TraceImplementation::Uniform1uiv(GLint location,
                                           GLsizei count,
                                           const GLuint* v) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform1uiv");
  gl_->Uniform1uiv(location, count, v);
}

void GLES2TraceImplementation::Uniform2f(GLint location, GLfloat x, GLfloat y) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform2f");
  gl_->Uniform2f(location, x, y);
}

void GLES2TraceImplementation::Uniform2fv(GLint location,
                                          GLsizei count,
                                          const GLfloat* v) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform2fv");
  gl_->Uniform2fv(location, count, v);
}

void GLES2TraceImplementation::Uniform2i(GLint location, GLint x, GLint y) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform2i");
  gl_->Uniform2i(location, x, y);
}

void GLES2TraceImplementation::Uniform2iv(GLint location,
                                          GLsizei count,
                                          const GLint* v) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform2iv");
  gl_->Uniform2iv(location, count, v);
}

void GLES2TraceImplementation::Uniform2ui(GLint location, GLuint x, GLuint y) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform2ui");
  gl_->Uniform2ui(location, x, y);
}

void GLES2TraceImplementation::Uniform2uiv(GLint location,
                                           GLsizei count,
                                           const GLuint* v) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform2uiv");
  gl_->Uniform2uiv(location, count, v);
}

void GLES2TraceImplementation::Uniform3f(GLint location,
                                         GLfloat x,
                                         GLfloat y,
                                         GLfloat z) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform3f");
  gl_->Uniform3f(location, x, y, z);
}

void GLES2TraceImplementation::Uniform3fv(GLint location,
                                          GLsizei count,
                                          const GLfloat* v) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform3fv");
  gl_->Uniform3fv(location, count, v);
}

void GLES2TraceImplementation::Uniform3i(GLint location,
                                         GLint x,
                                         GLint y,
                                         GLint z) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform3i");
  gl_->Uniform3i(location, x, y, z);
}

void GLES2TraceImplementation::Uniform3iv(GLint location,
                                          GLsizei count,
                                          const GLint* v) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform3iv");
  gl_->Uniform3iv(location, count, v);
}

void GLES2TraceImplementation::Uniform3ui(GLint location,
                                          GLuint x,
                                          GLuint y,
                                          GLuint z) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform3ui");
  gl_->Uniform3ui(location, x, y, z);
}

void GLES2TraceImplementation::Uniform3uiv(GLint location,
                                           GLsizei count,
                                           const GLuint* v) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform3uiv");
  gl_->Uniform3uiv(location, count, v);
}

void GLES2TraceImplementation::Uniform4f(GLint location,
                                         GLfloat x,
                                         GLfloat y,
                                         GLfloat z,
                                         GLfloat w) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform4f");
  gl_->Uniform4f(location, x, y, z, w);
}

void GLES2TraceImplementation::Uniform4fv(GLint location,
                                          GLsizei count,
                                          const GLfloat* v) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform4fv");
  gl_->Uniform4fv(location, count, v);
}

void GLES2TraceImplementation::Uniform4i(GLint location,
                                         GLint x,
                                         GLint y,
                                         GLint z,
                                         GLint w) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform4i");
  gl_->Uniform4i(location, x, y, z, w);
}

void GLES2TraceImplementation::Uniform4iv(GLint location,
                                          GLsizei count,
                                          const GLint* v) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform4iv");
  gl_->Uniform4iv(location, count, v);
}

void GLES2TraceImplementation::Uniform4ui(GLint location,
                                          GLuint x,
                                          GLuint y,
                                          GLuint z,
                                          GLuint w) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform4ui");
  gl_->Uniform4ui(location, x, y, z, w);
}

void GLES2TraceImplementation::Uniform4uiv(GLint location,
                                           GLsizei count,
                                           const GLuint* v) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Uniform4uiv");
  gl_->Uniform4uiv(location, count, v);
}

void GLES2TraceImplementation::UniformBlockBinding(GLuint program,
                                                   GLuint index,
                                                   GLuint binding) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UniformBlockBinding");
  gl_->UniformBlockBinding(program, index, binding);
}

void GLES2TraceImplementation::UniformMatrix2fv(GLint location,
                                                GLsizei count,
                                                GLboolean transpose,
                                                const GLfloat* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UniformMatrix2fv");
  gl_->UniformMatrix2fv(location, count, transpose, value);
}

void GLES2TraceImplementation::UniformMatrix2x3fv(GLint location,
                                                  GLsizei count,
                                                  GLboolean transpose,
                                                  const GLfloat* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UniformMatrix2x3fv");
  gl_->UniformMatrix2x3fv(location, count, transpose, value);
}

void GLES2TraceImplementation::UniformMatrix2x4fv(GLint location,
                                                  GLsizei count,
                                                  GLboolean transpose,
                                                  const GLfloat* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UniformMatrix2x4fv");
  gl_->UniformMatrix2x4fv(location, count, transpose, value);
}

void GLES2TraceImplementation::UniformMatrix3fv(GLint location,
                                                GLsizei count,
                                                GLboolean transpose,
                                                const GLfloat* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UniformMatrix3fv");
  gl_->UniformMatrix3fv(location, count, transpose, value);
}

void GLES2TraceImplementation::UniformMatrix3x2fv(GLint location,
                                                  GLsizei count,
                                                  GLboolean transpose,
                                                  const GLfloat* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UniformMatrix3x2fv");
  gl_->UniformMatrix3x2fv(location, count, transpose, value);
}

void GLES2TraceImplementation::UniformMatrix3x4fv(GLint location,
                                                  GLsizei count,
                                                  GLboolean transpose,
                                                  const GLfloat* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UniformMatrix3x4fv");
  gl_->UniformMatrix3x4fv(location, count, transpose, value);
}

void GLES2TraceImplementation::UniformMatrix4fv(GLint location,
                                                GLsizei count,
                                                GLboolean transpose,
                                                const GLfloat* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UniformMatrix4fv");
  gl_->UniformMatrix4fv(location, count, transpose, value);
}

void GLES2TraceImplementation::UniformMatrix4x2fv(GLint location,
                                                  GLsizei count,
                                                  GLboolean transpose,
                                                  const GLfloat* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UniformMatrix4x2fv");
  gl_->UniformMatrix4x2fv(location, count, transpose, value);
}

void GLES2TraceImplementation::UniformMatrix4x3fv(GLint location,
                                                  GLsizei count,
                                                  GLboolean transpose,
                                                  const GLfloat* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UniformMatrix4x3fv");
  gl_->UniformMatrix4x3fv(location, count, transpose, value);
}

void GLES2TraceImplementation::UseProgram(GLuint program) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UseProgram");
  gl_->UseProgram(program);
}

void GLES2TraceImplementation::ValidateProgram(GLuint program) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ValidateProgram");
  gl_->ValidateProgram(program);
}

void GLES2TraceImplementation::VertexAttrib1f(GLuint indx, GLfloat x) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttrib1f");
  gl_->VertexAttrib1f(indx, x);
}

void GLES2TraceImplementation::VertexAttrib1fv(GLuint indx,
                                               const GLfloat* values) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttrib1fv");
  gl_->VertexAttrib1fv(indx, values);
}

void GLES2TraceImplementation::VertexAttrib2f(GLuint indx,
                                              GLfloat x,
                                              GLfloat y) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttrib2f");
  gl_->VertexAttrib2f(indx, x, y);
}

void GLES2TraceImplementation::VertexAttrib2fv(GLuint indx,
                                               const GLfloat* values) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttrib2fv");
  gl_->VertexAttrib2fv(indx, values);
}

void GLES2TraceImplementation::VertexAttrib3f(GLuint indx,
                                              GLfloat x,
                                              GLfloat y,
                                              GLfloat z) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttrib3f");
  gl_->VertexAttrib3f(indx, x, y, z);
}

void GLES2TraceImplementation::VertexAttrib3fv(GLuint indx,
                                               const GLfloat* values) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttrib3fv");
  gl_->VertexAttrib3fv(indx, values);
}

void GLES2TraceImplementation::VertexAttrib4f(GLuint indx,
                                              GLfloat x,
                                              GLfloat y,
                                              GLfloat z,
                                              GLfloat w) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttrib4f");
  gl_->VertexAttrib4f(indx, x, y, z, w);
}

void GLES2TraceImplementation::VertexAttrib4fv(GLuint indx,
                                               const GLfloat* values) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttrib4fv");
  gl_->VertexAttrib4fv(indx, values);
}

void GLES2TraceImplementation::VertexAttribI4i(GLuint indx,
                                               GLint x,
                                               GLint y,
                                               GLint z,
                                               GLint w) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttribI4i");
  gl_->VertexAttribI4i(indx, x, y, z, w);
}

void GLES2TraceImplementation::VertexAttribI4iv(GLuint indx,
                                                const GLint* values) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttribI4iv");
  gl_->VertexAttribI4iv(indx, values);
}

void GLES2TraceImplementation::VertexAttribI4ui(GLuint indx,
                                                GLuint x,
                                                GLuint y,
                                                GLuint z,
                                                GLuint w) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttribI4ui");
  gl_->VertexAttribI4ui(indx, x, y, z, w);
}

void GLES2TraceImplementation::VertexAttribI4uiv(GLuint indx,
                                                 const GLuint* values) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttribI4uiv");
  gl_->VertexAttribI4uiv(indx, values);
}

void GLES2TraceImplementation::VertexAttribIPointer(GLuint indx,
                                                    GLint size,
                                                    GLenum type,
                                                    GLsizei stride,
                                                    const void* ptr) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttribIPointer");
  gl_->VertexAttribIPointer(indx, size, type, stride, ptr);
}

void GLES2TraceImplementation::VertexAttribPointer(GLuint indx,
                                                   GLint size,
                                                   GLenum type,
                                                   GLboolean normalized,
                                                   GLsizei stride,
                                                   const void* ptr) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttribPointer");
  gl_->VertexAttribPointer(indx, size, type, normalized, stride, ptr);
}

void GLES2TraceImplementation::Viewport(GLint x,
                                        GLint y,
                                        GLsizei width,
                                        GLsizei height) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::Viewport");
  gl_->Viewport(x, y, width, height);
}

void GLES2TraceImplementation::WaitSync(GLsync sync,
                                        GLbitfield flags,
                                        GLuint64 timeout) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::WaitSync");
  gl_->WaitSync(sync, flags, timeout);
}

void GLES2TraceImplementation::BlitFramebufferCHROMIUM(GLint srcX0,
                                                       GLint srcY0,
                                                       GLint srcX1,
                                                       GLint srcY1,
                                                       GLint dstX0,
                                                       GLint dstY0,
                                                       GLint dstX1,
                                                       GLint dstY1,
                                                       GLbitfield mask,
                                                       GLenum filter) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BlitFramebufferCHROMIUM");
  gl_->BlitFramebufferCHROMIUM(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1,
                               dstY1, mask, filter);
}

void GLES2TraceImplementation::RenderbufferStorageMultisampleCHROMIUM(
    GLenum target,
    GLsizei samples,
    GLenum internalformat,
    GLsizei width,
    GLsizei height) {
  TRACE_EVENT_BINARY_EFFICIENT0(
      "gpu", "GLES2Trace::RenderbufferStorageMultisampleCHROMIUM");
  gl_->RenderbufferStorageMultisampleCHROMIUM(target, samples, internalformat,
                                              width, height);
}

void GLES2TraceImplementation::RenderbufferStorageMultisampleEXT(
    GLenum target,
    GLsizei samples,
    GLenum internalformat,
    GLsizei width,
    GLsizei height) {
  TRACE_EVENT_BINARY_EFFICIENT0(
      "gpu", "GLES2Trace::RenderbufferStorageMultisampleEXT");
  gl_->RenderbufferStorageMultisampleEXT(target, samples, internalformat, width,
                                         height);
}

void GLES2TraceImplementation::FramebufferTexture2DMultisampleEXT(
    GLenum target,
    GLenum attachment,
    GLenum textarget,
    GLuint texture,
    GLint level,
    GLsizei samples) {
  TRACE_EVENT_BINARY_EFFICIENT0(
      "gpu", "GLES2Trace::FramebufferTexture2DMultisampleEXT");
  gl_->FramebufferTexture2DMultisampleEXT(target, attachment, textarget,
                                          texture, level, samples);
}

void GLES2TraceImplementation::TexStorage2DEXT(GLenum target,
                                               GLsizei levels,
                                               GLenum internalFormat,
                                               GLsizei width,
                                               GLsizei height) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TexStorage2DEXT");
  gl_->TexStorage2DEXT(target, levels, internalFormat, width, height);
}

void GLES2TraceImplementation::GenQueriesEXT(GLsizei n, GLuint* queries) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GenQueriesEXT");
  gl_->GenQueriesEXT(n, queries);
}

void GLES2TraceImplementation::DeleteQueriesEXT(GLsizei n,
                                                const GLuint* queries) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DeleteQueriesEXT");
  gl_->DeleteQueriesEXT(n, queries);
}

GLboolean GLES2TraceImplementation::IsQueryEXT(GLuint id) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsQueryEXT");
  return gl_->IsQueryEXT(id);
}

void GLES2TraceImplementation::BeginQueryEXT(GLenum target, GLuint id) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BeginQueryEXT");
  gl_->BeginQueryEXT(target, id);
}

void GLES2TraceImplementation::BeginTransformFeedback(GLenum primitivemode) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BeginTransformFeedback");
  gl_->BeginTransformFeedback(primitivemode);
}

void GLES2TraceImplementation::EndQueryEXT(GLenum target) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::EndQueryEXT");
  gl_->EndQueryEXT(target);
}

void GLES2TraceImplementation::EndTransformFeedback() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::EndTransformFeedback");
  gl_->EndTransformFeedback();
}

void GLES2TraceImplementation::GetQueryivEXT(GLenum target,
                                             GLenum pname,
                                             GLint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetQueryivEXT");
  gl_->GetQueryivEXT(target, pname, params);
}

void GLES2TraceImplementation::GetQueryObjectuivEXT(GLuint id,
                                                    GLenum pname,
                                                    GLuint* params) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetQueryObjectuivEXT");
  gl_->GetQueryObjectuivEXT(id, pname, params);
}

void GLES2TraceImplementation::InsertEventMarkerEXT(GLsizei length,
                                                    const GLchar* marker) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::InsertEventMarkerEXT");
  gl_->InsertEventMarkerEXT(length, marker);
}

void GLES2TraceImplementation::PushGroupMarkerEXT(GLsizei length,
                                                  const GLchar* marker) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::PushGroupMarkerEXT");
  gl_->PushGroupMarkerEXT(length, marker);
}

void GLES2TraceImplementation::PopGroupMarkerEXT() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::PopGroupMarkerEXT");
  gl_->PopGroupMarkerEXT();
}

void GLES2TraceImplementation::GenVertexArraysOES(GLsizei n, GLuint* arrays) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GenVertexArraysOES");
  gl_->GenVertexArraysOES(n, arrays);
}

void GLES2TraceImplementation::DeleteVertexArraysOES(GLsizei n,
                                                     const GLuint* arrays) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DeleteVertexArraysOES");
  gl_->DeleteVertexArraysOES(n, arrays);
}

GLboolean GLES2TraceImplementation::IsVertexArrayOES(GLuint array) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsVertexArrayOES");
  return gl_->IsVertexArrayOES(array);
}

void GLES2TraceImplementation::BindVertexArrayOES(GLuint array) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BindVertexArrayOES");
  gl_->BindVertexArrayOES(array);
}

void GLES2TraceImplementation::SwapBuffers() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::SwapBuffers");
  gl_->SwapBuffers();
}

GLuint GLES2TraceImplementation::GetMaxValueInBufferCHROMIUM(GLuint buffer_id,
                                                             GLsizei count,
                                                             GLenum type,
                                                             GLuint offset) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::GetMaxValueInBufferCHROMIUM");
  return gl_->GetMaxValueInBufferCHROMIUM(buffer_id, count, type, offset);
}

GLboolean GLES2TraceImplementation::EnableFeatureCHROMIUM(const char* feature) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::EnableFeatureCHROMIUM");
  return gl_->EnableFeatureCHROMIUM(feature);
}

void* GLES2TraceImplementation::MapBufferCHROMIUM(GLuint target,
                                                  GLenum access) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::MapBufferCHROMIUM");
  return gl_->MapBufferCHROMIUM(target, access);
}

GLboolean GLES2TraceImplementation::UnmapBufferCHROMIUM(GLuint target) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UnmapBufferCHROMIUM");
  return gl_->UnmapBufferCHROMIUM(target);
}

void* GLES2TraceImplementation::MapBufferSubDataCHROMIUM(GLuint target,
                                                         GLintptr offset,
                                                         GLsizeiptr size,
                                                         GLenum access) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::MapBufferSubDataCHROMIUM");
  return gl_->MapBufferSubDataCHROMIUM(target, offset, size, access);
}

void GLES2TraceImplementation::UnmapBufferSubDataCHROMIUM(const void* mem) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::UnmapBufferSubDataCHROMIUM");
  gl_->UnmapBufferSubDataCHROMIUM(mem);
}

void* GLES2TraceImplementation::MapBufferRange(GLenum target,
                                               GLintptr offset,
                                               GLsizeiptr size,
                                               GLbitfield access) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::MapBufferRange");
  return gl_->MapBufferRange(target, offset, size, access);
}

GLboolean GLES2TraceImplementation::UnmapBuffer(GLenum target) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::UnmapBuffer");
  return gl_->UnmapBuffer(target);
}

void* GLES2TraceImplementation::MapTexSubImage2DCHROMIUM(GLenum target,
                                                         GLint level,
                                                         GLint xoffset,
                                                         GLint yoffset,
                                                         GLsizei width,
                                                         GLsizei height,
                                                         GLenum format,
                                                         GLenum type,
                                                         GLenum access) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::MapTexSubImage2DCHROMIUM");
  return gl_->MapTexSubImage2DCHROMIUM(target, level, xoffset, yoffset, width,
                                       height, format, type, access);
}

void GLES2TraceImplementation::UnmapTexSubImage2DCHROMIUM(const void* mem) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::UnmapTexSubImage2DCHROMIUM");
  gl_->UnmapTexSubImage2DCHROMIUM(mem);
}

void GLES2TraceImplementation::ResizeCHROMIUM(GLuint width,
                                              GLuint height,
                                              GLfloat scale_factor) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ResizeCHROMIUM");
  gl_->ResizeCHROMIUM(width, height, scale_factor);
}

const GLchar* GLES2TraceImplementation::GetRequestableExtensionsCHROMIUM() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::GetRequestableExtensionsCHROMIUM");
  return gl_->GetRequestableExtensionsCHROMIUM();
}

void GLES2TraceImplementation::RequestExtensionCHROMIUM(const char* extension) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::RequestExtensionCHROMIUM");
  gl_->RequestExtensionCHROMIUM(extension);
}

void GLES2TraceImplementation::RateLimitOffscreenContextCHROMIUM() {
  TRACE_EVENT_BINARY_EFFICIENT0(
      "gpu", "GLES2Trace::RateLimitOffscreenContextCHROMIUM");
  gl_->RateLimitOffscreenContextCHROMIUM();
}

void GLES2TraceImplementation::GetProgramInfoCHROMIUM(GLuint program,
                                                      GLsizei bufsize,
                                                      GLsizei* size,
                                                      void* info) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetProgramInfoCHROMIUM");
  gl_->GetProgramInfoCHROMIUM(program, bufsize, size, info);
}

void GLES2TraceImplementation::GetUniformBlocksCHROMIUM(GLuint program,
                                                        GLsizei bufsize,
                                                        GLsizei* size,
                                                        void* info) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetUniformBlocksCHROMIUM");
  gl_->GetUniformBlocksCHROMIUM(program, bufsize, size, info);
}

void GLES2TraceImplementation::GetTransformFeedbackVaryingsCHROMIUM(
    GLuint program,
    GLsizei bufsize,
    GLsizei* size,
    void* info) {
  TRACE_EVENT_BINARY_EFFICIENT0(
      "gpu", "GLES2Trace::GetTransformFeedbackVaryingsCHROMIUM");
  gl_->GetTransformFeedbackVaryingsCHROMIUM(program, bufsize, size, info);
}

void GLES2TraceImplementation::GetUniformsES3CHROMIUM(GLuint program,
                                                      GLsizei bufsize,
                                                      GLsizei* size,
                                                      void* info) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GetUniformsES3CHROMIUM");
  gl_->GetUniformsES3CHROMIUM(program, bufsize, size, info);
}

GLuint GLES2TraceImplementation::CreateStreamTextureCHROMIUM(GLuint texture) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::CreateStreamTextureCHROMIUM");
  return gl_->CreateStreamTextureCHROMIUM(texture);
}

GLuint GLES2TraceImplementation::CreateImageCHROMIUM(ClientBuffer buffer,
                                                     GLsizei width,
                                                     GLsizei height,
                                                     GLenum internalformat) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CreateImageCHROMIUM");
  return gl_->CreateImageCHROMIUM(buffer, width, height, internalformat);
}

void GLES2TraceImplementation::DestroyImageCHROMIUM(GLuint image_id) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DestroyImageCHROMIUM");
  gl_->DestroyImageCHROMIUM(image_id);
}

GLuint GLES2TraceImplementation::CreateGpuMemoryBufferImageCHROMIUM(
    GLsizei width,
    GLsizei height,
    GLenum internalformat,
    GLenum usage) {
  TRACE_EVENT_BINARY_EFFICIENT0(
      "gpu", "GLES2Trace::CreateGpuMemoryBufferImageCHROMIUM");
  return gl_->CreateGpuMemoryBufferImageCHROMIUM(width, height, internalformat,
                                                 usage);
}

void GLES2TraceImplementation::GetTranslatedShaderSourceANGLE(GLuint shader,
                                                              GLsizei bufsize,
                                                              GLsizei* length,
                                                              char* source) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::GetTranslatedShaderSourceANGLE");
  gl_->GetTranslatedShaderSourceANGLE(shader, bufsize, length, source);
}

void GLES2TraceImplementation::PostSubBufferCHROMIUM(GLint x,
                                                     GLint y,
                                                     GLint width,
                                                     GLint height) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::PostSubBufferCHROMIUM");
  gl_->PostSubBufferCHROMIUM(x, y, width, height);
}

void GLES2TraceImplementation::TexImageIOSurface2DCHROMIUM(GLenum target,
                                                           GLsizei width,
                                                           GLsizei height,
                                                           GLuint ioSurfaceId,
                                                           GLuint plane) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::TexImageIOSurface2DCHROMIUM");
  gl_->TexImageIOSurface2DCHROMIUM(target, width, height, ioSurfaceId, plane);
}

void GLES2TraceImplementation::CopyTextureCHROMIUM(GLenum target,
                                                   GLenum source_id,
                                                   GLenum dest_id,
                                                   GLint internalformat,
                                                   GLenum dest_type) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CopyTextureCHROMIUM");
  gl_->CopyTextureCHROMIUM(target, source_id, dest_id, internalformat,
                           dest_type);
}

void GLES2TraceImplementation::CopySubTextureCHROMIUM(GLenum target,
                                                      GLenum source_id,
                                                      GLenum dest_id,
                                                      GLint xoffset,
                                                      GLint yoffset) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::CopySubTextureCHROMIUM");
  gl_->CopySubTextureCHROMIUM(target, source_id, dest_id, xoffset, yoffset);
}

void GLES2TraceImplementation::DrawArraysInstancedANGLE(GLenum mode,
                                                        GLint first,
                                                        GLsizei count,
                                                        GLsizei primcount) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DrawArraysInstancedANGLE");
  gl_->DrawArraysInstancedANGLE(mode, first, count, primcount);
}

void GLES2TraceImplementation::DrawElementsInstancedANGLE(GLenum mode,
                                                          GLsizei count,
                                                          GLenum type,
                                                          const void* indices,
                                                          GLsizei primcount) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::DrawElementsInstancedANGLE");
  gl_->DrawElementsInstancedANGLE(mode, count, type, indices, primcount);
}

void GLES2TraceImplementation::VertexAttribDivisorANGLE(GLuint index,
                                                        GLuint divisor) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::VertexAttribDivisorANGLE");
  gl_->VertexAttribDivisorANGLE(index, divisor);
}

void GLES2TraceImplementation::GenMailboxCHROMIUM(GLbyte* mailbox) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GenMailboxCHROMIUM");
  gl_->GenMailboxCHROMIUM(mailbox);
}

void GLES2TraceImplementation::ProduceTextureCHROMIUM(GLenum target,
                                                      const GLbyte* mailbox) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ProduceTextureCHROMIUM");
  gl_->ProduceTextureCHROMIUM(target, mailbox);
}

void GLES2TraceImplementation::ProduceTextureDirectCHROMIUM(
    GLuint texture,
    GLenum target,
    const GLbyte* mailbox) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::ProduceTextureDirectCHROMIUM");
  gl_->ProduceTextureDirectCHROMIUM(texture, target, mailbox);
}

void GLES2TraceImplementation::ConsumeTextureCHROMIUM(GLenum target,
                                                      const GLbyte* mailbox) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ConsumeTextureCHROMIUM");
  gl_->ConsumeTextureCHROMIUM(target, mailbox);
}

GLuint GLES2TraceImplementation::CreateAndConsumeTextureCHROMIUM(
    GLenum target,
    const GLbyte* mailbox) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::CreateAndConsumeTextureCHROMIUM");
  return gl_->CreateAndConsumeTextureCHROMIUM(target, mailbox);
}

void GLES2TraceImplementation::BindUniformLocationCHROMIUM(GLuint program,
                                                           GLint location,
                                                           const char* name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::BindUniformLocationCHROMIUM");
  gl_->BindUniformLocationCHROMIUM(program, location, name);
}

void GLES2TraceImplementation::GenValuebuffersCHROMIUM(GLsizei n,
                                                       GLuint* buffers) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::GenValuebuffersCHROMIUM");
  gl_->GenValuebuffersCHROMIUM(n, buffers);
}

void GLES2TraceImplementation::DeleteValuebuffersCHROMIUM(
    GLsizei n,
    const GLuint* valuebuffers) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::DeleteValuebuffersCHROMIUM");
  gl_->DeleteValuebuffersCHROMIUM(n, valuebuffers);
}

GLboolean GLES2TraceImplementation::IsValuebufferCHROMIUM(GLuint valuebuffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::IsValuebufferCHROMIUM");
  return gl_->IsValuebufferCHROMIUM(valuebuffer);
}

void GLES2TraceImplementation::BindValuebufferCHROMIUM(GLenum target,
                                                       GLuint valuebuffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BindValuebufferCHROMIUM");
  gl_->BindValuebufferCHROMIUM(target, valuebuffer);
}

void GLES2TraceImplementation::SubscribeValueCHROMIUM(GLenum target,
                                                      GLenum subscription) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::SubscribeValueCHROMIUM");
  gl_->SubscribeValueCHROMIUM(target, subscription);
}

void GLES2TraceImplementation::PopulateSubscribedValuesCHROMIUM(GLenum target) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::PopulateSubscribedValuesCHROMIUM");
  gl_->PopulateSubscribedValuesCHROMIUM(target);
}

void GLES2TraceImplementation::UniformValuebufferCHROMIUM(GLint location,
                                                          GLenum target,
                                                          GLenum subscription) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::UniformValuebufferCHROMIUM");
  gl_->UniformValuebufferCHROMIUM(location, target, subscription);
}

void GLES2TraceImplementation::BindTexImage2DCHROMIUM(GLenum target,
                                                      GLint imageId) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BindTexImage2DCHROMIUM");
  gl_->BindTexImage2DCHROMIUM(target, imageId);
}

void GLES2TraceImplementation::ReleaseTexImage2DCHROMIUM(GLenum target,
                                                         GLint imageId) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::ReleaseTexImage2DCHROMIUM");
  gl_->ReleaseTexImage2DCHROMIUM(target, imageId);
}

void GLES2TraceImplementation::TraceBeginCHROMIUM(const char* category_name,
                                                  const char* trace_name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TraceBeginCHROMIUM");
  gl_->TraceBeginCHROMIUM(category_name, trace_name);
}

void GLES2TraceImplementation::TraceEndCHROMIUM() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::TraceEndCHROMIUM");
  gl_->TraceEndCHROMIUM();
}

void GLES2TraceImplementation::AsyncTexSubImage2DCHROMIUM(GLenum target,
                                                          GLint level,
                                                          GLint xoffset,
                                                          GLint yoffset,
                                                          GLsizei width,
                                                          GLsizei height,
                                                          GLenum format,
                                                          GLenum type,
                                                          const void* data) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::AsyncTexSubImage2DCHROMIUM");
  gl_->AsyncTexSubImage2DCHROMIUM(target, level, xoffset, yoffset, width,
                                  height, format, type, data);
}

void GLES2TraceImplementation::AsyncTexImage2DCHROMIUM(GLenum target,
                                                       GLint level,
                                                       GLenum internalformat,
                                                       GLsizei width,
                                                       GLsizei height,
                                                       GLint border,
                                                       GLenum format,
                                                       GLenum type,
                                                       const void* pixels) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::AsyncTexImage2DCHROMIUM");
  gl_->AsyncTexImage2DCHROMIUM(target, level, internalformat, width, height,
                               border, format, type, pixels);
}

void GLES2TraceImplementation::WaitAsyncTexImage2DCHROMIUM(GLenum target) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::WaitAsyncTexImage2DCHROMIUM");
  gl_->WaitAsyncTexImage2DCHROMIUM(target);
}

void GLES2TraceImplementation::WaitAllAsyncTexImage2DCHROMIUM() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::WaitAllAsyncTexImage2DCHROMIUM");
  gl_->WaitAllAsyncTexImage2DCHROMIUM();
}

void GLES2TraceImplementation::DiscardFramebufferEXT(
    GLenum target,
    GLsizei count,
    const GLenum* attachments) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DiscardFramebufferEXT");
  gl_->DiscardFramebufferEXT(target, count, attachments);
}

void GLES2TraceImplementation::LoseContextCHROMIUM(GLenum current,
                                                   GLenum other) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::LoseContextCHROMIUM");
  gl_->LoseContextCHROMIUM(current, other);
}

GLuint GLES2TraceImplementation::InsertSyncPointCHROMIUM() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::InsertSyncPointCHROMIUM");
  return gl_->InsertSyncPointCHROMIUM();
}

void GLES2TraceImplementation::WaitSyncPointCHROMIUM(GLuint sync_point) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::WaitSyncPointCHROMIUM");
  gl_->WaitSyncPointCHROMIUM(sync_point);
}

void GLES2TraceImplementation::DrawBuffersEXT(GLsizei count,
                                              const GLenum* bufs) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DrawBuffersEXT");
  gl_->DrawBuffersEXT(count, bufs);
}

void GLES2TraceImplementation::DiscardBackbufferCHROMIUM() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::DiscardBackbufferCHROMIUM");
  gl_->DiscardBackbufferCHROMIUM();
}

void GLES2TraceImplementation::ScheduleOverlayPlaneCHROMIUM(
    GLint plane_z_order,
    GLenum plane_transform,
    GLuint overlay_texture_id,
    GLint bounds_x,
    GLint bounds_y,
    GLint bounds_width,
    GLint bounds_height,
    GLfloat uv_x,
    GLfloat uv_y,
    GLfloat uv_width,
    GLfloat uv_height) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::ScheduleOverlayPlaneCHROMIUM");
  gl_->ScheduleOverlayPlaneCHROMIUM(
      plane_z_order, plane_transform, overlay_texture_id, bounds_x, bounds_y,
      bounds_width, bounds_height, uv_x, uv_y, uv_width, uv_height);
}

void GLES2TraceImplementation::SwapInterval(GLint interval) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::SwapInterval");
  gl_->SwapInterval(interval);
}

void GLES2TraceImplementation::MatrixLoadfCHROMIUM(GLenum matrixMode,
                                                   const GLfloat* m) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::MatrixLoadfCHROMIUM");
  gl_->MatrixLoadfCHROMIUM(matrixMode, m);
}

void GLES2TraceImplementation::MatrixLoadIdentityCHROMIUM(GLenum matrixMode) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "GLES2Trace::MatrixLoadIdentityCHROMIUM");
  gl_->MatrixLoadIdentityCHROMIUM(matrixMode);
}

void GLES2TraceImplementation::BlendBarrierKHR() {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::BlendBarrierKHR");
  gl_->BlendBarrierKHR();
}

#endif  // GPU_COMMAND_BUFFER_CLIENT_GLES2_TRACE_IMPLEMENTATION_IMPL_AUTOGEN_H_
