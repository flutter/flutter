// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

layout(push_constant) uniform DrawInfo {
  vec4 color;
  mat4 mvp;
}
draw_info;

in vec4 v_color;
out vec4 frag_color;

void main() {
  frag_color = v_color * draw_info.color;
}
