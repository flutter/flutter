// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform VertInfo {
  mat4 mvp;
  float size;
}
vert_info;

in vec2 position;
in vec2 normal;
in float pen_down;

out float v_pen_down;

void main() {
  // Push one vertex by the half stroke size along the normal vector.
  vec2 offset = normal * vec2(vert_info.size * 0.5);
  gl_Position = vert_info.mvp * vec4(position + offset, 0.0, 1.0);
  v_pen_down = pen_down;
}
