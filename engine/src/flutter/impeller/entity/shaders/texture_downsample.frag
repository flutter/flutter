// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <downsample.glsl>

vec4 Sample(vec2 uv) {
  return texture(texture_sampler, uv, float16_t(kDefaultMipBias));
}
