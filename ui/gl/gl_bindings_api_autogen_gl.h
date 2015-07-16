// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is auto-generated from
// ui/gl/generate_bindings.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

void glActiveTextureFn(GLenum texture) override;
void glAttachShaderFn(GLuint program, GLuint shader) override;
void glBeginQueryFn(GLenum target, GLuint id) override;
void glBeginTransformFeedbackFn(GLenum primitiveMode) override;
void glBindAttribLocationFn(GLuint program,
                            GLuint index,
                            const char* name) override;
void glBindBufferFn(GLenum target, GLuint buffer) override;
void glBindBufferBaseFn(GLenum target, GLuint index, GLuint buffer) override;
void glBindBufferRangeFn(GLenum target,
                         GLuint index,
                         GLuint buffer,
                         GLintptr offset,
                         GLsizeiptr size) override;
void glBindFragDataLocationFn(GLuint program,
                              GLuint colorNumber,
                              const char* name) override;
void glBindFragDataLocationIndexedFn(GLuint program,
                                     GLuint colorNumber,
                                     GLuint index,
                                     const char* name) override;
void glBindFramebufferEXTFn(GLenum target, GLuint framebuffer) override;
void glBindRenderbufferEXTFn(GLenum target, GLuint renderbuffer) override;
void glBindSamplerFn(GLuint unit, GLuint sampler) override;
void glBindTextureFn(GLenum target, GLuint texture) override;
void glBindTransformFeedbackFn(GLenum target, GLuint id) override;
void glBindVertexArrayOESFn(GLuint array) override;
void glBlendBarrierKHRFn(void) override;
void glBlendColorFn(GLclampf red,
                    GLclampf green,
                    GLclampf blue,
                    GLclampf alpha) override;
void glBlendEquationFn(GLenum mode) override;
void glBlendEquationSeparateFn(GLenum modeRGB, GLenum modeAlpha) override;
void glBlendFuncFn(GLenum sfactor, GLenum dfactor) override;
void glBlendFuncSeparateFn(GLenum srcRGB,
                           GLenum dstRGB,
                           GLenum srcAlpha,
                           GLenum dstAlpha) override;
void glBlitFramebufferFn(GLint srcX0,
                         GLint srcY0,
                         GLint srcX1,
                         GLint srcY1,
                         GLint dstX0,
                         GLint dstY0,
                         GLint dstX1,
                         GLint dstY1,
                         GLbitfield mask,
                         GLenum filter) override;
void glBlitFramebufferANGLEFn(GLint srcX0,
                              GLint srcY0,
                              GLint srcX1,
                              GLint srcY1,
                              GLint dstX0,
                              GLint dstY0,
                              GLint dstX1,
                              GLint dstY1,
                              GLbitfield mask,
                              GLenum filter) override;
void glBlitFramebufferEXTFn(GLint srcX0,
                            GLint srcY0,
                            GLint srcX1,
                            GLint srcY1,
                            GLint dstX0,
                            GLint dstY0,
                            GLint dstX1,
                            GLint dstY1,
                            GLbitfield mask,
                            GLenum filter) override;
void glBufferDataFn(GLenum target,
                    GLsizeiptr size,
                    const void* data,
                    GLenum usage) override;
void glBufferSubDataFn(GLenum target,
                       GLintptr offset,
                       GLsizeiptr size,
                       const void* data) override;
GLenum glCheckFramebufferStatusEXTFn(GLenum target) override;
void glClearFn(GLbitfield mask) override;
void glClearBufferfiFn(GLenum buffer,
                       GLint drawbuffer,
                       const GLfloat depth,
                       GLint stencil) override;
void glClearBufferfvFn(GLenum buffer,
                       GLint drawbuffer,
                       const GLfloat* value) override;
void glClearBufferivFn(GLenum buffer,
                       GLint drawbuffer,
                       const GLint* value) override;
void glClearBufferuivFn(GLenum buffer,
                        GLint drawbuffer,
                        const GLuint* value) override;
void glClearColorFn(GLclampf red,
                    GLclampf green,
                    GLclampf blue,
                    GLclampf alpha) override;
void glClearDepthFn(GLclampd depth) override;
void glClearDepthfFn(GLclampf depth) override;
void glClearStencilFn(GLint s) override;
GLenum glClientWaitSyncFn(GLsync sync,
                          GLbitfield flags,
                          GLuint64 timeout) override;
void glColorMaskFn(GLboolean red,
                   GLboolean green,
                   GLboolean blue,
                   GLboolean alpha) override;
void glCompileShaderFn(GLuint shader) override;
void glCompressedTexImage2DFn(GLenum target,
                              GLint level,
                              GLenum internalformat,
                              GLsizei width,
                              GLsizei height,
                              GLint border,
                              GLsizei imageSize,
                              const void* data) override;
void glCompressedTexImage3DFn(GLenum target,
                              GLint level,
                              GLenum internalformat,
                              GLsizei width,
                              GLsizei height,
                              GLsizei depth,
                              GLint border,
                              GLsizei imageSize,
                              const void* data) override;
void glCompressedTexSubImage2DFn(GLenum target,
                                 GLint level,
                                 GLint xoffset,
                                 GLint yoffset,
                                 GLsizei width,
                                 GLsizei height,
                                 GLenum format,
                                 GLsizei imageSize,
                                 const void* data) override;
void glCopyBufferSubDataFn(GLenum readTarget,
                           GLenum writeTarget,
                           GLintptr readOffset,
                           GLintptr writeOffset,
                           GLsizeiptr size) override;
void glCopyTexImage2DFn(GLenum target,
                        GLint level,
                        GLenum internalformat,
                        GLint x,
                        GLint y,
                        GLsizei width,
                        GLsizei height,
                        GLint border) override;
void glCopyTexSubImage2DFn(GLenum target,
                           GLint level,
                           GLint xoffset,
                           GLint yoffset,
                           GLint x,
                           GLint y,
                           GLsizei width,
                           GLsizei height) override;
void glCopyTexSubImage3DFn(GLenum target,
                           GLint level,
                           GLint xoffset,
                           GLint yoffset,
                           GLint zoffset,
                           GLint x,
                           GLint y,
                           GLsizei width,
                           GLsizei height) override;
GLuint glCreateProgramFn(void) override;
GLuint glCreateShaderFn(GLenum type) override;
void glCullFaceFn(GLenum mode) override;
void glDeleteBuffersARBFn(GLsizei n, const GLuint* buffers) override;
void glDeleteFencesAPPLEFn(GLsizei n, const GLuint* fences) override;
void glDeleteFencesNVFn(GLsizei n, const GLuint* fences) override;
void glDeleteFramebuffersEXTFn(GLsizei n, const GLuint* framebuffers) override;
void glDeleteProgramFn(GLuint program) override;
void glDeleteQueriesFn(GLsizei n, const GLuint* ids) override;
void glDeleteRenderbuffersEXTFn(GLsizei n,
                                const GLuint* renderbuffers) override;
void glDeleteSamplersFn(GLsizei n, const GLuint* samplers) override;
void glDeleteShaderFn(GLuint shader) override;
void glDeleteSyncFn(GLsync sync) override;
void glDeleteTexturesFn(GLsizei n, const GLuint* textures) override;
void glDeleteTransformFeedbacksFn(GLsizei n, const GLuint* ids) override;
void glDeleteVertexArraysOESFn(GLsizei n, const GLuint* arrays) override;
void glDepthFuncFn(GLenum func) override;
void glDepthMaskFn(GLboolean flag) override;
void glDepthRangeFn(GLclampd zNear, GLclampd zFar) override;
void glDepthRangefFn(GLclampf zNear, GLclampf zFar) override;
void glDetachShaderFn(GLuint program, GLuint shader) override;
void glDisableFn(GLenum cap) override;
void glDisableVertexAttribArrayFn(GLuint index) override;
void glDiscardFramebufferEXTFn(GLenum target,
                               GLsizei numAttachments,
                               const GLenum* attachments) override;
void glDrawArraysFn(GLenum mode, GLint first, GLsizei count) override;
void glDrawArraysInstancedANGLEFn(GLenum mode,
                                  GLint first,
                                  GLsizei count,
                                  GLsizei primcount) override;
void glDrawBufferFn(GLenum mode) override;
void glDrawBuffersARBFn(GLsizei n, const GLenum* bufs) override;
void glDrawElementsFn(GLenum mode,
                      GLsizei count,
                      GLenum type,
                      const void* indices) override;
void glDrawElementsInstancedANGLEFn(GLenum mode,
                                    GLsizei count,
                                    GLenum type,
                                    const void* indices,
                                    GLsizei primcount) override;
void glDrawRangeElementsFn(GLenum mode,
                           GLuint start,
                           GLuint end,
                           GLsizei count,
                           GLenum type,
                           const void* indices) override;
void glEGLImageTargetRenderbufferStorageOESFn(GLenum target,
                                              GLeglImageOES image) override;
void glEGLImageTargetTexture2DOESFn(GLenum target,
                                    GLeglImageOES image) override;
void glEnableFn(GLenum cap) override;
void glEnableVertexAttribArrayFn(GLuint index) override;
void glEndQueryFn(GLenum target) override;
void glEndTransformFeedbackFn(void) override;
GLsync glFenceSyncFn(GLenum condition, GLbitfield flags) override;
void glFinishFn(void) override;
void glFinishFenceAPPLEFn(GLuint fence) override;
void glFinishFenceNVFn(GLuint fence) override;
void glFlushFn(void) override;
void glFlushMappedBufferRangeFn(GLenum target,
                                GLintptr offset,
                                GLsizeiptr length) override;
void glFramebufferRenderbufferEXTFn(GLenum target,
                                    GLenum attachment,
                                    GLenum renderbuffertarget,
                                    GLuint renderbuffer) override;
void glFramebufferTexture2DEXTFn(GLenum target,
                                 GLenum attachment,
                                 GLenum textarget,
                                 GLuint texture,
                                 GLint level) override;
void glFramebufferTexture2DMultisampleEXTFn(GLenum target,
                                            GLenum attachment,
                                            GLenum textarget,
                                            GLuint texture,
                                            GLint level,
                                            GLsizei samples) override;
void glFramebufferTexture2DMultisampleIMGFn(GLenum target,
                                            GLenum attachment,
                                            GLenum textarget,
                                            GLuint texture,
                                            GLint level,
                                            GLsizei samples) override;
void glFramebufferTextureLayerFn(GLenum target,
                                 GLenum attachment,
                                 GLuint texture,
                                 GLint level,
                                 GLint layer) override;
void glFrontFaceFn(GLenum mode) override;
void glGenBuffersARBFn(GLsizei n, GLuint* buffers) override;
void glGenerateMipmapEXTFn(GLenum target) override;
void glGenFencesAPPLEFn(GLsizei n, GLuint* fences) override;
void glGenFencesNVFn(GLsizei n, GLuint* fences) override;
void glGenFramebuffersEXTFn(GLsizei n, GLuint* framebuffers) override;
void glGenQueriesFn(GLsizei n, GLuint* ids) override;
void glGenRenderbuffersEXTFn(GLsizei n, GLuint* renderbuffers) override;
void glGenSamplersFn(GLsizei n, GLuint* samplers) override;
void glGenTexturesFn(GLsizei n, GLuint* textures) override;
void glGenTransformFeedbacksFn(GLsizei n, GLuint* ids) override;
void glGenVertexArraysOESFn(GLsizei n, GLuint* arrays) override;
void glGetActiveAttribFn(GLuint program,
                         GLuint index,
                         GLsizei bufsize,
                         GLsizei* length,
                         GLint* size,
                         GLenum* type,
                         char* name) override;
void glGetActiveUniformFn(GLuint program,
                          GLuint index,
                          GLsizei bufsize,
                          GLsizei* length,
                          GLint* size,
                          GLenum* type,
                          char* name) override;
void glGetActiveUniformBlockivFn(GLuint program,
                                 GLuint uniformBlockIndex,
                                 GLenum pname,
                                 GLint* params) override;
void glGetActiveUniformBlockNameFn(GLuint program,
                                   GLuint uniformBlockIndex,
                                   GLsizei bufSize,
                                   GLsizei* length,
                                   char* uniformBlockName) override;
void glGetActiveUniformsivFn(GLuint program,
                             GLsizei uniformCount,
                             const GLuint* uniformIndices,
                             GLenum pname,
                             GLint* params) override;
void glGetAttachedShadersFn(GLuint program,
                            GLsizei maxcount,
                            GLsizei* count,
                            GLuint* shaders) override;
GLint glGetAttribLocationFn(GLuint program, const char* name) override;
void glGetBooleanvFn(GLenum pname, GLboolean* params) override;
void glGetBufferParameterivFn(GLenum target,
                              GLenum pname,
                              GLint* params) override;
GLenum glGetErrorFn(void) override;
void glGetFenceivNVFn(GLuint fence, GLenum pname, GLint* params) override;
void glGetFloatvFn(GLenum pname, GLfloat* params) override;
GLint glGetFragDataLocationFn(GLuint program, const char* name) override;
void glGetFramebufferAttachmentParameterivEXTFn(GLenum target,
                                                GLenum attachment,
                                                GLenum pname,
                                                GLint* params) override;
GLenum glGetGraphicsResetStatusARBFn(void) override;
void glGetInteger64i_vFn(GLenum target, GLuint index, GLint64* data) override;
void glGetInteger64vFn(GLenum pname, GLint64* params) override;
void glGetIntegeri_vFn(GLenum target, GLuint index, GLint* data) override;
void glGetIntegervFn(GLenum pname, GLint* params) override;
void glGetInternalformativFn(GLenum target,
                             GLenum internalformat,
                             GLenum pname,
                             GLsizei bufSize,
                             GLint* params) override;
void glGetProgramBinaryFn(GLuint program,
                          GLsizei bufSize,
                          GLsizei* length,
                          GLenum* binaryFormat,
                          GLvoid* binary) override;
void glGetProgramInfoLogFn(GLuint program,
                           GLsizei bufsize,
                           GLsizei* length,
                           char* infolog) override;
void glGetProgramivFn(GLuint program, GLenum pname, GLint* params) override;
GLint glGetProgramResourceLocationFn(GLuint program,
                                     GLenum programInterface,
                                     const char* name) override;
void glGetQueryivFn(GLenum target, GLenum pname, GLint* params) override;
void glGetQueryObjecti64vFn(GLuint id, GLenum pname, GLint64* params) override;
void glGetQueryObjectivFn(GLuint id, GLenum pname, GLint* params) override;
void glGetQueryObjectui64vFn(GLuint id,
                             GLenum pname,
                             GLuint64* params) override;
void glGetQueryObjectuivFn(GLuint id, GLenum pname, GLuint* params) override;
void glGetRenderbufferParameterivEXTFn(GLenum target,
                                       GLenum pname,
                                       GLint* params) override;
void glGetSamplerParameterfvFn(GLuint sampler,
                               GLenum pname,
                               GLfloat* params) override;
void glGetSamplerParameterivFn(GLuint sampler,
                               GLenum pname,
                               GLint* params) override;
void glGetShaderInfoLogFn(GLuint shader,
                          GLsizei bufsize,
                          GLsizei* length,
                          char* infolog) override;
void glGetShaderivFn(GLuint shader, GLenum pname, GLint* params) override;
void glGetShaderPrecisionFormatFn(GLenum shadertype,
                                  GLenum precisiontype,
                                  GLint* range,
                                  GLint* precision) override;
void glGetShaderSourceFn(GLuint shader,
                         GLsizei bufsize,
                         GLsizei* length,
                         char* source) override;
const GLubyte* glGetStringFn(GLenum name) override;
const GLubyte* glGetStringiFn(GLenum name, GLuint index) override;
void glGetSyncivFn(GLsync sync,
                   GLenum pname,
                   GLsizei bufSize,
                   GLsizei* length,
                   GLint* values) override;
void glGetTexLevelParameterfvFn(GLenum target,
                                GLint level,
                                GLenum pname,
                                GLfloat* params) override;
void glGetTexLevelParameterivFn(GLenum target,
                                GLint level,
                                GLenum pname,
                                GLint* params) override;
void glGetTexParameterfvFn(GLenum target,
                           GLenum pname,
                           GLfloat* params) override;
void glGetTexParameterivFn(GLenum target, GLenum pname, GLint* params) override;
void glGetTransformFeedbackVaryingFn(GLuint program,
                                     GLuint index,
                                     GLsizei bufSize,
                                     GLsizei* length,
                                     GLsizei* size,
                                     GLenum* type,
                                     char* name) override;
void glGetTranslatedShaderSourceANGLEFn(GLuint shader,
                                        GLsizei bufsize,
                                        GLsizei* length,
                                        char* source) override;
GLuint glGetUniformBlockIndexFn(GLuint program,
                                const char* uniformBlockName) override;
void glGetUniformfvFn(GLuint program, GLint location, GLfloat* params) override;
void glGetUniformIndicesFn(GLuint program,
                           GLsizei uniformCount,
                           const char* const* uniformNames,
                           GLuint* uniformIndices) override;
void glGetUniformivFn(GLuint program, GLint location, GLint* params) override;
GLint glGetUniformLocationFn(GLuint program, const char* name) override;
void glGetVertexAttribfvFn(GLuint index,
                           GLenum pname,
                           GLfloat* params) override;
void glGetVertexAttribivFn(GLuint index, GLenum pname, GLint* params) override;
void glGetVertexAttribPointervFn(GLuint index,
                                 GLenum pname,
                                 void** pointer) override;
void glHintFn(GLenum target, GLenum mode) override;
void glInsertEventMarkerEXTFn(GLsizei length, const char* marker) override;
void glInvalidateFramebufferFn(GLenum target,
                               GLsizei numAttachments,
                               const GLenum* attachments) override;
void glInvalidateSubFramebufferFn(GLenum target,
                                  GLsizei numAttachments,
                                  const GLenum* attachments,
                                  GLint x,
                                  GLint y,
                                  GLint width,
                                  GLint height) override;
GLboolean glIsBufferFn(GLuint buffer) override;
GLboolean glIsEnabledFn(GLenum cap) override;
GLboolean glIsFenceAPPLEFn(GLuint fence) override;
GLboolean glIsFenceNVFn(GLuint fence) override;
GLboolean glIsFramebufferEXTFn(GLuint framebuffer) override;
GLboolean glIsProgramFn(GLuint program) override;
GLboolean glIsQueryFn(GLuint query) override;
GLboolean glIsRenderbufferEXTFn(GLuint renderbuffer) override;
GLboolean glIsSamplerFn(GLuint sampler) override;
GLboolean glIsShaderFn(GLuint shader) override;
GLboolean glIsSyncFn(GLsync sync) override;
GLboolean glIsTextureFn(GLuint texture) override;
GLboolean glIsTransformFeedbackFn(GLuint id) override;
GLboolean glIsVertexArrayOESFn(GLuint array) override;
void glLineWidthFn(GLfloat width) override;
void glLinkProgramFn(GLuint program) override;
void* glMapBufferFn(GLenum target, GLenum access) override;
void* glMapBufferRangeFn(GLenum target,
                         GLintptr offset,
                         GLsizeiptr length,
                         GLbitfield access) override;
void glMatrixLoadfEXTFn(GLenum matrixMode, const GLfloat* m) override;
void glMatrixLoadIdentityEXTFn(GLenum matrixMode) override;
void glPauseTransformFeedbackFn(void) override;
void glPixelStoreiFn(GLenum pname, GLint param) override;
void glPointParameteriFn(GLenum pname, GLint param) override;
void glPolygonOffsetFn(GLfloat factor, GLfloat units) override;
void glPopGroupMarkerEXTFn(void) override;
void glProgramBinaryFn(GLuint program,
                       GLenum binaryFormat,
                       const GLvoid* binary,
                       GLsizei length) override;
void glProgramParameteriFn(GLuint program, GLenum pname, GLint value) override;
void glPushGroupMarkerEXTFn(GLsizei length, const char* marker) override;
void glQueryCounterFn(GLuint id, GLenum target) override;
void glReadBufferFn(GLenum src) override;
void glReadPixelsFn(GLint x,
                    GLint y,
                    GLsizei width,
                    GLsizei height,
                    GLenum format,
                    GLenum type,
                    void* pixels) override;
void glReleaseShaderCompilerFn(void) override;
void glRenderbufferStorageEXTFn(GLenum target,
                                GLenum internalformat,
                                GLsizei width,
                                GLsizei height) override;
void glRenderbufferStorageMultisampleFn(GLenum target,
                                        GLsizei samples,
                                        GLenum internalformat,
                                        GLsizei width,
                                        GLsizei height) override;
void glRenderbufferStorageMultisampleANGLEFn(GLenum target,
                                             GLsizei samples,
                                             GLenum internalformat,
                                             GLsizei width,
                                             GLsizei height) override;
void glRenderbufferStorageMultisampleAPPLEFn(GLenum target,
                                             GLsizei samples,
                                             GLenum internalformat,
                                             GLsizei width,
                                             GLsizei height) override;
void glRenderbufferStorageMultisampleEXTFn(GLenum target,
                                           GLsizei samples,
                                           GLenum internalformat,
                                           GLsizei width,
                                           GLsizei height) override;
void glRenderbufferStorageMultisampleIMGFn(GLenum target,
                                           GLsizei samples,
                                           GLenum internalformat,
                                           GLsizei width,
                                           GLsizei height) override;
void glResolveMultisampleFramebufferAPPLEFn(void) override;
void glResumeTransformFeedbackFn(void) override;
void glSampleCoverageFn(GLclampf value, GLboolean invert) override;
void glSamplerParameterfFn(GLuint sampler,
                           GLenum pname,
                           GLfloat param) override;
void glSamplerParameterfvFn(GLuint sampler,
                            GLenum pname,
                            const GLfloat* params) override;
void glSamplerParameteriFn(GLuint sampler, GLenum pname, GLint param) override;
void glSamplerParameterivFn(GLuint sampler,
                            GLenum pname,
                            const GLint* params) override;
void glScissorFn(GLint x, GLint y, GLsizei width, GLsizei height) override;
void glSetFenceAPPLEFn(GLuint fence) override;
void glSetFenceNVFn(GLuint fence, GLenum condition) override;
void glShaderBinaryFn(GLsizei n,
                      const GLuint* shaders,
                      GLenum binaryformat,
                      const void* binary,
                      GLsizei length) override;
void glShaderSourceFn(GLuint shader,
                      GLsizei count,
                      const char* const* str,
                      const GLint* length) override;
void glStencilFuncFn(GLenum func, GLint ref, GLuint mask) override;
void glStencilFuncSeparateFn(GLenum face,
                             GLenum func,
                             GLint ref,
                             GLuint mask) override;
void glStencilMaskFn(GLuint mask) override;
void glStencilMaskSeparateFn(GLenum face, GLuint mask) override;
void glStencilOpFn(GLenum fail, GLenum zfail, GLenum zpass) override;
void glStencilOpSeparateFn(GLenum face,
                           GLenum fail,
                           GLenum zfail,
                           GLenum zpass) override;
GLboolean glTestFenceAPPLEFn(GLuint fence) override;
GLboolean glTestFenceNVFn(GLuint fence) override;
void glTexImage2DFn(GLenum target,
                    GLint level,
                    GLint internalformat,
                    GLsizei width,
                    GLsizei height,
                    GLint border,
                    GLenum format,
                    GLenum type,
                    const void* pixels) override;
void glTexImage3DFn(GLenum target,
                    GLint level,
                    GLint internalformat,
                    GLsizei width,
                    GLsizei height,
                    GLsizei depth,
                    GLint border,
                    GLenum format,
                    GLenum type,
                    const void* pixels) override;
void glTexParameterfFn(GLenum target, GLenum pname, GLfloat param) override;
void glTexParameterfvFn(GLenum target,
                        GLenum pname,
                        const GLfloat* params) override;
void glTexParameteriFn(GLenum target, GLenum pname, GLint param) override;
void glTexParameterivFn(GLenum target,
                        GLenum pname,
                        const GLint* params) override;
void glTexStorage2DEXTFn(GLenum target,
                         GLsizei levels,
                         GLenum internalformat,
                         GLsizei width,
                         GLsizei height) override;
void glTexStorage3DFn(GLenum target,
                      GLsizei levels,
                      GLenum internalformat,
                      GLsizei width,
                      GLsizei height,
                      GLsizei depth) override;
void glTexSubImage2DFn(GLenum target,
                       GLint level,
                       GLint xoffset,
                       GLint yoffset,
                       GLsizei width,
                       GLsizei height,
                       GLenum format,
                       GLenum type,
                       const void* pixels) override;
void glTransformFeedbackVaryingsFn(GLuint program,
                                   GLsizei count,
                                   const char* const* varyings,
                                   GLenum bufferMode) override;
void glUniform1fFn(GLint location, GLfloat x) override;
void glUniform1fvFn(GLint location, GLsizei count, const GLfloat* v) override;
void glUniform1iFn(GLint location, GLint x) override;
void glUniform1ivFn(GLint location, GLsizei count, const GLint* v) override;
void glUniform1uiFn(GLint location, GLuint v0) override;
void glUniform1uivFn(GLint location, GLsizei count, const GLuint* v) override;
void glUniform2fFn(GLint location, GLfloat x, GLfloat y) override;
void glUniform2fvFn(GLint location, GLsizei count, const GLfloat* v) override;
void glUniform2iFn(GLint location, GLint x, GLint y) override;
void glUniform2ivFn(GLint location, GLsizei count, const GLint* v) override;
void glUniform2uiFn(GLint location, GLuint v0, GLuint v1) override;
void glUniform2uivFn(GLint location, GLsizei count, const GLuint* v) override;
void glUniform3fFn(GLint location, GLfloat x, GLfloat y, GLfloat z) override;
void glUniform3fvFn(GLint location, GLsizei count, const GLfloat* v) override;
void glUniform3iFn(GLint location, GLint x, GLint y, GLint z) override;
void glUniform3ivFn(GLint location, GLsizei count, const GLint* v) override;
void glUniform3uiFn(GLint location, GLuint v0, GLuint v1, GLuint v2) override;
void glUniform3uivFn(GLint location, GLsizei count, const GLuint* v) override;
void glUniform4fFn(GLint location,
                   GLfloat x,
                   GLfloat y,
                   GLfloat z,
                   GLfloat w) override;
void glUniform4fvFn(GLint location, GLsizei count, const GLfloat* v) override;
void glUniform4iFn(GLint location, GLint x, GLint y, GLint z, GLint w) override;
void glUniform4ivFn(GLint location, GLsizei count, const GLint* v) override;
void glUniform4uiFn(GLint location,
                    GLuint v0,
                    GLuint v1,
                    GLuint v2,
                    GLuint v3) override;
void glUniform4uivFn(GLint location, GLsizei count, const GLuint* v) override;
void glUniformBlockBindingFn(GLuint program,
                             GLuint uniformBlockIndex,
                             GLuint uniformBlockBinding) override;
void glUniformMatrix2fvFn(GLint location,
                          GLsizei count,
                          GLboolean transpose,
                          const GLfloat* value) override;
void glUniformMatrix2x3fvFn(GLint location,
                            GLsizei count,
                            GLboolean transpose,
                            const GLfloat* value) override;
void glUniformMatrix2x4fvFn(GLint location,
                            GLsizei count,
                            GLboolean transpose,
                            const GLfloat* value) override;
void glUniformMatrix3fvFn(GLint location,
                          GLsizei count,
                          GLboolean transpose,
                          const GLfloat* value) override;
void glUniformMatrix3x2fvFn(GLint location,
                            GLsizei count,
                            GLboolean transpose,
                            const GLfloat* value) override;
void glUniformMatrix3x4fvFn(GLint location,
                            GLsizei count,
                            GLboolean transpose,
                            const GLfloat* value) override;
void glUniformMatrix4fvFn(GLint location,
                          GLsizei count,
                          GLboolean transpose,
                          const GLfloat* value) override;
void glUniformMatrix4x2fvFn(GLint location,
                            GLsizei count,
                            GLboolean transpose,
                            const GLfloat* value) override;
void glUniformMatrix4x3fvFn(GLint location,
                            GLsizei count,
                            GLboolean transpose,
                            const GLfloat* value) override;
GLboolean glUnmapBufferFn(GLenum target) override;
void glUseProgramFn(GLuint program) override;
void glValidateProgramFn(GLuint program) override;
void glVertexAttrib1fFn(GLuint indx, GLfloat x) override;
void glVertexAttrib1fvFn(GLuint indx, const GLfloat* values) override;
void glVertexAttrib2fFn(GLuint indx, GLfloat x, GLfloat y) override;
void glVertexAttrib2fvFn(GLuint indx, const GLfloat* values) override;
void glVertexAttrib3fFn(GLuint indx, GLfloat x, GLfloat y, GLfloat z) override;
void glVertexAttrib3fvFn(GLuint indx, const GLfloat* values) override;
void glVertexAttrib4fFn(GLuint indx,
                        GLfloat x,
                        GLfloat y,
                        GLfloat z,
                        GLfloat w) override;
void glVertexAttrib4fvFn(GLuint indx, const GLfloat* values) override;
void glVertexAttribDivisorANGLEFn(GLuint index, GLuint divisor) override;
void glVertexAttribI4iFn(GLuint indx,
                         GLint x,
                         GLint y,
                         GLint z,
                         GLint w) override;
void glVertexAttribI4ivFn(GLuint indx, const GLint* values) override;
void glVertexAttribI4uiFn(GLuint indx,
                          GLuint x,
                          GLuint y,
                          GLuint z,
                          GLuint w) override;
void glVertexAttribI4uivFn(GLuint indx, const GLuint* values) override;
void glVertexAttribIPointerFn(GLuint indx,
                              GLint size,
                              GLenum type,
                              GLsizei stride,
                              const void* ptr) override;
void glVertexAttribPointerFn(GLuint indx,
                             GLint size,
                             GLenum type,
                             GLboolean normalized,
                             GLsizei stride,
                             const void* ptr) override;
void glViewportFn(GLint x, GLint y, GLsizei width, GLsizei height) override;
GLenum glWaitSyncFn(GLsync sync, GLbitfield flags, GLuint64 timeout) override;
