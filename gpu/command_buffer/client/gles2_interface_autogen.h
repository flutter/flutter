// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

// This file is included by gles2_interface.h to declare the
// GL api functions.
#ifndef GPU_COMMAND_BUFFER_CLIENT_GLES2_INTERFACE_AUTOGEN_H_
#define GPU_COMMAND_BUFFER_CLIENT_GLES2_INTERFACE_AUTOGEN_H_

virtual void ActiveTexture(GLenum texture) = 0;
virtual void AttachShader(GLuint program, GLuint shader) = 0;
virtual void BindAttribLocation(GLuint program,
                                GLuint index,
                                const char* name) = 0;
virtual void BindBuffer(GLenum target, GLuint buffer) = 0;
virtual void BindBufferBase(GLenum target, GLuint index, GLuint buffer) = 0;
virtual void BindBufferRange(GLenum target,
                             GLuint index,
                             GLuint buffer,
                             GLintptr offset,
                             GLsizeiptr size) = 0;
virtual void BindFramebuffer(GLenum target, GLuint framebuffer) = 0;
virtual void BindRenderbuffer(GLenum target, GLuint renderbuffer) = 0;
virtual void BindSampler(GLuint unit, GLuint sampler) = 0;
virtual void BindTexture(GLenum target, GLuint texture) = 0;
virtual void BindTransformFeedback(GLenum target, GLuint transformfeedback) = 0;
virtual void BlendColor(GLclampf red,
                        GLclampf green,
                        GLclampf blue,
                        GLclampf alpha) = 0;
virtual void BlendEquation(GLenum mode) = 0;
virtual void BlendEquationSeparate(GLenum modeRGB, GLenum modeAlpha) = 0;
virtual void BlendFunc(GLenum sfactor, GLenum dfactor) = 0;
virtual void BlendFuncSeparate(GLenum srcRGB,
                               GLenum dstRGB,
                               GLenum srcAlpha,
                               GLenum dstAlpha) = 0;
virtual void BufferData(GLenum target,
                        GLsizeiptr size,
                        const void* data,
                        GLenum usage) = 0;
virtual void BufferSubData(GLenum target,
                           GLintptr offset,
                           GLsizeiptr size,
                           const void* data) = 0;
virtual GLenum CheckFramebufferStatus(GLenum target) = 0;
virtual void Clear(GLbitfield mask) = 0;
virtual void ClearBufferfi(GLenum buffer,
                           GLint drawbuffers,
                           GLfloat depth,
                           GLint stencil) = 0;
virtual void ClearBufferfv(GLenum buffer,
                           GLint drawbuffers,
                           const GLfloat* value) = 0;
virtual void ClearBufferiv(GLenum buffer,
                           GLint drawbuffers,
                           const GLint* value) = 0;
virtual void ClearBufferuiv(GLenum buffer,
                            GLint drawbuffers,
                            const GLuint* value) = 0;
virtual void ClearColor(GLclampf red,
                        GLclampf green,
                        GLclampf blue,
                        GLclampf alpha) = 0;
virtual void ClearDepthf(GLclampf depth) = 0;
virtual void ClearStencil(GLint s) = 0;
virtual GLenum ClientWaitSync(GLsync sync,
                              GLbitfield flags,
                              GLuint64 timeout) = 0;
virtual void ColorMask(GLboolean red,
                       GLboolean green,
                       GLboolean blue,
                       GLboolean alpha) = 0;
virtual void CompileShader(GLuint shader) = 0;
virtual void CompressedTexImage2D(GLenum target,
                                  GLint level,
                                  GLenum internalformat,
                                  GLsizei width,
                                  GLsizei height,
                                  GLint border,
                                  GLsizei imageSize,
                                  const void* data) = 0;
virtual void CompressedTexSubImage2D(GLenum target,
                                     GLint level,
                                     GLint xoffset,
                                     GLint yoffset,
                                     GLsizei width,
                                     GLsizei height,
                                     GLenum format,
                                     GLsizei imageSize,
                                     const void* data) = 0;
virtual void CopyBufferSubData(GLenum readtarget,
                               GLenum writetarget,
                               GLintptr readoffset,
                               GLintptr writeoffset,
                               GLsizeiptr size) = 0;
virtual void CopyTexImage2D(GLenum target,
                            GLint level,
                            GLenum internalformat,
                            GLint x,
                            GLint y,
                            GLsizei width,
                            GLsizei height,
                            GLint border) = 0;
virtual void CopyTexSubImage2D(GLenum target,
                               GLint level,
                               GLint xoffset,
                               GLint yoffset,
                               GLint x,
                               GLint y,
                               GLsizei width,
                               GLsizei height) = 0;
virtual void CopyTexSubImage3D(GLenum target,
                               GLint level,
                               GLint xoffset,
                               GLint yoffset,
                               GLint zoffset,
                               GLint x,
                               GLint y,
                               GLsizei width,
                               GLsizei height) = 0;
virtual GLuint CreateProgram() = 0;
virtual GLuint CreateShader(GLenum type) = 0;
virtual void CullFace(GLenum mode) = 0;
virtual void DeleteBuffers(GLsizei n, const GLuint* buffers) = 0;
virtual void DeleteFramebuffers(GLsizei n, const GLuint* framebuffers) = 0;
virtual void DeleteProgram(GLuint program) = 0;
virtual void DeleteRenderbuffers(GLsizei n, const GLuint* renderbuffers) = 0;
virtual void DeleteSamplers(GLsizei n, const GLuint* samplers) = 0;
virtual void DeleteSync(GLsync sync) = 0;
virtual void DeleteShader(GLuint shader) = 0;
virtual void DeleteTextures(GLsizei n, const GLuint* textures) = 0;
virtual void DeleteTransformFeedbacks(GLsizei n, const GLuint* ids) = 0;
virtual void DepthFunc(GLenum func) = 0;
virtual void DepthMask(GLboolean flag) = 0;
virtual void DepthRangef(GLclampf zNear, GLclampf zFar) = 0;
virtual void DetachShader(GLuint program, GLuint shader) = 0;
virtual void Disable(GLenum cap) = 0;
virtual void DisableVertexAttribArray(GLuint index) = 0;
virtual void DrawArrays(GLenum mode, GLint first, GLsizei count) = 0;
virtual void DrawElements(GLenum mode,
                          GLsizei count,
                          GLenum type,
                          const void* indices) = 0;
virtual void DrawRangeElements(GLenum mode,
                               GLuint start,
                               GLuint end,
                               GLsizei count,
                               GLenum type,
                               const void* indices) = 0;
virtual void Enable(GLenum cap) = 0;
virtual void EnableVertexAttribArray(GLuint index) = 0;
virtual GLsync FenceSync(GLenum condition, GLbitfield flags) = 0;
virtual void Finish() = 0;
virtual void Flush() = 0;
virtual void FramebufferRenderbuffer(GLenum target,
                                     GLenum attachment,
                                     GLenum renderbuffertarget,
                                     GLuint renderbuffer) = 0;
virtual void FramebufferTexture2D(GLenum target,
                                  GLenum attachment,
                                  GLenum textarget,
                                  GLuint texture,
                                  GLint level) = 0;
virtual void FramebufferTextureLayer(GLenum target,
                                     GLenum attachment,
                                     GLuint texture,
                                     GLint level,
                                     GLint layer) = 0;
virtual void FrontFace(GLenum mode) = 0;
virtual void GenBuffers(GLsizei n, GLuint* buffers) = 0;
virtual void GenerateMipmap(GLenum target) = 0;
virtual void GenFramebuffers(GLsizei n, GLuint* framebuffers) = 0;
virtual void GenRenderbuffers(GLsizei n, GLuint* renderbuffers) = 0;
virtual void GenSamplers(GLsizei n, GLuint* samplers) = 0;
virtual void GenTextures(GLsizei n, GLuint* textures) = 0;
virtual void GenTransformFeedbacks(GLsizei n, GLuint* ids) = 0;
virtual void GetActiveAttrib(GLuint program,
                             GLuint index,
                             GLsizei bufsize,
                             GLsizei* length,
                             GLint* size,
                             GLenum* type,
                             char* name) = 0;
virtual void GetActiveUniform(GLuint program,
                              GLuint index,
                              GLsizei bufsize,
                              GLsizei* length,
                              GLint* size,
                              GLenum* type,
                              char* name) = 0;
virtual void GetActiveUniformBlockiv(GLuint program,
                                     GLuint index,
                                     GLenum pname,
                                     GLint* params) = 0;
virtual void GetActiveUniformBlockName(GLuint program,
                                       GLuint index,
                                       GLsizei bufsize,
                                       GLsizei* length,
                                       char* name) = 0;
virtual void GetActiveUniformsiv(GLuint program,
                                 GLsizei count,
                                 const GLuint* indices,
                                 GLenum pname,
                                 GLint* params) = 0;
virtual void GetAttachedShaders(GLuint program,
                                GLsizei maxcount,
                                GLsizei* count,
                                GLuint* shaders) = 0;
virtual GLint GetAttribLocation(GLuint program, const char* name) = 0;
virtual void GetBooleanv(GLenum pname, GLboolean* params) = 0;
virtual void GetBufferParameteriv(GLenum target,
                                  GLenum pname,
                                  GLint* params) = 0;
virtual GLenum GetError() = 0;
virtual void GetFloatv(GLenum pname, GLfloat* params) = 0;
virtual GLint GetFragDataLocation(GLuint program, const char* name) = 0;
virtual void GetFramebufferAttachmentParameteriv(GLenum target,
                                                 GLenum attachment,
                                                 GLenum pname,
                                                 GLint* params) = 0;
virtual void GetInteger64v(GLenum pname, GLint64* params) = 0;
virtual void GetIntegeri_v(GLenum pname, GLuint index, GLint* data) = 0;
virtual void GetInteger64i_v(GLenum pname, GLuint index, GLint64* data) = 0;
virtual void GetIntegerv(GLenum pname, GLint* params) = 0;
virtual void GetInternalformativ(GLenum target,
                                 GLenum format,
                                 GLenum pname,
                                 GLsizei bufSize,
                                 GLint* params) = 0;
virtual void GetProgramiv(GLuint program, GLenum pname, GLint* params) = 0;
virtual void GetProgramInfoLog(GLuint program,
                               GLsizei bufsize,
                               GLsizei* length,
                               char* infolog) = 0;
virtual void GetRenderbufferParameteriv(GLenum target,
                                        GLenum pname,
                                        GLint* params) = 0;
virtual void GetSamplerParameterfv(GLuint sampler,
                                   GLenum pname,
                                   GLfloat* params) = 0;
virtual void GetSamplerParameteriv(GLuint sampler,
                                   GLenum pname,
                                   GLint* params) = 0;
virtual void GetShaderiv(GLuint shader, GLenum pname, GLint* params) = 0;
virtual void GetShaderInfoLog(GLuint shader,
                              GLsizei bufsize,
                              GLsizei* length,
                              char* infolog) = 0;
virtual void GetShaderPrecisionFormat(GLenum shadertype,
                                      GLenum precisiontype,
                                      GLint* range,
                                      GLint* precision) = 0;
virtual void GetShaderSource(GLuint shader,
                             GLsizei bufsize,
                             GLsizei* length,
                             char* source) = 0;
virtual const GLubyte* GetString(GLenum name) = 0;
virtual void GetSynciv(GLsync sync,
                       GLenum pname,
                       GLsizei bufsize,
                       GLsizei* length,
                       GLint* values) = 0;
virtual void GetTexParameterfv(GLenum target,
                               GLenum pname,
                               GLfloat* params) = 0;
virtual void GetTexParameteriv(GLenum target, GLenum pname, GLint* params) = 0;
virtual void GetTransformFeedbackVarying(GLuint program,
                                         GLuint index,
                                         GLsizei bufsize,
                                         GLsizei* length,
                                         GLsizei* size,
                                         GLenum* type,
                                         char* name) = 0;
virtual GLuint GetUniformBlockIndex(GLuint program, const char* name) = 0;
virtual void GetUniformfv(GLuint program, GLint location, GLfloat* params) = 0;
virtual void GetUniformiv(GLuint program, GLint location, GLint* params) = 0;
virtual void GetUniformIndices(GLuint program,
                               GLsizei count,
                               const char* const* names,
                               GLuint* indices) = 0;
virtual GLint GetUniformLocation(GLuint program, const char* name) = 0;
virtual void GetVertexAttribfv(GLuint index, GLenum pname, GLfloat* params) = 0;
virtual void GetVertexAttribiv(GLuint index, GLenum pname, GLint* params) = 0;
virtual void GetVertexAttribPointerv(GLuint index,
                                     GLenum pname,
                                     void** pointer) = 0;
virtual void Hint(GLenum target, GLenum mode) = 0;
virtual void InvalidateFramebuffer(GLenum target,
                                   GLsizei count,
                                   const GLenum* attachments) = 0;
virtual void InvalidateSubFramebuffer(GLenum target,
                                      GLsizei count,
                                      const GLenum* attachments,
                                      GLint x,
                                      GLint y,
                                      GLsizei width,
                                      GLsizei height) = 0;
virtual GLboolean IsBuffer(GLuint buffer) = 0;
virtual GLboolean IsEnabled(GLenum cap) = 0;
virtual GLboolean IsFramebuffer(GLuint framebuffer) = 0;
virtual GLboolean IsProgram(GLuint program) = 0;
virtual GLboolean IsRenderbuffer(GLuint renderbuffer) = 0;
virtual GLboolean IsSampler(GLuint sampler) = 0;
virtual GLboolean IsShader(GLuint shader) = 0;
virtual GLboolean IsSync(GLsync sync) = 0;
virtual GLboolean IsTexture(GLuint texture) = 0;
virtual GLboolean IsTransformFeedback(GLuint transformfeedback) = 0;
virtual void LineWidth(GLfloat width) = 0;
virtual void LinkProgram(GLuint program) = 0;
virtual void PauseTransformFeedback() = 0;
virtual void PixelStorei(GLenum pname, GLint param) = 0;
virtual void PolygonOffset(GLfloat factor, GLfloat units) = 0;
virtual void ReadBuffer(GLenum src) = 0;
virtual void ReadPixels(GLint x,
                        GLint y,
                        GLsizei width,
                        GLsizei height,
                        GLenum format,
                        GLenum type,
                        void* pixels) = 0;
virtual void ReleaseShaderCompiler() = 0;
virtual void RenderbufferStorage(GLenum target,
                                 GLenum internalformat,
                                 GLsizei width,
                                 GLsizei height) = 0;
virtual void ResumeTransformFeedback() = 0;
virtual void SampleCoverage(GLclampf value, GLboolean invert) = 0;
virtual void SamplerParameterf(GLuint sampler, GLenum pname, GLfloat param) = 0;
virtual void SamplerParameterfv(GLuint sampler,
                                GLenum pname,
                                const GLfloat* params) = 0;
virtual void SamplerParameteri(GLuint sampler, GLenum pname, GLint param) = 0;
virtual void SamplerParameteriv(GLuint sampler,
                                GLenum pname,
                                const GLint* params) = 0;
virtual void Scissor(GLint x, GLint y, GLsizei width, GLsizei height) = 0;
virtual void ShaderBinary(GLsizei n,
                          const GLuint* shaders,
                          GLenum binaryformat,
                          const void* binary,
                          GLsizei length) = 0;
virtual void ShaderSource(GLuint shader,
                          GLsizei count,
                          const GLchar* const* str,
                          const GLint* length) = 0;
virtual void ShallowFinishCHROMIUM() = 0;
virtual void ShallowFlushCHROMIUM() = 0;
virtual void OrderingBarrierCHROMIUM() = 0;
virtual void StencilFunc(GLenum func, GLint ref, GLuint mask) = 0;
virtual void StencilFuncSeparate(GLenum face,
                                 GLenum func,
                                 GLint ref,
                                 GLuint mask) = 0;
virtual void StencilMask(GLuint mask) = 0;
virtual void StencilMaskSeparate(GLenum face, GLuint mask) = 0;
virtual void StencilOp(GLenum fail, GLenum zfail, GLenum zpass) = 0;
virtual void StencilOpSeparate(GLenum face,
                               GLenum fail,
                               GLenum zfail,
                               GLenum zpass) = 0;
virtual void TexImage2D(GLenum target,
                        GLint level,
                        GLint internalformat,
                        GLsizei width,
                        GLsizei height,
                        GLint border,
                        GLenum format,
                        GLenum type,
                        const void* pixels) = 0;
virtual void TexImage3D(GLenum target,
                        GLint level,
                        GLint internalformat,
                        GLsizei width,
                        GLsizei height,
                        GLsizei depth,
                        GLint border,
                        GLenum format,
                        GLenum type,
                        const void* pixels) = 0;
virtual void TexParameterf(GLenum target, GLenum pname, GLfloat param) = 0;
virtual void TexParameterfv(GLenum target,
                            GLenum pname,
                            const GLfloat* params) = 0;
virtual void TexParameteri(GLenum target, GLenum pname, GLint param) = 0;
virtual void TexParameteriv(GLenum target,
                            GLenum pname,
                            const GLint* params) = 0;
virtual void TexStorage3D(GLenum target,
                          GLsizei levels,
                          GLenum internalFormat,
                          GLsizei width,
                          GLsizei height,
                          GLsizei depth) = 0;
virtual void TexSubImage2D(GLenum target,
                           GLint level,
                           GLint xoffset,
                           GLint yoffset,
                           GLsizei width,
                           GLsizei height,
                           GLenum format,
                           GLenum type,
                           const void* pixels) = 0;
virtual void TexSubImage3D(GLenum target,
                           GLint level,
                           GLint xoffset,
                           GLint yoffset,
                           GLint zoffset,
                           GLsizei width,
                           GLsizei height,
                           GLsizei depth,
                           GLenum format,
                           GLenum type,
                           const void* pixels) = 0;
virtual void TransformFeedbackVaryings(GLuint program,
                                       GLsizei count,
                                       const char* const* varyings,
                                       GLenum buffermode) = 0;
virtual void Uniform1f(GLint location, GLfloat x) = 0;
virtual void Uniform1fv(GLint location, GLsizei count, const GLfloat* v) = 0;
virtual void Uniform1i(GLint location, GLint x) = 0;
virtual void Uniform1iv(GLint location, GLsizei count, const GLint* v) = 0;
virtual void Uniform1ui(GLint location, GLuint x) = 0;
virtual void Uniform1uiv(GLint location, GLsizei count, const GLuint* v) = 0;
virtual void Uniform2f(GLint location, GLfloat x, GLfloat y) = 0;
virtual void Uniform2fv(GLint location, GLsizei count, const GLfloat* v) = 0;
virtual void Uniform2i(GLint location, GLint x, GLint y) = 0;
virtual void Uniform2iv(GLint location, GLsizei count, const GLint* v) = 0;
virtual void Uniform2ui(GLint location, GLuint x, GLuint y) = 0;
virtual void Uniform2uiv(GLint location, GLsizei count, const GLuint* v) = 0;
virtual void Uniform3f(GLint location, GLfloat x, GLfloat y, GLfloat z) = 0;
virtual void Uniform3fv(GLint location, GLsizei count, const GLfloat* v) = 0;
virtual void Uniform3i(GLint location, GLint x, GLint y, GLint z) = 0;
virtual void Uniform3iv(GLint location, GLsizei count, const GLint* v) = 0;
virtual void Uniform3ui(GLint location, GLuint x, GLuint y, GLuint z) = 0;
virtual void Uniform3uiv(GLint location, GLsizei count, const GLuint* v) = 0;
virtual void Uniform4f(GLint location,
                       GLfloat x,
                       GLfloat y,
                       GLfloat z,
                       GLfloat w) = 0;
virtual void Uniform4fv(GLint location, GLsizei count, const GLfloat* v) = 0;
virtual void Uniform4i(GLint location, GLint x, GLint y, GLint z, GLint w) = 0;
virtual void Uniform4iv(GLint location, GLsizei count, const GLint* v) = 0;
virtual void Uniform4ui(GLint location,
                        GLuint x,
                        GLuint y,
                        GLuint z,
                        GLuint w) = 0;
virtual void Uniform4uiv(GLint location, GLsizei count, const GLuint* v) = 0;
virtual void UniformBlockBinding(GLuint program,
                                 GLuint index,
                                 GLuint binding) = 0;
virtual void UniformMatrix2fv(GLint location,
                              GLsizei count,
                              GLboolean transpose,
                              const GLfloat* value) = 0;
virtual void UniformMatrix2x3fv(GLint location,
                                GLsizei count,
                                GLboolean transpose,
                                const GLfloat* value) = 0;
virtual void UniformMatrix2x4fv(GLint location,
                                GLsizei count,
                                GLboolean transpose,
                                const GLfloat* value) = 0;
virtual void UniformMatrix3fv(GLint location,
                              GLsizei count,
                              GLboolean transpose,
                              const GLfloat* value) = 0;
virtual void UniformMatrix3x2fv(GLint location,
                                GLsizei count,
                                GLboolean transpose,
                                const GLfloat* value) = 0;
virtual void UniformMatrix3x4fv(GLint location,
                                GLsizei count,
                                GLboolean transpose,
                                const GLfloat* value) = 0;
virtual void UniformMatrix4fv(GLint location,
                              GLsizei count,
                              GLboolean transpose,
                              const GLfloat* value) = 0;
virtual void UniformMatrix4x2fv(GLint location,
                                GLsizei count,
                                GLboolean transpose,
                                const GLfloat* value) = 0;
virtual void UniformMatrix4x3fv(GLint location,
                                GLsizei count,
                                GLboolean transpose,
                                const GLfloat* value) = 0;
virtual void UseProgram(GLuint program) = 0;
virtual void ValidateProgram(GLuint program) = 0;
virtual void VertexAttrib1f(GLuint indx, GLfloat x) = 0;
virtual void VertexAttrib1fv(GLuint indx, const GLfloat* values) = 0;
virtual void VertexAttrib2f(GLuint indx, GLfloat x, GLfloat y) = 0;
virtual void VertexAttrib2fv(GLuint indx, const GLfloat* values) = 0;
virtual void VertexAttrib3f(GLuint indx, GLfloat x, GLfloat y, GLfloat z) = 0;
virtual void VertexAttrib3fv(GLuint indx, const GLfloat* values) = 0;
virtual void VertexAttrib4f(GLuint indx,
                            GLfloat x,
                            GLfloat y,
                            GLfloat z,
                            GLfloat w) = 0;
virtual void VertexAttrib4fv(GLuint indx, const GLfloat* values) = 0;
virtual void VertexAttribI4i(GLuint indx,
                             GLint x,
                             GLint y,
                             GLint z,
                             GLint w) = 0;
virtual void VertexAttribI4iv(GLuint indx, const GLint* values) = 0;
virtual void VertexAttribI4ui(GLuint indx,
                              GLuint x,
                              GLuint y,
                              GLuint z,
                              GLuint w) = 0;
virtual void VertexAttribI4uiv(GLuint indx, const GLuint* values) = 0;
virtual void VertexAttribIPointer(GLuint indx,
                                  GLint size,
                                  GLenum type,
                                  GLsizei stride,
                                  const void* ptr) = 0;
virtual void VertexAttribPointer(GLuint indx,
                                 GLint size,
                                 GLenum type,
                                 GLboolean normalized,
                                 GLsizei stride,
                                 const void* ptr) = 0;
virtual void Viewport(GLint x, GLint y, GLsizei width, GLsizei height) = 0;
virtual void WaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout) = 0;
virtual void BlitFramebufferCHROMIUM(GLint srcX0,
                                     GLint srcY0,
                                     GLint srcX1,
                                     GLint srcY1,
                                     GLint dstX0,
                                     GLint dstY0,
                                     GLint dstX1,
                                     GLint dstY1,
                                     GLbitfield mask,
                                     GLenum filter) = 0;
virtual void RenderbufferStorageMultisampleCHROMIUM(GLenum target,
                                                    GLsizei samples,
                                                    GLenum internalformat,
                                                    GLsizei width,
                                                    GLsizei height) = 0;
virtual void RenderbufferStorageMultisampleEXT(GLenum target,
                                               GLsizei samples,
                                               GLenum internalformat,
                                               GLsizei width,
                                               GLsizei height) = 0;
virtual void FramebufferTexture2DMultisampleEXT(GLenum target,
                                                GLenum attachment,
                                                GLenum textarget,
                                                GLuint texture,
                                                GLint level,
                                                GLsizei samples) = 0;
virtual void TexStorage2DEXT(GLenum target,
                             GLsizei levels,
                             GLenum internalFormat,
                             GLsizei width,
                             GLsizei height) = 0;
virtual void GenQueriesEXT(GLsizei n, GLuint* queries) = 0;
virtual void DeleteQueriesEXT(GLsizei n, const GLuint* queries) = 0;
virtual GLboolean IsQueryEXT(GLuint id) = 0;
virtual void BeginQueryEXT(GLenum target, GLuint id) = 0;
virtual void BeginTransformFeedback(GLenum primitivemode) = 0;
virtual void EndQueryEXT(GLenum target) = 0;
virtual void EndTransformFeedback() = 0;
virtual void GetQueryivEXT(GLenum target, GLenum pname, GLint* params) = 0;
virtual void GetQueryObjectuivEXT(GLuint id, GLenum pname, GLuint* params) = 0;
virtual void InsertEventMarkerEXT(GLsizei length, const GLchar* marker) = 0;
virtual void PushGroupMarkerEXT(GLsizei length, const GLchar* marker) = 0;
virtual void PopGroupMarkerEXT() = 0;
virtual void GenVertexArraysOES(GLsizei n, GLuint* arrays) = 0;
virtual void DeleteVertexArraysOES(GLsizei n, const GLuint* arrays) = 0;
virtual GLboolean IsVertexArrayOES(GLuint array) = 0;
virtual void BindVertexArrayOES(GLuint array) = 0;
virtual void SwapBuffers() = 0;
virtual GLuint GetMaxValueInBufferCHROMIUM(GLuint buffer_id,
                                           GLsizei count,
                                           GLenum type,
                                           GLuint offset) = 0;
virtual GLboolean EnableFeatureCHROMIUM(const char* feature) = 0;
virtual void* MapBufferCHROMIUM(GLuint target, GLenum access) = 0;
virtual GLboolean UnmapBufferCHROMIUM(GLuint target) = 0;
virtual void* MapBufferSubDataCHROMIUM(GLuint target,
                                       GLintptr offset,
                                       GLsizeiptr size,
                                       GLenum access) = 0;
virtual void UnmapBufferSubDataCHROMIUM(const void* mem) = 0;
virtual void* MapBufferRange(GLenum target,
                             GLintptr offset,
                             GLsizeiptr size,
                             GLbitfield access) = 0;
virtual GLboolean UnmapBuffer(GLenum target) = 0;
virtual void* MapTexSubImage2DCHROMIUM(GLenum target,
                                       GLint level,
                                       GLint xoffset,
                                       GLint yoffset,
                                       GLsizei width,
                                       GLsizei height,
                                       GLenum format,
                                       GLenum type,
                                       GLenum access) = 0;
virtual void UnmapTexSubImage2DCHROMIUM(const void* mem) = 0;
virtual void ResizeCHROMIUM(GLuint width,
                            GLuint height,
                            GLfloat scale_factor) = 0;
virtual const GLchar* GetRequestableExtensionsCHROMIUM() = 0;
virtual void RequestExtensionCHROMIUM(const char* extension) = 0;
virtual void RateLimitOffscreenContextCHROMIUM() = 0;
virtual void GetProgramInfoCHROMIUM(GLuint program,
                                    GLsizei bufsize,
                                    GLsizei* size,
                                    void* info) = 0;
virtual void GetUniformBlocksCHROMIUM(GLuint program,
                                      GLsizei bufsize,
                                      GLsizei* size,
                                      void* info) = 0;
virtual void GetTransformFeedbackVaryingsCHROMIUM(GLuint program,
                                                  GLsizei bufsize,
                                                  GLsizei* size,
                                                  void* info) = 0;
virtual void GetUniformsES3CHROMIUM(GLuint program,
                                    GLsizei bufsize,
                                    GLsizei* size,
                                    void* info) = 0;
virtual GLuint CreateStreamTextureCHROMIUM(GLuint texture) = 0;
virtual GLuint CreateImageCHROMIUM(ClientBuffer buffer,
                                   GLsizei width,
                                   GLsizei height,
                                   GLenum internalformat) = 0;
virtual void DestroyImageCHROMIUM(GLuint image_id) = 0;
virtual GLuint CreateGpuMemoryBufferImageCHROMIUM(GLsizei width,
                                                  GLsizei height,
                                                  GLenum internalformat,
                                                  GLenum usage) = 0;
virtual void GetTranslatedShaderSourceANGLE(GLuint shader,
                                            GLsizei bufsize,
                                            GLsizei* length,
                                            char* source) = 0;
virtual void PostSubBufferCHROMIUM(GLint x,
                                   GLint y,
                                   GLint width,
                                   GLint height) = 0;
virtual void TexImageIOSurface2DCHROMIUM(GLenum target,
                                         GLsizei width,
                                         GLsizei height,
                                         GLuint ioSurfaceId,
                                         GLuint plane) = 0;
virtual void CopyTextureCHROMIUM(GLenum target,
                                 GLenum source_id,
                                 GLenum dest_id,
                                 GLint internalformat,
                                 GLenum dest_type) = 0;
virtual void CopySubTextureCHROMIUM(GLenum target,
                                    GLenum source_id,
                                    GLenum dest_id,
                                    GLint xoffset,
                                    GLint yoffset) = 0;
virtual void DrawArraysInstancedANGLE(GLenum mode,
                                      GLint first,
                                      GLsizei count,
                                      GLsizei primcount) = 0;
virtual void DrawElementsInstancedANGLE(GLenum mode,
                                        GLsizei count,
                                        GLenum type,
                                        const void* indices,
                                        GLsizei primcount) = 0;
virtual void VertexAttribDivisorANGLE(GLuint index, GLuint divisor) = 0;
virtual void GenMailboxCHROMIUM(GLbyte* mailbox) = 0;
virtual void ProduceTextureCHROMIUM(GLenum target, const GLbyte* mailbox) = 0;
virtual void ProduceTextureDirectCHROMIUM(GLuint texture,
                                          GLenum target,
                                          const GLbyte* mailbox) = 0;
virtual void ConsumeTextureCHROMIUM(GLenum target, const GLbyte* mailbox) = 0;
virtual GLuint CreateAndConsumeTextureCHROMIUM(GLenum target,
                                               const GLbyte* mailbox) = 0;
virtual void BindUniformLocationCHROMIUM(GLuint program,
                                         GLint location,
                                         const char* name) = 0;
virtual void GenValuebuffersCHROMIUM(GLsizei n, GLuint* buffers) = 0;
virtual void DeleteValuebuffersCHROMIUM(GLsizei n,
                                        const GLuint* valuebuffers) = 0;
virtual GLboolean IsValuebufferCHROMIUM(GLuint valuebuffer) = 0;
virtual void BindValuebufferCHROMIUM(GLenum target, GLuint valuebuffer) = 0;
virtual void SubscribeValueCHROMIUM(GLenum target, GLenum subscription) = 0;
virtual void PopulateSubscribedValuesCHROMIUM(GLenum target) = 0;
virtual void UniformValuebufferCHROMIUM(GLint location,
                                        GLenum target,
                                        GLenum subscription) = 0;
virtual void BindTexImage2DCHROMIUM(GLenum target, GLint imageId) = 0;
virtual void ReleaseTexImage2DCHROMIUM(GLenum target, GLint imageId) = 0;
virtual void TraceBeginCHROMIUM(const char* category_name,
                                const char* trace_name) = 0;
virtual void TraceEndCHROMIUM() = 0;
virtual void AsyncTexSubImage2DCHROMIUM(GLenum target,
                                        GLint level,
                                        GLint xoffset,
                                        GLint yoffset,
                                        GLsizei width,
                                        GLsizei height,
                                        GLenum format,
                                        GLenum type,
                                        const void* data) = 0;
virtual void AsyncTexImage2DCHROMIUM(GLenum target,
                                     GLint level,
                                     GLenum internalformat,
                                     GLsizei width,
                                     GLsizei height,
                                     GLint border,
                                     GLenum format,
                                     GLenum type,
                                     const void* pixels) = 0;
virtual void WaitAsyncTexImage2DCHROMIUM(GLenum target) = 0;
virtual void WaitAllAsyncTexImage2DCHROMIUM() = 0;
virtual void DiscardFramebufferEXT(GLenum target,
                                   GLsizei count,
                                   const GLenum* attachments) = 0;
virtual void LoseContextCHROMIUM(GLenum current, GLenum other) = 0;
virtual GLuint InsertSyncPointCHROMIUM() = 0;
virtual void WaitSyncPointCHROMIUM(GLuint sync_point) = 0;
virtual void DrawBuffersEXT(GLsizei count, const GLenum* bufs) = 0;
virtual void DiscardBackbufferCHROMIUM() = 0;
virtual void ScheduleOverlayPlaneCHROMIUM(GLint plane_z_order,
                                          GLenum plane_transform,
                                          GLuint overlay_texture_id,
                                          GLint bounds_x,
                                          GLint bounds_y,
                                          GLint bounds_width,
                                          GLint bounds_height,
                                          GLfloat uv_x,
                                          GLfloat uv_y,
                                          GLfloat uv_width,
                                          GLfloat uv_height) = 0;
virtual void SwapInterval(GLint interval) = 0;
virtual void MatrixLoadfCHROMIUM(GLenum matrixMode, const GLfloat* m) = 0;
virtual void MatrixLoadIdentityCHROMIUM(GLenum matrixMode) = 0;
virtual void BlendBarrierKHR() = 0;
#endif  // GPU_COMMAND_BUFFER_CLIENT_GLES2_INTERFACE_AUTOGEN_H_
