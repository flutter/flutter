// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'webgl1.dart';

@JS('WEBGL_draw_instanced_base_vertex_base_instance')
@staticInterop
class WEBGL_draw_instanced_base_vertex_base_instance {}

extension WEBGLDrawInstancedBaseVertexBaseInstanceExtension
    on WEBGL_draw_instanced_base_vertex_base_instance {
  external void drawArraysInstancedBaseInstanceWEBGL(
    GLenum mode,
    GLint first,
    GLsizei count,
    GLsizei instanceCount,
    GLuint baseInstance,
  );
  external void drawElementsInstancedBaseVertexBaseInstanceWEBGL(
    GLenum mode,
    GLsizei count,
    GLenum type,
    GLintptr offset,
    GLsizei instanceCount,
    GLint baseVertex,
    GLuint baseInstance,
  );
}
