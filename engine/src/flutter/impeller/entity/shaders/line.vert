// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/types.glsl>

uniform FrameInfo {
  mat4 mvp;
}
frame_info;

in vec2 position;

in vec3 e0;
in vec3 e1;
in vec3 e2;
in vec3 e3;

out vec2 v_position;
out vec3 v_e0;
out vec3 v_e1;
out vec3 v_e2;
out vec3 v_e3;

void main() {
  gl_Position = frame_info.mvp * vec4(position, 0.0, 1.0);
  v_position = position;
  v_e0 = e0;
  v_e1 = e1;
  v_e2 = e2;
  v_e3 = e3;
}
