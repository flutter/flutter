// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform FrameInfo {
  mat4 mvp;

  vec2 sigma_uv;

  float src_factor;
  float inner_blur_factor;
  float outer_blur_factor;
}
frame_info;

in vec2 vertices;
in vec2 texture_coords;

out vec2 v_texture_coords;
out vec2 v_sigma_uv;
out float v_src_factor;
out float v_inner_blur_factor;
out float v_outer_blur_factor;

void main() {
  gl_Position = frame_info.mvp * vec4(vertices, 0.0, 1.0);
  v_texture_coords = texture_coords;
  v_sigma_uv = frame_info.sigma_uv;
  v_src_factor = frame_info.src_factor;
  v_inner_blur_factor = frame_info.inner_blur_factor;
  v_outer_blur_factor = frame_info.outer_blur_factor;
}
