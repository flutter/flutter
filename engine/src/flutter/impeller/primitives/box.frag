// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

in vec4 color;
in vec2 interpolated_texture_coordinates;

uniform sampler2D contents1;
uniform sampler2D contents2;
uniform sampler2D contents3;

out vec4 frag_color;

void main() {
  vec4 color1 = texture(contents1, interpolated_texture_coordinates);
  vec4 color2 = texture(contents2, interpolated_texture_coordinates);
  vec4 color3 = texture(contents3, interpolated_texture_coordinates);
  frag_color = color3;
}
