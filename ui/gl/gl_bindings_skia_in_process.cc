// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


#include "ui/gl/gl_bindings_skia_in_process.h"

#include "base/logging.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_implementation.h"

namespace {

extern "C" {
// The following stub functions are required because the glXXX routines exported
// via gl_bindings.h use call-type GL_BINDING_CALL, which on Windows is stdcall.
// Skia has been built such that its GrGLInterface GL pointers are __cdecl.

GLvoid StubGLActiveTexture(GLenum texture) {
  glActiveTexture(texture);
}

GLvoid StubGLAttachShader(GLuint program, GLuint shader) {
  glAttachShader(program, shader);
}

GLvoid StubGLBeginQuery(GLenum target, GLuint id) {
  glBeginQuery(target, id);
}

GLvoid StubGLBindAttribLocation(GLuint program, GLuint index,
                                const char* name) {
  glBindAttribLocation(program, index, name);
}

GLvoid StubGLBindBuffer(GLenum target, GLuint buffer) {
  glBindBuffer(target, buffer);
}

GLvoid StubGLBindFragDataLocation(GLuint program, GLuint colorNumber,
                                  const GLchar * name) {
  glBindFragDataLocation(program, colorNumber, name);
}

GLvoid StubGLBindFragDataLocationIndexed(GLuint program, GLuint colorNumber,
                                         GLuint index, const GLchar * name) {
  glBindFragDataLocationIndexed(program, colorNumber, index, name);
}

GLvoid StubGLBindFramebuffer(GLenum target, GLuint framebuffer) {
  glBindFramebufferEXT(target, framebuffer);
}

GLvoid StubGLBindRenderbuffer(GLenum target, GLuint renderbuffer) {
  glBindRenderbufferEXT(target, renderbuffer);
}

GLvoid StubGLBindTexture(GLenum target, GLuint texture) {
  glBindTexture(target, texture);
}

GLvoid StubGLBindVertexArray(GLuint array) {
  glBindVertexArrayOES(array);
}

GLvoid StubGLBlendColor(GLclampf red, GLclampf green, GLclampf blue,
                        GLclampf alpha) {
  glBlendColor(red, green, blue, alpha);
}

GLvoid StubGLBlendEquation(GLenum mode) {
  glBlendEquation(mode);
}

GLvoid StubGLBlendFunc(GLenum sfactor, GLenum dfactor) {
  glBlendFunc(sfactor, dfactor);
}

GLvoid StubGLBlitFramebuffer(GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1,
                             GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1,
                             GLbitfield mask, GLenum filter) {
  glBlitFramebufferEXT(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1,
                       mask, filter);
}

GLvoid StubGLBufferData(GLenum target, GLsizeiptr size, const void* data,
                        GLenum usage) {
  glBufferData(target, size, data, usage);
}

GLvoid StubGLBufferSubData(GLenum target, GLintptr offset, GLsizeiptr size,
                           const void* data) {
  glBufferSubData(target, offset, size, data);
}

GLenum StubGLCheckFramebufferStatus(GLenum target) {
  return glCheckFramebufferStatusEXT(target);
}

GLvoid StubGLClear(GLbitfield mask) {
  glClear(mask);
}

GLvoid StubGLClearColor(GLclampf red, GLclampf green, GLclampf blue,
                        GLclampf alpha) {
  glClearColor(red, green, blue, alpha);
}

GLvoid StubGLClearStencil(GLint s) {
  glClearStencil(s);
}

GLvoid StubGLColorMask(GLboolean red, GLboolean green, GLboolean blue,
                       GLboolean alpha) {
  glColorMask(red, green, blue, alpha);
}

GLvoid StubGLCompileShader(GLuint shader) {
  glCompileShader(shader);
}

GLvoid StubGLCompressedTexImage2D(GLenum target, GLint level,
                                  GLenum internalformat, GLsizei width,
                                  GLsizei height, GLint border,
                                  GLsizei imageSize, const void* data) {
  glCompressedTexImage2D(target, level, internalformat, width, height, border,
                         imageSize, data);
}

GLvoid StubGLCopyTexSubImage2D(GLenum target, GLint level,
                               GLint xoffset, GLint yoffset,
                               GLint x, GLint y,
                               GLsizei width, GLsizei height) {
  glCopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
}

GLuint StubGLCreateProgram(void) {
  return glCreateProgram();
}

GLuint StubGLCreateShader(GLenum type) {
  return glCreateShader(type);
}

GLvoid StubGLCullFace(GLenum mode) {
  glCullFace(mode);
}

GLvoid StubGLDeleteBuffers(GLsizei n, const GLuint* buffers) {
  glDeleteBuffersARB(n, buffers);
}

GLvoid StubGLDeleteFramebuffers(GLsizei n, const GLuint* framebuffers) {
  glDeleteFramebuffersEXT(n, framebuffers);
}

GLvoid StubGLDeleteQueries(GLsizei n, const GLuint* ids) {
  glDeleteQueries(n, ids);
}

GLvoid StubGLDeleteProgram(GLuint program) {
  glDeleteProgram(program);
}

GLvoid StubGLDeleteRenderbuffers(GLsizei n, const GLuint* renderbuffers) {
  glDeleteRenderbuffersEXT(n, renderbuffers);
}

GLvoid StubGLDeleteShader(GLuint shader) {
  glDeleteShader(shader);
}

GLvoid StubGLDeleteTextures(GLsizei n, const GLuint* textures) {
  glDeleteTextures(n, textures);
}

GLvoid StubGLDeleteVertexArrays(GLsizei n, const GLuint* arrays) {
  glDeleteVertexArraysOES(n, arrays);
}

GLvoid StubGLDepthMask(GLboolean flag) {
  glDepthMask(flag);
}

GLvoid StubGLDisable(GLenum cap) {
  glDisable(cap);
}

GLvoid StubGLDisableVertexAttribArray(GLuint index) {
  glDisableVertexAttribArray(index);
}

GLvoid StubGLDiscardFramebuffer(GLenum target, GLsizei numAttachments,
                                const GLenum *attachments) {
  glDiscardFramebufferEXT(target, numAttachments, attachments);
}

GLvoid StubGLDrawArrays(GLenum mode, GLint first, GLsizei count) {
  glDrawArrays(mode, first, count);
}

GLvoid StubGLDrawArraysInstanced(GLenum mode, GLint first, GLsizei count,
                                 GLsizei instanceCount) {
  glDrawArraysInstancedANGLE(mode, first, count, instanceCount);
}


GLvoid StubGLDrawBuffer(GLenum mode) {
  glDrawBuffer(mode);
}

GLvoid StubGLDrawBuffers(GLsizei n, const GLenum* bufs) {
  glDrawBuffersARB(n, bufs);
}

GLvoid StubGLDrawElements(GLenum mode, GLsizei count, GLenum type,
                          const void* indices) {
  glDrawElements(mode, count, type, indices);
}

GLvoid StubGLDrawElementsInstanced(GLenum mode, GLsizei count, GLenum type,
                                   const GLvoid *indices,
                                   GLsizei instanceCount) {
  glDrawElementsInstancedANGLE(mode, count, type, indices, instanceCount);
}


GLvoid StubGLEnable(GLenum cap) {
  glEnable(cap);
}

GLvoid StubGLEnableVertexAttribArray(GLuint index) {
  glEnableVertexAttribArray(index);
}

GLvoid StubGLEndQuery(GLenum target) {
  glEndQuery(target);
}

GLvoid StubGLFinish() {
  glFinish();
}

GLvoid StubGLFlush() {
  glFlush();
}

GLvoid StubGLFlushMappedBufferRange(GLenum target, GLintptr offset,
                                    GLsizeiptr length) {
  glFlushMappedBufferRange(target, offset, length);
}

GLvoid StubGLFramebufferRenderbuffer(GLenum target, GLenum attachment,
                                     GLenum renderbuffertarget,
                                     GLuint renderbuffer) {
  glFramebufferRenderbufferEXT(target, attachment, renderbuffertarget,
                               renderbuffer);
}

GLvoid StubGLFramebufferTexture2D(GLenum target, GLenum attachment,
                                  GLenum textarget, GLuint texture,
                                  GLint level) {
  glFramebufferTexture2DEXT(target, attachment, textarget, texture, level);
}

GLvoid StubGLFramebufferTexture2DMultisample(GLenum target, GLenum attachment,
                                  GLenum textarget, GLuint texture,
                                  GLint level, GLsizei samples) {
  glFramebufferTexture2DMultisampleEXT(target, attachment, textarget, texture,
      level, samples);
}

GLvoid StubGLFrontFace(GLenum mode) {
  glFrontFace(mode);
}

GLvoid StubGLGenBuffers(GLsizei n, GLuint* buffers) {
  glGenBuffersARB(n, buffers);
}

GLvoid StubGLGenFramebuffers(GLsizei n, GLuint* framebuffers) {
  glGenFramebuffersEXT(n, framebuffers);
}

GLvoid StubGLGenQueries(GLsizei n, GLuint* ids) {
  glGenQueries(n, ids);
}

GLvoid StubGLGenRenderbuffers(GLsizei n, GLuint* renderbuffers) {
  glGenRenderbuffersEXT(n, renderbuffers);
}

GLvoid StubGLGenTextures(GLsizei n, GLuint* textures) {
  glGenTextures(n, textures);
}

GLvoid StubGLGenVertexArrays(GLsizei n, GLuint* arrays) {
  glGenVertexArraysOES(n, arrays);
}

GLvoid StubGLGenerateMipmap(GLenum target){
  glGenerateMipmapEXT(target);
}

GLvoid StubGLGetBufferParameteriv(GLenum target, GLenum pname, GLint* params) {
  glGetBufferParameteriv(target, pname, params);
}

GLvoid StubGLGetFramebufferAttachmentParameteriv(GLenum target,
                                                 GLenum attachment,
                                                 GLenum pname, GLint* params) {
  glGetFramebufferAttachmentParameterivEXT(target, attachment, pname, params);
}

GLenum StubGLGetError() {
  return glGetError();
}

GLvoid StubGLGetIntegerv(GLenum pname, GLint* params) {
  glGetIntegerv(pname, params);
}

GLvoid StubGLGetProgramInfoLog(GLuint program, GLsizei bufsize, GLsizei* length,
                               char* infolog) {
  glGetProgramInfoLog(program, bufsize, length, infolog);
}

GLvoid StubGLGetProgramiv(GLuint program, GLenum pname, GLint* params) {
  glGetProgramiv(program, pname, params);
}

GLvoid StubGLGetRenderbufferParameteriv(GLenum target,
                                        GLenum pname, GLint* params) {
  glGetRenderbufferParameterivEXT(target, pname, params);
}

GLvoid StubGLGetShaderInfoLog(GLuint shader, GLsizei bufsize, GLsizei* length,
                              char* infolog) {
  glGetShaderInfoLog(shader, bufsize, length, infolog);
}

GLvoid StubGLGetShaderiv(GLuint shader, GLenum pname, GLint* params) {
  glGetShaderiv(shader, pname, params);
}

GLvoid StubGLGetShaderPrecisionFormat(GLenum shadertype, GLenum precisiontype,
                                      GLint *range, GLint *precision) {
  glGetShaderPrecisionFormat(shadertype, precisiontype, range, precision);
}

const GLubyte* StubGLGetString(GLenum name) {
  return glGetString(name);
}

const GLubyte* StubGLGetStringi(GLenum name, GLuint index) {
  return glGetStringi(name, index);
}

GLvoid StubGLGetQueryiv(GLenum target, GLenum pname, GLint* params) {
  glGetQueryiv(target, pname, params);
}

GLvoid StubGLGetQueryObjecti64v(GLuint id, GLenum pname, GLint64* params) {
  glGetQueryObjecti64v(id, pname, params);
}

GLvoid StubGLGetQueryObjectiv(GLuint id, GLenum pname, GLint* params) {
  glGetQueryObjectiv(id, pname, params);
}

GLvoid StubGLGetQueryObjectui64v(GLuint id, GLenum pname, GLuint64* params) {
  glGetQueryObjectui64v(id, pname, params);
}

GLvoid StubGLGetQueryObjectuiv(GLuint id, GLenum pname, GLuint* params) {
  glGetQueryObjectuiv(id, pname, params);
}

GLvoid StubGLGetTexLevelParameteriv(GLenum target, GLint level,
                                    GLenum pname, GLint* params) {
  glGetTexLevelParameteriv(target, level, pname, params);
}

GLint StubGLGetUniformLocation(GLuint program, const char* name) {
  return glGetUniformLocation(program, name);
}

GLvoid StubGLInsertEventMarker(GLsizei length, const char* marker) {
  glInsertEventMarkerEXT(length, marker);
}

GLvoid StubGLInvalidateFramebuffer(GLenum target, GLsizei numAttachments,
                                   const GLenum* attachments) {
  glInvalidateFramebuffer(target, numAttachments, attachments);
}

GLvoid StubGLInvalidateSubFramebuffer(GLenum target,
                                      GLsizei numAttachments,
                                      const GLenum* attachments,
                                      GLint x, GLint y,
                                      GLsizei width, GLsizei height) {
  glInvalidateSubFramebuffer(target, numAttachments, attachments,
                             x, y, width, height);
}

GLvoid StubGLLineWidth(GLfloat width) {
  glLineWidth(width);
}

GLvoid StubGLLinkProgram(GLuint program) {
  glLinkProgram(program);
}

void* StubGLMapBuffer(GLenum target, GLenum access) {
  return glMapBuffer(target, access);
}

void* StubGLMapBufferRange(GLenum target, GLintptr offset, GLsizeiptr length,
                           GLbitfield access) {
  return glMapBufferRange(target, offset, length, access);
}

GLvoid StubGLPixelStorei(GLenum pname, GLint param) {
  glPixelStorei(pname, param);
}

GLvoid StubGLPopGroupMarker() {
  glPopGroupMarkerEXT();
}

GLvoid StubGLPushGroupMarker(GLsizei length, const char* marker) {
  glPushGroupMarkerEXT(length, marker);
}

GLvoid StubGLQueryCounter(GLuint id, GLenum target) {
  glQueryCounter(id, target);
}

GLvoid StubGLReadBuffer(GLenum src) {
  glReadBuffer(src);
}

GLvoid StubGLReadPixels(GLint x, GLint y, GLsizei width, GLsizei height,
                        GLenum format, GLenum type, void* pixels) {
  glReadPixels(x, y, width, height, format, type, pixels);
}

GLvoid StubGLRenderbufferStorage(GLenum target, GLenum internalformat,
                                 GLsizei width, GLsizei height) {
  glRenderbufferStorageEXT(target, internalformat, width, height);
}

GLvoid StubGLRenderbufferStorageMultisample(GLenum target, GLsizei samples,
                                            GLenum internalformat,
                                            GLsizei width, GLsizei height) {
  glRenderbufferStorageMultisampleEXT(target, samples, internalformat, width,
                                      height);
}

GLvoid StubGLRenderbufferStorageMultisampleAPPLE(GLenum target, GLsizei samples,
                                                 GLenum internalformat,
                                                 GLsizei width,
                                                 GLsizei height) {
  glRenderbufferStorageMultisampleAPPLE(target, samples, internalformat, width,
                                        height);
}

GLvoid StubResolveMultisampleFramebufferAPPLE(void) {
  glResolveMultisampleFramebufferAPPLE();
}

GLvoid StubGLScissor(GLint x, GLint y, GLsizei width, GLsizei height) {
  glScissor(x, y, width, height);
}

GLvoid StubGLShaderSource(GLuint shader, GLsizei count, const char* const* str,
                          const GLint* length) {
  glShaderSource(shader, count, str, length);
}

GLvoid StubGLStencilFunc(GLenum func, GLint ref, GLuint mask) {
  glStencilFunc(func, ref, mask);
}

GLvoid StubGLStencilFuncSeparate(GLenum face, GLenum func, GLint ref,
                                 GLuint mask) {
  glStencilFuncSeparate(face, func, ref, mask);
}

GLvoid StubGLStencilMask(GLuint mask) {
  glStencilMask(mask);
}

GLvoid StubGLStencilMaskSeparate(GLenum face, GLuint mask) {
  glStencilMaskSeparate(face, mask);
}

GLvoid StubGLStencilOp(GLenum fail, GLenum zfail, GLenum zpass) {
  glStencilOp(fail, zfail, zpass);
}

GLvoid StubGLStencilOpSeparate(GLenum face, GLenum fail, GLenum zfail,
                               GLenum zpass) {
  glStencilOpSeparate(face, fail, zfail, zpass);
}

GLvoid StubGLTexImage2D(GLenum target, GLint level, GLint internalformat,
                        GLsizei width, GLsizei height, GLint border,
                        GLenum format, GLenum type, const void* pixels) {
  glTexImage2D(target, level, internalformat, width, height, border, format,
               type, pixels);
}

GLvoid StubGLTexParameteri(GLenum target, GLenum pname, GLint param) {
  glTexParameteri(target, pname, param);
}

GLvoid StubGLTexParameteriv(GLenum target, GLenum pname, const GLint* params) {
  glTexParameteriv(target, pname, params);
}

GLvoid StubGLTexStorage2D(GLenum target, GLsizei levels, GLenum internalFormat,
                          GLsizei width, GLsizei height) {
  glTexStorage2DEXT(target, levels, internalFormat, width, height);
}

GLvoid StubGLTexSubImage2D(GLenum target, GLint level, GLint xoffset,
                           GLint yoffset, GLsizei width, GLsizei height,
                           GLenum format, GLenum type, const void* pixels) {
  glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type,
                  pixels);
}

GLvoid StubGLUniform1f(GLint location, GLfloat v) {
  glUniform1f(location, v);
}

GLvoid StubGLUniform1i(GLint location, GLint v) {
  glUniform1i(location, v);
}

GLvoid StubGLUniform1fv(GLint location, GLsizei count, const GLfloat* v) {
  glUniform1fv(location, count, v);
}

GLvoid StubGLUniform1iv(GLint location, GLsizei count, const GLint* v) {
  glUniform1iv(location, count, v);
}

GLvoid StubGLUniform2f(GLint location, GLfloat v0, GLfloat v1) {
  glUniform2f(location, v0, v1);
}

GLvoid StubGLUniform2i(GLint location, GLint v0, GLint v1) {
  glUniform2i(location, v0, v1);
}

GLvoid StubGLUniform2fv(GLint location, GLsizei count, const GLfloat* v) {
  glUniform2fv(location, count, v);
}

GLvoid StubGLUniform2iv(GLint location, GLsizei count, const GLint* v) {
  glUniform2iv(location, count, v);
}

GLvoid StubGLUniform3f(GLint location, GLfloat v0, GLfloat v1, GLfloat v2) {
  glUniform3f(location, v0, v1, v2);
}

GLvoid StubGLUniform3i(GLint location, GLint v0, GLint v1, GLint v2) {
  glUniform3i(location, v0, v1, v2);
}

GLvoid StubGLUniform3fv(GLint location, GLsizei count, const GLfloat* v) {
  glUniform3fv(location, count, v);
}

GLvoid StubGLUniform3iv(GLint location, GLsizei count, const GLint* v) {
  glUniform3iv(location, count, v);
}

GLvoid StubGLUniform4f(GLint location, GLfloat v0, GLfloat v1, GLfloat v2,
                       GLfloat v3) {
  glUniform4f(location, v0, v1, v2, v3);
}

GLvoid StubGLUniform4i(GLint location, GLint v0, GLint v1, GLint v2,
                       GLint v3) {
  glUniform4i(location, v0, v1, v2, v3);
}

GLvoid StubGLUniform4fv(GLint location, GLsizei count, const GLfloat* v) {
  glUniform4fv(location, count, v);
}

GLvoid StubGLUniform4iv(GLint location, GLsizei count, const GLint* v) {
  glUniform4iv(location, count, v);
}

GLvoid StubGLUniformMatrix2fv(GLint location, GLsizei count,
                              GLboolean transpose, const GLfloat* value) {
  glUniformMatrix2fv(location, count, transpose, value);
}

GLvoid StubGLUniformMatrix3fv(GLint location, GLsizei count,
                              GLboolean transpose, const GLfloat* value) {
  glUniformMatrix3fv(location, count, transpose, value);
}

GLvoid StubGLUniformMatrix4fv(GLint location, GLsizei count,
                              GLboolean transpose, const GLfloat* value) {
  glUniformMatrix4fv(location, count, transpose, value);
}

GLboolean StubGLUnmapBuffer(GLenum target) {
  return glUnmapBuffer(target);
}

GLvoid StubGLUseProgram(GLuint program) {
  glUseProgram(program);
}

GLvoid StubGLVertexAttrib1f(GLuint indx, const GLfloat value) {
  glVertexAttrib1f(indx, value);
}

GLvoid StubGLVertexAttrib2fv(GLuint indx, const GLfloat* values) {
  glVertexAttrib2fv(indx, values);
}

GLvoid StubGLVertexAttrib3fv(GLuint indx, const GLfloat* values) {
  glVertexAttrib3fv(indx, values);
}

GLvoid StubGLVertexAttrib4fv(GLuint indx, const GLfloat* values) {
  glVertexAttrib4fv(indx, values);
}

GLvoid StubGLVertexAttribDivisor(GLuint index, GLuint divisor) {
  glVertexAttribDivisorANGLE(index, divisor);
}

GLvoid StubGLVertexAttribPointer(GLuint indx, GLint size, GLenum type,
                                 GLboolean normalized, GLsizei stride,
                                 const void* ptr) {
  glVertexAttribPointer(indx, size, type, normalized, stride, ptr);
}

GLvoid StubGLViewport(GLint x, GLint y, GLsizei width, GLsizei height) {
  glViewport(x, y, width, height);
}

GLint StubGLGetProgramResourceLocation(GLuint program,
                                       GLenum programInterface,
                                       const char* name) {
  return glGetProgramResourceLocation(program, programInterface, name);
}

}  // extern "C"
}  // namespace

namespace gfx {

GrGLInterface* CreateInProcessSkiaGLBinding() {
  GrGLStandard standard;
  switch (gfx::GetGLImplementation()) {
    case gfx::kGLImplementationNone:
      NOTREACHED();
      return NULL;
    case gfx::kGLImplementationDesktopGL:
    case gfx::kGLImplementationAppleGL:
#if TARGET_OS_IPHONE
      standard = kGLES_GrGLStandard;
#else
      standard = kGL_GrGLStandard;
#endif
      break;
    case gfx::kGLImplementationOSMesaGL:
      standard = kGL_GrGLStandard;
      break;
    case gfx::kGLImplementationEGLGLES2:
      standard = kGLES_GrGLStandard;
      break;
    case gfx::kGLImplementationMockGL:
      NOTREACHED();
      return NULL;
    default:
      NOTREACHED();
      return NULL;
  }

  GrGLInterface* interface = new GrGLInterface;
  interface->fStandard = standard;
  interface->fExtensions.init(standard,
                              StubGLGetString,
                              StubGLGetStringi,
                              StubGLGetIntegerv);

  GrGLInterface::Functions* functions = &interface->fFunctions;
  functions->fActiveTexture = StubGLActiveTexture;
  functions->fAttachShader = StubGLAttachShader;
  functions->fBeginQuery = StubGLBeginQuery;
  functions->fBindAttribLocation = StubGLBindAttribLocation;
  functions->fBindBuffer = StubGLBindBuffer;
  functions->fBindFragDataLocation = StubGLBindFragDataLocation;
  functions->fBindTexture = StubGLBindTexture;
  functions->fBindVertexArray = StubGLBindVertexArray;
  functions->fBlendColor = StubGLBlendColor;
  functions->fBlendEquation = StubGLBlendEquation;
  functions->fBlendFunc = StubGLBlendFunc;
  functions->fBufferData = StubGLBufferData;
  functions->fBufferSubData = StubGLBufferSubData;
  functions->fClear = StubGLClear;
  functions->fClearColor = StubGLClearColor;
  functions->fClearStencil = StubGLClearStencil;
  functions->fColorMask = StubGLColorMask;
  functions->fCompileShader = StubGLCompileShader;
  functions->fCompressedTexImage2D = StubGLCompressedTexImage2D;
  functions->fCopyTexSubImage2D = StubGLCopyTexSubImage2D;
  functions->fCreateProgram = StubGLCreateProgram;
  functions->fCreateShader = StubGLCreateShader;
  functions->fCullFace = StubGLCullFace;
  functions->fDeleteBuffers = StubGLDeleteBuffers;
  functions->fDeleteProgram = StubGLDeleteProgram;
  functions->fDeleteQueries = StubGLDeleteQueries;
  functions->fDeleteShader = StubGLDeleteShader;
  functions->fDeleteTextures = StubGLDeleteTextures;
  functions->fDeleteVertexArrays = StubGLDeleteVertexArrays;
  functions->fDepthMask = StubGLDepthMask;
  functions->fDisable = StubGLDisable;
  functions->fDisableVertexAttribArray = StubGLDisableVertexAttribArray;
  functions->fDiscardFramebuffer = StubGLDiscardFramebuffer;
  functions->fDrawArrays = StubGLDrawArrays;
  functions->fDrawArraysInstanced = StubGLDrawArraysInstanced;
  functions->fDrawBuffer = StubGLDrawBuffer;
  functions->fDrawBuffers = StubGLDrawBuffers;
  functions->fDrawElements = StubGLDrawElements;
  functions->fDrawElementsInstanced = StubGLDrawElementsInstanced;
  functions->fEnable = StubGLEnable;
  functions->fEnableVertexAttribArray = StubGLEnableVertexAttribArray;
  functions->fEndQuery = StubGLEndQuery;
  functions->fFinish = StubGLFinish;
  functions->fFlush = StubGLFlush;
  functions->fFlushMappedBufferRange = StubGLFlushMappedBufferRange;
  functions->fFrontFace = StubGLFrontFace;
  functions->fGenBuffers = StubGLGenBuffers;
  functions->fGenQueries = StubGLGenQueries;
  functions->fGenTextures = StubGLGenTextures;
  functions->fGenVertexArrays = StubGLGenVertexArrays;
  functions->fGenerateMipmap = StubGLGenerateMipmap;
  functions->fGetBufferParameteriv = StubGLGetBufferParameteriv;
  functions->fGetError = StubGLGetError;
  functions->fGetIntegerv = StubGLGetIntegerv;
  functions->fGetQueryiv = StubGLGetQueryiv;
  functions->fGetQueryObjecti64v = StubGLGetQueryObjecti64v;
  functions->fGetQueryObjectiv = StubGLGetQueryObjectiv;
  functions->fGetQueryObjectui64v = StubGLGetQueryObjectui64v;
  functions->fGetQueryObjectuiv = StubGLGetQueryObjectuiv;
  functions->fGetProgramInfoLog = StubGLGetProgramInfoLog;
  functions->fGetProgramiv = StubGLGetProgramiv;
  functions->fGetShaderInfoLog = StubGLGetShaderInfoLog;
  functions->fGetShaderiv = StubGLGetShaderiv;
  functions->fGetShaderPrecisionFormat = StubGLGetShaderPrecisionFormat;
  functions->fGetString = StubGLGetString;
  functions->fGetStringi = StubGLGetStringi;
  functions->fGetTexLevelParameteriv = StubGLGetTexLevelParameteriv;
  functions->fGetUniformLocation = StubGLGetUniformLocation;
  functions->fInsertEventMarker = StubGLInsertEventMarker;
  functions->fInvalidateFramebuffer = StubGLInvalidateFramebuffer;
  functions->fInvalidateSubFramebuffer = StubGLInvalidateSubFramebuffer;
  functions->fLineWidth = StubGLLineWidth;
  functions->fLinkProgram = StubGLLinkProgram;
  functions->fMapBufferRange = StubGLMapBufferRange;
  functions->fPixelStorei = StubGLPixelStorei;
  functions->fPopGroupMarker = StubGLPopGroupMarker;
  functions->fPushGroupMarker = StubGLPushGroupMarker;
  functions->fQueryCounter = StubGLQueryCounter;
  functions->fReadBuffer = StubGLReadBuffer;
  functions->fReadPixels = StubGLReadPixels;
  functions->fScissor = StubGLScissor;
  functions->fShaderSource = StubGLShaderSource;
  functions->fStencilFunc = StubGLStencilFunc;
  functions->fStencilFuncSeparate = StubGLStencilFuncSeparate;
  functions->fStencilMask = StubGLStencilMask;
  functions->fStencilMaskSeparate = StubGLStencilMaskSeparate;
  functions->fStencilOp = StubGLStencilOp;
  functions->fStencilOpSeparate = StubGLStencilOpSeparate;
  functions->fTexImage2D = StubGLTexImage2D;
  functions->fTexParameteri = StubGLTexParameteri;
  functions->fTexParameteriv = StubGLTexParameteriv;
  functions->fTexSubImage2D = StubGLTexSubImage2D;
  functions->fTexStorage2D = StubGLTexStorage2D;
  functions->fUniform1f = StubGLUniform1f;
  functions->fUniform1i = StubGLUniform1i;
  functions->fUniform1fv = StubGLUniform1fv;
  functions->fUniform1iv = StubGLUniform1iv;
  functions->fUniform2f = StubGLUniform2f;
  functions->fUniform2i = StubGLUniform2i;
  functions->fUniform2fv = StubGLUniform2fv;
  functions->fUniform2iv = StubGLUniform2iv;
  functions->fUniform3f = StubGLUniform3f;
  functions->fUniform3i = StubGLUniform3i;
  functions->fUniform3fv = StubGLUniform3fv;
  functions->fUniform3iv = StubGLUniform3iv;
  functions->fUniform4f = StubGLUniform4f;
  functions->fUniform4i = StubGLUniform4i;
  functions->fUniform4fv = StubGLUniform4fv;
  functions->fUniform4iv = StubGLUniform4iv;
  functions->fUniformMatrix2fv = StubGLUniformMatrix2fv;
  functions->fUniformMatrix3fv = StubGLUniformMatrix3fv;
  functions->fUniformMatrix4fv = StubGLUniformMatrix4fv;
  functions->fUseProgram = StubGLUseProgram;
  functions->fVertexAttrib1f = StubGLVertexAttrib1f;
  functions->fVertexAttrib2fv = StubGLVertexAttrib2fv;
  functions->fVertexAttrib3fv = StubGLVertexAttrib3fv;
  functions->fVertexAttrib4fv = StubGLVertexAttrib4fv;
  functions->fVertexAttribDivisor = StubGLVertexAttribDivisor;
  functions->fVertexAttribPointer = StubGLVertexAttribPointer;
  functions->fViewport = StubGLViewport;
  functions->fBindFramebuffer = StubGLBindFramebuffer;
  functions->fBindRenderbuffer = StubGLBindRenderbuffer;
  functions->fCheckFramebufferStatus = StubGLCheckFramebufferStatus;
  functions->fDeleteFramebuffers = StubGLDeleteFramebuffers;
  functions->fDeleteRenderbuffers = StubGLDeleteRenderbuffers;
  functions->fFramebufferRenderbuffer = StubGLFramebufferRenderbuffer;
  functions->fFramebufferTexture2D = StubGLFramebufferTexture2D;
  functions->fFramebufferTexture2DMultisample =
    StubGLFramebufferTexture2DMultisample;
  functions->fGenFramebuffers = StubGLGenFramebuffers;
  functions->fGenRenderbuffers = StubGLGenRenderbuffers;
  functions->fGetFramebufferAttachmentParameteriv =
    StubGLGetFramebufferAttachmentParameteriv;
  functions->fGetRenderbufferParameteriv = StubGLGetRenderbufferParameteriv;
  functions->fRenderbufferStorage = StubGLRenderbufferStorage;
  functions->fRenderbufferStorageMultisample =
    StubGLRenderbufferStorageMultisample;
  functions->fRenderbufferStorageMultisampleES2EXT =
    StubGLRenderbufferStorageMultisample;
  functions->fRenderbufferStorageMultisampleES2APPLE =
    StubGLRenderbufferStorageMultisampleAPPLE;
  functions->fResolveMultisampleFramebuffer =
    StubResolveMultisampleFramebufferAPPLE;
  functions->fBlitFramebuffer = StubGLBlitFramebuffer;
  functions->fMapBuffer = StubGLMapBuffer;
  functions->fUnmapBuffer = StubGLUnmapBuffer;
  functions->fBindFragDataLocationIndexed =
    StubGLBindFragDataLocationIndexed;
  functions->fGetProgramResourceLocation = StubGLGetProgramResourceLocation;

  return interface;
}

}  // namespace gfx
