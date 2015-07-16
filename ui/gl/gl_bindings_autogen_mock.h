// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is auto-generated from
// ui/gl/generate_bindings.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

static void GL_BINDING_CALL Mock_glActiveTexture(GLenum texture);
static void GL_BINDING_CALL Mock_glAttachShader(GLuint program, GLuint shader);
static void GL_BINDING_CALL Mock_glBeginQuery(GLenum target, GLuint id);
static void GL_BINDING_CALL Mock_glBeginQueryARB(GLenum target, GLuint id);
static void GL_BINDING_CALL Mock_glBeginQueryEXT(GLenum target, GLuint id);
static void GL_BINDING_CALL Mock_glBeginTransformFeedback(GLenum primitiveMode);
static void GL_BINDING_CALL
Mock_glBindAttribLocation(GLuint program, GLuint index, const char* name);
static void GL_BINDING_CALL Mock_glBindBuffer(GLenum target, GLuint buffer);
static void GL_BINDING_CALL
Mock_glBindBufferBase(GLenum target, GLuint index, GLuint buffer);
static void GL_BINDING_CALL Mock_glBindBufferRange(GLenum target,
                                                   GLuint index,
                                                   GLuint buffer,
                                                   GLintptr offset,
                                                   GLsizeiptr size);
static void GL_BINDING_CALL Mock_glBindFragDataLocation(GLuint program,
                                                        GLuint colorNumber,
                                                        const char* name);
static void GL_BINDING_CALL
Mock_glBindFragDataLocationIndexed(GLuint program,
                                   GLuint colorNumber,
                                   GLuint index,
                                   const char* name);
static void GL_BINDING_CALL
Mock_glBindFramebuffer(GLenum target, GLuint framebuffer);
static void GL_BINDING_CALL
Mock_glBindFramebufferEXT(GLenum target, GLuint framebuffer);
static void GL_BINDING_CALL
Mock_glBindRenderbuffer(GLenum target, GLuint renderbuffer);
static void GL_BINDING_CALL
Mock_glBindRenderbufferEXT(GLenum target, GLuint renderbuffer);
static void GL_BINDING_CALL Mock_glBindSampler(GLuint unit, GLuint sampler);
static void GL_BINDING_CALL Mock_glBindTexture(GLenum target, GLuint texture);
static void GL_BINDING_CALL
Mock_glBindTransformFeedback(GLenum target, GLuint id);
static void GL_BINDING_CALL Mock_glBindVertexArray(GLuint array);
static void GL_BINDING_CALL Mock_glBindVertexArrayAPPLE(GLuint array);
static void GL_BINDING_CALL Mock_glBindVertexArrayOES(GLuint array);
static void GL_BINDING_CALL Mock_glBlendBarrierKHR(void);
static void GL_BINDING_CALL Mock_glBlendBarrierNV(void);
static void GL_BINDING_CALL
Mock_glBlendColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
static void GL_BINDING_CALL Mock_glBlendEquation(GLenum mode);
static void GL_BINDING_CALL
Mock_glBlendEquationSeparate(GLenum modeRGB, GLenum modeAlpha);
static void GL_BINDING_CALL Mock_glBlendFunc(GLenum sfactor, GLenum dfactor);
static void GL_BINDING_CALL Mock_glBlendFuncSeparate(GLenum srcRGB,
                                                     GLenum dstRGB,
                                                     GLenum srcAlpha,
                                                     GLenum dstAlpha);
static void GL_BINDING_CALL Mock_glBlitFramebuffer(GLint srcX0,
                                                   GLint srcY0,
                                                   GLint srcX1,
                                                   GLint srcY1,
                                                   GLint dstX0,
                                                   GLint dstY0,
                                                   GLint dstX1,
                                                   GLint dstY1,
                                                   GLbitfield mask,
                                                   GLenum filter);
static void GL_BINDING_CALL Mock_glBlitFramebufferANGLE(GLint srcX0,
                                                        GLint srcY0,
                                                        GLint srcX1,
                                                        GLint srcY1,
                                                        GLint dstX0,
                                                        GLint dstY0,
                                                        GLint dstX1,
                                                        GLint dstY1,
                                                        GLbitfield mask,
                                                        GLenum filter);
static void GL_BINDING_CALL Mock_glBlitFramebufferEXT(GLint srcX0,
                                                      GLint srcY0,
                                                      GLint srcX1,
                                                      GLint srcY1,
                                                      GLint dstX0,
                                                      GLint dstY0,
                                                      GLint dstX1,
                                                      GLint dstY1,
                                                      GLbitfield mask,
                                                      GLenum filter);
static void GL_BINDING_CALL Mock_glBufferData(GLenum target,
                                              GLsizeiptr size,
                                              const void* data,
                                              GLenum usage);
static void GL_BINDING_CALL Mock_glBufferSubData(GLenum target,
                                                 GLintptr offset,
                                                 GLsizeiptr size,
                                                 const void* data);
static GLenum GL_BINDING_CALL Mock_glCheckFramebufferStatus(GLenum target);
static GLenum GL_BINDING_CALL Mock_glCheckFramebufferStatusEXT(GLenum target);
static void GL_BINDING_CALL Mock_glClear(GLbitfield mask);
static void GL_BINDING_CALL Mock_glClearBufferfi(GLenum buffer,
                                                 GLint drawbuffer,
                                                 const GLfloat depth,
                                                 GLint stencil);
static void GL_BINDING_CALL
Mock_glClearBufferfv(GLenum buffer, GLint drawbuffer, const GLfloat* value);
static void GL_BINDING_CALL
Mock_glClearBufferiv(GLenum buffer, GLint drawbuffer, const GLint* value);
static void GL_BINDING_CALL
Mock_glClearBufferuiv(GLenum buffer, GLint drawbuffer, const GLuint* value);
static void GL_BINDING_CALL
Mock_glClearColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
static void GL_BINDING_CALL Mock_glClearDepth(GLclampd depth);
static void GL_BINDING_CALL Mock_glClearDepthf(GLclampf depth);
static void GL_BINDING_CALL Mock_glClearStencil(GLint s);
static GLenum GL_BINDING_CALL
Mock_glClientWaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout);
static void GL_BINDING_CALL Mock_glColorMask(GLboolean red,
                                             GLboolean green,
                                             GLboolean blue,
                                             GLboolean alpha);
static void GL_BINDING_CALL Mock_glCompileShader(GLuint shader);
static void GL_BINDING_CALL Mock_glCompressedTexImage2D(GLenum target,
                                                        GLint level,
                                                        GLenum internalformat,
                                                        GLsizei width,
                                                        GLsizei height,
                                                        GLint border,
                                                        GLsizei imageSize,
                                                        const void* data);
static void GL_BINDING_CALL Mock_glCompressedTexImage3D(GLenum target,
                                                        GLint level,
                                                        GLenum internalformat,
                                                        GLsizei width,
                                                        GLsizei height,
                                                        GLsizei depth,
                                                        GLint border,
                                                        GLsizei imageSize,
                                                        const void* data);
static void GL_BINDING_CALL Mock_glCompressedTexSubImage2D(GLenum target,
                                                           GLint level,
                                                           GLint xoffset,
                                                           GLint yoffset,
                                                           GLsizei width,
                                                           GLsizei height,
                                                           GLenum format,
                                                           GLsizei imageSize,
                                                           const void* data);
static void GL_BINDING_CALL Mock_glCopyBufferSubData(GLenum readTarget,
                                                     GLenum writeTarget,
                                                     GLintptr readOffset,
                                                     GLintptr writeOffset,
                                                     GLsizeiptr size);
static void GL_BINDING_CALL Mock_glCopyTexImage2D(GLenum target,
                                                  GLint level,
                                                  GLenum internalformat,
                                                  GLint x,
                                                  GLint y,
                                                  GLsizei width,
                                                  GLsizei height,
                                                  GLint border);
static void GL_BINDING_CALL Mock_glCopyTexSubImage2D(GLenum target,
                                                     GLint level,
                                                     GLint xoffset,
                                                     GLint yoffset,
                                                     GLint x,
                                                     GLint y,
                                                     GLsizei width,
                                                     GLsizei height);
static void GL_BINDING_CALL Mock_glCopyTexSubImage3D(GLenum target,
                                                     GLint level,
                                                     GLint xoffset,
                                                     GLint yoffset,
                                                     GLint zoffset,
                                                     GLint x,
                                                     GLint y,
                                                     GLsizei width,
                                                     GLsizei height);
static GLuint GL_BINDING_CALL Mock_glCreateProgram(void);
static GLuint GL_BINDING_CALL Mock_glCreateShader(GLenum type);
static void GL_BINDING_CALL Mock_glCullFace(GLenum mode);
static void GL_BINDING_CALL
Mock_glDeleteBuffers(GLsizei n, const GLuint* buffers);
static void GL_BINDING_CALL
Mock_glDeleteFencesAPPLE(GLsizei n, const GLuint* fences);
static void GL_BINDING_CALL
Mock_glDeleteFencesNV(GLsizei n, const GLuint* fences);
static void GL_BINDING_CALL
Mock_glDeleteFramebuffers(GLsizei n, const GLuint* framebuffers);
static void GL_BINDING_CALL
Mock_glDeleteFramebuffersEXT(GLsizei n, const GLuint* framebuffers);
static void GL_BINDING_CALL Mock_glDeleteProgram(GLuint program);
static void GL_BINDING_CALL Mock_glDeleteQueries(GLsizei n, const GLuint* ids);
static void GL_BINDING_CALL
Mock_glDeleteQueriesARB(GLsizei n, const GLuint* ids);
static void GL_BINDING_CALL
Mock_glDeleteQueriesEXT(GLsizei n, const GLuint* ids);
static void GL_BINDING_CALL
Mock_glDeleteRenderbuffers(GLsizei n, const GLuint* renderbuffers);
static void GL_BINDING_CALL
Mock_glDeleteRenderbuffersEXT(GLsizei n, const GLuint* renderbuffers);
static void GL_BINDING_CALL
Mock_glDeleteSamplers(GLsizei n, const GLuint* samplers);
static void GL_BINDING_CALL Mock_glDeleteShader(GLuint shader);
static void GL_BINDING_CALL Mock_glDeleteSync(GLsync sync);
static void GL_BINDING_CALL
Mock_glDeleteTextures(GLsizei n, const GLuint* textures);
static void GL_BINDING_CALL
Mock_glDeleteTransformFeedbacks(GLsizei n, const GLuint* ids);
static void GL_BINDING_CALL
Mock_glDeleteVertexArrays(GLsizei n, const GLuint* arrays);
static void GL_BINDING_CALL
Mock_glDeleteVertexArraysAPPLE(GLsizei n, const GLuint* arrays);
static void GL_BINDING_CALL
Mock_glDeleteVertexArraysOES(GLsizei n, const GLuint* arrays);
static void GL_BINDING_CALL Mock_glDepthFunc(GLenum func);
static void GL_BINDING_CALL Mock_glDepthMask(GLboolean flag);
static void GL_BINDING_CALL Mock_glDepthRange(GLclampd zNear, GLclampd zFar);
static void GL_BINDING_CALL Mock_glDepthRangef(GLclampf zNear, GLclampf zFar);
static void GL_BINDING_CALL Mock_glDetachShader(GLuint program, GLuint shader);
static void GL_BINDING_CALL Mock_glDisable(GLenum cap);
static void GL_BINDING_CALL Mock_glDisableVertexAttribArray(GLuint index);
static void GL_BINDING_CALL
Mock_glDiscardFramebufferEXT(GLenum target,
                             GLsizei numAttachments,
                             const GLenum* attachments);
static void GL_BINDING_CALL
Mock_glDrawArrays(GLenum mode, GLint first, GLsizei count);
static void GL_BINDING_CALL Mock_glDrawArraysInstanced(GLenum mode,
                                                       GLint first,
                                                       GLsizei count,
                                                       GLsizei primcount);
static void GL_BINDING_CALL Mock_glDrawArraysInstancedANGLE(GLenum mode,
                                                            GLint first,
                                                            GLsizei count,
                                                            GLsizei primcount);
static void GL_BINDING_CALL Mock_glDrawArraysInstancedARB(GLenum mode,
                                                          GLint first,
                                                          GLsizei count,
                                                          GLsizei primcount);
static void GL_BINDING_CALL Mock_glDrawBuffer(GLenum mode);
static void GL_BINDING_CALL Mock_glDrawBuffers(GLsizei n, const GLenum* bufs);
static void GL_BINDING_CALL
Mock_glDrawBuffersARB(GLsizei n, const GLenum* bufs);
static void GL_BINDING_CALL
Mock_glDrawBuffersEXT(GLsizei n, const GLenum* bufs);
static void GL_BINDING_CALL Mock_glDrawElements(GLenum mode,
                                                GLsizei count,
                                                GLenum type,
                                                const void* indices);
static void GL_BINDING_CALL Mock_glDrawElementsInstanced(GLenum mode,
                                                         GLsizei count,
                                                         GLenum type,
                                                         const void* indices,
                                                         GLsizei primcount);
static void GL_BINDING_CALL
Mock_glDrawElementsInstancedANGLE(GLenum mode,
                                  GLsizei count,
                                  GLenum type,
                                  const void* indices,
                                  GLsizei primcount);
static void GL_BINDING_CALL Mock_glDrawElementsInstancedARB(GLenum mode,
                                                            GLsizei count,
                                                            GLenum type,
                                                            const void* indices,
                                                            GLsizei primcount);
static void GL_BINDING_CALL Mock_glDrawRangeElements(GLenum mode,
                                                     GLuint start,
                                                     GLuint end,
                                                     GLsizei count,
                                                     GLenum type,
                                                     const void* indices);
static void GL_BINDING_CALL
Mock_glEGLImageTargetRenderbufferStorageOES(GLenum target, GLeglImageOES image);
static void GL_BINDING_CALL
Mock_glEGLImageTargetTexture2DOES(GLenum target, GLeglImageOES image);
static void GL_BINDING_CALL Mock_glEnable(GLenum cap);
static void GL_BINDING_CALL Mock_glEnableVertexAttribArray(GLuint index);
static void GL_BINDING_CALL Mock_glEndQuery(GLenum target);
static void GL_BINDING_CALL Mock_glEndQueryARB(GLenum target);
static void GL_BINDING_CALL Mock_glEndQueryEXT(GLenum target);
static void GL_BINDING_CALL Mock_glEndTransformFeedback(void);
static GLsync GL_BINDING_CALL
Mock_glFenceSync(GLenum condition, GLbitfield flags);
static void GL_BINDING_CALL Mock_glFinish(void);
static void GL_BINDING_CALL Mock_glFinishFenceAPPLE(GLuint fence);
static void GL_BINDING_CALL Mock_glFinishFenceNV(GLuint fence);
static void GL_BINDING_CALL Mock_glFlush(void);
static void GL_BINDING_CALL Mock_glFlushMappedBufferRange(GLenum target,
                                                          GLintptr offset,
                                                          GLsizeiptr length);
static void GL_BINDING_CALL
Mock_glFramebufferRenderbuffer(GLenum target,
                               GLenum attachment,
                               GLenum renderbuffertarget,
                               GLuint renderbuffer);
static void GL_BINDING_CALL
Mock_glFramebufferRenderbufferEXT(GLenum target,
                                  GLenum attachment,
                                  GLenum renderbuffertarget,
                                  GLuint renderbuffer);
static void GL_BINDING_CALL Mock_glFramebufferTexture2D(GLenum target,
                                                        GLenum attachment,
                                                        GLenum textarget,
                                                        GLuint texture,
                                                        GLint level);
static void GL_BINDING_CALL Mock_glFramebufferTexture2DEXT(GLenum target,
                                                           GLenum attachment,
                                                           GLenum textarget,
                                                           GLuint texture,
                                                           GLint level);
static void GL_BINDING_CALL
Mock_glFramebufferTexture2DMultisampleEXT(GLenum target,
                                          GLenum attachment,
                                          GLenum textarget,
                                          GLuint texture,
                                          GLint level,
                                          GLsizei samples);
static void GL_BINDING_CALL
Mock_glFramebufferTexture2DMultisampleIMG(GLenum target,
                                          GLenum attachment,
                                          GLenum textarget,
                                          GLuint texture,
                                          GLint level,
                                          GLsizei samples);
static void GL_BINDING_CALL Mock_glFramebufferTextureLayer(GLenum target,
                                                           GLenum attachment,
                                                           GLuint texture,
                                                           GLint level,
                                                           GLint layer);
static void GL_BINDING_CALL Mock_glFrontFace(GLenum mode);
static void GL_BINDING_CALL Mock_glGenBuffers(GLsizei n, GLuint* buffers);
static void GL_BINDING_CALL Mock_glGenFencesAPPLE(GLsizei n, GLuint* fences);
static void GL_BINDING_CALL Mock_glGenFencesNV(GLsizei n, GLuint* fences);
static void GL_BINDING_CALL
Mock_glGenFramebuffers(GLsizei n, GLuint* framebuffers);
static void GL_BINDING_CALL
Mock_glGenFramebuffersEXT(GLsizei n, GLuint* framebuffers);
static void GL_BINDING_CALL Mock_glGenQueries(GLsizei n, GLuint* ids);
static void GL_BINDING_CALL Mock_glGenQueriesARB(GLsizei n, GLuint* ids);
static void GL_BINDING_CALL Mock_glGenQueriesEXT(GLsizei n, GLuint* ids);
static void GL_BINDING_CALL
Mock_glGenRenderbuffers(GLsizei n, GLuint* renderbuffers);
static void GL_BINDING_CALL
Mock_glGenRenderbuffersEXT(GLsizei n, GLuint* renderbuffers);
static void GL_BINDING_CALL Mock_glGenSamplers(GLsizei n, GLuint* samplers);
static void GL_BINDING_CALL Mock_glGenTextures(GLsizei n, GLuint* textures);
static void GL_BINDING_CALL
Mock_glGenTransformFeedbacks(GLsizei n, GLuint* ids);
static void GL_BINDING_CALL Mock_glGenVertexArrays(GLsizei n, GLuint* arrays);
static void GL_BINDING_CALL
Mock_glGenVertexArraysAPPLE(GLsizei n, GLuint* arrays);
static void GL_BINDING_CALL
Mock_glGenVertexArraysOES(GLsizei n, GLuint* arrays);
static void GL_BINDING_CALL Mock_glGenerateMipmap(GLenum target);
static void GL_BINDING_CALL Mock_glGenerateMipmapEXT(GLenum target);
static void GL_BINDING_CALL Mock_glGetActiveAttrib(GLuint program,
                                                   GLuint index,
                                                   GLsizei bufsize,
                                                   GLsizei* length,
                                                   GLint* size,
                                                   GLenum* type,
                                                   char* name);
static void GL_BINDING_CALL Mock_glGetActiveUniform(GLuint program,
                                                    GLuint index,
                                                    GLsizei bufsize,
                                                    GLsizei* length,
                                                    GLint* size,
                                                    GLenum* type,
                                                    char* name);
static void GL_BINDING_CALL
Mock_glGetActiveUniformBlockName(GLuint program,
                                 GLuint uniformBlockIndex,
                                 GLsizei bufSize,
                                 GLsizei* length,
                                 char* uniformBlockName);
static void GL_BINDING_CALL
Mock_glGetActiveUniformBlockiv(GLuint program,
                               GLuint uniformBlockIndex,
                               GLenum pname,
                               GLint* params);
static void GL_BINDING_CALL
Mock_glGetActiveUniformsiv(GLuint program,
                           GLsizei uniformCount,
                           const GLuint* uniformIndices,
                           GLenum pname,
                           GLint* params);
static void GL_BINDING_CALL Mock_glGetAttachedShaders(GLuint program,
                                                      GLsizei maxcount,
                                                      GLsizei* count,
                                                      GLuint* shaders);
static GLint GL_BINDING_CALL
Mock_glGetAttribLocation(GLuint program, const char* name);
static void GL_BINDING_CALL Mock_glGetBooleanv(GLenum pname, GLboolean* params);
static void GL_BINDING_CALL
Mock_glGetBufferParameteriv(GLenum target, GLenum pname, GLint* params);
static GLenum GL_BINDING_CALL Mock_glGetError(void);
static void GL_BINDING_CALL
Mock_glGetFenceivNV(GLuint fence, GLenum pname, GLint* params);
static void GL_BINDING_CALL Mock_glGetFloatv(GLenum pname, GLfloat* params);
static GLint GL_BINDING_CALL
Mock_glGetFragDataLocation(GLuint program, const char* name);
static void GL_BINDING_CALL
Mock_glGetFramebufferAttachmentParameteriv(GLenum target,
                                           GLenum attachment,
                                           GLenum pname,
                                           GLint* params);
static void GL_BINDING_CALL
Mock_glGetFramebufferAttachmentParameterivEXT(GLenum target,
                                              GLenum attachment,
                                              GLenum pname,
                                              GLint* params);
static GLenum GL_BINDING_CALL Mock_glGetGraphicsResetStatus(void);
static GLenum GL_BINDING_CALL Mock_glGetGraphicsResetStatusARB(void);
static GLenum GL_BINDING_CALL Mock_glGetGraphicsResetStatusEXT(void);
static GLenum GL_BINDING_CALL Mock_glGetGraphicsResetStatusKHR(void);
static void GL_BINDING_CALL
Mock_glGetInteger64i_v(GLenum target, GLuint index, GLint64* data);
static void GL_BINDING_CALL Mock_glGetInteger64v(GLenum pname, GLint64* params);
static void GL_BINDING_CALL
Mock_glGetIntegeri_v(GLenum target, GLuint index, GLint* data);
static void GL_BINDING_CALL Mock_glGetIntegerv(GLenum pname, GLint* params);
static void GL_BINDING_CALL Mock_glGetInternalformativ(GLenum target,
                                                       GLenum internalformat,
                                                       GLenum pname,
                                                       GLsizei bufSize,
                                                       GLint* params);
static void GL_BINDING_CALL Mock_glGetProgramBinary(GLuint program,
                                                    GLsizei bufSize,
                                                    GLsizei* length,
                                                    GLenum* binaryFormat,
                                                    GLvoid* binary);
static void GL_BINDING_CALL Mock_glGetProgramBinaryOES(GLuint program,
                                                       GLsizei bufSize,
                                                       GLsizei* length,
                                                       GLenum* binaryFormat,
                                                       GLvoid* binary);
static void GL_BINDING_CALL Mock_glGetProgramInfoLog(GLuint program,
                                                     GLsizei bufsize,
                                                     GLsizei* length,
                                                     char* infolog);
static GLint GL_BINDING_CALL
Mock_glGetProgramResourceLocation(GLuint program,
                                  GLenum programInterface,
                                  const char* name);
static void GL_BINDING_CALL
Mock_glGetProgramiv(GLuint program, GLenum pname, GLint* params);
static void GL_BINDING_CALL
Mock_glGetQueryObjecti64v(GLuint id, GLenum pname, GLint64* params);
static void GL_BINDING_CALL
Mock_glGetQueryObjecti64vEXT(GLuint id, GLenum pname, GLint64* params);
static void GL_BINDING_CALL
Mock_glGetQueryObjectiv(GLuint id, GLenum pname, GLint* params);
static void GL_BINDING_CALL
Mock_glGetQueryObjectivARB(GLuint id, GLenum pname, GLint* params);
static void GL_BINDING_CALL
Mock_glGetQueryObjectivEXT(GLuint id, GLenum pname, GLint* params);
static void GL_BINDING_CALL
Mock_glGetQueryObjectui64v(GLuint id, GLenum pname, GLuint64* params);
static void GL_BINDING_CALL
Mock_glGetQueryObjectui64vEXT(GLuint id, GLenum pname, GLuint64* params);
static void GL_BINDING_CALL
Mock_glGetQueryObjectuiv(GLuint id, GLenum pname, GLuint* params);
static void GL_BINDING_CALL
Mock_glGetQueryObjectuivARB(GLuint id, GLenum pname, GLuint* params);
static void GL_BINDING_CALL
Mock_glGetQueryObjectuivEXT(GLuint id, GLenum pname, GLuint* params);
static void GL_BINDING_CALL
Mock_glGetQueryiv(GLenum target, GLenum pname, GLint* params);
static void GL_BINDING_CALL
Mock_glGetQueryivARB(GLenum target, GLenum pname, GLint* params);
static void GL_BINDING_CALL
Mock_glGetQueryivEXT(GLenum target, GLenum pname, GLint* params);
static void GL_BINDING_CALL
Mock_glGetRenderbufferParameteriv(GLenum target, GLenum pname, GLint* params);
static void GL_BINDING_CALL Mock_glGetRenderbufferParameterivEXT(GLenum target,
                                                                 GLenum pname,
                                                                 GLint* params);
static void GL_BINDING_CALL
Mock_glGetSamplerParameterfv(GLuint sampler, GLenum pname, GLfloat* params);
static void GL_BINDING_CALL
Mock_glGetSamplerParameteriv(GLuint sampler, GLenum pname, GLint* params);
static void GL_BINDING_CALL Mock_glGetShaderInfoLog(GLuint shader,
                                                    GLsizei bufsize,
                                                    GLsizei* length,
                                                    char* infolog);
static void GL_BINDING_CALL
Mock_glGetShaderPrecisionFormat(GLenum shadertype,
                                GLenum precisiontype,
                                GLint* range,
                                GLint* precision);
static void GL_BINDING_CALL Mock_glGetShaderSource(GLuint shader,
                                                   GLsizei bufsize,
                                                   GLsizei* length,
                                                   char* source);
static void GL_BINDING_CALL
Mock_glGetShaderiv(GLuint shader, GLenum pname, GLint* params);
static const GLubyte* GL_BINDING_CALL Mock_glGetString(GLenum name);
static const GLubyte* GL_BINDING_CALL
Mock_glGetStringi(GLenum name, GLuint index);
static void GL_BINDING_CALL Mock_glGetSynciv(GLsync sync,
                                             GLenum pname,
                                             GLsizei bufSize,
                                             GLsizei* length,
                                             GLint* values);
static void GL_BINDING_CALL Mock_glGetTexLevelParameterfv(GLenum target,
                                                          GLint level,
                                                          GLenum pname,
                                                          GLfloat* params);
static void GL_BINDING_CALL Mock_glGetTexLevelParameteriv(GLenum target,
                                                          GLint level,
                                                          GLenum pname,
                                                          GLint* params);
static void GL_BINDING_CALL
Mock_glGetTexParameterfv(GLenum target, GLenum pname, GLfloat* params);
static void GL_BINDING_CALL
Mock_glGetTexParameteriv(GLenum target, GLenum pname, GLint* params);
static void GL_BINDING_CALL Mock_glGetTransformFeedbackVarying(GLuint program,
                                                               GLuint index,
                                                               GLsizei bufSize,
                                                               GLsizei* length,
                                                               GLsizei* size,
                                                               GLenum* type,
                                                               char* name);
static void GL_BINDING_CALL
Mock_glGetTranslatedShaderSourceANGLE(GLuint shader,
                                      GLsizei bufsize,
                                      GLsizei* length,
                                      char* source);
static GLuint GL_BINDING_CALL
Mock_glGetUniformBlockIndex(GLuint program, const char* uniformBlockName);
static void GL_BINDING_CALL
Mock_glGetUniformIndices(GLuint program,
                         GLsizei uniformCount,
                         const char* const* uniformNames,
                         GLuint* uniformIndices);
static GLint GL_BINDING_CALL
Mock_glGetUniformLocation(GLuint program, const char* name);
static void GL_BINDING_CALL
Mock_glGetUniformfv(GLuint program, GLint location, GLfloat* params);
static void GL_BINDING_CALL
Mock_glGetUniformiv(GLuint program, GLint location, GLint* params);
static void GL_BINDING_CALL
Mock_glGetVertexAttribPointerv(GLuint index, GLenum pname, void** pointer);
static void GL_BINDING_CALL
Mock_glGetVertexAttribfv(GLuint index, GLenum pname, GLfloat* params);
static void GL_BINDING_CALL
Mock_glGetVertexAttribiv(GLuint index, GLenum pname, GLint* params);
static void GL_BINDING_CALL Mock_glHint(GLenum target, GLenum mode);
static void GL_BINDING_CALL
Mock_glInsertEventMarkerEXT(GLsizei length, const char* marker);
static void GL_BINDING_CALL
Mock_glInvalidateFramebuffer(GLenum target,
                             GLsizei numAttachments,
                             const GLenum* attachments);
static void GL_BINDING_CALL
Mock_glInvalidateSubFramebuffer(GLenum target,
                                GLsizei numAttachments,
                                const GLenum* attachments,
                                GLint x,
                                GLint y,
                                GLint width,
                                GLint height);
static GLboolean GL_BINDING_CALL Mock_glIsBuffer(GLuint buffer);
static GLboolean GL_BINDING_CALL Mock_glIsEnabled(GLenum cap);
static GLboolean GL_BINDING_CALL Mock_glIsFenceAPPLE(GLuint fence);
static GLboolean GL_BINDING_CALL Mock_glIsFenceNV(GLuint fence);
static GLboolean GL_BINDING_CALL Mock_glIsFramebuffer(GLuint framebuffer);
static GLboolean GL_BINDING_CALL Mock_glIsFramebufferEXT(GLuint framebuffer);
static GLboolean GL_BINDING_CALL Mock_glIsProgram(GLuint program);
static GLboolean GL_BINDING_CALL Mock_glIsQuery(GLuint query);
static GLboolean GL_BINDING_CALL Mock_glIsQueryARB(GLuint query);
static GLboolean GL_BINDING_CALL Mock_glIsQueryEXT(GLuint query);
static GLboolean GL_BINDING_CALL Mock_glIsRenderbuffer(GLuint renderbuffer);
static GLboolean GL_BINDING_CALL Mock_glIsRenderbufferEXT(GLuint renderbuffer);
static GLboolean GL_BINDING_CALL Mock_glIsSampler(GLuint sampler);
static GLboolean GL_BINDING_CALL Mock_glIsShader(GLuint shader);
static GLboolean GL_BINDING_CALL Mock_glIsSync(GLsync sync);
static GLboolean GL_BINDING_CALL Mock_glIsTexture(GLuint texture);
static GLboolean GL_BINDING_CALL Mock_glIsTransformFeedback(GLuint id);
static GLboolean GL_BINDING_CALL Mock_glIsVertexArray(GLuint array);
static GLboolean GL_BINDING_CALL Mock_glIsVertexArrayAPPLE(GLuint array);
static GLboolean GL_BINDING_CALL Mock_glIsVertexArrayOES(GLuint array);
static void GL_BINDING_CALL Mock_glLineWidth(GLfloat width);
static void GL_BINDING_CALL Mock_glLinkProgram(GLuint program);
static void* GL_BINDING_CALL Mock_glMapBuffer(GLenum target, GLenum access);
static void* GL_BINDING_CALL Mock_glMapBufferOES(GLenum target, GLenum access);
static void* GL_BINDING_CALL Mock_glMapBufferRange(GLenum target,
                                                   GLintptr offset,
                                                   GLsizeiptr length,
                                                   GLbitfield access);
static void* GL_BINDING_CALL Mock_glMapBufferRangeEXT(GLenum target,
                                                      GLintptr offset,
                                                      GLsizeiptr length,
                                                      GLbitfield access);
static void GL_BINDING_CALL Mock_glMatrixLoadIdentityEXT(GLenum matrixMode);
static void GL_BINDING_CALL
Mock_glMatrixLoadfEXT(GLenum matrixMode, const GLfloat* m);
static void GL_BINDING_CALL Mock_glPauseTransformFeedback(void);
static void GL_BINDING_CALL Mock_glPixelStorei(GLenum pname, GLint param);
static void GL_BINDING_CALL Mock_glPointParameteri(GLenum pname, GLint param);
static void GL_BINDING_CALL Mock_glPolygonOffset(GLfloat factor, GLfloat units);
static void GL_BINDING_CALL Mock_glPopGroupMarkerEXT(void);
static void GL_BINDING_CALL Mock_glProgramBinary(GLuint program,
                                                 GLenum binaryFormat,
                                                 const GLvoid* binary,
                                                 GLsizei length);
static void GL_BINDING_CALL Mock_glProgramBinaryOES(GLuint program,
                                                    GLenum binaryFormat,
                                                    const GLvoid* binary,
                                                    GLsizei length);
static void GL_BINDING_CALL
Mock_glProgramParameteri(GLuint program, GLenum pname, GLint value);
static void GL_BINDING_CALL
Mock_glPushGroupMarkerEXT(GLsizei length, const char* marker);
static void GL_BINDING_CALL Mock_glQueryCounter(GLuint id, GLenum target);
static void GL_BINDING_CALL Mock_glQueryCounterEXT(GLuint id, GLenum target);
static void GL_BINDING_CALL Mock_glReadBuffer(GLenum src);
static void GL_BINDING_CALL Mock_glReadPixels(GLint x,
                                              GLint y,
                                              GLsizei width,
                                              GLsizei height,
                                              GLenum format,
                                              GLenum type,
                                              void* pixels);
static void GL_BINDING_CALL Mock_glReleaseShaderCompiler(void);
static void GL_BINDING_CALL Mock_glRenderbufferStorage(GLenum target,
                                                       GLenum internalformat,
                                                       GLsizei width,
                                                       GLsizei height);
static void GL_BINDING_CALL Mock_glRenderbufferStorageEXT(GLenum target,
                                                          GLenum internalformat,
                                                          GLsizei width,
                                                          GLsizei height);
static void GL_BINDING_CALL
Mock_glRenderbufferStorageMultisample(GLenum target,
                                      GLsizei samples,
                                      GLenum internalformat,
                                      GLsizei width,
                                      GLsizei height);
static void GL_BINDING_CALL
Mock_glRenderbufferStorageMultisampleANGLE(GLenum target,
                                           GLsizei samples,
                                           GLenum internalformat,
                                           GLsizei width,
                                           GLsizei height);
static void GL_BINDING_CALL
Mock_glRenderbufferStorageMultisampleAPPLE(GLenum target,
                                           GLsizei samples,
                                           GLenum internalformat,
                                           GLsizei width,
                                           GLsizei height);
static void GL_BINDING_CALL
Mock_glRenderbufferStorageMultisampleEXT(GLenum target,
                                         GLsizei samples,
                                         GLenum internalformat,
                                         GLsizei width,
                                         GLsizei height);
static void GL_BINDING_CALL
Mock_glRenderbufferStorageMultisampleIMG(GLenum target,
                                         GLsizei samples,
                                         GLenum internalformat,
                                         GLsizei width,
                                         GLsizei height);
static void GL_BINDING_CALL Mock_glResolveMultisampleFramebufferAPPLE(void);
static void GL_BINDING_CALL Mock_glResumeTransformFeedback(void);
static void GL_BINDING_CALL
Mock_glSampleCoverage(GLclampf value, GLboolean invert);
static void GL_BINDING_CALL
Mock_glSamplerParameterf(GLuint sampler, GLenum pname, GLfloat param);
static void GL_BINDING_CALL
Mock_glSamplerParameterfv(GLuint sampler, GLenum pname, const GLfloat* params);
static void GL_BINDING_CALL
Mock_glSamplerParameteri(GLuint sampler, GLenum pname, GLint param);
static void GL_BINDING_CALL
Mock_glSamplerParameteriv(GLuint sampler, GLenum pname, const GLint* params);
static void GL_BINDING_CALL
Mock_glScissor(GLint x, GLint y, GLsizei width, GLsizei height);
static void GL_BINDING_CALL Mock_glSetFenceAPPLE(GLuint fence);
static void GL_BINDING_CALL Mock_glSetFenceNV(GLuint fence, GLenum condition);
static void GL_BINDING_CALL Mock_glShaderBinary(GLsizei n,
                                                const GLuint* shaders,
                                                GLenum binaryformat,
                                                const void* binary,
                                                GLsizei length);
static void GL_BINDING_CALL Mock_glShaderSource(GLuint shader,
                                                GLsizei count,
                                                const char* const* str,
                                                const GLint* length);
static void GL_BINDING_CALL
Mock_glStencilFunc(GLenum func, GLint ref, GLuint mask);
static void GL_BINDING_CALL
Mock_glStencilFuncSeparate(GLenum face, GLenum func, GLint ref, GLuint mask);
static void GL_BINDING_CALL Mock_glStencilMask(GLuint mask);
static void GL_BINDING_CALL
Mock_glStencilMaskSeparate(GLenum face, GLuint mask);
static void GL_BINDING_CALL
Mock_glStencilOp(GLenum fail, GLenum zfail, GLenum zpass);
static void GL_BINDING_CALL
Mock_glStencilOpSeparate(GLenum face, GLenum fail, GLenum zfail, GLenum zpass);
static GLboolean GL_BINDING_CALL Mock_glTestFenceAPPLE(GLuint fence);
static GLboolean GL_BINDING_CALL Mock_glTestFenceNV(GLuint fence);
static void GL_BINDING_CALL Mock_glTexImage2D(GLenum target,
                                              GLint level,
                                              GLint internalformat,
                                              GLsizei width,
                                              GLsizei height,
                                              GLint border,
                                              GLenum format,
                                              GLenum type,
                                              const void* pixels);
static void GL_BINDING_CALL Mock_glTexImage3D(GLenum target,
                                              GLint level,
                                              GLint internalformat,
                                              GLsizei width,
                                              GLsizei height,
                                              GLsizei depth,
                                              GLint border,
                                              GLenum format,
                                              GLenum type,
                                              const void* pixels);
static void GL_BINDING_CALL
Mock_glTexParameterf(GLenum target, GLenum pname, GLfloat param);
static void GL_BINDING_CALL
Mock_glTexParameterfv(GLenum target, GLenum pname, const GLfloat* params);
static void GL_BINDING_CALL
Mock_glTexParameteri(GLenum target, GLenum pname, GLint param);
static void GL_BINDING_CALL
Mock_glTexParameteriv(GLenum target, GLenum pname, const GLint* params);
static void GL_BINDING_CALL Mock_glTexStorage2D(GLenum target,
                                                GLsizei levels,
                                                GLenum internalformat,
                                                GLsizei width,
                                                GLsizei height);
static void GL_BINDING_CALL Mock_glTexStorage2DEXT(GLenum target,
                                                   GLsizei levels,
                                                   GLenum internalformat,
                                                   GLsizei width,
                                                   GLsizei height);
static void GL_BINDING_CALL Mock_glTexStorage3D(GLenum target,
                                                GLsizei levels,
                                                GLenum internalformat,
                                                GLsizei width,
                                                GLsizei height,
                                                GLsizei depth);
static void GL_BINDING_CALL Mock_glTexSubImage2D(GLenum target,
                                                 GLint level,
                                                 GLint xoffset,
                                                 GLint yoffset,
                                                 GLsizei width,
                                                 GLsizei height,
                                                 GLenum format,
                                                 GLenum type,
                                                 const void* pixels);
static void GL_BINDING_CALL
Mock_glTransformFeedbackVaryings(GLuint program,
                                 GLsizei count,
                                 const char* const* varyings,
                                 GLenum bufferMode);
static void GL_BINDING_CALL Mock_glUniform1f(GLint location, GLfloat x);
static void GL_BINDING_CALL
Mock_glUniform1fv(GLint location, GLsizei count, const GLfloat* v);
static void GL_BINDING_CALL Mock_glUniform1i(GLint location, GLint x);
static void GL_BINDING_CALL
Mock_glUniform1iv(GLint location, GLsizei count, const GLint* v);
static void GL_BINDING_CALL Mock_glUniform1ui(GLint location, GLuint v0);
static void GL_BINDING_CALL
Mock_glUniform1uiv(GLint location, GLsizei count, const GLuint* v);
static void GL_BINDING_CALL
Mock_glUniform2f(GLint location, GLfloat x, GLfloat y);
static void GL_BINDING_CALL
Mock_glUniform2fv(GLint location, GLsizei count, const GLfloat* v);
static void GL_BINDING_CALL Mock_glUniform2i(GLint location, GLint x, GLint y);
static void GL_BINDING_CALL
Mock_glUniform2iv(GLint location, GLsizei count, const GLint* v);
static void GL_BINDING_CALL
Mock_glUniform2ui(GLint location, GLuint v0, GLuint v1);
static void GL_BINDING_CALL
Mock_glUniform2uiv(GLint location, GLsizei count, const GLuint* v);
static void GL_BINDING_CALL
Mock_glUniform3f(GLint location, GLfloat x, GLfloat y, GLfloat z);
static void GL_BINDING_CALL
Mock_glUniform3fv(GLint location, GLsizei count, const GLfloat* v);
static void GL_BINDING_CALL
Mock_glUniform3i(GLint location, GLint x, GLint y, GLint z);
static void GL_BINDING_CALL
Mock_glUniform3iv(GLint location, GLsizei count, const GLint* v);
static void GL_BINDING_CALL
Mock_glUniform3ui(GLint location, GLuint v0, GLuint v1, GLuint v2);
static void GL_BINDING_CALL
Mock_glUniform3uiv(GLint location, GLsizei count, const GLuint* v);
static void GL_BINDING_CALL
Mock_glUniform4f(GLint location, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
static void GL_BINDING_CALL
Mock_glUniform4fv(GLint location, GLsizei count, const GLfloat* v);
static void GL_BINDING_CALL
Mock_glUniform4i(GLint location, GLint x, GLint y, GLint z, GLint w);
static void GL_BINDING_CALL
Mock_glUniform4iv(GLint location, GLsizei count, const GLint* v);
static void GL_BINDING_CALL
Mock_glUniform4ui(GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
static void GL_BINDING_CALL
Mock_glUniform4uiv(GLint location, GLsizei count, const GLuint* v);
static void GL_BINDING_CALL
Mock_glUniformBlockBinding(GLuint program,
                           GLuint uniformBlockIndex,
                           GLuint uniformBlockBinding);
static void GL_BINDING_CALL Mock_glUniformMatrix2fv(GLint location,
                                                    GLsizei count,
                                                    GLboolean transpose,
                                                    const GLfloat* value);
static void GL_BINDING_CALL Mock_glUniformMatrix2x3fv(GLint location,
                                                      GLsizei count,
                                                      GLboolean transpose,
                                                      const GLfloat* value);
static void GL_BINDING_CALL Mock_glUniformMatrix2x4fv(GLint location,
                                                      GLsizei count,
                                                      GLboolean transpose,
                                                      const GLfloat* value);
static void GL_BINDING_CALL Mock_glUniformMatrix3fv(GLint location,
                                                    GLsizei count,
                                                    GLboolean transpose,
                                                    const GLfloat* value);
static void GL_BINDING_CALL Mock_glUniformMatrix3x2fv(GLint location,
                                                      GLsizei count,
                                                      GLboolean transpose,
                                                      const GLfloat* value);
static void GL_BINDING_CALL Mock_glUniformMatrix3x4fv(GLint location,
                                                      GLsizei count,
                                                      GLboolean transpose,
                                                      const GLfloat* value);
static void GL_BINDING_CALL Mock_glUniformMatrix4fv(GLint location,
                                                    GLsizei count,
                                                    GLboolean transpose,
                                                    const GLfloat* value);
static void GL_BINDING_CALL Mock_glUniformMatrix4x2fv(GLint location,
                                                      GLsizei count,
                                                      GLboolean transpose,
                                                      const GLfloat* value);
static void GL_BINDING_CALL Mock_glUniformMatrix4x3fv(GLint location,
                                                      GLsizei count,
                                                      GLboolean transpose,
                                                      const GLfloat* value);
static GLboolean GL_BINDING_CALL Mock_glUnmapBuffer(GLenum target);
static GLboolean GL_BINDING_CALL Mock_glUnmapBufferOES(GLenum target);
static void GL_BINDING_CALL Mock_glUseProgram(GLuint program);
static void GL_BINDING_CALL Mock_glValidateProgram(GLuint program);
static void GL_BINDING_CALL Mock_glVertexAttrib1f(GLuint indx, GLfloat x);
static void GL_BINDING_CALL
Mock_glVertexAttrib1fv(GLuint indx, const GLfloat* values);
static void GL_BINDING_CALL
Mock_glVertexAttrib2f(GLuint indx, GLfloat x, GLfloat y);
static void GL_BINDING_CALL
Mock_glVertexAttrib2fv(GLuint indx, const GLfloat* values);
static void GL_BINDING_CALL
Mock_glVertexAttrib3f(GLuint indx, GLfloat x, GLfloat y, GLfloat z);
static void GL_BINDING_CALL
Mock_glVertexAttrib3fv(GLuint indx, const GLfloat* values);
static void GL_BINDING_CALL
Mock_glVertexAttrib4f(GLuint indx, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
static void GL_BINDING_CALL
Mock_glVertexAttrib4fv(GLuint indx, const GLfloat* values);
static void GL_BINDING_CALL
Mock_glVertexAttribDivisor(GLuint index, GLuint divisor);
static void GL_BINDING_CALL
Mock_glVertexAttribDivisorANGLE(GLuint index, GLuint divisor);
static void GL_BINDING_CALL
Mock_glVertexAttribDivisorARB(GLuint index, GLuint divisor);
static void GL_BINDING_CALL
Mock_glVertexAttribI4i(GLuint indx, GLint x, GLint y, GLint z, GLint w);
static void GL_BINDING_CALL
Mock_glVertexAttribI4iv(GLuint indx, const GLint* values);
static void GL_BINDING_CALL
Mock_glVertexAttribI4ui(GLuint indx, GLuint x, GLuint y, GLuint z, GLuint w);
static void GL_BINDING_CALL
Mock_glVertexAttribI4uiv(GLuint indx, const GLuint* values);
static void GL_BINDING_CALL Mock_glVertexAttribIPointer(GLuint indx,
                                                        GLint size,
                                                        GLenum type,
                                                        GLsizei stride,
                                                        const void* ptr);
static void GL_BINDING_CALL Mock_glVertexAttribPointer(GLuint indx,
                                                       GLint size,
                                                       GLenum type,
                                                       GLboolean normalized,
                                                       GLsizei stride,
                                                       const void* ptr);
static void GL_BINDING_CALL
Mock_glViewport(GLint x, GLint y, GLsizei width, GLsizei height);
static GLenum GL_BINDING_CALL
Mock_glWaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout);
