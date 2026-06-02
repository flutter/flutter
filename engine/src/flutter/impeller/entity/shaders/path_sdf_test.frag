// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/color.glsl>
#include <impeller/types.glsl>

uniform sampler2D texture_sampler;

uniform FragInfo {
  vec4 color;
  vec2 bounds_origin;
  vec2 bounds_size;
  float stroke_width;
  float aa_pixels;
}
frag_info;

out vec4 frag_color;

void main() {
  // 1. Calculate UV coordinates relative to path bounds in screen pixels
  vec2 uv = (gl_FragCoord.xy - frag_info.bounds_origin) / frag_info.bounds_size;

  // Clamp UV to prevent sampling wrap-around artifacts outside the bounds
  uv = clamp(uv, 0.0, 1.0);

  // 2. Sample the solid path mask
  float mask = texture(texture_sampler, uv).r;

  // 3. Compute screen-space gradients
  float mask_dx = dFdx(mask);
  float mask_dy = dFdy(mask);
  float grad_len = length(vec2(mask_dx, mask_dy));

  // Avoid division by zero in flat areas
  grad_len = max(grad_len, 0.0001);

  // 4. Estimate the signed distance to the boundary in screen pixels
  float sdf = (0.5 - mask) / grad_len;

  // 5. Stroke vs Fill evaluation
  float dist = (frag_info.stroke_width > 0.0)
                   ? (abs(sdf) - frag_info.stroke_width * 0.5)
                   : sdf;

  // 6. High-quality subpixel antialiasing
  float fade_size = frag_info.aa_pixels * 0.5;
  float alpha = 1.0 - smoothstep(-fade_size, fade_size, dist);

  vec4 final_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(final_color);
}
