// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/gaussian.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

// Constant time mask blur for image borders.
//
// This mask blur extends the geometry of the source image (with clamp border
// sampling) and applies a Gaussian blur to the alpha mask at the edges.
//
// The blur itself works by mapping the Gaussian distribution's indefinite
// integral (using an erf approximation) to the 4 edges of the UV rectangle and
// multiplying them.

uniform sampler2D texture_sampler;

uniform FragInfo {
  float texture_sampler_y_coord_scale;
}
frag_info;

in vec2 v_texture_coords;
in vec2 v_sigma_uv;
in float v_src_factor;
in float v_inner_blur_factor;
in float v_outer_blur_factor;

out vec4 frag_color;

float BoxBlurMask(vec2 uv) {
  // LTRB
  return IPGaussianIntegral(uv.x, v_sigma_uv.x) *      //
         IPGaussianIntegral(uv.y, v_sigma_uv.y) *      //
         IPGaussianIntegral(1 - uv.x, v_sigma_uv.x) *  //
         IPGaussianIntegral(1 - uv.y, v_sigma_uv.y);
}

void main() {
  vec4 image_color = IPSample(texture_sampler, v_texture_coords,
                              frag_info.texture_sampler_y_coord_scale);
  float blur_factor = BoxBlurMask(v_texture_coords);

  float within_bounds =
      float(v_texture_coords.x >= 0 && v_texture_coords.y >= 0 &&
            v_texture_coords.x < 1 && v_texture_coords.y < 1);
  float inner_factor =
      (v_inner_blur_factor * blur_factor + v_src_factor) * within_bounds;
  float outer_factor = v_outer_blur_factor * blur_factor * (1 - within_bounds);

  float mask_factor = inner_factor + outer_factor;
  frag_color = image_color * mask_factor;
}
