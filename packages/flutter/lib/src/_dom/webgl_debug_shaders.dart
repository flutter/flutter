// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'webgl1.dart';

@JS('WEBGL_debug_shaders')
@staticInterop
class WEBGL_debug_shaders {}

extension WEBGLDebugShadersExtension on WEBGL_debug_shaders {
  external String getTranslatedShaderSource(WebGLShader shader);
}
