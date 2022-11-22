// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/transform.glsl>
#include <impeller/types.glsl>

uniform VertInfo {
  mat4 mvp;
  mat4 matrix;
  vec2 texture_size;
}
vert_info;

in vec2 position;

out vec2 v_texture_coords;

void main() {
  gl_Position = vert_info.mvp * vec4(position, 0.0, 1.0);
  vec2 transformed = IPVec2TransformPosition(vert_info.matrix, position);
  v_texture_coords = transformed / vert_info.texture_size;
}
