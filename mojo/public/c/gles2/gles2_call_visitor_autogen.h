// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

VISIT_GL_CALL(ActiveTexture, void, (GLenum texture), (texture))
VISIT_GL_CALL(AttachShader,
              void,
              (GLuint program, GLuint shader),
              (program, shader))
VISIT_GL_CALL(BindAttribLocation,
              void,
              (GLuint program, GLuint index, const char* name),
              (program, index, name))
VISIT_GL_CALL(BindBuffer,
              void,
              (GLenum target, GLuint buffer),
              (target, buffer))
VISIT_GL_CALL(BindFramebuffer,
              void,
              (GLenum target, GLuint framebuffer),
              (target, framebuffer))
VISIT_GL_CALL(BindRenderbuffer,
              void,
              (GLenum target, GLuint renderbuffer),
              (target, renderbuffer))
VISIT_GL_CALL(BindTexture,
              void,
              (GLenum target, GLuint texture),
              (target, texture))
VISIT_GL_CALL(BlendColor,
              void,
              (GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha),
              (red, green, blue, alpha))
VISIT_GL_CALL(BlendEquation, void, (GLenum mode), (mode))
VISIT_GL_CALL(BlendEquationSeparate,
              void,
              (GLenum modeRGB, GLenum modeAlpha),
              (modeRGB, modeAlpha))
VISIT_GL_CALL(BlendFunc,
              void,
              (GLenum sfactor, GLenum dfactor),
              (sfactor, dfactor))
VISIT_GL_CALL(BlendFuncSeparate,
              void,
              (GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha),
              (srcRGB, dstRGB, srcAlpha, dstAlpha))
VISIT_GL_CALL(BufferData,
              void,
              (GLenum target, GLsizeiptr size, const void* data, GLenum usage),
              (target, size, data, usage))
VISIT_GL_CALL(
    BufferSubData,
    void,
    (GLenum target, GLintptr offset, GLsizeiptr size, const void* data),
    (target, offset, size, data))
VISIT_GL_CALL(CheckFramebufferStatus, GLenum, (GLenum target), (target))
VISIT_GL_CALL(Clear, void, (GLbitfield mask), (mask))
VISIT_GL_CALL(ClearColor,
              void,
              (GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha),
              (red, green, blue, alpha))
VISIT_GL_CALL(ClearDepthf, void, (GLclampf depth), (depth))
VISIT_GL_CALL(ClearStencil, void, (GLint s), (s))
VISIT_GL_CALL(ColorMask,
              void,
              (GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha),
              (red, green, blue, alpha))
VISIT_GL_CALL(CompileShader, void, (GLuint shader), (shader))
VISIT_GL_CALL(
    CompressedTexImage2D,
    void,
    (GLenum target,
     GLint level,
     GLenum internalformat,
     GLsizei width,
     GLsizei height,
     GLint border,
     GLsizei imageSize,
     const void* data),
    (target, level, internalformat, width, height, border, imageSize, data))
VISIT_GL_CALL(
    CompressedTexSubImage2D,
    void,
    (GLenum target,
     GLint level,
     GLint xoffset,
     GLint yoffset,
     GLsizei width,
     GLsizei height,
     GLenum format,
     GLsizei imageSize,
     const void* data),
    (target, level, xoffset, yoffset, width, height, format, imageSize, data))
VISIT_GL_CALL(CopyTexImage2D,
              void,
              (GLenum target,
               GLint level,
               GLenum internalformat,
               GLint x,
               GLint y,
               GLsizei width,
               GLsizei height,
               GLint border),
              (target, level, internalformat, x, y, width, height, border))
VISIT_GL_CALL(CopyTexSubImage2D,
              void,
              (GLenum target,
               GLint level,
               GLint xoffset,
               GLint yoffset,
               GLint x,
               GLint y,
               GLsizei width,
               GLsizei height),
              (target, level, xoffset, yoffset, x, y, width, height))
VISIT_GL_CALL(CreateProgram, GLuint, (), ())
VISIT_GL_CALL(CreateShader, GLuint, (GLenum type), (type))
VISIT_GL_CALL(CullFace, void, (GLenum mode), (mode))
VISIT_GL_CALL(DeleteBuffers,
              void,
              (GLsizei n, const GLuint* buffers),
              (n, buffers))
VISIT_GL_CALL(DeleteFramebuffers,
              void,
              (GLsizei n, const GLuint* framebuffers),
              (n, framebuffers))
VISIT_GL_CALL(DeleteProgram, void, (GLuint program), (program))
VISIT_GL_CALL(DeleteRenderbuffers,
              void,
              (GLsizei n, const GLuint* renderbuffers),
              (n, renderbuffers))
VISIT_GL_CALL(DeleteShader, void, (GLuint shader), (shader))
VISIT_GL_CALL(DeleteTextures,
              void,
              (GLsizei n, const GLuint* textures),
              (n, textures))
VISIT_GL_CALL(DepthFunc, void, (GLenum func), (func))
VISIT_GL_CALL(DepthMask, void, (GLboolean flag), (flag))
VISIT_GL_CALL(DepthRangef, void, (GLclampf zNear, GLclampf zFar), (zNear, zFar))
VISIT_GL_CALL(DetachShader,
              void,
              (GLuint program, GLuint shader),
              (program, shader))
VISIT_GL_CALL(Disable, void, (GLenum cap), (cap))
VISIT_GL_CALL(DisableVertexAttribArray, void, (GLuint index), (index))
VISIT_GL_CALL(DrawArrays,
              void,
              (GLenum mode, GLint first, GLsizei count),
              (mode, first, count))
VISIT_GL_CALL(DrawElements,
              void,
              (GLenum mode, GLsizei count, GLenum type, const void* indices),
              (mode, count, type, indices))
VISIT_GL_CALL(Enable, void, (GLenum cap), (cap))
VISIT_GL_CALL(EnableVertexAttribArray, void, (GLuint index), (index))
VISIT_GL_CALL(Finish, void, (), ())
VISIT_GL_CALL(Flush, void, (), ())
VISIT_GL_CALL(FramebufferRenderbuffer,
              void,
              (GLenum target,
               GLenum attachment,
               GLenum renderbuffertarget,
               GLuint renderbuffer),
              (target, attachment, renderbuffertarget, renderbuffer))
VISIT_GL_CALL(FramebufferTexture2D,
              void,
              (GLenum target,
               GLenum attachment,
               GLenum textarget,
               GLuint texture,
               GLint level),
              (target, attachment, textarget, texture, level))
VISIT_GL_CALL(FrontFace, void, (GLenum mode), (mode))
VISIT_GL_CALL(GenBuffers, void, (GLsizei n, GLuint* buffers), (n, buffers))
VISIT_GL_CALL(GenerateMipmap, void, (GLenum target), (target))
VISIT_GL_CALL(GenFramebuffers,
              void,
              (GLsizei n, GLuint* framebuffers),
              (n, framebuffers))
VISIT_GL_CALL(GenRenderbuffers,
              void,
              (GLsizei n, GLuint* renderbuffers),
              (n, renderbuffers))
VISIT_GL_CALL(GenTextures, void, (GLsizei n, GLuint* textures), (n, textures))
VISIT_GL_CALL(GetActiveAttrib,
              void,
              (GLuint program,
               GLuint index,
               GLsizei bufsize,
               GLsizei* length,
               GLint* size,
               GLenum* type,
               char* name),
              (program, index, bufsize, length, size, type, name))
VISIT_GL_CALL(GetActiveUniform,
              void,
              (GLuint program,
               GLuint index,
               GLsizei bufsize,
               GLsizei* length,
               GLint* size,
               GLenum* type,
               char* name),
              (program, index, bufsize, length, size, type, name))
VISIT_GL_CALL(
    GetAttachedShaders,
    void,
    (GLuint program, GLsizei maxcount, GLsizei* count, GLuint* shaders),
    (program, maxcount, count, shaders))
VISIT_GL_CALL(GetAttribLocation,
              GLint,
              (GLuint program, const char* name),
              (program, name))
VISIT_GL_CALL(GetBooleanv,
              void,
              (GLenum pname, GLboolean* params),
              (pname, params))
VISIT_GL_CALL(GetBufferParameteriv,
              void,
              (GLenum target, GLenum pname, GLint* params),
              (target, pname, params))
VISIT_GL_CALL(GetError, GLenum, (), ())
VISIT_GL_CALL(GetFloatv, void, (GLenum pname, GLfloat* params), (pname, params))
VISIT_GL_CALL(GetFramebufferAttachmentParameteriv,
              void,
              (GLenum target, GLenum attachment, GLenum pname, GLint* params),
              (target, attachment, pname, params))
VISIT_GL_CALL(GetIntegerv, void, (GLenum pname, GLint* params), (pname, params))
VISIT_GL_CALL(GetProgramiv,
              void,
              (GLuint program, GLenum pname, GLint* params),
              (program, pname, params))
VISIT_GL_CALL(GetProgramInfoLog,
              void,
              (GLuint program, GLsizei bufsize, GLsizei* length, char* infolog),
              (program, bufsize, length, infolog))
VISIT_GL_CALL(GetRenderbufferParameteriv,
              void,
              (GLenum target, GLenum pname, GLint* params),
              (target, pname, params))
VISIT_GL_CALL(GetShaderiv,
              void,
              (GLuint shader, GLenum pname, GLint* params),
              (shader, pname, params))
VISIT_GL_CALL(GetShaderInfoLog,
              void,
              (GLuint shader, GLsizei bufsize, GLsizei* length, char* infolog),
              (shader, bufsize, length, infolog))
VISIT_GL_CALL(
    GetShaderPrecisionFormat,
    void,
    (GLenum shadertype, GLenum precisiontype, GLint* range, GLint* precision),
    (shadertype, precisiontype, range, precision))
VISIT_GL_CALL(GetShaderSource,
              void,
              (GLuint shader, GLsizei bufsize, GLsizei* length, char* source),
              (shader, bufsize, length, source))
VISIT_GL_CALL(GetString, const GLubyte*, (GLenum name), (name))
VISIT_GL_CALL(GetTexParameterfv,
              void,
              (GLenum target, GLenum pname, GLfloat* params),
              (target, pname, params))
VISIT_GL_CALL(GetTexParameteriv,
              void,
              (GLenum target, GLenum pname, GLint* params),
              (target, pname, params))
VISIT_GL_CALL(GetUniformfv,
              void,
              (GLuint program, GLint location, GLfloat* params),
              (program, location, params))
VISIT_GL_CALL(GetUniformiv,
              void,
              (GLuint program, GLint location, GLint* params),
              (program, location, params))
VISIT_GL_CALL(GetUniformLocation,
              GLint,
              (GLuint program, const char* name),
              (program, name))
VISIT_GL_CALL(GetVertexAttribfv,
              void,
              (GLuint index, GLenum pname, GLfloat* params),
              (index, pname, params))
VISIT_GL_CALL(GetVertexAttribiv,
              void,
              (GLuint index, GLenum pname, GLint* params),
              (index, pname, params))
VISIT_GL_CALL(GetVertexAttribPointerv,
              void,
              (GLuint index, GLenum pname, void** pointer),
              (index, pname, pointer))
VISIT_GL_CALL(Hint, void, (GLenum target, GLenum mode), (target, mode))
VISIT_GL_CALL(IsBuffer, GLboolean, (GLuint buffer), (buffer))
VISIT_GL_CALL(IsEnabled, GLboolean, (GLenum cap), (cap))
VISIT_GL_CALL(IsFramebuffer, GLboolean, (GLuint framebuffer), (framebuffer))
VISIT_GL_CALL(IsProgram, GLboolean, (GLuint program), (program))
VISIT_GL_CALL(IsRenderbuffer, GLboolean, (GLuint renderbuffer), (renderbuffer))
VISIT_GL_CALL(IsShader, GLboolean, (GLuint shader), (shader))
VISIT_GL_CALL(IsTexture, GLboolean, (GLuint texture), (texture))
VISIT_GL_CALL(LineWidth, void, (GLfloat width), (width))
VISIT_GL_CALL(LinkProgram, void, (GLuint program), (program))
VISIT_GL_CALL(PixelStorei, void, (GLenum pname, GLint param), (pname, param))
VISIT_GL_CALL(PolygonOffset,
              void,
              (GLfloat factor, GLfloat units),
              (factor, units))
VISIT_GL_CALL(ReadPixels,
              void,
              (GLint x,
               GLint y,
               GLsizei width,
               GLsizei height,
               GLenum format,
               GLenum type,
               void* pixels),
              (x, y, width, height, format, type, pixels))
VISIT_GL_CALL(ReleaseShaderCompiler, void, (), ())
VISIT_GL_CALL(
    RenderbufferStorage,
    void,
    (GLenum target, GLenum internalformat, GLsizei width, GLsizei height),
    (target, internalformat, width, height))
VISIT_GL_CALL(SampleCoverage,
              void,
              (GLclampf value, GLboolean invert),
              (value, invert))
VISIT_GL_CALL(Scissor,
              void,
              (GLint x, GLint y, GLsizei width, GLsizei height),
              (x, y, width, height))
VISIT_GL_CALL(ShaderBinary,
              void,
              (GLsizei n,
               const GLuint* shaders,
               GLenum binaryformat,
               const void* binary,
               GLsizei length),
              (n, shaders, binaryformat, binary, length))
VISIT_GL_CALL(ShaderSource,
              void,
              (GLuint shader,
               GLsizei count,
               const GLchar* const* str,
               const GLint* length),
              (shader, count, str, length))
VISIT_GL_CALL(StencilFunc,
              void,
              (GLenum func, GLint ref, GLuint mask),
              (func, ref, mask))
VISIT_GL_CALL(StencilFuncSeparate,
              void,
              (GLenum face, GLenum func, GLint ref, GLuint mask),
              (face, func, ref, mask))
VISIT_GL_CALL(StencilMask, void, (GLuint mask), (mask))
VISIT_GL_CALL(StencilMaskSeparate,
              void,
              (GLenum face, GLuint mask),
              (face, mask))
VISIT_GL_CALL(StencilOp,
              void,
              (GLenum fail, GLenum zfail, GLenum zpass),
              (fail, zfail, zpass))
VISIT_GL_CALL(StencilOpSeparate,
              void,
              (GLenum face, GLenum fail, GLenum zfail, GLenum zpass),
              (face, fail, zfail, zpass))
VISIT_GL_CALL(TexImage2D,
              void,
              (GLenum target,
               GLint level,
               GLint internalformat,
               GLsizei width,
               GLsizei height,
               GLint border,
               GLenum format,
               GLenum type,
               const void* pixels),
              (target,
               level,
               internalformat,
               width,
               height,
               border,
               format,
               type,
               pixels))
VISIT_GL_CALL(TexParameterf,
              void,
              (GLenum target, GLenum pname, GLfloat param),
              (target, pname, param))
VISIT_GL_CALL(TexParameterfv,
              void,
              (GLenum target, GLenum pname, const GLfloat* params),
              (target, pname, params))
VISIT_GL_CALL(TexParameteri,
              void,
              (GLenum target, GLenum pname, GLint param),
              (target, pname, param))
VISIT_GL_CALL(TexParameteriv,
              void,
              (GLenum target, GLenum pname, const GLint* params),
              (target, pname, params))
VISIT_GL_CALL(
    TexSubImage2D,
    void,
    (GLenum target,
     GLint level,
     GLint xoffset,
     GLint yoffset,
     GLsizei width,
     GLsizei height,
     GLenum format,
     GLenum type,
     const void* pixels),
    (target, level, xoffset, yoffset, width, height, format, type, pixels))
VISIT_GL_CALL(Uniform1f, void, (GLint location, GLfloat x), (location, x))
VISIT_GL_CALL(Uniform1fv,
              void,
              (GLint location, GLsizei count, const GLfloat* v),
              (location, count, v))
VISIT_GL_CALL(Uniform1i, void, (GLint location, GLint x), (location, x))
VISIT_GL_CALL(Uniform1iv,
              void,
              (GLint location, GLsizei count, const GLint* v),
              (location, count, v))
VISIT_GL_CALL(Uniform2f,
              void,
              (GLint location, GLfloat x, GLfloat y),
              (location, x, y))
VISIT_GL_CALL(Uniform2fv,
              void,
              (GLint location, GLsizei count, const GLfloat* v),
              (location, count, v))
VISIT_GL_CALL(Uniform2i,
              void,
              (GLint location, GLint x, GLint y),
              (location, x, y))
VISIT_GL_CALL(Uniform2iv,
              void,
              (GLint location, GLsizei count, const GLint* v),
              (location, count, v))
VISIT_GL_CALL(Uniform3f,
              void,
              (GLint location, GLfloat x, GLfloat y, GLfloat z),
              (location, x, y, z))
VISIT_GL_CALL(Uniform3fv,
              void,
              (GLint location, GLsizei count, const GLfloat* v),
              (location, count, v))
VISIT_GL_CALL(Uniform3i,
              void,
              (GLint location, GLint x, GLint y, GLint z),
              (location, x, y, z))
VISIT_GL_CALL(Uniform3iv,
              void,
              (GLint location, GLsizei count, const GLint* v),
              (location, count, v))
VISIT_GL_CALL(Uniform4f,
              void,
              (GLint location, GLfloat x, GLfloat y, GLfloat z, GLfloat w),
              (location, x, y, z, w))
VISIT_GL_CALL(Uniform4fv,
              void,
              (GLint location, GLsizei count, const GLfloat* v),
              (location, count, v))
VISIT_GL_CALL(Uniform4i,
              void,
              (GLint location, GLint x, GLint y, GLint z, GLint w),
              (location, x, y, z, w))
VISIT_GL_CALL(Uniform4iv,
              void,
              (GLint location, GLsizei count, const GLint* v),
              (location, count, v))
VISIT_GL_CALL(
    UniformMatrix2fv,
    void,
    (GLint location, GLsizei count, GLboolean transpose, const GLfloat* value),
    (location, count, transpose, value))
VISIT_GL_CALL(
    UniformMatrix3fv,
    void,
    (GLint location, GLsizei count, GLboolean transpose, const GLfloat* value),
    (location, count, transpose, value))
VISIT_GL_CALL(
    UniformMatrix4fv,
    void,
    (GLint location, GLsizei count, GLboolean transpose, const GLfloat* value),
    (location, count, transpose, value))
VISIT_GL_CALL(UseProgram, void, (GLuint program), (program))
VISIT_GL_CALL(ValidateProgram, void, (GLuint program), (program))
VISIT_GL_CALL(VertexAttrib1f, void, (GLuint indx, GLfloat x), (indx, x))
VISIT_GL_CALL(VertexAttrib1fv,
              void,
              (GLuint indx, const GLfloat* values),
              (indx, values))
VISIT_GL_CALL(VertexAttrib2f,
              void,
              (GLuint indx, GLfloat x, GLfloat y),
              (indx, x, y))
VISIT_GL_CALL(VertexAttrib2fv,
              void,
              (GLuint indx, const GLfloat* values),
              (indx, values))
VISIT_GL_CALL(VertexAttrib3f,
              void,
              (GLuint indx, GLfloat x, GLfloat y, GLfloat z),
              (indx, x, y, z))
VISIT_GL_CALL(VertexAttrib3fv,
              void,
              (GLuint indx, const GLfloat* values),
              (indx, values))
VISIT_GL_CALL(VertexAttrib4f,
              void,
              (GLuint indx, GLfloat x, GLfloat y, GLfloat z, GLfloat w),
              (indx, x, y, z, w))
VISIT_GL_CALL(VertexAttrib4fv,
              void,
              (GLuint indx, const GLfloat* values),
              (indx, values))
VISIT_GL_CALL(VertexAttribPointer,
              void,
              (GLuint indx,
               GLint size,
               GLenum type,
               GLboolean normalized,
               GLsizei stride,
               const void* ptr),
              (indx, size, type, normalized, stride, ptr))
VISIT_GL_CALL(Viewport,
              void,
              (GLint x, GLint y, GLsizei width, GLsizei height),
              (x, y, width, height))
