// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/gaussian.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  f16vec4 color;
  f16vec2 rect_size;
  float16_t blur_sigma;
  float16_t corner_radius;
}
frag_info;

in f16vec2 v_position;

out f16vec4 frag_color;

const int kSampleCount = 4;

float16_t RRectDistance(f16vec2 sample_position, f16vec2 half_size) {
  f16vec2 space = abs(sample_position) - half_size + frag_info.corner_radius;
  return length(max(space, float16_t(0.0hf))) +
         min(max(space.x, space.y), float16_t(0.0hf)) - frag_info.corner_radius;
}

/// Closed form unidirectional rounded rect blur mask solution using the
/// analytical Gaussian integral (with approximated erf).
float16_t RRectShadowX(f16vec2 sample_position, f16vec2 half_size) {
  // Compute the X direction distance field (not incorporating the Y distance)
  // for the rounded rect.
  float16_t space =
      min(float16_t(0.0hf),
          half_size.y - frag_info.corner_radius - abs(sample_position.y));
  float16_t rrect_distance =
      half_size.x - frag_info.corner_radius +
      sqrt(max(
          float16_t(0.0hf),
          frag_info.corner_radius * frag_info.corner_radius - space * space));

  // Map the linear distance field to the approximate Gaussian integral.
  f16vec2 integral = IPVec2FastGaussianIntegral(
      sample_position.x + f16vec2(-rrect_distance, rrect_distance),
      frag_info.blur_sigma);
  return integral.y - integral.x;
}

float16_t RRectShadow(f16vec2 sample_position, f16vec2 half_size) {
  // Limit the sampling range to 3 standard deviations in the Y direction from
  // the kernel center to incorporate 99.7% of the color contribution.
  float16_t half_sampling_range = frag_info.blur_sigma * 3.0hf;

  float16_t begin_y =
      max(-half_sampling_range, sample_position.y - half_size.y);
  float16_t end_y = min(half_sampling_range, sample_position.y + half_size.y);
  float16_t interval = (end_y - begin_y) / float16_t(kSampleCount);

  // Sample the X blur kSampleCount times, weighted by the Gaussian function.
  float16_t result = 0.0hf;
  for (int sample_i = 0; sample_i < kSampleCount; sample_i++) {
    float16_t y = begin_y + interval * (float16_t(sample_i) + 0.5hf);
    result += RRectShadowX(f16vec2(sample_position.x, sample_position.y - y),
                           half_size) *
              IPGaussian(y, frag_info.blur_sigma) * interval;
  }

  return result;
}

void main() {
  frag_color = frag_info.color;

  f16vec2 half_size = frag_info.rect_size * 0.5hf;
  f16vec2 sample_position = v_position - half_size;

  if (frag_info.blur_sigma > 0.0hf) {
    frag_color *= RRectShadow(sample_position, half_size);
  } else {
    frag_color *= -RRectDistance(sample_position, half_size);
  }
}
