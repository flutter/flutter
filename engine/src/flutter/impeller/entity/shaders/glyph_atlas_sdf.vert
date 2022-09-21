// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/transform.glsl>

uniform FrameInfo {
  mat4 mvp;
} frame_info;

in vec2 unit_vertex;
in vec2 glyph_position;
in vec2 glyph_size;
in vec2 atlas_position;
in vec2 atlas_glyph_size;

out vec2 v_unit_vertex;
out vec2 v_atlas_position;
out vec2 v_atlas_glyph_size;

void main() {
  gl_Position = IPPositionForGlyphPosition(frame_info.mvp, unit_vertex, glyph_position, glyph_size);
  v_unit_vertex = unit_vertex;
  v_atlas_position = atlas_position;
  v_atlas_glyph_size = atlas_glyph_size;
}
