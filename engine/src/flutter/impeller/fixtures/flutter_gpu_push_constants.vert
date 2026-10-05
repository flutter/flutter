// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Declared by both stages, which read the same 80 bytes. `color` comes first
// so both stages agree on its offset.
layout(push_constant) uniform DrawInfo {
  vec4 color;  // offset 0 bytes, size 16 bytes
  mat4 mvp;    // offset 16 bytes, size 64 bytes
}
draw_info;

in vec2 position;
out vec4 v_color;

void main() {
  v_color = draw_info.color;
  gl_Position = draw_info.mvp * vec4(position, 0.0, 1.0);
}
