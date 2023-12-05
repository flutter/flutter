// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'webgl1.dart';

@JS('WebGLVertexArrayObjectOES')
@staticInterop
class WebGLVertexArrayObjectOES implements WebGLObject {}

@JS('OES_vertex_array_object')
@staticInterop
class OES_vertex_array_object {
  external static GLenum get VERTEX_ARRAY_BINDING_OES;
}

extension OESVertexArrayObjectExtension on OES_vertex_array_object {
  external WebGLVertexArrayObjectOES? createVertexArrayOES();
  external void deleteVertexArrayOES(WebGLVertexArrayObjectOES? arrayObject);
  external GLboolean isVertexArrayOES(WebGLVertexArrayObjectOES? arrayObject);
  external void bindVertexArrayOES(WebGLVertexArrayObjectOES? arrayObject);
}
