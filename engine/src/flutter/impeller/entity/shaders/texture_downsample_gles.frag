// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <downsample.glsl>

vec4 Sample(vec2 uv) {
  if ((uv.x < 0 || uv.y < 0 || uv.x > 1 || uv.y > 1)) {
    return vec4(0);
  } else {
    return texture(texture_sampler, uv, float16_t(kDefaultMipBias));
  }
}
