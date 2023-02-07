// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/types.glsl>

uniform sampler2D glyph_atlas_sampler;

uniform FragInfo {
  vec2 atlas_size;
  vec4 text_color;
}
frag_info;

in vec2 v_unit_position;
in vec2 v_source_position;
in vec2 v_source_glyph_size;
in float v_has_color;

out vec4 frag_color;

void main() {
  vec2 uv_size = v_source_glyph_size / frag_info.atlas_size;
  vec2 uv_position = v_source_position / frag_info.atlas_size;
  if (v_has_color == 1.0) {
    frag_color =
        texture(glyph_atlas_sampler, v_unit_position * uv_size + uv_position) *
        frag_info.text_color.a;
  } else {
    frag_color =
        texture(glyph_atlas_sampler, v_unit_position * uv_size + uv_position)
            .aaaa *
        frag_info.text_color;
  }
}
