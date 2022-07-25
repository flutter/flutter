// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform GradientInfo {
  vec2 center;
  float radius;
  vec4 center_color;
  vec4 edge_color;
} gradient_info;

in vec2 interpolated_vertices;

out vec4 frag_color;

void main() {
  float len = length(interpolated_vertices - gradient_info.center);
  float t = smoothstep(0.0, gradient_info.radius, len);
  frag_color = mix(gradient_info.center_color, gradient_info.edge_color, t);
}
