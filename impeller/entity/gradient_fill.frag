// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform GradientInfo {
  vec2 start_point;
  vec2 end_point;
  vec4 start_color;
  vec4 end_color;
} gradient_info;

in vec2 interpolated_vertices;

out vec4 frag_color;

void main() {
  float len = length(gradient_info.end_point - gradient_info.start_point);
  float dot = dot(
    interpolated_vertices - gradient_info.start_point,
    gradient_info.end_point - gradient_info.start_point
  );
  float interp = dot / (len * len);
  frag_color = mix(gradient_info.start_color, gradient_info.end_color, interp);
}
