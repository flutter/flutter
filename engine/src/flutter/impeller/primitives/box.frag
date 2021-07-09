// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform FrameInfo {
  float current_time;
} frame;

in vec4 color;
in vec2 interporlated_texture_coordinates;

out vec4 frag_color;

uniform sampler2D contents1_texture;
uniform sampler2D contents2_texture;

void main() {
  vec4 tex1 = texture(contents1_texture, interporlated_texture_coordinates);
  vec4 tex2 = texture(contents2_texture, interporlated_texture_coordinates);
  frag_color = mix(tex1, tex2, frame.current_time - floor(frame.current_time));
}
