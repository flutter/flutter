// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'webgl1.dart';

@JS('WEBGL_multi_draw_instanced_base_vertex_base_instance')
@staticInterop
class WEBGL_multi_draw_instanced_base_vertex_base_instance {}

extension WEBGLMultiDrawInstancedBaseVertexBaseInstanceExtension
    on WEBGL_multi_draw_instanced_base_vertex_base_instance {
  external void multiDrawArraysInstancedBaseInstanceWEBGL(
    GLenum mode,
    JSObject firstsList,
    int firstsOffset,
    JSObject countsList,
    int countsOffset,
    JSObject instanceCountsList,
    int instanceCountsOffset,
    JSObject baseInstancesList,
    int baseInstancesOffset,
    GLsizei drawcount,
  );
  external void multiDrawElementsInstancedBaseVertexBaseInstanceWEBGL(
    GLenum mode,
    JSObject countsList,
    int countsOffset,
    GLenum type,
    JSObject offsetsList,
    int offsetsOffset,
    JSObject instanceCountsList,
    int instanceCountsOffset,
    JSObject baseVerticesList,
    int baseVerticesOffset,
    JSObject baseInstancesList,
    int baseInstancesOffset,
    GLsizei drawcount,
  );
}
