// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform FrameInfo {
  mat4 mvp;
  vec2 atlas_size;
  vec4 text_color;
} frame_info;

readonly buffer GlyphPositions {
  mat4 position[];
} glyph_positions;

readonly buffer GlyphSizes {
  vec2 size[];
} glyph_sizes;

readonly buffer AtlasPositions {
  vec2 position[];
} atlas_positions;

readonly buffer AtlasGlyphSizes {
  vec2 size[];
} atlas_glyph_sizes;

in vec2 unit_vertex;

out vec2 v_unit_vertex;
out vec2 v_atlas_position;
out vec2 v_atlas_glyph_size;
out vec2 v_atlas_size;
out vec4 v_text_color;

void main() {
  // The position to place the glyph.
  mat4 glyph_position = glyph_positions.position[gl_InstanceIndex];
  // The size of the glyph.
  vec2 glyph_size = glyph_sizes.size[gl_InstanceIndex];
  // The location of the glyph in the atlas.
  vec2 glyph_atlas_position = atlas_positions.position[gl_InstanceIndex];
  // The size of the glyph within the atlas.
  vec2 glyph_atlas_size = atlas_glyph_sizes.size[gl_InstanceIndex];

  gl_Position = frame_info.mvp
              * glyph_position
              * vec4(unit_vertex.x * glyph_size.x,
                     unit_vertex.y * glyph_size.y, 0.0, 1.0);

  v_unit_vertex = unit_vertex;
  v_atlas_position = glyph_atlas_position;
  v_atlas_glyph_size = glyph_atlas_size;
  v_atlas_size = frame_info.atlas_size;
  v_text_color = frame_info.text_color;
}
