// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

vec3 ComponentIsValue(vec3 n, float value) {
  vec3 diff = abs(n - value);
  return vec3(diff.r < 0.0001, diff.g < 0.0001, diff.b < 0.0001);
}

vec3 MixComponents(vec3 a, vec3 b, vec3 weight, float cutoff) {
  return vec3(mix(a.x, b.x, weight.x > cutoff),  //
              mix(a.y, b.y, weight.y > cutoff),  //
              mix(a.z, b.z, weight.z > cutoff));
}

vec3 MixHalf(vec3 a, vec3 b, vec3 weight) {
  return MixComponents(a, b, weight, 0.5);
}

vec3 BlendScreen(vec3 dst, vec3 src) {
  return dst + src - (dst * src);
}

vec3 BlendHardLight(vec3 dst, vec3 src) {
  return MixHalf(dst * (2 * src), BlendScreen(dst, 2 * src - 1), src);
}
