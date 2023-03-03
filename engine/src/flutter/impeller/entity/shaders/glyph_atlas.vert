// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/transform.glsl>
#include <impeller/types.glsl>

uniform FrameInfo {
  mat4 mvp;
}
frame_info;

in vec4 position;
in vec2 uv;
in float has_color;

out vec2 v_uv;
out float v_has_color;

void main() {
  gl_Position = frame_info.mvp * position;
  v_uv = uv;
  v_has_color = has_color;
}
