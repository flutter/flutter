// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform sampler2D glyph_atlas_sampler;

uniform FragInfo {
  vec2 atlas_size;
  vec4 text_color;
} frag_info;

in vec2 v_unit_vertex;
in vec2 v_atlas_position;
in vec2 v_atlas_glyph_size;
in float v_color_glyph;

out vec4 frag_color;

void main() {
  vec2 scale_perspective = v_atlas_glyph_size / frag_info.atlas_size;
  vec2 offset = v_atlas_position / frag_info.atlas_size;
  if (v_color_glyph == 1.0) {
    frag_color = texture(
      glyph_atlas_sampler,
      v_unit_vertex * scale_perspective + offset
    );
  } else {
    frag_color = texture(
      glyph_atlas_sampler,
      v_unit_vertex * scale_perspective + offset
    ).aaaa * frag_info.text_color;
  }
}
