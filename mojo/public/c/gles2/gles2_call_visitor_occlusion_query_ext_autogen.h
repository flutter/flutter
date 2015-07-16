// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

VISIT_GL_CALL(GenQueriesEXT, void, (GLsizei n, GLuint* queries), (n, queries))
VISIT_GL_CALL(DeleteQueriesEXT,
              void,
              (GLsizei n, const GLuint* queries),
              (n, queries))
VISIT_GL_CALL(IsQueryEXT, GLboolean, (GLuint id), (id))
VISIT_GL_CALL(BeginQueryEXT, void, (GLenum target, GLuint id), (target, id))
VISIT_GL_CALL(EndQueryEXT, void, (GLenum target), (target))
VISIT_GL_CALL(GetQueryivEXT,
              void,
              (GLenum target, GLenum pname, GLint* params),
              (target, pname, params))
VISIT_GL_CALL(GetQueryObjectuivEXT,
              void,
              (GLuint id, GLenum pname, GLuint* params),
              (id, pname, params))
