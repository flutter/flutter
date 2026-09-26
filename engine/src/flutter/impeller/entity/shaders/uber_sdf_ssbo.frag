// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "uber_sdf_common.glsl"

struct ColorPoint {
  vec4 color;
  float stop;
  float inverse_delta;
};

// Gradient ramp stops. Solid color sources use frag_info.color instead and
// ignore this buffer.
layout(std140) readonly buffer ColorData {
  ColorPoint colors[];
}
color_data;

// Provides the `getGradientColor()` implementation used by the shared UberSDF
// body in `uber_sdf_common.glsl`.
vec4 getGradientColor(float t) {
  // UberSDF always uses a transparent decal border.
  if ((t < 0.0 || t > 1.0) && frag_info.tile_mode == kTileModeDecal) {
    return vec4(0.0);
  }
  t = IPFloatTile(t, frag_info.tile_mode);

  vec4 gradient_color = vec4(0.0);
  int colors_length = int(frag_info.colors_length);
  for (int i = 1; i < colors_length; i++) {
    ColorPoint prev_point = color_data.colors[i - 1];
    ColorPoint current_point = color_data.colors[i];
    if (t >= prev_point.stop && t <= current_point.stop) {
      if (current_point.inverse_delta > 1000.0) {
        gradient_color = current_point.color;
      } else {
        float ratio = (t - prev_point.stop) * current_point.inverse_delta;
        gradient_color = mix(prev_point.color, current_point.color, ratio);
      }
      break;
    }
  }

  return gradient_color;
}
