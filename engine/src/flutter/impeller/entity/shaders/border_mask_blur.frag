// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Constant time mask blur for image borders.
//
// This mask blur extends the geometry of the source image (with clamp border
// sampling) and applies a Gaussian blur to the alpha mask at the edges.
//
// The blur itself works by mapping the Gaussian distribution's indefinite
// integral (using an erf approximation) to the 4 edges of the UV rectangle and
// multiplying them.

uniform sampler2D texture_sampler;

in vec2 v_texture_coords;
in vec2 v_sigma_uv;
in float v_src_factor;
in float v_inner_blur_factor;
in float v_outer_blur_factor;

out vec4 frag_color;

// Abramowitz and Stegun erf approximation.
float erf(float x) {
  float a = abs(x);
  // 0.278393*x + 0.230389*x^2 + 0.078108*x^4 + 1
  float b = (0.278393 + (0.230389 + 0.078108 * a * a) * a) * a + 1.0;
  return sign(x) * (1 - 1 / (b * b * b * b));
}

const float kHalfSqrtTwo = 0.70710678118;

// Indefinite integral of the Gaussian function (with constant range 0->1).
float GaussianIntegral(float x, float sigma) {
  // ( 1 + erf( x * (sqrt(2) / (2 * sigma) ) ) / 2
  // Because this sigmoid is always > 1, we remap it (n * 1.07 - 0.07)
  // so that it always fades to zero before it reaches the blur radius.
  return 0.535 * erf(x * (kHalfSqrtTwo / sigma)) + 0.465;
}

float BoxBlurMask(vec2 uv) {
  // LTRB
  return GaussianIntegral(uv.x, v_sigma_uv.x) *      //
         GaussianIntegral(uv.y, v_sigma_uv.y) *      //
         GaussianIntegral(1 - uv.x, v_sigma_uv.x) *  //
         GaussianIntegral(1 - uv.y, v_sigma_uv.y);
}

void main() {
  vec4 image_color = texture(texture_sampler, v_texture_coords);
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
