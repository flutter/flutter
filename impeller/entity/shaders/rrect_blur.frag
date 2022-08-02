// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform FragInfo {
  vec4 color;
  float blur_radius;
  vec2 rect_size;
  float corner_radius;
}
frag_info;

in vec2 v_position;

out vec4 frag_color;

// Simple logistic sigmoid with a domain of [-1, 1] and range of [0, 1].
float Sigmoid(float x) {
  return 1.03731472073 / (1 + exp(-4 * x)) - 0.0186573603638;
}

float RRectDistance(vec2 sample_position, vec2 rect_size, float corner_radius) {
  vec2 space = abs(sample_position) - rect_size + corner_radius;
  return length(max(space, 0.0)) + min(max(space.x, space.y), 0.0) -
         corner_radius;
}

void main() {
  vec2 center = v_position - frag_info.rect_size / 2.0;
  float dist =
      RRectDistance(center, frag_info.rect_size / 2.0, frag_info.corner_radius);
  float shadow_mask = Sigmoid(-dist / frag_info.blur_radius);
  frag_color = frag_info.color * shadow_mask;
}
