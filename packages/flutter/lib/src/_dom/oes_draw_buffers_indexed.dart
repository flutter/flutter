// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'webgl1.dart';

@JS('OES_draw_buffers_indexed')
@staticInterop
class OES_draw_buffers_indexed {}

extension OESDrawBuffersIndexedExtension on OES_draw_buffers_indexed {
  external void enableiOES(
    GLenum target,
    GLuint index,
  );
  external void disableiOES(
    GLenum target,
    GLuint index,
  );
  external void blendEquationiOES(
    GLuint buf,
    GLenum mode,
  );
  external void blendEquationSeparateiOES(
    GLuint buf,
    GLenum modeRGB,
    GLenum modeAlpha,
  );
  external void blendFunciOES(
    GLuint buf,
    GLenum src,
    GLenum dst,
  );
  external void blendFuncSeparateiOES(
    GLuint buf,
    GLenum srcRGB,
    GLenum dstRGB,
    GLenum srcAlpha,
    GLenum dstAlpha,
  );
  external void colorMaskiOES(
    GLuint buf,
    GLboolean r,
    GLboolean g,
    GLboolean b,
    GLboolean a,
  );
}
