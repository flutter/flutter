// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/types.glsl>

#include <impeller/transform.glsl>

uniform FrameInfo {
  mat4 mvp;
}
frame_info;

in vec4 position;
in vec2 uv;

out vec2 v_uv;

void main() {
  gl_Position = frame_info.mvp * position;
  v_uv = uv;
}
