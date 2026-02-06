// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <downsample.glsl>

uniform BoundInfo {
  // A matrix to calculate the signed distance from the edges of the quad
  // defining the bounded area.
  //
  // See PrecomputeQuadLineParameters for details on the format.
  mat4 quad_line_params;
}
bound_info;

// Determines if the given texture coordinates are out of bounds defined by
// `frag_info.quad_line_params`.
bool OutOfBounds(vec2 coords) {
  vec4 signed_distances = vec4(coords, 1.0, 0.0) * bound_info.quad_line_params;
  return any(lessThan(signed_distances, vec4(0.0)));
}

vec4 Sample(vec2 uv) {
  if (OutOfBounds(uv)) {
    return vec4(0);
  }
  return texture(texture_sampler, uv, float16_t(kDefaultMipBias));
}
