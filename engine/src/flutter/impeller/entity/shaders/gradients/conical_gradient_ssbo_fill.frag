// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision highp float;

#include <impeller/color.glsl>
#include <impeller/dithering.glsl>
#include <impeller/gradient.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

layout(constant_id = 0) const float kind = 3.0;

struct ColorPoint {
  vec4 scale;
  vec4 bias;
  float threshold;
};

layout(std140) readonly buffer ColorData {
  ColorPoint colors[];
}
color_data;

IP_DEFINE_BINARY_SEARCH_COLOR_INDEX(IPBinarySearchColorIndex, color_data.colors)

uniform FragInfo {
  highp vec2 center;
  float radius;
  float tile_mode;
  vec4 decal_border_color;
  float alpha;
  int colors_length;
  vec2 focus;
  float focus_radius;
}
frag_info;

highp in vec2 v_position;

out vec4 frag_color;

void main() {
  vec2 res = IPComputeConicalT(kind, frag_info.focus, frag_info.focus_radius,
                               frag_info.center, frag_info.radius, v_position);

  float t = res.x;
  f16vec4 color;
  if (res.y < 0.0 ||
      ((t < 0.0 || t > 1.0) && frag_info.tile_mode == kTileModeDecal)) {
    color = f16vec4(frag_info.decal_border_color);
  } else {
    t = IPFloatTile(t, frag_info.tile_mode);

    int lo = IPBinarySearchColorIndex(t, frag_info.colors_length);
    ColorPoint segment = color_data.colors[lo];
    color = float16_t(t) * f16vec4(segment.scale) + f16vec4(segment.bias);
  }

  color = IPHalfPremultiply(color) * float16_t(frag_info.alpha);
  color = IPHalfOrderedDither8x8(color, gl_FragCoord.xy);
  frag_color = vec4(color);
}
