// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/texture.glsl>

vec4 Sample(sampler2D tex, vec2 coords) {
  return IPSampleDecal(tex, coords);
}

#include "gaussian_blur.glsl"
