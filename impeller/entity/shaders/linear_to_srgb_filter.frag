// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/color.glsl>
#include <impeller/types.glsl>

// A color filter that applies the sRGB gamma curve to the color.
//
// This filter is used so that the colors are suitable for display in monitors.

uniform sampler2D input_texture;

uniform FragInfo {
  float input_alpha;
}
frag_info;

in vec2 v_position;
out vec4 frag_color;

void main() {
  vec4 input_color = texture(input_texture, v_position) * frag_info.input_alpha;

  vec4 color = IPUnpremultiply(input_color);
  for (int i = 0; i < 3; i++) {
    if (color[i] <= 0.0031308) {
      color[i] = (color[i]) * 12.92;
    } else {
      color[i] = 1.055 * pow(color[i], (1.0 / 2.4)) - 0.055;
    }
  }

  frag_color = IPPremultiply(color);
}
