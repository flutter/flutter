// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/constants.glsl>
#include <impeller/gaussian.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

uniform f16sampler2D texture_sampler;

struct KernelSample {
  vec2 uv_offset;
  float coefficient;
};

uniform KernelSamples {
  int sample_count;
  KernelSample samples[48];
}
blur_info;

f16vec4 Sample(f16sampler2D tex, vec2 coords) {
#if ENABLE_DECAL_SPECIALIZATION
  return IPHalfSampleDecal(tex, coords);
#else
  return texture(tex, coords);
#endif
}

in vec2 v_texture_coords;

out f16vec4 frag_color;

void main() {
  f16vec4 total_color = f16vec4(0.0hf);

  for (int i = 0; i < blur_info.sample_count; ++i) {
    float16_t coefficient = float16_t(blur_info.samples[i].coefficient);
    total_color +=
        coefficient * Sample(texture_sampler,
                             v_texture_coords + blur_info.samples[i].uv_offset);
  }

  frag_color = total_color;
}
