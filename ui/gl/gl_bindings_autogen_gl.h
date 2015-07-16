// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is auto-generated from
// ui/gl/generate_bindings.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

#ifndef UI_GFX_GL_GL_BINDINGS_AUTOGEN_GL_H_
#define UI_GFX_GL_GL_BINDINGS_AUTOGEN_GL_H_

namespace gfx {

class GLContext;

typedef void(GL_BINDING_CALL* glActiveTextureProc)(GLenum texture);
typedef void(GL_BINDING_CALL* glAttachShaderProc)(GLuint program,
                                                  GLuint shader);
typedef void(GL_BINDING_CALL* glBeginQueryProc)(GLenum target, GLuint id);
typedef void(GL_BINDING_CALL* glBeginTransformFeedbackProc)(
    GLenum primitiveMode);
typedef void(GL_BINDING_CALL* glBindAttribLocationProc)(GLuint program,
                                                        GLuint index,
                                                        const char* name);
typedef void(GL_BINDING_CALL* glBindBufferProc)(GLenum target, GLuint buffer);
typedef void(GL_BINDING_CALL* glBindBufferBaseProc)(GLenum target,
                                                    GLuint index,
                                                    GLuint buffer);
typedef void(GL_BINDING_CALL* glBindBufferRangeProc)(GLenum target,
                                                     GLuint index,
                                                     GLuint buffer,
                                                     GLintptr offset,
                                                     GLsizeiptr size);
typedef void(GL_BINDING_CALL* glBindFragDataLocationProc)(GLuint program,
                                                          GLuint colorNumber,
                                                          const char* name);
typedef void(GL_BINDING_CALL* glBindFragDataLocationIndexedProc)(
    GLuint program,
    GLuint colorNumber,
    GLuint index,
    const char* name);
typedef void(GL_BINDING_CALL* glBindFramebufferEXTProc)(GLenum target,
                                                        GLuint framebuffer);
typedef void(GL_BINDING_CALL* glBindRenderbufferEXTProc)(GLenum target,
                                                         GLuint renderbuffer);
typedef void(GL_BINDING_CALL* glBindSamplerProc)(GLuint unit, GLuint sampler);
typedef void(GL_BINDING_CALL* glBindTextureProc)(GLenum target, GLuint texture);
typedef void(GL_BINDING_CALL* glBindTransformFeedbackProc)(GLenum target,
                                                           GLuint id);
typedef void(GL_BINDING_CALL* glBindVertexArrayOESProc)(GLuint array);
typedef void(GL_BINDING_CALL* glBlendBarrierKHRProc)(void);
typedef void(GL_BINDING_CALL* glBlendColorProc)(GLclampf red,
                                                GLclampf green,
                                                GLclampf blue,
                                                GLclampf alpha);
typedef void(GL_BINDING_CALL* glBlendEquationProc)(GLenum mode);
typedef void(GL_BINDING_CALL* glBlendEquationSeparateProc)(GLenum modeRGB,
                                                           GLenum modeAlpha);
typedef void(GL_BINDING_CALL* glBlendFuncProc)(GLenum sfactor, GLenum dfactor);
typedef void(GL_BINDING_CALL* glBlendFuncSeparateProc)(GLenum srcRGB,
                                                       GLenum dstRGB,
                                                       GLenum srcAlpha,
                                                       GLenum dstAlpha);
typedef void(GL_BINDING_CALL* glBlitFramebufferProc)(GLint srcX0,
                                                     GLint srcY0,
                                                     GLint srcX1,
                                                     GLint srcY1,
                                                     GLint dstX0,
                                                     GLint dstY0,
                                                     GLint dstX1,
                                                     GLint dstY1,
                                                     GLbitfield mask,
                                                     GLenum filter);
typedef void(GL_BINDING_CALL* glBlitFramebufferANGLEProc)(GLint srcX0,
                                                          GLint srcY0,
                                                          GLint srcX1,
                                                          GLint srcY1,
                                                          GLint dstX0,
                                                          GLint dstY0,
                                                          GLint dstX1,
                                                          GLint dstY1,
                                                          GLbitfield mask,
                                                          GLenum filter);
typedef void(GL_BINDING_CALL* glBlitFramebufferEXTProc)(GLint srcX0,
                                                        GLint srcY0,
                                                        GLint srcX1,
                                                        GLint srcY1,
                                                        GLint dstX0,
                                                        GLint dstY0,
                                                        GLint dstX1,
                                                        GLint dstY1,
                                                        GLbitfield mask,
                                                        GLenum filter);
typedef void(GL_BINDING_CALL* glBufferDataProc)(GLenum target,
                                                GLsizeiptr size,
                                                const void* data,
                                                GLenum usage);
typedef void(GL_BINDING_CALL* glBufferSubDataProc)(GLenum target,
                                                   GLintptr offset,
                                                   GLsizeiptr size,
                                                   const void* data);
typedef GLenum(GL_BINDING_CALL* glCheckFramebufferStatusEXTProc)(GLenum target);
typedef void(GL_BINDING_CALL* glClearProc)(GLbitfield mask);
typedef void(GL_BINDING_CALL* glClearBufferfiProc)(GLenum buffer,
                                                   GLint drawbuffer,
                                                   const GLfloat depth,
                                                   GLint stencil);
typedef void(GL_BINDING_CALL* glClearBufferfvProc)(GLenum buffer,
                                                   GLint drawbuffer,
                                                   const GLfloat* value);
typedef void(GL_BINDING_CALL* glClearBufferivProc)(GLenum buffer,
                                                   GLint drawbuffer,
                                                   const GLint* value);
typedef void(GL_BINDING_CALL* glClearBufferuivProc)(GLenum buffer,
                                                    GLint drawbuffer,
                                                    const GLuint* value);
typedef void(GL_BINDING_CALL* glClearColorProc)(GLclampf red,
                                                GLclampf green,
                                                GLclampf blue,
                                                GLclampf alpha);
typedef void(GL_BINDING_CALL* glClearDepthProc)(GLclampd depth);
typedef void(GL_BINDING_CALL* glClearDepthfProc)(GLclampf depth);
typedef void(GL_BINDING_CALL* glClearStencilProc)(GLint s);
typedef GLenum(GL_BINDING_CALL* glClientWaitSyncProc)(GLsync sync,
                                                      GLbitfield flags,
                                                      GLuint64 timeout);
typedef void(GL_BINDING_CALL* glColorMaskProc)(GLboolean red,
                                               GLboolean green,
                                               GLboolean blue,
                                               GLboolean alpha);
typedef void(GL_BINDING_CALL* glCompileShaderProc)(GLuint shader);
typedef void(GL_BINDING_CALL* glCompressedTexImage2DProc)(GLenum target,
                                                          GLint level,
                                                          GLenum internalformat,
                                                          GLsizei width,
                                                          GLsizei height,
                                                          GLint border,
                                                          GLsizei imageSize,
                                                          const void* data);
typedef void(GL_BINDING_CALL* glCompressedTexImage3DProc)(GLenum target,
                                                          GLint level,
                                                          GLenum internalformat,
                                                          GLsizei width,
                                                          GLsizei height,
                                                          GLsizei depth,
                                                          GLint border,
                                                          GLsizei imageSize,
                                                          const void* data);
typedef void(GL_BINDING_CALL* glCompressedTexSubImage2DProc)(GLenum target,
                                                             GLint level,
                                                             GLint xoffset,
                                                             GLint yoffset,
                                                             GLsizei width,
                                                             GLsizei height,
                                                             GLenum format,
                                                             GLsizei imageSize,
                                                             const void* data);
typedef void(GL_BINDING_CALL* glCopyBufferSubDataProc)(GLenum readTarget,
                                                       GLenum writeTarget,
                                                       GLintptr readOffset,
                                                       GLintptr writeOffset,
                                                       GLsizeiptr size);
typedef void(GL_BINDING_CALL* glCopyTexImage2DProc)(GLenum target,
                                                    GLint level,
                                                    GLenum internalformat,
                                                    GLint x,
                                                    GLint y,
                                                    GLsizei width,
                                                    GLsizei height,
                                                    GLint border);
typedef void(GL_BINDING_CALL* glCopyTexSubImage2DProc)(GLenum target,
                                                       GLint level,
                                                       GLint xoffset,
                                                       GLint yoffset,
                                                       GLint x,
                                                       GLint y,
                                                       GLsizei width,
                                                       GLsizei height);
typedef void(GL_BINDING_CALL* glCopyTexSubImage3DProc)(GLenum target,
                                                       GLint level,
                                                       GLint xoffset,
                                                       GLint yoffset,
                                                       GLint zoffset,
                                                       GLint x,
                                                       GLint y,
                                                       GLsizei width,
                                                       GLsizei height);
typedef GLuint(GL_BINDING_CALL* glCreateProgramProc)(void);
typedef GLuint(GL_BINDING_CALL* glCreateShaderProc)(GLenum type);
typedef void(GL_BINDING_CALL* glCullFaceProc)(GLenum mode);
typedef void(GL_BINDING_CALL* glDeleteBuffersARBProc)(GLsizei n,
                                                      const GLuint* buffers);
typedef void(GL_BINDING_CALL* glDeleteFencesAPPLEProc)(GLsizei n,
                                                       const GLuint* fences);
typedef void(GL_BINDING_CALL* glDeleteFencesNVProc)(GLsizei n,
                                                    const GLuint* fences);
typedef void(GL_BINDING_CALL* glDeleteFramebuffersEXTProc)(
    GLsizei n,
    const GLuint* framebuffers);
typedef void(GL_BINDING_CALL* glDeleteProgramProc)(GLuint program);
typedef void(GL_BINDING_CALL* glDeleteQueriesProc)(GLsizei n,
                                                   const GLuint* ids);
typedef void(GL_BINDING_CALL* glDeleteRenderbuffersEXTProc)(
    GLsizei n,
    const GLuint* renderbuffers);
typedef void(GL_BINDING_CALL* glDeleteSamplersProc)(GLsizei n,
                                                    const GLuint* samplers);
typedef void(GL_BINDING_CALL* glDeleteShaderProc)(GLuint shader);
typedef void(GL_BINDING_CALL* glDeleteSyncProc)(GLsync sync);
typedef void(GL_BINDING_CALL* glDeleteTexturesProc)(GLsizei n,
                                                    const GLuint* textures);
typedef void(GL_BINDING_CALL* glDeleteTransformFeedbacksProc)(
    GLsizei n,
    const GLuint* ids);
typedef void(GL_BINDING_CALL* glDeleteVertexArraysOESProc)(
    GLsizei n,
    const GLuint* arrays);
typedef void(GL_BINDING_CALL* glDepthFuncProc)(GLenum func);
typedef void(GL_BINDING_CALL* glDepthMaskProc)(GLboolean flag);
typedef void(GL_BINDING_CALL* glDepthRangeProc)(GLclampd zNear, GLclampd zFar);
typedef void(GL_BINDING_CALL* glDepthRangefProc)(GLclampf zNear, GLclampf zFar);
typedef void(GL_BINDING_CALL* glDetachShaderProc)(GLuint program,
                                                  GLuint shader);
typedef void(GL_BINDING_CALL* glDisableProc)(GLenum cap);
typedef void(GL_BINDING_CALL* glDisableVertexAttribArrayProc)(GLuint index);
typedef void(GL_BINDING_CALL* glDiscardFramebufferEXTProc)(
    GLenum target,
    GLsizei numAttachments,
    const GLenum* attachments);
typedef void(GL_BINDING_CALL* glDrawArraysProc)(GLenum mode,
                                                GLint first,
                                                GLsizei count);
typedef void(GL_BINDING_CALL* glDrawArraysInstancedANGLEProc)(
    GLenum mode,
    GLint first,
    GLsizei count,
    GLsizei primcount);
typedef void(GL_BINDING_CALL* glDrawBufferProc)(GLenum mode);
typedef void(GL_BINDING_CALL* glDrawBuffersARBProc)(GLsizei n,
                                                    const GLenum* bufs);
typedef void(GL_BINDING_CALL* glDrawElementsProc)(GLenum mode,
                                                  GLsizei count,
                                                  GLenum type,
                                                  const void* indices);
typedef void(GL_BINDING_CALL* glDrawElementsInstancedANGLEProc)(
    GLenum mode,
    GLsizei count,
    GLenum type,
    const void* indices,
    GLsizei primcount);
typedef void(GL_BINDING_CALL* glDrawRangeElementsProc)(GLenum mode,
                                                       GLuint start,
                                                       GLuint end,
                                                       GLsizei count,
                                                       GLenum type,
                                                       const void* indices);
typedef void(GL_BINDING_CALL* glEGLImageTargetRenderbufferStorageOESProc)(
    GLenum target,
    GLeglImageOES image);
typedef void(GL_BINDING_CALL* glEGLImageTargetTexture2DOESProc)(
    GLenum target,
    GLeglImageOES image);
typedef void(GL_BINDING_CALL* glEnableProc)(GLenum cap);
typedef void(GL_BINDING_CALL* glEnableVertexAttribArrayProc)(GLuint index);
typedef void(GL_BINDING_CALL* glEndQueryProc)(GLenum target);
typedef void(GL_BINDING_CALL* glEndTransformFeedbackProc)(void);
typedef GLsync(GL_BINDING_CALL* glFenceSyncProc)(GLenum condition,
                                                 GLbitfield flags);
typedef void(GL_BINDING_CALL* glFinishProc)(void);
typedef void(GL_BINDING_CALL* glFinishFenceAPPLEProc)(GLuint fence);
typedef void(GL_BINDING_CALL* glFinishFenceNVProc)(GLuint fence);
typedef void(GL_BINDING_CALL* glFlushProc)(void);
typedef void(GL_BINDING_CALL* glFlushMappedBufferRangeProc)(GLenum target,
                                                            GLintptr offset,
                                                            GLsizeiptr length);
typedef void(GL_BINDING_CALL* glFramebufferRenderbufferEXTProc)(
    GLenum target,
    GLenum attachment,
    GLenum renderbuffertarget,
    GLuint renderbuffer);
typedef void(GL_BINDING_CALL* glFramebufferTexture2DEXTProc)(GLenum target,
                                                             GLenum attachment,
                                                             GLenum textarget,
                                                             GLuint texture,
                                                             GLint level);
typedef void(GL_BINDING_CALL* glFramebufferTexture2DMultisampleEXTProc)(
    GLenum target,
    GLenum attachment,
    GLenum textarget,
    GLuint texture,
    GLint level,
    GLsizei samples);
typedef void(GL_BINDING_CALL* glFramebufferTexture2DMultisampleIMGProc)(
    GLenum target,
    GLenum attachment,
    GLenum textarget,
    GLuint texture,
    GLint level,
    GLsizei samples);
typedef void(GL_BINDING_CALL* glFramebufferTextureLayerProc)(GLenum target,
                                                             GLenum attachment,
                                                             GLuint texture,
                                                             GLint level,
                                                             GLint layer);
typedef void(GL_BINDING_CALL* glFrontFaceProc)(GLenum mode);
typedef void(GL_BINDING_CALL* glGenBuffersARBProc)(GLsizei n, GLuint* buffers);
typedef void(GL_BINDING_CALL* glGenerateMipmapEXTProc)(GLenum target);
typedef void(GL_BINDING_CALL* glGenFencesAPPLEProc)(GLsizei n, GLuint* fences);
typedef void(GL_BINDING_CALL* glGenFencesNVProc)(GLsizei n, GLuint* fences);
typedef void(GL_BINDING_CALL* glGenFramebuffersEXTProc)(GLsizei n,
                                                        GLuint* framebuffers);
typedef void(GL_BINDING_CALL* glGenQueriesProc)(GLsizei n, GLuint* ids);
typedef void(GL_BINDING_CALL* glGenRenderbuffersEXTProc)(GLsizei n,
                                                         GLuint* renderbuffers);
typedef void(GL_BINDING_CALL* glGenSamplersProc)(GLsizei n, GLuint* samplers);
typedef void(GL_BINDING_CALL* glGenTexturesProc)(GLsizei n, GLuint* textures);
typedef void(GL_BINDING_CALL* glGenTransformFeedbacksProc)(GLsizei n,
                                                           GLuint* ids);
typedef void(GL_BINDING_CALL* glGenVertexArraysOESProc)(GLsizei n,
                                                        GLuint* arrays);
typedef void(GL_BINDING_CALL* glGetActiveAttribProc)(GLuint program,
                                                     GLuint index,
                                                     GLsizei bufsize,
                                                     GLsizei* length,
                                                     GLint* size,
                                                     GLenum* type,
                                                     char* name);
typedef void(GL_BINDING_CALL* glGetActiveUniformProc)(GLuint program,
                                                      GLuint index,
                                                      GLsizei bufsize,
                                                      GLsizei* length,
                                                      GLint* size,
                                                      GLenum* type,
                                                      char* name);
typedef void(GL_BINDING_CALL* glGetActiveUniformBlockivProc)(
    GLuint program,
    GLuint uniformBlockIndex,
    GLenum pname,
    GLint* params);
typedef void(GL_BINDING_CALL* glGetActiveUniformBlockNameProc)(
    GLuint program,
    GLuint uniformBlockIndex,
    GLsizei bufSize,
    GLsizei* length,
    char* uniformBlockName);
typedef void(GL_BINDING_CALL* glGetActiveUniformsivProc)(
    GLuint program,
    GLsizei uniformCount,
    const GLuint* uniformIndices,
    GLenum pname,
    GLint* params);
typedef void(GL_BINDING_CALL* glGetAttachedShadersProc)(GLuint program,
                                                        GLsizei maxcount,
                                                        GLsizei* count,
                                                        GLuint* shaders);
typedef GLint(GL_BINDING_CALL* glGetAttribLocationProc)(GLuint program,
                                                        const char* name);
typedef void(GL_BINDING_CALL* glGetBooleanvProc)(GLenum pname,
                                                 GLboolean* params);
typedef void(GL_BINDING_CALL* glGetBufferParameterivProc)(GLenum target,
                                                          GLenum pname,
                                                          GLint* params);
typedef GLenum(GL_BINDING_CALL* glGetErrorProc)(void);
typedef void(GL_BINDING_CALL* glGetFenceivNVProc)(GLuint fence,
                                                  GLenum pname,
                                                  GLint* params);
typedef void(GL_BINDING_CALL* glGetFloatvProc)(GLenum pname, GLfloat* params);
typedef GLint(GL_BINDING_CALL* glGetFragDataLocationProc)(GLuint program,
                                                          const char* name);
typedef void(GL_BINDING_CALL* glGetFramebufferAttachmentParameterivEXTProc)(
    GLenum target,
    GLenum attachment,
    GLenum pname,
    GLint* params);
typedef GLenum(GL_BINDING_CALL* glGetGraphicsResetStatusARBProc)(void);
typedef void(GL_BINDING_CALL* glGetInteger64i_vProc)(GLenum target,
                                                     GLuint index,
                                                     GLint64* data);
typedef void(GL_BINDING_CALL* glGetInteger64vProc)(GLenum pname,
                                                   GLint64* params);
typedef void(GL_BINDING_CALL* glGetIntegeri_vProc)(GLenum target,
                                                   GLuint index,
                                                   GLint* data);
typedef void(GL_BINDING_CALL* glGetIntegervProc)(GLenum pname, GLint* params);
typedef void(GL_BINDING_CALL* glGetInternalformativProc)(GLenum target,
                                                         GLenum internalformat,
                                                         GLenum pname,
                                                         GLsizei bufSize,
                                                         GLint* params);
typedef void(GL_BINDING_CALL* glGetProgramBinaryProc)(GLuint program,
                                                      GLsizei bufSize,
                                                      GLsizei* length,
                                                      GLenum* binaryFormat,
                                                      GLvoid* binary);
typedef void(GL_BINDING_CALL* glGetProgramInfoLogProc)(GLuint program,
                                                       GLsizei bufsize,
                                                       GLsizei* length,
                                                       char* infolog);
typedef void(GL_BINDING_CALL* glGetProgramivProc)(GLuint program,
                                                  GLenum pname,
                                                  GLint* params);
typedef GLint(GL_BINDING_CALL* glGetProgramResourceLocationProc)(
    GLuint program,
    GLenum programInterface,
    const char* name);
typedef void(GL_BINDING_CALL* glGetQueryivProc)(GLenum target,
                                                GLenum pname,
                                                GLint* params);
typedef void(GL_BINDING_CALL* glGetQueryObjecti64vProc)(GLuint id,
                                                        GLenum pname,
                                                        GLint64* params);
typedef void(GL_BINDING_CALL* glGetQueryObjectivProc)(GLuint id,
                                                      GLenum pname,
                                                      GLint* params);
typedef void(GL_BINDING_CALL* glGetQueryObjectui64vProc)(GLuint id,
                                                         GLenum pname,
                                                         GLuint64* params);
typedef void(GL_BINDING_CALL* glGetQueryObjectuivProc)(GLuint id,
                                                       GLenum pname,
                                                       GLuint* params);
typedef void(GL_BINDING_CALL* glGetRenderbufferParameterivEXTProc)(
    GLenum target,
    GLenum pname,
    GLint* params);
typedef void(GL_BINDING_CALL* glGetSamplerParameterfvProc)(GLuint sampler,
                                                           GLenum pname,
                                                           GLfloat* params);
typedef void(GL_BINDING_CALL* glGetSamplerParameterivProc)(GLuint sampler,
                                                           GLenum pname,
                                                           GLint* params);
typedef void(GL_BINDING_CALL* glGetShaderInfoLogProc)(GLuint shader,
                                                      GLsizei bufsize,
                                                      GLsizei* length,
                                                      char* infolog);
typedef void(GL_BINDING_CALL* glGetShaderivProc)(GLuint shader,
                                                 GLenum pname,
                                                 GLint* params);
typedef void(GL_BINDING_CALL* glGetShaderPrecisionFormatProc)(
    GLenum shadertype,
    GLenum precisiontype,
    GLint* range,
    GLint* precision);
typedef void(GL_BINDING_CALL* glGetShaderSourceProc)(GLuint shader,
                                                     GLsizei bufsize,
                                                     GLsizei* length,
                                                     char* source);
typedef const GLubyte*(GL_BINDING_CALL* glGetStringProc)(GLenum name);
typedef const GLubyte*(GL_BINDING_CALL* glGetStringiProc)(GLenum name,
                                                          GLuint index);
typedef void(GL_BINDING_CALL* glGetSyncivProc)(GLsync sync,
                                               GLenum pname,
                                               GLsizei bufSize,
                                               GLsizei* length,
                                               GLint* values);
typedef void(GL_BINDING_CALL* glGetTexLevelParameterfvProc)(GLenum target,
                                                            GLint level,
                                                            GLenum pname,
                                                            GLfloat* params);
typedef void(GL_BINDING_CALL* glGetTexLevelParameterivProc)(GLenum target,
                                                            GLint level,
                                                            GLenum pname,
                                                            GLint* params);
typedef void(GL_BINDING_CALL* glGetTexParameterfvProc)(GLenum target,
                                                       GLenum pname,
                                                       GLfloat* params);
typedef void(GL_BINDING_CALL* glGetTexParameterivProc)(GLenum target,
                                                       GLenum pname,
                                                       GLint* params);
typedef void(GL_BINDING_CALL* glGetTransformFeedbackVaryingProc)(
    GLuint program,
    GLuint index,
    GLsizei bufSize,
    GLsizei* length,
    GLsizei* size,
    GLenum* type,
    char* name);
typedef void(GL_BINDING_CALL* glGetTranslatedShaderSourceANGLEProc)(
    GLuint shader,
    GLsizei bufsize,
    GLsizei* length,
    char* source);
typedef GLuint(GL_BINDING_CALL* glGetUniformBlockIndexProc)(
    GLuint program,
    const char* uniformBlockName);
typedef void(GL_BINDING_CALL* glGetUniformfvProc)(GLuint program,
                                                  GLint location,
                                                  GLfloat* params);
typedef void(GL_BINDING_CALL* glGetUniformIndicesProc)(
    GLuint program,
    GLsizei uniformCount,
    const char* const* uniformNames,
    GLuint* uniformIndices);
typedef void(GL_BINDING_CALL* glGetUniformivProc)(GLuint program,
                                                  GLint location,
                                                  GLint* params);
typedef GLint(GL_BINDING_CALL* glGetUniformLocationProc)(GLuint program,
                                                         const char* name);
typedef void(GL_BINDING_CALL* glGetVertexAttribfvProc)(GLuint index,
                                                       GLenum pname,
                                                       GLfloat* params);
typedef void(GL_BINDING_CALL* glGetVertexAttribivProc)(GLuint index,
                                                       GLenum pname,
                                                       GLint* params);
typedef void(GL_BINDING_CALL* glGetVertexAttribPointervProc)(GLuint index,
                                                             GLenum pname,
                                                             void** pointer);
typedef void(GL_BINDING_CALL* glHintProc)(GLenum target, GLenum mode);
typedef void(GL_BINDING_CALL* glInsertEventMarkerEXTProc)(GLsizei length,
                                                          const char* marker);
typedef void(GL_BINDING_CALL* glInvalidateFramebufferProc)(
    GLenum target,
    GLsizei numAttachments,
    const GLenum* attachments);
typedef void(GL_BINDING_CALL* glInvalidateSubFramebufferProc)(
    GLenum target,
    GLsizei numAttachments,
    const GLenum* attachments,
    GLint x,
    GLint y,
    GLint width,
    GLint height);
typedef GLboolean(GL_BINDING_CALL* glIsBufferProc)(GLuint buffer);
typedef GLboolean(GL_BINDING_CALL* glIsEnabledProc)(GLenum cap);
typedef GLboolean(GL_BINDING_CALL* glIsFenceAPPLEProc)(GLuint fence);
typedef GLboolean(GL_BINDING_CALL* glIsFenceNVProc)(GLuint fence);
typedef GLboolean(GL_BINDING_CALL* glIsFramebufferEXTProc)(GLuint framebuffer);
typedef GLboolean(GL_BINDING_CALL* glIsProgramProc)(GLuint program);
typedef GLboolean(GL_BINDING_CALL* glIsQueryProc)(GLuint query);
typedef GLboolean(GL_BINDING_CALL* glIsRenderbufferEXTProc)(
    GLuint renderbuffer);
typedef GLboolean(GL_BINDING_CALL* glIsSamplerProc)(GLuint sampler);
typedef GLboolean(GL_BINDING_CALL* glIsShaderProc)(GLuint shader);
typedef GLboolean(GL_BINDING_CALL* glIsSyncProc)(GLsync sync);
typedef GLboolean(GL_BINDING_CALL* glIsTextureProc)(GLuint texture);
typedef GLboolean(GL_BINDING_CALL* glIsTransformFeedbackProc)(GLuint id);
typedef GLboolean(GL_BINDING_CALL* glIsVertexArrayOESProc)(GLuint array);
typedef void(GL_BINDING_CALL* glLineWidthProc)(GLfloat width);
typedef void(GL_BINDING_CALL* glLinkProgramProc)(GLuint program);
typedef void*(GL_BINDING_CALL* glMapBufferProc)(GLenum target, GLenum access);
typedef void*(GL_BINDING_CALL* glMapBufferRangeProc)(GLenum target,
                                                     GLintptr offset,
                                                     GLsizeiptr length,
                                                     GLbitfield access);
typedef void(GL_BINDING_CALL* glMatrixLoadfEXTProc)(GLenum matrixMode,
                                                    const GLfloat* m);
typedef void(GL_BINDING_CALL* glMatrixLoadIdentityEXTProc)(GLenum matrixMode);
typedef void(GL_BINDING_CALL* glPauseTransformFeedbackProc)(void);
typedef void(GL_BINDING_CALL* glPixelStoreiProc)(GLenum pname, GLint param);
typedef void(GL_BINDING_CALL* glPointParameteriProc)(GLenum pname, GLint param);
typedef void(GL_BINDING_CALL* glPolygonOffsetProc)(GLfloat factor,
                                                   GLfloat units);
typedef void(GL_BINDING_CALL* glPopGroupMarkerEXTProc)(void);
typedef void(GL_BINDING_CALL* glProgramBinaryProc)(GLuint program,
                                                   GLenum binaryFormat,
                                                   const GLvoid* binary,
                                                   GLsizei length);
typedef void(GL_BINDING_CALL* glProgramParameteriProc)(GLuint program,
                                                       GLenum pname,
                                                       GLint value);
typedef void(GL_BINDING_CALL* glPushGroupMarkerEXTProc)(GLsizei length,
                                                        const char* marker);
typedef void(GL_BINDING_CALL* glQueryCounterProc)(GLuint id, GLenum target);
typedef void(GL_BINDING_CALL* glReadBufferProc)(GLenum src);
typedef void(GL_BINDING_CALL* glReadPixelsProc)(GLint x,
                                                GLint y,
                                                GLsizei width,
                                                GLsizei height,
                                                GLenum format,
                                                GLenum type,
                                                void* pixels);
typedef void(GL_BINDING_CALL* glReleaseShaderCompilerProc)(void);
typedef void(GL_BINDING_CALL* glRenderbufferStorageEXTProc)(
    GLenum target,
    GLenum internalformat,
    GLsizei width,
    GLsizei height);
typedef void(GL_BINDING_CALL* glRenderbufferStorageMultisampleProc)(
    GLenum target,
    GLsizei samples,
    GLenum internalformat,
    GLsizei width,
    GLsizei height);
typedef void(GL_BINDING_CALL* glRenderbufferStorageMultisampleANGLEProc)(
    GLenum target,
    GLsizei samples,
    GLenum internalformat,
    GLsizei width,
    GLsizei height);
typedef void(GL_BINDING_CALL* glRenderbufferStorageMultisampleAPPLEProc)(
    GLenum target,
    GLsizei samples,
    GLenum internalformat,
    GLsizei width,
    GLsizei height);
typedef void(GL_BINDING_CALL* glRenderbufferStorageMultisampleEXTProc)(
    GLenum target,
    GLsizei samples,
    GLenum internalformat,
    GLsizei width,
    GLsizei height);
typedef void(GL_BINDING_CALL* glRenderbufferStorageMultisampleIMGProc)(
    GLenum target,
    GLsizei samples,
    GLenum internalformat,
    GLsizei width,
    GLsizei height);
typedef void(GL_BINDING_CALL* glResolveMultisampleFramebufferAPPLEProc)(void);
typedef void(GL_BINDING_CALL* glResumeTransformFeedbackProc)(void);
typedef void(GL_BINDING_CALL* glSampleCoverageProc)(GLclampf value,
                                                    GLboolean invert);
typedef void(GL_BINDING_CALL* glSamplerParameterfProc)(GLuint sampler,
                                                       GLenum pname,
                                                       GLfloat param);
typedef void(GL_BINDING_CALL* glSamplerParameterfvProc)(GLuint sampler,
                                                        GLenum pname,
                                                        const GLfloat* params);
typedef void(GL_BINDING_CALL* glSamplerParameteriProc)(GLuint sampler,
                                                       GLenum pname,
                                                       GLint param);
typedef void(GL_BINDING_CALL* glSamplerParameterivProc)(GLuint sampler,
                                                        GLenum pname,
                                                        const GLint* params);
typedef void(GL_BINDING_CALL* glScissorProc)(GLint x,
                                             GLint y,
                                             GLsizei width,
                                             GLsizei height);
typedef void(GL_BINDING_CALL* glSetFenceAPPLEProc)(GLuint fence);
typedef void(GL_BINDING_CALL* glSetFenceNVProc)(GLuint fence, GLenum condition);
typedef void(GL_BINDING_CALL* glShaderBinaryProc)(GLsizei n,
                                                  const GLuint* shaders,
                                                  GLenum binaryformat,
                                                  const void* binary,
                                                  GLsizei length);
typedef void(GL_BINDING_CALL* glShaderSourceProc)(GLuint shader,
                                                  GLsizei count,
                                                  const char* const* str,
                                                  const GLint* length);
typedef void(GL_BINDING_CALL* glStencilFuncProc)(GLenum func,
                                                 GLint ref,
                                                 GLuint mask);
typedef void(GL_BINDING_CALL* glStencilFuncSeparateProc)(GLenum face,
                                                         GLenum func,
                                                         GLint ref,
                                                         GLuint mask);
typedef void(GL_BINDING_CALL* glStencilMaskProc)(GLuint mask);
typedef void(GL_BINDING_CALL* glStencilMaskSeparateProc)(GLenum face,
                                                         GLuint mask);
typedef void(GL_BINDING_CALL* glStencilOpProc)(GLenum fail,
                                               GLenum zfail,
                                               GLenum zpass);
typedef void(GL_BINDING_CALL* glStencilOpSeparateProc)(GLenum face,
                                                       GLenum fail,
                                                       GLenum zfail,
                                                       GLenum zpass);
typedef GLboolean(GL_BINDING_CALL* glTestFenceAPPLEProc)(GLuint fence);
typedef GLboolean(GL_BINDING_CALL* glTestFenceNVProc)(GLuint fence);
typedef void(GL_BINDING_CALL* glTexImage2DProc)(GLenum target,
                                                GLint level,
                                                GLint internalformat,
                                                GLsizei width,
                                                GLsizei height,
                                                GLint border,
                                                GLenum format,
                                                GLenum type,
                                                const void* pixels);
typedef void(GL_BINDING_CALL* glTexImage3DProc)(GLenum target,
                                                GLint level,
                                                GLint internalformat,
                                                GLsizei width,
                                                GLsizei height,
                                                GLsizei depth,
                                                GLint border,
                                                GLenum format,
                                                GLenum type,
                                                const void* pixels);
typedef void(GL_BINDING_CALL* glTexParameterfProc)(GLenum target,
                                                   GLenum pname,
                                                   GLfloat param);
typedef void(GL_BINDING_CALL* glTexParameterfvProc)(GLenum target,
                                                    GLenum pname,
                                                    const GLfloat* params);
typedef void(GL_BINDING_CALL* glTexParameteriProc)(GLenum target,
                                                   GLenum pname,
                                                   GLint param);
typedef void(GL_BINDING_CALL* glTexParameterivProc)(GLenum target,
                                                    GLenum pname,
                                                    const GLint* params);
typedef void(GL_BINDING_CALL* glTexStorage2DEXTProc)(GLenum target,
                                                     GLsizei levels,
                                                     GLenum internalformat,
                                                     GLsizei width,
                                                     GLsizei height);
typedef void(GL_BINDING_CALL* glTexStorage3DProc)(GLenum target,
                                                  GLsizei levels,
                                                  GLenum internalformat,
                                                  GLsizei width,
                                                  GLsizei height,
                                                  GLsizei depth);
typedef void(GL_BINDING_CALL* glTexSubImage2DProc)(GLenum target,
                                                   GLint level,
                                                   GLint xoffset,
                                                   GLint yoffset,
                                                   GLsizei width,
                                                   GLsizei height,
                                                   GLenum format,
                                                   GLenum type,
                                                   const void* pixels);
typedef void(GL_BINDING_CALL* glTransformFeedbackVaryingsProc)(
    GLuint program,
    GLsizei count,
    const char* const* varyings,
    GLenum bufferMode);
typedef void(GL_BINDING_CALL* glUniform1fProc)(GLint location, GLfloat x);
typedef void(GL_BINDING_CALL* glUniform1fvProc)(GLint location,
                                                GLsizei count,
                                                const GLfloat* v);
typedef void(GL_BINDING_CALL* glUniform1iProc)(GLint location, GLint x);
typedef void(GL_BINDING_CALL* glUniform1ivProc)(GLint location,
                                                GLsizei count,
                                                const GLint* v);
typedef void(GL_BINDING_CALL* glUniform1uiProc)(GLint location, GLuint v0);
typedef void(GL_BINDING_CALL* glUniform1uivProc)(GLint location,
                                                 GLsizei count,
                                                 const GLuint* v);
typedef void(GL_BINDING_CALL* glUniform2fProc)(GLint location,
                                               GLfloat x,
                                               GLfloat y);
typedef void(GL_BINDING_CALL* glUniform2fvProc)(GLint location,
                                                GLsizei count,
                                                const GLfloat* v);
typedef void(GL_BINDING_CALL* glUniform2iProc)(GLint location,
                                               GLint x,
                                               GLint y);
typedef void(GL_BINDING_CALL* glUniform2ivProc)(GLint location,
                                                GLsizei count,
                                                const GLint* v);
typedef void(GL_BINDING_CALL* glUniform2uiProc)(GLint location,
                                                GLuint v0,
                                                GLuint v1);
typedef void(GL_BINDING_CALL* glUniform2uivProc)(GLint location,
                                                 GLsizei count,
                                                 const GLuint* v);
typedef void(GL_BINDING_CALL* glUniform3fProc)(GLint location,
                                               GLfloat x,
                                               GLfloat y,
                                               GLfloat z);
typedef void(GL_BINDING_CALL* glUniform3fvProc)(GLint location,
                                                GLsizei count,
                                                const GLfloat* v);
typedef void(GL_BINDING_CALL* glUniform3iProc)(GLint location,
                                               GLint x,
                                               GLint y,
                                               GLint z);
typedef void(GL_BINDING_CALL* glUniform3ivProc)(GLint location,
                                                GLsizei count,
                                                const GLint* v);
typedef void(GL_BINDING_CALL* glUniform3uiProc)(GLint location,
                                                GLuint v0,
                                                GLuint v1,
                                                GLuint v2);
typedef void(GL_BINDING_CALL* glUniform3uivProc)(GLint location,
                                                 GLsizei count,
                                                 const GLuint* v);
typedef void(GL_BINDING_CALL* glUniform4fProc)(GLint location,
                                               GLfloat x,
                                               GLfloat y,
                                               GLfloat z,
                                               GLfloat w);
typedef void(GL_BINDING_CALL* glUniform4fvProc)(GLint location,
                                                GLsizei count,
                                                const GLfloat* v);
typedef void(GL_BINDING_CALL* glUniform4iProc)(GLint location,
                                               GLint x,
                                               GLint y,
                                               GLint z,
                                               GLint w);
typedef void(GL_BINDING_CALL* glUniform4ivProc)(GLint location,
                                                GLsizei count,
                                                const GLint* v);
typedef void(GL_BINDING_CALL* glUniform4uiProc)(GLint location,
                                                GLuint v0,
                                                GLuint v1,
                                                GLuint v2,
                                                GLuint v3);
typedef void(GL_BINDING_CALL* glUniform4uivProc)(GLint location,
                                                 GLsizei count,
                                                 const GLuint* v);
typedef void(GL_BINDING_CALL* glUniformBlockBindingProc)(
    GLuint program,
    GLuint uniformBlockIndex,
    GLuint uniformBlockBinding);
typedef void(GL_BINDING_CALL* glUniformMatrix2fvProc)(GLint location,
                                                      GLsizei count,
                                                      GLboolean transpose,
                                                      const GLfloat* value);
typedef void(GL_BINDING_CALL* glUniformMatrix2x3fvProc)(GLint location,
                                                        GLsizei count,
                                                        GLboolean transpose,
                                                        const GLfloat* value);
typedef void(GL_BINDING_CALL* glUniformMatrix2x4fvProc)(GLint location,
                                                        GLsizei count,
                                                        GLboolean transpose,
                                                        const GLfloat* value);
typedef void(GL_BINDING_CALL* glUniformMatrix3fvProc)(GLint location,
                                                      GLsizei count,
                                                      GLboolean transpose,
                                                      const GLfloat* value);
typedef void(GL_BINDING_CALL* glUniformMatrix3x2fvProc)(GLint location,
                                                        GLsizei count,
                                                        GLboolean transpose,
                                                        const GLfloat* value);
typedef void(GL_BINDING_CALL* glUniformMatrix3x4fvProc)(GLint location,
                                                        GLsizei count,
                                                        GLboolean transpose,
                                                        const GLfloat* value);
typedef void(GL_BINDING_CALL* glUniformMatrix4fvProc)(GLint location,
                                                      GLsizei count,
                                                      GLboolean transpose,
                                                      const GLfloat* value);
typedef void(GL_BINDING_CALL* glUniformMatrix4x2fvProc)(GLint location,
                                                        GLsizei count,
                                                        GLboolean transpose,
                                                        const GLfloat* value);
typedef void(GL_BINDING_CALL* glUniformMatrix4x3fvProc)(GLint location,
                                                        GLsizei count,
                                                        GLboolean transpose,
                                                        const GLfloat* value);
typedef GLboolean(GL_BINDING_CALL* glUnmapBufferProc)(GLenum target);
typedef void(GL_BINDING_CALL* glUseProgramProc)(GLuint program);
typedef void(GL_BINDING_CALL* glValidateProgramProc)(GLuint program);
typedef void(GL_BINDING_CALL* glVertexAttrib1fProc)(GLuint indx, GLfloat x);
typedef void(GL_BINDING_CALL* glVertexAttrib1fvProc)(GLuint indx,
                                                     const GLfloat* values);
typedef void(GL_BINDING_CALL* glVertexAttrib2fProc)(GLuint indx,
                                                    GLfloat x,
                                                    GLfloat y);
typedef void(GL_BINDING_CALL* glVertexAttrib2fvProc)(GLuint indx,
                                                     const GLfloat* values);
typedef void(GL_BINDING_CALL* glVertexAttrib3fProc)(GLuint indx,
                                                    GLfloat x,
                                                    GLfloat y,
                                                    GLfloat z);
typedef void(GL_BINDING_CALL* glVertexAttrib3fvProc)(GLuint indx,
                                                     const GLfloat* values);
typedef void(GL_BINDING_CALL* glVertexAttrib4fProc)(GLuint indx,
                                                    GLfloat x,
                                                    GLfloat y,
                                                    GLfloat z,
                                                    GLfloat w);
typedef void(GL_BINDING_CALL* glVertexAttrib4fvProc)(GLuint indx,
                                                     const GLfloat* values);
typedef void(GL_BINDING_CALL* glVertexAttribDivisorANGLEProc)(GLuint index,
                                                              GLuint divisor);
typedef void(GL_BINDING_CALL* glVertexAttribI4iProc)(GLuint indx,
                                                     GLint x,
                                                     GLint y,
                                                     GLint z,
                                                     GLint w);
typedef void(GL_BINDING_CALL* glVertexAttribI4ivProc)(GLuint indx,
                                                      const GLint* values);
typedef void(GL_BINDING_CALL* glVertexAttribI4uiProc)(GLuint indx,
                                                      GLuint x,
                                                      GLuint y,
                                                      GLuint z,
                                                      GLuint w);
typedef void(GL_BINDING_CALL* glVertexAttribI4uivProc)(GLuint indx,
                                                       const GLuint* values);
typedef void(GL_BINDING_CALL* glVertexAttribIPointerProc)(GLuint indx,
                                                          GLint size,
                                                          GLenum type,
                                                          GLsizei stride,
                                                          const void* ptr);
typedef void(GL_BINDING_CALL* glVertexAttribPointerProc)(GLuint indx,
                                                         GLint size,
                                                         GLenum type,
                                                         GLboolean normalized,
                                                         GLsizei stride,
                                                         const void* ptr);
typedef void(GL_BINDING_CALL* glViewportProc)(GLint x,
                                              GLint y,
                                              GLsizei width,
                                              GLsizei height);
typedef GLenum(GL_BINDING_CALL* glWaitSyncProc)(GLsync sync,
                                                GLbitfield flags,
                                                GLuint64 timeout);

struct ExtensionsGL {
  bool b_GL_ANGLE_framebuffer_blit;
  bool b_GL_ANGLE_framebuffer_multisample;
  bool b_GL_ANGLE_instanced_arrays;
  bool b_GL_ANGLE_translated_shader_source;
  bool b_GL_APPLE_fence;
  bool b_GL_APPLE_framebuffer_multisample;
  bool b_GL_APPLE_vertex_array_object;
  bool b_GL_ARB_draw_buffers;
  bool b_GL_ARB_draw_instanced;
  bool b_GL_ARB_get_program_binary;
  bool b_GL_ARB_instanced_arrays;
  bool b_GL_ARB_map_buffer_range;
  bool b_GL_ARB_occlusion_query;
  bool b_GL_ARB_robustness;
  bool b_GL_ARB_sync;
  bool b_GL_ARB_texture_storage;
  bool b_GL_ARB_timer_query;
  bool b_GL_ARB_vertex_array_object;
  bool b_GL_CHROMIUM_gles_depth_binding_hack;
  bool b_GL_EXT_debug_marker;
  bool b_GL_EXT_direct_state_access;
  bool b_GL_EXT_discard_framebuffer;
  bool b_GL_EXT_disjoint_timer_query;
  bool b_GL_EXT_draw_buffers;
  bool b_GL_EXT_framebuffer_blit;
  bool b_GL_EXT_framebuffer_multisample;
  bool b_GL_EXT_framebuffer_object;
  bool b_GL_EXT_map_buffer_range;
  bool b_GL_EXT_multisampled_render_to_texture;
  bool b_GL_EXT_occlusion_query_boolean;
  bool b_GL_EXT_robustness;
  bool b_GL_EXT_texture_storage;
  bool b_GL_EXT_timer_query;
  bool b_GL_IMG_multisampled_render_to_texture;
  bool b_GL_KHR_blend_equation_advanced;
  bool b_GL_KHR_robustness;
  bool b_GL_NV_blend_equation_advanced;
  bool b_GL_NV_fence;
  bool b_GL_NV_path_rendering;
  bool b_GL_OES_EGL_image;
  bool b_GL_OES_get_program_binary;
  bool b_GL_OES_mapbuffer;
  bool b_GL_OES_vertex_array_object;
};

struct ProcsGL {
  glActiveTextureProc glActiveTextureFn;
  glAttachShaderProc glAttachShaderFn;
  glBeginQueryProc glBeginQueryFn;
  glBeginTransformFeedbackProc glBeginTransformFeedbackFn;
  glBindAttribLocationProc glBindAttribLocationFn;
  glBindBufferProc glBindBufferFn;
  glBindBufferBaseProc glBindBufferBaseFn;
  glBindBufferRangeProc glBindBufferRangeFn;
  glBindFragDataLocationProc glBindFragDataLocationFn;
  glBindFragDataLocationIndexedProc glBindFragDataLocationIndexedFn;
  glBindFramebufferEXTProc glBindFramebufferEXTFn;
  glBindRenderbufferEXTProc glBindRenderbufferEXTFn;
  glBindSamplerProc glBindSamplerFn;
  glBindTextureProc glBindTextureFn;
  glBindTransformFeedbackProc glBindTransformFeedbackFn;
  glBindVertexArrayOESProc glBindVertexArrayOESFn;
  glBlendBarrierKHRProc glBlendBarrierKHRFn;
  glBlendColorProc glBlendColorFn;
  glBlendEquationProc glBlendEquationFn;
  glBlendEquationSeparateProc glBlendEquationSeparateFn;
  glBlendFuncProc glBlendFuncFn;
  glBlendFuncSeparateProc glBlendFuncSeparateFn;
  glBlitFramebufferProc glBlitFramebufferFn;
  glBlitFramebufferANGLEProc glBlitFramebufferANGLEFn;
  glBlitFramebufferEXTProc glBlitFramebufferEXTFn;
  glBufferDataProc glBufferDataFn;
  glBufferSubDataProc glBufferSubDataFn;
  glCheckFramebufferStatusEXTProc glCheckFramebufferStatusEXTFn;
  glClearProc glClearFn;
  glClearBufferfiProc glClearBufferfiFn;
  glClearBufferfvProc glClearBufferfvFn;
  glClearBufferivProc glClearBufferivFn;
  glClearBufferuivProc glClearBufferuivFn;
  glClearColorProc glClearColorFn;
  glClearDepthProc glClearDepthFn;
  glClearDepthfProc glClearDepthfFn;
  glClearStencilProc glClearStencilFn;
  glClientWaitSyncProc glClientWaitSyncFn;
  glColorMaskProc glColorMaskFn;
  glCompileShaderProc glCompileShaderFn;
  glCompressedTexImage2DProc glCompressedTexImage2DFn;
  glCompressedTexImage3DProc glCompressedTexImage3DFn;
  glCompressedTexSubImage2DProc glCompressedTexSubImage2DFn;
  glCopyBufferSubDataProc glCopyBufferSubDataFn;
  glCopyTexImage2DProc glCopyTexImage2DFn;
  glCopyTexSubImage2DProc glCopyTexSubImage2DFn;
  glCopyTexSubImage3DProc glCopyTexSubImage3DFn;
  glCreateProgramProc glCreateProgramFn;
  glCreateShaderProc glCreateShaderFn;
  glCullFaceProc glCullFaceFn;
  glDeleteBuffersARBProc glDeleteBuffersARBFn;
  glDeleteFencesAPPLEProc glDeleteFencesAPPLEFn;
  glDeleteFencesNVProc glDeleteFencesNVFn;
  glDeleteFramebuffersEXTProc glDeleteFramebuffersEXTFn;
  glDeleteProgramProc glDeleteProgramFn;
  glDeleteQueriesProc glDeleteQueriesFn;
  glDeleteRenderbuffersEXTProc glDeleteRenderbuffersEXTFn;
  glDeleteSamplersProc glDeleteSamplersFn;
  glDeleteShaderProc glDeleteShaderFn;
  glDeleteSyncProc glDeleteSyncFn;
  glDeleteTexturesProc glDeleteTexturesFn;
  glDeleteTransformFeedbacksProc glDeleteTransformFeedbacksFn;
  glDeleteVertexArraysOESProc glDeleteVertexArraysOESFn;
  glDepthFuncProc glDepthFuncFn;
  glDepthMaskProc glDepthMaskFn;
  glDepthRangeProc glDepthRangeFn;
  glDepthRangefProc glDepthRangefFn;
  glDetachShaderProc glDetachShaderFn;
  glDisableProc glDisableFn;
  glDisableVertexAttribArrayProc glDisableVertexAttribArrayFn;
  glDiscardFramebufferEXTProc glDiscardFramebufferEXTFn;
  glDrawArraysProc glDrawArraysFn;
  glDrawArraysInstancedANGLEProc glDrawArraysInstancedANGLEFn;
  glDrawBufferProc glDrawBufferFn;
  glDrawBuffersARBProc glDrawBuffersARBFn;
  glDrawElementsProc glDrawElementsFn;
  glDrawElementsInstancedANGLEProc glDrawElementsInstancedANGLEFn;
  glDrawRangeElementsProc glDrawRangeElementsFn;
  glEGLImageTargetRenderbufferStorageOESProc
      glEGLImageTargetRenderbufferStorageOESFn;
  glEGLImageTargetTexture2DOESProc glEGLImageTargetTexture2DOESFn;
  glEnableProc glEnableFn;
  glEnableVertexAttribArrayProc glEnableVertexAttribArrayFn;
  glEndQueryProc glEndQueryFn;
  glEndTransformFeedbackProc glEndTransformFeedbackFn;
  glFenceSyncProc glFenceSyncFn;
  glFinishProc glFinishFn;
  glFinishFenceAPPLEProc glFinishFenceAPPLEFn;
  glFinishFenceNVProc glFinishFenceNVFn;
  glFlushProc glFlushFn;
  glFlushMappedBufferRangeProc glFlushMappedBufferRangeFn;
  glFramebufferRenderbufferEXTProc glFramebufferRenderbufferEXTFn;
  glFramebufferTexture2DEXTProc glFramebufferTexture2DEXTFn;
  glFramebufferTexture2DMultisampleEXTProc
      glFramebufferTexture2DMultisampleEXTFn;
  glFramebufferTexture2DMultisampleIMGProc
      glFramebufferTexture2DMultisampleIMGFn;
  glFramebufferTextureLayerProc glFramebufferTextureLayerFn;
  glFrontFaceProc glFrontFaceFn;
  glGenBuffersARBProc glGenBuffersARBFn;
  glGenerateMipmapEXTProc glGenerateMipmapEXTFn;
  glGenFencesAPPLEProc glGenFencesAPPLEFn;
  glGenFencesNVProc glGenFencesNVFn;
  glGenFramebuffersEXTProc glGenFramebuffersEXTFn;
  glGenQueriesProc glGenQueriesFn;
  glGenRenderbuffersEXTProc glGenRenderbuffersEXTFn;
  glGenSamplersProc glGenSamplersFn;
  glGenTexturesProc glGenTexturesFn;
  glGenTransformFeedbacksProc glGenTransformFeedbacksFn;
  glGenVertexArraysOESProc glGenVertexArraysOESFn;
  glGetActiveAttribProc glGetActiveAttribFn;
  glGetActiveUniformProc glGetActiveUniformFn;
  glGetActiveUniformBlockivProc glGetActiveUniformBlockivFn;
  glGetActiveUniformBlockNameProc glGetActiveUniformBlockNameFn;
  glGetActiveUniformsivProc glGetActiveUniformsivFn;
  glGetAttachedShadersProc glGetAttachedShadersFn;
  glGetAttribLocationProc glGetAttribLocationFn;
  glGetBooleanvProc glGetBooleanvFn;
  glGetBufferParameterivProc glGetBufferParameterivFn;
  glGetErrorProc glGetErrorFn;
  glGetFenceivNVProc glGetFenceivNVFn;
  glGetFloatvProc glGetFloatvFn;
  glGetFragDataLocationProc glGetFragDataLocationFn;
  glGetFramebufferAttachmentParameterivEXTProc
      glGetFramebufferAttachmentParameterivEXTFn;
  glGetGraphicsResetStatusARBProc glGetGraphicsResetStatusARBFn;
  glGetInteger64i_vProc glGetInteger64i_vFn;
  glGetInteger64vProc glGetInteger64vFn;
  glGetIntegeri_vProc glGetIntegeri_vFn;
  glGetIntegervProc glGetIntegervFn;
  glGetInternalformativProc glGetInternalformativFn;
  glGetProgramBinaryProc glGetProgramBinaryFn;
  glGetProgramInfoLogProc glGetProgramInfoLogFn;
  glGetProgramivProc glGetProgramivFn;
  glGetProgramResourceLocationProc glGetProgramResourceLocationFn;
  glGetQueryivProc glGetQueryivFn;
  glGetQueryObjecti64vProc glGetQueryObjecti64vFn;
  glGetQueryObjectivProc glGetQueryObjectivFn;
  glGetQueryObjectui64vProc glGetQueryObjectui64vFn;
  glGetQueryObjectuivProc glGetQueryObjectuivFn;
  glGetRenderbufferParameterivEXTProc glGetRenderbufferParameterivEXTFn;
  glGetSamplerParameterfvProc glGetSamplerParameterfvFn;
  glGetSamplerParameterivProc glGetSamplerParameterivFn;
  glGetShaderInfoLogProc glGetShaderInfoLogFn;
  glGetShaderivProc glGetShaderivFn;
  glGetShaderPrecisionFormatProc glGetShaderPrecisionFormatFn;
  glGetShaderSourceProc glGetShaderSourceFn;
  glGetStringProc glGetStringFn;
  glGetStringiProc glGetStringiFn;
  glGetSyncivProc glGetSyncivFn;
  glGetTexLevelParameterfvProc glGetTexLevelParameterfvFn;
  glGetTexLevelParameterivProc glGetTexLevelParameterivFn;
  glGetTexParameterfvProc glGetTexParameterfvFn;
  glGetTexParameterivProc glGetTexParameterivFn;
  glGetTransformFeedbackVaryingProc glGetTransformFeedbackVaryingFn;
  glGetTranslatedShaderSourceANGLEProc glGetTranslatedShaderSourceANGLEFn;
  glGetUniformBlockIndexProc glGetUniformBlockIndexFn;
  glGetUniformfvProc glGetUniformfvFn;
  glGetUniformIndicesProc glGetUniformIndicesFn;
  glGetUniformivProc glGetUniformivFn;
  glGetUniformLocationProc glGetUniformLocationFn;
  glGetVertexAttribfvProc glGetVertexAttribfvFn;
  glGetVertexAttribivProc glGetVertexAttribivFn;
  glGetVertexAttribPointervProc glGetVertexAttribPointervFn;
  glHintProc glHintFn;
  glInsertEventMarkerEXTProc glInsertEventMarkerEXTFn;
  glInvalidateFramebufferProc glInvalidateFramebufferFn;
  glInvalidateSubFramebufferProc glInvalidateSubFramebufferFn;
  glIsBufferProc glIsBufferFn;
  glIsEnabledProc glIsEnabledFn;
  glIsFenceAPPLEProc glIsFenceAPPLEFn;
  glIsFenceNVProc glIsFenceNVFn;
  glIsFramebufferEXTProc glIsFramebufferEXTFn;
  glIsProgramProc glIsProgramFn;
  glIsQueryProc glIsQueryFn;
  glIsRenderbufferEXTProc glIsRenderbufferEXTFn;
  glIsSamplerProc glIsSamplerFn;
  glIsShaderProc glIsShaderFn;
  glIsSyncProc glIsSyncFn;
  glIsTextureProc glIsTextureFn;
  glIsTransformFeedbackProc glIsTransformFeedbackFn;
  glIsVertexArrayOESProc glIsVertexArrayOESFn;
  glLineWidthProc glLineWidthFn;
  glLinkProgramProc glLinkProgramFn;
  glMapBufferProc glMapBufferFn;
  glMapBufferRangeProc glMapBufferRangeFn;
  glMatrixLoadfEXTProc glMatrixLoadfEXTFn;
  glMatrixLoadIdentityEXTProc glMatrixLoadIdentityEXTFn;
  glPauseTransformFeedbackProc glPauseTransformFeedbackFn;
  glPixelStoreiProc glPixelStoreiFn;
  glPointParameteriProc glPointParameteriFn;
  glPolygonOffsetProc glPolygonOffsetFn;
  glPopGroupMarkerEXTProc glPopGroupMarkerEXTFn;
  glProgramBinaryProc glProgramBinaryFn;
  glProgramParameteriProc glProgramParameteriFn;
  glPushGroupMarkerEXTProc glPushGroupMarkerEXTFn;
  glQueryCounterProc glQueryCounterFn;
  glReadBufferProc glReadBufferFn;
  glReadPixelsProc glReadPixelsFn;
  glReleaseShaderCompilerProc glReleaseShaderCompilerFn;
  glRenderbufferStorageEXTProc glRenderbufferStorageEXTFn;
  glRenderbufferStorageMultisampleProc glRenderbufferStorageMultisampleFn;
  glRenderbufferStorageMultisampleANGLEProc
      glRenderbufferStorageMultisampleANGLEFn;
  glRenderbufferStorageMultisampleAPPLEProc
      glRenderbufferStorageMultisampleAPPLEFn;
  glRenderbufferStorageMultisampleEXTProc glRenderbufferStorageMultisampleEXTFn;
  glRenderbufferStorageMultisampleIMGProc glRenderbufferStorageMultisampleIMGFn;
  glResolveMultisampleFramebufferAPPLEProc
      glResolveMultisampleFramebufferAPPLEFn;
  glResumeTransformFeedbackProc glResumeTransformFeedbackFn;
  glSampleCoverageProc glSampleCoverageFn;
  glSamplerParameterfProc glSamplerParameterfFn;
  glSamplerParameterfvProc glSamplerParameterfvFn;
  glSamplerParameteriProc glSamplerParameteriFn;
  glSamplerParameterivProc glSamplerParameterivFn;
  glScissorProc glScissorFn;
  glSetFenceAPPLEProc glSetFenceAPPLEFn;
  glSetFenceNVProc glSetFenceNVFn;
  glShaderBinaryProc glShaderBinaryFn;
  glShaderSourceProc glShaderSourceFn;
  glStencilFuncProc glStencilFuncFn;
  glStencilFuncSeparateProc glStencilFuncSeparateFn;
  glStencilMaskProc glStencilMaskFn;
  glStencilMaskSeparateProc glStencilMaskSeparateFn;
  glStencilOpProc glStencilOpFn;
  glStencilOpSeparateProc glStencilOpSeparateFn;
  glTestFenceAPPLEProc glTestFenceAPPLEFn;
  glTestFenceNVProc glTestFenceNVFn;
  glTexImage2DProc glTexImage2DFn;
  glTexImage3DProc glTexImage3DFn;
  glTexParameterfProc glTexParameterfFn;
  glTexParameterfvProc glTexParameterfvFn;
  glTexParameteriProc glTexParameteriFn;
  glTexParameterivProc glTexParameterivFn;
  glTexStorage2DEXTProc glTexStorage2DEXTFn;
  glTexStorage3DProc glTexStorage3DFn;
  glTexSubImage2DProc glTexSubImage2DFn;
  glTransformFeedbackVaryingsProc glTransformFeedbackVaryingsFn;
  glUniform1fProc glUniform1fFn;
  glUniform1fvProc glUniform1fvFn;
  glUniform1iProc glUniform1iFn;
  glUniform1ivProc glUniform1ivFn;
  glUniform1uiProc glUniform1uiFn;
  glUniform1uivProc glUniform1uivFn;
  glUniform2fProc glUniform2fFn;
  glUniform2fvProc glUniform2fvFn;
  glUniform2iProc glUniform2iFn;
  glUniform2ivProc glUniform2ivFn;
  glUniform2uiProc glUniform2uiFn;
  glUniform2uivProc glUniform2uivFn;
  glUniform3fProc glUniform3fFn;
  glUniform3fvProc glUniform3fvFn;
  glUniform3iProc glUniform3iFn;
  glUniform3ivProc glUniform3ivFn;
  glUniform3uiProc glUniform3uiFn;
  glUniform3uivProc glUniform3uivFn;
  glUniform4fProc glUniform4fFn;
  glUniform4fvProc glUniform4fvFn;
  glUniform4iProc glUniform4iFn;
  glUniform4ivProc glUniform4ivFn;
  glUniform4uiProc glUniform4uiFn;
  glUniform4uivProc glUniform4uivFn;
  glUniformBlockBindingProc glUniformBlockBindingFn;
  glUniformMatrix2fvProc glUniformMatrix2fvFn;
  glUniformMatrix2x3fvProc glUniformMatrix2x3fvFn;
  glUniformMatrix2x4fvProc glUniformMatrix2x4fvFn;
  glUniformMatrix3fvProc glUniformMatrix3fvFn;
  glUniformMatrix3x2fvProc glUniformMatrix3x2fvFn;
  glUniformMatrix3x4fvProc glUniformMatrix3x4fvFn;
  glUniformMatrix4fvProc glUniformMatrix4fvFn;
  glUniformMatrix4x2fvProc glUniformMatrix4x2fvFn;
  glUniformMatrix4x3fvProc glUniformMatrix4x3fvFn;
  glUnmapBufferProc glUnmapBufferFn;
  glUseProgramProc glUseProgramFn;
  glValidateProgramProc glValidateProgramFn;
  glVertexAttrib1fProc glVertexAttrib1fFn;
  glVertexAttrib1fvProc glVertexAttrib1fvFn;
  glVertexAttrib2fProc glVertexAttrib2fFn;
  glVertexAttrib2fvProc glVertexAttrib2fvFn;
  glVertexAttrib3fProc glVertexAttrib3fFn;
  glVertexAttrib3fvProc glVertexAttrib3fvFn;
  glVertexAttrib4fProc glVertexAttrib4fFn;
  glVertexAttrib4fvProc glVertexAttrib4fvFn;
  glVertexAttribDivisorANGLEProc glVertexAttribDivisorANGLEFn;
  glVertexAttribI4iProc glVertexAttribI4iFn;
  glVertexAttribI4ivProc glVertexAttribI4ivFn;
  glVertexAttribI4uiProc glVertexAttribI4uiFn;
  glVertexAttribI4uivProc glVertexAttribI4uivFn;
  glVertexAttribIPointerProc glVertexAttribIPointerFn;
  glVertexAttribPointerProc glVertexAttribPointerFn;
  glViewportProc glViewportFn;
  glWaitSyncProc glWaitSyncFn;
};

class GL_EXPORT GLApi {
 public:
  GLApi();
  virtual ~GLApi();

  virtual void glActiveTextureFn(GLenum texture) = 0;
  virtual void glAttachShaderFn(GLuint program, GLuint shader) = 0;
  virtual void glBeginQueryFn(GLenum target, GLuint id) = 0;
  virtual void glBeginTransformFeedbackFn(GLenum primitiveMode) = 0;
  virtual void glBindAttribLocationFn(GLuint program,
                                      GLuint index,
                                      const char* name) = 0;
  virtual void glBindBufferFn(GLenum target, GLuint buffer) = 0;
  virtual void glBindBufferBaseFn(GLenum target,
                                  GLuint index,
                                  GLuint buffer) = 0;
  virtual void glBindBufferRangeFn(GLenum target,
                                   GLuint index,
                                   GLuint buffer,
                                   GLintptr offset,
                                   GLsizeiptr size) = 0;
  virtual void glBindFragDataLocationFn(GLuint program,
                                        GLuint colorNumber,
                                        const char* name) = 0;
  virtual void glBindFragDataLocationIndexedFn(GLuint program,
                                               GLuint colorNumber,
                                               GLuint index,
                                               const char* name) = 0;
  virtual void glBindFramebufferEXTFn(GLenum target, GLuint framebuffer) = 0;
  virtual void glBindRenderbufferEXTFn(GLenum target, GLuint renderbuffer) = 0;
  virtual void glBindSamplerFn(GLuint unit, GLuint sampler) = 0;
  virtual void glBindTextureFn(GLenum target, GLuint texture) = 0;
  virtual void glBindTransformFeedbackFn(GLenum target, GLuint id) = 0;
  virtual void glBindVertexArrayOESFn(GLuint array) = 0;
  virtual void glBlendBarrierKHRFn(void) = 0;
  virtual void glBlendColorFn(GLclampf red,
                              GLclampf green,
                              GLclampf blue,
                              GLclampf alpha) = 0;
  virtual void glBlendEquationFn(GLenum mode) = 0;
  virtual void glBlendEquationSeparateFn(GLenum modeRGB, GLenum modeAlpha) = 0;
  virtual void glBlendFuncFn(GLenum sfactor, GLenum dfactor) = 0;
  virtual void glBlendFuncSeparateFn(GLenum srcRGB,
                                     GLenum dstRGB,
                                     GLenum srcAlpha,
                                     GLenum dstAlpha) = 0;
  virtual void glBlitFramebufferFn(GLint srcX0,
                                   GLint srcY0,
                                   GLint srcX1,
                                   GLint srcY1,
                                   GLint dstX0,
                                   GLint dstY0,
                                   GLint dstX1,
                                   GLint dstY1,
                                   GLbitfield mask,
                                   GLenum filter) = 0;
  virtual void glBlitFramebufferANGLEFn(GLint srcX0,
                                        GLint srcY0,
                                        GLint srcX1,
                                        GLint srcY1,
                                        GLint dstX0,
                                        GLint dstY0,
                                        GLint dstX1,
                                        GLint dstY1,
                                        GLbitfield mask,
                                        GLenum filter) = 0;
  virtual void glBlitFramebufferEXTFn(GLint srcX0,
                                      GLint srcY0,
                                      GLint srcX1,
                                      GLint srcY1,
                                      GLint dstX0,
                                      GLint dstY0,
                                      GLint dstX1,
                                      GLint dstY1,
                                      GLbitfield mask,
                                      GLenum filter) = 0;
  virtual void glBufferDataFn(GLenum target,
                              GLsizeiptr size,
                              const void* data,
                              GLenum usage) = 0;
  virtual void glBufferSubDataFn(GLenum target,
                                 GLintptr offset,
                                 GLsizeiptr size,
                                 const void* data) = 0;
  virtual GLenum glCheckFramebufferStatusEXTFn(GLenum target) = 0;
  virtual void glClearFn(GLbitfield mask) = 0;
  virtual void glClearBufferfiFn(GLenum buffer,
                                 GLint drawbuffer,
                                 const GLfloat depth,
                                 GLint stencil) = 0;
  virtual void glClearBufferfvFn(GLenum buffer,
                                 GLint drawbuffer,
                                 const GLfloat* value) = 0;
  virtual void glClearBufferivFn(GLenum buffer,
                                 GLint drawbuffer,
                                 const GLint* value) = 0;
  virtual void glClearBufferuivFn(GLenum buffer,
                                  GLint drawbuffer,
                                  const GLuint* value) = 0;
  virtual void glClearColorFn(GLclampf red,
                              GLclampf green,
                              GLclampf blue,
                              GLclampf alpha) = 0;
  virtual void glClearDepthFn(GLclampd depth) = 0;
  virtual void glClearDepthfFn(GLclampf depth) = 0;
  virtual void glClearStencilFn(GLint s) = 0;
  virtual GLenum glClientWaitSyncFn(GLsync sync,
                                    GLbitfield flags,
                                    GLuint64 timeout) = 0;
  virtual void glColorMaskFn(GLboolean red,
                             GLboolean green,
                             GLboolean blue,
                             GLboolean alpha) = 0;
  virtual void glCompileShaderFn(GLuint shader) = 0;
  virtual void glCompressedTexImage2DFn(GLenum target,
                                        GLint level,
                                        GLenum internalformat,
                                        GLsizei width,
                                        GLsizei height,
                                        GLint border,
                                        GLsizei imageSize,
                                        const void* data) = 0;
  virtual void glCompressedTexImage3DFn(GLenum target,
                                        GLint level,
                                        GLenum internalformat,
                                        GLsizei width,
                                        GLsizei height,
                                        GLsizei depth,
                                        GLint border,
                                        GLsizei imageSize,
                                        const void* data) = 0;
  virtual void glCompressedTexSubImage2DFn(GLenum target,
                                           GLint level,
                                           GLint xoffset,
                                           GLint yoffset,
                                           GLsizei width,
                                           GLsizei height,
                                           GLenum format,
                                           GLsizei imageSize,
                                           const void* data) = 0;
  virtual void glCopyBufferSubDataFn(GLenum readTarget,
                                     GLenum writeTarget,
                                     GLintptr readOffset,
                                     GLintptr writeOffset,
                                     GLsizeiptr size) = 0;
  virtual void glCopyTexImage2DFn(GLenum target,
                                  GLint level,
                                  GLenum internalformat,
                                  GLint x,
                                  GLint y,
                                  GLsizei width,
                                  GLsizei height,
                                  GLint border) = 0;
  virtual void glCopyTexSubImage2DFn(GLenum target,
                                     GLint level,
                                     GLint xoffset,
                                     GLint yoffset,
                                     GLint x,
                                     GLint y,
                                     GLsizei width,
                                     GLsizei height) = 0;
  virtual void glCopyTexSubImage3DFn(GLenum target,
                                     GLint level,
                                     GLint xoffset,
                                     GLint yoffset,
                                     GLint zoffset,
                                     GLint x,
                                     GLint y,
                                     GLsizei width,
                                     GLsizei height) = 0;
  virtual GLuint glCreateProgramFn(void) = 0;
  virtual GLuint glCreateShaderFn(GLenum type) = 0;
  virtual void glCullFaceFn(GLenum mode) = 0;
  virtual void glDeleteBuffersARBFn(GLsizei n, const GLuint* buffers) = 0;
  virtual void glDeleteFencesAPPLEFn(GLsizei n, const GLuint* fences) = 0;
  virtual void glDeleteFencesNVFn(GLsizei n, const GLuint* fences) = 0;
  virtual void glDeleteFramebuffersEXTFn(GLsizei n,
                                         const GLuint* framebuffers) = 0;
  virtual void glDeleteProgramFn(GLuint program) = 0;
  virtual void glDeleteQueriesFn(GLsizei n, const GLuint* ids) = 0;
  virtual void glDeleteRenderbuffersEXTFn(GLsizei n,
                                          const GLuint* renderbuffers) = 0;
  virtual void glDeleteSamplersFn(GLsizei n, const GLuint* samplers) = 0;
  virtual void glDeleteShaderFn(GLuint shader) = 0;
  virtual void glDeleteSyncFn(GLsync sync) = 0;
  virtual void glDeleteTexturesFn(GLsizei n, const GLuint* textures) = 0;
  virtual void glDeleteTransformFeedbacksFn(GLsizei n, const GLuint* ids) = 0;
  virtual void glDeleteVertexArraysOESFn(GLsizei n, const GLuint* arrays) = 0;
  virtual void glDepthFuncFn(GLenum func) = 0;
  virtual void glDepthMaskFn(GLboolean flag) = 0;
  virtual void glDepthRangeFn(GLclampd zNear, GLclampd zFar) = 0;
  virtual void glDepthRangefFn(GLclampf zNear, GLclampf zFar) = 0;
  virtual void glDetachShaderFn(GLuint program, GLuint shader) = 0;
  virtual void glDisableFn(GLenum cap) = 0;
  virtual void glDisableVertexAttribArrayFn(GLuint index) = 0;
  virtual void glDiscardFramebufferEXTFn(GLenum target,
                                         GLsizei numAttachments,
                                         const GLenum* attachments) = 0;
  virtual void glDrawArraysFn(GLenum mode, GLint first, GLsizei count) = 0;
  virtual void glDrawArraysInstancedANGLEFn(GLenum mode,
                                            GLint first,
                                            GLsizei count,
                                            GLsizei primcount) = 0;
  virtual void glDrawBufferFn(GLenum mode) = 0;
  virtual void glDrawBuffersARBFn(GLsizei n, const GLenum* bufs) = 0;
  virtual void glDrawElementsFn(GLenum mode,
                                GLsizei count,
                                GLenum type,
                                const void* indices) = 0;
  virtual void glDrawElementsInstancedANGLEFn(GLenum mode,
                                              GLsizei count,
                                              GLenum type,
                                              const void* indices,
                                              GLsizei primcount) = 0;
  virtual void glDrawRangeElementsFn(GLenum mode,
                                     GLuint start,
                                     GLuint end,
                                     GLsizei count,
                                     GLenum type,
                                     const void* indices) = 0;
  virtual void glEGLImageTargetRenderbufferStorageOESFn(
      GLenum target,
      GLeglImageOES image) = 0;
  virtual void glEGLImageTargetTexture2DOESFn(GLenum target,
                                              GLeglImageOES image) = 0;
  virtual void glEnableFn(GLenum cap) = 0;
  virtual void glEnableVertexAttribArrayFn(GLuint index) = 0;
  virtual void glEndQueryFn(GLenum target) = 0;
  virtual void glEndTransformFeedbackFn(void) = 0;
  virtual GLsync glFenceSyncFn(GLenum condition, GLbitfield flags) = 0;
  virtual void glFinishFn(void) = 0;
  virtual void glFinishFenceAPPLEFn(GLuint fence) = 0;
  virtual void glFinishFenceNVFn(GLuint fence) = 0;
  virtual void glFlushFn(void) = 0;
  virtual void glFlushMappedBufferRangeFn(GLenum target,
                                          GLintptr offset,
                                          GLsizeiptr length) = 0;
  virtual void glFramebufferRenderbufferEXTFn(GLenum target,
                                              GLenum attachment,
                                              GLenum renderbuffertarget,
                                              GLuint renderbuffer) = 0;
  virtual void glFramebufferTexture2DEXTFn(GLenum target,
                                           GLenum attachment,
                                           GLenum textarget,
                                           GLuint texture,
                                           GLint level) = 0;
  virtual void glFramebufferTexture2DMultisampleEXTFn(GLenum target,
                                                      GLenum attachment,
                                                      GLenum textarget,
                                                      GLuint texture,
                                                      GLint level,
                                                      GLsizei samples) = 0;
  virtual void glFramebufferTexture2DMultisampleIMGFn(GLenum target,
                                                      GLenum attachment,
                                                      GLenum textarget,
                                                      GLuint texture,
                                                      GLint level,
                                                      GLsizei samples) = 0;
  virtual void glFramebufferTextureLayerFn(GLenum target,
                                           GLenum attachment,
                                           GLuint texture,
                                           GLint level,
                                           GLint layer) = 0;
  virtual void glFrontFaceFn(GLenum mode) = 0;
  virtual void glGenBuffersARBFn(GLsizei n, GLuint* buffers) = 0;
  virtual void glGenerateMipmapEXTFn(GLenum target) = 0;
  virtual void glGenFencesAPPLEFn(GLsizei n, GLuint* fences) = 0;
  virtual void glGenFencesNVFn(GLsizei n, GLuint* fences) = 0;
  virtual void glGenFramebuffersEXTFn(GLsizei n, GLuint* framebuffers) = 0;
  virtual void glGenQueriesFn(GLsizei n, GLuint* ids) = 0;
  virtual void glGenRenderbuffersEXTFn(GLsizei n, GLuint* renderbuffers) = 0;
  virtual void glGenSamplersFn(GLsizei n, GLuint* samplers) = 0;
  virtual void glGenTexturesFn(GLsizei n, GLuint* textures) = 0;
  virtual void glGenTransformFeedbacksFn(GLsizei n, GLuint* ids) = 0;
  virtual void glGenVertexArraysOESFn(GLsizei n, GLuint* arrays) = 0;
  virtual void glGetActiveAttribFn(GLuint program,
                                   GLuint index,
                                   GLsizei bufsize,
                                   GLsizei* length,
                                   GLint* size,
                                   GLenum* type,
                                   char* name) = 0;
  virtual void glGetActiveUniformFn(GLuint program,
                                    GLuint index,
                                    GLsizei bufsize,
                                    GLsizei* length,
                                    GLint* size,
                                    GLenum* type,
                                    char* name) = 0;
  virtual void glGetActiveUniformBlockivFn(GLuint program,
                                           GLuint uniformBlockIndex,
                                           GLenum pname,
                                           GLint* params) = 0;
  virtual void glGetActiveUniformBlockNameFn(GLuint program,
                                             GLuint uniformBlockIndex,
                                             GLsizei bufSize,
                                             GLsizei* length,
                                             char* uniformBlockName) = 0;
  virtual void glGetActiveUniformsivFn(GLuint program,
                                       GLsizei uniformCount,
                                       const GLuint* uniformIndices,
                                       GLenum pname,
                                       GLint* params) = 0;
  virtual void glGetAttachedShadersFn(GLuint program,
                                      GLsizei maxcount,
                                      GLsizei* count,
                                      GLuint* shaders) = 0;
  virtual GLint glGetAttribLocationFn(GLuint program, const char* name) = 0;
  virtual void glGetBooleanvFn(GLenum pname, GLboolean* params) = 0;
  virtual void glGetBufferParameterivFn(GLenum target,
                                        GLenum pname,
                                        GLint* params) = 0;
  virtual GLenum glGetErrorFn(void) = 0;
  virtual void glGetFenceivNVFn(GLuint fence, GLenum pname, GLint* params) = 0;
  virtual void glGetFloatvFn(GLenum pname, GLfloat* params) = 0;
  virtual GLint glGetFragDataLocationFn(GLuint program, const char* name) = 0;
  virtual void glGetFramebufferAttachmentParameterivEXTFn(GLenum target,
                                                          GLenum attachment,
                                                          GLenum pname,
                                                          GLint* params) = 0;
  virtual GLenum glGetGraphicsResetStatusARBFn(void) = 0;
  virtual void glGetInteger64i_vFn(GLenum target,
                                   GLuint index,
                                   GLint64* data) = 0;
  virtual void glGetInteger64vFn(GLenum pname, GLint64* params) = 0;
  virtual void glGetIntegeri_vFn(GLenum target, GLuint index, GLint* data) = 0;
  virtual void glGetIntegervFn(GLenum pname, GLint* params) = 0;
  virtual void glGetInternalformativFn(GLenum target,
                                       GLenum internalformat,
                                       GLenum pname,
                                       GLsizei bufSize,
                                       GLint* params) = 0;
  virtual void glGetProgramBinaryFn(GLuint program,
                                    GLsizei bufSize,
                                    GLsizei* length,
                                    GLenum* binaryFormat,
                                    GLvoid* binary) = 0;
  virtual void glGetProgramInfoLogFn(GLuint program,
                                     GLsizei bufsize,
                                     GLsizei* length,
                                     char* infolog) = 0;
  virtual void glGetProgramivFn(GLuint program,
                                GLenum pname,
                                GLint* params) = 0;
  virtual GLint glGetProgramResourceLocationFn(GLuint program,
                                               GLenum programInterface,
                                               const char* name) = 0;
  virtual void glGetQueryivFn(GLenum target, GLenum pname, GLint* params) = 0;
  virtual void glGetQueryObjecti64vFn(GLuint id,
                                      GLenum pname,
                                      GLint64* params) = 0;
  virtual void glGetQueryObjectivFn(GLuint id, GLenum pname, GLint* params) = 0;
  virtual void glGetQueryObjectui64vFn(GLuint id,
                                       GLenum pname,
                                       GLuint64* params) = 0;
  virtual void glGetQueryObjectuivFn(GLuint id,
                                     GLenum pname,
                                     GLuint* params) = 0;
  virtual void glGetRenderbufferParameterivEXTFn(GLenum target,
                                                 GLenum pname,
                                                 GLint* params) = 0;
  virtual void glGetSamplerParameterfvFn(GLuint sampler,
                                         GLenum pname,
                                         GLfloat* params) = 0;
  virtual void glGetSamplerParameterivFn(GLuint sampler,
                                         GLenum pname,
                                         GLint* params) = 0;
  virtual void glGetShaderInfoLogFn(GLuint shader,
                                    GLsizei bufsize,
                                    GLsizei* length,
                                    char* infolog) = 0;
  virtual void glGetShaderivFn(GLuint shader, GLenum pname, GLint* params) = 0;
  virtual void glGetShaderPrecisionFormatFn(GLenum shadertype,
                                            GLenum precisiontype,
                                            GLint* range,
                                            GLint* precision) = 0;
  virtual void glGetShaderSourceFn(GLuint shader,
                                   GLsizei bufsize,
                                   GLsizei* length,
                                   char* source) = 0;
  virtual const GLubyte* glGetStringFn(GLenum name) = 0;
  virtual const GLubyte* glGetStringiFn(GLenum name, GLuint index) = 0;
  virtual void glGetSyncivFn(GLsync sync,
                             GLenum pname,
                             GLsizei bufSize,
                             GLsizei* length,
                             GLint* values) = 0;
  virtual void glGetTexLevelParameterfvFn(GLenum target,
                                          GLint level,
                                          GLenum pname,
                                          GLfloat* params) = 0;
  virtual void glGetTexLevelParameterivFn(GLenum target,
                                          GLint level,
                                          GLenum pname,
                                          GLint* params) = 0;
  virtual void glGetTexParameterfvFn(GLenum target,
                                     GLenum pname,
                                     GLfloat* params) = 0;
  virtual void glGetTexParameterivFn(GLenum target,
                                     GLenum pname,
                                     GLint* params) = 0;
  virtual void glGetTransformFeedbackVaryingFn(GLuint program,
                                               GLuint index,
                                               GLsizei bufSize,
                                               GLsizei* length,
                                               GLsizei* size,
                                               GLenum* type,
                                               char* name) = 0;
  virtual void glGetTranslatedShaderSourceANGLEFn(GLuint shader,
                                                  GLsizei bufsize,
                                                  GLsizei* length,
                                                  char* source) = 0;
  virtual GLuint glGetUniformBlockIndexFn(GLuint program,
                                          const char* uniformBlockName) = 0;
  virtual void glGetUniformfvFn(GLuint program,
                                GLint location,
                                GLfloat* params) = 0;
  virtual void glGetUniformIndicesFn(GLuint program,
                                     GLsizei uniformCount,
                                     const char* const* uniformNames,
                                     GLuint* uniformIndices) = 0;
  virtual void glGetUniformivFn(GLuint program,
                                GLint location,
                                GLint* params) = 0;
  virtual GLint glGetUniformLocationFn(GLuint program, const char* name) = 0;
  virtual void glGetVertexAttribfvFn(GLuint index,
                                     GLenum pname,
                                     GLfloat* params) = 0;
  virtual void glGetVertexAttribivFn(GLuint index,
                                     GLenum pname,
                                     GLint* params) = 0;
  virtual void glGetVertexAttribPointervFn(GLuint index,
                                           GLenum pname,
                                           void** pointer) = 0;
  virtual void glHintFn(GLenum target, GLenum mode) = 0;
  virtual void glInsertEventMarkerEXTFn(GLsizei length, const char* marker) = 0;
  virtual void glInvalidateFramebufferFn(GLenum target,
                                         GLsizei numAttachments,
                                         const GLenum* attachments) = 0;
  virtual void glInvalidateSubFramebufferFn(GLenum target,
                                            GLsizei numAttachments,
                                            const GLenum* attachments,
                                            GLint x,
                                            GLint y,
                                            GLint width,
                                            GLint height) = 0;
  virtual GLboolean glIsBufferFn(GLuint buffer) = 0;
  virtual GLboolean glIsEnabledFn(GLenum cap) = 0;
  virtual GLboolean glIsFenceAPPLEFn(GLuint fence) = 0;
  virtual GLboolean glIsFenceNVFn(GLuint fence) = 0;
  virtual GLboolean glIsFramebufferEXTFn(GLuint framebuffer) = 0;
  virtual GLboolean glIsProgramFn(GLuint program) = 0;
  virtual GLboolean glIsQueryFn(GLuint query) = 0;
  virtual GLboolean glIsRenderbufferEXTFn(GLuint renderbuffer) = 0;
  virtual GLboolean glIsSamplerFn(GLuint sampler) = 0;
  virtual GLboolean glIsShaderFn(GLuint shader) = 0;
  virtual GLboolean glIsSyncFn(GLsync sync) = 0;
  virtual GLboolean glIsTextureFn(GLuint texture) = 0;
  virtual GLboolean glIsTransformFeedbackFn(GLuint id) = 0;
  virtual GLboolean glIsVertexArrayOESFn(GLuint array) = 0;
  virtual void glLineWidthFn(GLfloat width) = 0;
  virtual void glLinkProgramFn(GLuint program) = 0;
  virtual void* glMapBufferFn(GLenum target, GLenum access) = 0;
  virtual void* glMapBufferRangeFn(GLenum target,
                                   GLintptr offset,
                                   GLsizeiptr length,
                                   GLbitfield access) = 0;
  virtual void glMatrixLoadfEXTFn(GLenum matrixMode, const GLfloat* m) = 0;
  virtual void glMatrixLoadIdentityEXTFn(GLenum matrixMode) = 0;
  virtual void glPauseTransformFeedbackFn(void) = 0;
  virtual void glPixelStoreiFn(GLenum pname, GLint param) = 0;
  virtual void glPointParameteriFn(GLenum pname, GLint param) = 0;
  virtual void glPolygonOffsetFn(GLfloat factor, GLfloat units) = 0;
  virtual void glPopGroupMarkerEXTFn(void) = 0;
  virtual void glProgramBinaryFn(GLuint program,
                                 GLenum binaryFormat,
                                 const GLvoid* binary,
                                 GLsizei length) = 0;
  virtual void glProgramParameteriFn(GLuint program,
                                     GLenum pname,
                                     GLint value) = 0;
  virtual void glPushGroupMarkerEXTFn(GLsizei length, const char* marker) = 0;
  virtual void glQueryCounterFn(GLuint id, GLenum target) = 0;
  virtual void glReadBufferFn(GLenum src) = 0;
  virtual void glReadPixelsFn(GLint x,
                              GLint y,
                              GLsizei width,
                              GLsizei height,
                              GLenum format,
                              GLenum type,
                              void* pixels) = 0;
  virtual void glReleaseShaderCompilerFn(void) = 0;
  virtual void glRenderbufferStorageEXTFn(GLenum target,
                                          GLenum internalformat,
                                          GLsizei width,
                                          GLsizei height) = 0;
  virtual void glRenderbufferStorageMultisampleFn(GLenum target,
                                                  GLsizei samples,
                                                  GLenum internalformat,
                                                  GLsizei width,
                                                  GLsizei height) = 0;
  virtual void glRenderbufferStorageMultisampleANGLEFn(GLenum target,
                                                       GLsizei samples,
                                                       GLenum internalformat,
                                                       GLsizei width,
                                                       GLsizei height) = 0;
  virtual void glRenderbufferStorageMultisampleAPPLEFn(GLenum target,
                                                       GLsizei samples,
                                                       GLenum internalformat,
                                                       GLsizei width,
                                                       GLsizei height) = 0;
  virtual void glRenderbufferStorageMultisampleEXTFn(GLenum target,
                                                     GLsizei samples,
                                                     GLenum internalformat,
                                                     GLsizei width,
                                                     GLsizei height) = 0;
  virtual void glRenderbufferStorageMultisampleIMGFn(GLenum target,
                                                     GLsizei samples,
                                                     GLenum internalformat,
                                                     GLsizei width,
                                                     GLsizei height) = 0;
  virtual void glResolveMultisampleFramebufferAPPLEFn(void) = 0;
  virtual void glResumeTransformFeedbackFn(void) = 0;
  virtual void glSampleCoverageFn(GLclampf value, GLboolean invert) = 0;
  virtual void glSamplerParameterfFn(GLuint sampler,
                                     GLenum pname,
                                     GLfloat param) = 0;
  virtual void glSamplerParameterfvFn(GLuint sampler,
                                      GLenum pname,
                                      const GLfloat* params) = 0;
  virtual void glSamplerParameteriFn(GLuint sampler,
                                     GLenum pname,
                                     GLint param) = 0;
  virtual void glSamplerParameterivFn(GLuint sampler,
                                      GLenum pname,
                                      const GLint* params) = 0;
  virtual void glScissorFn(GLint x, GLint y, GLsizei width, GLsizei height) = 0;
  virtual void glSetFenceAPPLEFn(GLuint fence) = 0;
  virtual void glSetFenceNVFn(GLuint fence, GLenum condition) = 0;
  virtual void glShaderBinaryFn(GLsizei n,
                                const GLuint* shaders,
                                GLenum binaryformat,
                                const void* binary,
                                GLsizei length) = 0;
  virtual void glShaderSourceFn(GLuint shader,
                                GLsizei count,
                                const char* const* str,
                                const GLint* length) = 0;
  virtual void glStencilFuncFn(GLenum func, GLint ref, GLuint mask) = 0;
  virtual void glStencilFuncSeparateFn(GLenum face,
                                       GLenum func,
                                       GLint ref,
                                       GLuint mask) = 0;
  virtual void glStencilMaskFn(GLuint mask) = 0;
  virtual void glStencilMaskSeparateFn(GLenum face, GLuint mask) = 0;
  virtual void glStencilOpFn(GLenum fail, GLenum zfail, GLenum zpass) = 0;
  virtual void glStencilOpSeparateFn(GLenum face,
                                     GLenum fail,
                                     GLenum zfail,
                                     GLenum zpass) = 0;
  virtual GLboolean glTestFenceAPPLEFn(GLuint fence) = 0;
  virtual GLboolean glTestFenceNVFn(GLuint fence) = 0;
  virtual void glTexImage2DFn(GLenum target,
                              GLint level,
                              GLint internalformat,
                              GLsizei width,
                              GLsizei height,
                              GLint border,
                              GLenum format,
                              GLenum type,
                              const void* pixels) = 0;
  virtual void glTexImage3DFn(GLenum target,
                              GLint level,
                              GLint internalformat,
                              GLsizei width,
                              GLsizei height,
                              GLsizei depth,
                              GLint border,
                              GLenum format,
                              GLenum type,
                              const void* pixels) = 0;
  virtual void glTexParameterfFn(GLenum target,
                                 GLenum pname,
                                 GLfloat param) = 0;
  virtual void glTexParameterfvFn(GLenum target,
                                  GLenum pname,
                                  const GLfloat* params) = 0;
  virtual void glTexParameteriFn(GLenum target, GLenum pname, GLint param) = 0;
  virtual void glTexParameterivFn(GLenum target,
                                  GLenum pname,
                                  const GLint* params) = 0;
  virtual void glTexStorage2DEXTFn(GLenum target,
                                   GLsizei levels,
                                   GLenum internalformat,
                                   GLsizei width,
                                   GLsizei height) = 0;
  virtual void glTexStorage3DFn(GLenum target,
                                GLsizei levels,
                                GLenum internalformat,
                                GLsizei width,
                                GLsizei height,
                                GLsizei depth) = 0;
  virtual void glTexSubImage2DFn(GLenum target,
                                 GLint level,
                                 GLint xoffset,
                                 GLint yoffset,
                                 GLsizei width,
                                 GLsizei height,
                                 GLenum format,
                                 GLenum type,
                                 const void* pixels) = 0;
  virtual void glTransformFeedbackVaryingsFn(GLuint program,
                                             GLsizei count,
                                             const char* const* varyings,
                                             GLenum bufferMode) = 0;
  virtual void glUniform1fFn(GLint location, GLfloat x) = 0;
  virtual void glUniform1fvFn(GLint location,
                              GLsizei count,
                              const GLfloat* v) = 0;
  virtual void glUniform1iFn(GLint location, GLint x) = 0;
  virtual void glUniform1ivFn(GLint location,
                              GLsizei count,
                              const GLint* v) = 0;
  virtual void glUniform1uiFn(GLint location, GLuint v0) = 0;
  virtual void glUniform1uivFn(GLint location,
                               GLsizei count,
                               const GLuint* v) = 0;
  virtual void glUniform2fFn(GLint location, GLfloat x, GLfloat y) = 0;
  virtual void glUniform2fvFn(GLint location,
                              GLsizei count,
                              const GLfloat* v) = 0;
  virtual void glUniform2iFn(GLint location, GLint x, GLint y) = 0;
  virtual void glUniform2ivFn(GLint location,
                              GLsizei count,
                              const GLint* v) = 0;
  virtual void glUniform2uiFn(GLint location, GLuint v0, GLuint v1) = 0;
  virtual void glUniform2uivFn(GLint location,
                               GLsizei count,
                               const GLuint* v) = 0;
  virtual void glUniform3fFn(GLint location,
                             GLfloat x,
                             GLfloat y,
                             GLfloat z) = 0;
  virtual void glUniform3fvFn(GLint location,
                              GLsizei count,
                              const GLfloat* v) = 0;
  virtual void glUniform3iFn(GLint location, GLint x, GLint y, GLint z) = 0;
  virtual void glUniform3ivFn(GLint location,
                              GLsizei count,
                              const GLint* v) = 0;
  virtual void glUniform3uiFn(GLint location,
                              GLuint v0,
                              GLuint v1,
                              GLuint v2) = 0;
  virtual void glUniform3uivFn(GLint location,
                               GLsizei count,
                               const GLuint* v) = 0;
  virtual void glUniform4fFn(GLint location,
                             GLfloat x,
                             GLfloat y,
                             GLfloat z,
                             GLfloat w) = 0;
  virtual void glUniform4fvFn(GLint location,
                              GLsizei count,
                              const GLfloat* v) = 0;
  virtual void glUniform4iFn(GLint location,
                             GLint x,
                             GLint y,
                             GLint z,
                             GLint w) = 0;
  virtual void glUniform4ivFn(GLint location,
                              GLsizei count,
                              const GLint* v) = 0;
  virtual void glUniform4uiFn(GLint location,
                              GLuint v0,
                              GLuint v1,
                              GLuint v2,
                              GLuint v3) = 0;
  virtual void glUniform4uivFn(GLint location,
                               GLsizei count,
                               const GLuint* v) = 0;
  virtual void glUniformBlockBindingFn(GLuint program,
                                       GLuint uniformBlockIndex,
                                       GLuint uniformBlockBinding) = 0;
  virtual void glUniformMatrix2fvFn(GLint location,
                                    GLsizei count,
                                    GLboolean transpose,
                                    const GLfloat* value) = 0;
  virtual void glUniformMatrix2x3fvFn(GLint location,
                                      GLsizei count,
                                      GLboolean transpose,
                                      const GLfloat* value) = 0;
  virtual void glUniformMatrix2x4fvFn(GLint location,
                                      GLsizei count,
                                      GLboolean transpose,
                                      const GLfloat* value) = 0;
  virtual void glUniformMatrix3fvFn(GLint location,
                                    GLsizei count,
                                    GLboolean transpose,
                                    const GLfloat* value) = 0;
  virtual void glUniformMatrix3x2fvFn(GLint location,
                                      GLsizei count,
                                      GLboolean transpose,
                                      const GLfloat* value) = 0;
  virtual void glUniformMatrix3x4fvFn(GLint location,
                                      GLsizei count,
                                      GLboolean transpose,
                                      const GLfloat* value) = 0;
  virtual void glUniformMatrix4fvFn(GLint location,
                                    GLsizei count,
                                    GLboolean transpose,
                                    const GLfloat* value) = 0;
  virtual void glUniformMatrix4x2fvFn(GLint location,
                                      GLsizei count,
                                      GLboolean transpose,
                                      const GLfloat* value) = 0;
  virtual void glUniformMatrix4x3fvFn(GLint location,
                                      GLsizei count,
                                      GLboolean transpose,
                                      const GLfloat* value) = 0;
  virtual GLboolean glUnmapBufferFn(GLenum target) = 0;
  virtual void glUseProgramFn(GLuint program) = 0;
  virtual void glValidateProgramFn(GLuint program) = 0;
  virtual void glVertexAttrib1fFn(GLuint indx, GLfloat x) = 0;
  virtual void glVertexAttrib1fvFn(GLuint indx, const GLfloat* values) = 0;
  virtual void glVertexAttrib2fFn(GLuint indx, GLfloat x, GLfloat y) = 0;
  virtual void glVertexAttrib2fvFn(GLuint indx, const GLfloat* values) = 0;
  virtual void glVertexAttrib3fFn(GLuint indx,
                                  GLfloat x,
                                  GLfloat y,
                                  GLfloat z) = 0;
  virtual void glVertexAttrib3fvFn(GLuint indx, const GLfloat* values) = 0;
  virtual void glVertexAttrib4fFn(GLuint indx,
                                  GLfloat x,
                                  GLfloat y,
                                  GLfloat z,
                                  GLfloat w) = 0;
  virtual void glVertexAttrib4fvFn(GLuint indx, const GLfloat* values) = 0;
  virtual void glVertexAttribDivisorANGLEFn(GLuint index, GLuint divisor) = 0;
  virtual void glVertexAttribI4iFn(GLuint indx,
                                   GLint x,
                                   GLint y,
                                   GLint z,
                                   GLint w) = 0;
  virtual void glVertexAttribI4ivFn(GLuint indx, const GLint* values) = 0;
  virtual void glVertexAttribI4uiFn(GLuint indx,
                                    GLuint x,
                                    GLuint y,
                                    GLuint z,
                                    GLuint w) = 0;
  virtual void glVertexAttribI4uivFn(GLuint indx, const GLuint* values) = 0;
  virtual void glVertexAttribIPointerFn(GLuint indx,
                                        GLint size,
                                        GLenum type,
                                        GLsizei stride,
                                        const void* ptr) = 0;
  virtual void glVertexAttribPointerFn(GLuint indx,
                                       GLint size,
                                       GLenum type,
                                       GLboolean normalized,
                                       GLsizei stride,
                                       const void* ptr) = 0;
  virtual void glViewportFn(GLint x,
                            GLint y,
                            GLsizei width,
                            GLsizei height) = 0;
  virtual GLenum glWaitSyncFn(GLsync sync,
                              GLbitfield flags,
                              GLuint64 timeout) = 0;
};

}  // namespace gfx

#define glActiveTexture ::gfx::g_current_gl_context->glActiveTextureFn
#define glAttachShader ::gfx::g_current_gl_context->glAttachShaderFn
#define glBeginQuery ::gfx::g_current_gl_context->glBeginQueryFn
#define glBeginTransformFeedback \
  ::gfx::g_current_gl_context->glBeginTransformFeedbackFn
#define glBindAttribLocation ::gfx::g_current_gl_context->glBindAttribLocationFn
#define glBindBuffer ::gfx::g_current_gl_context->glBindBufferFn
#define glBindBufferBase ::gfx::g_current_gl_context->glBindBufferBaseFn
#define glBindBufferRange ::gfx::g_current_gl_context->glBindBufferRangeFn
#define glBindFragDataLocation \
  ::gfx::g_current_gl_context->glBindFragDataLocationFn
#define glBindFragDataLocationIndexed \
  ::gfx::g_current_gl_context->glBindFragDataLocationIndexedFn
#define glBindFramebufferEXT ::gfx::g_current_gl_context->glBindFramebufferEXTFn
#define glBindRenderbufferEXT \
  ::gfx::g_current_gl_context->glBindRenderbufferEXTFn
#define glBindSampler ::gfx::g_current_gl_context->glBindSamplerFn
#define glBindTexture ::gfx::g_current_gl_context->glBindTextureFn
#define glBindTransformFeedback \
  ::gfx::g_current_gl_context->glBindTransformFeedbackFn
#define glBindVertexArrayOES ::gfx::g_current_gl_context->glBindVertexArrayOESFn
#define glBlendBarrierKHR ::gfx::g_current_gl_context->glBlendBarrierKHRFn
#define glBlendColor ::gfx::g_current_gl_context->glBlendColorFn
#define glBlendEquation ::gfx::g_current_gl_context->glBlendEquationFn
#define glBlendEquationSeparate \
  ::gfx::g_current_gl_context->glBlendEquationSeparateFn
#define glBlendFunc ::gfx::g_current_gl_context->glBlendFuncFn
#define glBlendFuncSeparate ::gfx::g_current_gl_context->glBlendFuncSeparateFn
#define glBlitFramebuffer ::gfx::g_current_gl_context->glBlitFramebufferFn
#define glBlitFramebufferANGLE \
  ::gfx::g_current_gl_context->glBlitFramebufferANGLEFn
#define glBlitFramebufferEXT ::gfx::g_current_gl_context->glBlitFramebufferEXTFn
#define glBufferData ::gfx::g_current_gl_context->glBufferDataFn
#define glBufferSubData ::gfx::g_current_gl_context->glBufferSubDataFn
#define glCheckFramebufferStatusEXT \
  ::gfx::g_current_gl_context->glCheckFramebufferStatusEXTFn
#define glClear ::gfx::g_current_gl_context->glClearFn
#define glClearBufferfi ::gfx::g_current_gl_context->glClearBufferfiFn
#define glClearBufferfv ::gfx::g_current_gl_context->glClearBufferfvFn
#define glClearBufferiv ::gfx::g_current_gl_context->glClearBufferivFn
#define glClearBufferuiv ::gfx::g_current_gl_context->glClearBufferuivFn
#define glClearColor ::gfx::g_current_gl_context->glClearColorFn
#define glClearDepth ::gfx::g_current_gl_context->glClearDepthFn
#define glClearDepthf ::gfx::g_current_gl_context->glClearDepthfFn
#define glClearStencil ::gfx::g_current_gl_context->glClearStencilFn
#define glClientWaitSync ::gfx::g_current_gl_context->glClientWaitSyncFn
#define glColorMask ::gfx::g_current_gl_context->glColorMaskFn
#define glCompileShader ::gfx::g_current_gl_context->glCompileShaderFn
#define glCompressedTexImage2D \
  ::gfx::g_current_gl_context->glCompressedTexImage2DFn
#define glCompressedTexImage3D \
  ::gfx::g_current_gl_context->glCompressedTexImage3DFn
#define glCompressedTexSubImage2D \
  ::gfx::g_current_gl_context->glCompressedTexSubImage2DFn
#define glCopyBufferSubData ::gfx::g_current_gl_context->glCopyBufferSubDataFn
#define glCopyTexImage2D ::gfx::g_current_gl_context->glCopyTexImage2DFn
#define glCopyTexSubImage2D ::gfx::g_current_gl_context->glCopyTexSubImage2DFn
#define glCopyTexSubImage3D ::gfx::g_current_gl_context->glCopyTexSubImage3DFn
#define glCreateProgram ::gfx::g_current_gl_context->glCreateProgramFn
#define glCreateShader ::gfx::g_current_gl_context->glCreateShaderFn
#define glCullFace ::gfx::g_current_gl_context->glCullFaceFn
#define glDeleteBuffersARB ::gfx::g_current_gl_context->glDeleteBuffersARBFn
#define glDeleteFencesAPPLE ::gfx::g_current_gl_context->glDeleteFencesAPPLEFn
#define glDeleteFencesNV ::gfx::g_current_gl_context->glDeleteFencesNVFn
#define glDeleteFramebuffersEXT \
  ::gfx::g_current_gl_context->glDeleteFramebuffersEXTFn
#define glDeleteProgram ::gfx::g_current_gl_context->glDeleteProgramFn
#define glDeleteQueries ::gfx::g_current_gl_context->glDeleteQueriesFn
#define glDeleteRenderbuffersEXT \
  ::gfx::g_current_gl_context->glDeleteRenderbuffersEXTFn
#define glDeleteSamplers ::gfx::g_current_gl_context->glDeleteSamplersFn
#define glDeleteShader ::gfx::g_current_gl_context->glDeleteShaderFn
#define glDeleteSync ::gfx::g_current_gl_context->glDeleteSyncFn
#define glDeleteTextures ::gfx::g_current_gl_context->glDeleteTexturesFn
#define glDeleteTransformFeedbacks \
  ::gfx::g_current_gl_context->glDeleteTransformFeedbacksFn
#define glDeleteVertexArraysOES \
  ::gfx::g_current_gl_context->glDeleteVertexArraysOESFn
#define glDepthFunc ::gfx::g_current_gl_context->glDepthFuncFn
#define glDepthMask ::gfx::g_current_gl_context->glDepthMaskFn
#define glDepthRange ::gfx::g_current_gl_context->glDepthRangeFn
#define glDepthRangef ::gfx::g_current_gl_context->glDepthRangefFn
#define glDetachShader ::gfx::g_current_gl_context->glDetachShaderFn
#define glDisable ::gfx::g_current_gl_context->glDisableFn
#define glDisableVertexAttribArray \
  ::gfx::g_current_gl_context->glDisableVertexAttribArrayFn
#define glDiscardFramebufferEXT \
  ::gfx::g_current_gl_context->glDiscardFramebufferEXTFn
#define glDrawArrays ::gfx::g_current_gl_context->glDrawArraysFn
#define glDrawArraysInstancedANGLE \
  ::gfx::g_current_gl_context->glDrawArraysInstancedANGLEFn
#define glDrawBuffer ::gfx::g_current_gl_context->glDrawBufferFn
#define glDrawBuffersARB ::gfx::g_current_gl_context->glDrawBuffersARBFn
#define glDrawElements ::gfx::g_current_gl_context->glDrawElementsFn
#define glDrawElementsInstancedANGLE \
  ::gfx::g_current_gl_context->glDrawElementsInstancedANGLEFn
#define glDrawRangeElements ::gfx::g_current_gl_context->glDrawRangeElementsFn
#define glEGLImageTargetRenderbufferStorageOES \
  ::gfx::g_current_gl_context->glEGLImageTargetRenderbufferStorageOESFn
#define glEGLImageTargetTexture2DOES \
  ::gfx::g_current_gl_context->glEGLImageTargetTexture2DOESFn
#define glEnable ::gfx::g_current_gl_context->glEnableFn
#define glEnableVertexAttribArray \
  ::gfx::g_current_gl_context->glEnableVertexAttribArrayFn
#define glEndQuery ::gfx::g_current_gl_context->glEndQueryFn
#define glEndTransformFeedback \
  ::gfx::g_current_gl_context->glEndTransformFeedbackFn
#define glFenceSync ::gfx::g_current_gl_context->glFenceSyncFn
#define glFinish ::gfx::g_current_gl_context->glFinishFn
#define glFinishFenceAPPLE ::gfx::g_current_gl_context->glFinishFenceAPPLEFn
#define glFinishFenceNV ::gfx::g_current_gl_context->glFinishFenceNVFn
#define glFlush ::gfx::g_current_gl_context->glFlushFn
#define glFlushMappedBufferRange \
  ::gfx::g_current_gl_context->glFlushMappedBufferRangeFn
#define glFramebufferRenderbufferEXT \
  ::gfx::g_current_gl_context->glFramebufferRenderbufferEXTFn
#define glFramebufferTexture2DEXT \
  ::gfx::g_current_gl_context->glFramebufferTexture2DEXTFn
#define glFramebufferTexture2DMultisampleEXT \
  ::gfx::g_current_gl_context->glFramebufferTexture2DMultisampleEXTFn
#define glFramebufferTexture2DMultisampleIMG \
  ::gfx::g_current_gl_context->glFramebufferTexture2DMultisampleIMGFn
#define glFramebufferTextureLayer \
  ::gfx::g_current_gl_context->glFramebufferTextureLayerFn
#define glFrontFace ::gfx::g_current_gl_context->glFrontFaceFn
#define glGenBuffersARB ::gfx::g_current_gl_context->glGenBuffersARBFn
#define glGenerateMipmapEXT ::gfx::g_current_gl_context->glGenerateMipmapEXTFn
#define glGenFencesAPPLE ::gfx::g_current_gl_context->glGenFencesAPPLEFn
#define glGenFencesNV ::gfx::g_current_gl_context->glGenFencesNVFn
#define glGenFramebuffersEXT ::gfx::g_current_gl_context->glGenFramebuffersEXTFn
#define glGenQueries ::gfx::g_current_gl_context->glGenQueriesFn
#define glGenRenderbuffersEXT \
  ::gfx::g_current_gl_context->glGenRenderbuffersEXTFn
#define glGenSamplers ::gfx::g_current_gl_context->glGenSamplersFn
#define glGenTextures ::gfx::g_current_gl_context->glGenTexturesFn
#define glGenTransformFeedbacks \
  ::gfx::g_current_gl_context->glGenTransformFeedbacksFn
#define glGenVertexArraysOES ::gfx::g_current_gl_context->glGenVertexArraysOESFn
#define glGetActiveAttrib ::gfx::g_current_gl_context->glGetActiveAttribFn
#define glGetActiveUniform ::gfx::g_current_gl_context->glGetActiveUniformFn
#define glGetActiveUniformBlockiv \
  ::gfx::g_current_gl_context->glGetActiveUniformBlockivFn
#define glGetActiveUniformBlockName \
  ::gfx::g_current_gl_context->glGetActiveUniformBlockNameFn
#define glGetActiveUniformsiv \
  ::gfx::g_current_gl_context->glGetActiveUniformsivFn
#define glGetAttachedShaders ::gfx::g_current_gl_context->glGetAttachedShadersFn
#define glGetAttribLocation ::gfx::g_current_gl_context->glGetAttribLocationFn
#define glGetBooleanv ::gfx::g_current_gl_context->glGetBooleanvFn
#define glGetBufferParameteriv \
  ::gfx::g_current_gl_context->glGetBufferParameterivFn
#define glGetError ::gfx::g_current_gl_context->glGetErrorFn
#define glGetFenceivNV ::gfx::g_current_gl_context->glGetFenceivNVFn
#define glGetFloatv ::gfx::g_current_gl_context->glGetFloatvFn
#define glGetFragDataLocation \
  ::gfx::g_current_gl_context->glGetFragDataLocationFn
#define glGetFramebufferAttachmentParameterivEXT \
  ::gfx::g_current_gl_context->glGetFramebufferAttachmentParameterivEXTFn
#define glGetGraphicsResetStatusARB \
  ::gfx::g_current_gl_context->glGetGraphicsResetStatusARBFn
#define glGetInteger64i_v ::gfx::g_current_gl_context->glGetInteger64i_vFn
#define glGetInteger64v ::gfx::g_current_gl_context->glGetInteger64vFn
#define glGetIntegeri_v ::gfx::g_current_gl_context->glGetIntegeri_vFn
#define glGetIntegerv ::gfx::g_current_gl_context->glGetIntegervFn
#define glGetInternalformativ \
  ::gfx::g_current_gl_context->glGetInternalformativFn
#define glGetProgramBinary ::gfx::g_current_gl_context->glGetProgramBinaryFn
#define glGetProgramInfoLog ::gfx::g_current_gl_context->glGetProgramInfoLogFn
#define glGetProgramiv ::gfx::g_current_gl_context->glGetProgramivFn
#define glGetProgramResourceLocation \
  ::gfx::g_current_gl_context->glGetProgramResourceLocationFn
#define glGetQueryiv ::gfx::g_current_gl_context->glGetQueryivFn
#define glGetQueryObjecti64v ::gfx::g_current_gl_context->glGetQueryObjecti64vFn
#define glGetQueryObjectiv ::gfx::g_current_gl_context->glGetQueryObjectivFn
#define glGetQueryObjectui64v \
  ::gfx::g_current_gl_context->glGetQueryObjectui64vFn
#define glGetQueryObjectuiv ::gfx::g_current_gl_context->glGetQueryObjectuivFn
#define glGetRenderbufferParameterivEXT \
  ::gfx::g_current_gl_context->glGetRenderbufferParameterivEXTFn
#define glGetSamplerParameterfv \
  ::gfx::g_current_gl_context->glGetSamplerParameterfvFn
#define glGetSamplerParameteriv \
  ::gfx::g_current_gl_context->glGetSamplerParameterivFn
#define glGetShaderInfoLog ::gfx::g_current_gl_context->glGetShaderInfoLogFn
#define glGetShaderiv ::gfx::g_current_gl_context->glGetShaderivFn
#define glGetShaderPrecisionFormat \
  ::gfx::g_current_gl_context->glGetShaderPrecisionFormatFn
#define glGetShaderSource ::gfx::g_current_gl_context->glGetShaderSourceFn
#define glGetString ::gfx::g_current_gl_context->glGetStringFn
#define glGetStringi ::gfx::g_current_gl_context->glGetStringiFn
#define glGetSynciv ::gfx::g_current_gl_context->glGetSyncivFn
#define glGetTexLevelParameterfv \
  ::gfx::g_current_gl_context->glGetTexLevelParameterfvFn
#define glGetTexLevelParameteriv \
  ::gfx::g_current_gl_context->glGetTexLevelParameterivFn
#define glGetTexParameterfv ::gfx::g_current_gl_context->glGetTexParameterfvFn
#define glGetTexParameteriv ::gfx::g_current_gl_context->glGetTexParameterivFn
#define glGetTransformFeedbackVarying \
  ::gfx::g_current_gl_context->glGetTransformFeedbackVaryingFn
#define glGetTranslatedShaderSourceANGLE \
  ::gfx::g_current_gl_context->glGetTranslatedShaderSourceANGLEFn
#define glGetUniformBlockIndex \
  ::gfx::g_current_gl_context->glGetUniformBlockIndexFn
#define glGetUniformfv ::gfx::g_current_gl_context->glGetUniformfvFn
#define glGetUniformIndices ::gfx::g_current_gl_context->glGetUniformIndicesFn
#define glGetUniformiv ::gfx::g_current_gl_context->glGetUniformivFn
#define glGetUniformLocation ::gfx::g_current_gl_context->glGetUniformLocationFn
#define glGetVertexAttribfv ::gfx::g_current_gl_context->glGetVertexAttribfvFn
#define glGetVertexAttribiv ::gfx::g_current_gl_context->glGetVertexAttribivFn
#define glGetVertexAttribPointerv \
  ::gfx::g_current_gl_context->glGetVertexAttribPointervFn
#define glHint ::gfx::g_current_gl_context->glHintFn
#define glInsertEventMarkerEXT \
  ::gfx::g_current_gl_context->glInsertEventMarkerEXTFn
#define glInvalidateFramebuffer \
  ::gfx::g_current_gl_context->glInvalidateFramebufferFn
#define glInvalidateSubFramebuffer \
  ::gfx::g_current_gl_context->glInvalidateSubFramebufferFn
#define glIsBuffer ::gfx::g_current_gl_context->glIsBufferFn
#define glIsEnabled ::gfx::g_current_gl_context->glIsEnabledFn
#define glIsFenceAPPLE ::gfx::g_current_gl_context->glIsFenceAPPLEFn
#define glIsFenceNV ::gfx::g_current_gl_context->glIsFenceNVFn
#define glIsFramebufferEXT ::gfx::g_current_gl_context->glIsFramebufferEXTFn
#define glIsProgram ::gfx::g_current_gl_context->glIsProgramFn
#define glIsQuery ::gfx::g_current_gl_context->glIsQueryFn
#define glIsRenderbufferEXT ::gfx::g_current_gl_context->glIsRenderbufferEXTFn
#define glIsSampler ::gfx::g_current_gl_context->glIsSamplerFn
#define glIsShader ::gfx::g_current_gl_context->glIsShaderFn
#define glIsSync ::gfx::g_current_gl_context->glIsSyncFn
#define glIsTexture ::gfx::g_current_gl_context->glIsTextureFn
#define glIsTransformFeedback \
  ::gfx::g_current_gl_context->glIsTransformFeedbackFn
#define glIsVertexArrayOES ::gfx::g_current_gl_context->glIsVertexArrayOESFn
#define glLineWidth ::gfx::g_current_gl_context->glLineWidthFn
#define glLinkProgram ::gfx::g_current_gl_context->glLinkProgramFn
#define glMapBuffer ::gfx::g_current_gl_context->glMapBufferFn
#define glMapBufferRange ::gfx::g_current_gl_context->glMapBufferRangeFn
#define glMatrixLoadfEXT ::gfx::g_current_gl_context->glMatrixLoadfEXTFn
#define glMatrixLoadIdentityEXT \
  ::gfx::g_current_gl_context->glMatrixLoadIdentityEXTFn
#define glPauseTransformFeedback \
  ::gfx::g_current_gl_context->glPauseTransformFeedbackFn
#define glPixelStorei ::gfx::g_current_gl_context->glPixelStoreiFn
#define glPointParameteri ::gfx::g_current_gl_context->glPointParameteriFn
#define glPolygonOffset ::gfx::g_current_gl_context->glPolygonOffsetFn
#define glPopGroupMarkerEXT ::gfx::g_current_gl_context->glPopGroupMarkerEXTFn
#define glProgramBinary ::gfx::g_current_gl_context->glProgramBinaryFn
#define glProgramParameteri ::gfx::g_current_gl_context->glProgramParameteriFn
#define glPushGroupMarkerEXT ::gfx::g_current_gl_context->glPushGroupMarkerEXTFn
#define glQueryCounter ::gfx::g_current_gl_context->glQueryCounterFn
#define glReadBuffer ::gfx::g_current_gl_context->glReadBufferFn
#define glReadPixels ::gfx::g_current_gl_context->glReadPixelsFn
#define glReleaseShaderCompiler \
  ::gfx::g_current_gl_context->glReleaseShaderCompilerFn
#define glRenderbufferStorageEXT \
  ::gfx::g_current_gl_context->glRenderbufferStorageEXTFn
#define glRenderbufferStorageMultisample \
  ::gfx::g_current_gl_context->glRenderbufferStorageMultisampleFn
#define glRenderbufferStorageMultisampleANGLE \
  ::gfx::g_current_gl_context->glRenderbufferStorageMultisampleANGLEFn
#define glRenderbufferStorageMultisampleAPPLE \
  ::gfx::g_current_gl_context->glRenderbufferStorageMultisampleAPPLEFn
#define glRenderbufferStorageMultisampleEXT \
  ::gfx::g_current_gl_context->glRenderbufferStorageMultisampleEXTFn
#define glRenderbufferStorageMultisampleIMG \
  ::gfx::g_current_gl_context->glRenderbufferStorageMultisampleIMGFn
#define glResolveMultisampleFramebufferAPPLE \
  ::gfx::g_current_gl_context->glResolveMultisampleFramebufferAPPLEFn
#define glResumeTransformFeedback \
  ::gfx::g_current_gl_context->glResumeTransformFeedbackFn
#define glSampleCoverage ::gfx::g_current_gl_context->glSampleCoverageFn
#define glSamplerParameterf ::gfx::g_current_gl_context->glSamplerParameterfFn
#define glSamplerParameterfv ::gfx::g_current_gl_context->glSamplerParameterfvFn
#define glSamplerParameteri ::gfx::g_current_gl_context->glSamplerParameteriFn
#define glSamplerParameteriv ::gfx::g_current_gl_context->glSamplerParameterivFn
#define glScissor ::gfx::g_current_gl_context->glScissorFn
#define glSetFenceAPPLE ::gfx::g_current_gl_context->glSetFenceAPPLEFn
#define glSetFenceNV ::gfx::g_current_gl_context->glSetFenceNVFn
#define glShaderBinary ::gfx::g_current_gl_context->glShaderBinaryFn
#define glShaderSource ::gfx::g_current_gl_context->glShaderSourceFn
#define glStencilFunc ::gfx::g_current_gl_context->glStencilFuncFn
#define glStencilFuncSeparate \
  ::gfx::g_current_gl_context->glStencilFuncSeparateFn
#define glStencilMask ::gfx::g_current_gl_context->glStencilMaskFn
#define glStencilMaskSeparate \
  ::gfx::g_current_gl_context->glStencilMaskSeparateFn
#define glStencilOp ::gfx::g_current_gl_context->glStencilOpFn
#define glStencilOpSeparate ::gfx::g_current_gl_context->glStencilOpSeparateFn
#define glTestFenceAPPLE ::gfx::g_current_gl_context->glTestFenceAPPLEFn
#define glTestFenceNV ::gfx::g_current_gl_context->glTestFenceNVFn
#define glTexImage2D ::gfx::g_current_gl_context->glTexImage2DFn
#define glTexImage3D ::gfx::g_current_gl_context->glTexImage3DFn
#define glTexParameterf ::gfx::g_current_gl_context->glTexParameterfFn
#define glTexParameterfv ::gfx::g_current_gl_context->glTexParameterfvFn
#define glTexParameteri ::gfx::g_current_gl_context->glTexParameteriFn
#define glTexParameteriv ::gfx::g_current_gl_context->glTexParameterivFn
#define glTexStorage2DEXT ::gfx::g_current_gl_context->glTexStorage2DEXTFn
#define glTexStorage3D ::gfx::g_current_gl_context->glTexStorage3DFn
#define glTexSubImage2D ::gfx::g_current_gl_context->glTexSubImage2DFn
#define glTransformFeedbackVaryings \
  ::gfx::g_current_gl_context->glTransformFeedbackVaryingsFn
#define glUniform1f ::gfx::g_current_gl_context->glUniform1fFn
#define glUniform1fv ::gfx::g_current_gl_context->glUniform1fvFn
#define glUniform1i ::gfx::g_current_gl_context->glUniform1iFn
#define glUniform1iv ::gfx::g_current_gl_context->glUniform1ivFn
#define glUniform1ui ::gfx::g_current_gl_context->glUniform1uiFn
#define glUniform1uiv ::gfx::g_current_gl_context->glUniform1uivFn
#define glUniform2f ::gfx::g_current_gl_context->glUniform2fFn
#define glUniform2fv ::gfx::g_current_gl_context->glUniform2fvFn
#define glUniform2i ::gfx::g_current_gl_context->glUniform2iFn
#define glUniform2iv ::gfx::g_current_gl_context->glUniform2ivFn
#define glUniform2ui ::gfx::g_current_gl_context->glUniform2uiFn
#define glUniform2uiv ::gfx::g_current_gl_context->glUniform2uivFn
#define glUniform3f ::gfx::g_current_gl_context->glUniform3fFn
#define glUniform3fv ::gfx::g_current_gl_context->glUniform3fvFn
#define glUniform3i ::gfx::g_current_gl_context->glUniform3iFn
#define glUniform3iv ::gfx::g_current_gl_context->glUniform3ivFn
#define glUniform3ui ::gfx::g_current_gl_context->glUniform3uiFn
#define glUniform3uiv ::gfx::g_current_gl_context->glUniform3uivFn
#define glUniform4f ::gfx::g_current_gl_context->glUniform4fFn
#define glUniform4fv ::gfx::g_current_gl_context->glUniform4fvFn
#define glUniform4i ::gfx::g_current_gl_context->glUniform4iFn
#define glUniform4iv ::gfx::g_current_gl_context->glUniform4ivFn
#define glUniform4ui ::gfx::g_current_gl_context->glUniform4uiFn
#define glUniform4uiv ::gfx::g_current_gl_context->glUniform4uivFn
#define glUniformBlockBinding \
  ::gfx::g_current_gl_context->glUniformBlockBindingFn
#define glUniformMatrix2fv ::gfx::g_current_gl_context->glUniformMatrix2fvFn
#define glUniformMatrix2x3fv ::gfx::g_current_gl_context->glUniformMatrix2x3fvFn
#define glUniformMatrix2x4fv ::gfx::g_current_gl_context->glUniformMatrix2x4fvFn
#define glUniformMatrix3fv ::gfx::g_current_gl_context->glUniformMatrix3fvFn
#define glUniformMatrix3x2fv ::gfx::g_current_gl_context->glUniformMatrix3x2fvFn
#define glUniformMatrix3x4fv ::gfx::g_current_gl_context->glUniformMatrix3x4fvFn
#define glUniformMatrix4fv ::gfx::g_current_gl_context->glUniformMatrix4fvFn
#define glUniformMatrix4x2fv ::gfx::g_current_gl_context->glUniformMatrix4x2fvFn
#define glUniformMatrix4x3fv ::gfx::g_current_gl_context->glUniformMatrix4x3fvFn
#define glUnmapBuffer ::gfx::g_current_gl_context->glUnmapBufferFn
#define glUseProgram ::gfx::g_current_gl_context->glUseProgramFn
#define glValidateProgram ::gfx::g_current_gl_context->glValidateProgramFn
#define glVertexAttrib1f ::gfx::g_current_gl_context->glVertexAttrib1fFn
#define glVertexAttrib1fv ::gfx::g_current_gl_context->glVertexAttrib1fvFn
#define glVertexAttrib2f ::gfx::g_current_gl_context->glVertexAttrib2fFn
#define glVertexAttrib2fv ::gfx::g_current_gl_context->glVertexAttrib2fvFn
#define glVertexAttrib3f ::gfx::g_current_gl_context->glVertexAttrib3fFn
#define glVertexAttrib3fv ::gfx::g_current_gl_context->glVertexAttrib3fvFn
#define glVertexAttrib4f ::gfx::g_current_gl_context->glVertexAttrib4fFn
#define glVertexAttrib4fv ::gfx::g_current_gl_context->glVertexAttrib4fvFn
#define glVertexAttribDivisorANGLE \
  ::gfx::g_current_gl_context->glVertexAttribDivisorANGLEFn
#define glVertexAttribI4i ::gfx::g_current_gl_context->glVertexAttribI4iFn
#define glVertexAttribI4iv ::gfx::g_current_gl_context->glVertexAttribI4ivFn
#define glVertexAttribI4ui ::gfx::g_current_gl_context->glVertexAttribI4uiFn
#define glVertexAttribI4uiv ::gfx::g_current_gl_context->glVertexAttribI4uivFn
#define glVertexAttribIPointer \
  ::gfx::g_current_gl_context->glVertexAttribIPointerFn
#define glVertexAttribPointer \
  ::gfx::g_current_gl_context->glVertexAttribPointerFn
#define glViewport ::gfx::g_current_gl_context->glViewportFn
#define glWaitSync ::gfx::g_current_gl_context->glWaitSyncFn

#endif  //  UI_GFX_GL_GL_BINDINGS_AUTOGEN_GL_H_
