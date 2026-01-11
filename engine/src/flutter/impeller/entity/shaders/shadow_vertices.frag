// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/gaussian.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  // shadow_color is the color supplied to DrawShadow. It will be modulated
  // by the gaussian opacity of the shadow, computed from the coefficient
  // in the mesh vertex data.
  f16vec4 shadow_color;
}
frag_info;

// v_gaussian will contain the interpolated gaussian coefficient from the
// mesh per-vertex data. It determines where in the gaussian curve of the
// umbra and penumbra we are with 0.0 representing the outermost part of
// the penumbra and 1.0 representing the innermost umbra.
in float16_t v_gaussian;

out f16vec4 frag_color;

// A shader that modulates the shadow color by the gaussian integral
// value computed from the interpolated v_gaussian coefficient.
void main() {
  frag_color =
      frag_info.shadow_color * IPHalfFractionToFastGaussianCDF(v_gaussian);
}
