// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

#include "mojo/gpu/mojo_gles2_impl_autogen.h"

#include "base/logging.h"
#include "mojo/public/c/gles2/gles2.h"
#include "mojo/public/c/gpu/MGL/mgl_onscreen.h"

#define GL_GLEXT_PROTOTYPES
#include "mojo/public/c/gpu/GLES2/gl2.h"
#include "mojo/public/c/gpu/GLES2/gl2ext.h"
#include "mojo/public/c/gpu/GLES2/gl2extmojo.h"

namespace mojo {

void MojoGLES2Impl::ActiveTexture(GLenum texture) {
  MojoGLES2MakeCurrent(context_);
  glActiveTexture(texture);
}
void MojoGLES2Impl::AttachShader(GLuint program, GLuint shader) {
  MojoGLES2MakeCurrent(context_);
  glAttachShader(program, shader);
}
void MojoGLES2Impl::BindAttribLocation(GLuint program,
                                       GLuint index,
                                       const char* name) {
  MojoGLES2MakeCurrent(context_);
  glBindAttribLocation(program, index, name);
}
void MojoGLES2Impl::BindBuffer(GLenum target, GLuint buffer) {
  MojoGLES2MakeCurrent(context_);
  glBindBuffer(target, buffer);
}
void MojoGLES2Impl::BindBufferBase(GLenum target, GLuint index, GLuint buffer) {
  NOTREACHED() << "Unimplemented BindBufferBase.";
}
void MojoGLES2Impl::BindBufferRange(GLenum target,
                                    GLuint index,
                                    GLuint buffer,
                                    GLintptr offset,
                                    GLsizeiptr size) {
  NOTREACHED() << "Unimplemented BindBufferRange.";
}
void MojoGLES2Impl::BindFramebuffer(GLenum target, GLuint framebuffer) {
  MojoGLES2MakeCurrent(context_);
  glBindFramebuffer(target, framebuffer);
}
void MojoGLES2Impl::BindRenderbuffer(GLenum target, GLuint renderbuffer) {
  MojoGLES2MakeCurrent(context_);
  glBindRenderbuffer(target, renderbuffer);
}
void MojoGLES2Impl::BindSampler(GLuint unit, GLuint sampler) {
  NOTREACHED() << "Unimplemented BindSampler.";
}
void MojoGLES2Impl::BindTexture(GLenum target, GLuint texture) {
  MojoGLES2MakeCurrent(context_);
  glBindTexture(target, texture);
}
void MojoGLES2Impl::BindTransformFeedback(GLenum target,
                                          GLuint transformfeedback) {
  NOTREACHED() << "Unimplemented BindTransformFeedback.";
}
void MojoGLES2Impl::BlendColor(GLclampf red,
                               GLclampf green,
                               GLclampf blue,
                               GLclampf alpha) {
  MojoGLES2MakeCurrent(context_);
  glBlendColor(red, green, blue, alpha);
}
void MojoGLES2Impl::BlendEquation(GLenum mode) {
  MojoGLES2MakeCurrent(context_);
  glBlendEquation(mode);
}
void MojoGLES2Impl::BlendEquationSeparate(GLenum modeRGB, GLenum modeAlpha) {
  MojoGLES2MakeCurrent(context_);
  glBlendEquationSeparate(modeRGB, modeAlpha);
}
void MojoGLES2Impl::BlendFunc(GLenum sfactor, GLenum dfactor) {
  MojoGLES2MakeCurrent(context_);
  glBlendFunc(sfactor, dfactor);
}
void MojoGLES2Impl::BlendFuncSeparate(GLenum srcRGB,
                                      GLenum dstRGB,
                                      GLenum srcAlpha,
                                      GLenum dstAlpha) {
  MojoGLES2MakeCurrent(context_);
  glBlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
}
void MojoGLES2Impl::BufferData(GLenum target,
                               GLsizeiptr size,
                               const void* data,
                               GLenum usage) {
  MojoGLES2MakeCurrent(context_);
  glBufferData(target, size, data, usage);
}
void MojoGLES2Impl::BufferSubData(GLenum target,
                                  GLintptr offset,
                                  GLsizeiptr size,
                                  const void* data) {
  MojoGLES2MakeCurrent(context_);
  glBufferSubData(target, offset, size, data);
}
GLenum MojoGLES2Impl::CheckFramebufferStatus(GLenum target) {
  MojoGLES2MakeCurrent(context_);
  return glCheckFramebufferStatus(target);
}
void MojoGLES2Impl::Clear(GLbitfield mask) {
  MojoGLES2MakeCurrent(context_);
  glClear(mask);
}
void MojoGLES2Impl::ClearBufferfi(GLenum buffer,
                                  GLint drawbuffers,
                                  GLfloat depth,
                                  GLint stencil) {
  NOTREACHED() << "Unimplemented ClearBufferfi.";
}
void MojoGLES2Impl::ClearBufferfv(GLenum buffer,
                                  GLint drawbuffers,
                                  const GLfloat* value) {
  NOTREACHED() << "Unimplemented ClearBufferfv.";
}
void MojoGLES2Impl::ClearBufferiv(GLenum buffer,
                                  GLint drawbuffers,
                                  const GLint* value) {
  NOTREACHED() << "Unimplemented ClearBufferiv.";
}
void MojoGLES2Impl::ClearBufferuiv(GLenum buffer,
                                   GLint drawbuffers,
                                   const GLuint* value) {
  NOTREACHED() << "Unimplemented ClearBufferuiv.";
}
void MojoGLES2Impl::ClearColor(GLclampf red,
                               GLclampf green,
                               GLclampf blue,
                               GLclampf alpha) {
  MojoGLES2MakeCurrent(context_);
  glClearColor(red, green, blue, alpha);
}
void MojoGLES2Impl::ClearDepthf(GLclampf depth) {
  MojoGLES2MakeCurrent(context_);
  glClearDepthf(depth);
}
void MojoGLES2Impl::ClearStencil(GLint s) {
  MojoGLES2MakeCurrent(context_);
  glClearStencil(s);
}
GLenum MojoGLES2Impl::ClientWaitSync(GLsync sync,
                                     GLbitfield flags,
                                     GLuint64 timeout) {
  NOTREACHED() << "Unimplemented ClientWaitSync.";
  return 0;
}
void MojoGLES2Impl::ColorMask(GLboolean red,
                              GLboolean green,
                              GLboolean blue,
                              GLboolean alpha) {
  MojoGLES2MakeCurrent(context_);
  glColorMask(red, green, blue, alpha);
}
void MojoGLES2Impl::CompileShader(GLuint shader) {
  MojoGLES2MakeCurrent(context_);
  glCompileShader(shader);
}
void MojoGLES2Impl::CompressedTexImage2D(GLenum target,
                                         GLint level,
                                         GLenum internalformat,
                                         GLsizei width,
                                         GLsizei height,
                                         GLint border,
                                         GLsizei imageSize,
                                         const void* data) {
  MojoGLES2MakeCurrent(context_);
  glCompressedTexImage2D(target, level, internalformat, width, height, border,
                         imageSize, data);
}
void MojoGLES2Impl::CompressedTexSubImage2D(GLenum target,
                                            GLint level,
                                            GLint xoffset,
                                            GLint yoffset,
                                            GLsizei width,
                                            GLsizei height,
                                            GLenum format,
                                            GLsizei imageSize,
                                            const void* data) {
  MojoGLES2MakeCurrent(context_);
  glCompressedTexSubImage2D(target, level, xoffset, yoffset, width, height,
                            format, imageSize, data);
}
void MojoGLES2Impl::CopyBufferSubData(GLenum readtarget,
                                      GLenum writetarget,
                                      GLintptr readoffset,
                                      GLintptr writeoffset,
                                      GLsizeiptr size) {
  NOTREACHED() << "Unimplemented CopyBufferSubData.";
}
void MojoGLES2Impl::CopyTexImage2D(GLenum target,
                                   GLint level,
                                   GLenum internalformat,
                                   GLint x,
                                   GLint y,
                                   GLsizei width,
                                   GLsizei height,
                                   GLint border) {
  MojoGLES2MakeCurrent(context_);
  glCopyTexImage2D(target, level, internalformat, x, y, width, height, border);
}
void MojoGLES2Impl::CopyTexSubImage2D(GLenum target,
                                      GLint level,
                                      GLint xoffset,
                                      GLint yoffset,
                                      GLint x,
                                      GLint y,
                                      GLsizei width,
                                      GLsizei height) {
  MojoGLES2MakeCurrent(context_);
  glCopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
}
void MojoGLES2Impl::CopyTexSubImage3D(GLenum target,
                                      GLint level,
                                      GLint xoffset,
                                      GLint yoffset,
                                      GLint zoffset,
                                      GLint x,
                                      GLint y,
                                      GLsizei width,
                                      GLsizei height) {
  NOTREACHED() << "Unimplemented CopyTexSubImage3D.";
}
GLuint MojoGLES2Impl::CreateProgram() {
  MojoGLES2MakeCurrent(context_);
  return glCreateProgram();
}
GLuint MojoGLES2Impl::CreateShader(GLenum type) {
  MojoGLES2MakeCurrent(context_);
  return glCreateShader(type);
}
void MojoGLES2Impl::CullFace(GLenum mode) {
  MojoGLES2MakeCurrent(context_);
  glCullFace(mode);
}
void MojoGLES2Impl::DeleteBuffers(GLsizei n, const GLuint* buffers) {
  MojoGLES2MakeCurrent(context_);
  glDeleteBuffers(n, buffers);
}
void MojoGLES2Impl::DeleteFramebuffers(GLsizei n, const GLuint* framebuffers) {
  MojoGLES2MakeCurrent(context_);
  glDeleteFramebuffers(n, framebuffers);
}
void MojoGLES2Impl::DeleteProgram(GLuint program) {
  MojoGLES2MakeCurrent(context_);
  glDeleteProgram(program);
}
void MojoGLES2Impl::DeleteRenderbuffers(GLsizei n,
                                        const GLuint* renderbuffers) {
  MojoGLES2MakeCurrent(context_);
  glDeleteRenderbuffers(n, renderbuffers);
}
void MojoGLES2Impl::DeleteSamplers(GLsizei n, const GLuint* samplers) {
  NOTREACHED() << "Unimplemented DeleteSamplers.";
}
void MojoGLES2Impl::DeleteSync(GLsync sync) {
  NOTREACHED() << "Unimplemented DeleteSync.";
}
void MojoGLES2Impl::DeleteShader(GLuint shader) {
  MojoGLES2MakeCurrent(context_);
  glDeleteShader(shader);
}
void MojoGLES2Impl::DeleteTextures(GLsizei n, const GLuint* textures) {
  MojoGLES2MakeCurrent(context_);
  glDeleteTextures(n, textures);
}
void MojoGLES2Impl::DeleteTransformFeedbacks(GLsizei n, const GLuint* ids) {
  NOTREACHED() << "Unimplemented DeleteTransformFeedbacks.";
}
void MojoGLES2Impl::DepthFunc(GLenum func) {
  MojoGLES2MakeCurrent(context_);
  glDepthFunc(func);
}
void MojoGLES2Impl::DepthMask(GLboolean flag) {
  MojoGLES2MakeCurrent(context_);
  glDepthMask(flag);
}
void MojoGLES2Impl::DepthRangef(GLclampf zNear, GLclampf zFar) {
  MojoGLES2MakeCurrent(context_);
  glDepthRangef(zNear, zFar);
}
void MojoGLES2Impl::DetachShader(GLuint program, GLuint shader) {
  MojoGLES2MakeCurrent(context_);
  glDetachShader(program, shader);
}
void MojoGLES2Impl::Disable(GLenum cap) {
  MojoGLES2MakeCurrent(context_);
  glDisable(cap);
}
void MojoGLES2Impl::DisableVertexAttribArray(GLuint index) {
  MojoGLES2MakeCurrent(context_);
  glDisableVertexAttribArray(index);
}
void MojoGLES2Impl::DrawArrays(GLenum mode, GLint first, GLsizei count) {
  MojoGLES2MakeCurrent(context_);
  glDrawArrays(mode, first, count);
}
void MojoGLES2Impl::DrawElements(GLenum mode,
                                 GLsizei count,
                                 GLenum type,
                                 const void* indices) {
  MojoGLES2MakeCurrent(context_);
  glDrawElements(mode, count, type, indices);
}
void MojoGLES2Impl::DrawRangeElements(GLenum mode,
                                      GLuint start,
                                      GLuint end,
                                      GLsizei count,
                                      GLenum type,
                                      const void* indices) {
  NOTREACHED() << "Unimplemented DrawRangeElements.";
}
void MojoGLES2Impl::Enable(GLenum cap) {
  MojoGLES2MakeCurrent(context_);
  glEnable(cap);
}
void MojoGLES2Impl::EnableVertexAttribArray(GLuint index) {
  MojoGLES2MakeCurrent(context_);
  glEnableVertexAttribArray(index);
}
GLsync MojoGLES2Impl::FenceSync(GLenum condition, GLbitfield flags) {
  NOTREACHED() << "Unimplemented FenceSync.";
  return 0;
}
void MojoGLES2Impl::Finish() {
  MojoGLES2MakeCurrent(context_);
  glFinish();
}
void MojoGLES2Impl::Flush() {
  MojoGLES2MakeCurrent(context_);
  glFlush();
}
void MojoGLES2Impl::FramebufferRenderbuffer(GLenum target,
                                            GLenum attachment,
                                            GLenum renderbuffertarget,
                                            GLuint renderbuffer) {
  MojoGLES2MakeCurrent(context_);
  glFramebufferRenderbuffer(target, attachment, renderbuffertarget,
                            renderbuffer);
}
void MojoGLES2Impl::FramebufferTexture2D(GLenum target,
                                         GLenum attachment,
                                         GLenum textarget,
                                         GLuint texture,
                                         GLint level) {
  MojoGLES2MakeCurrent(context_);
  glFramebufferTexture2D(target, attachment, textarget, texture, level);
}
void MojoGLES2Impl::FramebufferTextureLayer(GLenum target,
                                            GLenum attachment,
                                            GLuint texture,
                                            GLint level,
                                            GLint layer) {
  NOTREACHED() << "Unimplemented FramebufferTextureLayer.";
}
void MojoGLES2Impl::FrontFace(GLenum mode) {
  MojoGLES2MakeCurrent(context_);
  glFrontFace(mode);
}
void MojoGLES2Impl::GenBuffers(GLsizei n, GLuint* buffers) {
  MojoGLES2MakeCurrent(context_);
  glGenBuffers(n, buffers);
}
void MojoGLES2Impl::GenerateMipmap(GLenum target) {
  MojoGLES2MakeCurrent(context_);
  glGenerateMipmap(target);
}
void MojoGLES2Impl::GenFramebuffers(GLsizei n, GLuint* framebuffers) {
  MojoGLES2MakeCurrent(context_);
  glGenFramebuffers(n, framebuffers);
}
void MojoGLES2Impl::GenRenderbuffers(GLsizei n, GLuint* renderbuffers) {
  MojoGLES2MakeCurrent(context_);
  glGenRenderbuffers(n, renderbuffers);
}
void MojoGLES2Impl::GenSamplers(GLsizei n, GLuint* samplers) {
  NOTREACHED() << "Unimplemented GenSamplers.";
}
void MojoGLES2Impl::GenTextures(GLsizei n, GLuint* textures) {
  MojoGLES2MakeCurrent(context_);
  glGenTextures(n, textures);
}
void MojoGLES2Impl::GenTransformFeedbacks(GLsizei n, GLuint* ids) {
  NOTREACHED() << "Unimplemented GenTransformFeedbacks.";
}
void MojoGLES2Impl::GetActiveAttrib(GLuint program,
                                    GLuint index,
                                    GLsizei bufsize,
                                    GLsizei* length,
                                    GLint* size,
                                    GLenum* type,
                                    char* name) {
  MojoGLES2MakeCurrent(context_);
  glGetActiveAttrib(program, index, bufsize, length, size, type, name);
}
void MojoGLES2Impl::GetActiveUniform(GLuint program,
                                     GLuint index,
                                     GLsizei bufsize,
                                     GLsizei* length,
                                     GLint* size,
                                     GLenum* type,
                                     char* name) {
  MojoGLES2MakeCurrent(context_);
  glGetActiveUniform(program, index, bufsize, length, size, type, name);
}
void MojoGLES2Impl::GetActiveUniformBlockiv(GLuint program,
                                            GLuint index,
                                            GLenum pname,
                                            GLint* params) {
  NOTREACHED() << "Unimplemented GetActiveUniformBlockiv.";
}
void MojoGLES2Impl::GetActiveUniformBlockName(GLuint program,
                                              GLuint index,
                                              GLsizei bufsize,
                                              GLsizei* length,
                                              char* name) {
  NOTREACHED() << "Unimplemented GetActiveUniformBlockName.";
}
void MojoGLES2Impl::GetActiveUniformsiv(GLuint program,
                                        GLsizei count,
                                        const GLuint* indices,
                                        GLenum pname,
                                        GLint* params) {
  NOTREACHED() << "Unimplemented GetActiveUniformsiv.";
}
void MojoGLES2Impl::GetAttachedShaders(GLuint program,
                                       GLsizei maxcount,
                                       GLsizei* count,
                                       GLuint* shaders) {
  MojoGLES2MakeCurrent(context_);
  glGetAttachedShaders(program, maxcount, count, shaders);
}
GLint MojoGLES2Impl::GetAttribLocation(GLuint program, const char* name) {
  MojoGLES2MakeCurrent(context_);
  return glGetAttribLocation(program, name);
}
void MojoGLES2Impl::GetBooleanv(GLenum pname, GLboolean* params) {
  MojoGLES2MakeCurrent(context_);
  glGetBooleanv(pname, params);
}
void MojoGLES2Impl::GetBufferParameteriv(GLenum target,
                                         GLenum pname,
                                         GLint* params) {
  MojoGLES2MakeCurrent(context_);
  glGetBufferParameteriv(target, pname, params);
}
GLenum MojoGLES2Impl::GetError() {
  MojoGLES2MakeCurrent(context_);
  return glGetError();
}
void MojoGLES2Impl::GetFloatv(GLenum pname, GLfloat* params) {
  MojoGLES2MakeCurrent(context_);
  glGetFloatv(pname, params);
}
GLint MojoGLES2Impl::GetFragDataLocation(GLuint program, const char* name) {
  NOTREACHED() << "Unimplemented GetFragDataLocation.";
  return 0;
}
void MojoGLES2Impl::GetFramebufferAttachmentParameteriv(GLenum target,
                                                        GLenum attachment,
                                                        GLenum pname,
                                                        GLint* params) {
  MojoGLES2MakeCurrent(context_);
  glGetFramebufferAttachmentParameteriv(target, attachment, pname, params);
}
void MojoGLES2Impl::GetInteger64v(GLenum pname, GLint64* params) {
  NOTREACHED() << "Unimplemented GetInteger64v.";
}
void MojoGLES2Impl::GetIntegeri_v(GLenum pname, GLuint index, GLint* data) {
  NOTREACHED() << "Unimplemented GetIntegeri_v.";
}
void MojoGLES2Impl::GetInteger64i_v(GLenum pname, GLuint index, GLint64* data) {
  NOTREACHED() << "Unimplemented GetInteger64i_v.";
}
void MojoGLES2Impl::GetIntegerv(GLenum pname, GLint* params) {
  MojoGLES2MakeCurrent(context_);
  glGetIntegerv(pname, params);
}
void MojoGLES2Impl::GetInternalformativ(GLenum target,
                                        GLenum format,
                                        GLenum pname,
                                        GLsizei bufSize,
                                        GLint* params) {
  NOTREACHED() << "Unimplemented GetInternalformativ.";
}
void MojoGLES2Impl::GetProgramiv(GLuint program, GLenum pname, GLint* params) {
  MojoGLES2MakeCurrent(context_);
  glGetProgramiv(program, pname, params);
}
void MojoGLES2Impl::GetProgramInfoLog(GLuint program,
                                      GLsizei bufsize,
                                      GLsizei* length,
                                      char* infolog) {
  MojoGLES2MakeCurrent(context_);
  glGetProgramInfoLog(program, bufsize, length, infolog);
}
void MojoGLES2Impl::GetRenderbufferParameteriv(GLenum target,
                                               GLenum pname,
                                               GLint* params) {
  MojoGLES2MakeCurrent(context_);
  glGetRenderbufferParameteriv(target, pname, params);
}
void MojoGLES2Impl::GetSamplerParameterfv(GLuint sampler,
                                          GLenum pname,
                                          GLfloat* params) {
  NOTREACHED() << "Unimplemented GetSamplerParameterfv.";
}
void MojoGLES2Impl::GetSamplerParameteriv(GLuint sampler,
                                          GLenum pname,
                                          GLint* params) {
  NOTREACHED() << "Unimplemented GetSamplerParameteriv.";
}
void MojoGLES2Impl::GetShaderiv(GLuint shader, GLenum pname, GLint* params) {
  MojoGLES2MakeCurrent(context_);
  glGetShaderiv(shader, pname, params);
}
void MojoGLES2Impl::GetShaderInfoLog(GLuint shader,
                                     GLsizei bufsize,
                                     GLsizei* length,
                                     char* infolog) {
  MojoGLES2MakeCurrent(context_);
  glGetShaderInfoLog(shader, bufsize, length, infolog);
}
void MojoGLES2Impl::GetShaderPrecisionFormat(GLenum shadertype,
                                             GLenum precisiontype,
                                             GLint* range,
                                             GLint* precision) {
  MojoGLES2MakeCurrent(context_);
  glGetShaderPrecisionFormat(shadertype, precisiontype, range, precision);
}
void MojoGLES2Impl::GetShaderSource(GLuint shader,
                                    GLsizei bufsize,
                                    GLsizei* length,
                                    char* source) {
  MojoGLES2MakeCurrent(context_);
  glGetShaderSource(shader, bufsize, length, source);
}
const GLubyte* MojoGLES2Impl::GetString(GLenum name) {
  MojoGLES2MakeCurrent(context_);
  return glGetString(name);
}
void MojoGLES2Impl::GetSynciv(GLsync sync,
                              GLenum pname,
                              GLsizei bufsize,
                              GLsizei* length,
                              GLint* values) {
  NOTREACHED() << "Unimplemented GetSynciv.";
}
void MojoGLES2Impl::GetTexParameterfv(GLenum target,
                                      GLenum pname,
                                      GLfloat* params) {
  MojoGLES2MakeCurrent(context_);
  glGetTexParameterfv(target, pname, params);
}
void MojoGLES2Impl::GetTexParameteriv(GLenum target,
                                      GLenum pname,
                                      GLint* params) {
  MojoGLES2MakeCurrent(context_);
  glGetTexParameteriv(target, pname, params);
}
void MojoGLES2Impl::GetTransformFeedbackVarying(GLuint program,
                                                GLuint index,
                                                GLsizei bufsize,
                                                GLsizei* length,
                                                GLsizei* size,
                                                GLenum* type,
                                                char* name) {
  NOTREACHED() << "Unimplemented GetTransformFeedbackVarying.";
}
GLuint MojoGLES2Impl::GetUniformBlockIndex(GLuint program, const char* name) {
  NOTREACHED() << "Unimplemented GetUniformBlockIndex.";
  return 0;
}
void MojoGLES2Impl::GetUniformfv(GLuint program,
                                 GLint location,
                                 GLfloat* params) {
  MojoGLES2MakeCurrent(context_);
  glGetUniformfv(program, location, params);
}
void MojoGLES2Impl::GetUniformiv(GLuint program,
                                 GLint location,
                                 GLint* params) {
  MojoGLES2MakeCurrent(context_);
  glGetUniformiv(program, location, params);
}
void MojoGLES2Impl::GetUniformIndices(GLuint program,
                                      GLsizei count,
                                      const char* const* names,
                                      GLuint* indices) {
  NOTREACHED() << "Unimplemented GetUniformIndices.";
}
GLint MojoGLES2Impl::GetUniformLocation(GLuint program, const char* name) {
  MojoGLES2MakeCurrent(context_);
  return glGetUniformLocation(program, name);
}
void MojoGLES2Impl::GetVertexAttribfv(GLuint index,
                                      GLenum pname,
                                      GLfloat* params) {
  MojoGLES2MakeCurrent(context_);
  glGetVertexAttribfv(index, pname, params);
}
void MojoGLES2Impl::GetVertexAttribiv(GLuint index,
                                      GLenum pname,
                                      GLint* params) {
  MojoGLES2MakeCurrent(context_);
  glGetVertexAttribiv(index, pname, params);
}
void MojoGLES2Impl::GetVertexAttribPointerv(GLuint index,
                                            GLenum pname,
                                            void** pointer) {
  MojoGLES2MakeCurrent(context_);
  glGetVertexAttribPointerv(index, pname, pointer);
}
void MojoGLES2Impl::Hint(GLenum target, GLenum mode) {
  MojoGLES2MakeCurrent(context_);
  glHint(target, mode);
}
void MojoGLES2Impl::InvalidateFramebuffer(GLenum target,
                                          GLsizei count,
                                          const GLenum* attachments) {
  NOTREACHED() << "Unimplemented InvalidateFramebuffer.";
}
void MojoGLES2Impl::InvalidateSubFramebuffer(GLenum target,
                                             GLsizei count,
                                             const GLenum* attachments,
                                             GLint x,
                                             GLint y,
                                             GLsizei width,
                                             GLsizei height) {
  NOTREACHED() << "Unimplemented InvalidateSubFramebuffer.";
}
GLboolean MojoGLES2Impl::IsBuffer(GLuint buffer) {
  MojoGLES2MakeCurrent(context_);
  return glIsBuffer(buffer);
}
GLboolean MojoGLES2Impl::IsEnabled(GLenum cap) {
  MojoGLES2MakeCurrent(context_);
  return glIsEnabled(cap);
}
GLboolean MojoGLES2Impl::IsFramebuffer(GLuint framebuffer) {
  MojoGLES2MakeCurrent(context_);
  return glIsFramebuffer(framebuffer);
}
GLboolean MojoGLES2Impl::IsProgram(GLuint program) {
  MojoGLES2MakeCurrent(context_);
  return glIsProgram(program);
}
GLboolean MojoGLES2Impl::IsRenderbuffer(GLuint renderbuffer) {
  MojoGLES2MakeCurrent(context_);
  return glIsRenderbuffer(renderbuffer);
}
GLboolean MojoGLES2Impl::IsSampler(GLuint sampler) {
  NOTREACHED() << "Unimplemented IsSampler.";
  return 0;
}
GLboolean MojoGLES2Impl::IsShader(GLuint shader) {
  MojoGLES2MakeCurrent(context_);
  return glIsShader(shader);
}
GLboolean MojoGLES2Impl::IsSync(GLsync sync) {
  NOTREACHED() << "Unimplemented IsSync.";
  return 0;
}
GLboolean MojoGLES2Impl::IsTexture(GLuint texture) {
  MojoGLES2MakeCurrent(context_);
  return glIsTexture(texture);
}
GLboolean MojoGLES2Impl::IsTransformFeedback(GLuint transformfeedback) {
  NOTREACHED() << "Unimplemented IsTransformFeedback.";
  return 0;
}
void MojoGLES2Impl::LineWidth(GLfloat width) {
  MojoGLES2MakeCurrent(context_);
  glLineWidth(width);
}
void MojoGLES2Impl::LinkProgram(GLuint program) {
  MojoGLES2MakeCurrent(context_);
  glLinkProgram(program);
}
void MojoGLES2Impl::PauseTransformFeedback() {
  NOTREACHED() << "Unimplemented PauseTransformFeedback.";
}
void MojoGLES2Impl::PixelStorei(GLenum pname, GLint param) {
  MojoGLES2MakeCurrent(context_);
  glPixelStorei(pname, param);
}
void MojoGLES2Impl::PolygonOffset(GLfloat factor, GLfloat units) {
  MojoGLES2MakeCurrent(context_);
  glPolygonOffset(factor, units);
}
void MojoGLES2Impl::ReadBuffer(GLenum src) {
  NOTREACHED() << "Unimplemented ReadBuffer.";
}
void MojoGLES2Impl::ReadPixels(GLint x,
                               GLint y,
                               GLsizei width,
                               GLsizei height,
                               GLenum format,
                               GLenum type,
                               void* pixels) {
  MojoGLES2MakeCurrent(context_);
  glReadPixels(x, y, width, height, format, type, pixels);
}
void MojoGLES2Impl::ReleaseShaderCompiler() {
  MojoGLES2MakeCurrent(context_);
  glReleaseShaderCompiler();
}
void MojoGLES2Impl::RenderbufferStorage(GLenum target,
                                        GLenum internalformat,
                                        GLsizei width,
                                        GLsizei height) {
  MojoGLES2MakeCurrent(context_);
  glRenderbufferStorage(target, internalformat, width, height);
}
void MojoGLES2Impl::ResumeTransformFeedback() {
  NOTREACHED() << "Unimplemented ResumeTransformFeedback.";
}
void MojoGLES2Impl::SampleCoverage(GLclampf value, GLboolean invert) {
  MojoGLES2MakeCurrent(context_);
  glSampleCoverage(value, invert);
}
void MojoGLES2Impl::SamplerParameterf(GLuint sampler,
                                      GLenum pname,
                                      GLfloat param) {
  NOTREACHED() << "Unimplemented SamplerParameterf.";
}
void MojoGLES2Impl::SamplerParameterfv(GLuint sampler,
                                       GLenum pname,
                                       const GLfloat* params) {
  NOTREACHED() << "Unimplemented SamplerParameterfv.";
}
void MojoGLES2Impl::SamplerParameteri(GLuint sampler,
                                      GLenum pname,
                                      GLint param) {
  NOTREACHED() << "Unimplemented SamplerParameteri.";
}
void MojoGLES2Impl::SamplerParameteriv(GLuint sampler,
                                       GLenum pname,
                                       const GLint* params) {
  NOTREACHED() << "Unimplemented SamplerParameteriv.";
}
void MojoGLES2Impl::Scissor(GLint x, GLint y, GLsizei width, GLsizei height) {
  MojoGLES2MakeCurrent(context_);
  glScissor(x, y, width, height);
}
void MojoGLES2Impl::ShaderBinary(GLsizei n,
                                 const GLuint* shaders,
                                 GLenum binaryformat,
                                 const void* binary,
                                 GLsizei length) {
  MojoGLES2MakeCurrent(context_);
  glShaderBinary(n, shaders, binaryformat, binary, length);
}
void MojoGLES2Impl::ShaderSource(GLuint shader,
                                 GLsizei count,
                                 const GLchar* const* str,
                                 const GLint* length) {
  MojoGLES2MakeCurrent(context_);
  glShaderSource(shader, count, str, length);
}
void MojoGLES2Impl::ShallowFinishCHROMIUM() {
  NOTREACHED() << "Unimplemented ShallowFinishCHROMIUM.";
}
void MojoGLES2Impl::ShallowFlushCHROMIUM() {
  MojoGLES2MakeCurrent(context_);
  glShallowFlushCHROMIUM();
}
void MojoGLES2Impl::OrderingBarrierCHROMIUM() {
  NOTREACHED() << "Unimplemented OrderingBarrierCHROMIUM.";
}
void MojoGLES2Impl::StencilFunc(GLenum func, GLint ref, GLuint mask) {
  MojoGLES2MakeCurrent(context_);
  glStencilFunc(func, ref, mask);
}
void MojoGLES2Impl::StencilFuncSeparate(GLenum face,
                                        GLenum func,
                                        GLint ref,
                                        GLuint mask) {
  MojoGLES2MakeCurrent(context_);
  glStencilFuncSeparate(face, func, ref, mask);
}
void MojoGLES2Impl::StencilMask(GLuint mask) {
  MojoGLES2MakeCurrent(context_);
  glStencilMask(mask);
}
void MojoGLES2Impl::StencilMaskSeparate(GLenum face, GLuint mask) {
  MojoGLES2MakeCurrent(context_);
  glStencilMaskSeparate(face, mask);
}
void MojoGLES2Impl::StencilOp(GLenum fail, GLenum zfail, GLenum zpass) {
  MojoGLES2MakeCurrent(context_);
  glStencilOp(fail, zfail, zpass);
}
void MojoGLES2Impl::StencilOpSeparate(GLenum face,
                                      GLenum fail,
                                      GLenum zfail,
                                      GLenum zpass) {
  MojoGLES2MakeCurrent(context_);
  glStencilOpSeparate(face, fail, zfail, zpass);
}
void MojoGLES2Impl::TexImage2D(GLenum target,
                               GLint level,
                               GLint internalformat,
                               GLsizei width,
                               GLsizei height,
                               GLint border,
                               GLenum format,
                               GLenum type,
                               const void* pixels) {
  MojoGLES2MakeCurrent(context_);
  glTexImage2D(target, level, internalformat, width, height, border, format,
               type, pixels);
}
void MojoGLES2Impl::TexImage3D(GLenum target,
                               GLint level,
                               GLint internalformat,
                               GLsizei width,
                               GLsizei height,
                               GLsizei depth,
                               GLint border,
                               GLenum format,
                               GLenum type,
                               const void* pixels) {
  NOTREACHED() << "Unimplemented TexImage3D.";
}
void MojoGLES2Impl::TexParameterf(GLenum target, GLenum pname, GLfloat param) {
  MojoGLES2MakeCurrent(context_);
  glTexParameterf(target, pname, param);
}
void MojoGLES2Impl::TexParameterfv(GLenum target,
                                   GLenum pname,
                                   const GLfloat* params) {
  MojoGLES2MakeCurrent(context_);
  glTexParameterfv(target, pname, params);
}
void MojoGLES2Impl::TexParameteri(GLenum target, GLenum pname, GLint param) {
  MojoGLES2MakeCurrent(context_);
  glTexParameteri(target, pname, param);
}
void MojoGLES2Impl::TexParameteriv(GLenum target,
                                   GLenum pname,
                                   const GLint* params) {
  MojoGLES2MakeCurrent(context_);
  glTexParameteriv(target, pname, params);
}
void MojoGLES2Impl::TexStorage3D(GLenum target,
                                 GLsizei levels,
                                 GLenum internalFormat,
                                 GLsizei width,
                                 GLsizei height,
                                 GLsizei depth) {
  NOTREACHED() << "Unimplemented TexStorage3D.";
}
void MojoGLES2Impl::TexSubImage2D(GLenum target,
                                  GLint level,
                                  GLint xoffset,
                                  GLint yoffset,
                                  GLsizei width,
                                  GLsizei height,
                                  GLenum format,
                                  GLenum type,
                                  const void* pixels) {
  MojoGLES2MakeCurrent(context_);
  glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type,
                  pixels);
}
void MojoGLES2Impl::TexSubImage3D(GLenum target,
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
  NOTREACHED() << "Unimplemented TexSubImage3D.";
}
void MojoGLES2Impl::TransformFeedbackVaryings(GLuint program,
                                              GLsizei count,
                                              const char* const* varyings,
                                              GLenum buffermode) {
  NOTREACHED() << "Unimplemented TransformFeedbackVaryings.";
}
void MojoGLES2Impl::Uniform1f(GLint location, GLfloat x) {
  MojoGLES2MakeCurrent(context_);
  glUniform1f(location, x);
}
void MojoGLES2Impl::Uniform1fv(GLint location,
                               GLsizei count,
                               const GLfloat* v) {
  MojoGLES2MakeCurrent(context_);
  glUniform1fv(location, count, v);
}
void MojoGLES2Impl::Uniform1i(GLint location, GLint x) {
  MojoGLES2MakeCurrent(context_);
  glUniform1i(location, x);
}
void MojoGLES2Impl::Uniform1iv(GLint location, GLsizei count, const GLint* v) {
  MojoGLES2MakeCurrent(context_);
  glUniform1iv(location, count, v);
}
void MojoGLES2Impl::Uniform1ui(GLint location, GLuint x) {
  NOTREACHED() << "Unimplemented Uniform1ui.";
}
void MojoGLES2Impl::Uniform1uiv(GLint location,
                                GLsizei count,
                                const GLuint* v) {
  NOTREACHED() << "Unimplemented Uniform1uiv.";
}
void MojoGLES2Impl::Uniform2f(GLint location, GLfloat x, GLfloat y) {
  MojoGLES2MakeCurrent(context_);
  glUniform2f(location, x, y);
}
void MojoGLES2Impl::Uniform2fv(GLint location,
                               GLsizei count,
                               const GLfloat* v) {
  MojoGLES2MakeCurrent(context_);
  glUniform2fv(location, count, v);
}
void MojoGLES2Impl::Uniform2i(GLint location, GLint x, GLint y) {
  MojoGLES2MakeCurrent(context_);
  glUniform2i(location, x, y);
}
void MojoGLES2Impl::Uniform2iv(GLint location, GLsizei count, const GLint* v) {
  MojoGLES2MakeCurrent(context_);
  glUniform2iv(location, count, v);
}
void MojoGLES2Impl::Uniform2ui(GLint location, GLuint x, GLuint y) {
  NOTREACHED() << "Unimplemented Uniform2ui.";
}
void MojoGLES2Impl::Uniform2uiv(GLint location,
                                GLsizei count,
                                const GLuint* v) {
  NOTREACHED() << "Unimplemented Uniform2uiv.";
}
void MojoGLES2Impl::Uniform3f(GLint location, GLfloat x, GLfloat y, GLfloat z) {
  MojoGLES2MakeCurrent(context_);
  glUniform3f(location, x, y, z);
}
void MojoGLES2Impl::Uniform3fv(GLint location,
                               GLsizei count,
                               const GLfloat* v) {
  MojoGLES2MakeCurrent(context_);
  glUniform3fv(location, count, v);
}
void MojoGLES2Impl::Uniform3i(GLint location, GLint x, GLint y, GLint z) {
  MojoGLES2MakeCurrent(context_);
  glUniform3i(location, x, y, z);
}
void MojoGLES2Impl::Uniform3iv(GLint location, GLsizei count, const GLint* v) {
  MojoGLES2MakeCurrent(context_);
  glUniform3iv(location, count, v);
}
void MojoGLES2Impl::Uniform3ui(GLint location, GLuint x, GLuint y, GLuint z) {
  NOTREACHED() << "Unimplemented Uniform3ui.";
}
void MojoGLES2Impl::Uniform3uiv(GLint location,
                                GLsizei count,
                                const GLuint* v) {
  NOTREACHED() << "Unimplemented Uniform3uiv.";
}
void MojoGLES2Impl::Uniform4f(GLint location,
                              GLfloat x,
                              GLfloat y,
                              GLfloat z,
                              GLfloat w) {
  MojoGLES2MakeCurrent(context_);
  glUniform4f(location, x, y, z, w);
}
void MojoGLES2Impl::Uniform4fv(GLint location,
                               GLsizei count,
                               const GLfloat* v) {
  MojoGLES2MakeCurrent(context_);
  glUniform4fv(location, count, v);
}
void MojoGLES2Impl::Uniform4i(GLint location,
                              GLint x,
                              GLint y,
                              GLint z,
                              GLint w) {
  MojoGLES2MakeCurrent(context_);
  glUniform4i(location, x, y, z, w);
}
void MojoGLES2Impl::Uniform4iv(GLint location, GLsizei count, const GLint* v) {
  MojoGLES2MakeCurrent(context_);
  glUniform4iv(location, count, v);
}
void MojoGLES2Impl::Uniform4ui(GLint location,
                               GLuint x,
                               GLuint y,
                               GLuint z,
                               GLuint w) {
  NOTREACHED() << "Unimplemented Uniform4ui.";
}
void MojoGLES2Impl::Uniform4uiv(GLint location,
                                GLsizei count,
                                const GLuint* v) {
  NOTREACHED() << "Unimplemented Uniform4uiv.";
}
void MojoGLES2Impl::UniformBlockBinding(GLuint program,
                                        GLuint index,
                                        GLuint binding) {
  NOTREACHED() << "Unimplemented UniformBlockBinding.";
}
void MojoGLES2Impl::UniformMatrix2fv(GLint location,
                                     GLsizei count,
                                     GLboolean transpose,
                                     const GLfloat* value) {
  MojoGLES2MakeCurrent(context_);
  glUniformMatrix2fv(location, count, transpose, value);
}
void MojoGLES2Impl::UniformMatrix2x3fv(GLint location,
                                       GLsizei count,
                                       GLboolean transpose,
                                       const GLfloat* value) {
  NOTREACHED() << "Unimplemented UniformMatrix2x3fv.";
}
void MojoGLES2Impl::UniformMatrix2x4fv(GLint location,
                                       GLsizei count,
                                       GLboolean transpose,
                                       const GLfloat* value) {
  NOTREACHED() << "Unimplemented UniformMatrix2x4fv.";
}
void MojoGLES2Impl::UniformMatrix3fv(GLint location,
                                     GLsizei count,
                                     GLboolean transpose,
                                     const GLfloat* value) {
  MojoGLES2MakeCurrent(context_);
  glUniformMatrix3fv(location, count, transpose, value);
}
void MojoGLES2Impl::UniformMatrix3x2fv(GLint location,
                                       GLsizei count,
                                       GLboolean transpose,
                                       const GLfloat* value) {
  NOTREACHED() << "Unimplemented UniformMatrix3x2fv.";
}
void MojoGLES2Impl::UniformMatrix3x4fv(GLint location,
                                       GLsizei count,
                                       GLboolean transpose,
                                       const GLfloat* value) {
  NOTREACHED() << "Unimplemented UniformMatrix3x4fv.";
}
void MojoGLES2Impl::UniformMatrix4fv(GLint location,
                                     GLsizei count,
                                     GLboolean transpose,
                                     const GLfloat* value) {
  MojoGLES2MakeCurrent(context_);
  glUniformMatrix4fv(location, count, transpose, value);
}
void MojoGLES2Impl::UniformMatrix4x2fv(GLint location,
                                       GLsizei count,
                                       GLboolean transpose,
                                       const GLfloat* value) {
  NOTREACHED() << "Unimplemented UniformMatrix4x2fv.";
}
void MojoGLES2Impl::UniformMatrix4x3fv(GLint location,
                                       GLsizei count,
                                       GLboolean transpose,
                                       const GLfloat* value) {
  NOTREACHED() << "Unimplemented UniformMatrix4x3fv.";
}
void MojoGLES2Impl::UseProgram(GLuint program) {
  MojoGLES2MakeCurrent(context_);
  glUseProgram(program);
}
void MojoGLES2Impl::ValidateProgram(GLuint program) {
  MojoGLES2MakeCurrent(context_);
  glValidateProgram(program);
}
void MojoGLES2Impl::VertexAttrib1f(GLuint indx, GLfloat x) {
  MojoGLES2MakeCurrent(context_);
  glVertexAttrib1f(indx, x);
}
void MojoGLES2Impl::VertexAttrib1fv(GLuint indx, const GLfloat* values) {
  MojoGLES2MakeCurrent(context_);
  glVertexAttrib1fv(indx, values);
}
void MojoGLES2Impl::VertexAttrib2f(GLuint indx, GLfloat x, GLfloat y) {
  MojoGLES2MakeCurrent(context_);
  glVertexAttrib2f(indx, x, y);
}
void MojoGLES2Impl::VertexAttrib2fv(GLuint indx, const GLfloat* values) {
  MojoGLES2MakeCurrent(context_);
  glVertexAttrib2fv(indx, values);
}
void MojoGLES2Impl::VertexAttrib3f(GLuint indx,
                                   GLfloat x,
                                   GLfloat y,
                                   GLfloat z) {
  MojoGLES2MakeCurrent(context_);
  glVertexAttrib3f(indx, x, y, z);
}
void MojoGLES2Impl::VertexAttrib3fv(GLuint indx, const GLfloat* values) {
  MojoGLES2MakeCurrent(context_);
  glVertexAttrib3fv(indx, values);
}
void MojoGLES2Impl::VertexAttrib4f(GLuint indx,
                                   GLfloat x,
                                   GLfloat y,
                                   GLfloat z,
                                   GLfloat w) {
  MojoGLES2MakeCurrent(context_);
  glVertexAttrib4f(indx, x, y, z, w);
}
void MojoGLES2Impl::VertexAttrib4fv(GLuint indx, const GLfloat* values) {
  MojoGLES2MakeCurrent(context_);
  glVertexAttrib4fv(indx, values);
}
void MojoGLES2Impl::VertexAttribI4i(GLuint indx,
                                    GLint x,
                                    GLint y,
                                    GLint z,
                                    GLint w) {
  NOTREACHED() << "Unimplemented VertexAttribI4i.";
}
void MojoGLES2Impl::VertexAttribI4iv(GLuint indx, const GLint* values) {
  NOTREACHED() << "Unimplemented VertexAttribI4iv.";
}
void MojoGLES2Impl::VertexAttribI4ui(GLuint indx,
                                     GLuint x,
                                     GLuint y,
                                     GLuint z,
                                     GLuint w) {
  NOTREACHED() << "Unimplemented VertexAttribI4ui.";
}
void MojoGLES2Impl::VertexAttribI4uiv(GLuint indx, const GLuint* values) {
  NOTREACHED() << "Unimplemented VertexAttribI4uiv.";
}
void MojoGLES2Impl::VertexAttribIPointer(GLuint indx,
                                         GLint size,
                                         GLenum type,
                                         GLsizei stride,
                                         const void* ptr) {
  NOTREACHED() << "Unimplemented VertexAttribIPointer.";
}
void MojoGLES2Impl::VertexAttribPointer(GLuint indx,
                                        GLint size,
                                        GLenum type,
                                        GLboolean normalized,
                                        GLsizei stride,
                                        const void* ptr) {
  MojoGLES2MakeCurrent(context_);
  glVertexAttribPointer(indx, size, type, normalized, stride, ptr);
}
void MojoGLES2Impl::Viewport(GLint x, GLint y, GLsizei width, GLsizei height) {
  MojoGLES2MakeCurrent(context_);
  glViewport(x, y, width, height);
}
void MojoGLES2Impl::WaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout) {
  NOTREACHED() << "Unimplemented WaitSync.";
}
void MojoGLES2Impl::BlitFramebufferCHROMIUM(GLint srcX0,
                                            GLint srcY0,
                                            GLint srcX1,
                                            GLint srcY1,
                                            GLint dstX0,
                                            GLint dstY0,
                                            GLint dstX1,
                                            GLint dstY1,
                                            GLbitfield mask,
                                            GLenum filter) {
  NOTREACHED() << "Unimplemented BlitFramebufferCHROMIUM.";
}
void MojoGLES2Impl::RenderbufferStorageMultisampleCHROMIUM(
    GLenum target,
    GLsizei samples,
    GLenum internalformat,
    GLsizei width,
    GLsizei height) {
  NOTREACHED() << "Unimplemented RenderbufferStorageMultisampleCHROMIUM.";
}
void MojoGLES2Impl::RenderbufferStorageMultisampleEXT(GLenum target,
                                                      GLsizei samples,
                                                      GLenum internalformat,
                                                      GLsizei width,
                                                      GLsizei height) {
  NOTREACHED() << "Unimplemented RenderbufferStorageMultisampleEXT.";
}
void MojoGLES2Impl::FramebufferTexture2DMultisampleEXT(GLenum target,
                                                       GLenum attachment,
                                                       GLenum textarget,
                                                       GLuint texture,
                                                       GLint level,
                                                       GLsizei samples) {
  NOTREACHED() << "Unimplemented FramebufferTexture2DMultisampleEXT.";
}
void MojoGLES2Impl::TexStorage2DEXT(GLenum target,
                                    GLsizei levels,
                                    GLenum internalFormat,
                                    GLsizei width,
                                    GLsizei height) {
  NOTREACHED() << "Unimplemented TexStorage2DEXT.";
}
void MojoGLES2Impl::GenQueriesEXT(GLsizei n, GLuint* queries) {
  MojoGLES2MakeCurrent(context_);
  glGenQueriesEXT(n, queries);
}
void MojoGLES2Impl::DeleteQueriesEXT(GLsizei n, const GLuint* queries) {
  MojoGLES2MakeCurrent(context_);
  glDeleteQueriesEXT(n, queries);
}
GLboolean MojoGLES2Impl::IsQueryEXT(GLuint id) {
  MojoGLES2MakeCurrent(context_);
  return glIsQueryEXT(id);
}
void MojoGLES2Impl::BeginQueryEXT(GLenum target, GLuint id) {
  MojoGLES2MakeCurrent(context_);
  glBeginQueryEXT(target, id);
}
void MojoGLES2Impl::BeginTransformFeedback(GLenum primitivemode) {
  NOTREACHED() << "Unimplemented BeginTransformFeedback.";
}
void MojoGLES2Impl::EndQueryEXT(GLenum target) {
  MojoGLES2MakeCurrent(context_);
  glEndQueryEXT(target);
}
void MojoGLES2Impl::EndTransformFeedback() {
  NOTREACHED() << "Unimplemented EndTransformFeedback.";
}
void MojoGLES2Impl::GetQueryivEXT(GLenum target, GLenum pname, GLint* params) {
  MojoGLES2MakeCurrent(context_);
  glGetQueryivEXT(target, pname, params);
}
void MojoGLES2Impl::GetQueryObjectuivEXT(GLuint id,
                                         GLenum pname,
                                         GLuint* params) {
  MojoGLES2MakeCurrent(context_);
  glGetQueryObjectuivEXT(id, pname, params);
}
void MojoGLES2Impl::InsertEventMarkerEXT(GLsizei length, const GLchar* marker) {
  MojoGLES2MakeCurrent(context_);
  glInsertEventMarkerEXT(length, marker);
}
void MojoGLES2Impl::PushGroupMarkerEXT(GLsizei length, const GLchar* marker) {
  MojoGLES2MakeCurrent(context_);
  glPushGroupMarkerEXT(length, marker);
}
void MojoGLES2Impl::PopGroupMarkerEXT() {
  MojoGLES2MakeCurrent(context_);
  glPopGroupMarkerEXT();
}
void MojoGLES2Impl::GenVertexArraysOES(GLsizei n, GLuint* arrays) {
  MojoGLES2MakeCurrent(context_);
  glGenVertexArraysOES(n, arrays);
}
void MojoGLES2Impl::DeleteVertexArraysOES(GLsizei n, const GLuint* arrays) {
  MojoGLES2MakeCurrent(context_);
  glDeleteVertexArraysOES(n, arrays);
}
GLboolean MojoGLES2Impl::IsVertexArrayOES(GLuint array) {
  MojoGLES2MakeCurrent(context_);
  return glIsVertexArrayOES(array);
}
void MojoGLES2Impl::BindVertexArrayOES(GLuint array) {
  MojoGLES2MakeCurrent(context_);
  glBindVertexArrayOES(array);
}
void MojoGLES2Impl::SwapBuffers() {
  NOTREACHED() << "Unimplemented SwapBuffers.";
}
GLuint MojoGLES2Impl::GetMaxValueInBufferCHROMIUM(GLuint buffer_id,
                                                  GLsizei count,
                                                  GLenum type,
                                                  GLuint offset) {
  NOTREACHED() << "Unimplemented GetMaxValueInBufferCHROMIUM.";
  return 0;
}
GLboolean MojoGLES2Impl::EnableFeatureCHROMIUM(const char* feature) {
  NOTREACHED() << "Unimplemented EnableFeatureCHROMIUM.";
  return 0;
}
void* MojoGLES2Impl::MapBufferCHROMIUM(GLuint target, GLenum access) {
  NOTREACHED() << "Unimplemented MapBufferCHROMIUM.";
  return 0;
}
GLboolean MojoGLES2Impl::UnmapBufferCHROMIUM(GLuint target) {
  NOTREACHED() << "Unimplemented UnmapBufferCHROMIUM.";
  return 0;
}
void* MojoGLES2Impl::MapBufferSubDataCHROMIUM(GLuint target,
                                              GLintptr offset,
                                              GLsizeiptr size,
                                              GLenum access) {
  MojoGLES2MakeCurrent(context_);
  return glMapBufferSubDataCHROMIUM(target, offset, size, access);
}
void MojoGLES2Impl::UnmapBufferSubDataCHROMIUM(const void* mem) {
  MojoGLES2MakeCurrent(context_);
  glUnmapBufferSubDataCHROMIUM(mem);
}
void* MojoGLES2Impl::MapBufferRange(GLenum target,
                                    GLintptr offset,
                                    GLsizeiptr size,
                                    GLbitfield access) {
  NOTREACHED() << "Unimplemented MapBufferRange.";
  return 0;
}
GLboolean MojoGLES2Impl::UnmapBuffer(GLenum target) {
  NOTREACHED() << "Unimplemented UnmapBuffer.";
  return 0;
}
void* MojoGLES2Impl::MapTexSubImage2DCHROMIUM(GLenum target,
                                              GLint level,
                                              GLint xoffset,
                                              GLint yoffset,
                                              GLsizei width,
                                              GLsizei height,
                                              GLenum format,
                                              GLenum type,
                                              GLenum access) {
  MojoGLES2MakeCurrent(context_);
  return glMapTexSubImage2DCHROMIUM(target, level, xoffset, yoffset, width,
                                    height, format, type, access);
}
void MojoGLES2Impl::UnmapTexSubImage2DCHROMIUM(const void* mem) {
  MojoGLES2MakeCurrent(context_);
  glUnmapTexSubImage2DCHROMIUM(mem);
}
void MojoGLES2Impl::ResizeCHROMIUM(GLuint width,
                                   GLuint height,
                                   GLfloat scale_factor) {
  MojoGLES2MakeCurrent(context_);
  MGLResizeSurface(width, height);
}
const GLchar* MojoGLES2Impl::GetRequestableExtensionsCHROMIUM() {
  NOTREACHED() << "Unimplemented GetRequestableExtensionsCHROMIUM.";
  return 0;
}
void MojoGLES2Impl::RequestExtensionCHROMIUM(const char* extension) {
  NOTREACHED() << "Unimplemented RequestExtensionCHROMIUM.";
}
void MojoGLES2Impl::RateLimitOffscreenContextCHROMIUM() {
  NOTREACHED() << "Unimplemented RateLimitOffscreenContextCHROMIUM.";
}
void MojoGLES2Impl::GetProgramInfoCHROMIUM(GLuint program,
                                           GLsizei bufsize,
                                           GLsizei* size,
                                           void* info) {
  NOTREACHED() << "Unimplemented GetProgramInfoCHROMIUM.";
}
void MojoGLES2Impl::GetUniformBlocksCHROMIUM(GLuint program,
                                             GLsizei bufsize,
                                             GLsizei* size,
                                             void* info) {
  NOTREACHED() << "Unimplemented GetUniformBlocksCHROMIUM.";
}
void MojoGLES2Impl::GetTransformFeedbackVaryingsCHROMIUM(GLuint program,
                                                         GLsizei bufsize,
                                                         GLsizei* size,
                                                         void* info) {
  NOTREACHED() << "Unimplemented GetTransformFeedbackVaryingsCHROMIUM.";
}
void MojoGLES2Impl::GetUniformsES3CHROMIUM(GLuint program,
                                           GLsizei bufsize,
                                           GLsizei* size,
                                           void* info) {
  NOTREACHED() << "Unimplemented GetUniformsES3CHROMIUM.";
}
GLuint MojoGLES2Impl::CreateStreamTextureCHROMIUM(GLuint texture) {
  NOTREACHED() << "Unimplemented CreateStreamTextureCHROMIUM.";
  return 0;
}
GLuint MojoGLES2Impl::CreateImageCHROMIUM(ClientBuffer buffer,
                                          GLsizei width,
                                          GLsizei height,
                                          GLenum internalformat) {
  NOTREACHED() << "Unimplemented CreateImageCHROMIUM.";
  return 0;
}
void MojoGLES2Impl::DestroyImageCHROMIUM(GLuint image_id) {
  NOTREACHED() << "Unimplemented DestroyImageCHROMIUM.";
}
GLuint MojoGLES2Impl::CreateGpuMemoryBufferImageCHROMIUM(GLsizei width,
                                                         GLsizei height,
                                                         GLenum internalformat,
                                                         GLenum usage) {
  NOTREACHED() << "Unimplemented CreateGpuMemoryBufferImageCHROMIUM.";
  return 0;
}
void MojoGLES2Impl::GetTranslatedShaderSourceANGLE(GLuint shader,
                                                   GLsizei bufsize,
                                                   GLsizei* length,
                                                   char* source) {
  NOTREACHED() << "Unimplemented GetTranslatedShaderSourceANGLE.";
}
void MojoGLES2Impl::PostSubBufferCHROMIUM(GLint x,
                                          GLint y,
                                          GLint width,
                                          GLint height) {
  NOTREACHED() << "Unimplemented PostSubBufferCHROMIUM.";
}
void MojoGLES2Impl::TexImageIOSurface2DCHROMIUM(GLenum target,
                                                GLsizei width,
                                                GLsizei height,
                                                GLuint ioSurfaceId,
                                                GLuint plane) {
  NOTREACHED() << "Unimplemented TexImageIOSurface2DCHROMIUM.";
}
void MojoGLES2Impl::CopyTextureCHROMIUM(GLenum target,
                                        GLenum source_id,
                                        GLenum dest_id,
                                        GLint internalformat,
                                        GLenum dest_type) {
  NOTREACHED() << "Unimplemented CopyTextureCHROMIUM.";
}
void MojoGLES2Impl::CopySubTextureCHROMIUM(GLenum target,
                                           GLenum source_id,
                                           GLenum dest_id,
                                           GLint xoffset,
                                           GLint yoffset) {
  NOTREACHED() << "Unimplemented CopySubTextureCHROMIUM.";
}
void MojoGLES2Impl::DrawArraysInstancedANGLE(GLenum mode,
                                             GLint first,
                                             GLsizei count,
                                             GLsizei primcount) {
  NOTREACHED() << "Unimplemented DrawArraysInstancedANGLE.";
}
void MojoGLES2Impl::DrawElementsInstancedANGLE(GLenum mode,
                                               GLsizei count,
                                               GLenum type,
                                               const void* indices,
                                               GLsizei primcount) {
  NOTREACHED() << "Unimplemented DrawElementsInstancedANGLE.";
}
void MojoGLES2Impl::VertexAttribDivisorANGLE(GLuint index, GLuint divisor) {
  NOTREACHED() << "Unimplemented VertexAttribDivisorANGLE.";
}
void MojoGLES2Impl::GenMailboxCHROMIUM(GLbyte* mailbox) {
  MojoGLES2MakeCurrent(context_);
  glGenMailboxCHROMIUM(mailbox);
}
void MojoGLES2Impl::ProduceTextureCHROMIUM(GLenum target,
                                           const GLbyte* mailbox) {
  MojoGLES2MakeCurrent(context_);
  glProduceTextureCHROMIUM(target, mailbox);
}
void MojoGLES2Impl::ProduceTextureDirectCHROMIUM(GLuint texture,
                                                 GLenum target,
                                                 const GLbyte* mailbox) {
  MojoGLES2MakeCurrent(context_);
  glProduceTextureDirectCHROMIUM(texture, target, mailbox);
}
void MojoGLES2Impl::ConsumeTextureCHROMIUM(GLenum target,
                                           const GLbyte* mailbox) {
  MojoGLES2MakeCurrent(context_);
  glConsumeTextureCHROMIUM(target, mailbox);
}
GLuint MojoGLES2Impl::CreateAndConsumeTextureCHROMIUM(GLenum target,
                                                      const GLbyte* mailbox) {
  MojoGLES2MakeCurrent(context_);
  return glCreateAndConsumeTextureCHROMIUM(target, mailbox);
}
void MojoGLES2Impl::BindUniformLocationCHROMIUM(GLuint program,
                                                GLint location,
                                                const char* name) {
  MojoGLES2MakeCurrent(context_);
  glBindUniformLocationCHROMIUM(program, location, name);
}
void MojoGLES2Impl::GenValuebuffersCHROMIUM(GLsizei n, GLuint* buffers) {
  NOTREACHED() << "Unimplemented GenValuebuffersCHROMIUM.";
}
void MojoGLES2Impl::DeleteValuebuffersCHROMIUM(GLsizei n,
                                               const GLuint* valuebuffers) {
  NOTREACHED() << "Unimplemented DeleteValuebuffersCHROMIUM.";
}
GLboolean MojoGLES2Impl::IsValuebufferCHROMIUM(GLuint valuebuffer) {
  NOTREACHED() << "Unimplemented IsValuebufferCHROMIUM.";
  return 0;
}
void MojoGLES2Impl::BindValuebufferCHROMIUM(GLenum target, GLuint valuebuffer) {
  NOTREACHED() << "Unimplemented BindValuebufferCHROMIUM.";
}
void MojoGLES2Impl::SubscribeValueCHROMIUM(GLenum target, GLenum subscription) {
  NOTREACHED() << "Unimplemented SubscribeValueCHROMIUM.";
}
void MojoGLES2Impl::PopulateSubscribedValuesCHROMIUM(GLenum target) {
  NOTREACHED() << "Unimplemented PopulateSubscribedValuesCHROMIUM.";
}
void MojoGLES2Impl::UniformValuebufferCHROMIUM(GLint location,
                                               GLenum target,
                                               GLenum subscription) {
  NOTREACHED() << "Unimplemented UniformValuebufferCHROMIUM.";
}
void MojoGLES2Impl::BindTexImage2DCHROMIUM(GLenum target, GLint imageId) {
  NOTREACHED() << "Unimplemented BindTexImage2DCHROMIUM.";
}
void MojoGLES2Impl::ReleaseTexImage2DCHROMIUM(GLenum target, GLint imageId) {
  NOTREACHED() << "Unimplemented ReleaseTexImage2DCHROMIUM.";
}
void MojoGLES2Impl::TraceBeginCHROMIUM(const char* category_name,
                                       const char* trace_name) {
  NOTREACHED() << "Unimplemented TraceBeginCHROMIUM.";
}
void MojoGLES2Impl::TraceEndCHROMIUM() {
  NOTREACHED() << "Unimplemented TraceEndCHROMIUM.";
}
void MojoGLES2Impl::AsyncTexSubImage2DCHROMIUM(GLenum target,
                                               GLint level,
                                               GLint xoffset,
                                               GLint yoffset,
                                               GLsizei width,
                                               GLsizei height,
                                               GLenum format,
                                               GLenum type,
                                               const void* data) {
  NOTREACHED() << "Unimplemented AsyncTexSubImage2DCHROMIUM.";
}
void MojoGLES2Impl::AsyncTexImage2DCHROMIUM(GLenum target,
                                            GLint level,
                                            GLenum internalformat,
                                            GLsizei width,
                                            GLsizei height,
                                            GLint border,
                                            GLenum format,
                                            GLenum type,
                                            const void* pixels) {
  NOTREACHED() << "Unimplemented AsyncTexImage2DCHROMIUM.";
}
void MojoGLES2Impl::WaitAsyncTexImage2DCHROMIUM(GLenum target) {
  NOTREACHED() << "Unimplemented WaitAsyncTexImage2DCHROMIUM.";
}
void MojoGLES2Impl::WaitAllAsyncTexImage2DCHROMIUM() {
  NOTREACHED() << "Unimplemented WaitAllAsyncTexImage2DCHROMIUM.";
}
void MojoGLES2Impl::DiscardFramebufferEXT(GLenum target,
                                          GLsizei count,
                                          const GLenum* attachments) {
  NOTREACHED() << "Unimplemented DiscardFramebufferEXT.";
}
void MojoGLES2Impl::LoseContextCHROMIUM(GLenum current, GLenum other) {
  NOTREACHED() << "Unimplemented LoseContextCHROMIUM.";
}
GLuint MojoGLES2Impl::InsertSyncPointCHROMIUM() {
  MojoGLES2MakeCurrent(context_);
  return glInsertSyncPointCHROMIUM();
}
void MojoGLES2Impl::WaitSyncPointCHROMIUM(GLuint sync_point) {
  MojoGLES2MakeCurrent(context_);
  glWaitSyncPointCHROMIUM(sync_point);
}
void MojoGLES2Impl::DrawBuffersEXT(GLsizei count, const GLenum* bufs) {
  NOTREACHED() << "Unimplemented DrawBuffersEXT.";
}
void MojoGLES2Impl::DiscardBackbufferCHROMIUM() {
  NOTREACHED() << "Unimplemented DiscardBackbufferCHROMIUM.";
}
void MojoGLES2Impl::ScheduleOverlayPlaneCHROMIUM(GLint plane_z_order,
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
  NOTREACHED() << "Unimplemented ScheduleOverlayPlaneCHROMIUM.";
}
void MojoGLES2Impl::SwapInterval(GLint interval) {
  NOTREACHED() << "Unimplemented SwapInterval.";
}
void MojoGLES2Impl::MatrixLoadfCHROMIUM(GLenum matrixMode, const GLfloat* m) {
  NOTREACHED() << "Unimplemented MatrixLoadfCHROMIUM.";
}
void MojoGLES2Impl::MatrixLoadIdentityCHROMIUM(GLenum matrixMode) {
  NOTREACHED() << "Unimplemented MatrixLoadIdentityCHROMIUM.";
}
void MojoGLES2Impl::BlendBarrierKHR() {
  NOTREACHED() << "Unimplemented BlendBarrierKHR.";
}

}  // namespace mojo
