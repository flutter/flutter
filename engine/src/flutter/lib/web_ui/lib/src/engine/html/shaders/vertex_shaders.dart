// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'shader_builder.dart';
import '../../browser_detection.dart';

/// Provides common shaders used for gradients and drawVertices APIs.
class VertexShaders {
  static String? _baseVertexShader;

  /// Creates a vertex shader transforms pixel space [Vertices.positions] to
  /// final clipSpace -1..1 coordinates with inverted Y Axis.
  ///     #version 300 es
  ///     layout (location=0) in vec4 position;
  ///     layout (location=1) in vec4 color;
  ///     uniform mat4 u_ctransform;
  ///     uniform vec4 u_scale;
  ///     uniform vec4 u_shift;
  ///     out vec4 vColor;
  ///     void main() {
  ///       gl_Position = ((u_ctransform * position) * u_scale) + u_shift;
  ///       v_color = color.zyxw;
  ///     }
  static String writeBaseVertexShader() {
    if (_baseVertexShader == null) {
      ShaderBuilder builder = ShaderBuilder(webGLVersion);
      builder.addIn(ShaderType.kVec4, name: 'position');
      builder.addIn(ShaderType.kVec4, name: 'color');
      builder.addUniform(ShaderType.kMat4, name: 'u_ctransform');
      builder.addUniform(ShaderType.kVec4, name: 'u_scale');
      builder.addUniform(ShaderType.kVec4, name: 'u_shift');
      builder.addOut(ShaderType.kVec4, name: 'v_color');
      ShaderMethod method = builder.addMethod('main');
      method.addStatement(
          'gl_Position = ((u_ctransform * position) * u_scale) + u_shift;');
      method.addStatement('v_color = color.zyxw;');
      _baseVertexShader = builder.build();
    }
    return _baseVertexShader!;
  }
}
