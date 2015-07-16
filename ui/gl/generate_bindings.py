#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""code generator for GL/GLES extension wrangler."""

import optparse
import os
import collections
import re
import platform
import sys
from subprocess import call
from collections import namedtuple

HEADER_PATHS = [
  '../../third_party/khronos',
  '../../third_party/mesa/src/include',
  '.',
  '../../gpu',
]

UNCONDITIONALLY_BOUND_EXTENSIONS = set([
  'WGL_ARB_extensions_string',
  'WGL_EXT_extensions_string',
  'GL_CHROMIUM_gles_depth_binding_hack', # crbug.com/448206
])

"""Function binding conditions can be specified manually by supplying a versions
array instead of the names array. Each version has the following keys:
   name: Mandatory. Name of the function. Multiple versions can have the same
         name but different conditions.
   extensions: Extra Extensions for which the function is bound. Only needed
               in some cases where the extension cannot be parsed from the
               headers.

By default, the function gets its name from the first name in its names or
versions array. This can be overridden by supplying a 'known_as' key.
"""
GL_FUNCTIONS = [
{ 'return_type': 'void',
  'names': ['glActiveTexture'],
  'arguments': 'GLenum texture', },
{ 'return_type': 'void',
  'names': ['glAttachShader'],
  'arguments': 'GLuint program, GLuint shader', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glBeginQuery' },
               { 'name': 'glBeginQueryARB' },
               { 'name': 'glBeginQueryEXT',
                 'extensions': ['GL_EXT_occlusion_query_boolean'] }],
  'arguments': 'GLenum target, GLuint id', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glBeginTransformFeedback' }],
  'arguments': 'GLenum primitiveMode', },
{ 'return_type': 'void',
  'names': ['glBindAttribLocation'],
  'arguments': 'GLuint program, GLuint index, const char* name', },
{ 'return_type': 'void',
  'names': ['glBindBuffer'],
  'arguments': 'GLenum target, GLuint buffer', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glBindBufferBase' }],
  'arguments': 'GLenum target, GLuint index, GLuint buffer', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glBindBufferRange' }],
  'arguments': 'GLenum target, GLuint index, GLuint buffer, GLintptr offset, '
               'GLsizeiptr size', },
{ 'return_type': 'void',
  'names': ['glBindFragDataLocation'],
  'arguments': 'GLuint program, GLuint colorNumber, const char* name', },
{ 'return_type': 'void',
  'names': ['glBindFragDataLocationIndexed'],
  'arguments':
      'GLuint program, GLuint colorNumber, GLuint index, const char* name', },
{ 'return_type': 'void',
  'names': ['glBindFramebufferEXT', 'glBindFramebuffer'],
  'arguments': 'GLenum target, GLuint framebuffer', },
{ 'return_type': 'void',
  'names': ['glBindRenderbufferEXT', 'glBindRenderbuffer'],
  'arguments': 'GLenum target, GLuint renderbuffer', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glBindSampler' }],
  'arguments': 'GLuint unit, GLuint sampler', },
{ 'return_type': 'void',
  'names': ['glBindTexture'],
  'arguments': 'GLenum target, GLuint texture', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glBindTransformFeedback' }],
  'arguments': 'GLenum target, GLuint id', },
{ 'return_type': 'void',
  'known_as': 'glBindVertexArrayOES',
  'versions': [{ 'name': 'glBindVertexArray',
                 'extensions': ['GL_ARB_vertex_array_object'], },
               { 'name': 'glBindVertexArrayOES' },
               { 'name': 'glBindVertexArrayAPPLE',
                 'extensions': ['GL_APPLE_vertex_array_object'] }],
  'arguments': 'GLuint array' },
{ 'return_type': 'void',
  'known_as': 'glBlendBarrierKHR',
  'versions': [{ 'name': 'glBlendBarrierNV',
                 'extensions': ['GL_NV_blend_equation_advanced'] },
               { 'name': 'glBlendBarrierKHR',
                 'extensions': ['GL_KHR_blend_equation_advanced'] }],
  'arguments': 'void' },
{ 'return_type': 'void',
  'names': ['glBlendColor'],
  'arguments': 'GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha', },
{ 'return_type': 'void',
  'names': ['glBlendEquation'],
  'arguments': ' GLenum mode ', },
{ 'return_type': 'void',
  'names': ['glBlendEquationSeparate'],
  'arguments': 'GLenum modeRGB, GLenum modeAlpha', },
{ 'return_type': 'void',
  'names': ['glBlendFunc'],
  'arguments': 'GLenum sfactor, GLenum dfactor', },
{ 'return_type': 'void',
  'names': ['glBlendFuncSeparate'],
  'arguments':
      'GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha', },
{ 'return_type': 'void',
  'names': ['glBlitFramebuffer'],
  'arguments': 'GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, '
               'GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, '
               'GLbitfield mask, GLenum filter', },
{ 'return_type': 'void',
  'names': ['glBlitFramebufferANGLE', 'glBlitFramebuffer'],
  'arguments': 'GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, '
               'GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, '
               'GLbitfield mask, GLenum filter', },
{ 'return_type': 'void',
  'names': ['glBlitFramebufferEXT', 'glBlitFramebuffer'],
  'arguments': 'GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, '
               'GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, '
               'GLbitfield mask, GLenum filter', },
{ 'return_type': 'void',
  'names': ['glBufferData'],
  'arguments':
      'GLenum target, GLsizeiptr size, const void* data, GLenum usage', },
{ 'return_type': 'void',
  'names': ['glBufferSubData'],
  'arguments':
      'GLenum target, GLintptr offset, GLsizeiptr size, const void* data', },
{ 'return_type': 'GLenum',
  'names': ['glCheckFramebufferStatusEXT',
            'glCheckFramebufferStatus'],
  'arguments': 'GLenum target',
  'logging_code': """
  GL_SERVICE_LOG("GL_RESULT: " << GLEnums::GetStringEnum(result));
""", },
{ 'return_type': 'void',
  'names': ['glClear'],
  'arguments': 'GLbitfield mask', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glClearBufferfi' }],
  'arguments': 'GLenum buffer, GLint drawbuffer, const GLfloat depth, '
               'GLint stencil', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glClearBufferfv' }],
  'arguments': 'GLenum buffer, GLint drawbuffer, const GLfloat* value', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glClearBufferiv' }],
  'arguments': 'GLenum buffer, GLint drawbuffer, const GLint* value', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glClearBufferuiv' }],
  'arguments': 'GLenum buffer, GLint drawbuffer, const GLuint* value', },
{ 'return_type': 'void',
  'names': ['glClearColor'],
  'arguments': 'GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glClearDepth',
                 'extensions': ['GL_CHROMIUM_gles_depth_binding_hack'] }],
  'arguments': 'GLclampd depth', },
{ 'return_type': 'void',
  'names': ['glClearDepthf'],
  'arguments': 'GLclampf depth', },
{ 'return_type': 'void',
  'names': ['glClearStencil'],
  'arguments': 'GLint s', },
{ 'return_type': 'GLenum',
  'versions': [{ 'name': 'glClientWaitSync',
                 'extensions': ['GL_ARB_sync'] }],
  'arguments': 'GLsync sync, GLbitfield flags, GLuint64 timeout', },
{ 'return_type': 'void',
  'names': ['glColorMask'],
  'arguments':
      'GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha', },
{ 'return_type': 'void',
  'names': ['glCompileShader'],
  'arguments': 'GLuint shader', },
{ 'return_type': 'void',
  'names': ['glCompressedTexImage2D'],
  'arguments':
      'GLenum target, GLint level, GLenum internalformat, GLsizei width, '
      'GLsizei height, GLint border, GLsizei imageSize, const void* data', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glCompressedTexImage3D' }],
  'arguments':
      'GLenum target, GLint level, GLenum internalformat, GLsizei width, '
      'GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, '
      'const void* data', },
{ 'return_type': 'void',
  'names': ['glCompressedTexSubImage2D'],
  'arguments':
      'GLenum target, GLint level, GLint xoffset, GLint yoffset, '
      'GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, '
      'const void* data', },
# TODO(zmo): wait for MOCK_METHOD11.
# { 'return_type': 'void',
#   'versions': [{ 'name': 'glCompressedTexSubImage3D' }],
#   'arguments':
#       'GLenum target, GLint level, GLint xoffset, GLint yoffset, '
#       'GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, '
#       'GLenum format, GLsizei imageSize, const void* data', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glCopyBufferSubData' }],
  'arguments':
      'GLenum readTarget, GLenum writeTarget, GLintptr readOffset, '
      'GLintptr writeOffset, GLsizeiptr size', },
{ 'return_type': 'void',
  'names': ['glCopyTexImage2D'],
  'arguments':
      'GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, '
      'GLsizei width, GLsizei height, GLint border', },
{ 'return_type': 'void',
  'names': ['glCopyTexSubImage2D'],
  'arguments':
      'GLenum target, GLint level, GLint xoffset, '
      'GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glCopyTexSubImage3D' }],
  'arguments':
      'GLenum target, GLint level, GLint xoffset, GLint yoffset, '
      'GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height', },
{ 'return_type': 'GLuint',
  'names': ['glCreateProgram'],
  'arguments': 'void', },
{ 'return_type': 'GLuint',
  'names': ['glCreateShader'],
  'arguments': 'GLenum type', },
{ 'return_type': 'void',
  'names': ['glCullFace'],
  'arguments': 'GLenum mode', },
{ 'return_type': 'void',
  'names': ['glDeleteBuffers'],
  'known_as': 'glDeleteBuffersARB',
  'arguments': 'GLsizei n, const GLuint* buffers', },
{ 'return_type': 'void',
  'known_as': 'glDeleteFencesAPPLE',
  'versions': [{ 'name': 'glDeleteFencesAPPLE',
                 'extensions': ['GL_APPLE_fence'] }],
  'arguments': 'GLsizei n, const GLuint* fences', },
{ 'return_type': 'void',
  'names': ['glDeleteFencesNV'],
  'arguments': 'GLsizei n, const GLuint* fences', },
{ 'return_type': 'void',
  'names': ['glDeleteFramebuffersEXT', 'glDeleteFramebuffers'],
  'arguments': 'GLsizei n, const GLuint* framebuffers', },
{ 'return_type': 'void',
  'names': ['glDeleteProgram'],
  'arguments': 'GLuint program', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glDeleteQueries' },
               { 'name': 'glDeleteQueriesARB'},
               { 'name': 'glDeleteQueriesEXT',
                 'extensions': ['GL_EXT_occlusion_query_boolean'] }],
  'arguments': 'GLsizei n, const GLuint* ids', },
{ 'return_type': 'void',
  'names': ['glDeleteRenderbuffersEXT', 'glDeleteRenderbuffers'],
  'arguments': 'GLsizei n, const GLuint* renderbuffers', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glDeleteSamplers' }],
  'arguments': 'GLsizei n, const GLuint* samplers', },
{ 'return_type': 'void',
  'names': ['glDeleteShader'],
  'arguments': 'GLuint shader', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glDeleteSync',
                 'extensions': ['GL_ARB_sync'] }],
  'arguments': 'GLsync sync', },
{ 'return_type': 'void',
  'names': ['glDeleteTextures'],
  'arguments': 'GLsizei n, const GLuint* textures', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glDeleteTransformFeedbacks' }],
  'arguments': 'GLsizei n, const GLuint* ids', },
{ 'return_type': 'void',
  'known_as': 'glDeleteVertexArraysOES',
  'versions': [{ 'name': 'glDeleteVertexArrays',
                 'extensions': ['GL_ARB_vertex_array_object'], },
               { 'name': 'glDeleteVertexArraysOES' },
               { 'name': 'glDeleteVertexArraysAPPLE',
                 'extensions': ['GL_APPLE_vertex_array_object'] }],
  'arguments': 'GLsizei n, const GLuint* arrays' },
{ 'return_type': 'void',
  'names': ['glDepthFunc'],
  'arguments': 'GLenum func', },
{ 'return_type': 'void',
  'names': ['glDepthMask'],
  'arguments': 'GLboolean flag', },
{ 'return_type': 'void',
 'versions': [{ 'name': 'glDepthRange',
                'extensions': ['GL_CHROMIUM_gles_depth_binding_hack'] }],
  'arguments': 'GLclampd zNear, GLclampd zFar', },
{ 'return_type': 'void',
  'names': ['glDepthRangef'],
  'arguments': 'GLclampf zNear, GLclampf zFar', },
{ 'return_type': 'void',
  'names': ['glDetachShader'],
  'arguments': 'GLuint program, GLuint shader', },
{ 'return_type': 'void',
  'names': ['glDisable'],
  'arguments': 'GLenum cap', },
{ 'return_type': 'void',
  'names': ['glDisableVertexAttribArray'],
  'arguments': 'GLuint index', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glDiscardFramebufferEXT',
                 'extensions': ['GL_EXT_discard_framebuffer'] }],
  'arguments': 'GLenum target, GLsizei numAttachments, '
      'const GLenum* attachments' },
{ 'return_type': 'void',
  'names': ['glDrawArrays'],
  'arguments': 'GLenum mode, GLint first, GLsizei count', },
{ 'return_type': 'void',
  'known_as': 'glDrawArraysInstancedANGLE',
  'names': ['glDrawArraysInstancedARB', 'glDrawArraysInstancedANGLE',
            'glDrawArraysInstanced'],
  'arguments': 'GLenum mode, GLint first, GLsizei count, GLsizei primcount', },
{ 'return_type': 'void',
  'names': ['glDrawBuffer'],
  'arguments': 'GLenum mode', },
{ 'return_type': 'void',
  'names': ['glDrawBuffersARB', 'glDrawBuffersEXT', 'glDrawBuffers'],
  'arguments': 'GLsizei n, const GLenum* bufs', },
{ 'return_type': 'void',
  'names': ['glDrawElements'],
  'arguments':
      'GLenum mode, GLsizei count, GLenum type, const void* indices', },
{ 'return_type': 'void',
  'known_as': 'glDrawElementsInstancedANGLE',
  'names': ['glDrawElementsInstancedARB', 'glDrawElementsInstancedANGLE',
            'glDrawElementsInstanced'],
  'arguments':
      'GLenum mode, GLsizei count, GLenum type, const void* indices, '
      'GLsizei primcount', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glDrawRangeElements' }],
  'arguments': 'GLenum mode, GLuint start, GLuint end, GLsizei count, '
               'GLenum type, const void* indices', },
{ 'return_type': 'void',
  'names': ['glEGLImageTargetRenderbufferStorageOES'],
  'arguments': 'GLenum target, GLeglImageOES image', },
{ 'return_type': 'void',
  'names': ['glEGLImageTargetTexture2DOES'],
  'arguments': 'GLenum target, GLeglImageOES image', },
{ 'return_type': 'void',
  'names': ['glEnable'],
  'arguments': 'GLenum cap', },
{ 'return_type': 'void',
  'names': ['glEnableVertexAttribArray'],
  'arguments': 'GLuint index', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glEndQuery' },
               { 'name': 'glEndQueryARB' },
               { 'name': 'glEndQueryEXT',
                 'extensions': ['GL_EXT_occlusion_query_boolean'] }],
  'arguments': 'GLenum target', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glEndTransformFeedback' }],
  'arguments': 'void', },
{ 'return_type': 'GLsync',
  'versions': [{ 'name': 'glFenceSync',
                 'extensions': ['GL_ARB_sync'] }],
  'arguments': 'GLenum condition, GLbitfield flags', },
{ 'return_type': 'void',
  'names': ['glFinish'],
  'arguments': 'void', },
{ 'return_type': 'void',
  'known_as': 'glFinishFenceAPPLE',
  'versions': [{ 'name': 'glFinishFenceAPPLE',
                 'extensions': ['GL_APPLE_fence'] }],
  'arguments': 'GLuint fence', },
{ 'return_type': 'void',
  'names': ['glFinishFenceNV'],
  'arguments': 'GLuint fence', },
{ 'return_type': 'void',
  'names': ['glFlush'],
  'arguments': 'void', },
{ 'return_type': 'void',
  'names': ['glFlushMappedBufferRange'],
  'arguments': 'GLenum target, GLintptr offset, GLsizeiptr length', },
{ 'return_type': 'void',
  'names': ['glFramebufferRenderbufferEXT', 'glFramebufferRenderbuffer'],
  'arguments':
      'GLenum target, GLenum attachment, GLenum renderbuffertarget, '
      'GLuint renderbuffer', },
{ 'return_type': 'void',
  'names': ['glFramebufferTexture2DEXT', 'glFramebufferTexture2D'],
  'arguments':
      'GLenum target, GLenum attachment, GLenum textarget, GLuint texture, '
      'GLint level', },
{ 'return_type': 'void',
  'names': ['glFramebufferTexture2DMultisampleEXT'],
  'arguments':
      'GLenum target, GLenum attachment, GLenum textarget, GLuint texture, '
      'GLint level, GLsizei samples', },
{ 'return_type': 'void',
  'names': ['glFramebufferTexture2DMultisampleIMG'],
  'arguments':
      'GLenum target, GLenum attachment, GLenum textarget, GLuint texture, '
      'GLint level, GLsizei samples', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glFramebufferTextureLayer' }],
  'arguments': 'GLenum target, GLenum attachment, GLuint texture, GLint level, '
               'GLint layer', },
{ 'return_type': 'void',
  'names': ['glFrontFace'],
  'arguments': 'GLenum mode', },
{ 'return_type': 'void',
  'names': ['glGenBuffers'],
  'known_as': 'glGenBuffersARB',
  'arguments': 'GLsizei n, GLuint* buffers', },
{ 'return_type': 'void',
  'names': ['glGenerateMipmapEXT', 'glGenerateMipmap'],
  'arguments': 'GLenum target', },
{ 'return_type': 'void',
  'known_as': 'glGenFencesAPPLE',
  'versions': [{ 'name': 'glGenFencesAPPLE',
                 'extensions': ['GL_APPLE_fence'] }],
  'arguments': 'GLsizei n, GLuint* fences', },
{ 'return_type': 'void',
  'names': ['glGenFencesNV'],
  'arguments': 'GLsizei n, GLuint* fences', },
{ 'return_type': 'void',
  'names': ['glGenFramebuffersEXT', 'glGenFramebuffers'],
  'arguments': 'GLsizei n, GLuint* framebuffers', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGenQueries' },
               { 'name': 'glGenQueriesARB', },
               { 'name' : 'glGenQueriesEXT',
                 'extensions': ['GL_EXT_occlusion_query_boolean'] }],
  'arguments': 'GLsizei n, GLuint* ids', },
{ 'return_type': 'void',
  'names': ['glGenRenderbuffersEXT', 'glGenRenderbuffers'],
  'arguments': 'GLsizei n, GLuint* renderbuffers', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGenSamplers' }],
  'arguments': 'GLsizei n, GLuint* samplers', },
{ 'return_type': 'void',
  'names': ['glGenTextures'],
  'arguments': 'GLsizei n, GLuint* textures', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGenTransformFeedbacks' }],
  'arguments': 'GLsizei n, GLuint* ids', },
{ 'return_type': 'void',
  'known_as': 'glGenVertexArraysOES',
  'versions': [{ 'name': 'glGenVertexArrays',
                 'extensions': ['GL_ARB_vertex_array_object'], },
               { 'name': 'glGenVertexArraysOES' },
               { 'name': 'glGenVertexArraysAPPLE',
                 'extensions': ['GL_APPLE_vertex_array_object'] }],
  'arguments': 'GLsizei n, GLuint* arrays', },
{ 'return_type': 'void',
  'names': ['glGetActiveAttrib'],
  'arguments':
      'GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, '
      'GLint* size, GLenum* type, char* name', },
{ 'return_type': 'void',
  'names': ['glGetActiveUniform'],
  'arguments':
      'GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, '
      'GLint* size, GLenum* type, char* name', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetActiveUniformBlockiv' }],
  'arguments': 'GLuint program, GLuint uniformBlockIndex, GLenum pname, '
               'GLint* params', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetActiveUniformBlockName' }],
  'arguments': 'GLuint program, GLuint uniformBlockIndex, GLsizei bufSize, '
               'GLsizei* length, char* uniformBlockName', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetActiveUniformsiv' }],
  'arguments': 'GLuint program, GLsizei uniformCount, '
               'const GLuint* uniformIndices, GLenum pname, GLint* params', },
{ 'return_type': 'void',
  'names': ['glGetAttachedShaders'],
  'arguments':
      'GLuint program, GLsizei maxcount, GLsizei* count, GLuint* shaders', },
{ 'return_type': 'GLint',
  'names': ['glGetAttribLocation'],
  'arguments': 'GLuint program, const char* name', },
{ 'return_type': 'void',
  'names': ['glGetBooleanv'],
  'arguments': 'GLenum pname, GLboolean* params', },
{ 'return_type': 'void',
  'names': ['glGetBufferParameteriv'],
  'arguments': 'GLenum target, GLenum pname, GLint* params', },
{ 'return_type': 'GLenum',
  'names': ['glGetError'],
  'arguments': 'void',
  'logging_code': """
  GL_SERVICE_LOG("GL_RESULT: " << GLEnums::GetStringError(result));
""", },
{ 'return_type': 'void',
  'names': ['glGetFenceivNV'],
  'arguments': 'GLuint fence, GLenum pname, GLint* params', },
{ 'return_type': 'void',
  'names': ['glGetFloatv'],
  'arguments': 'GLenum pname, GLfloat* params', },
{ 'return_type': 'GLint',
  'versions': [{ 'name': 'glGetFragDataLocation' }],
  'arguments': 'GLuint program, const char* name', },
{ 'return_type': 'void',
  'names': ['glGetFramebufferAttachmentParameterivEXT',
            'glGetFramebufferAttachmentParameteriv'],
  'arguments': 'GLenum target, '
               'GLenum attachment, GLenum pname, GLint* params', },
{ 'return_type': 'GLenum',
  'names': ['glGetGraphicsResetStatusARB',
            'glGetGraphicsResetStatusKHR',
            'glGetGraphicsResetStatusEXT',
            'glGetGraphicsResetStatus'],
  'arguments': 'void', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetInteger64i_v' }],
  'arguments': 'GLenum target, GLuint index, GLint64* data', },
{ 'return_type': 'void',
  'names': ['glGetInteger64v'],
  'arguments': 'GLenum pname, GLint64* params', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetIntegeri_v' }],
  'arguments': 'GLenum target, GLuint index, GLint* data', },
{ 'return_type': 'void',
  'names': ['glGetIntegerv'],
  'arguments': 'GLenum pname, GLint* params', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetInternalformativ' }],
  'arguments': 'GLenum target, GLenum internalformat, GLenum pname, '
               'GLsizei bufSize, GLint* params', },
{ 'return_type': 'void',
  'known_as': 'glGetProgramBinary',
  'versions': [{ 'name': 'glGetProgramBinaryOES' },
               { 'name': 'glGetProgramBinary',
                 'extensions': ['GL_ARB_get_program_binary'] }],
  'arguments': 'GLuint program, GLsizei bufSize, GLsizei* length, '
               'GLenum* binaryFormat, GLvoid* binary' },
{ 'return_type': 'void',
  'names': ['glGetProgramInfoLog'],
  'arguments':
      'GLuint program, GLsizei bufsize, GLsizei* length, char* infolog', },
{ 'return_type': 'void',
  'names': ['glGetProgramiv'],
  'arguments': 'GLuint program, GLenum pname, GLint* params', },
{ 'return_type': 'GLint',
  'names': ['glGetProgramResourceLocation'],
  'arguments': 'GLuint program, GLenum programInterface, const char* name', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetQueryiv' },
               { 'name': 'glGetQueryivARB' },
               { 'name': 'glGetQueryivEXT',
                 'extensions': ['GL_EXT_occlusion_query_boolean'] }],
  'arguments': 'GLenum target, GLenum pname, GLint* params', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetQueryObjecti64v',
                 'extensions': ['GL_ARB_timer_query'] },
               { 'name': 'glGetQueryObjecti64vEXT' }],
  'arguments': 'GLuint id, GLenum pname, GLint64* params', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetQueryObjectiv' },
               { 'name': 'glGetQueryObjectivARB' },
               { 'name': 'glGetQueryObjectivEXT' }],
  'arguments': 'GLuint id, GLenum pname, GLint* params', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetQueryObjectui64v',
                 'extensions': ['GL_ARB_timer_query'] },
               { 'name': 'glGetQueryObjectui64vEXT' }],
  'arguments': 'GLuint id, GLenum pname, GLuint64* params', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetQueryObjectuiv' },
               { 'name': 'glGetQueryObjectuivARB' },
               { 'name': 'glGetQueryObjectuivEXT',
                 'extensions': ['GL_EXT_occlusion_query_boolean'] }],
  'arguments': 'GLuint id, GLenum pname, GLuint* params', },
{ 'return_type': 'void',
  'names': ['glGetRenderbufferParameterivEXT', 'glGetRenderbufferParameteriv'],
  'arguments': 'GLenum target, GLenum pname, GLint* params', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetSamplerParameterfv' }],
  'arguments': 'GLuint sampler, GLenum pname, GLfloat* params', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetSamplerParameteriv' }],
  'arguments': 'GLuint sampler, GLenum pname, GLint* params', },
{ 'return_type': 'void',
  'names': ['glGetShaderInfoLog'],
  'arguments':
      'GLuint shader, GLsizei bufsize, GLsizei* length, char* infolog', },
{ 'return_type': 'void',
  'names': ['glGetShaderiv'],
  'arguments': 'GLuint shader, GLenum pname, GLint* params', },
{ 'return_type': 'void',
  'names': ['glGetShaderPrecisionFormat'],
  'arguments': 'GLenum shadertype, GLenum precisiontype, '
               'GLint* range, GLint* precision', },
{ 'return_type': 'void',
  'names': ['glGetShaderSource'],
  'arguments':
      'GLuint shader, GLsizei bufsize, GLsizei* length, char* source', },
{ 'return_type': 'const GLubyte*',
  'names': ['glGetString'],
  'arguments': 'GLenum name', },
{ 'return_type': 'const GLubyte*',
  'names': ['glGetStringi'],
  'arguments': 'GLenum name, GLuint index', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetSynciv',
                 'extensions': ['GL_ARB_sync'] }],
  'arguments':
    'GLsync sync, GLenum pname, GLsizei bufSize, GLsizei* length,'
    'GLint* values', },
{ 'return_type': 'void',
  'names': ['glGetTexLevelParameterfv'],
  'arguments': 'GLenum target, GLint level, GLenum pname, GLfloat* params', },
{ 'return_type': 'void',
  'names': ['glGetTexLevelParameteriv'],
  'arguments': 'GLenum target, GLint level, GLenum pname, GLint* params', },
{ 'return_type': 'void',
  'names': ['glGetTexParameterfv'],
  'arguments': 'GLenum target, GLenum pname, GLfloat* params', },
{ 'return_type': 'void',
  'names': ['glGetTexParameteriv'],
  'arguments': 'GLenum target, GLenum pname, GLint* params', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetTransformFeedbackVarying' }],
  'arguments': 'GLuint program, GLuint index, GLsizei bufSize, '
               'GLsizei* length, GLsizei* size, GLenum* type, char* name', },
{ 'return_type': 'void',
  'names': ['glGetTranslatedShaderSourceANGLE'],
  'arguments':
      'GLuint shader, GLsizei bufsize, GLsizei* length, char* source', },
{ 'return_type': 'GLuint',
  'versions': [{ 'name': 'glGetUniformBlockIndex' }],
  'arguments': 'GLuint program, const char* uniformBlockName', },
{ 'return_type': 'void',
  'names': ['glGetUniformfv'],
  'arguments': 'GLuint program, GLint location, GLfloat* params', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glGetUniformIndices' }],
  'arguments': 'GLuint program, GLsizei uniformCount, '
               'const char* const* uniformNames, GLuint* uniformIndices', },
{ 'return_type': 'void',
  'names': ['glGetUniformiv'],
  'arguments': 'GLuint program, GLint location, GLint* params', },
{ 'return_type': 'GLint',
  'names': ['glGetUniformLocation'],
  'arguments': 'GLuint program, const char* name', },
{ 'return_type': 'void',
  'names': ['glGetVertexAttribfv'],
  'arguments': 'GLuint index, GLenum pname, GLfloat* params', },
{ 'return_type': 'void',
  'names': ['glGetVertexAttribiv'],
  'arguments': 'GLuint index, GLenum pname, GLint* params', },
{ 'return_type': 'void',
  'names': ['glGetVertexAttribPointerv'],
  'arguments': 'GLuint index, GLenum pname, void** pointer', },
{ 'return_type': 'void',
  'names': ['glHint'],
  'arguments': 'GLenum target, GLenum mode', },
{ 'return_type': 'void',
  'names': ['glInsertEventMarkerEXT'],
  'arguments': 'GLsizei length, const char* marker', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glInvalidateFramebuffer' }],
  'arguments': 'GLenum target, GLsizei numAttachments, '
      'const GLenum* attachments' },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glInvalidateSubFramebuffer' }],
  'arguments':
      'GLenum target, GLsizei numAttachments, const GLenum* attachments, '
      'GLint x, GLint y, GLint width, GLint height', },
{ 'return_type': 'GLboolean',
  'names': ['glIsBuffer'],
  'arguments': 'GLuint buffer', },
{ 'return_type': 'GLboolean',
  'names': ['glIsEnabled'],
  'arguments': 'GLenum cap', },
{ 'return_type': 'GLboolean',
  'known_as': 'glIsFenceAPPLE',
  'versions': [{ 'name': 'glIsFenceAPPLE',
                 'extensions': ['GL_APPLE_fence'] }],
  'arguments': 'GLuint fence', },
{ 'return_type': 'GLboolean',
  'names': ['glIsFenceNV'],
  'arguments': 'GLuint fence', },
{ 'return_type': 'GLboolean',
  'names': ['glIsFramebufferEXT', 'glIsFramebuffer'],
  'arguments': 'GLuint framebuffer', },
{ 'return_type': 'GLboolean',
  'names': ['glIsProgram'],
  'arguments': 'GLuint program', },
{ 'return_type': 'GLboolean',
  'versions': [{ 'name': 'glIsQuery' },
               { 'name': 'glIsQueryARB' },
               { 'name': 'glIsQueryEXT',
                 'extensions': ['GL_EXT_occlusion_query_boolean'] }],
  'arguments': 'GLuint query', },
{ 'return_type': 'GLboolean',
  'names': ['glIsRenderbufferEXT', 'glIsRenderbuffer'],
  'arguments': 'GLuint renderbuffer', },
{ 'return_type': 'GLboolean',
  'versions': [{ 'name': 'glIsSampler' }],
  'arguments': 'GLuint sampler', },
{ 'return_type': 'GLboolean',
  'names': ['glIsShader'],
  'arguments': 'GLuint shader', },
{ 'return_type': 'GLboolean',
  'versions': [{ 'name': 'glIsSync',
                 'extensions': ['GL_ARB_sync'] }],
  'arguments': 'GLsync sync', },
{ 'return_type': 'GLboolean',
  'names': ['glIsTexture'],
  'arguments': 'GLuint texture', },
{ 'return_type': 'GLboolean',
  'versions': [{ 'name': 'glIsTransformFeedback' }],
  'arguments': 'GLuint id', },
{ 'return_type': 'GLboolean',
  'known_as': 'glIsVertexArrayOES',
  'versions': [{ 'name': 'glIsVertexArray',
                 'extensions': ['GL_ARB_vertex_array_object'], },
               { 'name': 'glIsVertexArrayOES' },
               { 'name': 'glIsVertexArrayAPPLE',
                 'extensions': ['GL_APPLE_vertex_array_object'] }],
  'arguments': 'GLuint array' },
{ 'return_type': 'void',
  'names': ['glLineWidth'],
  'arguments': 'GLfloat width', },
{ 'return_type': 'void',
  'names': ['glLinkProgram'],
  'arguments': 'GLuint program', },
{ 'return_type': 'void*',
  'known_as': 'glMapBuffer',
  'names': ['glMapBufferOES', 'glMapBuffer'],
  'arguments': 'GLenum target, GLenum access', },
{ 'return_type': 'void*',
  'known_as': 'glMapBufferRange',
  'versions': [{ 'name': 'glMapBufferRange',
                 'extensions': ['GL_ARB_map_buffer_range'] },
               { 'name': 'glMapBufferRangeEXT',
                 'extensions': ['GL_EXT_map_buffer_range'] }],
  'arguments':
      'GLenum target, GLintptr offset, GLsizeiptr length, GLbitfield access', },
{ 'return_type': 'void',
  'known_as': 'glMatrixLoadfEXT',
  'versions': [{ 'name': 'glMatrixLoadfEXT',
                 'extensions': ['GL_EXT_direct_state_access',
                                'GL_NV_path_rendering'] }],
  'arguments': 'GLenum matrixMode, const GLfloat* m' },
{ 'return_type': 'void',
  'known_as': 'glMatrixLoadIdentityEXT',
  'versions': [{ 'name': 'glMatrixLoadIdentityEXT',
                 'extensions': ['GL_EXT_direct_state_access',
                                'GL_NV_path_rendering'] },],
  'arguments': 'GLenum matrixMode' },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glPauseTransformFeedback' }],
  'arguments': 'void', },
{ 'return_type': 'void',
  'names': ['glPixelStorei'],
  'arguments': 'GLenum pname, GLint param', },
{ 'return_type': 'void',
  'names': ['glPointParameteri'],
  'arguments': 'GLenum pname, GLint param', },
{ 'return_type': 'void',
  'names': ['glPolygonOffset'],
  'arguments': 'GLfloat factor, GLfloat units', },
{ 'return_type': 'void',
  'names': ['glPopGroupMarkerEXT'],
  'arguments': 'void', },
{ 'return_type': 'void',
  'known_as': 'glProgramBinary',
  'versions': [{ 'name': 'glProgramBinaryOES' },
               { 'name': 'glProgramBinary',
                 'extensions': ['GL_ARB_get_program_binary'] }],
  'arguments': 'GLuint program, GLenum binaryFormat, '
               'const GLvoid* binary, GLsizei length' },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glProgramParameteri',
                 'extensions': ['GL_ARB_get_program_binary'] }],
  'arguments': 'GLuint program, GLenum pname, GLint value' },
{ 'return_type': 'void',
  'names': ['glPushGroupMarkerEXT'],
  'arguments': 'GLsizei length, const char* marker', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glQueryCounter',
                 'extensions': ['GL_ARB_timer_query'] },
               { 'name': 'glQueryCounterEXT' }],
  'arguments': 'GLuint id, GLenum target', },
{ 'return_type': 'void',
  'names': ['glReadBuffer'],
  'arguments': 'GLenum src', },
{ 'return_type': 'void',
  'names': ['glReadPixels'],
  'arguments':
    'GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, '
    'GLenum type, void* pixels', },
{ 'return_type': 'void',
  'names': ['glReleaseShaderCompiler'],
  'arguments': 'void', },
{ 'return_type': 'void',
  'names': ['glRenderbufferStorageEXT', 'glRenderbufferStorage'],
  'arguments':
      'GLenum target, GLenum internalformat, GLsizei width, GLsizei height', },
{ 'return_type': 'void',
  'names': ['glRenderbufferStorageMultisample'],
  'arguments': 'GLenum target, GLsizei samples, GLenum internalformat, '
               'GLsizei width, GLsizei height', },
{ 'return_type': 'void',
  'names': ['glRenderbufferStorageMultisampleANGLE'],
  'arguments': 'GLenum target, GLsizei samples, GLenum internalformat, '
               'GLsizei width, GLsizei height', },
{ 'return_type': 'void',
  'names': ['glRenderbufferStorageMultisampleAPPLE'],
  'arguments': 'GLenum target, GLsizei samples, GLenum internalformat, '
               'GLsizei width, GLsizei height', },
{ 'return_type': 'void',
  'names': ['glRenderbufferStorageMultisampleEXT'],
  'arguments': 'GLenum target, GLsizei samples, GLenum internalformat, '
               'GLsizei width, GLsizei height', },
{ 'return_type': 'void',
  'names': ['glRenderbufferStorageMultisampleIMG'],
  'arguments': 'GLenum target, GLsizei samples, GLenum internalformat, '
               'GLsizei width, GLsizei height', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glResolveMultisampleFramebufferAPPLE' }],
  'arguments': 'void', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glResumeTransformFeedback' }],
  'arguments': 'void', },
{ 'return_type': 'void',
  'names': ['glSampleCoverage'],
  'arguments': 'GLclampf value, GLboolean invert', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glSamplerParameterf' }],
  'arguments': 'GLuint sampler, GLenum pname, GLfloat param', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glSamplerParameterfv' }],
  'arguments': 'GLuint sampler, GLenum pname, const GLfloat* params', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glSamplerParameteri' }],
  'arguments': 'GLuint sampler, GLenum pname, GLint param', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glSamplerParameteriv' }],
  'arguments': 'GLuint sampler, GLenum pname, const GLint* params', },
{ 'return_type': 'void',
  'names': ['glScissor'],
  'arguments': 'GLint x, GLint y, GLsizei width, GLsizei height', },
{ 'return_type': 'void',
  'known_as': 'glSetFenceAPPLE',
  'versions': [{ 'name': 'glSetFenceAPPLE',
                 'extensions': ['GL_APPLE_fence'] }],
  'arguments': 'GLuint fence', },
{ 'return_type': 'void',
  'names': ['glSetFenceNV'],
  'arguments': 'GLuint fence, GLenum condition', },
{ 'return_type': 'void',
  'names': ['glShaderBinary'],
  'arguments': 'GLsizei n, const GLuint* shaders, GLenum binaryformat, '
               'const void* binary, GLsizei length', },
{ 'return_type': 'void',
  'names': ['glShaderSource'],
  'arguments': 'GLuint shader, GLsizei count, const char* const* str, '
               'const GLint* length',
  'logging_code': """
  GL_SERVICE_LOG_CODE_BLOCK({
    for (GLsizei ii = 0; ii < count; ++ii) {
      if (str[ii]) {
        if (length && length[ii] >= 0) {
          std::string source(str[ii], length[ii]);
          GL_SERVICE_LOG("  " << ii << ": ---\\n" << source << "\\n---");
        } else {
          GL_SERVICE_LOG("  " << ii << ": ---\\n" << str[ii] << "\\n---");
        }
      } else {
        GL_SERVICE_LOG("  " << ii << ": NULL");
      }
    }
  });
""", },
{ 'return_type': 'void',
  'names': ['glStencilFunc'],
  'arguments': 'GLenum func, GLint ref, GLuint mask', },
{ 'return_type': 'void',
  'names': ['glStencilFuncSeparate'],
  'arguments': 'GLenum face, GLenum func, GLint ref, GLuint mask', },
{ 'return_type': 'void',
  'names': ['glStencilMask'],
  'arguments': 'GLuint mask', },
{ 'return_type': 'void',
  'names': ['glStencilMaskSeparate'],
  'arguments': 'GLenum face, GLuint mask', },
{ 'return_type': 'void',
  'names': ['glStencilOp'],
  'arguments': 'GLenum fail, GLenum zfail, GLenum zpass', },
{ 'return_type': 'void',
  'names': ['glStencilOpSeparate'],
  'arguments': 'GLenum face, GLenum fail, GLenum zfail, GLenum zpass', },
{ 'return_type': 'GLboolean',
  'known_as': 'glTestFenceAPPLE',
  'versions': [{ 'name': 'glTestFenceAPPLE',
                 'extensions': ['GL_APPLE_fence'] }],
  'arguments': 'GLuint fence', },
{ 'return_type': 'GLboolean',
  'names': ['glTestFenceNV'],
  'arguments': 'GLuint fence', },
{ 'return_type': 'void',
  'names': ['glTexImage2D'],
  'arguments':
      'GLenum target, GLint level, GLint internalformat, GLsizei width, '
      'GLsizei height, GLint border, GLenum format, GLenum type, '
      'const void* pixels', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glTexImage3D' }],
  'arguments':
      'GLenum target, GLint level, GLint internalformat, GLsizei width, '
      'GLsizei height, GLsizei depth, GLint border, GLenum format, '
      'GLenum type, const void* pixels', },
{ 'return_type': 'void',
  'names': ['glTexParameterf'],
  'arguments': 'GLenum target, GLenum pname, GLfloat param', },
{ 'return_type': 'void',
  'names': ['glTexParameterfv'],
  'arguments': 'GLenum target, GLenum pname, const GLfloat* params', },
{ 'return_type': 'void',
  'names': ['glTexParameteri'],
  'arguments': 'GLenum target, GLenum pname, GLint param', },
{ 'return_type': 'void',
  'names': ['glTexParameteriv'],
  'arguments': 'GLenum target, GLenum pname, const GLint* params', },
{ 'return_type': 'void',
  'known_as': 'glTexStorage2DEXT',
  'versions': [{ 'name': 'glTexStorage2D',
                 'extensions': ['GL_ARB_texture_storage'] },
               { 'name': 'glTexStorage2DEXT',
                 'extensions': ['GL_EXT_texture_storage'] }],
  'arguments': 'GLenum target, GLsizei levels, GLenum internalformat, '
               'GLsizei width, GLsizei height', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glTexStorage3D' }],
  'arguments': 'GLenum target, GLsizei levels, GLenum internalformat, '
               'GLsizei width, GLsizei height, GLsizei depth', },
{ 'return_type': 'void',
  'names': ['glTexSubImage2D'],
  'arguments':
     'GLenum target, GLint level, GLint xoffset, GLint yoffset, '
     'GLsizei width, GLsizei height, GLenum format, GLenum type, '
     'const void* pixels', },
# TODO(zmo): wait for MOCK_METHOD11.
# { 'return_type': 'void',
#   'versions': [{ 'name': 'glTexSubImage3D' }],
#   'arguments':
#       'GLenum target, GLint level, GLint xoffset, GLint yoffset, '
#       'GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, '
#       'GLenum format, GLenum type, const void* pixels', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glTransformFeedbackVaryings' }],
  'arguments': 'GLuint program, GLsizei count, const char* const* varyings, '
               'GLenum bufferMode', },
{ 'return_type': 'void',
  'names': ['glUniform1f'],
  'arguments': 'GLint location, GLfloat x', },
{ 'return_type': 'void',
  'names': ['glUniform1fv'],
  'arguments': 'GLint location, GLsizei count, const GLfloat* v', },
{ 'return_type': 'void',
  'names': ['glUniform1i'],
  'arguments': 'GLint location, GLint x', },
{ 'return_type': 'void',
  'names': ['glUniform1iv'],
  'arguments': 'GLint location, GLsizei count, const GLint* v', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniform1ui' }],
  'arguments': 'GLint location, GLuint v0', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniform1uiv' }],
  'arguments': 'GLint location, GLsizei count, const GLuint* v', },
{ 'return_type': 'void',
  'names': ['glUniform2f'],
  'arguments': 'GLint location, GLfloat x, GLfloat y', },
{ 'return_type': 'void',
  'names': ['glUniform2fv'],
  'arguments': 'GLint location, GLsizei count, const GLfloat* v', },
{ 'return_type': 'void',
  'names': ['glUniform2i'],
  'arguments': 'GLint location, GLint x, GLint y', },
{ 'return_type': 'void',
  'names': ['glUniform2iv'],
  'arguments': 'GLint location, GLsizei count, const GLint* v', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniform2ui' }],
  'arguments': 'GLint location, GLuint v0, GLuint v1', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniform2uiv' }],
  'arguments': 'GLint location, GLsizei count, const GLuint* v', },
{ 'return_type': 'void',
  'names': ['glUniform3f'],
  'arguments': 'GLint location, GLfloat x, GLfloat y, GLfloat z', },
{ 'return_type': 'void',
  'names': ['glUniform3fv'],
  'arguments': 'GLint location, GLsizei count, const GLfloat* v', },
{ 'return_type': 'void',
  'names': ['glUniform3i'],
  'arguments': 'GLint location, GLint x, GLint y, GLint z', },
{ 'return_type': 'void',
  'names': ['glUniform3iv'],
  'arguments': 'GLint location, GLsizei count, const GLint* v', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniform3ui' }],
  'arguments': 'GLint location, GLuint v0, GLuint v1, GLuint v2', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniform3uiv' }],
  'arguments': 'GLint location, GLsizei count, const GLuint* v', },
{ 'return_type': 'void',
  'names': ['glUniform4f'],
  'arguments': 'GLint location, GLfloat x, GLfloat y, GLfloat z, GLfloat w', },
{ 'return_type': 'void',
  'names': ['glUniform4fv'],
  'arguments': 'GLint location, GLsizei count, const GLfloat* v', },
{ 'return_type': 'void',
  'names': ['glUniform4i'],
  'arguments': 'GLint location, GLint x, GLint y, GLint z, GLint w', },
{ 'return_type': 'void',
  'names': ['glUniform4iv'],
  'arguments': 'GLint location, GLsizei count, const GLint* v', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniform4ui' }],
  'arguments': 'GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniform4uiv' }],
  'arguments': 'GLint location, GLsizei count, const GLuint* v', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniformBlockBinding' }],
  'arguments': 'GLuint program, GLuint uniformBlockIndex, '
               'GLuint uniformBlockBinding', },
{ 'return_type': 'void',
  'names': ['glUniformMatrix2fv'],
  'arguments': 'GLint location, GLsizei count, '
               'GLboolean transpose, const GLfloat* value', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniformMatrix2x3fv' }],
  'arguments': 'GLint location, GLsizei count, '
               'GLboolean transpose, const GLfloat* value', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniformMatrix2x4fv' }],
  'arguments': 'GLint location, GLsizei count, '
               'GLboolean transpose, const GLfloat* value', },
{ 'return_type': 'void',
  'names': ['glUniformMatrix3fv'],
  'arguments': 'GLint location, GLsizei count, '
               'GLboolean transpose, const GLfloat* value', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniformMatrix3x2fv' }],
  'arguments': 'GLint location, GLsizei count, '
               'GLboolean transpose, const GLfloat* value', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniformMatrix3x4fv' }],
  'arguments': 'GLint location, GLsizei count, '
               'GLboolean transpose, const GLfloat* value', },
{ 'return_type': 'void',
  'names': ['glUniformMatrix4fv'],
  'arguments': 'GLint location, GLsizei count, '
               'GLboolean transpose, const GLfloat* value', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniformMatrix4x2fv' }],
  'arguments': 'GLint location, GLsizei count, '
               'GLboolean transpose, const GLfloat* value', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glUniformMatrix4x3fv' }],
  'arguments': 'GLint location, GLsizei count, '
               'GLboolean transpose, const GLfloat* value', },
{ 'return_type': 'GLboolean',
  'known_as': 'glUnmapBuffer',
  'names': ['glUnmapBufferOES', 'glUnmapBuffer'],
  'arguments': 'GLenum target', },
{ 'return_type': 'void',
  'names': ['glUseProgram'],
  'arguments': 'GLuint program', },
{ 'return_type': 'void',
  'names': ['glValidateProgram'],
  'arguments': 'GLuint program', },
{ 'return_type': 'void',
  'names': ['glVertexAttrib1f'],
  'arguments': 'GLuint indx, GLfloat x', },
{ 'return_type': 'void',
  'names': ['glVertexAttrib1fv'],
  'arguments': 'GLuint indx, const GLfloat* values', },
{ 'return_type': 'void',
  'names': ['glVertexAttrib2f'],
  'arguments': 'GLuint indx, GLfloat x, GLfloat y', },
{ 'return_type': 'void',
  'names': ['glVertexAttrib2fv'],
  'arguments': 'GLuint indx, const GLfloat* values', },
{ 'return_type': 'void',
  'names': ['glVertexAttrib3f'],
  'arguments': 'GLuint indx, GLfloat x, GLfloat y, GLfloat z', },
{ 'return_type': 'void',
  'names': ['glVertexAttrib3fv'],
  'arguments': 'GLuint indx, const GLfloat* values', },
{ 'return_type': 'void',
  'names': ['glVertexAttrib4f'],
  'arguments': 'GLuint indx, GLfloat x, GLfloat y, GLfloat z, GLfloat w', },
{ 'return_type': 'void',
  'names': ['glVertexAttrib4fv'],
  'arguments': 'GLuint indx, const GLfloat* values', },
{ 'return_type': 'void',
  'known_as': 'glVertexAttribDivisorANGLE',
  'names': ['glVertexAttribDivisorARB', 'glVertexAttribDivisorANGLE',
            'glVertexAttribDivisor'],
  'arguments':
      'GLuint index, GLuint divisor', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glVertexAttribI4i' }],
  'arguments': 'GLuint indx, GLint x, GLint y, GLint z, GLint w', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glVertexAttribI4iv' }],
  'arguments': 'GLuint indx, const GLint* values', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glVertexAttribI4ui' }],
  'arguments': 'GLuint indx, GLuint x, GLuint y, GLuint z, GLuint w', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glVertexAttribI4uiv' }],
  'arguments': 'GLuint indx, const GLuint* values', },
{ 'return_type': 'void',
  'versions': [{ 'name': 'glVertexAttribIPointer' }],
  'arguments': 'GLuint indx, GLint size, GLenum type, GLsizei stride, '
               'const void* ptr', },
{ 'return_type': 'void',
  'names': ['glVertexAttribPointer'],
  'arguments': 'GLuint indx, GLint size, GLenum type, GLboolean normalized, '
               'GLsizei stride, const void* ptr', },
{ 'return_type': 'void',
  'names': ['glViewport'],
  'arguments': 'GLint x, GLint y, GLsizei width, GLsizei height', },
{ 'return_type': 'GLenum',
  'versions': [{ 'name': 'glWaitSync',
                 'extensions': ['GL_ARB_sync'] }],
  'arguments':
    'GLsync sync, GLbitfield flags, GLuint64 timeout', },
]

OSMESA_FUNCTIONS = [
{ 'return_type': 'void',
  'names': ['OSMesaColorClamp'],
  'arguments': 'GLboolean enable', },
{ 'return_type': 'OSMesaContext',
  'names': ['OSMesaCreateContext'],
  'arguments': 'GLenum format, OSMesaContext sharelist', },
{ 'return_type': 'OSMesaContext',
  'names': ['OSMesaCreateContextExt'],
  'arguments':
      'GLenum format, GLint depthBits, GLint stencilBits, GLint accumBits, '
      'OSMesaContext sharelist', },
{ 'return_type': 'void',
  'names': ['OSMesaDestroyContext'],
  'arguments': 'OSMesaContext ctx', },
{ 'return_type': 'GLboolean',
  'names': ['OSMesaGetColorBuffer'],
  'arguments': 'OSMesaContext c, GLint* width, GLint* height, GLint* format, '
               'void** buffer', },
{ 'return_type': 'OSMesaContext',
  'names': ['OSMesaGetCurrentContext'],
  'arguments': 'void', },
{ 'return_type': 'GLboolean',
  'names': ['OSMesaGetDepthBuffer'],
  'arguments':
      'OSMesaContext c, GLint* width, GLint* height, GLint* bytesPerValue, '
      'void** buffer', },
{ 'return_type': 'void',
  'names': ['OSMesaGetIntegerv'],
  'arguments': 'GLint pname, GLint* value', },
{ 'return_type': 'OSMESAproc',
  'names': ['OSMesaGetProcAddress'],
  'arguments': 'const char* funcName', },
{ 'return_type': 'GLboolean',
  'names': ['OSMesaMakeCurrent'],
  'arguments': 'OSMesaContext ctx, void* buffer, GLenum type, GLsizei width, '
               'GLsizei height', },
{ 'return_type': 'void',
  'names': ['OSMesaPixelStore'],
  'arguments': 'GLint pname, GLint value', },
]

EGL_FUNCTIONS = [
{ 'return_type': 'EGLBoolean',
  'names': ['eglBindAPI'],
  'arguments': 'EGLenum api', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglBindTexImage'],
  'arguments': 'EGLDisplay dpy, EGLSurface surface, EGLint buffer', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglChooseConfig'],
  'arguments': 'EGLDisplay dpy, const EGLint* attrib_list, EGLConfig* configs, '
               'EGLint config_size, EGLint* num_config', },
{ 'return_type': 'EGLint',
  'versions': [{ 'name': 'eglClientWaitSyncKHR',
                 'extensions': ['EGL_KHR_fence_sync'] }],
  'arguments': 'EGLDisplay dpy, EGLSyncKHR sync, EGLint flags, '
      'EGLTimeKHR timeout' },
{ 'return_type': 'EGLBoolean',
  'names': ['eglCopyBuffers'],
  'arguments':
      'EGLDisplay dpy, EGLSurface surface, EGLNativePixmapType target', },
{ 'return_type': 'EGLContext',
  'names': ['eglCreateContext'],
  'arguments': 'EGLDisplay dpy, EGLConfig config, EGLContext share_context, '
              'const EGLint* attrib_list', },
{ 'return_type': 'EGLImageKHR',
  'versions': [{ 'name': 'eglCreateImageKHR',
                 'extensions':
                     ['EGL_KHR_image_base', 'EGL_KHR_gl_texture_2D_image'] }],
  'arguments':
      'EGLDisplay dpy, EGLContext ctx, EGLenum target, EGLClientBuffer buffer, '
      'const EGLint* attrib_list' },
{ 'return_type': 'EGLSurface',
  'names': ['eglCreatePbufferFromClientBuffer'],
  'arguments':
      'EGLDisplay dpy, EGLenum buftype, void* buffer, EGLConfig config, '
      'const EGLint* attrib_list', },
{ 'return_type': 'EGLSurface',
  'names': ['eglCreatePbufferSurface'],
  'arguments': 'EGLDisplay dpy, EGLConfig config, const EGLint* attrib_list', },
{ 'return_type': 'EGLSurface',
  'names': ['eglCreatePixmapSurface'],
  'arguments': 'EGLDisplay dpy, EGLConfig config, EGLNativePixmapType pixmap, '
               'const EGLint* attrib_list', },
{ 'return_type': 'EGLSyncKHR',
  'versions': [{ 'name': 'eglCreateSyncKHR',
                 'extensions': ['EGL_KHR_fence_sync'] }],
  'arguments': 'EGLDisplay dpy, EGLenum type, const EGLint* attrib_list' },
{ 'return_type': 'EGLSurface',
  'names': ['eglCreateWindowSurface'],
  'arguments': 'EGLDisplay dpy, EGLConfig config, EGLNativeWindowType win, '
               'const EGLint* attrib_list', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglDestroyContext'],
  'arguments': 'EGLDisplay dpy, EGLContext ctx', },
{ 'return_type': 'EGLBoolean',
  'versions': [{ 'name' : 'eglDestroyImageKHR',
                 'extensions': ['EGL_KHR_image_base'] }],
  'arguments': 'EGLDisplay dpy, EGLImageKHR image' },
{ 'return_type': 'EGLBoolean',
  'names': ['eglDestroySurface'],
  'arguments': 'EGLDisplay dpy, EGLSurface surface', },
{ 'return_type': 'EGLBoolean',
  'versions': [{ 'name': 'eglDestroySyncKHR',
                 'extensions': ['EGL_KHR_fence_sync'] }],
  'arguments': 'EGLDisplay dpy, EGLSyncKHR sync' },
{ 'return_type': 'EGLBoolean',
  'names': ['eglGetConfigAttrib'],
  'arguments':
      'EGLDisplay dpy, EGLConfig config, EGLint attribute, EGLint* value', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglGetConfigs'],
  'arguments': 'EGLDisplay dpy, EGLConfig* configs, EGLint config_size, '
               'EGLint* num_config', },
{ 'return_type': 'EGLContext',
  'names': ['eglGetCurrentContext'],
  'arguments': 'void', },
{ 'return_type': 'EGLDisplay',
  'names': ['eglGetCurrentDisplay'],
  'arguments': 'void', },
{ 'return_type': 'EGLSurface',
  'names': ['eglGetCurrentSurface'],
  'arguments': 'EGLint readdraw', },
{ 'return_type': 'EGLDisplay',
  'names': ['eglGetDisplay'],
  'arguments': 'EGLNativeDisplayType display_id', },
{ 'return_type': 'EGLint',
  'names': ['eglGetError'],
  'arguments': 'void', },
{ 'return_type': 'EGLDisplay',
  'known_as': 'eglGetPlatformDisplayEXT',
  'versions': [{ 'name': 'eglGetPlatformDisplayEXT',
                 'extensions': ['EGL_ANGLE_platform_angle'] }],
  'arguments': 'EGLenum platform, void* native_display, '
               'const EGLint* attrib_list', },
{ 'return_type': '__eglMustCastToProperFunctionPointerType',
  'names': ['eglGetProcAddress'],
  'arguments': 'const char* procname', },
{ 'return_type': 'EGLBoolean',
  'versions': [{ 'name': 'eglGetSyncAttribKHR',
                 'extensions': ['EGL_KHR_fence_sync'] }],
  'arguments': 'EGLDisplay dpy, EGLSyncKHR sync, EGLint attribute, '
      'EGLint* value' },
{ 'return_type': 'EGLBoolean',
  'names': ['eglGetSyncValuesCHROMIUM'],
  'arguments':
      'EGLDisplay dpy, EGLSurface surface, '
      'EGLuint64CHROMIUM* ust, EGLuint64CHROMIUM* msc, '
      'EGLuint64CHROMIUM* sbc', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglInitialize'],
  'arguments': 'EGLDisplay dpy, EGLint* major, EGLint* minor', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglMakeCurrent'],
  'arguments':
      'EGLDisplay dpy, EGLSurface draw, EGLSurface read, EGLContext ctx', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglPostSubBufferNV'],
  'arguments': 'EGLDisplay dpy, EGLSurface surface, '
    'EGLint x, EGLint y, EGLint width, EGLint height', },
{ 'return_type': 'EGLenum',
  'names': ['eglQueryAPI'],
  'arguments': 'void', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglQueryContext'],
  'arguments':
      'EGLDisplay dpy, EGLContext ctx, EGLint attribute, EGLint* value', },
{ 'return_type': 'const char*',
  'names': ['eglQueryString'],
  'arguments': 'EGLDisplay dpy, EGLint name', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglQuerySurface'],
  'arguments':
      'EGLDisplay dpy, EGLSurface surface, EGLint attribute, EGLint* value', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglQuerySurfacePointerANGLE'],
  'arguments':
      'EGLDisplay dpy, EGLSurface surface, EGLint attribute, void** value', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglReleaseTexImage'],
  'arguments': 'EGLDisplay dpy, EGLSurface surface, EGLint buffer', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglReleaseThread'],
  'arguments': 'void', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglSurfaceAttrib'],
  'arguments':
      'EGLDisplay dpy, EGLSurface surface, EGLint attribute, EGLint value', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglSwapBuffers'],
  'arguments': 'EGLDisplay dpy, EGLSurface surface', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglSwapInterval'],
  'arguments': 'EGLDisplay dpy, EGLint interval', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglTerminate'],
  'arguments': 'EGLDisplay dpy', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglWaitClient'],
  'arguments': 'void', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglWaitGL'],
  'arguments': 'void', },
{ 'return_type': 'EGLBoolean',
  'names': ['eglWaitNative'],
  'arguments': 'EGLint engine', },
{ 'return_type': 'EGLint',
  'versions': [{ 'name': 'eglWaitSyncKHR',
                 'extensions': ['EGL_KHR_wait_sync'] }],
  'arguments': 'EGLDisplay dpy, EGLSyncKHR sync, EGLint flags' },
]

WGL_FUNCTIONS = [
{ 'return_type': 'BOOL',
  'names': ['wglChoosePixelFormatARB'],
  'arguments':
      'HDC dc, const int* int_attrib_list, const float* float_attrib_list, '
      'UINT max_formats, int* formats, UINT* num_formats', },
{ 'return_type': 'BOOL',
  'names': ['wglCopyContext'],
  'arguments': 'HGLRC hglrcSrc, HGLRC hglrcDst, UINT mask', },
{ 'return_type': 'HGLRC',
  'names': ['wglCreateContext'],
  'arguments': 'HDC hdc', },
{ 'return_type': 'HGLRC',
  'names': ['wglCreateLayerContext'],
  'arguments': 'HDC hdc, int iLayerPlane', },
{ 'return_type': 'HPBUFFERARB',
  'names': ['wglCreatePbufferARB'],
  'arguments': 'HDC hDC, int iPixelFormat, int iWidth, int iHeight, '
               'const int* piAttribList', },
{ 'return_type': 'BOOL',
  'names': ['wglDeleteContext'],
  'arguments': 'HGLRC hglrc', },
{ 'return_type': 'BOOL',
  'names': ['wglDestroyPbufferARB'],
  'arguments': 'HPBUFFERARB hPbuffer', },
{ 'return_type': 'HGLRC',
  'names': ['wglGetCurrentContext'],
  'arguments': '', },
{ 'return_type': 'HDC',
  'names': ['wglGetCurrentDC'],
  'arguments': '', },
{ 'return_type': 'const char*',
  'names': ['wglGetExtensionsStringARB'],
  'arguments': 'HDC hDC', },
{ 'return_type': 'const char*',
  'names': ['wglGetExtensionsStringEXT'],
  'arguments': '', },
{ 'return_type': 'HDC',
  'names': ['wglGetPbufferDCARB'],
  'arguments': 'HPBUFFERARB hPbuffer', },
{ 'return_type': 'BOOL',
  'names': ['wglMakeCurrent'],
  'arguments': 'HDC hdc, HGLRC hglrc', },
{ 'return_type': 'BOOL',
  'names': ['wglQueryPbufferARB'],
  'arguments': 'HPBUFFERARB hPbuffer, int iAttribute, int* piValue', },
{ 'return_type': 'int',
  'names': ['wglReleasePbufferDCARB'],
  'arguments': 'HPBUFFERARB hPbuffer, HDC hDC', },
{ 'return_type': 'BOOL',
  'names': ['wglShareLists'],
  'arguments': 'HGLRC hglrc1, HGLRC hglrc2', },
{ 'return_type': 'BOOL',
  'names': ['wglSwapIntervalEXT'],
  'arguments': 'int interval', },
{ 'return_type': 'BOOL',
  'names': ['wglSwapLayerBuffers'],
  'arguments': 'HDC hdc, UINT fuPlanes', },
]

GLX_FUNCTIONS = [
{ 'return_type': 'void',
  'names': ['glXBindTexImageEXT'],
  'arguments':
      'Display* dpy, GLXDrawable drawable, int buffer, int* attribList', },
{ 'return_type': 'GLXFBConfig*',
  'names': ['glXChooseFBConfig'],
  'arguments':
      'Display* dpy, int screen, const int* attribList, int* nitems', },
{ 'return_type': 'XVisualInfo*',
  'names': ['glXChooseVisual'],
  'arguments': 'Display* dpy, int screen, int* attribList', },
{ 'return_type': 'void',
  'names': ['glXCopyContext'],
  'arguments':
      'Display* dpy, GLXContext src, GLXContext dst, unsigned long mask', },
{ 'return_type': 'void',
  'names': ['glXCopySubBufferMESA'],
  'arguments': 'Display* dpy, GLXDrawable drawable, '
               'int x, int y, int width, int height', },
{ 'return_type': 'GLXContext',
  'names': ['glXCreateContext'],
  'arguments':
      'Display* dpy, XVisualInfo* vis, GLXContext shareList, int direct', },
{ 'return_type': 'GLXContext',
  'names': ['glXCreateContextAttribsARB'],
  'arguments':
      'Display* dpy, GLXFBConfig config, GLXContext share_context, int direct, '
      'const int* attrib_list', },
{ 'return_type': 'GLXPixmap',
  'names': ['glXCreateGLXPixmap'],
  'arguments': 'Display* dpy, XVisualInfo* visual, Pixmap pixmap', },
{ 'return_type': 'GLXContext',
  'names': ['glXCreateNewContext'],
  'arguments': 'Display* dpy, GLXFBConfig config, int renderType, '
               'GLXContext shareList, int direct', },
{ 'return_type': 'GLXPbuffer',
  'names': ['glXCreatePbuffer'],
  'arguments': 'Display* dpy, GLXFBConfig config, const int* attribList', },
{ 'return_type': 'GLXPixmap',
  'names': ['glXCreatePixmap'],
  'arguments': 'Display* dpy, GLXFBConfig config, '
               'Pixmap pixmap, const int* attribList', },
{ 'return_type': 'GLXWindow',
  'names': ['glXCreateWindow'],
  'arguments':
      'Display* dpy, GLXFBConfig config, Window win, const int* attribList', },
{ 'return_type': 'void',
  'names': ['glXDestroyContext'],
  'arguments': 'Display* dpy, GLXContext ctx', },
{ 'return_type': 'void',
  'names': ['glXDestroyGLXPixmap'],
  'arguments': 'Display* dpy, GLXPixmap pixmap', },
{ 'return_type': 'void',
  'names': ['glXDestroyPbuffer'],
  'arguments': 'Display* dpy, GLXPbuffer pbuf', },
{ 'return_type': 'void',
  'names': ['glXDestroyPixmap'],
  'arguments': 'Display* dpy, GLXPixmap pixmap', },
{ 'return_type': 'void',
  'names': ['glXDestroyWindow'],
  'arguments': 'Display* dpy, GLXWindow window', },
{ 'return_type': 'const char*',
  'names': ['glXGetClientString'],
  'arguments': 'Display* dpy, int name', },
{ 'return_type': 'int',
  'names': ['glXGetConfig'],
  'arguments': 'Display* dpy, XVisualInfo* visual, int attrib, int* value', },
{ 'return_type': 'GLXContext',
  'names': ['glXGetCurrentContext'],
  'arguments': 'void', },
{ 'return_type': 'Display*',
  'names': ['glXGetCurrentDisplay'],
  'arguments': 'void', },
{ 'return_type': 'GLXDrawable',
  'names': ['glXGetCurrentDrawable'],
  'arguments': 'void', },
{ 'return_type': 'GLXDrawable',
  'names': ['glXGetCurrentReadDrawable'],
  'arguments': 'void', },
{ 'return_type': 'int',
  'names': ['glXGetFBConfigAttrib'],
  'arguments': 'Display* dpy, GLXFBConfig config, int attribute, int* value', },
{ 'return_type': 'GLXFBConfig',
  'names': ['glXGetFBConfigFromVisualSGIX'],
  'arguments': 'Display* dpy, XVisualInfo* visualInfo', },
{ 'return_type': 'GLXFBConfig*',
  'names': ['glXGetFBConfigs'],
  'arguments': 'Display* dpy, int screen, int* nelements', },
{ 'return_type': 'bool',
  'names': ['glXGetMscRateOML'],
  'arguments':
      'Display* dpy, GLXDrawable drawable, int32* numerator, '
      'int32* denominator' },
{ 'return_type': 'void',
  'names': ['glXGetSelectedEvent'],
  'arguments': 'Display* dpy, GLXDrawable drawable, unsigned long* mask', },
{ 'return_type': 'bool',
  'names': ['glXGetSyncValuesOML'],
  'arguments':
      'Display* dpy, GLXDrawable drawable, int64* ust, int64* msc, '
      'int64* sbc' },
{ 'return_type': 'XVisualInfo*',
  'names': ['glXGetVisualFromFBConfig'],
  'arguments': 'Display* dpy, GLXFBConfig config', },
{ 'return_type': 'int',
  'names': ['glXIsDirect'],
  'arguments': 'Display* dpy, GLXContext ctx', },
{ 'return_type': 'int',
  'names': ['glXMakeContextCurrent'],
  'arguments':
      'Display* dpy, GLXDrawable draw, GLXDrawable read, GLXContext ctx', },
{ 'return_type': 'int',
  'names': ['glXMakeCurrent'],
  'arguments': 'Display* dpy, GLXDrawable drawable, GLXContext ctx', },
{ 'return_type': 'int',
  'names': ['glXQueryContext'],
  'arguments': 'Display* dpy, GLXContext ctx, int attribute, int* value', },
{ 'return_type': 'void',
  'names': ['glXQueryDrawable'],
  'arguments':
      'Display* dpy, GLXDrawable draw, int attribute, unsigned int* value', },
{ 'return_type': 'int',
  'names': ['glXQueryExtension'],
  'arguments': 'Display* dpy, int* errorb, int* event', },
{ 'return_type': 'const char*',
  'names': ['glXQueryExtensionsString'],
  'arguments': 'Display* dpy, int screen', },
{ 'return_type': 'const char*',
  'names': ['glXQueryServerString'],
  'arguments': 'Display* dpy, int screen, int name', },
{ 'return_type': 'int',
  'names': ['glXQueryVersion'],
  'arguments': 'Display* dpy, int* maj, int* min', },
{ 'return_type': 'void',
  'names': ['glXReleaseTexImageEXT'],
  'arguments': 'Display* dpy, GLXDrawable drawable, int buffer', },
{ 'return_type': 'void',
  'names': ['glXSelectEvent'],
  'arguments': 'Display* dpy, GLXDrawable drawable, unsigned long mask', },
{ 'return_type': 'void',
  'names': ['glXSwapBuffers'],
  'arguments': 'Display* dpy, GLXDrawable drawable', },
{ 'return_type': 'void',
  'names': ['glXSwapIntervalEXT'],
  'arguments': 'Display* dpy, GLXDrawable drawable, int interval', },
{ 'return_type': 'void',
  'names': ['glXSwapIntervalMESA'],
  'arguments': 'unsigned int interval', },
{ 'return_type': 'void',
  'names': ['glXUseXFont'],
  'arguments': 'Font font, int first, int count, int list', },
{ 'return_type': 'void',
  'names': ['glXWaitGL'],
  'arguments': 'void', },
{ 'return_type': 'int',
  'names': ['glXWaitVideoSyncSGI'],
  'arguments': 'int divisor, int remainder, unsigned int* count', },
{ 'return_type': 'void',
  'names': ['glXWaitX'],
  'arguments': 'void', },
]

FUNCTION_SETS = [
  [GL_FUNCTIONS, 'gl', [
      'GL/gl.h',
      'noninclude/GL/glext.h',
      'GLES2/gl2ext.h',
      'GLES3/gl3.h',
      'GLES3/gl31.h',
      # Files below are Chromium-specific and shipped with Chromium sources.
      'GL/glextchromium.h',
      'GLES2/gl2chromium.h',
      'GLES2/gl2extchromium.h'
  ], []],
  [OSMESA_FUNCTIONS, 'osmesa', [], []],
  [EGL_FUNCTIONS, 'egl', [
      'EGL/eglext.h',
      # Files below are Chromium-specific and shipped with Chromium sources.
      'EGL/eglextchromium.h',
    ],
    [
      'EGL_ANGLE_d3d_share_handle_client_buffer',
      'EGL_ANGLE_surface_d3d_texture_2d_share_handle',
    ],
  ],
  [WGL_FUNCTIONS, 'wgl', ['noninclude/GL/wglext.h'], []],
  [GLX_FUNCTIONS, 'glx', ['GL/glx.h', 'noninclude/GL/glxext.h'], []],
]

GLES2_HEADERS_WITH_ENUMS = [
  'GLES2/gl2.h',
  'GLES2/gl2ext.h',
  'GLES2/gl2chromium.h',
  'GLES2/gl2extchromium.h',
  'GLES3/gl3.h',
]

SELF_LOCATION = os.path.dirname(os.path.abspath(__file__))

LICENSE_AND_HEADER = """\
// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is auto-generated from
// ui/gl/generate_bindings.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

"""

GLVersion = namedtuple('GLVersion', 'is_es major_version minor_version')

def GLVersionBindAlways(version):
  return version.major_version <= 2


def GetStaticBinding(func):
  """If this function has a name assigned to it that should  be bound always,
  then return this name.

  This will be the case if either a function name is specified
  that depends on an extension from UNCONDITIONALLY_BOUND_EXTENSIONS,
  or if the GL version it depends on is assumed to be available (e.g. <=2.1).
  There can only be one name that satisfies this condition (or the bindings
  would be ambiguous)."""

  static_bindings = set([])

  for version in func['versions']:
    if 'extensions' in version:
      extensions = version['extensions']
      num_unconditional_extensions = len(
          extensions & UNCONDITIONALLY_BOUND_EXTENSIONS)
      if num_unconditional_extensions:
        static_bindings.add(version['name'])
    elif 'gl_versions' in version:
      versions = [v for v in version['gl_versions'] if GLVersionBindAlways(v)]
      # It's only unconditional if it exists in GL and GLES
      if len(versions) == 2:
        assert versions[0].is_es != versions[1].is_es
        static_bindings.add(version['name'])
    else:
        static_bindings.add(version['name'])

  # Avoid ambiguous bindings (static binding with different names)
  assert len(static_bindings) <= 1
  if len(static_bindings):
    static_name = static_bindings.pop()
    # Avoid ambiguous bindings (static and dynamic bindings with
    # different names)
    assert len([v['name'] for v in func['versions']
               if v['name'] != static_name]) == 0, func
    return static_name
  else:
    return None


def GenerateHeader(file, functions, set_name, used_extensions):
  """Generates gl_bindings_autogen_x.h"""

  # Write file header.
  file.write(LICENSE_AND_HEADER +
"""

#ifndef UI_GFX_GL_GL_BINDINGS_AUTOGEN_%(name)s_H_
#define UI_GFX_GL_GL_BINDINGS_AUTOGEN_%(name)s_H_

namespace gfx {

class GLContext;

""" % {'name': set_name.upper()})

  # Write typedefs for function pointer types. Always use the GL name for the
  # typedef.
  file.write('\n')
  for func in functions:
    file.write('typedef %s (GL_BINDING_CALL *%sProc)(%s);\n' %
        (func['return_type'], func['known_as'], func['arguments']))

  # Write declarations for booleans indicating which extensions are available.
  file.write('\n')
  file.write("struct Extensions%s {\n" % set_name.upper())
  for extension in sorted(used_extensions):
    file.write('  bool b_%s;\n' % extension)
  file.write('};\n')
  file.write('\n')

  # Write Procs struct.
  file.write("struct Procs%s {\n" % set_name.upper())
  for func in functions:
    file.write('  %sProc %sFn;\n' % (func['known_as'], func['known_as']))
  file.write('};\n')
  file.write('\n')

  # Write Api class.
  file.write(
"""class GL_EXPORT %(name)sApi {
 public:
  %(name)sApi();
  virtual ~%(name)sApi();

""" % {'name': set_name.upper()})
  for func in functions:
    file.write('  virtual %s %sFn(%s) = 0;\n' %
      (func['return_type'], func['known_as'], func['arguments']))
  file.write('};\n')
  file.write('\n')

  file.write( '}  // namespace gfx\n')

  # Write macros to invoke function pointers. Always use the GL name for the
  # macro.
  file.write('\n')
  for func in functions:
    file.write('#define %s ::gfx::g_current_%s_context->%sFn\n' %
        (func['known_as'], set_name.lower(), func['known_as']))

  file.write('\n')
  file.write('#endif  //  UI_GFX_GL_GL_BINDINGS_AUTOGEN_%s_H_\n' %
      set_name.upper())


def GenerateAPIHeader(file, functions, set_name):
  """Generates gl_bindings_api_autogen_x.h"""

  # Write file header.
  file.write(LICENSE_AND_HEADER)

  # Write API declaration.
  for func in functions:
    file.write('  %s %sFn(%s) override;\n' %
      (func['return_type'], func['known_as'], func['arguments']))

  file.write('\n')


def GenerateMockHeader(file, functions, set_name):
  """Generates gl_mock_autogen_x.h"""

  # Write file header.
  file.write(LICENSE_AND_HEADER)

  # Write API declaration.
  for func in functions:
    args = func['arguments']
    if args == 'void':
      args = ''
    arg_count = 0
    if len(args):
      arg_count = func['arguments'].count(',') + 1
    file.write('  MOCK_METHOD%d(%s, %s(%s));\n' %
      (arg_count, func['known_as'][2:], func['return_type'], args))

  file.write('\n')


def GenerateSource(file, functions, set_name, used_extensions):
  """Generates gl_bindings_autogen_x.cc"""

  set_header_name = "ui/gl/gl_" + set_name.lower() + "_api_implementation.h"
  include_list = [ 'base/trace_event/trace_event.h',
                   'ui/gl/gl_enums.h',
                   'ui/gl/gl_bindings.h',
                   'ui/gl/gl_context.h',
                   'ui/gl/gl_implementation.h',
                   'ui/gl/gl_version_info.h',
                   set_header_name ]

  includes_string = "\n".join(["#include \"{0}\"".format(h)
                               for h in sorted(include_list)])

  # Write file header.
  file.write(LICENSE_AND_HEADER +
"""

#include <string>

%s

namespace gfx {
""" % includes_string)

  file.write('\n')
  file.write('static bool g_debugBindingsInitialized;\n')
  file.write('Driver%s g_driver_%s;\n' % (set_name.upper(), set_name.lower()))
  file.write('\n')

  # Write stub functions that take the place of some functions before a context
  # is initialized. This is done to provide clear asserts on debug build and to
  # avoid crashing in case of a bug on release build.
  file.write('\n')
  num_dynamic = 0
  for func in functions:
    static_binding = GetStaticBinding(func)
    if static_binding:
      func['static_binding'] = static_binding
    else:
      num_dynamic = num_dynamic + 1

  print "[%s] %d static bindings, %d dynamic bindings" % (
      set_name, len(functions) - num_dynamic, num_dynamic)

  # Write function to initialize the function pointers that are always the same
  # and to initialize bindings where choice of the function depends on the
  # extension string or the GL version to point to stub functions.
  file.write('\n')
  file.write('void Driver%s::InitializeStaticBindings() {\n' %
             set_name.upper())

  def WriteFuncBinding(file, known_as, version_name):
    file.write(
        '  fn.%sFn = reinterpret_cast<%sProc>(GetGLProcAddress("%s"));\n' %
        (known_as, known_as, version_name))

  for func in functions:
    if 'static_binding' in func:
      WriteFuncBinding(file, func['known_as'], func['static_binding'])
    else:
      file.write('  fn.%sFn = 0;\n' % func['known_as'])

  if set_name == 'gl':
    # Write the deferred bindings for GL that need a current context and depend
    # on GL_VERSION and GL_EXTENSIONS.
    file.write('}\n\n')
    file.write("""void DriverGL::InitializeDynamicBindings(GLContext* context) {
  DCHECK(context && context->IsCurrent(NULL));
  const GLVersionInfo* ver = context->GetVersionInfo();
  ALLOW_UNUSED_LOCAL(ver);
  std::string extensions = context->GetExtensions() + " ";
  ALLOW_UNUSED_LOCAL(extensions);

""")
  else:
    file.write("""std::string extensions(GetPlatformExtensions());
  extensions += " ";
  ALLOW_UNUSED_LOCAL(extensions);

""")

  for extension in sorted(used_extensions):
    # Extra space at the end of the extension name is intentional, it is used
    # as a separator
    file.write('  ext.b_%s = extensions.find("%s ") != std::string::npos;\n' %
        (extension, extension))

  def GetGLVersionCondition(gl_version):
    if GLVersionBindAlways(gl_version):
      if gl_version.is_es:
        return 'ver->is_es'
      else:
        return '!ver->is_es'
    elif gl_version.is_es:
      return 'ver->IsAtLeastGLES(%du, %du)' % (
          gl_version.major_version, gl_version.minor_version)
    else:
      return 'ver->IsAtLeastGL(%du, %du)' % (
          gl_version.major_version, gl_version.minor_version)

  def GetBindingCondition(version):
    conditions = []
    if 'gl_versions' in version:
      conditions.extend(
          [GetGLVersionCondition(v) for v in version['gl_versions']])
    if 'extensions' in version and version['extensions']:
      conditions.extend(
          ['ext.b_%s' % e for e in version['extensions']])
    return ' || '.join(conditions)

  def WriteConditionalFuncBinding(file, func):
    assert len(func['versions']) > 0
    known_as = func['known_as']
    i = 0
    first_version = True
    while i < len(func['versions']):
      version = func['versions'][i]
      cond = GetBindingCondition(version)
      if first_version:
        file.write('  if (%s) {\n  ' % cond)
      else:
        file.write('  else if (%s) {\n  ' % (cond))

      WriteFuncBinding(file, known_as, version['name'])
      file.write('DCHECK(fn.%sFn);\n' % known_as)
      file.write('}\n')
      i += 1
      first_version = False

  for func in functions:
    if not 'static_binding' in func:
      file.write('\n')
      file.write('  debug_fn.%sFn = 0;\n' % func['known_as'])
      WriteConditionalFuncBinding(file, func)

  # Some new function pointers have been added, so update them in debug bindings
  file.write('\n')
  file.write('  if (g_debugBindingsInitialized)\n')
  file.write('    InitializeDebugBindings();\n')
  file.write('}\n')
  file.write('\n')

  # Write logging wrappers for each function.
  file.write('extern "C" {\n')
  for func in functions:
    return_type = func['return_type']
    arguments = func['arguments']
    file.write('\n')
    file.write('static %s GL_BINDING_CALL Debug_%s(%s) {\n' %
        (return_type, func['known_as'], arguments))
    argument_names = re.sub(
        r'(const )?[a-zA-Z0-9_]+\** ([a-zA-Z0-9_]+)', r'\2', arguments)
    argument_names = re.sub(
        r'(const )?[a-zA-Z0-9_]+\** ([a-zA-Z0-9_]+)', r'\2', argument_names)
    log_argument_names = re.sub(
        r'const char\* ([a-zA-Z0-9_]+)', r'CONSTCHAR_\1', arguments)
    log_argument_names = re.sub(
        r'(const )?[a-zA-Z0-9_]+\* ([a-zA-Z0-9_]+)',
        r'CONSTVOID_\2', log_argument_names)
    log_argument_names = re.sub(
        r'(?<!E)GLenum ([a-zA-Z0-9_]+)', r'GLenum_\1', log_argument_names)
    log_argument_names = re.sub(
        r'(?<!E)GLboolean ([a-zA-Z0-9_]+)', r'GLboolean_\1', log_argument_names)
    log_argument_names = re.sub(
        r'(const )?[a-zA-Z0-9_]+\** ([a-zA-Z0-9_]+)', r'\2',
        log_argument_names)
    log_argument_names = re.sub(
        r'(const )?[a-zA-Z0-9_]+\** ([a-zA-Z0-9_]+)', r'\2',
        log_argument_names)
    log_argument_names = re.sub(
        r'CONSTVOID_([a-zA-Z0-9_]+)',
        r'static_cast<const void*>(\1)', log_argument_names)
    log_argument_names = re.sub(
        r'CONSTCHAR_([a-zA-Z0-9_]+)', r'\1', log_argument_names)
    log_argument_names = re.sub(
        r'GLenum_([a-zA-Z0-9_]+)', r'GLEnums::GetStringEnum(\1)',
        log_argument_names)
    log_argument_names = re.sub(
        r'GLboolean_([a-zA-Z0-9_]+)', r'GLEnums::GetStringBool(\1)',
        log_argument_names)
    log_argument_names = log_argument_names.replace(',', ' << ", " <<')
    if argument_names == 'void' or argument_names == '':
      argument_names = ''
      log_argument_names = ''
    else:
      log_argument_names = " << " + log_argument_names
    function_name = func['known_as']
    if return_type == 'void':
      file.write('  GL_SERVICE_LOG("%s" << "(" %s << ")");\n' %
          (function_name, log_argument_names))
      file.write('  g_driver_%s.debug_fn.%sFn(%s);\n' %
          (set_name.lower(), function_name, argument_names))
      if 'logging_code' in func:
        file.write("%s\n" % func['logging_code'])
    else:
      file.write('  GL_SERVICE_LOG("%s" << "(" %s << ")");\n' %
          (function_name, log_argument_names))
      file.write('  %s result = g_driver_%s.debug_fn.%sFn(%s);\n' %
          (return_type, set_name.lower(), function_name, argument_names))
      if 'logging_code' in func:
        file.write("%s\n" % func['logging_code'])
      else:
        file.write('  GL_SERVICE_LOG("GL_RESULT: " << result);\n')
      file.write('  return result;\n')
    file.write('}\n')
  file.write('}  // extern "C"\n')

  # Write function to initialize the debug function pointers.
  file.write('\n')
  file.write('void Driver%s::InitializeDebugBindings() {\n' %
             set_name.upper())
  for func in functions:
    first_name = func['known_as']
    file.write('  if (!debug_fn.%sFn) {\n' % first_name)
    file.write('    debug_fn.%sFn = fn.%sFn;\n' % (first_name, first_name))
    file.write('    fn.%sFn = Debug_%s;\n' % (first_name, first_name))
    file.write('  }\n')
  file.write('  g_debugBindingsInitialized = true;\n')
  file.write('}\n')

  # Write function to clear all function pointers.
  file.write('\n')
  file.write("""void Driver%s::ClearBindings() {
  memset(this, 0, sizeof(*this));
}
""" % set_name.upper())

  def MakeArgNames(arguments):
    argument_names = re.sub(
        r'(const )?[a-zA-Z0-9_]+\** ([a-zA-Z0-9_]+)', r'\2', arguments)
    argument_names = re.sub(
        r'(const )?[a-zA-Z0-9_]+\** ([a-zA-Z0-9_]+)', r'\2', argument_names)
    if argument_names == 'void' or argument_names == '':
      argument_names = ''
    return argument_names

  # Write GLApiBase functions
  for func in functions:
    function_name = func['known_as']
    return_type = func['return_type']
    arguments = func['arguments']
    file.write('\n')
    file.write('%s %sApiBase::%sFn(%s) {\n' %
        (return_type, set_name.upper(), function_name, arguments))
    argument_names = MakeArgNames(arguments)
    if return_type == 'void':
      file.write('  driver_->fn.%sFn(%s);\n' %
          (function_name, argument_names))
    else:
      file.write('  return driver_->fn.%sFn(%s);\n' %
          (function_name, argument_names))
    file.write('}\n')

  # Write TraceGLApi functions
  for func in functions:
    function_name = func['known_as']
    return_type = func['return_type']
    arguments = func['arguments']
    file.write('\n')
    file.write('%s Trace%sApi::%sFn(%s) {\n' %
        (return_type, set_name.upper(), function_name, arguments))
    argument_names = MakeArgNames(arguments)
    file.write('  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::%s")\n' %
               function_name)
    if return_type == 'void':
      file.write('  %s_api_->%sFn(%s);\n' %
          (set_name.lower(), function_name, argument_names))
    else:
      file.write('  return %s_api_->%sFn(%s);\n' %
          (set_name.lower(), function_name, argument_names))
    file.write('}\n')

  # Write NoContextGLApi functions
  if set_name.upper() == "GL":
    for func in functions:
      function_name = func['known_as']
      return_type = func['return_type']
      arguments = func['arguments']
      file.write('\n')
      file.write('%s NoContextGLApi::%sFn(%s) {\n' %
          (return_type, function_name, arguments))
      argument_names = MakeArgNames(arguments)
      no_context_error = "Trying to call %s() without current GL context" % function_name
      file.write('  NOTREACHED() <<  "%s";\n' % no_context_error)
      file.write('  LOG(ERROR) <<  "%s";\n' % no_context_error)
      default_value = { 'GLenum': 'static_cast<GLenum>(0)',
                        'GLuint': '0U',
                        'GLint': '0',
                        'GLboolean': 'GL_FALSE',
                        'GLbyte': '0',
                        'GLubyte': '0',
                        'GLbutfield': '0',
                        'GLushort': '0',
                        'GLsizei': '0',
                        'GLfloat': '0.0f',
                        'GLdouble': '0.0',
                        'GLsync': 'NULL'}
      if return_type.endswith('*'):
        file.write('  return NULL;\n')
      elif return_type != 'void':
        file.write('  return %s;\n' % default_value[return_type])
      file.write('}\n')

  file.write('\n')
  file.write('}  // namespace gfx\n')


def GetUniquelyNamedFunctions(functions):
  uniquely_named_functions = {}

  for func in functions:
    for version in func['versions']:
      uniquely_named_functions[version['name']] = ({
        'name': version['name'],
        'return_type': func['return_type'],
        'arguments': func['arguments'],
        'known_as': func['known_as']
      })
  return uniquely_named_functions


def GenerateMockBindingsHeader(file, functions):
  """Headers for functions that invoke MockGLInterface members"""

  file.write(LICENSE_AND_HEADER)
  uniquely_named_functions = GetUniquelyNamedFunctions(functions)

  for key in sorted(uniquely_named_functions.iterkeys()):
    func = uniquely_named_functions[key]
    file.write('static %s GL_BINDING_CALL Mock_%s(%s);\n' %
        (func['return_type'], func['name'], func['arguments']))


def GenerateMockBindingsSource(file, functions):
  """Generates functions that invoke MockGLInterface members and a
  GetGLProcAddress function that returns addresses to those functions."""

  file.write(LICENSE_AND_HEADER +
"""

#include <string.h>

#include "ui/gl/gl_mock.h"

namespace gfx {

// This is called mainly to prevent the compiler combining the code of mock
// functions with identical contents, so that their function pointers will be
// different.
void MakeFunctionUnique(const char *func_name) {
    VLOG(2) << "Calling mock " << func_name;
}

""")
  # Write functions that trampoline into the set MockGLInterface instance.
  uniquely_named_functions = GetUniquelyNamedFunctions(functions)
  sorted_function_names = sorted(uniquely_named_functions.iterkeys())

  for key in sorted_function_names:
    func = uniquely_named_functions[key]
    file.write('\n')
    file.write('%s GL_BINDING_CALL MockGLInterface::Mock_%s(%s) {\n' %
        (func['return_type'], func['name'], func['arguments']))
    file.write('  MakeFunctionUnique("%s");\n' % func['name'])
    arg_re = r'(const )?[a-zA-Z0-9]+((\s*const\s*)?\*)* ([a-zA-Z0-9]+)'
    argument_names = re.sub(arg_re, r'\4', func['arguments'])
    if argument_names == 'void':
      argument_names = ''
    function_name = func['known_as'][2:]
    if func['return_type'] == 'void':
      file.write('  interface_->%s(%s);\n' %
          (function_name, argument_names))
    else:
      file.write('  return interface_->%s(%s);\n' %
          (function_name, argument_names))
    file.write('}\n')

  # Write an 'invalid' function to catch code calling through uninitialized
  # function pointers or trying to interpret the return value of
  # GLProcAddress().
  file.write('\n')
  file.write('static void MockInvalidFunction() {\n')
  file.write('  NOTREACHED();\n')
  file.write('}\n')

  # Write a function to lookup a mock GL function based on its name.
  file.write('\n')
  file.write('void* GL_BINDING_CALL ' +
      'MockGLInterface::GetGLProcAddress(const char* name) {\n')
  for key in sorted_function_names:
    name = uniquely_named_functions[key]['name']
    file.write('  if (strcmp(name, "%s") == 0)\n' % name)
    file.write('    return reinterpret_cast<void*>(Mock_%s);\n' % name)
  # Always return a non-NULL pointer like some EGL implementations do.
  file.write('  return reinterpret_cast<void*>(&MockInvalidFunction);\n')
  file.write('}\n')

  file.write('\n')
  file.write('}  // namespace gfx\n')

def GenerateEnumUtils(out_file, input_filenames):
  enum_re = re.compile(r'\#define\s+(GL_[a-zA-Z0-9_]+)\s+([0-9A-Fa-fx]+)')
  dict = {}
  for fname in input_filenames:
    lines = open(fname).readlines()
    for line in lines:
      m = enum_re.match(line)
      if m:
        name = m.group(1)
        value = m.group(2)
        if len(value) <= 10:
          if not value in dict:
            dict[value] = name
          # check our own _CHROMIUM macro conflicts with khronos GL headers.
          elif dict[value] != name and (name.endswith('_CHROMIUM') or
              dict[value].endswith('_CHROMIUM')):
            raise RunTimeError("code collision: %s and %s have the same code %s"
                               %  (dict[value], name, value))

  out_file.write(LICENSE_AND_HEADER)
  out_file.write("static const GLEnums::EnumToString "
                 "enum_to_string_table[] = {\n")
  for value in dict:
    out_file.write('  { %s, "%s", },\n' % (value, dict[value]))
  out_file.write("""};

const GLEnums::EnumToString* const GLEnums::enum_to_string_table_ =
  enum_to_string_table;
const size_t GLEnums::enum_to_string_table_len_ =
  sizeof(enum_to_string_table) / sizeof(enum_to_string_table[0]);

""")


def ParseFunctionsFromHeader(header_file, extensions, versions):
  """Parse a C extension header file and return a map from extension names to
  a list of functions.

  Args:
    header_file: Line-iterable C header file.
  Returns:
    Map of extension name => functions, Map of gl version => functions.
    Functions will only be in either one of the two maps.
  """
  version_start = re.compile(
      r'#ifndef GL_(ES_|)VERSION((?:_[0-9])+)$')
  extension_start = re.compile(
      r'#ifndef ((?:GL|EGL|WGL|GLX)_[A-Z]+_[a-zA-Z]\w+)')
  extension_function = re.compile(r'.+\s+([a-z]+\w+)\s*\(')
  typedef = re.compile(r'typedef .*')
  macro_start = re.compile(r'^#(if|ifdef|ifndef).*')
  macro_end = re.compile(r'^#endif.*')
  macro_depth = 0
  current_version = None
  current_version_depth = 0
  current_extension = None
  current_extension_depth = 0

  # Pick up all core functions here, since some of them are missing in the
  # Khronos headers.
  hdr = os.path.basename(header_file.name)
  if hdr == "gl.h":
    current_version = GLVersion(False, 1, 0)

  line_num = 1
  for line in header_file:
    version_match = version_start.match(line)
    if macro_start.match(line):
      macro_depth += 1
      if version_match:
        if current_version:
          raise RuntimeError('Nested GL version macro in %s at line %d' % (
              header_file.name, line_num))
        current_version_depth = macro_depth
        es = version_match.group(1)
        major_version, minor_version =\
            version_match.group(2).lstrip('_').split('_')
        is_es = len(es) > 0
        if (not is_es) and (major_version == '1'):
          minor_version = 0
        current_version = GLVersion(
            is_es, int(major_version), int(minor_version))
    elif macro_end.match(line):
      macro_depth -= 1
      if macro_depth < current_extension_depth:
        current_extension = None
      if macro_depth < current_version_depth:
        current_version = None

    match = extension_start.match(line)
    if match and not version_match:
      if current_version and hdr != "gl.h":
        raise RuntimeError('Nested GL version macro in %s at line %d' % (
            header_file.name, line_num))
      current_extension = match.group(1)
      current_extension_depth = macro_depth

    match = extension_function.match(line)
    if match and not typedef.match(line):
      if current_extension:
        extensions[current_extension].add(match.group(1))
      elif current_version:
        versions[current_version].add(match.group(1))
    line_num = line_num + 1


def GetDynamicFunctions(extension_headers):
  """Parse all optional functions from a list of header files.

  Args:
    extension_headers: List of header file names.
  Returns:
    Map of extension name => list of functions,
    Map of gl version => list of functions.
  """
  extensions = collections.defaultdict(lambda: set([]))
  gl_versions = collections.defaultdict(lambda: set([]))
  for header in extension_headers:
    ParseFunctionsFromHeader(open(header), extensions, gl_versions)
  return extensions, gl_versions


def GetFunctionToExtensionsMap(extensions):
  """Construct map from a function names to extensions which define the
  function.

  Args:
    extensions: Map of extension name => functions.
  Returns:
    Map of function name => extension names.
  """
  function_to_extensions = {}
  for extension, functions in extensions.items():
    for function in functions:
      if not function in function_to_extensions:
        function_to_extensions[function] = set([])
      function_to_extensions[function].add(extension)
  return function_to_extensions

def GetFunctionToGLVersionsMap(gl_versions):
  """Construct map from a function names to GL versions which define the
  function.

  Args:
    extensions: Map of gl versions => functions.
  Returns:
    Map of function name => gl versions.
  """
  function_to_gl_versions = {}
  for gl_version, functions in gl_versions.items():
    for function in functions:
      if not function in function_to_gl_versions:
        function_to_gl_versions[function] = set([])
      function_to_gl_versions[function].add(gl_version)
  return function_to_gl_versions


def LooksLikeExtensionFunction(function):
  """Heuristic to see if a function name is consistent with extension function
  naming."""
  vendor = re.match(r'\w+?([A-Z][A-Z]+)$', function)
  return vendor is not None and not vendor.group(1) in ['GL', 'API', 'DC']


def SortVersions(key):
   # Prefer functions from the core for binding
  if 'gl_versions' in key:
    return 0
  else:
    return 1

def FillExtensionsFromHeaders(functions, extension_headers, extra_extensions):
  """Determine which functions belong to extensions based on extension headers,
  and fill in this information to the functions table for functions that don't
  already have the information.

  Args:
    functions: List of (return type, function versions, arguments).
    extension_headers: List of header file names.
    extra_extensions: Extensions to add to the list.
  Returns:
    Set of used extensions.
  """
  # Parse known extensions.
  extensions, gl_versions = GetDynamicFunctions(extension_headers)
  functions_to_extensions = GetFunctionToExtensionsMap(extensions)
  functions_to_gl_versions = GetFunctionToGLVersionsMap(gl_versions)

  # Fill in the extension information.
  used_extensions = set()
  used_functions_by_version = collections.defaultdict(lambda: set([]))
  for func in functions:
    for version in func['versions']:
      name = version['name']

      # There should only be one version entry per name string.
      if len([v for v in func['versions'] if v['name'] == name]) > 1:
        raise RuntimeError(
            'Duplicate version entries with same name for %s' % name)

      # Make sure we know about all extensions and extension functions.
      extensions_from_headers = set([])
      if name in functions_to_extensions:
        extensions_from_headers = set(functions_to_extensions[name])

      explicit_extensions = set([])
      if 'extensions' in version:
        explicit_extensions = set(version['extensions'])

      in_both = explicit_extensions.intersection(extensions_from_headers)
      if len(in_both):
        print "[%s] Specified redundant extensions for binding: %s" % (
            name, ', '.join(in_both))
      diff = explicit_extensions - extensions_from_headers
      if len(diff):
        print "[%s] Specified extra extensions for binding: %s" % (
            name, ', '.join(diff))

      all_extensions = extensions_from_headers.union(explicit_extensions)
      if len(all_extensions):
        version['extensions'] = all_extensions

      if 'extensions' in version:
        assert len(version['extensions'])
        used_extensions.update(version['extensions'])

      if not 'extensions' in version and LooksLikeExtensionFunction(name):
        raise RuntimeError('%s looks like an extension function but does not '
            'belong to any of the known extensions.' % name)

      if name in functions_to_gl_versions:
        assert not 'gl_versions' in version
        version['gl_versions'] = functions_to_gl_versions[name]
        for v in version['gl_versions']:
          used_functions_by_version[v].add(name)

    func['versions'] = sorted(func['versions'], key=SortVersions)

  # Add extensions that do not have any functions.
  used_extensions.update(extra_extensions)

  # Print out used function count by GL(ES) version.
  for v in sorted([v for v in used_functions_by_version if v.is_es]):
    print "OpenGL ES %d.%d: %d used functions" % (
        v.major_version, v.minor_version, len(used_functions_by_version[v]))
  for v in sorted([v for v in used_functions_by_version if not v.is_es]):
    print "OpenGL %d.%d: %d used functions" % (
        v.major_version, v.minor_version, len(used_functions_by_version[v]))

  return used_extensions


def ResolveHeader(header, header_paths):
  for path in header_paths:
    result = os.path.join(path, header)
    if not os.path.isabs(path):
      result = os.path.abspath(os.path.join(SELF_LOCATION, result))
    if os.path.exists(result):
      # Always use forward slashes as path separators. Otherwise backslashes
      # may be incorrectly interpreted as escape characters.
      return result.replace(os.path.sep, '/')

  raise Exception('Header %s not found.' % header)


def main(argv):
  """This is the main function."""

  parser = optparse.OptionParser()
  parser.add_option('--inputs', action='store_true')
  parser.add_option('--verify-order', action='store_true')

  options, args = parser.parse_args(argv)

  if options.inputs:
    for [_, _, headers, _] in FUNCTION_SETS:
      for header in headers:
        print ResolveHeader(header, HEADER_PATHS)
    return 0

  directory = SELF_LOCATION
  if len(args) >= 1:
    directory = args[0]

  def ClangFormat(filename):
    formatter = "clang-format"
    if platform.system() == "Windows":
      formatter += ".bat"
    call([formatter, "-i", "-style=chromium", filename])

  for [functions, set_name, extension_headers, extensions] in FUNCTION_SETS:
    # Function names can be specified in two ways (list of unique names or list
    # of versions with different binding conditions). Fill in the data to the
    # versions list in case it is missing, so that can be used from here on:
    for func in functions:
      assert 'versions' in func or 'names' in func, 'Function with no names'
      if 'versions' not in func:
        func['versions'] = [{'name': n} for n in func['names']]
      # Use the first version's name unless otherwise specified
      if 'known_as' not in func:
        func['known_as'] = func['versions'][0]['name']
      # Make sure that 'names' is not accidentally used instead of 'versions'
      if 'names' in func:
        del func['names']

    # Check function names in each set is sorted in alphabetical order.
    for index in range(len(functions) - 1):
      func_name = functions[index]['known_as']
      next_func_name = functions[index + 1]['known_as']
      if func_name.lower() > next_func_name.lower():
        raise Exception(
            'function %s is not in alphabetical order' % next_func_name)
    if options.verify_order:
      continue

    extension_headers = [ResolveHeader(h, HEADER_PATHS)
                         for h in extension_headers]
    used_extensions = FillExtensionsFromHeaders(
        functions, extension_headers, extensions)

    header_file = open(
        os.path.join(directory, 'gl_bindings_autogen_%s.h' % set_name), 'wb')
    GenerateHeader(header_file, functions, set_name, used_extensions)
    header_file.close()
    ClangFormat(header_file.name)

    header_file = open(
        os.path.join(directory, 'gl_bindings_api_autogen_%s.h' % set_name),
        'wb')
    GenerateAPIHeader(header_file, functions, set_name)
    header_file.close()
    ClangFormat(header_file.name)

    source_file = open(
        os.path.join(directory, 'gl_bindings_autogen_%s.cc' % set_name), 'wb')
    GenerateSource(source_file, functions, set_name, used_extensions)
    source_file.close()
    ClangFormat(source_file.name)

  if not options.verify_order:
    header_file = open(
        os.path.join(directory, 'gl_mock_autogen_gl.h'), 'wb')
    GenerateMockHeader(header_file, GL_FUNCTIONS, 'gl')
    header_file.close()
    ClangFormat(header_file.name)

    header_file = open(os.path.join(directory, 'gl_bindings_autogen_mock.h'),
                       'wb')
    GenerateMockBindingsHeader(header_file, GL_FUNCTIONS)
    header_file.close()
    ClangFormat(header_file.name)

    source_file = open(os.path.join(directory, 'gl_bindings_autogen_mock.cc'),
                       'wb')
    GenerateMockBindingsSource(source_file, GL_FUNCTIONS)
    source_file.close()
    ClangFormat(source_file.name)

    enum_header_filenames = [ResolveHeader(h, HEADER_PATHS)
                             for h in GLES2_HEADERS_WITH_ENUMS]
    header_file = open(os.path.join(directory,
                                    'gl_enums_implementation_autogen.h'),
                       'wb')
    GenerateEnumUtils(header_file, enum_header_filenames)
    header_file.close()
    ClangFormat(header_file.name)
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
