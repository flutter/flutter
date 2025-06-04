// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

<<<<<<< HEAD:engine/src/flutter/impeller/entity/shaders/gradients/conical_gradient_uniform_fill.frag
=======
#ifndef CONICAL_GRADIENT_UNIFORM_FILL_GLSL_
#define CONICAL_GRADIENT_UNIFORM_FILL_GLSL_

>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8:engine/src/flutter/impeller/compiler/shader_lib/impeller/conical_gradient_uniform_fill.glsl
precision highp float;

#include <impeller/texture.glsl>

uniform FragInfo {
  highp vec2 center;
  vec2 focus;
  float focus_radius;
  float radius;
  float tile_mode;
  float alpha;
  float colors_length;
  vec4 decal_border_color;
  vec4 colors[256];
  vec4 stop_pairs[128];
}
frag_info;

vec4 DoConicalGradientUniformFill(vec2 res) {
  float t = res.x;
  vec4 result_color = vec4(0);
  if (res.y < 0.0 ||
      ((t < 0.0 || t > 1.0) && frag_info.tile_mode == kTileModeDecal)) {
    result_color = frag_info.decal_border_color;
  } else {
    t = IPFloatTile(t, frag_info.tile_mode);

    vec2 prev_stop = frag_info.stop_pairs[0].xy;
    bool even = false;
    for (int i = 1; i < frag_info.colors_length; i++) {
      // stop_pairs[i/2].xy = values for stop i
      // stop_pairs[i/2].zw = values for stop i+1
      vec2 cur_stop = even ? frag_info.stop_pairs[i / 2].xy
                           : frag_info.stop_pairs[i / 2].zw;
      even = !even;
      // stop.x == t value
      // stop.y == inverse_delta to next stop
      if (t >= prev_stop.x && t <= cur_stop.x) {
        if (cur_stop.y > 1000.0) {
          result_color = frag_info.colors[i];
        } else {
          float ratio = (t - prev_stop.x) * cur_stop.y;
          result_color =
              mix(frag_info.colors[i - 1], frag_info.colors[i], ratio);
        }
        break;
      }
      prev_stop = cur_stop;
    }
  }

  result_color = IPPremultiply(result_color) * frag_info.alpha;
  return result_color;
}

#endif  // CONICAL_GRADIENT_UNIFORM_FILL_GLSL_
