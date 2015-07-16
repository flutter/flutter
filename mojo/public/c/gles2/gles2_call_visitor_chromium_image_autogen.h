// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

VISIT_GL_CALL(
    CreateImageCHROMIUM,
    GLuint,
    (ClientBuffer buffer, GLsizei width, GLsizei height, GLenum internalformat),
    (buffer, width, height, internalformat))
VISIT_GL_CALL(DestroyImageCHROMIUM, void, (GLuint image_id), (image_id))
VISIT_GL_CALL(
    CreateGpuMemoryBufferImageCHROMIUM,
    GLuint,
    (GLsizei width, GLsizei height, GLenum internalformat, GLenum usage),
    (width, height, internalformat, usage))
VISIT_GL_CALL(BindTexImage2DCHROMIUM,
              void,
              (GLenum target, GLint imageId),
              (target, imageId))
VISIT_GL_CALL(ReleaseTexImage2DCHROMIUM,
              void,
              (GLenum target, GLint imageId),
              (target, imageId))
