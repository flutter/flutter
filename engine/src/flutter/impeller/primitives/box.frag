// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

in vec4 color;
in vec2 interpolated_texture_coordinates;

uniform sampler2D contents;
// uniform sampler2D texture_sampler2;
// uniform sampler2D texture_sampler3;

out vec4 frag_color;

void main() {
  vec4 color1 = texture(contents, interpolated_texture_coordinates);
  // vec4 color2 = texture(texture_sampler2, interpolated_texture_coordinates);
  // vec4 color3 = texture(texture_sampler3, interpolated_texture_coordinates);
  frag_color = color1;
}
