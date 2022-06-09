// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform FrameInfo {
  mat4 mvp;
  vec4 color;
  float size;
} frame_info;

in vec2 vertex_position;
in vec2 vertex_normal;
in float pen_down;

out vec4 stroke_color;
out float v_pen_down;

void main() {
  // Push one vertex by the half stroke size along the normal vector.
  vec2 offset = vertex_normal * vec2(frame_info.size * 0.5);
  gl_Position = frame_info.mvp * vec4(vertex_position + offset, 0.0, 1.0);
  stroke_color = frame_info.color;
  v_pen_down = pen_down;
}
