// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

in vec4 color;
in vec2 interporlated_texture_coordinates;

out vec4 frag_color;

uniform sampler2D contents_texture;

void main() {
  frag_color = texture(contents_texture, interporlated_texture_coordinates);
}
