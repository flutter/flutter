// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

vec3 ComponentIsValue(vec3 n, float value) {
  return vec3(n.r == value, n.g == value, n.b == value);
}

vec3 Blend(vec3 dst, vec3 src) {
  vec3 color = 1 - min(vec3(1), (1 - dst) / src);
  color = mix(color, vec3(1), ComponentIsValue(dst, 1.0));
  color = mix(color, vec3(0), ComponentIsValue(src, 0.0));
  return color;
}

#include "advanced_blend.glsl"
