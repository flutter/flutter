// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Vertex shader for the UberSDF fragment shaders (`uber_sdf.frag` and
// `uber_sdf_ssbo.frag`).
//
// Moves the per-draw offsets (the shape's center and the gradient's origin)
// out of the fragment shader, which needs fewer uniforms as a result. Both
// outputs are affine in `position`, so interpolating them is exact.

#include <impeller/types.glsl>

uniform FrameInfo {
  mat4 mvp;
  /// The center of the shape in local coordinates.
  vec2 center;
  /// The linear gradient start point or radial gradient center in local
  /// coordinates. Unused (0) for solid colors.
  vec2 gradient_origin;
}
frame_info;

in vec2 position;

/// The local position relative to the shape's center.
out vec2 v_position;
/// The local position relative to the gradient's origin.
out vec2 v_gradient_position;

void main() {
  gl_Position = frame_info.mvp * vec4(position, 0.0, 1.0);
  v_position = position - frame_info.center;
  v_gradient_position = position - frame_info.gradient_origin;
}
