// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

VISIT_GL_CALL(GenVertexArraysOES,
              void,
              (GLsizei n, GLuint* arrays),
              (n, arrays))
VISIT_GL_CALL(DeleteVertexArraysOES,
              void,
              (GLsizei n, const GLuint* arrays),
              (n, arrays))
VISIT_GL_CALL(IsVertexArrayOES, GLboolean, (GLuint array), (array))
VISIT_GL_CALL(BindVertexArrayOES, void, (GLuint array), (array))
