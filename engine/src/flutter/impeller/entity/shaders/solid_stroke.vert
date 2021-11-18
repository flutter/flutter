// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform FrameInfo {
  mat4 mvp;
} frame_info;

uniform StrokeInfo {
  vec4 color;
  float size;
} stroke_info;

in vec2 vertex_position;
in vec2 vertex_normal;

out vec4 stroke_color;

void main() {
  // Push one vertex by the half stroke size along the normal vector.
  vec2 offset = vertex_normal * vec2(stroke_info.size * 0.5);
  gl_Position = frame_info.mvp * vec4(vertex_position + offset, 0.0, 1.0);
  stroke_color = stroke_info.color;
}
