// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

// This file is included by gles2_implementation.h to declare the
// GL api functions.
#ifndef GPU_COMMAND_BUFFER_CLIENT_GLES2_IMPLEMENTATION_AUTOGEN_H_
#define GPU_COMMAND_BUFFER_CLIENT_GLES2_IMPLEMENTATION_AUTOGEN_H_

void ActiveTexture(GLenum texture) override;

void AttachShader(GLuint program, GLuint shader) override;

void BindAttribLocation(GLuint program,
                        GLuint index,
                        const char* name) override;

void BindBuffer(GLenum target, GLuint buffer) override;

void BindBufferBase(GLenum target, GLuint index, GLuint buffer) override;

void BindBufferRange(GLenum target,
                     GLuint index,
                     GLuint buffer,
                     GLintptr offset,
                     GLsizeiptr size) override;

void BindFramebuffer(GLenum target, GLuint framebuffer) override;

void BindRenderbuffer(GLenum target, GLuint renderbuffer) override;

void BindSampler(GLuint unit, GLuint sampler) override;

void BindTexture(GLenum target, GLuint texture) override;

void BindTransformFeedback(GLenum target, GLuint transformfeedback) override;

void BlendColor(GLclampf red,
                GLclampf green,
                GLclampf blue,
                GLclampf alpha) override;

void BlendEquation(GLenum mode) override;

void BlendEquationSeparate(GLenum modeRGB, GLenum modeAlpha) override;

void BlendFunc(GLenum sfactor, GLenum dfactor) override;

void BlendFuncSeparate(GLenum srcRGB,
                       GLenum dstRGB,
                       GLenum srcAlpha,
                       GLenum dstAlpha) override;

void BufferData(GLenum target,
                GLsizeiptr size,
                const void* data,
                GLenum usage) override;

void BufferSubData(GLenum target,
                   GLintptr offset,
                   GLsizeiptr size,
                   const void* data) override;

GLenum CheckFramebufferStatus(GLenum target) override;

void Clear(GLbitfield mask) override;

void ClearBufferfi(GLenum buffer,
                   GLint drawbuffers,
                   GLfloat depth,
                   GLint stencil) override;

void ClearBufferfv(GLenum buffer,
                   GLint drawbuffers,
                   const GLfloat* value) override;

void ClearBufferiv(GLenum buffer,
                   GLint drawbuffers,
                   const GLint* value) override;

void ClearBufferuiv(GLenum buffer,
                    GLint drawbuffers,
                    const GLuint* value) override;

void ClearColor(GLclampf red,
                GLclampf green,
                GLclampf blue,
                GLclampf alpha) override;

void ClearDepthf(GLclampf depth) override;

void ClearStencil(GLint s) override;

GLenum ClientWaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout) override;

void ColorMask(GLboolean red,
               GLboolean green,
               GLboolean blue,
               GLboolean alpha) override;

void CompileShader(GLuint shader) override;

void CompressedTexImage2D(GLenum target,
                          GLint level,
                          GLenum internalformat,
                          GLsizei width,
                          GLsizei height,
                          GLint border,
                          GLsizei imageSize,
                          const void* data) override;

void CompressedTexSubImage2D(GLenum target,
                             GLint level,
                             GLint xoffset,
                             GLint yoffset,
                             GLsizei width,
                             GLsizei height,
                             GLenum format,
                             GLsizei imageSize,
                             const void* data) override;

void CopyBufferSubData(GLenum readtarget,
                       GLenum writetarget,
                       GLintptr readoffset,
                       GLintptr writeoffset,
                       GLsizeiptr size) override;

void CopyTexImage2D(GLenum target,
                    GLint level,
                    GLenum internalformat,
                    GLint x,
                    GLint y,
                    GLsizei width,
                    GLsizei height,
                    GLint border) override;

void CopyTexSubImage2D(GLenum target,
                       GLint level,
                       GLint xoffset,
                       GLint yoffset,
                       GLint x,
                       GLint y,
                       GLsizei width,
                       GLsizei height) override;

void CopyTexSubImage3D(GLenum target,
                       GLint level,
                       GLint xoffset,
                       GLint yoffset,
                       GLint zoffset,
                       GLint x,
                       GLint y,
                       GLsizei width,
                       GLsizei height) override;

GLuint CreateProgram() override;

GLuint CreateShader(GLenum type) override;

void CullFace(GLenum mode) override;

void DeleteBuffers(GLsizei n, const GLuint* buffers) override;

void DeleteFramebuffers(GLsizei n, const GLuint* framebuffers) override;

void DeleteProgram(GLuint program) override;

void DeleteRenderbuffers(GLsizei n, const GLuint* renderbuffers) override;

void DeleteSamplers(GLsizei n, const GLuint* samplers) override;

void DeleteSync(GLsync sync) override;

void DeleteShader(GLuint shader) override;

void DeleteTextures(GLsizei n, const GLuint* textures) override;

void DeleteTransformFeedbacks(GLsizei n, const GLuint* ids) override;

void DepthFunc(GLenum func) override;

void DepthMask(GLboolean flag) override;

void DepthRangef(GLclampf zNear, GLclampf zFar) override;

void DetachShader(GLuint program, GLuint shader) override;

void Disable(GLenum cap) override;

void DrawArrays(GLenum mode, GLint first, GLsizei count) override;

void DrawElements(GLenum mode,
                  GLsizei count,
                  GLenum type,
                  const void* indices) override;

void DrawRangeElements(GLenum mode,
                       GLuint start,
                       GLuint end,
                       GLsizei count,
                       GLenum type,
                       const void* indices) override;

void Enable(GLenum cap) override;

GLsync FenceSync(GLenum condition, GLbitfield flags) override;

void Finish() override;

void Flush() override;

void FramebufferRenderbuffer(GLenum target,
                             GLenum attachment,
                             GLenum renderbuffertarget,
                             GLuint renderbuffer) override;

void FramebufferTexture2D(GLenum target,
                          GLenum attachment,
                          GLenum textarget,
                          GLuint texture,
                          GLint level) override;

void FramebufferTextureLayer(GLenum target,
                             GLenum attachment,
                             GLuint texture,
                             GLint level,
                             GLint layer) override;

void FrontFace(GLenum mode) override;

void GenBuffers(GLsizei n, GLuint* buffers) override;

void GenerateMipmap(GLenum target) override;

void GenFramebuffers(GLsizei n, GLuint* framebuffers) override;

void GenRenderbuffers(GLsizei n, GLuint* renderbuffers) override;

void GenSamplers(GLsizei n, GLuint* samplers) override;

void GenTextures(GLsizei n, GLuint* textures) override;

void GenTransformFeedbacks(GLsizei n, GLuint* ids) override;

void GetActiveAttrib(GLuint program,
                     GLuint index,
                     GLsizei bufsize,
                     GLsizei* length,
                     GLint* size,
                     GLenum* type,
                     char* name) override;

void GetActiveUniform(GLuint program,
                      GLuint index,
                      GLsizei bufsize,
                      GLsizei* length,
                      GLint* size,
                      GLenum* type,
                      char* name) override;

void GetActiveUniformBlockiv(GLuint program,
                             GLuint index,
                             GLenum pname,
                             GLint* params) override;

void GetActiveUniformBlockName(GLuint program,
                               GLuint index,
                               GLsizei bufsize,
                               GLsizei* length,
                               char* name) override;

void GetActiveUniformsiv(GLuint program,
                         GLsizei count,
                         const GLuint* indices,
                         GLenum pname,
                         GLint* params) override;

void GetAttachedShaders(GLuint program,
                        GLsizei maxcount,
                        GLsizei* count,
                        GLuint* shaders) override;

GLint GetAttribLocation(GLuint program, const char* name) override;

void GetBooleanv(GLenum pname, GLboolean* params) override;

void GetBufferParameteriv(GLenum target, GLenum pname, GLint* params) override;

GLenum GetError() override;

void GetFloatv(GLenum pname, GLfloat* params) override;

GLint GetFragDataLocation(GLuint program, const char* name) override;

void GetFramebufferAttachmentParameteriv(GLenum target,
                                         GLenum attachment,
                                         GLenum pname,
                                         GLint* params) override;

void GetInteger64v(GLenum pname, GLint64* params) override;

void GetIntegeri_v(GLenum pname, GLuint index, GLint* data) override;

void GetInteger64i_v(GLenum pname, GLuint index, GLint64* data) override;

void GetIntegerv(GLenum pname, GLint* params) override;

void GetInternalformativ(GLenum target,
                         GLenum format,
                         GLenum pname,
                         GLsizei bufSize,
                         GLint* params) override;

void GetProgramiv(GLuint program, GLenum pname, GLint* params) override;

void GetProgramInfoLog(GLuint program,
                       GLsizei bufsize,
                       GLsizei* length,
                       char* infolog) override;

void GetRenderbufferParameteriv(GLenum target,
                                GLenum pname,
                                GLint* params) override;

void GetSamplerParameterfv(GLuint sampler,
                           GLenum pname,
                           GLfloat* params) override;

void GetSamplerParameteriv(GLuint sampler,
                           GLenum pname,
                           GLint* params) override;

void GetShaderiv(GLuint shader, GLenum pname, GLint* params) override;

void GetShaderInfoLog(GLuint shader,
                      GLsizei bufsize,
                      GLsizei* length,
                      char* infolog) override;

void GetShaderPrecisionFormat(GLenum shadertype,
                              GLenum precisiontype,
                              GLint* range,
                              GLint* precision) override;

void GetShaderSource(GLuint shader,
                     GLsizei bufsize,
                     GLsizei* length,
                     char* source) override;

const GLubyte* GetString(GLenum name) override;

void GetSynciv(GLsync sync,
               GLenum pname,
               GLsizei bufsize,
               GLsizei* length,
               GLint* values) override;

void GetTexParameterfv(GLenum target, GLenum pname, GLfloat* params) override;

void GetTexParameteriv(GLenum target, GLenum pname, GLint* params) override;

void GetTransformFeedbackVarying(GLuint program,
                                 GLuint index,
                                 GLsizei bufsize,
                                 GLsizei* length,
                                 GLsizei* size,
                                 GLenum* type,
                                 char* name) override;

GLuint GetUniformBlockIndex(GLuint program, const char* name) override;

void GetUniformfv(GLuint program, GLint location, GLfloat* params) override;

void GetUniformiv(GLuint program, GLint location, GLint* params) override;

void GetUniformIndices(GLuint program,
                       GLsizei count,
                       const char* const* names,
                       GLuint* indices) override;

GLint GetUniformLocation(GLuint program, const char* name) override;

void GetVertexAttribPointerv(GLuint index,
                             GLenum pname,
                             void** pointer) override;

void Hint(GLenum target, GLenum mode) override;

void InvalidateFramebuffer(GLenum target,
                           GLsizei count,
                           const GLenum* attachments) override;

void InvalidateSubFramebuffer(GLenum target,
                              GLsizei count,
                              const GLenum* attachments,
                              GLint x,
                              GLint y,
                              GLsizei width,
                              GLsizei height) override;

GLboolean IsBuffer(GLuint buffer) override;

GLboolean IsEnabled(GLenum cap) override;

GLboolean IsFramebuffer(GLuint framebuffer) override;

GLboolean IsProgram(GLuint program) override;

GLboolean IsRenderbuffer(GLuint renderbuffer) override;

GLboolean IsSampler(GLuint sampler) override;

GLboolean IsShader(GLuint shader) override;

GLboolean IsSync(GLsync sync) override;

GLboolean IsTexture(GLuint texture) override;

GLboolean IsTransformFeedback(GLuint transformfeedback) override;

void LineWidth(GLfloat width) override;

void LinkProgram(GLuint program) override;

void PauseTransformFeedback() override;

void PixelStorei(GLenum pname, GLint param) override;

void PolygonOffset(GLfloat factor, GLfloat units) override;

void ReadBuffer(GLenum src) override;

void ReadPixels(GLint x,
                GLint y,
                GLsizei width,
                GLsizei height,
                GLenum format,
                GLenum type,
                void* pixels) override;

void ReleaseShaderCompiler() override;

void RenderbufferStorage(GLenum target,
                         GLenum internalformat,
                         GLsizei width,
                         GLsizei height) override;

void ResumeTransformFeedback() override;

void SampleCoverage(GLclampf value, GLboolean invert) override;

void SamplerParameterf(GLuint sampler, GLenum pname, GLfloat param) override;

void SamplerParameterfv(GLuint sampler,
                        GLenum pname,
                        const GLfloat* params) override;

void SamplerParameteri(GLuint sampler, GLenum pname, GLint param) override;

void SamplerParameteriv(GLuint sampler,
                        GLenum pname,
                        const GLint* params) override;

void Scissor(GLint x, GLint y, GLsizei width, GLsizei height) override;

void ShaderBinary(GLsizei n,
                  const GLuint* shaders,
                  GLenum binaryformat,
                  const void* binary,
                  GLsizei length) override;

void ShaderSource(GLuint shader,
                  GLsizei count,
                  const GLchar* const* str,
                  const GLint* length) override;

void ShallowFinishCHROMIUM() override;

void ShallowFlushCHROMIUM() override;

void OrderingBarrierCHROMIUM() override;

void StencilFunc(GLenum func, GLint ref, GLuint mask) override;

void StencilFuncSeparate(GLenum face,
                         GLenum func,
                         GLint ref,
                         GLuint mask) override;

void StencilMask(GLuint mask) override;

void StencilMaskSeparate(GLenum face, GLuint mask) override;

void StencilOp(GLenum fail, GLenum zfail, GLenum zpass) override;

void StencilOpSeparate(GLenum face,
                       GLenum fail,
                       GLenum zfail,
                       GLenum zpass) override;

void TexImage2D(GLenum target,
                GLint level,
                GLint internalformat,
                GLsizei width,
                GLsizei height,
                GLint border,
                GLenum format,
                GLenum type,
                const void* pixels) override;

void TexImage3D(GLenum target,
                GLint level,
                GLint internalformat,
                GLsizei width,
                GLsizei height,
                GLsizei depth,
                GLint border,
                GLenum format,
                GLenum type,
                const void* pixels) override;

void TexParameterf(GLenum target, GLenum pname, GLfloat param) override;

void TexParameterfv(GLenum target,
                    GLenum pname,
                    const GLfloat* params) override;

void TexParameteri(GLenum target, GLenum pname, GLint param) override;

void TexParameteriv(GLenum target, GLenum pname, const GLint* params) override;

void TexStorage3D(GLenum target,
                  GLsizei levels,
                  GLenum internalFormat,
                  GLsizei width,
                  GLsizei height,
                  GLsizei depth) override;

void TexSubImage2D(GLenum target,
                   GLint level,
                   GLint xoffset,
                   GLint yoffset,
                   GLsizei width,
                   GLsizei height,
                   GLenum format,
                   GLenum type,
                   const void* pixels) override;

void TexSubImage3D(GLenum target,
                   GLint level,
                   GLint xoffset,
                   GLint yoffset,
                   GLint zoffset,
                   GLsizei width,
                   GLsizei height,
                   GLsizei depth,
                   GLenum format,
                   GLenum type,
                   const void* pixels) override;

void TransformFeedbackVaryings(GLuint program,
                               GLsizei count,
                               const char* const* varyings,
                               GLenum buffermode) override;

void Uniform1f(GLint location, GLfloat x) override;

void Uniform1fv(GLint location, GLsizei count, const GLfloat* v) override;

void Uniform1i(GLint location, GLint x) override;

void Uniform1iv(GLint location, GLsizei count, const GLint* v) override;

void Uniform1ui(GLint location, GLuint x) override;

void Uniform1uiv(GLint location, GLsizei count, const GLuint* v) override;

void Uniform2f(GLint location, GLfloat x, GLfloat y) override;

void Uniform2fv(GLint location, GLsizei count, const GLfloat* v) override;

void Uniform2i(GLint location, GLint x, GLint y) override;

void Uniform2iv(GLint location, GLsizei count, const GLint* v) override;

void Uniform2ui(GLint location, GLuint x, GLuint y) override;

void Uniform2uiv(GLint location, GLsizei count, const GLuint* v) override;

void Uniform3f(GLint location, GLfloat x, GLfloat y, GLfloat z) override;

void Uniform3fv(GLint location, GLsizei count, const GLfloat* v) override;

void Uniform3i(GLint location, GLint x, GLint y, GLint z) override;

void Uniform3iv(GLint location, GLsizei count, const GLint* v) override;

void Uniform3ui(GLint location, GLuint x, GLuint y, GLuint z) override;

void Uniform3uiv(GLint location, GLsizei count, const GLuint* v) override;

void Uniform4f(GLint location,
               GLfloat x,
               GLfloat y,
               GLfloat z,
               GLfloat w) override;

void Uniform4fv(GLint location, GLsizei count, const GLfloat* v) override;

void Uniform4i(GLint location, GLint x, GLint y, GLint z, GLint w) override;

void Uniform4iv(GLint location, GLsizei count, const GLint* v) override;

void Uniform4ui(GLint location,
                GLuint x,
                GLuint y,
                GLuint z,
                GLuint w) override;

void Uniform4uiv(GLint location, GLsizei count, const GLuint* v) override;

void UniformBlockBinding(GLuint program, GLuint index, GLuint binding) override;

void UniformMatrix2fv(GLint location,
                      GLsizei count,
                      GLboolean transpose,
                      const GLfloat* value) override;

void UniformMatrix2x3fv(GLint location,
                        GLsizei count,
                        GLboolean transpose,
                        const GLfloat* value) override;

void UniformMatrix2x4fv(GLint location,
                        GLsizei count,
                        GLboolean transpose,
                        const GLfloat* value) override;

void UniformMatrix3fv(GLint location,
                      GLsizei count,
                      GLboolean transpose,
                      const GLfloat* value) override;

void UniformMatrix3x2fv(GLint location,
                        GLsizei count,
                        GLboolean transpose,
                        const GLfloat* value) override;

void UniformMatrix3x4fv(GLint location,
                        GLsizei count,
                        GLboolean transpose,
                        const GLfloat* value) override;

void UniformMatrix4fv(GLint location,
                      GLsizei count,
                      GLboolean transpose,
                      const GLfloat* value) override;

void UniformMatrix4x2fv(GLint location,
                        GLsizei count,
                        GLboolean transpose,
                        const GLfloat* value) override;

void UniformMatrix4x3fv(GLint location,
                        GLsizei count,
                        GLboolean transpose,
                        const GLfloat* value) override;

void UseProgram(GLuint program) override;

void ValidateProgram(GLuint program) override;

void VertexAttrib1f(GLuint indx, GLfloat x) override;

void VertexAttrib1fv(GLuint indx, const GLfloat* values) override;

void VertexAttrib2f(GLuint indx, GLfloat x, GLfloat y) override;

void VertexAttrib2fv(GLuint indx, const GLfloat* values) override;

void VertexAttrib3f(GLuint indx, GLfloat x, GLfloat y, GLfloat z) override;

void VertexAttrib3fv(GLuint indx, const GLfloat* values) override;

void VertexAttrib4f(GLuint indx,
                    GLfloat x,
                    GLfloat y,
                    GLfloat z,
                    GLfloat w) override;

void VertexAttrib4fv(GLuint indx, const GLfloat* values) override;

void VertexAttribI4i(GLuint indx, GLint x, GLint y, GLint z, GLint w) override;

void VertexAttribI4iv(GLuint indx, const GLint* values) override;

void VertexAttribI4ui(GLuint indx,
                      GLuint x,
                      GLuint y,
                      GLuint z,
                      GLuint w) override;

void VertexAttribI4uiv(GLuint indx, const GLuint* values) override;

void VertexAttribIPointer(GLuint indx,
                          GLint size,
                          GLenum type,
                          GLsizei stride,
                          const void* ptr) override;

void VertexAttribPointer(GLuint indx,
                         GLint size,
                         GLenum type,
                         GLboolean normalized,
                         GLsizei stride,
                         const void* ptr) override;

void Viewport(GLint x, GLint y, GLsizei width, GLsizei height) override;

void WaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout) override;

void BlitFramebufferCHROMIUM(GLint srcX0,
                             GLint srcY0,
                             GLint srcX1,
                             GLint srcY1,
                             GLint dstX0,
                             GLint dstY0,
                             GLint dstX1,
                             GLint dstY1,
                             GLbitfield mask,
                             GLenum filter) override;

void RenderbufferStorageMultisampleCHROMIUM(GLenum target,
                                            GLsizei samples,
                                            GLenum internalformat,
                                            GLsizei width,
                                            GLsizei height) override;

void RenderbufferStorageMultisampleEXT(GLenum target,
                                       GLsizei samples,
                                       GLenum internalformat,
                                       GLsizei width,
                                       GLsizei height) override;

void FramebufferTexture2DMultisampleEXT(GLenum target,
                                        GLenum attachment,
                                        GLenum textarget,
                                        GLuint texture,
                                        GLint level,
                                        GLsizei samples) override;

void TexStorage2DEXT(GLenum target,
                     GLsizei levels,
                     GLenum internalFormat,
                     GLsizei width,
                     GLsizei height) override;

void GenQueriesEXT(GLsizei n, GLuint* queries) override;

void DeleteQueriesEXT(GLsizei n, const GLuint* queries) override;

GLboolean IsQueryEXT(GLuint id) override;

void BeginQueryEXT(GLenum target, GLuint id) override;

void BeginTransformFeedback(GLenum primitivemode) override;

void EndQueryEXT(GLenum target) override;

void EndTransformFeedback() override;

void GetQueryivEXT(GLenum target, GLenum pname, GLint* params) override;

void GetQueryObjectuivEXT(GLuint id, GLenum pname, GLuint* params) override;

void InsertEventMarkerEXT(GLsizei length, const GLchar* marker) override;

void PushGroupMarkerEXT(GLsizei length, const GLchar* marker) override;

void PopGroupMarkerEXT() override;

void GenVertexArraysOES(GLsizei n, GLuint* arrays) override;

void DeleteVertexArraysOES(GLsizei n, const GLuint* arrays) override;

GLboolean IsVertexArrayOES(GLuint array) override;

void BindVertexArrayOES(GLuint array) override;

void SwapBuffers() override;

GLuint GetMaxValueInBufferCHROMIUM(GLuint buffer_id,
                                   GLsizei count,
                                   GLenum type,
                                   GLuint offset) override;

GLboolean EnableFeatureCHROMIUM(const char* feature) override;

void* MapBufferCHROMIUM(GLuint target, GLenum access) override;

GLboolean UnmapBufferCHROMIUM(GLuint target) override;

void* MapBufferSubDataCHROMIUM(GLuint target,
                               GLintptr offset,
                               GLsizeiptr size,
                               GLenum access) override;

void UnmapBufferSubDataCHROMIUM(const void* mem) override;

void* MapBufferRange(GLenum target,
                     GLintptr offset,
                     GLsizeiptr size,
                     GLbitfield access) override;

GLboolean UnmapBuffer(GLenum target) override;

void* MapTexSubImage2DCHROMIUM(GLenum target,
                               GLint level,
                               GLint xoffset,
                               GLint yoffset,
                               GLsizei width,
                               GLsizei height,
                               GLenum format,
                               GLenum type,
                               GLenum access) override;

void UnmapTexSubImage2DCHROMIUM(const void* mem) override;

void ResizeCHROMIUM(GLuint width, GLuint height, GLfloat scale_factor) override;

const GLchar* GetRequestableExtensionsCHROMIUM() override;

void RequestExtensionCHROMIUM(const char* extension) override;

void RateLimitOffscreenContextCHROMIUM() override;

void GetProgramInfoCHROMIUM(GLuint program,
                            GLsizei bufsize,
                            GLsizei* size,
                            void* info) override;

void GetUniformBlocksCHROMIUM(GLuint program,
                              GLsizei bufsize,
                              GLsizei* size,
                              void* info) override;

void GetTransformFeedbackVaryingsCHROMIUM(GLuint program,
                                          GLsizei bufsize,
                                          GLsizei* size,
                                          void* info) override;

void GetUniformsES3CHROMIUM(GLuint program,
                            GLsizei bufsize,
                            GLsizei* size,
                            void* info) override;

GLuint CreateStreamTextureCHROMIUM(GLuint texture) override;

GLuint CreateImageCHROMIUM(ClientBuffer buffer,
                           GLsizei width,
                           GLsizei height,
                           GLenum internalformat) override;

void DestroyImageCHROMIUM(GLuint image_id) override;

GLuint CreateGpuMemoryBufferImageCHROMIUM(GLsizei width,
                                          GLsizei height,
                                          GLenum internalformat,
                                          GLenum usage) override;

void GetTranslatedShaderSourceANGLE(GLuint shader,
                                    GLsizei bufsize,
                                    GLsizei* length,
                                    char* source) override;

void PostSubBufferCHROMIUM(GLint x,
                           GLint y,
                           GLint width,
                           GLint height) override;

void TexImageIOSurface2DCHROMIUM(GLenum target,
                                 GLsizei width,
                                 GLsizei height,
                                 GLuint ioSurfaceId,
                                 GLuint plane) override;

void CopyTextureCHROMIUM(GLenum target,
                         GLenum source_id,
                         GLenum dest_id,
                         GLint internalformat,
                         GLenum dest_type) override;

void CopySubTextureCHROMIUM(GLenum target,
                            GLenum source_id,
                            GLenum dest_id,
                            GLint xoffset,
                            GLint yoffset) override;

void DrawArraysInstancedANGLE(GLenum mode,
                              GLint first,
                              GLsizei count,
                              GLsizei primcount) override;

void DrawElementsInstancedANGLE(GLenum mode,
                                GLsizei count,
                                GLenum type,
                                const void* indices,
                                GLsizei primcount) override;

void VertexAttribDivisorANGLE(GLuint index, GLuint divisor) override;

void GenMailboxCHROMIUM(GLbyte* mailbox) override;

void ProduceTextureCHROMIUM(GLenum target, const GLbyte* mailbox) override;

void ProduceTextureDirectCHROMIUM(GLuint texture,
                                  GLenum target,
                                  const GLbyte* mailbox) override;

void ConsumeTextureCHROMIUM(GLenum target, const GLbyte* mailbox) override;

GLuint CreateAndConsumeTextureCHROMIUM(GLenum target,
                                       const GLbyte* mailbox) override;

void BindUniformLocationCHROMIUM(GLuint program,
                                 GLint location,
                                 const char* name) override;

void GenValuebuffersCHROMIUM(GLsizei n, GLuint* buffers) override;

void DeleteValuebuffersCHROMIUM(GLsizei n, const GLuint* valuebuffers) override;

GLboolean IsValuebufferCHROMIUM(GLuint valuebuffer) override;

void BindValuebufferCHROMIUM(GLenum target, GLuint valuebuffer) override;

void SubscribeValueCHROMIUM(GLenum target, GLenum subscription) override;

void PopulateSubscribedValuesCHROMIUM(GLenum target) override;

void UniformValuebufferCHROMIUM(GLint location,
                                GLenum target,
                                GLenum subscription) override;

void BindTexImage2DCHROMIUM(GLenum target, GLint imageId) override;

void ReleaseTexImage2DCHROMIUM(GLenum target, GLint imageId) override;

void TraceBeginCHROMIUM(const char* category_name,
                        const char* trace_name) override;

void TraceEndCHROMIUM() override;

void AsyncTexSubImage2DCHROMIUM(GLenum target,
                                GLint level,
                                GLint xoffset,
                                GLint yoffset,
                                GLsizei width,
                                GLsizei height,
                                GLenum format,
                                GLenum type,
                                const void* data) override;

void AsyncTexImage2DCHROMIUM(GLenum target,
                             GLint level,
                             GLenum internalformat,
                             GLsizei width,
                             GLsizei height,
                             GLint border,
                             GLenum format,
                             GLenum type,
                             const void* pixels) override;

void WaitAsyncTexImage2DCHROMIUM(GLenum target) override;

void WaitAllAsyncTexImage2DCHROMIUM() override;

void DiscardFramebufferEXT(GLenum target,
                           GLsizei count,
                           const GLenum* attachments) override;

void LoseContextCHROMIUM(GLenum current, GLenum other) override;

GLuint InsertSyncPointCHROMIUM() override;

void WaitSyncPointCHROMIUM(GLuint sync_point) override;

void DrawBuffersEXT(GLsizei count, const GLenum* bufs) override;

void DiscardBackbufferCHROMIUM() override;

void ScheduleOverlayPlaneCHROMIUM(GLint plane_z_order,
                                  GLenum plane_transform,
                                  GLuint overlay_texture_id,
                                  GLint bounds_x,
                                  GLint bounds_y,
                                  GLint bounds_width,
                                  GLint bounds_height,
                                  GLfloat uv_x,
                                  GLfloat uv_y,
                                  GLfloat uv_width,
                                  GLfloat uv_height) override;

void SwapInterval(GLint interval) override;

void MatrixLoadfCHROMIUM(GLenum matrixMode, const GLfloat* m) override;

void MatrixLoadIdentityCHROMIUM(GLenum matrixMode) override;

void BlendBarrierKHR() override;

#endif  // GPU_COMMAND_BUFFER_CLIENT_GLES2_IMPLEMENTATION_AUTOGEN_H_
