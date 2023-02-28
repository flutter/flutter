// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/texture.glsl>
#include <impeller/transform.glsl>
#include <impeller/types.glsl>

uniform FrameInfo {
  mat4 mvp;
  mat4 effect_transform;
  vec2 bounds_origin;
  vec2 texture_size;
  float texture_sampler_y_coord_scale;
}
frame_info;

in vec2 position;

out vec2 v_texture_coords;

void main() {
  gl_Position = frame_info.mvp * vec4(position, 0.0, 1.0);
  v_texture_coords = IPRemapCoords(
      IPVec2TransformPosition(
          frame_info.effect_transform,
          (position - frame_info.bounds_origin) / frame_info.texture_size),
      frame_info.texture_sampler_y_coord_scale);
}
