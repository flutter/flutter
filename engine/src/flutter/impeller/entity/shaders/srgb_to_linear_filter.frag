// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/color.glsl>

// Creates a color filter that applies the inverse of the sRGB gamma curve
// to the RGB channels.

#include <impeller/types.glsl>

uniform sampler2D input_texture;

uniform FragInfo {
  float input_alpha;
}
frag_info;

in highp vec2 v_texture_coords;
out vec4 frag_color;

void main() {
  vec4 input_color =
      texture(input_texture, v_texture_coords) * frag_info.input_alpha;

  vec4 color = IPUnpremultiply(input_color);
  for (int i = 0; i < 3; i++) {
    if (color[i] <= 0.04045) {
      color[i] = color[i] / 12.92;
    } else {
      color[i] = pow((color[i] + 0.055) / 1.055, 2.4);
    }
  }

  frag_color = IPPremultiply(color);
}
