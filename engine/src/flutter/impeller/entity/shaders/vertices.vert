// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform FrameInfo {
  mat4 mvp;
} frame_info;

in vec2 point;
in vec4 vertex_color;

out vec4 color;

void main() {
  gl_Position = frame_info.mvp * vec4(point, 0.0, 1.0);
  color = vertex_color;
}
