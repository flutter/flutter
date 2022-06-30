// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TEXTURE_GLSL_
#define TEXTURE_GLSL_

#include <impeller/branching.glsl>

/// Sample from a texture.
///
/// If `y_coord_scale` < 0.0, the Y coordinate is flipped. This is useful
/// for Impeller graphics backends that use a flipped framebuffer coordinate
/// space.
vec4 IPSample(sampler2D texture_sampler, vec2 coords, float y_coord_scale) {
  if (y_coord_scale < 0.0) {
    coords.y = 1.0 - coords.y;
  }
  return texture(texture_sampler, coords);
}

/// Sample a texture, emulating SamplerAddressMode::ClampToBorder.
///
/// This is useful for Impeller graphics backend that don't support
/// ClampToBorder.
vec4 IPSampleClampToBorder(sampler2D tex, vec2 uv) {
  float within_bounds = float(uv.x > 0 && uv.y > 0 && uv.x < 1 && uv.y < 1);
  return texture(tex, uv) * within_bounds;
}

#endif
