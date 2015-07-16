// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is auto-generated from
// ui/gl/generate_bindings.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

MOCK_METHOD1(ActiveTexture, void(GLenum texture));
MOCK_METHOD2(AttachShader, void(GLuint program, GLuint shader));
MOCK_METHOD2(BeginQuery, void(GLenum target, GLuint id));
MOCK_METHOD1(BeginTransformFeedback, void(GLenum primitiveMode));
MOCK_METHOD3(BindAttribLocation,
             void(GLuint program, GLuint index, const char* name));
MOCK_METHOD2(BindBuffer, void(GLenum target, GLuint buffer));
MOCK_METHOD3(BindBufferBase, void(GLenum target, GLuint index, GLuint buffer));
MOCK_METHOD5(BindBufferRange,
             void(GLenum target,
                  GLuint index,
                  GLuint buffer,
                  GLintptr offset,
                  GLsizeiptr size));
MOCK_METHOD3(BindFragDataLocation,
             void(GLuint program, GLuint colorNumber, const char* name));
MOCK_METHOD4(
    BindFragDataLocationIndexed,
    void(GLuint program, GLuint colorNumber, GLuint index, const char* name));
MOCK_METHOD2(BindFramebufferEXT, void(GLenum target, GLuint framebuffer));
MOCK_METHOD2(BindRenderbufferEXT, void(GLenum target, GLuint renderbuffer));
MOCK_METHOD2(BindSampler, void(GLuint unit, GLuint sampler));
MOCK_METHOD2(BindTexture, void(GLenum target, GLuint texture));
MOCK_METHOD2(BindTransformFeedback, void(GLenum target, GLuint id));
MOCK_METHOD1(BindVertexArrayOES, void(GLuint array));
MOCK_METHOD0(BlendBarrierKHR, void());
MOCK_METHOD4(BlendColor,
             void(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha));
MOCK_METHOD1(BlendEquation, void(GLenum mode));
MOCK_METHOD2(BlendEquationSeparate, void(GLenum modeRGB, GLenum modeAlpha));
MOCK_METHOD2(BlendFunc, void(GLenum sfactor, GLenum dfactor));
MOCK_METHOD4(
    BlendFuncSeparate,
    void(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha));
MOCK_METHOD10(BlitFramebuffer,
              void(GLint srcX0,
                   GLint srcY0,
                   GLint srcX1,
                   GLint srcY1,
                   GLint dstX0,
                   GLint dstY0,
                   GLint dstX1,
                   GLint dstY1,
                   GLbitfield mask,
                   GLenum filter));
MOCK_METHOD10(BlitFramebufferANGLE,
              void(GLint srcX0,
                   GLint srcY0,
                   GLint srcX1,
                   GLint srcY1,
                   GLint dstX0,
                   GLint dstY0,
                   GLint dstX1,
                   GLint dstY1,
                   GLbitfield mask,
                   GLenum filter));
MOCK_METHOD10(BlitFramebufferEXT,
              void(GLint srcX0,
                   GLint srcY0,
                   GLint srcX1,
                   GLint srcY1,
                   GLint dstX0,
                   GLint dstY0,
                   GLint dstX1,
                   GLint dstY1,
                   GLbitfield mask,
                   GLenum filter));
MOCK_METHOD4(
    BufferData,
    void(GLenum target, GLsizeiptr size, const void* data, GLenum usage));
MOCK_METHOD4(
    BufferSubData,
    void(GLenum target, GLintptr offset, GLsizeiptr size, const void* data));
MOCK_METHOD1(CheckFramebufferStatusEXT, GLenum(GLenum target));
MOCK_METHOD1(Clear, void(GLbitfield mask));
MOCK_METHOD4(
    ClearBufferfi,
    void(GLenum buffer, GLint drawbuffer, const GLfloat depth, GLint stencil));
MOCK_METHOD3(ClearBufferfv,
             void(GLenum buffer, GLint drawbuffer, const GLfloat* value));
MOCK_METHOD3(ClearBufferiv,
             void(GLenum buffer, GLint drawbuffer, const GLint* value));
MOCK_METHOD3(ClearBufferuiv,
             void(GLenum buffer, GLint drawbuffer, const GLuint* value));
MOCK_METHOD4(ClearColor,
             void(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha));
MOCK_METHOD1(ClearDepth, void(GLclampd depth));
MOCK_METHOD1(ClearDepthf, void(GLclampf depth));
MOCK_METHOD1(ClearStencil, void(GLint s));
MOCK_METHOD3(ClientWaitSync,
             GLenum(GLsync sync, GLbitfield flags, GLuint64 timeout));
MOCK_METHOD4(
    ColorMask,
    void(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha));
MOCK_METHOD1(CompileShader, void(GLuint shader));
MOCK_METHOD8(CompressedTexImage2D,
             void(GLenum target,
                  GLint level,
                  GLenum internalformat,
                  GLsizei width,
                  GLsizei height,
                  GLint border,
                  GLsizei imageSize,
                  const void* data));
MOCK_METHOD9(CompressedTexImage3D,
             void(GLenum target,
                  GLint level,
                  GLenum internalformat,
                  GLsizei width,
                  GLsizei height,
                  GLsizei depth,
                  GLint border,
                  GLsizei imageSize,
                  const void* data));
MOCK_METHOD9(CompressedTexSubImage2D,
             void(GLenum target,
                  GLint level,
                  GLint xoffset,
                  GLint yoffset,
                  GLsizei width,
                  GLsizei height,
                  GLenum format,
                  GLsizei imageSize,
                  const void* data));
MOCK_METHOD5(CopyBufferSubData,
             void(GLenum readTarget,
                  GLenum writeTarget,
                  GLintptr readOffset,
                  GLintptr writeOffset,
                  GLsizeiptr size));
MOCK_METHOD8(CopyTexImage2D,
             void(GLenum target,
                  GLint level,
                  GLenum internalformat,
                  GLint x,
                  GLint y,
                  GLsizei width,
                  GLsizei height,
                  GLint border));
MOCK_METHOD8(CopyTexSubImage2D,
             void(GLenum target,
                  GLint level,
                  GLint xoffset,
                  GLint yoffset,
                  GLint x,
                  GLint y,
                  GLsizei width,
                  GLsizei height));
MOCK_METHOD9(CopyTexSubImage3D,
             void(GLenum target,
                  GLint level,
                  GLint xoffset,
                  GLint yoffset,
                  GLint zoffset,
                  GLint x,
                  GLint y,
                  GLsizei width,
                  GLsizei height));
MOCK_METHOD0(CreateProgram, GLuint());
MOCK_METHOD1(CreateShader, GLuint(GLenum type));
MOCK_METHOD1(CullFace, void(GLenum mode));
MOCK_METHOD2(DeleteBuffersARB, void(GLsizei n, const GLuint* buffers));
MOCK_METHOD2(DeleteFencesAPPLE, void(GLsizei n, const GLuint* fences));
MOCK_METHOD2(DeleteFencesNV, void(GLsizei n, const GLuint* fences));
MOCK_METHOD2(DeleteFramebuffersEXT,
             void(GLsizei n, const GLuint* framebuffers));
MOCK_METHOD1(DeleteProgram, void(GLuint program));
MOCK_METHOD2(DeleteQueries, void(GLsizei n, const GLuint* ids));
MOCK_METHOD2(DeleteRenderbuffersEXT,
             void(GLsizei n, const GLuint* renderbuffers));
MOCK_METHOD2(DeleteSamplers, void(GLsizei n, const GLuint* samplers));
MOCK_METHOD1(DeleteShader, void(GLuint shader));
MOCK_METHOD1(DeleteSync, void(GLsync sync));
MOCK_METHOD2(DeleteTextures, void(GLsizei n, const GLuint* textures));
MOCK_METHOD2(DeleteTransformFeedbacks, void(GLsizei n, const GLuint* ids));
MOCK_METHOD2(DeleteVertexArraysOES, void(GLsizei n, const GLuint* arrays));
MOCK_METHOD1(DepthFunc, void(GLenum func));
MOCK_METHOD1(DepthMask, void(GLboolean flag));
MOCK_METHOD2(DepthRange, void(GLclampd zNear, GLclampd zFar));
MOCK_METHOD2(DepthRangef, void(GLclampf zNear, GLclampf zFar));
MOCK_METHOD2(DetachShader, void(GLuint program, GLuint shader));
MOCK_METHOD1(Disable, void(GLenum cap));
MOCK_METHOD1(DisableVertexAttribArray, void(GLuint index));
MOCK_METHOD3(DiscardFramebufferEXT,
             void(GLenum target,
                  GLsizei numAttachments,
                  const GLenum* attachments));
MOCK_METHOD3(DrawArrays, void(GLenum mode, GLint first, GLsizei count));
MOCK_METHOD4(DrawArraysInstancedANGLE,
             void(GLenum mode, GLint first, GLsizei count, GLsizei primcount));
MOCK_METHOD1(DrawBuffer, void(GLenum mode));
MOCK_METHOD2(DrawBuffersARB, void(GLsizei n, const GLenum* bufs));
MOCK_METHOD4(
    DrawElements,
    void(GLenum mode, GLsizei count, GLenum type, const void* indices));
MOCK_METHOD5(DrawElementsInstancedANGLE,
             void(GLenum mode,
                  GLsizei count,
                  GLenum type,
                  const void* indices,
                  GLsizei primcount));
MOCK_METHOD6(DrawRangeElements,
             void(GLenum mode,
                  GLuint start,
                  GLuint end,
                  GLsizei count,
                  GLenum type,
                  const void* indices));
MOCK_METHOD2(EGLImageTargetRenderbufferStorageOES,
             void(GLenum target, GLeglImageOES image));
MOCK_METHOD2(EGLImageTargetTexture2DOES,
             void(GLenum target, GLeglImageOES image));
MOCK_METHOD1(Enable, void(GLenum cap));
MOCK_METHOD1(EnableVertexAttribArray, void(GLuint index));
MOCK_METHOD1(EndQuery, void(GLenum target));
MOCK_METHOD0(EndTransformFeedback, void());
MOCK_METHOD2(FenceSync, GLsync(GLenum condition, GLbitfield flags));
MOCK_METHOD0(Finish, void());
MOCK_METHOD1(FinishFenceAPPLE, void(GLuint fence));
MOCK_METHOD1(FinishFenceNV, void(GLuint fence));
MOCK_METHOD0(Flush, void());
MOCK_METHOD3(FlushMappedBufferRange,
             void(GLenum target, GLintptr offset, GLsizeiptr length));
MOCK_METHOD4(FramebufferRenderbufferEXT,
             void(GLenum target,
                  GLenum attachment,
                  GLenum renderbuffertarget,
                  GLuint renderbuffer));
MOCK_METHOD5(FramebufferTexture2DEXT,
             void(GLenum target,
                  GLenum attachment,
                  GLenum textarget,
                  GLuint texture,
                  GLint level));
MOCK_METHOD6(FramebufferTexture2DMultisampleEXT,
             void(GLenum target,
                  GLenum attachment,
                  GLenum textarget,
                  GLuint texture,
                  GLint level,
                  GLsizei samples));
MOCK_METHOD6(FramebufferTexture2DMultisampleIMG,
             void(GLenum target,
                  GLenum attachment,
                  GLenum textarget,
                  GLuint texture,
                  GLint level,
                  GLsizei samples));
MOCK_METHOD5(FramebufferTextureLayer,
             void(GLenum target,
                  GLenum attachment,
                  GLuint texture,
                  GLint level,
                  GLint layer));
MOCK_METHOD1(FrontFace, void(GLenum mode));
MOCK_METHOD2(GenBuffersARB, void(GLsizei n, GLuint* buffers));
MOCK_METHOD1(GenerateMipmapEXT, void(GLenum target));
MOCK_METHOD2(GenFencesAPPLE, void(GLsizei n, GLuint* fences));
MOCK_METHOD2(GenFencesNV, void(GLsizei n, GLuint* fences));
MOCK_METHOD2(GenFramebuffersEXT, void(GLsizei n, GLuint* framebuffers));
MOCK_METHOD2(GenQueries, void(GLsizei n, GLuint* ids));
MOCK_METHOD2(GenRenderbuffersEXT, void(GLsizei n, GLuint* renderbuffers));
MOCK_METHOD2(GenSamplers, void(GLsizei n, GLuint* samplers));
MOCK_METHOD2(GenTextures, void(GLsizei n, GLuint* textures));
MOCK_METHOD2(GenTransformFeedbacks, void(GLsizei n, GLuint* ids));
MOCK_METHOD2(GenVertexArraysOES, void(GLsizei n, GLuint* arrays));
MOCK_METHOD7(GetActiveAttrib,
             void(GLuint program,
                  GLuint index,
                  GLsizei bufsize,
                  GLsizei* length,
                  GLint* size,
                  GLenum* type,
                  char* name));
MOCK_METHOD7(GetActiveUniform,
             void(GLuint program,
                  GLuint index,
                  GLsizei bufsize,
                  GLsizei* length,
                  GLint* size,
                  GLenum* type,
                  char* name));
MOCK_METHOD4(GetActiveUniformBlockiv,
             void(GLuint program,
                  GLuint uniformBlockIndex,
                  GLenum pname,
                  GLint* params));
MOCK_METHOD5(GetActiveUniformBlockName,
             void(GLuint program,
                  GLuint uniformBlockIndex,
                  GLsizei bufSize,
                  GLsizei* length,
                  char* uniformBlockName));
MOCK_METHOD5(GetActiveUniformsiv,
             void(GLuint program,
                  GLsizei uniformCount,
                  const GLuint* uniformIndices,
                  GLenum pname,
                  GLint* params));
MOCK_METHOD4(
    GetAttachedShaders,
    void(GLuint program, GLsizei maxcount, GLsizei* count, GLuint* shaders));
MOCK_METHOD2(GetAttribLocation, GLint(GLuint program, const char* name));
MOCK_METHOD2(GetBooleanv, void(GLenum pname, GLboolean* params));
MOCK_METHOD3(GetBufferParameteriv,
             void(GLenum target, GLenum pname, GLint* params));
MOCK_METHOD0(GetError, GLenum());
MOCK_METHOD3(GetFenceivNV, void(GLuint fence, GLenum pname, GLint* params));
MOCK_METHOD2(GetFloatv, void(GLenum pname, GLfloat* params));
MOCK_METHOD2(GetFragDataLocation, GLint(GLuint program, const char* name));
MOCK_METHOD4(
    GetFramebufferAttachmentParameterivEXT,
    void(GLenum target, GLenum attachment, GLenum pname, GLint* params));
MOCK_METHOD0(GetGraphicsResetStatusARB, GLenum());
MOCK_METHOD3(GetInteger64i_v, void(GLenum target, GLuint index, GLint64* data));
MOCK_METHOD2(GetInteger64v, void(GLenum pname, GLint64* params));
MOCK_METHOD3(GetIntegeri_v, void(GLenum target, GLuint index, GLint* data));
MOCK_METHOD2(GetIntegerv, void(GLenum pname, GLint* params));
MOCK_METHOD5(GetInternalformativ,
             void(GLenum target,
                  GLenum internalformat,
                  GLenum pname,
                  GLsizei bufSize,
                  GLint* params));
MOCK_METHOD5(GetProgramBinary,
             void(GLuint program,
                  GLsizei bufSize,
                  GLsizei* length,
                  GLenum* binaryFormat,
                  GLvoid* binary));
MOCK_METHOD4(
    GetProgramInfoLog,
    void(GLuint program, GLsizei bufsize, GLsizei* length, char* infolog));
MOCK_METHOD3(GetProgramiv, void(GLuint program, GLenum pname, GLint* params));
MOCK_METHOD3(GetProgramResourceLocation,
             GLint(GLuint program, GLenum programInterface, const char* name));
MOCK_METHOD3(GetQueryiv, void(GLenum target, GLenum pname, GLint* params));
MOCK_METHOD3(GetQueryObjecti64v,
             void(GLuint id, GLenum pname, GLint64* params));
MOCK_METHOD3(GetQueryObjectiv, void(GLuint id, GLenum pname, GLint* params));
MOCK_METHOD3(GetQueryObjectui64v,
             void(GLuint id, GLenum pname, GLuint64* params));
MOCK_METHOD3(GetQueryObjectuiv, void(GLuint id, GLenum pname, GLuint* params));
MOCK_METHOD3(GetRenderbufferParameterivEXT,
             void(GLenum target, GLenum pname, GLint* params));
MOCK_METHOD3(GetSamplerParameterfv,
             void(GLuint sampler, GLenum pname, GLfloat* params));
MOCK_METHOD3(GetSamplerParameteriv,
             void(GLuint sampler, GLenum pname, GLint* params));
MOCK_METHOD4(
    GetShaderInfoLog,
    void(GLuint shader, GLsizei bufsize, GLsizei* length, char* infolog));
MOCK_METHOD3(GetShaderiv, void(GLuint shader, GLenum pname, GLint* params));
MOCK_METHOD4(GetShaderPrecisionFormat,
             void(GLenum shadertype,
                  GLenum precisiontype,
                  GLint* range,
                  GLint* precision));
MOCK_METHOD4(
    GetShaderSource,
    void(GLuint shader, GLsizei bufsize, GLsizei* length, char* source));
MOCK_METHOD1(GetString, const GLubyte*(GLenum name));
MOCK_METHOD2(GetStringi, const GLubyte*(GLenum name, GLuint index));
MOCK_METHOD5(GetSynciv,
             void(GLsync sync,
                  GLenum pname,
                  GLsizei bufSize,
                  GLsizei* length,
                  GLint* values));
MOCK_METHOD4(GetTexLevelParameterfv,
             void(GLenum target, GLint level, GLenum pname, GLfloat* params));
MOCK_METHOD4(GetTexLevelParameteriv,
             void(GLenum target, GLint level, GLenum pname, GLint* params));
MOCK_METHOD3(GetTexParameterfv,
             void(GLenum target, GLenum pname, GLfloat* params));
MOCK_METHOD3(GetTexParameteriv,
             void(GLenum target, GLenum pname, GLint* params));
MOCK_METHOD7(GetTransformFeedbackVarying,
             void(GLuint program,
                  GLuint index,
                  GLsizei bufSize,
                  GLsizei* length,
                  GLsizei* size,
                  GLenum* type,
                  char* name));
MOCK_METHOD4(
    GetTranslatedShaderSourceANGLE,
    void(GLuint shader, GLsizei bufsize, GLsizei* length, char* source));
MOCK_METHOD2(GetUniformBlockIndex,
             GLuint(GLuint program, const char* uniformBlockName));
MOCK_METHOD3(GetUniformfv,
             void(GLuint program, GLint location, GLfloat* params));
MOCK_METHOD4(GetUniformIndices,
             void(GLuint program,
                  GLsizei uniformCount,
                  const char* const* uniformNames,
                  GLuint* uniformIndices));
MOCK_METHOD3(GetUniformiv, void(GLuint program, GLint location, GLint* params));
MOCK_METHOD2(GetUniformLocation, GLint(GLuint program, const char* name));
MOCK_METHOD3(GetVertexAttribfv,
             void(GLuint index, GLenum pname, GLfloat* params));
MOCK_METHOD3(GetVertexAttribiv,
             void(GLuint index, GLenum pname, GLint* params));
MOCK_METHOD3(GetVertexAttribPointerv,
             void(GLuint index, GLenum pname, void** pointer));
MOCK_METHOD2(Hint, void(GLenum target, GLenum mode));
MOCK_METHOD2(InsertEventMarkerEXT, void(GLsizei length, const char* marker));
MOCK_METHOD3(InvalidateFramebuffer,
             void(GLenum target,
                  GLsizei numAttachments,
                  const GLenum* attachments));
MOCK_METHOD7(InvalidateSubFramebuffer,
             void(GLenum target,
                  GLsizei numAttachments,
                  const GLenum* attachments,
                  GLint x,
                  GLint y,
                  GLint width,
                  GLint height));
MOCK_METHOD1(IsBuffer, GLboolean(GLuint buffer));
MOCK_METHOD1(IsEnabled, GLboolean(GLenum cap));
MOCK_METHOD1(IsFenceAPPLE, GLboolean(GLuint fence));
MOCK_METHOD1(IsFenceNV, GLboolean(GLuint fence));
MOCK_METHOD1(IsFramebufferEXT, GLboolean(GLuint framebuffer));
MOCK_METHOD1(IsProgram, GLboolean(GLuint program));
MOCK_METHOD1(IsQuery, GLboolean(GLuint query));
MOCK_METHOD1(IsRenderbufferEXT, GLboolean(GLuint renderbuffer));
MOCK_METHOD1(IsSampler, GLboolean(GLuint sampler));
MOCK_METHOD1(IsShader, GLboolean(GLuint shader));
MOCK_METHOD1(IsSync, GLboolean(GLsync sync));
MOCK_METHOD1(IsTexture, GLboolean(GLuint texture));
MOCK_METHOD1(IsTransformFeedback, GLboolean(GLuint id));
MOCK_METHOD1(IsVertexArrayOES, GLboolean(GLuint array));
MOCK_METHOD1(LineWidth, void(GLfloat width));
MOCK_METHOD1(LinkProgram, void(GLuint program));
MOCK_METHOD2(MapBuffer, void*(GLenum target, GLenum access));
MOCK_METHOD4(MapBufferRange,
             void*(GLenum target,
                   GLintptr offset,
                   GLsizeiptr length,
                   GLbitfield access));
MOCK_METHOD2(MatrixLoadfEXT, void(GLenum matrixMode, const GLfloat* m));
MOCK_METHOD1(MatrixLoadIdentityEXT, void(GLenum matrixMode));
MOCK_METHOD0(PauseTransformFeedback, void());
MOCK_METHOD2(PixelStorei, void(GLenum pname, GLint param));
MOCK_METHOD2(PointParameteri, void(GLenum pname, GLint param));
MOCK_METHOD2(PolygonOffset, void(GLfloat factor, GLfloat units));
MOCK_METHOD0(PopGroupMarkerEXT, void());
MOCK_METHOD4(ProgramBinary,
             void(GLuint program,
                  GLenum binaryFormat,
                  const GLvoid* binary,
                  GLsizei length));
MOCK_METHOD3(ProgramParameteri,
             void(GLuint program, GLenum pname, GLint value));
MOCK_METHOD2(PushGroupMarkerEXT, void(GLsizei length, const char* marker));
MOCK_METHOD2(QueryCounter, void(GLuint id, GLenum target));
MOCK_METHOD1(ReadBuffer, void(GLenum src));
MOCK_METHOD7(ReadPixels,
             void(GLint x,
                  GLint y,
                  GLsizei width,
                  GLsizei height,
                  GLenum format,
                  GLenum type,
                  void* pixels));
MOCK_METHOD0(ReleaseShaderCompiler, void());
MOCK_METHOD4(
    RenderbufferStorageEXT,
    void(GLenum target, GLenum internalformat, GLsizei width, GLsizei height));
MOCK_METHOD5(RenderbufferStorageMultisample,
             void(GLenum target,
                  GLsizei samples,
                  GLenum internalformat,
                  GLsizei width,
                  GLsizei height));
MOCK_METHOD5(RenderbufferStorageMultisampleANGLE,
             void(GLenum target,
                  GLsizei samples,
                  GLenum internalformat,
                  GLsizei width,
                  GLsizei height));
MOCK_METHOD5(RenderbufferStorageMultisampleAPPLE,
             void(GLenum target,
                  GLsizei samples,
                  GLenum internalformat,
                  GLsizei width,
                  GLsizei height));
MOCK_METHOD5(RenderbufferStorageMultisampleEXT,
             void(GLenum target,
                  GLsizei samples,
                  GLenum internalformat,
                  GLsizei width,
                  GLsizei height));
MOCK_METHOD5(RenderbufferStorageMultisampleIMG,
             void(GLenum target,
                  GLsizei samples,
                  GLenum internalformat,
                  GLsizei width,
                  GLsizei height));
MOCK_METHOD0(ResolveMultisampleFramebufferAPPLE, void());
MOCK_METHOD0(ResumeTransformFeedback, void());
MOCK_METHOD2(SampleCoverage, void(GLclampf value, GLboolean invert));
MOCK_METHOD3(SamplerParameterf,
             void(GLuint sampler, GLenum pname, GLfloat param));
MOCK_METHOD3(SamplerParameterfv,
             void(GLuint sampler, GLenum pname, const GLfloat* params));
MOCK_METHOD3(SamplerParameteri,
             void(GLuint sampler, GLenum pname, GLint param));
MOCK_METHOD3(SamplerParameteriv,
             void(GLuint sampler, GLenum pname, const GLint* params));
MOCK_METHOD4(Scissor, void(GLint x, GLint y, GLsizei width, GLsizei height));
MOCK_METHOD1(SetFenceAPPLE, void(GLuint fence));
MOCK_METHOD2(SetFenceNV, void(GLuint fence, GLenum condition));
MOCK_METHOD5(ShaderBinary,
             void(GLsizei n,
                  const GLuint* shaders,
                  GLenum binaryformat,
                  const void* binary,
                  GLsizei length));
MOCK_METHOD4(ShaderSource,
             void(GLuint shader,
                  GLsizei count,
                  const char* const* str,
                  const GLint* length));
MOCK_METHOD3(StencilFunc, void(GLenum func, GLint ref, GLuint mask));
MOCK_METHOD4(StencilFuncSeparate,
             void(GLenum face, GLenum func, GLint ref, GLuint mask));
MOCK_METHOD1(StencilMask, void(GLuint mask));
MOCK_METHOD2(StencilMaskSeparate, void(GLenum face, GLuint mask));
MOCK_METHOD3(StencilOp, void(GLenum fail, GLenum zfail, GLenum zpass));
MOCK_METHOD4(StencilOpSeparate,
             void(GLenum face, GLenum fail, GLenum zfail, GLenum zpass));
MOCK_METHOD1(TestFenceAPPLE, GLboolean(GLuint fence));
MOCK_METHOD1(TestFenceNV, GLboolean(GLuint fence));
MOCK_METHOD9(TexImage2D,
             void(GLenum target,
                  GLint level,
                  GLint internalformat,
                  GLsizei width,
                  GLsizei height,
                  GLint border,
                  GLenum format,
                  GLenum type,
                  const void* pixels));
MOCK_METHOD10(TexImage3D,
              void(GLenum target,
                   GLint level,
                   GLint internalformat,
                   GLsizei width,
                   GLsizei height,
                   GLsizei depth,
                   GLint border,
                   GLenum format,
                   GLenum type,
                   const void* pixels));
MOCK_METHOD3(TexParameterf, void(GLenum target, GLenum pname, GLfloat param));
MOCK_METHOD3(TexParameterfv,
             void(GLenum target, GLenum pname, const GLfloat* params));
MOCK_METHOD3(TexParameteri, void(GLenum target, GLenum pname, GLint param));
MOCK_METHOD3(TexParameteriv,
             void(GLenum target, GLenum pname, const GLint* params));
MOCK_METHOD5(TexStorage2DEXT,
             void(GLenum target,
                  GLsizei levels,
                  GLenum internalformat,
                  GLsizei width,
                  GLsizei height));
MOCK_METHOD6(TexStorage3D,
             void(GLenum target,
                  GLsizei levels,
                  GLenum internalformat,
                  GLsizei width,
                  GLsizei height,
                  GLsizei depth));
MOCK_METHOD9(TexSubImage2D,
             void(GLenum target,
                  GLint level,
                  GLint xoffset,
                  GLint yoffset,
                  GLsizei width,
                  GLsizei height,
                  GLenum format,
                  GLenum type,
                  const void* pixels));
MOCK_METHOD4(TransformFeedbackVaryings,
             void(GLuint program,
                  GLsizei count,
                  const char* const* varyings,
                  GLenum bufferMode));
MOCK_METHOD2(Uniform1f, void(GLint location, GLfloat x));
MOCK_METHOD3(Uniform1fv, void(GLint location, GLsizei count, const GLfloat* v));
MOCK_METHOD2(Uniform1i, void(GLint location, GLint x));
MOCK_METHOD3(Uniform1iv, void(GLint location, GLsizei count, const GLint* v));
MOCK_METHOD2(Uniform1ui, void(GLint location, GLuint v0));
MOCK_METHOD3(Uniform1uiv, void(GLint location, GLsizei count, const GLuint* v));
MOCK_METHOD3(Uniform2f, void(GLint location, GLfloat x, GLfloat y));
MOCK_METHOD3(Uniform2fv, void(GLint location, GLsizei count, const GLfloat* v));
MOCK_METHOD3(Uniform2i, void(GLint location, GLint x, GLint y));
MOCK_METHOD3(Uniform2iv, void(GLint location, GLsizei count, const GLint* v));
MOCK_METHOD3(Uniform2ui, void(GLint location, GLuint v0, GLuint v1));
MOCK_METHOD3(Uniform2uiv, void(GLint location, GLsizei count, const GLuint* v));
MOCK_METHOD4(Uniform3f, void(GLint location, GLfloat x, GLfloat y, GLfloat z));
MOCK_METHOD3(Uniform3fv, void(GLint location, GLsizei count, const GLfloat* v));
MOCK_METHOD4(Uniform3i, void(GLint location, GLint x, GLint y, GLint z));
MOCK_METHOD3(Uniform3iv, void(GLint location, GLsizei count, const GLint* v));
MOCK_METHOD4(Uniform3ui, void(GLint location, GLuint v0, GLuint v1, GLuint v2));
MOCK_METHOD3(Uniform3uiv, void(GLint location, GLsizei count, const GLuint* v));
MOCK_METHOD5(Uniform4f,
             void(GLint location, GLfloat x, GLfloat y, GLfloat z, GLfloat w));
MOCK_METHOD3(Uniform4fv, void(GLint location, GLsizei count, const GLfloat* v));
MOCK_METHOD5(Uniform4i,
             void(GLint location, GLint x, GLint y, GLint z, GLint w));
MOCK_METHOD3(Uniform4iv, void(GLint location, GLsizei count, const GLint* v));
MOCK_METHOD5(Uniform4ui,
             void(GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3));
MOCK_METHOD3(Uniform4uiv, void(GLint location, GLsizei count, const GLuint* v));
MOCK_METHOD3(UniformBlockBinding,
             void(GLuint program,
                  GLuint uniformBlockIndex,
                  GLuint uniformBlockBinding));
MOCK_METHOD4(UniformMatrix2fv,
             void(GLint location,
                  GLsizei count,
                  GLboolean transpose,
                  const GLfloat* value));
MOCK_METHOD4(UniformMatrix2x3fv,
             void(GLint location,
                  GLsizei count,
                  GLboolean transpose,
                  const GLfloat* value));
MOCK_METHOD4(UniformMatrix2x4fv,
             void(GLint location,
                  GLsizei count,
                  GLboolean transpose,
                  const GLfloat* value));
MOCK_METHOD4(UniformMatrix3fv,
             void(GLint location,
                  GLsizei count,
                  GLboolean transpose,
                  const GLfloat* value));
MOCK_METHOD4(UniformMatrix3x2fv,
             void(GLint location,
                  GLsizei count,
                  GLboolean transpose,
                  const GLfloat* value));
MOCK_METHOD4(UniformMatrix3x4fv,
             void(GLint location,
                  GLsizei count,
                  GLboolean transpose,
                  const GLfloat* value));
MOCK_METHOD4(UniformMatrix4fv,
             void(GLint location,
                  GLsizei count,
                  GLboolean transpose,
                  const GLfloat* value));
MOCK_METHOD4(UniformMatrix4x2fv,
             void(GLint location,
                  GLsizei count,
                  GLboolean transpose,
                  const GLfloat* value));
MOCK_METHOD4(UniformMatrix4x3fv,
             void(GLint location,
                  GLsizei count,
                  GLboolean transpose,
                  const GLfloat* value));
MOCK_METHOD1(UnmapBuffer, GLboolean(GLenum target));
MOCK_METHOD1(UseProgram, void(GLuint program));
MOCK_METHOD1(ValidateProgram, void(GLuint program));
MOCK_METHOD2(VertexAttrib1f, void(GLuint indx, GLfloat x));
MOCK_METHOD2(VertexAttrib1fv, void(GLuint indx, const GLfloat* values));
MOCK_METHOD3(VertexAttrib2f, void(GLuint indx, GLfloat x, GLfloat y));
MOCK_METHOD2(VertexAttrib2fv, void(GLuint indx, const GLfloat* values));
MOCK_METHOD4(VertexAttrib3f,
             void(GLuint indx, GLfloat x, GLfloat y, GLfloat z));
MOCK_METHOD2(VertexAttrib3fv, void(GLuint indx, const GLfloat* values));
MOCK_METHOD5(VertexAttrib4f,
             void(GLuint indx, GLfloat x, GLfloat y, GLfloat z, GLfloat w));
MOCK_METHOD2(VertexAttrib4fv, void(GLuint indx, const GLfloat* values));
MOCK_METHOD2(VertexAttribDivisorANGLE, void(GLuint index, GLuint divisor));
MOCK_METHOD5(VertexAttribI4i,
             void(GLuint indx, GLint x, GLint y, GLint z, GLint w));
MOCK_METHOD2(VertexAttribI4iv, void(GLuint indx, const GLint* values));
MOCK_METHOD5(VertexAttribI4ui,
             void(GLuint indx, GLuint x, GLuint y, GLuint z, GLuint w));
MOCK_METHOD2(VertexAttribI4uiv, void(GLuint indx, const GLuint* values));
MOCK_METHOD5(VertexAttribIPointer,
             void(GLuint indx,
                  GLint size,
                  GLenum type,
                  GLsizei stride,
                  const void* ptr));
MOCK_METHOD6(VertexAttribPointer,
             void(GLuint indx,
                  GLint size,
                  GLenum type,
                  GLboolean normalized,
                  GLsizei stride,
                  const void* ptr));
MOCK_METHOD4(Viewport, void(GLint x, GLint y, GLsizei width, GLsizei height));
MOCK_METHOD3(WaitSync, GLenum(GLsync sync, GLbitfield flags, GLuint64 timeout));
