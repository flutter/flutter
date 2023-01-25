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
                                vec2 destination_position,
                                vec2 destination_size) {
  mat4 translation = mat4(1, 0, 0, 0,  //
                          0, 1, 0, 0,  //
                          0, 0, 1, 0,  //
                          destination_position.xy, 0, 1);
  return mvp * translation *
         vec4(unit_position.x * destination_size.x,
              unit_position.y * destination_size.y, 0.0, 1.0);
}

#endif
