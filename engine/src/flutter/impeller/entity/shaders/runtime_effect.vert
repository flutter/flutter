// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/types.glsl>

layout(binding = 10) uniform FrameInfo {
  mat4 mvp;
  mat4 text_transform_0;
  mat4 text_transform_1;
  mat4 text_transform_2;
  mat4 text_transform_3;
}
frame_info;

in vec2 position;
// Note: The GLES backend uses name matching for attribute locations. This name
// must match the name of the attribute input in:
// impeller/compiler/shader_lib/flutter/runtime_effect.glsl
out vec2 _fragCoord;
out vec2 v_tex_coord_0;
out vec2 v_tex_coord_1;
out vec2 v_tex_coord_2;
out vec2 v_tex_coord_3;

void main() {
  gl_Position = frame_info.mvp * vec4(position, 0.0, 1.0);
  _fragCoord = position;
  v_tex_coord_0 = (frame_info.text_transform_0 * vec4(position, 0.0, 1.0)).xy;
  v_tex_coord_1 = (frame_info.text_transform_1 * vec4(position, 0.0, 1.0)).xy;
  v_tex_coord_2 = (frame_info.text_transform_2 * vec4(position, 0.0, 1.0)).xy;
  v_tex_coord_3 = (frame_info.text_transform_3 * vec4(position, 0.0, 1.0)).xy;
}
