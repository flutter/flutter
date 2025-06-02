// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

<<<<<<< HEAD:engine/src/flutter/impeller/entity/shaders/gradients/conical_gradient_fill.frag
precision highp float;
=======
#ifndef CONICAL_GRADIENT_UNIFORM_FILL_GLSL_
#define CONICAL_GRADIENT_UNIFORM_FILL_GLSL_
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8:engine/src/flutter/impeller/compiler/shader_lib/impeller/conical_gradient_fill.glsl

#include <impeller/texture.glsl>

uniform sampler2D texture_sampler;

uniform FragInfo {
  highp vec2 center;
  float radius;
  float tile_mode;
  vec4 decal_border_color;
  float texture_sampler_y_coord_scale;
  float alpha;
  vec2 half_texel;
  vec2 focus;
  float focus_radius;
}
frag_info;

vec4 DoConicalGradientTextureFill(vec2 res) {
  if (res.y < 0.0) {
    return vec4(0);
  }

  float t = res.x;
  vec4 result =
      IPSampleLinearWithTileMode(texture_sampler,                          //
                                 vec2(t, 0.5),                             //
                                 frag_info.texture_sampler_y_coord_scale,  //
                                 frag_info.half_texel,                     //
                                 frag_info.tile_mode,                      //
                                 frag_info.decal_border_color);
  result = IPPremultiply(result) * frag_info.alpha;
  return result;
}

#endif  // CONICAL_GRADIENT_UNIFORM_FILL_GLSL_
