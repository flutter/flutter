// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is auto-generated from
// ui/gl/generate_bindings.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

#include <string.h>

#include "ui/gl/gl_mock.h"

namespace gfx {

// This is called mainly to prevent the compiler combining the code of mock
// functions with identical contents, so that their function pointers will be
// different.
void MakeFunctionUnique(const char* func_name) {
  VLOG(2) << "Calling mock " << func_name;
}

void GL_BINDING_CALL MockGLInterface::Mock_glActiveTexture(GLenum texture) {
  MakeFunctionUnique("glActiveTexture");
  interface_->ActiveTexture(texture);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glAttachShader(GLuint program, GLuint shader) {
  MakeFunctionUnique("glAttachShader");
  interface_->AttachShader(program, shader);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBeginQuery(GLenum target, GLuint id) {
  MakeFunctionUnique("glBeginQuery");
  interface_->BeginQuery(target, id);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBeginQueryARB(GLenum target, GLuint id) {
  MakeFunctionUnique("glBeginQueryARB");
  interface_->BeginQuery(target, id);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBeginQueryEXT(GLenum target, GLuint id) {
  MakeFunctionUnique("glBeginQueryEXT");
  interface_->BeginQuery(target, id);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBeginTransformFeedback(GLenum primitiveMode) {
  MakeFunctionUnique("glBeginTransformFeedback");
  interface_->BeginTransformFeedback(primitiveMode);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBindAttribLocation(GLuint program,
                                           GLuint index,
                                           const char* name) {
  MakeFunctionUnique("glBindAttribLocation");
  interface_->BindAttribLocation(program, index, name);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBindBuffer(GLenum target, GLuint buffer) {
  MakeFunctionUnique("glBindBuffer");
  interface_->BindBuffer(target, buffer);
}

void GL_BINDING_CALL MockGLInterface::Mock_glBindBufferBase(GLenum target,
                                                            GLuint index,
                                                            GLuint buffer) {
  MakeFunctionUnique("glBindBufferBase");
  interface_->BindBufferBase(target, index, buffer);
}

void GL_BINDING_CALL MockGLInterface::Mock_glBindBufferRange(GLenum target,
                                                             GLuint index,
                                                             GLuint buffer,
                                                             GLintptr offset,
                                                             GLsizeiptr size) {
  MakeFunctionUnique("glBindBufferRange");
  interface_->BindBufferRange(target, index, buffer, offset, size);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBindFragDataLocation(GLuint program,
                                             GLuint colorNumber,
                                             const char* name) {
  MakeFunctionUnique("glBindFragDataLocation");
  interface_->BindFragDataLocation(program, colorNumber, name);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBindFragDataLocationIndexed(GLuint program,
                                                    GLuint colorNumber,
                                                    GLuint index,
                                                    const char* name) {
  MakeFunctionUnique("glBindFragDataLocationIndexed");
  interface_->BindFragDataLocationIndexed(program, colorNumber, index, name);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBindFramebuffer(GLenum target, GLuint framebuffer) {
  MakeFunctionUnique("glBindFramebuffer");
  interface_->BindFramebufferEXT(target, framebuffer);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBindFramebufferEXT(GLenum target, GLuint framebuffer) {
  MakeFunctionUnique("glBindFramebufferEXT");
  interface_->BindFramebufferEXT(target, framebuffer);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBindRenderbuffer(GLenum target, GLuint renderbuffer) {
  MakeFunctionUnique("glBindRenderbuffer");
  interface_->BindRenderbufferEXT(target, renderbuffer);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBindRenderbufferEXT(GLenum target,
                                            GLuint renderbuffer) {
  MakeFunctionUnique("glBindRenderbufferEXT");
  interface_->BindRenderbufferEXT(target, renderbuffer);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBindSampler(GLuint unit, GLuint sampler) {
  MakeFunctionUnique("glBindSampler");
  interface_->BindSampler(unit, sampler);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBindTexture(GLenum target, GLuint texture) {
  MakeFunctionUnique("glBindTexture");
  interface_->BindTexture(target, texture);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBindTransformFeedback(GLenum target, GLuint id) {
  MakeFunctionUnique("glBindTransformFeedback");
  interface_->BindTransformFeedback(target, id);
}

void GL_BINDING_CALL MockGLInterface::Mock_glBindVertexArray(GLuint array) {
  MakeFunctionUnique("glBindVertexArray");
  interface_->BindVertexArrayOES(array);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBindVertexArrayAPPLE(GLuint array) {
  MakeFunctionUnique("glBindVertexArrayAPPLE");
  interface_->BindVertexArrayOES(array);
}

void GL_BINDING_CALL MockGLInterface::Mock_glBindVertexArrayOES(GLuint array) {
  MakeFunctionUnique("glBindVertexArrayOES");
  interface_->BindVertexArrayOES(array);
}

void GL_BINDING_CALL MockGLInterface::Mock_glBlendBarrierKHR(void) {
  MakeFunctionUnique("glBlendBarrierKHR");
  interface_->BlendBarrierKHR();
}

void GL_BINDING_CALL MockGLInterface::Mock_glBlendBarrierNV(void) {
  MakeFunctionUnique("glBlendBarrierNV");
  interface_->BlendBarrierKHR();
}

void GL_BINDING_CALL MockGLInterface::Mock_glBlendColor(GLclampf red,
                                                        GLclampf green,
                                                        GLclampf blue,
                                                        GLclampf alpha) {
  MakeFunctionUnique("glBlendColor");
  interface_->BlendColor(red, green, blue, alpha);
}

void GL_BINDING_CALL MockGLInterface::Mock_glBlendEquation(GLenum mode) {
  MakeFunctionUnique("glBlendEquation");
  interface_->BlendEquation(mode);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBlendEquationSeparate(GLenum modeRGB,
                                              GLenum modeAlpha) {
  MakeFunctionUnique("glBlendEquationSeparate");
  interface_->BlendEquationSeparate(modeRGB, modeAlpha);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBlendFunc(GLenum sfactor, GLenum dfactor) {
  MakeFunctionUnique("glBlendFunc");
  interface_->BlendFunc(sfactor, dfactor);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBlendFuncSeparate(GLenum srcRGB,
                                          GLenum dstRGB,
                                          GLenum srcAlpha,
                                          GLenum dstAlpha) {
  MakeFunctionUnique("glBlendFuncSeparate");
  interface_->BlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
}

void GL_BINDING_CALL MockGLInterface::Mock_glBlitFramebuffer(GLint srcX0,
                                                             GLint srcY0,
                                                             GLint srcX1,
                                                             GLint srcY1,
                                                             GLint dstX0,
                                                             GLint dstY0,
                                                             GLint dstX1,
                                                             GLint dstY1,
                                                             GLbitfield mask,
                                                             GLenum filter) {
  MakeFunctionUnique("glBlitFramebuffer");
  interface_->BlitFramebufferEXT(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0,
                                 dstX1, dstY1, mask, filter);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glBlitFramebufferANGLE(GLint srcX0,
                                             GLint srcY0,
                                             GLint srcX1,
                                             GLint srcY1,
                                             GLint dstX0,
                                             GLint dstY0,
                                             GLint dstX1,
                                             GLint dstY1,
                                             GLbitfield mask,
                                             GLenum filter) {
  MakeFunctionUnique("glBlitFramebufferANGLE");
  interface_->BlitFramebufferANGLE(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0,
                                   dstX1, dstY1, mask, filter);
}

void GL_BINDING_CALL MockGLInterface::Mock_glBlitFramebufferEXT(GLint srcX0,
                                                                GLint srcY0,
                                                                GLint srcX1,
                                                                GLint srcY1,
                                                                GLint dstX0,
                                                                GLint dstY0,
                                                                GLint dstX1,
                                                                GLint dstY1,
                                                                GLbitfield mask,
                                                                GLenum filter) {
  MakeFunctionUnique("glBlitFramebufferEXT");
  interface_->BlitFramebufferEXT(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0,
                                 dstX1, dstY1, mask, filter);
}

void GL_BINDING_CALL MockGLInterface::Mock_glBufferData(GLenum target,
                                                        GLsizeiptr size,
                                                        const void* data,
                                                        GLenum usage) {
  MakeFunctionUnique("glBufferData");
  interface_->BufferData(target, size, data, usage);
}

void GL_BINDING_CALL MockGLInterface::Mock_glBufferSubData(GLenum target,
                                                           GLintptr offset,
                                                           GLsizeiptr size,
                                                           const void* data) {
  MakeFunctionUnique("glBufferSubData");
  interface_->BufferSubData(target, offset, size, data);
}

GLenum GL_BINDING_CALL
MockGLInterface::Mock_glCheckFramebufferStatus(GLenum target) {
  MakeFunctionUnique("glCheckFramebufferStatus");
  return interface_->CheckFramebufferStatusEXT(target);
}

GLenum GL_BINDING_CALL
MockGLInterface::Mock_glCheckFramebufferStatusEXT(GLenum target) {
  MakeFunctionUnique("glCheckFramebufferStatusEXT");
  return interface_->CheckFramebufferStatusEXT(target);
}

void GL_BINDING_CALL MockGLInterface::Mock_glClear(GLbitfield mask) {
  MakeFunctionUnique("glClear");
  interface_->Clear(mask);
}

void GL_BINDING_CALL MockGLInterface::Mock_glClearBufferfi(GLenum buffer,
                                                           GLint drawbuffer,
                                                           const GLfloat depth,
                                                           GLint stencil) {
  MakeFunctionUnique("glClearBufferfi");
  interface_->ClearBufferfi(buffer, drawbuffer, depth, stencil);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glClearBufferfv(GLenum buffer,
                                      GLint drawbuffer,
                                      const GLfloat* value) {
  MakeFunctionUnique("glClearBufferfv");
  interface_->ClearBufferfv(buffer, drawbuffer, value);
}

void GL_BINDING_CALL MockGLInterface::Mock_glClearBufferiv(GLenum buffer,
                                                           GLint drawbuffer,
                                                           const GLint* value) {
  MakeFunctionUnique("glClearBufferiv");
  interface_->ClearBufferiv(buffer, drawbuffer, value);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glClearBufferuiv(GLenum buffer,
                                       GLint drawbuffer,
                                       const GLuint* value) {
  MakeFunctionUnique("glClearBufferuiv");
  interface_->ClearBufferuiv(buffer, drawbuffer, value);
}

void GL_BINDING_CALL MockGLInterface::Mock_glClearColor(GLclampf red,
                                                        GLclampf green,
                                                        GLclampf blue,
                                                        GLclampf alpha) {
  MakeFunctionUnique("glClearColor");
  interface_->ClearColor(red, green, blue, alpha);
}

void GL_BINDING_CALL MockGLInterface::Mock_glClearDepth(GLclampd depth) {
  MakeFunctionUnique("glClearDepth");
  interface_->ClearDepth(depth);
}

void GL_BINDING_CALL MockGLInterface::Mock_glClearDepthf(GLclampf depth) {
  MakeFunctionUnique("glClearDepthf");
  interface_->ClearDepthf(depth);
}

void GL_BINDING_CALL MockGLInterface::Mock_glClearStencil(GLint s) {
  MakeFunctionUnique("glClearStencil");
  interface_->ClearStencil(s);
}

GLenum GL_BINDING_CALL
MockGLInterface::Mock_glClientWaitSync(GLsync sync,
                                       GLbitfield flags,
                                       GLuint64 timeout) {
  MakeFunctionUnique("glClientWaitSync");
  return interface_->ClientWaitSync(sync, flags, timeout);
}

void GL_BINDING_CALL MockGLInterface::Mock_glColorMask(GLboolean red,
                                                       GLboolean green,
                                                       GLboolean blue,
                                                       GLboolean alpha) {
  MakeFunctionUnique("glColorMask");
  interface_->ColorMask(red, green, blue, alpha);
}

void GL_BINDING_CALL MockGLInterface::Mock_glCompileShader(GLuint shader) {
  MakeFunctionUnique("glCompileShader");
  interface_->CompileShader(shader);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glCompressedTexImage2D(GLenum target,
                                             GLint level,
                                             GLenum internalformat,
                                             GLsizei width,
                                             GLsizei height,
                                             GLint border,
                                             GLsizei imageSize,
                                             const void* data) {
  MakeFunctionUnique("glCompressedTexImage2D");
  interface_->CompressedTexImage2D(target, level, internalformat, width, height,
                                   border, imageSize, data);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glCompressedTexImage3D(GLenum target,
                                             GLint level,
                                             GLenum internalformat,
                                             GLsizei width,
                                             GLsizei height,
                                             GLsizei depth,
                                             GLint border,
                                             GLsizei imageSize,
                                             const void* data) {
  MakeFunctionUnique("glCompressedTexImage3D");
  interface_->CompressedTexImage3D(target, level, internalformat, width, height,
                                   depth, border, imageSize, data);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glCompressedTexSubImage2D(GLenum target,
                                                GLint level,
                                                GLint xoffset,
                                                GLint yoffset,
                                                GLsizei width,
                                                GLsizei height,
                                                GLenum format,
                                                GLsizei imageSize,
                                                const void* data) {
  MakeFunctionUnique("glCompressedTexSubImage2D");
  interface_->CompressedTexSubImage2D(target, level, xoffset, yoffset, width,
                                      height, format, imageSize, data);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glCopyBufferSubData(GLenum readTarget,
                                          GLenum writeTarget,
                                          GLintptr readOffset,
                                          GLintptr writeOffset,
                                          GLsizeiptr size) {
  MakeFunctionUnique("glCopyBufferSubData");
  interface_->CopyBufferSubData(readTarget, writeTarget, readOffset,
                                writeOffset, size);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glCopyTexImage2D(GLenum target,
                                       GLint level,
                                       GLenum internalformat,
                                       GLint x,
                                       GLint y,
                                       GLsizei width,
                                       GLsizei height,
                                       GLint border) {
  MakeFunctionUnique("glCopyTexImage2D");
  interface_->CopyTexImage2D(target, level, internalformat, x, y, width, height,
                             border);
}

void GL_BINDING_CALL MockGLInterface::Mock_glCopyTexSubImage2D(GLenum target,
                                                               GLint level,
                                                               GLint xoffset,
                                                               GLint yoffset,
                                                               GLint x,
                                                               GLint y,
                                                               GLsizei width,
                                                               GLsizei height) {
  MakeFunctionUnique("glCopyTexSubImage2D");
  interface_->CopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width,
                                height);
}

void GL_BINDING_CALL MockGLInterface::Mock_glCopyTexSubImage3D(GLenum target,
                                                               GLint level,
                                                               GLint xoffset,
                                                               GLint yoffset,
                                                               GLint zoffset,
                                                               GLint x,
                                                               GLint y,
                                                               GLsizei width,
                                                               GLsizei height) {
  MakeFunctionUnique("glCopyTexSubImage3D");
  interface_->CopyTexSubImage3D(target, level, xoffset, yoffset, zoffset, x, y,
                                width, height);
}

GLuint GL_BINDING_CALL MockGLInterface::Mock_glCreateProgram(void) {
  MakeFunctionUnique("glCreateProgram");
  return interface_->CreateProgram();
}

GLuint GL_BINDING_CALL MockGLInterface::Mock_glCreateShader(GLenum type) {
  MakeFunctionUnique("glCreateShader");
  return interface_->CreateShader(type);
}

void GL_BINDING_CALL MockGLInterface::Mock_glCullFace(GLenum mode) {
  MakeFunctionUnique("glCullFace");
  interface_->CullFace(mode);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteBuffers(GLsizei n, const GLuint* buffers) {
  MakeFunctionUnique("glDeleteBuffers");
  interface_->DeleteBuffersARB(n, buffers);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteFencesAPPLE(GLsizei n, const GLuint* fences) {
  MakeFunctionUnique("glDeleteFencesAPPLE");
  interface_->DeleteFencesAPPLE(n, fences);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteFencesNV(GLsizei n, const GLuint* fences) {
  MakeFunctionUnique("glDeleteFencesNV");
  interface_->DeleteFencesNV(n, fences);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteFramebuffers(GLsizei n,
                                           const GLuint* framebuffers) {
  MakeFunctionUnique("glDeleteFramebuffers");
  interface_->DeleteFramebuffersEXT(n, framebuffers);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteFramebuffersEXT(GLsizei n,
                                              const GLuint* framebuffers) {
  MakeFunctionUnique("glDeleteFramebuffersEXT");
  interface_->DeleteFramebuffersEXT(n, framebuffers);
}

void GL_BINDING_CALL MockGLInterface::Mock_glDeleteProgram(GLuint program) {
  MakeFunctionUnique("glDeleteProgram");
  interface_->DeleteProgram(program);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteQueries(GLsizei n, const GLuint* ids) {
  MakeFunctionUnique("glDeleteQueries");
  interface_->DeleteQueries(n, ids);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteQueriesARB(GLsizei n, const GLuint* ids) {
  MakeFunctionUnique("glDeleteQueriesARB");
  interface_->DeleteQueries(n, ids);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteQueriesEXT(GLsizei n, const GLuint* ids) {
  MakeFunctionUnique("glDeleteQueriesEXT");
  interface_->DeleteQueries(n, ids);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteRenderbuffers(GLsizei n,
                                            const GLuint* renderbuffers) {
  MakeFunctionUnique("glDeleteRenderbuffers");
  interface_->DeleteRenderbuffersEXT(n, renderbuffers);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteRenderbuffersEXT(GLsizei n,
                                               const GLuint* renderbuffers) {
  MakeFunctionUnique("glDeleteRenderbuffersEXT");
  interface_->DeleteRenderbuffersEXT(n, renderbuffers);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteSamplers(GLsizei n, const GLuint* samplers) {
  MakeFunctionUnique("glDeleteSamplers");
  interface_->DeleteSamplers(n, samplers);
}

void GL_BINDING_CALL MockGLInterface::Mock_glDeleteShader(GLuint shader) {
  MakeFunctionUnique("glDeleteShader");
  interface_->DeleteShader(shader);
}

void GL_BINDING_CALL MockGLInterface::Mock_glDeleteSync(GLsync sync) {
  MakeFunctionUnique("glDeleteSync");
  interface_->DeleteSync(sync);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteTextures(GLsizei n, const GLuint* textures) {
  MakeFunctionUnique("glDeleteTextures");
  interface_->DeleteTextures(n, textures);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteTransformFeedbacks(GLsizei n, const GLuint* ids) {
  MakeFunctionUnique("glDeleteTransformFeedbacks");
  interface_->DeleteTransformFeedbacks(n, ids);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteVertexArrays(GLsizei n, const GLuint* arrays) {
  MakeFunctionUnique("glDeleteVertexArrays");
  interface_->DeleteVertexArraysOES(n, arrays);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteVertexArraysAPPLE(GLsizei n,
                                                const GLuint* arrays) {
  MakeFunctionUnique("glDeleteVertexArraysAPPLE");
  interface_->DeleteVertexArraysOES(n, arrays);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDeleteVertexArraysOES(GLsizei n, const GLuint* arrays) {
  MakeFunctionUnique("glDeleteVertexArraysOES");
  interface_->DeleteVertexArraysOES(n, arrays);
}

void GL_BINDING_CALL MockGLInterface::Mock_glDepthFunc(GLenum func) {
  MakeFunctionUnique("glDepthFunc");
  interface_->DepthFunc(func);
}

void GL_BINDING_CALL MockGLInterface::Mock_glDepthMask(GLboolean flag) {
  MakeFunctionUnique("glDepthMask");
  interface_->DepthMask(flag);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDepthRange(GLclampd zNear, GLclampd zFar) {
  MakeFunctionUnique("glDepthRange");
  interface_->DepthRange(zNear, zFar);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDepthRangef(GLclampf zNear, GLclampf zFar) {
  MakeFunctionUnique("glDepthRangef");
  interface_->DepthRangef(zNear, zFar);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDetachShader(GLuint program, GLuint shader) {
  MakeFunctionUnique("glDetachShader");
  interface_->DetachShader(program, shader);
}

void GL_BINDING_CALL MockGLInterface::Mock_glDisable(GLenum cap) {
  MakeFunctionUnique("glDisable");
  interface_->Disable(cap);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDisableVertexAttribArray(GLuint index) {
  MakeFunctionUnique("glDisableVertexAttribArray");
  interface_->DisableVertexAttribArray(index);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDiscardFramebufferEXT(GLenum target,
                                              GLsizei numAttachments,
                                              const GLenum* attachments) {
  MakeFunctionUnique("glDiscardFramebufferEXT");
  interface_->DiscardFramebufferEXT(target, numAttachments, attachments);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDrawArrays(GLenum mode, GLint first, GLsizei count) {
  MakeFunctionUnique("glDrawArrays");
  interface_->DrawArrays(mode, first, count);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDrawArraysInstanced(GLenum mode,
                                            GLint first,
                                            GLsizei count,
                                            GLsizei primcount) {
  MakeFunctionUnique("glDrawArraysInstanced");
  interface_->DrawArraysInstancedANGLE(mode, first, count, primcount);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDrawArraysInstancedANGLE(GLenum mode,
                                                 GLint first,
                                                 GLsizei count,
                                                 GLsizei primcount) {
  MakeFunctionUnique("glDrawArraysInstancedANGLE");
  interface_->DrawArraysInstancedANGLE(mode, first, count, primcount);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDrawArraysInstancedARB(GLenum mode,
                                               GLint first,
                                               GLsizei count,
                                               GLsizei primcount) {
  MakeFunctionUnique("glDrawArraysInstancedARB");
  interface_->DrawArraysInstancedANGLE(mode, first, count, primcount);
}

void GL_BINDING_CALL MockGLInterface::Mock_glDrawBuffer(GLenum mode) {
  MakeFunctionUnique("glDrawBuffer");
  interface_->DrawBuffer(mode);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDrawBuffers(GLsizei n, const GLenum* bufs) {
  MakeFunctionUnique("glDrawBuffers");
  interface_->DrawBuffersARB(n, bufs);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDrawBuffersARB(GLsizei n, const GLenum* bufs) {
  MakeFunctionUnique("glDrawBuffersARB");
  interface_->DrawBuffersARB(n, bufs);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDrawBuffersEXT(GLsizei n, const GLenum* bufs) {
  MakeFunctionUnique("glDrawBuffersEXT");
  interface_->DrawBuffersARB(n, bufs);
}

void GL_BINDING_CALL MockGLInterface::Mock_glDrawElements(GLenum mode,
                                                          GLsizei count,
                                                          GLenum type,
                                                          const void* indices) {
  MakeFunctionUnique("glDrawElements");
  interface_->DrawElements(mode, count, type, indices);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDrawElementsInstanced(GLenum mode,
                                              GLsizei count,
                                              GLenum type,
                                              const void* indices,
                                              GLsizei primcount) {
  MakeFunctionUnique("glDrawElementsInstanced");
  interface_->DrawElementsInstancedANGLE(mode, count, type, indices, primcount);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDrawElementsInstancedANGLE(GLenum mode,
                                                   GLsizei count,
                                                   GLenum type,
                                                   const void* indices,
                                                   GLsizei primcount) {
  MakeFunctionUnique("glDrawElementsInstancedANGLE");
  interface_->DrawElementsInstancedANGLE(mode, count, type, indices, primcount);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDrawElementsInstancedARB(GLenum mode,
                                                 GLsizei count,
                                                 GLenum type,
                                                 const void* indices,
                                                 GLsizei primcount) {
  MakeFunctionUnique("glDrawElementsInstancedARB");
  interface_->DrawElementsInstancedANGLE(mode, count, type, indices, primcount);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glDrawRangeElements(GLenum mode,
                                          GLuint start,
                                          GLuint end,
                                          GLsizei count,
                                          GLenum type,
                                          const void* indices) {
  MakeFunctionUnique("glDrawRangeElements");
  interface_->DrawRangeElements(mode, start, end, count, type, indices);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glEGLImageTargetRenderbufferStorageOES(
    GLenum target,
    GLeglImageOES image) {
  MakeFunctionUnique("glEGLImageTargetRenderbufferStorageOES");
  interface_->EGLImageTargetRenderbufferStorageOES(target, image);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glEGLImageTargetTexture2DOES(GLenum target,
                                                   GLeglImageOES image) {
  MakeFunctionUnique("glEGLImageTargetTexture2DOES");
  interface_->EGLImageTargetTexture2DOES(target, image);
}

void GL_BINDING_CALL MockGLInterface::Mock_glEnable(GLenum cap) {
  MakeFunctionUnique("glEnable");
  interface_->Enable(cap);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glEnableVertexAttribArray(GLuint index) {
  MakeFunctionUnique("glEnableVertexAttribArray");
  interface_->EnableVertexAttribArray(index);
}

void GL_BINDING_CALL MockGLInterface::Mock_glEndQuery(GLenum target) {
  MakeFunctionUnique("glEndQuery");
  interface_->EndQuery(target);
}

void GL_BINDING_CALL MockGLInterface::Mock_glEndQueryARB(GLenum target) {
  MakeFunctionUnique("glEndQueryARB");
  interface_->EndQuery(target);
}

void GL_BINDING_CALL MockGLInterface::Mock_glEndQueryEXT(GLenum target) {
  MakeFunctionUnique("glEndQueryEXT");
  interface_->EndQuery(target);
}

void GL_BINDING_CALL MockGLInterface::Mock_glEndTransformFeedback(void) {
  MakeFunctionUnique("glEndTransformFeedback");
  interface_->EndTransformFeedback();
}

GLsync GL_BINDING_CALL
MockGLInterface::Mock_glFenceSync(GLenum condition, GLbitfield flags) {
  MakeFunctionUnique("glFenceSync");
  return interface_->FenceSync(condition, flags);
}

void GL_BINDING_CALL MockGLInterface::Mock_glFinish(void) {
  MakeFunctionUnique("glFinish");
  interface_->Finish();
}

void GL_BINDING_CALL MockGLInterface::Mock_glFinishFenceAPPLE(GLuint fence) {
  MakeFunctionUnique("glFinishFenceAPPLE");
  interface_->FinishFenceAPPLE(fence);
}

void GL_BINDING_CALL MockGLInterface::Mock_glFinishFenceNV(GLuint fence) {
  MakeFunctionUnique("glFinishFenceNV");
  interface_->FinishFenceNV(fence);
}

void GL_BINDING_CALL MockGLInterface::Mock_glFlush(void) {
  MakeFunctionUnique("glFlush");
  interface_->Flush();
}

void GL_BINDING_CALL
MockGLInterface::Mock_glFlushMappedBufferRange(GLenum target,
                                               GLintptr offset,
                                               GLsizeiptr length) {
  MakeFunctionUnique("glFlushMappedBufferRange");
  interface_->FlushMappedBufferRange(target, offset, length);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glFramebufferRenderbuffer(GLenum target,
                                                GLenum attachment,
                                                GLenum renderbuffertarget,
                                                GLuint renderbuffer) {
  MakeFunctionUnique("glFramebufferRenderbuffer");
  interface_->FramebufferRenderbufferEXT(target, attachment, renderbuffertarget,
                                         renderbuffer);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glFramebufferRenderbufferEXT(GLenum target,
                                                   GLenum attachment,
                                                   GLenum renderbuffertarget,
                                                   GLuint renderbuffer) {
  MakeFunctionUnique("glFramebufferRenderbufferEXT");
  interface_->FramebufferRenderbufferEXT(target, attachment, renderbuffertarget,
                                         renderbuffer);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glFramebufferTexture2D(GLenum target,
                                             GLenum attachment,
                                             GLenum textarget,
                                             GLuint texture,
                                             GLint level) {
  MakeFunctionUnique("glFramebufferTexture2D");
  interface_->FramebufferTexture2DEXT(target, attachment, textarget, texture,
                                      level);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glFramebufferTexture2DEXT(GLenum target,
                                                GLenum attachment,
                                                GLenum textarget,
                                                GLuint texture,
                                                GLint level) {
  MakeFunctionUnique("glFramebufferTexture2DEXT");
  interface_->FramebufferTexture2DEXT(target, attachment, textarget, texture,
                                      level);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glFramebufferTexture2DMultisampleEXT(GLenum target,
                                                           GLenum attachment,
                                                           GLenum textarget,
                                                           GLuint texture,
                                                           GLint level,
                                                           GLsizei samples) {
  MakeFunctionUnique("glFramebufferTexture2DMultisampleEXT");
  interface_->FramebufferTexture2DMultisampleEXT(target, attachment, textarget,
                                                 texture, level, samples);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glFramebufferTexture2DMultisampleIMG(GLenum target,
                                                           GLenum attachment,
                                                           GLenum textarget,
                                                           GLuint texture,
                                                           GLint level,
                                                           GLsizei samples) {
  MakeFunctionUnique("glFramebufferTexture2DMultisampleIMG");
  interface_->FramebufferTexture2DMultisampleIMG(target, attachment, textarget,
                                                 texture, level, samples);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glFramebufferTextureLayer(GLenum target,
                                                GLenum attachment,
                                                GLuint texture,
                                                GLint level,
                                                GLint layer) {
  MakeFunctionUnique("glFramebufferTextureLayer");
  interface_->FramebufferTextureLayer(target, attachment, texture, level,
                                      layer);
}

void GL_BINDING_CALL MockGLInterface::Mock_glFrontFace(GLenum mode) {
  MakeFunctionUnique("glFrontFace");
  interface_->FrontFace(mode);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenBuffers(GLsizei n, GLuint* buffers) {
  MakeFunctionUnique("glGenBuffers");
  interface_->GenBuffersARB(n, buffers);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenFencesAPPLE(GLsizei n, GLuint* fences) {
  MakeFunctionUnique("glGenFencesAPPLE");
  interface_->GenFencesAPPLE(n, fences);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenFencesNV(GLsizei n, GLuint* fences) {
  MakeFunctionUnique("glGenFencesNV");
  interface_->GenFencesNV(n, fences);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenFramebuffers(GLsizei n, GLuint* framebuffers) {
  MakeFunctionUnique("glGenFramebuffers");
  interface_->GenFramebuffersEXT(n, framebuffers);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenFramebuffersEXT(GLsizei n, GLuint* framebuffers) {
  MakeFunctionUnique("glGenFramebuffersEXT");
  interface_->GenFramebuffersEXT(n, framebuffers);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenQueries(GLsizei n, GLuint* ids) {
  MakeFunctionUnique("glGenQueries");
  interface_->GenQueries(n, ids);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenQueriesARB(GLsizei n, GLuint* ids) {
  MakeFunctionUnique("glGenQueriesARB");
  interface_->GenQueries(n, ids);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenQueriesEXT(GLsizei n, GLuint* ids) {
  MakeFunctionUnique("glGenQueriesEXT");
  interface_->GenQueries(n, ids);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenRenderbuffers(GLsizei n, GLuint* renderbuffers) {
  MakeFunctionUnique("glGenRenderbuffers");
  interface_->GenRenderbuffersEXT(n, renderbuffers);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenRenderbuffersEXT(GLsizei n, GLuint* renderbuffers) {
  MakeFunctionUnique("glGenRenderbuffersEXT");
  interface_->GenRenderbuffersEXT(n, renderbuffers);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenSamplers(GLsizei n, GLuint* samplers) {
  MakeFunctionUnique("glGenSamplers");
  interface_->GenSamplers(n, samplers);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenTextures(GLsizei n, GLuint* textures) {
  MakeFunctionUnique("glGenTextures");
  interface_->GenTextures(n, textures);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenTransformFeedbacks(GLsizei n, GLuint* ids) {
  MakeFunctionUnique("glGenTransformFeedbacks");
  interface_->GenTransformFeedbacks(n, ids);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenVertexArrays(GLsizei n, GLuint* arrays) {
  MakeFunctionUnique("glGenVertexArrays");
  interface_->GenVertexArraysOES(n, arrays);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenVertexArraysAPPLE(GLsizei n, GLuint* arrays) {
  MakeFunctionUnique("glGenVertexArraysAPPLE");
  interface_->GenVertexArraysOES(n, arrays);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGenVertexArraysOES(GLsizei n, GLuint* arrays) {
  MakeFunctionUnique("glGenVertexArraysOES");
  interface_->GenVertexArraysOES(n, arrays);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGenerateMipmap(GLenum target) {
  MakeFunctionUnique("glGenerateMipmap");
  interface_->GenerateMipmapEXT(target);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGenerateMipmapEXT(GLenum target) {
  MakeFunctionUnique("glGenerateMipmapEXT");
  interface_->GenerateMipmapEXT(target);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetActiveAttrib(GLuint program,
                                                             GLuint index,
                                                             GLsizei bufsize,
                                                             GLsizei* length,
                                                             GLint* size,
                                                             GLenum* type,
                                                             char* name) {
  MakeFunctionUnique("glGetActiveAttrib");
  interface_->GetActiveAttrib(program, index, bufsize, length, size, type,
                              name);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetActiveUniform(GLuint program,
                                                              GLuint index,
                                                              GLsizei bufsize,
                                                              GLsizei* length,
                                                              GLint* size,
                                                              GLenum* type,
                                                              char* name) {
  MakeFunctionUnique("glGetActiveUniform");
  interface_->GetActiveUniform(program, index, bufsize, length, size, type,
                               name);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetActiveUniformBlockName(GLuint program,
                                                  GLuint uniformBlockIndex,
                                                  GLsizei bufSize,
                                                  GLsizei* length,
                                                  char* uniformBlockName) {
  MakeFunctionUnique("glGetActiveUniformBlockName");
  interface_->GetActiveUniformBlockName(program, uniformBlockIndex, bufSize,
                                        length, uniformBlockName);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetActiveUniformBlockiv(GLuint program,
                                                GLuint uniformBlockIndex,
                                                GLenum pname,
                                                GLint* params) {
  MakeFunctionUnique("glGetActiveUniformBlockiv");
  interface_->GetActiveUniformBlockiv(program, uniformBlockIndex, pname,
                                      params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetActiveUniformsiv(GLuint program,
                                            GLsizei uniformCount,
                                            const GLuint* uniformIndices,
                                            GLenum pname,
                                            GLint* params) {
  MakeFunctionUnique("glGetActiveUniformsiv");
  interface_->GetActiveUniformsiv(program, uniformCount, uniformIndices, pname,
                                  params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetAttachedShaders(GLuint program,
                                           GLsizei maxcount,
                                           GLsizei* count,
                                           GLuint* shaders) {
  MakeFunctionUnique("glGetAttachedShaders");
  interface_->GetAttachedShaders(program, maxcount, count, shaders);
}

GLint GL_BINDING_CALL
MockGLInterface::Mock_glGetAttribLocation(GLuint program, const char* name) {
  MakeFunctionUnique("glGetAttribLocation");
  return interface_->GetAttribLocation(program, name);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetBooleanv(GLenum pname, GLboolean* params) {
  MakeFunctionUnique("glGetBooleanv");
  interface_->GetBooleanv(pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetBufferParameteriv(GLenum target,
                                             GLenum pname,
                                             GLint* params) {
  MakeFunctionUnique("glGetBufferParameteriv");
  interface_->GetBufferParameteriv(target, pname, params);
}

GLenum GL_BINDING_CALL MockGLInterface::Mock_glGetError(void) {
  MakeFunctionUnique("glGetError");
  return interface_->GetError();
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetFenceivNV(GLuint fence,
                                                          GLenum pname,
                                                          GLint* params) {
  MakeFunctionUnique("glGetFenceivNV");
  interface_->GetFenceivNV(fence, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetFloatv(GLenum pname, GLfloat* params) {
  MakeFunctionUnique("glGetFloatv");
  interface_->GetFloatv(pname, params);
}

GLint GL_BINDING_CALL
MockGLInterface::Mock_glGetFragDataLocation(GLuint program, const char* name) {
  MakeFunctionUnique("glGetFragDataLocation");
  return interface_->GetFragDataLocation(program, name);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetFramebufferAttachmentParameteriv(GLenum target,
                                                            GLenum attachment,
                                                            GLenum pname,
                                                            GLint* params) {
  MakeFunctionUnique("glGetFramebufferAttachmentParameteriv");
  interface_->GetFramebufferAttachmentParameterivEXT(target, attachment, pname,
                                                     params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetFramebufferAttachmentParameterivEXT(
    GLenum target,
    GLenum attachment,
    GLenum pname,
    GLint* params) {
  MakeFunctionUnique("glGetFramebufferAttachmentParameterivEXT");
  interface_->GetFramebufferAttachmentParameterivEXT(target, attachment, pname,
                                                     params);
}

GLenum GL_BINDING_CALL MockGLInterface::Mock_glGetGraphicsResetStatus(void) {
  MakeFunctionUnique("glGetGraphicsResetStatus");
  return interface_->GetGraphicsResetStatusARB();
}

GLenum GL_BINDING_CALL MockGLInterface::Mock_glGetGraphicsResetStatusARB(void) {
  MakeFunctionUnique("glGetGraphicsResetStatusARB");
  return interface_->GetGraphicsResetStatusARB();
}

GLenum GL_BINDING_CALL MockGLInterface::Mock_glGetGraphicsResetStatusEXT(void) {
  MakeFunctionUnique("glGetGraphicsResetStatusEXT");
  return interface_->GetGraphicsResetStatusARB();
}

GLenum GL_BINDING_CALL MockGLInterface::Mock_glGetGraphicsResetStatusKHR(void) {
  MakeFunctionUnique("glGetGraphicsResetStatusKHR");
  return interface_->GetGraphicsResetStatusARB();
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetInteger64i_v(GLenum target,
                                                             GLuint index,
                                                             GLint64* data) {
  MakeFunctionUnique("glGetInteger64i_v");
  interface_->GetInteger64i_v(target, index, data);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetInteger64v(GLenum pname, GLint64* params) {
  MakeFunctionUnique("glGetInteger64v");
  interface_->GetInteger64v(pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetIntegeri_v(GLenum target,
                                                           GLuint index,
                                                           GLint* data) {
  MakeFunctionUnique("glGetIntegeri_v");
  interface_->GetIntegeri_v(target, index, data);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetIntegerv(GLenum pname, GLint* params) {
  MakeFunctionUnique("glGetIntegerv");
  interface_->GetIntegerv(pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetInternalformativ(GLenum target,
                                            GLenum internalformat,
                                            GLenum pname,
                                            GLsizei bufSize,
                                            GLint* params) {
  MakeFunctionUnique("glGetInternalformativ");
  interface_->GetInternalformativ(target, internalformat, pname, bufSize,
                                  params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetProgramBinary(GLuint program,
                                         GLsizei bufSize,
                                         GLsizei* length,
                                         GLenum* binaryFormat,
                                         GLvoid* binary) {
  MakeFunctionUnique("glGetProgramBinary");
  interface_->GetProgramBinary(program, bufSize, length, binaryFormat, binary);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetProgramBinaryOES(GLuint program,
                                            GLsizei bufSize,
                                            GLsizei* length,
                                            GLenum* binaryFormat,
                                            GLvoid* binary) {
  MakeFunctionUnique("glGetProgramBinaryOES");
  interface_->GetProgramBinary(program, bufSize, length, binaryFormat, binary);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetProgramInfoLog(GLuint program,
                                                               GLsizei bufsize,
                                                               GLsizei* length,
                                                               char* infolog) {
  MakeFunctionUnique("glGetProgramInfoLog");
  interface_->GetProgramInfoLog(program, bufsize, length, infolog);
}

GLint GL_BINDING_CALL
MockGLInterface::Mock_glGetProgramResourceLocation(GLuint program,
                                                   GLenum programInterface,
                                                   const char* name) {
  MakeFunctionUnique("glGetProgramResourceLocation");
  return interface_->GetProgramResourceLocation(program, programInterface,
                                                name);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetProgramiv(GLuint program,
                                                          GLenum pname,
                                                          GLint* params) {
  MakeFunctionUnique("glGetProgramiv");
  interface_->GetProgramiv(program, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetQueryObjecti64v(GLuint id,
                                           GLenum pname,
                                           GLint64* params) {
  MakeFunctionUnique("glGetQueryObjecti64v");
  interface_->GetQueryObjecti64v(id, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetQueryObjecti64vEXT(GLuint id,
                                              GLenum pname,
                                              GLint64* params) {
  MakeFunctionUnique("glGetQueryObjecti64vEXT");
  interface_->GetQueryObjecti64v(id, pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetQueryObjectiv(GLuint id,
                                                              GLenum pname,
                                                              GLint* params) {
  MakeFunctionUnique("glGetQueryObjectiv");
  interface_->GetQueryObjectiv(id, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetQueryObjectivARB(GLuint id,
                                            GLenum pname,
                                            GLint* params) {
  MakeFunctionUnique("glGetQueryObjectivARB");
  interface_->GetQueryObjectiv(id, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetQueryObjectivEXT(GLuint id,
                                            GLenum pname,
                                            GLint* params) {
  MakeFunctionUnique("glGetQueryObjectivEXT");
  interface_->GetQueryObjectiv(id, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetQueryObjectui64v(GLuint id,
                                            GLenum pname,
                                            GLuint64* params) {
  MakeFunctionUnique("glGetQueryObjectui64v");
  interface_->GetQueryObjectui64v(id, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetQueryObjectui64vEXT(GLuint id,
                                               GLenum pname,
                                               GLuint64* params) {
  MakeFunctionUnique("glGetQueryObjectui64vEXT");
  interface_->GetQueryObjectui64v(id, pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetQueryObjectuiv(GLuint id,
                                                               GLenum pname,
                                                               GLuint* params) {
  MakeFunctionUnique("glGetQueryObjectuiv");
  interface_->GetQueryObjectuiv(id, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetQueryObjectuivARB(GLuint id,
                                             GLenum pname,
                                             GLuint* params) {
  MakeFunctionUnique("glGetQueryObjectuivARB");
  interface_->GetQueryObjectuiv(id, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetQueryObjectuivEXT(GLuint id,
                                             GLenum pname,
                                             GLuint* params) {
  MakeFunctionUnique("glGetQueryObjectuivEXT");
  interface_->GetQueryObjectuiv(id, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetQueryiv(GLenum target, GLenum pname, GLint* params) {
  MakeFunctionUnique("glGetQueryiv");
  interface_->GetQueryiv(target, pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetQueryivARB(GLenum target,
                                                           GLenum pname,
                                                           GLint* params) {
  MakeFunctionUnique("glGetQueryivARB");
  interface_->GetQueryiv(target, pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetQueryivEXT(GLenum target,
                                                           GLenum pname,
                                                           GLint* params) {
  MakeFunctionUnique("glGetQueryivEXT");
  interface_->GetQueryiv(target, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetRenderbufferParameteriv(GLenum target,
                                                   GLenum pname,
                                                   GLint* params) {
  MakeFunctionUnique("glGetRenderbufferParameteriv");
  interface_->GetRenderbufferParameterivEXT(target, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetRenderbufferParameterivEXT(GLenum target,
                                                      GLenum pname,
                                                      GLint* params) {
  MakeFunctionUnique("glGetRenderbufferParameterivEXT");
  interface_->GetRenderbufferParameterivEXT(target, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetSamplerParameterfv(GLuint sampler,
                                              GLenum pname,
                                              GLfloat* params) {
  MakeFunctionUnique("glGetSamplerParameterfv");
  interface_->GetSamplerParameterfv(sampler, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetSamplerParameteriv(GLuint sampler,
                                              GLenum pname,
                                              GLint* params) {
  MakeFunctionUnique("glGetSamplerParameteriv");
  interface_->GetSamplerParameteriv(sampler, pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetShaderInfoLog(GLuint shader,
                                                              GLsizei bufsize,
                                                              GLsizei* length,
                                                              char* infolog) {
  MakeFunctionUnique("glGetShaderInfoLog");
  interface_->GetShaderInfoLog(shader, bufsize, length, infolog);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetShaderPrecisionFormat(GLenum shadertype,
                                                 GLenum precisiontype,
                                                 GLint* range,
                                                 GLint* precision) {
  MakeFunctionUnique("glGetShaderPrecisionFormat");
  interface_->GetShaderPrecisionFormat(shadertype, precisiontype, range,
                                       precision);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetShaderSource(GLuint shader,
                                                             GLsizei bufsize,
                                                             GLsizei* length,
                                                             char* source) {
  MakeFunctionUnique("glGetShaderSource");
  interface_->GetShaderSource(shader, bufsize, length, source);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetShaderiv(GLuint shader,
                                                         GLenum pname,
                                                         GLint* params) {
  MakeFunctionUnique("glGetShaderiv");
  interface_->GetShaderiv(shader, pname, params);
}

const GLubyte* GL_BINDING_CALL MockGLInterface::Mock_glGetString(GLenum name) {
  MakeFunctionUnique("glGetString");
  return interface_->GetString(name);
}

const GLubyte* GL_BINDING_CALL
MockGLInterface::Mock_glGetStringi(GLenum name, GLuint index) {
  MakeFunctionUnique("glGetStringi");
  return interface_->GetStringi(name, index);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetSynciv(GLsync sync,
                                                       GLenum pname,
                                                       GLsizei bufSize,
                                                       GLsizei* length,
                                                       GLint* values) {
  MakeFunctionUnique("glGetSynciv");
  interface_->GetSynciv(sync, pname, bufSize, length, values);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetTexLevelParameterfv(GLenum target,
                                               GLint level,
                                               GLenum pname,
                                               GLfloat* params) {
  MakeFunctionUnique("glGetTexLevelParameterfv");
  interface_->GetTexLevelParameterfv(target, level, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetTexLevelParameteriv(GLenum target,
                                               GLint level,
                                               GLenum pname,
                                               GLint* params) {
  MakeFunctionUnique("glGetTexLevelParameteriv");
  interface_->GetTexLevelParameteriv(target, level, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetTexParameterfv(GLenum target,
                                          GLenum pname,
                                          GLfloat* params) {
  MakeFunctionUnique("glGetTexParameterfv");
  interface_->GetTexParameterfv(target, pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetTexParameteriv(GLenum target,
                                                               GLenum pname,
                                                               GLint* params) {
  MakeFunctionUnique("glGetTexParameteriv");
  interface_->GetTexParameteriv(target, pname, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetTransformFeedbackVarying(GLuint program,
                                                    GLuint index,
                                                    GLsizei bufSize,
                                                    GLsizei* length,
                                                    GLsizei* size,
                                                    GLenum* type,
                                                    char* name) {
  MakeFunctionUnique("glGetTransformFeedbackVarying");
  interface_->GetTransformFeedbackVarying(program, index, bufSize, length, size,
                                          type, name);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetTranslatedShaderSourceANGLE(GLuint shader,
                                                       GLsizei bufsize,
                                                       GLsizei* length,
                                                       char* source) {
  MakeFunctionUnique("glGetTranslatedShaderSourceANGLE");
  interface_->GetTranslatedShaderSourceANGLE(shader, bufsize, length, source);
}

GLuint GL_BINDING_CALL
MockGLInterface::Mock_glGetUniformBlockIndex(GLuint program,
                                             const char* uniformBlockName) {
  MakeFunctionUnique("glGetUniformBlockIndex");
  return interface_->GetUniformBlockIndex(program, uniformBlockName);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetUniformIndices(GLuint program,
                                          GLsizei uniformCount,
                                          const char* const* uniformNames,
                                          GLuint* uniformIndices) {
  MakeFunctionUnique("glGetUniformIndices");
  interface_->GetUniformIndices(program, uniformCount, uniformNames,
                                uniformIndices);
}

GLint GL_BINDING_CALL
MockGLInterface::Mock_glGetUniformLocation(GLuint program, const char* name) {
  MakeFunctionUnique("glGetUniformLocation");
  return interface_->GetUniformLocation(program, name);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetUniformfv(GLuint program,
                                                          GLint location,
                                                          GLfloat* params) {
  MakeFunctionUnique("glGetUniformfv");
  interface_->GetUniformfv(program, location, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetUniformiv(GLuint program,
                                                          GLint location,
                                                          GLint* params) {
  MakeFunctionUnique("glGetUniformiv");
  interface_->GetUniformiv(program, location, params);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetVertexAttribPointerv(GLuint index,
                                                GLenum pname,
                                                void** pointer) {
  MakeFunctionUnique("glGetVertexAttribPointerv");
  interface_->GetVertexAttribPointerv(index, pname, pointer);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glGetVertexAttribfv(GLuint index,
                                          GLenum pname,
                                          GLfloat* params) {
  MakeFunctionUnique("glGetVertexAttribfv");
  interface_->GetVertexAttribfv(index, pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glGetVertexAttribiv(GLuint index,
                                                               GLenum pname,
                                                               GLint* params) {
  MakeFunctionUnique("glGetVertexAttribiv");
  interface_->GetVertexAttribiv(index, pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glHint(GLenum target, GLenum mode) {
  MakeFunctionUnique("glHint");
  interface_->Hint(target, mode);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glInsertEventMarkerEXT(GLsizei length,
                                             const char* marker) {
  MakeFunctionUnique("glInsertEventMarkerEXT");
  interface_->InsertEventMarkerEXT(length, marker);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glInvalidateFramebuffer(GLenum target,
                                              GLsizei numAttachments,
                                              const GLenum* attachments) {
  MakeFunctionUnique("glInvalidateFramebuffer");
  interface_->InvalidateFramebuffer(target, numAttachments, attachments);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glInvalidateSubFramebuffer(GLenum target,
                                                 GLsizei numAttachments,
                                                 const GLenum* attachments,
                                                 GLint x,
                                                 GLint y,
                                                 GLint width,
                                                 GLint height) {
  MakeFunctionUnique("glInvalidateSubFramebuffer");
  interface_->InvalidateSubFramebuffer(target, numAttachments, attachments, x,
                                       y, width, height);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsBuffer(GLuint buffer) {
  MakeFunctionUnique("glIsBuffer");
  return interface_->IsBuffer(buffer);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsEnabled(GLenum cap) {
  MakeFunctionUnique("glIsEnabled");
  return interface_->IsEnabled(cap);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsFenceAPPLE(GLuint fence) {
  MakeFunctionUnique("glIsFenceAPPLE");
  return interface_->IsFenceAPPLE(fence);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsFenceNV(GLuint fence) {
  MakeFunctionUnique("glIsFenceNV");
  return interface_->IsFenceNV(fence);
}

GLboolean GL_BINDING_CALL
MockGLInterface::Mock_glIsFramebuffer(GLuint framebuffer) {
  MakeFunctionUnique("glIsFramebuffer");
  return interface_->IsFramebufferEXT(framebuffer);
}

GLboolean GL_BINDING_CALL
MockGLInterface::Mock_glIsFramebufferEXT(GLuint framebuffer) {
  MakeFunctionUnique("glIsFramebufferEXT");
  return interface_->IsFramebufferEXT(framebuffer);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsProgram(GLuint program) {
  MakeFunctionUnique("glIsProgram");
  return interface_->IsProgram(program);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsQuery(GLuint query) {
  MakeFunctionUnique("glIsQuery");
  return interface_->IsQuery(query);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsQueryARB(GLuint query) {
  MakeFunctionUnique("glIsQueryARB");
  return interface_->IsQuery(query);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsQueryEXT(GLuint query) {
  MakeFunctionUnique("glIsQueryEXT");
  return interface_->IsQuery(query);
}

GLboolean GL_BINDING_CALL
MockGLInterface::Mock_glIsRenderbuffer(GLuint renderbuffer) {
  MakeFunctionUnique("glIsRenderbuffer");
  return interface_->IsRenderbufferEXT(renderbuffer);
}

GLboolean GL_BINDING_CALL
MockGLInterface::Mock_glIsRenderbufferEXT(GLuint renderbuffer) {
  MakeFunctionUnique("glIsRenderbufferEXT");
  return interface_->IsRenderbufferEXT(renderbuffer);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsSampler(GLuint sampler) {
  MakeFunctionUnique("glIsSampler");
  return interface_->IsSampler(sampler);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsShader(GLuint shader) {
  MakeFunctionUnique("glIsShader");
  return interface_->IsShader(shader);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsSync(GLsync sync) {
  MakeFunctionUnique("glIsSync");
  return interface_->IsSync(sync);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsTexture(GLuint texture) {
  MakeFunctionUnique("glIsTexture");
  return interface_->IsTexture(texture);
}

GLboolean GL_BINDING_CALL
MockGLInterface::Mock_glIsTransformFeedback(GLuint id) {
  MakeFunctionUnique("glIsTransformFeedback");
  return interface_->IsTransformFeedback(id);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glIsVertexArray(GLuint array) {
  MakeFunctionUnique("glIsVertexArray");
  return interface_->IsVertexArrayOES(array);
}

GLboolean GL_BINDING_CALL
MockGLInterface::Mock_glIsVertexArrayAPPLE(GLuint array) {
  MakeFunctionUnique("glIsVertexArrayAPPLE");
  return interface_->IsVertexArrayOES(array);
}

GLboolean GL_BINDING_CALL
MockGLInterface::Mock_glIsVertexArrayOES(GLuint array) {
  MakeFunctionUnique("glIsVertexArrayOES");
  return interface_->IsVertexArrayOES(array);
}

void GL_BINDING_CALL MockGLInterface::Mock_glLineWidth(GLfloat width) {
  MakeFunctionUnique("glLineWidth");
  interface_->LineWidth(width);
}

void GL_BINDING_CALL MockGLInterface::Mock_glLinkProgram(GLuint program) {
  MakeFunctionUnique("glLinkProgram");
  interface_->LinkProgram(program);
}

void* GL_BINDING_CALL
MockGLInterface::Mock_glMapBuffer(GLenum target, GLenum access) {
  MakeFunctionUnique("glMapBuffer");
  return interface_->MapBuffer(target, access);
}

void* GL_BINDING_CALL
MockGLInterface::Mock_glMapBufferOES(GLenum target, GLenum access) {
  MakeFunctionUnique("glMapBufferOES");
  return interface_->MapBuffer(target, access);
}

void* GL_BINDING_CALL
MockGLInterface::Mock_glMapBufferRange(GLenum target,
                                       GLintptr offset,
                                       GLsizeiptr length,
                                       GLbitfield access) {
  MakeFunctionUnique("glMapBufferRange");
  return interface_->MapBufferRange(target, offset, length, access);
}

void* GL_BINDING_CALL
MockGLInterface::Mock_glMapBufferRangeEXT(GLenum target,
                                          GLintptr offset,
                                          GLsizeiptr length,
                                          GLbitfield access) {
  MakeFunctionUnique("glMapBufferRangeEXT");
  return interface_->MapBufferRange(target, offset, length, access);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glMatrixLoadIdentityEXT(GLenum matrixMode) {
  MakeFunctionUnique("glMatrixLoadIdentityEXT");
  interface_->MatrixLoadIdentityEXT(matrixMode);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glMatrixLoadfEXT(GLenum matrixMode, const GLfloat* m) {
  MakeFunctionUnique("glMatrixLoadfEXT");
  interface_->MatrixLoadfEXT(matrixMode, m);
}

void GL_BINDING_CALL MockGLInterface::Mock_glPauseTransformFeedback(void) {
  MakeFunctionUnique("glPauseTransformFeedback");
  interface_->PauseTransformFeedback();
}

void GL_BINDING_CALL
MockGLInterface::Mock_glPixelStorei(GLenum pname, GLint param) {
  MakeFunctionUnique("glPixelStorei");
  interface_->PixelStorei(pname, param);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glPointParameteri(GLenum pname, GLint param) {
  MakeFunctionUnique("glPointParameteri");
  interface_->PointParameteri(pname, param);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glPolygonOffset(GLfloat factor, GLfloat units) {
  MakeFunctionUnique("glPolygonOffset");
  interface_->PolygonOffset(factor, units);
}

void GL_BINDING_CALL MockGLInterface::Mock_glPopGroupMarkerEXT(void) {
  MakeFunctionUnique("glPopGroupMarkerEXT");
  interface_->PopGroupMarkerEXT();
}

void GL_BINDING_CALL MockGLInterface::Mock_glProgramBinary(GLuint program,
                                                           GLenum binaryFormat,
                                                           const GLvoid* binary,
                                                           GLsizei length) {
  MakeFunctionUnique("glProgramBinary");
  interface_->ProgramBinary(program, binaryFormat, binary, length);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glProgramBinaryOES(GLuint program,
                                         GLenum binaryFormat,
                                         const GLvoid* binary,
                                         GLsizei length) {
  MakeFunctionUnique("glProgramBinaryOES");
  interface_->ProgramBinary(program, binaryFormat, binary, length);
}

void GL_BINDING_CALL MockGLInterface::Mock_glProgramParameteri(GLuint program,
                                                               GLenum pname,
                                                               GLint value) {
  MakeFunctionUnique("glProgramParameteri");
  interface_->ProgramParameteri(program, pname, value);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glPushGroupMarkerEXT(GLsizei length, const char* marker) {
  MakeFunctionUnique("glPushGroupMarkerEXT");
  interface_->PushGroupMarkerEXT(length, marker);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glQueryCounter(GLuint id, GLenum target) {
  MakeFunctionUnique("glQueryCounter");
  interface_->QueryCounter(id, target);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glQueryCounterEXT(GLuint id, GLenum target) {
  MakeFunctionUnique("glQueryCounterEXT");
  interface_->QueryCounter(id, target);
}

void GL_BINDING_CALL MockGLInterface::Mock_glReadBuffer(GLenum src) {
  MakeFunctionUnique("glReadBuffer");
  interface_->ReadBuffer(src);
}

void GL_BINDING_CALL MockGLInterface::Mock_glReadPixels(GLint x,
                                                        GLint y,
                                                        GLsizei width,
                                                        GLsizei height,
                                                        GLenum format,
                                                        GLenum type,
                                                        void* pixels) {
  MakeFunctionUnique("glReadPixels");
  interface_->ReadPixels(x, y, width, height, format, type, pixels);
}

void GL_BINDING_CALL MockGLInterface::Mock_glReleaseShaderCompiler(void) {
  MakeFunctionUnique("glReleaseShaderCompiler");
  interface_->ReleaseShaderCompiler();
}

void GL_BINDING_CALL
MockGLInterface::Mock_glRenderbufferStorage(GLenum target,
                                            GLenum internalformat,
                                            GLsizei width,
                                            GLsizei height) {
  MakeFunctionUnique("glRenderbufferStorage");
  interface_->RenderbufferStorageEXT(target, internalformat, width, height);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glRenderbufferStorageEXT(GLenum target,
                                               GLenum internalformat,
                                               GLsizei width,
                                               GLsizei height) {
  MakeFunctionUnique("glRenderbufferStorageEXT");
  interface_->RenderbufferStorageEXT(target, internalformat, width, height);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glRenderbufferStorageMultisample(GLenum target,
                                                       GLsizei samples,
                                                       GLenum internalformat,
                                                       GLsizei width,
                                                       GLsizei height) {
  MakeFunctionUnique("glRenderbufferStorageMultisample");
  interface_->RenderbufferStorageMultisample(target, samples, internalformat,
                                             width, height);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glRenderbufferStorageMultisampleANGLE(
    GLenum target,
    GLsizei samples,
    GLenum internalformat,
    GLsizei width,
    GLsizei height) {
  MakeFunctionUnique("glRenderbufferStorageMultisampleANGLE");
  interface_->RenderbufferStorageMultisampleANGLE(
      target, samples, internalformat, width, height);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glRenderbufferStorageMultisampleAPPLE(
    GLenum target,
    GLsizei samples,
    GLenum internalformat,
    GLsizei width,
    GLsizei height) {
  MakeFunctionUnique("glRenderbufferStorageMultisampleAPPLE");
  interface_->RenderbufferStorageMultisampleAPPLE(
      target, samples, internalformat, width, height);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glRenderbufferStorageMultisampleEXT(GLenum target,
                                                          GLsizei samples,
                                                          GLenum internalformat,
                                                          GLsizei width,
                                                          GLsizei height) {
  MakeFunctionUnique("glRenderbufferStorageMultisampleEXT");
  interface_->RenderbufferStorageMultisampleEXT(target, samples, internalformat,
                                                width, height);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glRenderbufferStorageMultisampleIMG(GLenum target,
                                                          GLsizei samples,
                                                          GLenum internalformat,
                                                          GLsizei width,
                                                          GLsizei height) {
  MakeFunctionUnique("glRenderbufferStorageMultisampleIMG");
  interface_->RenderbufferStorageMultisampleIMG(target, samples, internalformat,
                                                width, height);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glResolveMultisampleFramebufferAPPLE(void) {
  MakeFunctionUnique("glResolveMultisampleFramebufferAPPLE");
  interface_->ResolveMultisampleFramebufferAPPLE();
}

void GL_BINDING_CALL MockGLInterface::Mock_glResumeTransformFeedback(void) {
  MakeFunctionUnique("glResumeTransformFeedback");
  interface_->ResumeTransformFeedback();
}

void GL_BINDING_CALL
MockGLInterface::Mock_glSampleCoverage(GLclampf value, GLboolean invert) {
  MakeFunctionUnique("glSampleCoverage");
  interface_->SampleCoverage(value, invert);
}

void GL_BINDING_CALL MockGLInterface::Mock_glSamplerParameterf(GLuint sampler,
                                                               GLenum pname,
                                                               GLfloat param) {
  MakeFunctionUnique("glSamplerParameterf");
  interface_->SamplerParameterf(sampler, pname, param);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glSamplerParameterfv(GLuint sampler,
                                           GLenum pname,
                                           const GLfloat* params) {
  MakeFunctionUnique("glSamplerParameterfv");
  interface_->SamplerParameterfv(sampler, pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glSamplerParameteri(GLuint sampler,
                                                               GLenum pname,
                                                               GLint param) {
  MakeFunctionUnique("glSamplerParameteri");
  interface_->SamplerParameteri(sampler, pname, param);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glSamplerParameteriv(GLuint sampler,
                                           GLenum pname,
                                           const GLint* params) {
  MakeFunctionUnique("glSamplerParameteriv");
  interface_->SamplerParameteriv(sampler, pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glScissor(GLint x,
                                                     GLint y,
                                                     GLsizei width,
                                                     GLsizei height) {
  MakeFunctionUnique("glScissor");
  interface_->Scissor(x, y, width, height);
}

void GL_BINDING_CALL MockGLInterface::Mock_glSetFenceAPPLE(GLuint fence) {
  MakeFunctionUnique("glSetFenceAPPLE");
  interface_->SetFenceAPPLE(fence);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glSetFenceNV(GLuint fence, GLenum condition) {
  MakeFunctionUnique("glSetFenceNV");
  interface_->SetFenceNV(fence, condition);
}

void GL_BINDING_CALL MockGLInterface::Mock_glShaderBinary(GLsizei n,
                                                          const GLuint* shaders,
                                                          GLenum binaryformat,
                                                          const void* binary,
                                                          GLsizei length) {
  MakeFunctionUnique("glShaderBinary");
  interface_->ShaderBinary(n, shaders, binaryformat, binary, length);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glShaderSource(GLuint shader,
                                     GLsizei count,
                                     const char* const* str,
                                     const GLint* length) {
  MakeFunctionUnique("glShaderSource");
  interface_->ShaderSource(shader, count, str, length);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glStencilFunc(GLenum func, GLint ref, GLuint mask) {
  MakeFunctionUnique("glStencilFunc");
  interface_->StencilFunc(func, ref, mask);
}

void GL_BINDING_CALL MockGLInterface::Mock_glStencilFuncSeparate(GLenum face,
                                                                 GLenum func,
                                                                 GLint ref,
                                                                 GLuint mask) {
  MakeFunctionUnique("glStencilFuncSeparate");
  interface_->StencilFuncSeparate(face, func, ref, mask);
}

void GL_BINDING_CALL MockGLInterface::Mock_glStencilMask(GLuint mask) {
  MakeFunctionUnique("glStencilMask");
  interface_->StencilMask(mask);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glStencilMaskSeparate(GLenum face, GLuint mask) {
  MakeFunctionUnique("glStencilMaskSeparate");
  interface_->StencilMaskSeparate(face, mask);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glStencilOp(GLenum fail, GLenum zfail, GLenum zpass) {
  MakeFunctionUnique("glStencilOp");
  interface_->StencilOp(fail, zfail, zpass);
}

void GL_BINDING_CALL MockGLInterface::Mock_glStencilOpSeparate(GLenum face,
                                                               GLenum fail,
                                                               GLenum zfail,
                                                               GLenum zpass) {
  MakeFunctionUnique("glStencilOpSeparate");
  interface_->StencilOpSeparate(face, fail, zfail, zpass);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glTestFenceAPPLE(GLuint fence) {
  MakeFunctionUnique("glTestFenceAPPLE");
  return interface_->TestFenceAPPLE(fence);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glTestFenceNV(GLuint fence) {
  MakeFunctionUnique("glTestFenceNV");
  return interface_->TestFenceNV(fence);
}

void GL_BINDING_CALL MockGLInterface::Mock_glTexImage2D(GLenum target,
                                                        GLint level,
                                                        GLint internalformat,
                                                        GLsizei width,
                                                        GLsizei height,
                                                        GLint border,
                                                        GLenum format,
                                                        GLenum type,
                                                        const void* pixels) {
  MakeFunctionUnique("glTexImage2D");
  interface_->TexImage2D(target, level, internalformat, width, height, border,
                         format, type, pixels);
}

void GL_BINDING_CALL MockGLInterface::Mock_glTexImage3D(GLenum target,
                                                        GLint level,
                                                        GLint internalformat,
                                                        GLsizei width,
                                                        GLsizei height,
                                                        GLsizei depth,
                                                        GLint border,
                                                        GLenum format,
                                                        GLenum type,
                                                        const void* pixels) {
  MakeFunctionUnique("glTexImage3D");
  interface_->TexImage3D(target, level, internalformat, width, height, depth,
                         border, format, type, pixels);
}

void GL_BINDING_CALL MockGLInterface::Mock_glTexParameterf(GLenum target,
                                                           GLenum pname,
                                                           GLfloat param) {
  MakeFunctionUnique("glTexParameterf");
  interface_->TexParameterf(target, pname, param);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glTexParameterfv(GLenum target,
                                       GLenum pname,
                                       const GLfloat* params) {
  MakeFunctionUnique("glTexParameterfv");
  interface_->TexParameterfv(target, pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glTexParameteri(GLenum target,
                                                           GLenum pname,
                                                           GLint param) {
  MakeFunctionUnique("glTexParameteri");
  interface_->TexParameteri(target, pname, param);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glTexParameteriv(GLenum target,
                                       GLenum pname,
                                       const GLint* params) {
  MakeFunctionUnique("glTexParameteriv");
  interface_->TexParameteriv(target, pname, params);
}

void GL_BINDING_CALL MockGLInterface::Mock_glTexStorage2D(GLenum target,
                                                          GLsizei levels,
                                                          GLenum internalformat,
                                                          GLsizei width,
                                                          GLsizei height) {
  MakeFunctionUnique("glTexStorage2D");
  interface_->TexStorage2DEXT(target, levels, internalformat, width, height);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glTexStorage2DEXT(GLenum target,
                                        GLsizei levels,
                                        GLenum internalformat,
                                        GLsizei width,
                                        GLsizei height) {
  MakeFunctionUnique("glTexStorage2DEXT");
  interface_->TexStorage2DEXT(target, levels, internalformat, width, height);
}

void GL_BINDING_CALL MockGLInterface::Mock_glTexStorage3D(GLenum target,
                                                          GLsizei levels,
                                                          GLenum internalformat,
                                                          GLsizei width,
                                                          GLsizei height,
                                                          GLsizei depth) {
  MakeFunctionUnique("glTexStorage3D");
  interface_->TexStorage3D(target, levels, internalformat, width, height,
                           depth);
}

void GL_BINDING_CALL MockGLInterface::Mock_glTexSubImage2D(GLenum target,
                                                           GLint level,
                                                           GLint xoffset,
                                                           GLint yoffset,
                                                           GLsizei width,
                                                           GLsizei height,
                                                           GLenum format,
                                                           GLenum type,
                                                           const void* pixels) {
  MakeFunctionUnique("glTexSubImage2D");
  interface_->TexSubImage2D(target, level, xoffset, yoffset, width, height,
                            format, type, pixels);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glTransformFeedbackVaryings(GLuint program,
                                                  GLsizei count,
                                                  const char* const* varyings,
                                                  GLenum bufferMode) {
  MakeFunctionUnique("glTransformFeedbackVaryings");
  interface_->TransformFeedbackVaryings(program, count, varyings, bufferMode);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniform1f(GLint location, GLfloat x) {
  MakeFunctionUnique("glUniform1f");
  interface_->Uniform1f(location, x);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform1fv(GLint location,
                                                        GLsizei count,
                                                        const GLfloat* v) {
  MakeFunctionUnique("glUniform1fv");
  interface_->Uniform1fv(location, count, v);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniform1i(GLint location, GLint x) {
  MakeFunctionUnique("glUniform1i");
  interface_->Uniform1i(location, x);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform1iv(GLint location,
                                                        GLsizei count,
                                                        const GLint* v) {
  MakeFunctionUnique("glUniform1iv");
  interface_->Uniform1iv(location, count, v);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniform1ui(GLint location, GLuint v0) {
  MakeFunctionUnique("glUniform1ui");
  interface_->Uniform1ui(location, v0);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform1uiv(GLint location,
                                                         GLsizei count,
                                                         const GLuint* v) {
  MakeFunctionUnique("glUniform1uiv");
  interface_->Uniform1uiv(location, count, v);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniform2f(GLint location, GLfloat x, GLfloat y) {
  MakeFunctionUnique("glUniform2f");
  interface_->Uniform2f(location, x, y);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform2fv(GLint location,
                                                        GLsizei count,
                                                        const GLfloat* v) {
  MakeFunctionUnique("glUniform2fv");
  interface_->Uniform2fv(location, count, v);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniform2i(GLint location, GLint x, GLint y) {
  MakeFunctionUnique("glUniform2i");
  interface_->Uniform2i(location, x, y);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform2iv(GLint location,
                                                        GLsizei count,
                                                        const GLint* v) {
  MakeFunctionUnique("glUniform2iv");
  interface_->Uniform2iv(location, count, v);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniform2ui(GLint location, GLuint v0, GLuint v1) {
  MakeFunctionUnique("glUniform2ui");
  interface_->Uniform2ui(location, v0, v1);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform2uiv(GLint location,
                                                         GLsizei count,
                                                         const GLuint* v) {
  MakeFunctionUnique("glUniform2uiv");
  interface_->Uniform2uiv(location, count, v);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform3f(GLint location,
                                                       GLfloat x,
                                                       GLfloat y,
                                                       GLfloat z) {
  MakeFunctionUnique("glUniform3f");
  interface_->Uniform3f(location, x, y, z);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform3fv(GLint location,
                                                        GLsizei count,
                                                        const GLfloat* v) {
  MakeFunctionUnique("glUniform3fv");
  interface_->Uniform3fv(location, count, v);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniform3i(GLint location, GLint x, GLint y, GLint z) {
  MakeFunctionUnique("glUniform3i");
  interface_->Uniform3i(location, x, y, z);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform3iv(GLint location,
                                                        GLsizei count,
                                                        const GLint* v) {
  MakeFunctionUnique("glUniform3iv");
  interface_->Uniform3iv(location, count, v);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform3ui(GLint location,
                                                        GLuint v0,
                                                        GLuint v1,
                                                        GLuint v2) {
  MakeFunctionUnique("glUniform3ui");
  interface_->Uniform3ui(location, v0, v1, v2);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform3uiv(GLint location,
                                                         GLsizei count,
                                                         const GLuint* v) {
  MakeFunctionUnique("glUniform3uiv");
  interface_->Uniform3uiv(location, count, v);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform4f(GLint location,
                                                       GLfloat x,
                                                       GLfloat y,
                                                       GLfloat z,
                                                       GLfloat w) {
  MakeFunctionUnique("glUniform4f");
  interface_->Uniform4f(location, x, y, z, w);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform4fv(GLint location,
                                                        GLsizei count,
                                                        const GLfloat* v) {
  MakeFunctionUnique("glUniform4fv");
  interface_->Uniform4fv(location, count, v);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform4i(GLint location,
                                                       GLint x,
                                                       GLint y,
                                                       GLint z,
                                                       GLint w) {
  MakeFunctionUnique("glUniform4i");
  interface_->Uniform4i(location, x, y, z, w);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform4iv(GLint location,
                                                        GLsizei count,
                                                        const GLint* v) {
  MakeFunctionUnique("glUniform4iv");
  interface_->Uniform4iv(location, count, v);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform4ui(GLint location,
                                                        GLuint v0,
                                                        GLuint v1,
                                                        GLuint v2,
                                                        GLuint v3) {
  MakeFunctionUnique("glUniform4ui");
  interface_->Uniform4ui(location, v0, v1, v2, v3);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUniform4uiv(GLint location,
                                                         GLsizei count,
                                                         const GLuint* v) {
  MakeFunctionUnique("glUniform4uiv");
  interface_->Uniform4uiv(location, count, v);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniformBlockBinding(GLuint program,
                                            GLuint uniformBlockIndex,
                                            GLuint uniformBlockBinding) {
  MakeFunctionUnique("glUniformBlockBinding");
  interface_->UniformBlockBinding(program, uniformBlockIndex,
                                  uniformBlockBinding);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniformMatrix2fv(GLint location,
                                         GLsizei count,
                                         GLboolean transpose,
                                         const GLfloat* value) {
  MakeFunctionUnique("glUniformMatrix2fv");
  interface_->UniformMatrix2fv(location, count, transpose, value);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniformMatrix2x3fv(GLint location,
                                           GLsizei count,
                                           GLboolean transpose,
                                           const GLfloat* value) {
  MakeFunctionUnique("glUniformMatrix2x3fv");
  interface_->UniformMatrix2x3fv(location, count, transpose, value);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniformMatrix2x4fv(GLint location,
                                           GLsizei count,
                                           GLboolean transpose,
                                           const GLfloat* value) {
  MakeFunctionUnique("glUniformMatrix2x4fv");
  interface_->UniformMatrix2x4fv(location, count, transpose, value);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniformMatrix3fv(GLint location,
                                         GLsizei count,
                                         GLboolean transpose,
                                         const GLfloat* value) {
  MakeFunctionUnique("glUniformMatrix3fv");
  interface_->UniformMatrix3fv(location, count, transpose, value);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniformMatrix3x2fv(GLint location,
                                           GLsizei count,
                                           GLboolean transpose,
                                           const GLfloat* value) {
  MakeFunctionUnique("glUniformMatrix3x2fv");
  interface_->UniformMatrix3x2fv(location, count, transpose, value);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniformMatrix3x4fv(GLint location,
                                           GLsizei count,
                                           GLboolean transpose,
                                           const GLfloat* value) {
  MakeFunctionUnique("glUniformMatrix3x4fv");
  interface_->UniformMatrix3x4fv(location, count, transpose, value);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniformMatrix4fv(GLint location,
                                         GLsizei count,
                                         GLboolean transpose,
                                         const GLfloat* value) {
  MakeFunctionUnique("glUniformMatrix4fv");
  interface_->UniformMatrix4fv(location, count, transpose, value);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniformMatrix4x2fv(GLint location,
                                           GLsizei count,
                                           GLboolean transpose,
                                           const GLfloat* value) {
  MakeFunctionUnique("glUniformMatrix4x2fv");
  interface_->UniformMatrix4x2fv(location, count, transpose, value);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glUniformMatrix4x3fv(GLint location,
                                           GLsizei count,
                                           GLboolean transpose,
                                           const GLfloat* value) {
  MakeFunctionUnique("glUniformMatrix4x3fv");
  interface_->UniformMatrix4x3fv(location, count, transpose, value);
}

GLboolean GL_BINDING_CALL MockGLInterface::Mock_glUnmapBuffer(GLenum target) {
  MakeFunctionUnique("glUnmapBuffer");
  return interface_->UnmapBuffer(target);
}

GLboolean GL_BINDING_CALL
MockGLInterface::Mock_glUnmapBufferOES(GLenum target) {
  MakeFunctionUnique("glUnmapBufferOES");
  return interface_->UnmapBuffer(target);
}

void GL_BINDING_CALL MockGLInterface::Mock_glUseProgram(GLuint program) {
  MakeFunctionUnique("glUseProgram");
  interface_->UseProgram(program);
}

void GL_BINDING_CALL MockGLInterface::Mock_glValidateProgram(GLuint program) {
  MakeFunctionUnique("glValidateProgram");
  interface_->ValidateProgram(program);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttrib1f(GLuint indx, GLfloat x) {
  MakeFunctionUnique("glVertexAttrib1f");
  interface_->VertexAttrib1f(indx, x);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttrib1fv(GLuint indx, const GLfloat* values) {
  MakeFunctionUnique("glVertexAttrib1fv");
  interface_->VertexAttrib1fv(indx, values);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttrib2f(GLuint indx, GLfloat x, GLfloat y) {
  MakeFunctionUnique("glVertexAttrib2f");
  interface_->VertexAttrib2f(indx, x, y);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttrib2fv(GLuint indx, const GLfloat* values) {
  MakeFunctionUnique("glVertexAttrib2fv");
  interface_->VertexAttrib2fv(indx, values);
}

void GL_BINDING_CALL MockGLInterface::Mock_glVertexAttrib3f(GLuint indx,
                                                            GLfloat x,
                                                            GLfloat y,
                                                            GLfloat z) {
  MakeFunctionUnique("glVertexAttrib3f");
  interface_->VertexAttrib3f(indx, x, y, z);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttrib3fv(GLuint indx, const GLfloat* values) {
  MakeFunctionUnique("glVertexAttrib3fv");
  interface_->VertexAttrib3fv(indx, values);
}

void GL_BINDING_CALL MockGLInterface::Mock_glVertexAttrib4f(GLuint indx,
                                                            GLfloat x,
                                                            GLfloat y,
                                                            GLfloat z,
                                                            GLfloat w) {
  MakeFunctionUnique("glVertexAttrib4f");
  interface_->VertexAttrib4f(indx, x, y, z, w);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttrib4fv(GLuint indx, const GLfloat* values) {
  MakeFunctionUnique("glVertexAttrib4fv");
  interface_->VertexAttrib4fv(indx, values);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttribDivisor(GLuint index, GLuint divisor) {
  MakeFunctionUnique("glVertexAttribDivisor");
  interface_->VertexAttribDivisorANGLE(index, divisor);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttribDivisorANGLE(GLuint index, GLuint divisor) {
  MakeFunctionUnique("glVertexAttribDivisorANGLE");
  interface_->VertexAttribDivisorANGLE(index, divisor);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttribDivisorARB(GLuint index, GLuint divisor) {
  MakeFunctionUnique("glVertexAttribDivisorARB");
  interface_->VertexAttribDivisorANGLE(index, divisor);
}

void GL_BINDING_CALL MockGLInterface::Mock_glVertexAttribI4i(GLuint indx,
                                                             GLint x,
                                                             GLint y,
                                                             GLint z,
                                                             GLint w) {
  MakeFunctionUnique("glVertexAttribI4i");
  interface_->VertexAttribI4i(indx, x, y, z, w);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttribI4iv(GLuint indx, const GLint* values) {
  MakeFunctionUnique("glVertexAttribI4iv");
  interface_->VertexAttribI4iv(indx, values);
}

void GL_BINDING_CALL MockGLInterface::Mock_glVertexAttribI4ui(GLuint indx,
                                                              GLuint x,
                                                              GLuint y,
                                                              GLuint z,
                                                              GLuint w) {
  MakeFunctionUnique("glVertexAttribI4ui");
  interface_->VertexAttribI4ui(indx, x, y, z, w);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttribI4uiv(GLuint indx, const GLuint* values) {
  MakeFunctionUnique("glVertexAttribI4uiv");
  interface_->VertexAttribI4uiv(indx, values);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttribIPointer(GLuint indx,
                                             GLint size,
                                             GLenum type,
                                             GLsizei stride,
                                             const void* ptr) {
  MakeFunctionUnique("glVertexAttribIPointer");
  interface_->VertexAttribIPointer(indx, size, type, stride, ptr);
}

void GL_BINDING_CALL
MockGLInterface::Mock_glVertexAttribPointer(GLuint indx,
                                            GLint size,
                                            GLenum type,
                                            GLboolean normalized,
                                            GLsizei stride,
                                            const void* ptr) {
  MakeFunctionUnique("glVertexAttribPointer");
  interface_->VertexAttribPointer(indx, size, type, normalized, stride, ptr);
}

void GL_BINDING_CALL MockGLInterface::Mock_glViewport(GLint x,
                                                      GLint y,
                                                      GLsizei width,
                                                      GLsizei height) {
  MakeFunctionUnique("glViewport");
  interface_->Viewport(x, y, width, height);
}

GLenum GL_BINDING_CALL MockGLInterface::Mock_glWaitSync(GLsync sync,
                                                        GLbitfield flags,
                                                        GLuint64 timeout) {
  MakeFunctionUnique("glWaitSync");
  return interface_->WaitSync(sync, flags, timeout);
}

static void MockInvalidFunction() {
  NOTREACHED();
}

void* GL_BINDING_CALL MockGLInterface::GetGLProcAddress(const char* name) {
  if (strcmp(name, "glActiveTexture") == 0)
    return reinterpret_cast<void*>(Mock_glActiveTexture);
  if (strcmp(name, "glAttachShader") == 0)
    return reinterpret_cast<void*>(Mock_glAttachShader);
  if (strcmp(name, "glBeginQuery") == 0)
    return reinterpret_cast<void*>(Mock_glBeginQuery);
  if (strcmp(name, "glBeginQueryARB") == 0)
    return reinterpret_cast<void*>(Mock_glBeginQueryARB);
  if (strcmp(name, "glBeginQueryEXT") == 0)
    return reinterpret_cast<void*>(Mock_glBeginQueryEXT);
  if (strcmp(name, "glBeginTransformFeedback") == 0)
    return reinterpret_cast<void*>(Mock_glBeginTransformFeedback);
  if (strcmp(name, "glBindAttribLocation") == 0)
    return reinterpret_cast<void*>(Mock_glBindAttribLocation);
  if (strcmp(name, "glBindBuffer") == 0)
    return reinterpret_cast<void*>(Mock_glBindBuffer);
  if (strcmp(name, "glBindBufferBase") == 0)
    return reinterpret_cast<void*>(Mock_glBindBufferBase);
  if (strcmp(name, "glBindBufferRange") == 0)
    return reinterpret_cast<void*>(Mock_glBindBufferRange);
  if (strcmp(name, "glBindFragDataLocation") == 0)
    return reinterpret_cast<void*>(Mock_glBindFragDataLocation);
  if (strcmp(name, "glBindFragDataLocationIndexed") == 0)
    return reinterpret_cast<void*>(Mock_glBindFragDataLocationIndexed);
  if (strcmp(name, "glBindFramebuffer") == 0)
    return reinterpret_cast<void*>(Mock_glBindFramebuffer);
  if (strcmp(name, "glBindFramebufferEXT") == 0)
    return reinterpret_cast<void*>(Mock_glBindFramebufferEXT);
  if (strcmp(name, "glBindRenderbuffer") == 0)
    return reinterpret_cast<void*>(Mock_glBindRenderbuffer);
  if (strcmp(name, "glBindRenderbufferEXT") == 0)
    return reinterpret_cast<void*>(Mock_glBindRenderbufferEXT);
  if (strcmp(name, "glBindSampler") == 0)
    return reinterpret_cast<void*>(Mock_glBindSampler);
  if (strcmp(name, "glBindTexture") == 0)
    return reinterpret_cast<void*>(Mock_glBindTexture);
  if (strcmp(name, "glBindTransformFeedback") == 0)
    return reinterpret_cast<void*>(Mock_glBindTransformFeedback);
  if (strcmp(name, "glBindVertexArray") == 0)
    return reinterpret_cast<void*>(Mock_glBindVertexArray);
  if (strcmp(name, "glBindVertexArrayAPPLE") == 0)
    return reinterpret_cast<void*>(Mock_glBindVertexArrayAPPLE);
  if (strcmp(name, "glBindVertexArrayOES") == 0)
    return reinterpret_cast<void*>(Mock_glBindVertexArrayOES);
  if (strcmp(name, "glBlendBarrierKHR") == 0)
    return reinterpret_cast<void*>(Mock_glBlendBarrierKHR);
  if (strcmp(name, "glBlendBarrierNV") == 0)
    return reinterpret_cast<void*>(Mock_glBlendBarrierNV);
  if (strcmp(name, "glBlendColor") == 0)
    return reinterpret_cast<void*>(Mock_glBlendColor);
  if (strcmp(name, "glBlendEquation") == 0)
    return reinterpret_cast<void*>(Mock_glBlendEquation);
  if (strcmp(name, "glBlendEquationSeparate") == 0)
    return reinterpret_cast<void*>(Mock_glBlendEquationSeparate);
  if (strcmp(name, "glBlendFunc") == 0)
    return reinterpret_cast<void*>(Mock_glBlendFunc);
  if (strcmp(name, "glBlendFuncSeparate") == 0)
    return reinterpret_cast<void*>(Mock_glBlendFuncSeparate);
  if (strcmp(name, "glBlitFramebuffer") == 0)
    return reinterpret_cast<void*>(Mock_glBlitFramebuffer);
  if (strcmp(name, "glBlitFramebufferANGLE") == 0)
    return reinterpret_cast<void*>(Mock_glBlitFramebufferANGLE);
  if (strcmp(name, "glBlitFramebufferEXT") == 0)
    return reinterpret_cast<void*>(Mock_glBlitFramebufferEXT);
  if (strcmp(name, "glBufferData") == 0)
    return reinterpret_cast<void*>(Mock_glBufferData);
  if (strcmp(name, "glBufferSubData") == 0)
    return reinterpret_cast<void*>(Mock_glBufferSubData);
  if (strcmp(name, "glCheckFramebufferStatus") == 0)
    return reinterpret_cast<void*>(Mock_glCheckFramebufferStatus);
  if (strcmp(name, "glCheckFramebufferStatusEXT") == 0)
    return reinterpret_cast<void*>(Mock_glCheckFramebufferStatusEXT);
  if (strcmp(name, "glClear") == 0)
    return reinterpret_cast<void*>(Mock_glClear);
  if (strcmp(name, "glClearBufferfi") == 0)
    return reinterpret_cast<void*>(Mock_glClearBufferfi);
  if (strcmp(name, "glClearBufferfv") == 0)
    return reinterpret_cast<void*>(Mock_glClearBufferfv);
  if (strcmp(name, "glClearBufferiv") == 0)
    return reinterpret_cast<void*>(Mock_glClearBufferiv);
  if (strcmp(name, "glClearBufferuiv") == 0)
    return reinterpret_cast<void*>(Mock_glClearBufferuiv);
  if (strcmp(name, "glClearColor") == 0)
    return reinterpret_cast<void*>(Mock_glClearColor);
  if (strcmp(name, "glClearDepth") == 0)
    return reinterpret_cast<void*>(Mock_glClearDepth);
  if (strcmp(name, "glClearDepthf") == 0)
    return reinterpret_cast<void*>(Mock_glClearDepthf);
  if (strcmp(name, "glClearStencil") == 0)
    return reinterpret_cast<void*>(Mock_glClearStencil);
  if (strcmp(name, "glClientWaitSync") == 0)
    return reinterpret_cast<void*>(Mock_glClientWaitSync);
  if (strcmp(name, "glColorMask") == 0)
    return reinterpret_cast<void*>(Mock_glColorMask);
  if (strcmp(name, "glCompileShader") == 0)
    return reinterpret_cast<void*>(Mock_glCompileShader);
  if (strcmp(name, "glCompressedTexImage2D") == 0)
    return reinterpret_cast<void*>(Mock_glCompressedTexImage2D);
  if (strcmp(name, "glCompressedTexImage3D") == 0)
    return reinterpret_cast<void*>(Mock_glCompressedTexImage3D);
  if (strcmp(name, "glCompressedTexSubImage2D") == 0)
    return reinterpret_cast<void*>(Mock_glCompressedTexSubImage2D);
  if (strcmp(name, "glCopyBufferSubData") == 0)
    return reinterpret_cast<void*>(Mock_glCopyBufferSubData);
  if (strcmp(name, "glCopyTexImage2D") == 0)
    return reinterpret_cast<void*>(Mock_glCopyTexImage2D);
  if (strcmp(name, "glCopyTexSubImage2D") == 0)
    return reinterpret_cast<void*>(Mock_glCopyTexSubImage2D);
  if (strcmp(name, "glCopyTexSubImage3D") == 0)
    return reinterpret_cast<void*>(Mock_glCopyTexSubImage3D);
  if (strcmp(name, "glCreateProgram") == 0)
    return reinterpret_cast<void*>(Mock_glCreateProgram);
  if (strcmp(name, "glCreateShader") == 0)
    return reinterpret_cast<void*>(Mock_glCreateShader);
  if (strcmp(name, "glCullFace") == 0)
    return reinterpret_cast<void*>(Mock_glCullFace);
  if (strcmp(name, "glDeleteBuffers") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteBuffers);
  if (strcmp(name, "glDeleteFencesAPPLE") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteFencesAPPLE);
  if (strcmp(name, "glDeleteFencesNV") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteFencesNV);
  if (strcmp(name, "glDeleteFramebuffers") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteFramebuffers);
  if (strcmp(name, "glDeleteFramebuffersEXT") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteFramebuffersEXT);
  if (strcmp(name, "glDeleteProgram") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteProgram);
  if (strcmp(name, "glDeleteQueries") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteQueries);
  if (strcmp(name, "glDeleteQueriesARB") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteQueriesARB);
  if (strcmp(name, "glDeleteQueriesEXT") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteQueriesEXT);
  if (strcmp(name, "glDeleteRenderbuffers") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteRenderbuffers);
  if (strcmp(name, "glDeleteRenderbuffersEXT") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteRenderbuffersEXT);
  if (strcmp(name, "glDeleteSamplers") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteSamplers);
  if (strcmp(name, "glDeleteShader") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteShader);
  if (strcmp(name, "glDeleteSync") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteSync);
  if (strcmp(name, "glDeleteTextures") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteTextures);
  if (strcmp(name, "glDeleteTransformFeedbacks") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteTransformFeedbacks);
  if (strcmp(name, "glDeleteVertexArrays") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteVertexArrays);
  if (strcmp(name, "glDeleteVertexArraysAPPLE") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteVertexArraysAPPLE);
  if (strcmp(name, "glDeleteVertexArraysOES") == 0)
    return reinterpret_cast<void*>(Mock_glDeleteVertexArraysOES);
  if (strcmp(name, "glDepthFunc") == 0)
    return reinterpret_cast<void*>(Mock_glDepthFunc);
  if (strcmp(name, "glDepthMask") == 0)
    return reinterpret_cast<void*>(Mock_glDepthMask);
  if (strcmp(name, "glDepthRange") == 0)
    return reinterpret_cast<void*>(Mock_glDepthRange);
  if (strcmp(name, "glDepthRangef") == 0)
    return reinterpret_cast<void*>(Mock_glDepthRangef);
  if (strcmp(name, "glDetachShader") == 0)
    return reinterpret_cast<void*>(Mock_glDetachShader);
  if (strcmp(name, "glDisable") == 0)
    return reinterpret_cast<void*>(Mock_glDisable);
  if (strcmp(name, "glDisableVertexAttribArray") == 0)
    return reinterpret_cast<void*>(Mock_glDisableVertexAttribArray);
  if (strcmp(name, "glDiscardFramebufferEXT") == 0)
    return reinterpret_cast<void*>(Mock_glDiscardFramebufferEXT);
  if (strcmp(name, "glDrawArrays") == 0)
    return reinterpret_cast<void*>(Mock_glDrawArrays);
  if (strcmp(name, "glDrawArraysInstanced") == 0)
    return reinterpret_cast<void*>(Mock_glDrawArraysInstanced);
  if (strcmp(name, "glDrawArraysInstancedANGLE") == 0)
    return reinterpret_cast<void*>(Mock_glDrawArraysInstancedANGLE);
  if (strcmp(name, "glDrawArraysInstancedARB") == 0)
    return reinterpret_cast<void*>(Mock_glDrawArraysInstancedARB);
  if (strcmp(name, "glDrawBuffer") == 0)
    return reinterpret_cast<void*>(Mock_glDrawBuffer);
  if (strcmp(name, "glDrawBuffers") == 0)
    return reinterpret_cast<void*>(Mock_glDrawBuffers);
  if (strcmp(name, "glDrawBuffersARB") == 0)
    return reinterpret_cast<void*>(Mock_glDrawBuffersARB);
  if (strcmp(name, "glDrawBuffersEXT") == 0)
    return reinterpret_cast<void*>(Mock_glDrawBuffersEXT);
  if (strcmp(name, "glDrawElements") == 0)
    return reinterpret_cast<void*>(Mock_glDrawElements);
  if (strcmp(name, "glDrawElementsInstanced") == 0)
    return reinterpret_cast<void*>(Mock_glDrawElementsInstanced);
  if (strcmp(name, "glDrawElementsInstancedANGLE") == 0)
    return reinterpret_cast<void*>(Mock_glDrawElementsInstancedANGLE);
  if (strcmp(name, "glDrawElementsInstancedARB") == 0)
    return reinterpret_cast<void*>(Mock_glDrawElementsInstancedARB);
  if (strcmp(name, "glDrawRangeElements") == 0)
    return reinterpret_cast<void*>(Mock_glDrawRangeElements);
  if (strcmp(name, "glEGLImageTargetRenderbufferStorageOES") == 0)
    return reinterpret_cast<void*>(Mock_glEGLImageTargetRenderbufferStorageOES);
  if (strcmp(name, "glEGLImageTargetTexture2DOES") == 0)
    return reinterpret_cast<void*>(Mock_glEGLImageTargetTexture2DOES);
  if (strcmp(name, "glEnable") == 0)
    return reinterpret_cast<void*>(Mock_glEnable);
  if (strcmp(name, "glEnableVertexAttribArray") == 0)
    return reinterpret_cast<void*>(Mock_glEnableVertexAttribArray);
  if (strcmp(name, "glEndQuery") == 0)
    return reinterpret_cast<void*>(Mock_glEndQuery);
  if (strcmp(name, "glEndQueryARB") == 0)
    return reinterpret_cast<void*>(Mock_glEndQueryARB);
  if (strcmp(name, "glEndQueryEXT") == 0)
    return reinterpret_cast<void*>(Mock_glEndQueryEXT);
  if (strcmp(name, "glEndTransformFeedback") == 0)
    return reinterpret_cast<void*>(Mock_glEndTransformFeedback);
  if (strcmp(name, "glFenceSync") == 0)
    return reinterpret_cast<void*>(Mock_glFenceSync);
  if (strcmp(name, "glFinish") == 0)
    return reinterpret_cast<void*>(Mock_glFinish);
  if (strcmp(name, "glFinishFenceAPPLE") == 0)
    return reinterpret_cast<void*>(Mock_glFinishFenceAPPLE);
  if (strcmp(name, "glFinishFenceNV") == 0)
    return reinterpret_cast<void*>(Mock_glFinishFenceNV);
  if (strcmp(name, "glFlush") == 0)
    return reinterpret_cast<void*>(Mock_glFlush);
  if (strcmp(name, "glFlushMappedBufferRange") == 0)
    return reinterpret_cast<void*>(Mock_glFlushMappedBufferRange);
  if (strcmp(name, "glFramebufferRenderbuffer") == 0)
    return reinterpret_cast<void*>(Mock_glFramebufferRenderbuffer);
  if (strcmp(name, "glFramebufferRenderbufferEXT") == 0)
    return reinterpret_cast<void*>(Mock_glFramebufferRenderbufferEXT);
  if (strcmp(name, "glFramebufferTexture2D") == 0)
    return reinterpret_cast<void*>(Mock_glFramebufferTexture2D);
  if (strcmp(name, "glFramebufferTexture2DEXT") == 0)
    return reinterpret_cast<void*>(Mock_glFramebufferTexture2DEXT);
  if (strcmp(name, "glFramebufferTexture2DMultisampleEXT") == 0)
    return reinterpret_cast<void*>(Mock_glFramebufferTexture2DMultisampleEXT);
  if (strcmp(name, "glFramebufferTexture2DMultisampleIMG") == 0)
    return reinterpret_cast<void*>(Mock_glFramebufferTexture2DMultisampleIMG);
  if (strcmp(name, "glFramebufferTextureLayer") == 0)
    return reinterpret_cast<void*>(Mock_glFramebufferTextureLayer);
  if (strcmp(name, "glFrontFace") == 0)
    return reinterpret_cast<void*>(Mock_glFrontFace);
  if (strcmp(name, "glGenBuffers") == 0)
    return reinterpret_cast<void*>(Mock_glGenBuffers);
  if (strcmp(name, "glGenFencesAPPLE") == 0)
    return reinterpret_cast<void*>(Mock_glGenFencesAPPLE);
  if (strcmp(name, "glGenFencesNV") == 0)
    return reinterpret_cast<void*>(Mock_glGenFencesNV);
  if (strcmp(name, "glGenFramebuffers") == 0)
    return reinterpret_cast<void*>(Mock_glGenFramebuffers);
  if (strcmp(name, "glGenFramebuffersEXT") == 0)
    return reinterpret_cast<void*>(Mock_glGenFramebuffersEXT);
  if (strcmp(name, "glGenQueries") == 0)
    return reinterpret_cast<void*>(Mock_glGenQueries);
  if (strcmp(name, "glGenQueriesARB") == 0)
    return reinterpret_cast<void*>(Mock_glGenQueriesARB);
  if (strcmp(name, "glGenQueriesEXT") == 0)
    return reinterpret_cast<void*>(Mock_glGenQueriesEXT);
  if (strcmp(name, "glGenRenderbuffers") == 0)
    return reinterpret_cast<void*>(Mock_glGenRenderbuffers);
  if (strcmp(name, "glGenRenderbuffersEXT") == 0)
    return reinterpret_cast<void*>(Mock_glGenRenderbuffersEXT);
  if (strcmp(name, "glGenSamplers") == 0)
    return reinterpret_cast<void*>(Mock_glGenSamplers);
  if (strcmp(name, "glGenTextures") == 0)
    return reinterpret_cast<void*>(Mock_glGenTextures);
  if (strcmp(name, "glGenTransformFeedbacks") == 0)
    return reinterpret_cast<void*>(Mock_glGenTransformFeedbacks);
  if (strcmp(name, "glGenVertexArrays") == 0)
    return reinterpret_cast<void*>(Mock_glGenVertexArrays);
  if (strcmp(name, "glGenVertexArraysAPPLE") == 0)
    return reinterpret_cast<void*>(Mock_glGenVertexArraysAPPLE);
  if (strcmp(name, "glGenVertexArraysOES") == 0)
    return reinterpret_cast<void*>(Mock_glGenVertexArraysOES);
  if (strcmp(name, "glGenerateMipmap") == 0)
    return reinterpret_cast<void*>(Mock_glGenerateMipmap);
  if (strcmp(name, "glGenerateMipmapEXT") == 0)
    return reinterpret_cast<void*>(Mock_glGenerateMipmapEXT);
  if (strcmp(name, "glGetActiveAttrib") == 0)
    return reinterpret_cast<void*>(Mock_glGetActiveAttrib);
  if (strcmp(name, "glGetActiveUniform") == 0)
    return reinterpret_cast<void*>(Mock_glGetActiveUniform);
  if (strcmp(name, "glGetActiveUniformBlockName") == 0)
    return reinterpret_cast<void*>(Mock_glGetActiveUniformBlockName);
  if (strcmp(name, "glGetActiveUniformBlockiv") == 0)
    return reinterpret_cast<void*>(Mock_glGetActiveUniformBlockiv);
  if (strcmp(name, "glGetActiveUniformsiv") == 0)
    return reinterpret_cast<void*>(Mock_glGetActiveUniformsiv);
  if (strcmp(name, "glGetAttachedShaders") == 0)
    return reinterpret_cast<void*>(Mock_glGetAttachedShaders);
  if (strcmp(name, "glGetAttribLocation") == 0)
    return reinterpret_cast<void*>(Mock_glGetAttribLocation);
  if (strcmp(name, "glGetBooleanv") == 0)
    return reinterpret_cast<void*>(Mock_glGetBooleanv);
  if (strcmp(name, "glGetBufferParameteriv") == 0)
    return reinterpret_cast<void*>(Mock_glGetBufferParameteriv);
  if (strcmp(name, "glGetError") == 0)
    return reinterpret_cast<void*>(Mock_glGetError);
  if (strcmp(name, "glGetFenceivNV") == 0)
    return reinterpret_cast<void*>(Mock_glGetFenceivNV);
  if (strcmp(name, "glGetFloatv") == 0)
    return reinterpret_cast<void*>(Mock_glGetFloatv);
  if (strcmp(name, "glGetFragDataLocation") == 0)
    return reinterpret_cast<void*>(Mock_glGetFragDataLocation);
  if (strcmp(name, "glGetFramebufferAttachmentParameteriv") == 0)
    return reinterpret_cast<void*>(Mock_glGetFramebufferAttachmentParameteriv);
  if (strcmp(name, "glGetFramebufferAttachmentParameterivEXT") == 0)
    return reinterpret_cast<void*>(
        Mock_glGetFramebufferAttachmentParameterivEXT);
  if (strcmp(name, "glGetGraphicsResetStatus") == 0)
    return reinterpret_cast<void*>(Mock_glGetGraphicsResetStatus);
  if (strcmp(name, "glGetGraphicsResetStatusARB") == 0)
    return reinterpret_cast<void*>(Mock_glGetGraphicsResetStatusARB);
  if (strcmp(name, "glGetGraphicsResetStatusEXT") == 0)
    return reinterpret_cast<void*>(Mock_glGetGraphicsResetStatusEXT);
  if (strcmp(name, "glGetGraphicsResetStatusKHR") == 0)
    return reinterpret_cast<void*>(Mock_glGetGraphicsResetStatusKHR);
  if (strcmp(name, "glGetInteger64i_v") == 0)
    return reinterpret_cast<void*>(Mock_glGetInteger64i_v);
  if (strcmp(name, "glGetInteger64v") == 0)
    return reinterpret_cast<void*>(Mock_glGetInteger64v);
  if (strcmp(name, "glGetIntegeri_v") == 0)
    return reinterpret_cast<void*>(Mock_glGetIntegeri_v);
  if (strcmp(name, "glGetIntegerv") == 0)
    return reinterpret_cast<void*>(Mock_glGetIntegerv);
  if (strcmp(name, "glGetInternalformativ") == 0)
    return reinterpret_cast<void*>(Mock_glGetInternalformativ);
  if (strcmp(name, "glGetProgramBinary") == 0)
    return reinterpret_cast<void*>(Mock_glGetProgramBinary);
  if (strcmp(name, "glGetProgramBinaryOES") == 0)
    return reinterpret_cast<void*>(Mock_glGetProgramBinaryOES);
  if (strcmp(name, "glGetProgramInfoLog") == 0)
    return reinterpret_cast<void*>(Mock_glGetProgramInfoLog);
  if (strcmp(name, "glGetProgramResourceLocation") == 0)
    return reinterpret_cast<void*>(Mock_glGetProgramResourceLocation);
  if (strcmp(name, "glGetProgramiv") == 0)
    return reinterpret_cast<void*>(Mock_glGetProgramiv);
  if (strcmp(name, "glGetQueryObjecti64v") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryObjecti64v);
  if (strcmp(name, "glGetQueryObjecti64vEXT") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryObjecti64vEXT);
  if (strcmp(name, "glGetQueryObjectiv") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryObjectiv);
  if (strcmp(name, "glGetQueryObjectivARB") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryObjectivARB);
  if (strcmp(name, "glGetQueryObjectivEXT") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryObjectivEXT);
  if (strcmp(name, "glGetQueryObjectui64v") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryObjectui64v);
  if (strcmp(name, "glGetQueryObjectui64vEXT") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryObjectui64vEXT);
  if (strcmp(name, "glGetQueryObjectuiv") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryObjectuiv);
  if (strcmp(name, "glGetQueryObjectuivARB") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryObjectuivARB);
  if (strcmp(name, "glGetQueryObjectuivEXT") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryObjectuivEXT);
  if (strcmp(name, "glGetQueryiv") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryiv);
  if (strcmp(name, "glGetQueryivARB") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryivARB);
  if (strcmp(name, "glGetQueryivEXT") == 0)
    return reinterpret_cast<void*>(Mock_glGetQueryivEXT);
  if (strcmp(name, "glGetRenderbufferParameteriv") == 0)
    return reinterpret_cast<void*>(Mock_glGetRenderbufferParameteriv);
  if (strcmp(name, "glGetRenderbufferParameterivEXT") == 0)
    return reinterpret_cast<void*>(Mock_glGetRenderbufferParameterivEXT);
  if (strcmp(name, "glGetSamplerParameterfv") == 0)
    return reinterpret_cast<void*>(Mock_glGetSamplerParameterfv);
  if (strcmp(name, "glGetSamplerParameteriv") == 0)
    return reinterpret_cast<void*>(Mock_glGetSamplerParameteriv);
  if (strcmp(name, "glGetShaderInfoLog") == 0)
    return reinterpret_cast<void*>(Mock_glGetShaderInfoLog);
  if (strcmp(name, "glGetShaderPrecisionFormat") == 0)
    return reinterpret_cast<void*>(Mock_glGetShaderPrecisionFormat);
  if (strcmp(name, "glGetShaderSource") == 0)
    return reinterpret_cast<void*>(Mock_glGetShaderSource);
  if (strcmp(name, "glGetShaderiv") == 0)
    return reinterpret_cast<void*>(Mock_glGetShaderiv);
  if (strcmp(name, "glGetString") == 0)
    return reinterpret_cast<void*>(Mock_glGetString);
  if (strcmp(name, "glGetStringi") == 0)
    return reinterpret_cast<void*>(Mock_glGetStringi);
  if (strcmp(name, "glGetSynciv") == 0)
    return reinterpret_cast<void*>(Mock_glGetSynciv);
  if (strcmp(name, "glGetTexLevelParameterfv") == 0)
    return reinterpret_cast<void*>(Mock_glGetTexLevelParameterfv);
  if (strcmp(name, "glGetTexLevelParameteriv") == 0)
    return reinterpret_cast<void*>(Mock_glGetTexLevelParameteriv);
  if (strcmp(name, "glGetTexParameterfv") == 0)
    return reinterpret_cast<void*>(Mock_glGetTexParameterfv);
  if (strcmp(name, "glGetTexParameteriv") == 0)
    return reinterpret_cast<void*>(Mock_glGetTexParameteriv);
  if (strcmp(name, "glGetTransformFeedbackVarying") == 0)
    return reinterpret_cast<void*>(Mock_glGetTransformFeedbackVarying);
  if (strcmp(name, "glGetTranslatedShaderSourceANGLE") == 0)
    return reinterpret_cast<void*>(Mock_glGetTranslatedShaderSourceANGLE);
  if (strcmp(name, "glGetUniformBlockIndex") == 0)
    return reinterpret_cast<void*>(Mock_glGetUniformBlockIndex);
  if (strcmp(name, "glGetUniformIndices") == 0)
    return reinterpret_cast<void*>(Mock_glGetUniformIndices);
  if (strcmp(name, "glGetUniformLocation") == 0)
    return reinterpret_cast<void*>(Mock_glGetUniformLocation);
  if (strcmp(name, "glGetUniformfv") == 0)
    return reinterpret_cast<void*>(Mock_glGetUniformfv);
  if (strcmp(name, "glGetUniformiv") == 0)
    return reinterpret_cast<void*>(Mock_glGetUniformiv);
  if (strcmp(name, "glGetVertexAttribPointerv") == 0)
    return reinterpret_cast<void*>(Mock_glGetVertexAttribPointerv);
  if (strcmp(name, "glGetVertexAttribfv") == 0)
    return reinterpret_cast<void*>(Mock_glGetVertexAttribfv);
  if (strcmp(name, "glGetVertexAttribiv") == 0)
    return reinterpret_cast<void*>(Mock_glGetVertexAttribiv);
  if (strcmp(name, "glHint") == 0)
    return reinterpret_cast<void*>(Mock_glHint);
  if (strcmp(name, "glInsertEventMarkerEXT") == 0)
    return reinterpret_cast<void*>(Mock_glInsertEventMarkerEXT);
  if (strcmp(name, "glInvalidateFramebuffer") == 0)
    return reinterpret_cast<void*>(Mock_glInvalidateFramebuffer);
  if (strcmp(name, "glInvalidateSubFramebuffer") == 0)
    return reinterpret_cast<void*>(Mock_glInvalidateSubFramebuffer);
  if (strcmp(name, "glIsBuffer") == 0)
    return reinterpret_cast<void*>(Mock_glIsBuffer);
  if (strcmp(name, "glIsEnabled") == 0)
    return reinterpret_cast<void*>(Mock_glIsEnabled);
  if (strcmp(name, "glIsFenceAPPLE") == 0)
    return reinterpret_cast<void*>(Mock_glIsFenceAPPLE);
  if (strcmp(name, "glIsFenceNV") == 0)
    return reinterpret_cast<void*>(Mock_glIsFenceNV);
  if (strcmp(name, "glIsFramebuffer") == 0)
    return reinterpret_cast<void*>(Mock_glIsFramebuffer);
  if (strcmp(name, "glIsFramebufferEXT") == 0)
    return reinterpret_cast<void*>(Mock_glIsFramebufferEXT);
  if (strcmp(name, "glIsProgram") == 0)
    return reinterpret_cast<void*>(Mock_glIsProgram);
  if (strcmp(name, "glIsQuery") == 0)
    return reinterpret_cast<void*>(Mock_glIsQuery);
  if (strcmp(name, "glIsQueryARB") == 0)
    return reinterpret_cast<void*>(Mock_glIsQueryARB);
  if (strcmp(name, "glIsQueryEXT") == 0)
    return reinterpret_cast<void*>(Mock_glIsQueryEXT);
  if (strcmp(name, "glIsRenderbuffer") == 0)
    return reinterpret_cast<void*>(Mock_glIsRenderbuffer);
  if (strcmp(name, "glIsRenderbufferEXT") == 0)
    return reinterpret_cast<void*>(Mock_glIsRenderbufferEXT);
  if (strcmp(name, "glIsSampler") == 0)
    return reinterpret_cast<void*>(Mock_glIsSampler);
  if (strcmp(name, "glIsShader") == 0)
    return reinterpret_cast<void*>(Mock_glIsShader);
  if (strcmp(name, "glIsSync") == 0)
    return reinterpret_cast<void*>(Mock_glIsSync);
  if (strcmp(name, "glIsTexture") == 0)
    return reinterpret_cast<void*>(Mock_glIsTexture);
  if (strcmp(name, "glIsTransformFeedback") == 0)
    return reinterpret_cast<void*>(Mock_glIsTransformFeedback);
  if (strcmp(name, "glIsVertexArray") == 0)
    return reinterpret_cast<void*>(Mock_glIsVertexArray);
  if (strcmp(name, "glIsVertexArrayAPPLE") == 0)
    return reinterpret_cast<void*>(Mock_glIsVertexArrayAPPLE);
  if (strcmp(name, "glIsVertexArrayOES") == 0)
    return reinterpret_cast<void*>(Mock_glIsVertexArrayOES);
  if (strcmp(name, "glLineWidth") == 0)
    return reinterpret_cast<void*>(Mock_glLineWidth);
  if (strcmp(name, "glLinkProgram") == 0)
    return reinterpret_cast<void*>(Mock_glLinkProgram);
  if (strcmp(name, "glMapBuffer") == 0)
    return reinterpret_cast<void*>(Mock_glMapBuffer);
  if (strcmp(name, "glMapBufferOES") == 0)
    return reinterpret_cast<void*>(Mock_glMapBufferOES);
  if (strcmp(name, "glMapBufferRange") == 0)
    return reinterpret_cast<void*>(Mock_glMapBufferRange);
  if (strcmp(name, "glMapBufferRangeEXT") == 0)
    return reinterpret_cast<void*>(Mock_glMapBufferRangeEXT);
  if (strcmp(name, "glMatrixLoadIdentityEXT") == 0)
    return reinterpret_cast<void*>(Mock_glMatrixLoadIdentityEXT);
  if (strcmp(name, "glMatrixLoadfEXT") == 0)
    return reinterpret_cast<void*>(Mock_glMatrixLoadfEXT);
  if (strcmp(name, "glPauseTransformFeedback") == 0)
    return reinterpret_cast<void*>(Mock_glPauseTransformFeedback);
  if (strcmp(name, "glPixelStorei") == 0)
    return reinterpret_cast<void*>(Mock_glPixelStorei);
  if (strcmp(name, "glPointParameteri") == 0)
    return reinterpret_cast<void*>(Mock_glPointParameteri);
  if (strcmp(name, "glPolygonOffset") == 0)
    return reinterpret_cast<void*>(Mock_glPolygonOffset);
  if (strcmp(name, "glPopGroupMarkerEXT") == 0)
    return reinterpret_cast<void*>(Mock_glPopGroupMarkerEXT);
  if (strcmp(name, "glProgramBinary") == 0)
    return reinterpret_cast<void*>(Mock_glProgramBinary);
  if (strcmp(name, "glProgramBinaryOES") == 0)
    return reinterpret_cast<void*>(Mock_glProgramBinaryOES);
  if (strcmp(name, "glProgramParameteri") == 0)
    return reinterpret_cast<void*>(Mock_glProgramParameteri);
  if (strcmp(name, "glPushGroupMarkerEXT") == 0)
    return reinterpret_cast<void*>(Mock_glPushGroupMarkerEXT);
  if (strcmp(name, "glQueryCounter") == 0)
    return reinterpret_cast<void*>(Mock_glQueryCounter);
  if (strcmp(name, "glQueryCounterEXT") == 0)
    return reinterpret_cast<void*>(Mock_glQueryCounterEXT);
  if (strcmp(name, "glReadBuffer") == 0)
    return reinterpret_cast<void*>(Mock_glReadBuffer);
  if (strcmp(name, "glReadPixels") == 0)
    return reinterpret_cast<void*>(Mock_glReadPixels);
  if (strcmp(name, "glReleaseShaderCompiler") == 0)
    return reinterpret_cast<void*>(Mock_glReleaseShaderCompiler);
  if (strcmp(name, "glRenderbufferStorage") == 0)
    return reinterpret_cast<void*>(Mock_glRenderbufferStorage);
  if (strcmp(name, "glRenderbufferStorageEXT") == 0)
    return reinterpret_cast<void*>(Mock_glRenderbufferStorageEXT);
  if (strcmp(name, "glRenderbufferStorageMultisample") == 0)
    return reinterpret_cast<void*>(Mock_glRenderbufferStorageMultisample);
  if (strcmp(name, "glRenderbufferStorageMultisampleANGLE") == 0)
    return reinterpret_cast<void*>(Mock_glRenderbufferStorageMultisampleANGLE);
  if (strcmp(name, "glRenderbufferStorageMultisampleAPPLE") == 0)
    return reinterpret_cast<void*>(Mock_glRenderbufferStorageMultisampleAPPLE);
  if (strcmp(name, "glRenderbufferStorageMultisampleEXT") == 0)
    return reinterpret_cast<void*>(Mock_glRenderbufferStorageMultisampleEXT);
  if (strcmp(name, "glRenderbufferStorageMultisampleIMG") == 0)
    return reinterpret_cast<void*>(Mock_glRenderbufferStorageMultisampleIMG);
  if (strcmp(name, "glResolveMultisampleFramebufferAPPLE") == 0)
    return reinterpret_cast<void*>(Mock_glResolveMultisampleFramebufferAPPLE);
  if (strcmp(name, "glResumeTransformFeedback") == 0)
    return reinterpret_cast<void*>(Mock_glResumeTransformFeedback);
  if (strcmp(name, "glSampleCoverage") == 0)
    return reinterpret_cast<void*>(Mock_glSampleCoverage);
  if (strcmp(name, "glSamplerParameterf") == 0)
    return reinterpret_cast<void*>(Mock_glSamplerParameterf);
  if (strcmp(name, "glSamplerParameterfv") == 0)
    return reinterpret_cast<void*>(Mock_glSamplerParameterfv);
  if (strcmp(name, "glSamplerParameteri") == 0)
    return reinterpret_cast<void*>(Mock_glSamplerParameteri);
  if (strcmp(name, "glSamplerParameteriv") == 0)
    return reinterpret_cast<void*>(Mock_glSamplerParameteriv);
  if (strcmp(name, "glScissor") == 0)
    return reinterpret_cast<void*>(Mock_glScissor);
  if (strcmp(name, "glSetFenceAPPLE") == 0)
    return reinterpret_cast<void*>(Mock_glSetFenceAPPLE);
  if (strcmp(name, "glSetFenceNV") == 0)
    return reinterpret_cast<void*>(Mock_glSetFenceNV);
  if (strcmp(name, "glShaderBinary") == 0)
    return reinterpret_cast<void*>(Mock_glShaderBinary);
  if (strcmp(name, "glShaderSource") == 0)
    return reinterpret_cast<void*>(Mock_glShaderSource);
  if (strcmp(name, "glStencilFunc") == 0)
    return reinterpret_cast<void*>(Mock_glStencilFunc);
  if (strcmp(name, "glStencilFuncSeparate") == 0)
    return reinterpret_cast<void*>(Mock_glStencilFuncSeparate);
  if (strcmp(name, "glStencilMask") == 0)
    return reinterpret_cast<void*>(Mock_glStencilMask);
  if (strcmp(name, "glStencilMaskSeparate") == 0)
    return reinterpret_cast<void*>(Mock_glStencilMaskSeparate);
  if (strcmp(name, "glStencilOp") == 0)
    return reinterpret_cast<void*>(Mock_glStencilOp);
  if (strcmp(name, "glStencilOpSeparate") == 0)
    return reinterpret_cast<void*>(Mock_glStencilOpSeparate);
  if (strcmp(name, "glTestFenceAPPLE") == 0)
    return reinterpret_cast<void*>(Mock_glTestFenceAPPLE);
  if (strcmp(name, "glTestFenceNV") == 0)
    return reinterpret_cast<void*>(Mock_glTestFenceNV);
  if (strcmp(name, "glTexImage2D") == 0)
    return reinterpret_cast<void*>(Mock_glTexImage2D);
  if (strcmp(name, "glTexImage3D") == 0)
    return reinterpret_cast<void*>(Mock_glTexImage3D);
  if (strcmp(name, "glTexParameterf") == 0)
    return reinterpret_cast<void*>(Mock_glTexParameterf);
  if (strcmp(name, "glTexParameterfv") == 0)
    return reinterpret_cast<void*>(Mock_glTexParameterfv);
  if (strcmp(name, "glTexParameteri") == 0)
    return reinterpret_cast<void*>(Mock_glTexParameteri);
  if (strcmp(name, "glTexParameteriv") == 0)
    return reinterpret_cast<void*>(Mock_glTexParameteriv);
  if (strcmp(name, "glTexStorage2D") == 0)
    return reinterpret_cast<void*>(Mock_glTexStorage2D);
  if (strcmp(name, "glTexStorage2DEXT") == 0)
    return reinterpret_cast<void*>(Mock_glTexStorage2DEXT);
  if (strcmp(name, "glTexStorage3D") == 0)
    return reinterpret_cast<void*>(Mock_glTexStorage3D);
  if (strcmp(name, "glTexSubImage2D") == 0)
    return reinterpret_cast<void*>(Mock_glTexSubImage2D);
  if (strcmp(name, "glTransformFeedbackVaryings") == 0)
    return reinterpret_cast<void*>(Mock_glTransformFeedbackVaryings);
  if (strcmp(name, "glUniform1f") == 0)
    return reinterpret_cast<void*>(Mock_glUniform1f);
  if (strcmp(name, "glUniform1fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniform1fv);
  if (strcmp(name, "glUniform1i") == 0)
    return reinterpret_cast<void*>(Mock_glUniform1i);
  if (strcmp(name, "glUniform1iv") == 0)
    return reinterpret_cast<void*>(Mock_glUniform1iv);
  if (strcmp(name, "glUniform1ui") == 0)
    return reinterpret_cast<void*>(Mock_glUniform1ui);
  if (strcmp(name, "glUniform1uiv") == 0)
    return reinterpret_cast<void*>(Mock_glUniform1uiv);
  if (strcmp(name, "glUniform2f") == 0)
    return reinterpret_cast<void*>(Mock_glUniform2f);
  if (strcmp(name, "glUniform2fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniform2fv);
  if (strcmp(name, "glUniform2i") == 0)
    return reinterpret_cast<void*>(Mock_glUniform2i);
  if (strcmp(name, "glUniform2iv") == 0)
    return reinterpret_cast<void*>(Mock_glUniform2iv);
  if (strcmp(name, "glUniform2ui") == 0)
    return reinterpret_cast<void*>(Mock_glUniform2ui);
  if (strcmp(name, "glUniform2uiv") == 0)
    return reinterpret_cast<void*>(Mock_glUniform2uiv);
  if (strcmp(name, "glUniform3f") == 0)
    return reinterpret_cast<void*>(Mock_glUniform3f);
  if (strcmp(name, "glUniform3fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniform3fv);
  if (strcmp(name, "glUniform3i") == 0)
    return reinterpret_cast<void*>(Mock_glUniform3i);
  if (strcmp(name, "glUniform3iv") == 0)
    return reinterpret_cast<void*>(Mock_glUniform3iv);
  if (strcmp(name, "glUniform3ui") == 0)
    return reinterpret_cast<void*>(Mock_glUniform3ui);
  if (strcmp(name, "glUniform3uiv") == 0)
    return reinterpret_cast<void*>(Mock_glUniform3uiv);
  if (strcmp(name, "glUniform4f") == 0)
    return reinterpret_cast<void*>(Mock_glUniform4f);
  if (strcmp(name, "glUniform4fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniform4fv);
  if (strcmp(name, "glUniform4i") == 0)
    return reinterpret_cast<void*>(Mock_glUniform4i);
  if (strcmp(name, "glUniform4iv") == 0)
    return reinterpret_cast<void*>(Mock_glUniform4iv);
  if (strcmp(name, "glUniform4ui") == 0)
    return reinterpret_cast<void*>(Mock_glUniform4ui);
  if (strcmp(name, "glUniform4uiv") == 0)
    return reinterpret_cast<void*>(Mock_glUniform4uiv);
  if (strcmp(name, "glUniformBlockBinding") == 0)
    return reinterpret_cast<void*>(Mock_glUniformBlockBinding);
  if (strcmp(name, "glUniformMatrix2fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniformMatrix2fv);
  if (strcmp(name, "glUniformMatrix2x3fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniformMatrix2x3fv);
  if (strcmp(name, "glUniformMatrix2x4fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniformMatrix2x4fv);
  if (strcmp(name, "glUniformMatrix3fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniformMatrix3fv);
  if (strcmp(name, "glUniformMatrix3x2fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniformMatrix3x2fv);
  if (strcmp(name, "glUniformMatrix3x4fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniformMatrix3x4fv);
  if (strcmp(name, "glUniformMatrix4fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniformMatrix4fv);
  if (strcmp(name, "glUniformMatrix4x2fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniformMatrix4x2fv);
  if (strcmp(name, "glUniformMatrix4x3fv") == 0)
    return reinterpret_cast<void*>(Mock_glUniformMatrix4x3fv);
  if (strcmp(name, "glUnmapBuffer") == 0)
    return reinterpret_cast<void*>(Mock_glUnmapBuffer);
  if (strcmp(name, "glUnmapBufferOES") == 0)
    return reinterpret_cast<void*>(Mock_glUnmapBufferOES);
  if (strcmp(name, "glUseProgram") == 0)
    return reinterpret_cast<void*>(Mock_glUseProgram);
  if (strcmp(name, "glValidateProgram") == 0)
    return reinterpret_cast<void*>(Mock_glValidateProgram);
  if (strcmp(name, "glVertexAttrib1f") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttrib1f);
  if (strcmp(name, "glVertexAttrib1fv") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttrib1fv);
  if (strcmp(name, "glVertexAttrib2f") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttrib2f);
  if (strcmp(name, "glVertexAttrib2fv") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttrib2fv);
  if (strcmp(name, "glVertexAttrib3f") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttrib3f);
  if (strcmp(name, "glVertexAttrib3fv") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttrib3fv);
  if (strcmp(name, "glVertexAttrib4f") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttrib4f);
  if (strcmp(name, "glVertexAttrib4fv") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttrib4fv);
  if (strcmp(name, "glVertexAttribDivisor") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttribDivisor);
  if (strcmp(name, "glVertexAttribDivisorANGLE") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttribDivisorANGLE);
  if (strcmp(name, "glVertexAttribDivisorARB") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttribDivisorARB);
  if (strcmp(name, "glVertexAttribI4i") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttribI4i);
  if (strcmp(name, "glVertexAttribI4iv") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttribI4iv);
  if (strcmp(name, "glVertexAttribI4ui") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttribI4ui);
  if (strcmp(name, "glVertexAttribI4uiv") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttribI4uiv);
  if (strcmp(name, "glVertexAttribIPointer") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttribIPointer);
  if (strcmp(name, "glVertexAttribPointer") == 0)
    return reinterpret_cast<void*>(Mock_glVertexAttribPointer);
  if (strcmp(name, "glViewport") == 0)
    return reinterpret_cast<void*>(Mock_glViewport);
  if (strcmp(name, "glWaitSync") == 0)
    return reinterpret_cast<void*>(Mock_glWaitSync);
  return reinterpret_cast<void*>(&MockInvalidFunction);
}

}  // namespace gfx
