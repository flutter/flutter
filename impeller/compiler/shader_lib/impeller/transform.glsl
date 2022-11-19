// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TRANSFORM_GLSL_
#define TRANSFORM_GLSL_

/// Returns the Cartesian coordinates of `position` in `transform` space.
vec2 IPVec2TransformPosition(mat4 matrix, vec2 point) {
  vec4 transformed = matrix * vec4(point, 0, 1);
  return transformed.xy / transformed.w;
}

// Returns the transformed gl_Position for a given glyph position in a glyph
// atlas.
vec4 IPPositionForGlyphPosition(mat4 mvp,
                                vec2 unit_position,
                                vec2 glyph_position,
                                vec2 glyph_size) {
  vec4 translate =
      mvp[0] * glyph_position.x + mvp[1] * glyph_position.y + mvp[3];
  mat4 translated_mvp =
      mat4(mvp[0], mvp[1], mvp[2], vec4(translate.xyz, mvp[3].w));
  return translated_mvp * vec4(unit_position.x * glyph_size.x,
                               unit_position.y * glyph_size.y, 0.0, 1.0);
}

#endif
