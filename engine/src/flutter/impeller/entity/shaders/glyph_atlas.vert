// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/transform.glsl>

precision highp float;

uniform FrameInfo {
  highp mat4 mvp;
  highp mat4 entity_transform;
  highp vec2 atlas_size;
  highp vec2 offset;
  float is_translation_scale;
}
frame_info;

// XYWH.
in highp vec4 atlas_glyph_bounds;
// XYWH
in highp vec4 glyph_bounds;

in highp vec2 unit_position;
in highp vec2 glyph_position;

out highp vec2 v_uv;

mat4 basis(mat4 m) {
  return mat4(m[0][0], m[0][1], m[0][2], 0.0,  //
              m[1][0], m[1][1], m[1][2], 0.0,  //
              m[2][0], m[2][1], m[2][2], 0.0,  //
              0.0, 0.0, 0.0, 1.0               //
  );
}

vec2 project(mat4 m, vec2 v) {
  float w = v.x * m[0][3] + v.y * m[1][3] + m[3][3];
  vec2 result = vec2(v.x * m[0][0] + v.y * m[1][0] + m[3][0],
                     v.x * m[0][1] + v.y * m[1][1] + m[3][1]);

  // This is Skia's behavior, but it may be reasonable to allow UB for the w=0
  // case.
  if (w != 0) {
    w = 1 / w;
  }
  return result * w;
}

void main() {
  vec2 screen_offset =
      round(project(frame_info.entity_transform, frame_info.offset));

  // For each glyph, we compute two rectangles. One for the vertex positions
  // and one for the texture coordinates (UVs).
  vec2 uv_origin = (atlas_glyph_bounds.xy - vec2(0.5)) / frame_info.atlas_size;
  vec2 uv_size = (atlas_glyph_bounds.zw + vec2(1)) / frame_info.atlas_size;

  // Rounding here prevents most jitter between glyphs in the run when
  // nearest sampling.
  mat4 basis_transform = basis(frame_info.entity_transform);
  vec2 screen_glyph_position =
      screen_offset +
      round(project(basis_transform, (glyph_position + glyph_bounds.xy)));

  vec4 position;
  if (frame_info.is_translation_scale == 1.0) {
    // Rouding up here prevents the bounds from becoming 1 pixel too small
    // when nearest sampling. This path breaks down for projections.
    position = vec4(
        screen_glyph_position +
            ceil(project(basis_transform, unit_position * glyph_bounds.zw)),
        0.0, 1.0);
  } else {
    position = frame_info.entity_transform *
               vec4(frame_info.offset + glyph_position + glyph_bounds.xy +
                        unit_position * glyph_bounds.zw,
                    0.0, 1.0);
  }

  gl_Position = frame_info.mvp * position;
  v_uv = uv_origin + unit_position * uv_size;
}
