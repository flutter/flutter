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


// These values must correspond to the order of the items in the
// 'Entity::TileMode' enum class.
const float kTileModeClamp = 0;
const float kTileModeRepeat = 1;
const float kTileModeMirror = 2;
const float kTileModeDecal = 3;

/// Compute an interpolant value "t".
///
/// The domain appears to be any value and the range is [0 to 1].
float IPTileTextureCoords(float t, float tile_mode) {
  if (tile_mode == kTileModeClamp) {
    t = clamp(t, 0.0, 1.0);
  } else if (tile_mode == kTileModeRepeat) {
    t = fract(t);
  } else if (tile_mode == kTileModeMirror) {
    float t1 = t - 1;
    float t2 = t1 - 2 * floor(t1 * 0.5) - 1;
    t = abs(t2);
  }
  return t;
}

#endif
