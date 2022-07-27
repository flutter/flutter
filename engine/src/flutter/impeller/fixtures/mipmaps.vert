// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform VertInfo {
  mat4 mvp;
}
vert_info;

in vec2 vertex_position;
in vec2 uv;

out vec2 v_uv;

void main() {
  gl_Position = vert_info.mvp * vec4(vertex_position, 0.0, 1.0);
  v_uv = uv;
}
