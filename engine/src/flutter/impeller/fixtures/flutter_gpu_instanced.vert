// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform VertInfo {
  mat4 mvp;
}
vert_info;

in vec2 position;
in vec2 instance_offset;
in vec4 instance_color;
out vec4 v_color;

void main() {
  v_color = instance_color;
  gl_Position = vert_info.mvp * vec4(position + instance_offset, 0.0, 1.0);
}
