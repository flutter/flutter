// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <downsample.glsl>

uniform BoundsInfo {
  mat4 quad_line_params;
}
decal_info;

vec4 Sample(highp vec2 uv) {
  vec4 signed_distances = decal_info.quad_line_params * vec4(uv, 1.0, 0.0);
  if (any(lessThan(signed_distances, vec4(0.0)))) {
    return vec4(0);
  } else {
    return texture(texture_sampler, uv, float16_t(kDefaultMipBias));
  }
}
