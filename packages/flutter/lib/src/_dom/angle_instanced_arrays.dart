// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

// ignore_for_file: public_member_api_docs

import 'dart:js_interop';

import 'webgl1.dart';

@JS('ANGLE_instanced_arrays')
@staticInterop
class ANGLE_instanced_arrays {
  external static GLenum get VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE;
}

extension ANGLEInstancedArraysExtension on ANGLE_instanced_arrays {
  external void drawArraysInstancedANGLE(
    GLenum mode,
    GLint first,
    GLsizei count,
    GLsizei primcount,
  );
  external void drawElementsInstancedANGLE(
    GLenum mode,
    GLsizei count,
    GLenum type,
    GLintptr offset,
    GLsizei primcount,
  );
  external void vertexAttribDivisorANGLE(
    GLuint index,
    GLuint divisor,
  );
}
