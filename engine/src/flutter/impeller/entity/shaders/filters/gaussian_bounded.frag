// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/color.glsl>
#include <impeller/constants.glsl>
#include <impeller/gaussian.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

uniform f16sampler2D texture_sampler;

layout(constant_id = 0) const float supports_decal = 1.0;

uniform KernelSamples {
  float sample_count;

  // X, Y are uv offset and Z is Coefficient. W is padding.
  vec4 sample_data[50];
}
kernel_samples;

uniform FragInfo {
  // A matrix to calculate the signed distance from the edges of the quad
  // defining the bounded area.
  //
  // See PrecomputeQuadLineParameters for details on the format.
  mat4 quad_line_params;
}
frag_info;

f16vec4 Sample(f16sampler2D tex, vec2 coords) {
  if (supports_decal == 1.0) {
    return texture(tex, coords);
  }
  return IPHalfSampleDecal(tex, coords);
}

// Determines if the given texture coordinates are out of bounds defined by
// `frag_info.quad_line_params`.
bool OutOfBounds(vec2 coords) {
  vec4 signed_distances = vec4(coords, 1.0, 0.0) * frag_info.quad_line_params;
  return any(lessThan(signed_distances, vec4(0.0)));
}

// Sampling the texture while treating out of bounds pixels as almost
// transparent.
//
// Returns Sample(tex, coords) for in-bounds pixels.  For out-of-bounds (OOB)
// pixels, it returns the same color but clamps alpha to `min_alpha`.
//
// This is crucial for preventing dark fringes at the blur boundary. This is a
// two-pass blur, and the second pass linearly interpolates the first pass's
// output. If OOB samples were transparent black (0,0,0,0), interpolating with
// premultiplied in-bounds pixels would darken the color.
//
// Using the edge color with a minimal alpha provides the correct RGB continuity
// for the interpolator while being effectively transparent, avoiding the
// artifact.
f16vec4 BoundedSample(f16sampler2D tex, vec2 coords) {
  f16vec4 color = Sample(tex, coords);
  const float16_t min_alpha = 1.0hf / 255.0hf;
  if (OutOfBounds(coords)) {
    color.a = min(color.a, min_alpha);
  }
  return color;
}

in vec2 v_texture_coords;

out f16vec4 frag_color;

void main() {
  f16vec4 total_color = f16vec4(0.0hf);
  int sample_count = int(kernel_samples.sample_count);

  int i = 0;
  // Use sample_count - 1 so that there is always at least one sample left for
  // the edge compensation.
  for (; i < (sample_count - 1) &&
         OutOfBounds(v_texture_coords + kernel_samples.sample_data[i].xy);
       i++) {
  }

  // Starting edge compensation.
  //
  // This allieviates the issue caused by the lerped kernel where the first
  // in-bounds sample is actually quite far from the edge, and there is a large
  // gap that would be unaccounted for in the blur.
  if (i > 0) {
    vec2 offset = (kernel_samples.sample_data[i].xy +
                   kernel_samples.sample_data[i - 1].xy) /
                  2.0;
    float16_t coefficient = kernel_samples.sample_data[i].z / 2.0;
    total_color +=
        coefficient * IPHalfPremultiply(BoundedSample(
                          texture_sampler, v_texture_coords + offset));
  }

  for (; i < sample_count &&
         !OutOfBounds(v_texture_coords + kernel_samples.sample_data[i].xy);
       i++) {
    float16_t coefficient = float16_t(kernel_samples.sample_data[i].z);
    total_color +=
        coefficient * IPHalfPremultiply(Sample(
                          texture_sampler,
                          v_texture_coords + kernel_samples.sample_data[i].xy));
  }

  // Ending edge compensation.
  if (i < sample_count) {
    vec2 offset = (kernel_samples.sample_data[i].xy +
                   kernel_samples.sample_data[i - 1].xy) /
                  2.0;
    float16_t coefficient = kernel_samples.sample_data[i].z / 2.0;
    total_color +=
        coefficient * IPHalfPremultiply(BoundedSample(
                          texture_sampler, v_texture_coords + offset));
  }

  frag_color = IPHalfUnpremultiplyOpaque(total_color);
}
