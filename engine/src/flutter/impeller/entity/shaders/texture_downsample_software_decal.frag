// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <downsample.glsl>

uniform DecalInfo {
  vec4 bounds_uv;
}
decal_info;

vec4 Sample(highp vec2 uv) {
  vec4 bounds = decal_info.bounds_uv;
  if ((uv.x < bounds.x || uv.y < bounds.y || uv.x > bounds.z ||
       uv.y > bounds.w)) {
    return vec4(0);
  } else {
    return texture(texture_sampler, uv, float16_t(kDefaultMipBias));
  }
}
