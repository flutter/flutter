// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/gaussian.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  vec4 color;
  float blur_sigma;
  vec2 rect_size;
  float corner_radius;
}
frag_info;

in vec2 v_position;

out vec4 frag_color;

const int kSampleCount = 4;

float RRectDistance(vec2 sample_position, vec2 half_size) {
  vec2 space = abs(sample_position) - half_size + frag_info.corner_radius;
  return length(max(space, 0.0)) + min(max(space.x, space.y), 0.0) -
         frag_info.corner_radius;
}

/// Closed form unidirectional rounded rect blur mask solution using the
/// analytical Gaussian integral (with approximated erf).
float RRectShadowX(vec2 sample_position, vec2 half_size) {
  // Compute the X direction distance field (not incorporating the Y distance)
  // for the rounded rect.
  float space =
      min(0, half_size.y - frag_info.corner_radius - abs(sample_position.y));
  float rrect_distance =
      half_size.x - frag_info.corner_radius +
      sqrt(max(0, frag_info.corner_radius * frag_info.corner_radius -
                      space * space));

  // Map the linear distance field to the approximate Gaussian integral.
  vec2 integral = IPVec2FastGaussianIntegral(
      sample_position.x + vec2(-rrect_distance, rrect_distance),
      frag_info.blur_sigma);
  return integral.y - integral.x;
}

float RRectShadow(vec2 sample_position, vec2 half_size) {
  // Limit the sampling range to 3 standard deviations in the Y direction from
  // the kernel center to incorporate 99.7% of the color contribution.
  float half_sampling_range = frag_info.blur_sigma * 3;

  float begin_y = max(-half_sampling_range, sample_position.y - half_size.y);
  float end_y = min(half_sampling_range, sample_position.y + half_size.y);
  float interval = (end_y - begin_y) / kSampleCount;

  // Sample the X blur kSampleCount times, weighted by the Gaussian function.
  float result = 0;
  for (int sample_i = 0; sample_i < kSampleCount; sample_i++) {
    float y = begin_y + interval * (sample_i + 0.5);
    result += RRectShadowX(vec2(sample_position.x, sample_position.y - y),
                           half_size) *
              IPGaussian(y, frag_info.blur_sigma) * interval;
  }

  return result;
}

void main() {
  frag_color = frag_info.color;

  vec2 half_size = frag_info.rect_size * 0.5;
  vec2 sample_position = v_position - half_size;

  if (frag_info.blur_sigma > 0) {
    frag_color *= RRectShadow(sample_position, half_size);
  } else {
    frag_color *= -RRectDistance(sample_position, half_size);
  }
}
