// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform sampler2D u_texture;

out vec4 frag_color;

// Encodes the width of the filter input in the red channel and the x
// coordinate of the fragment within the input in the green channel.
void main() {
  vec4 input_color = texture(u_texture, FlutterFragCoord().xy / u_size);
  frag_color =
      vec4(u_size.x / 255.0, FlutterFragCoord().x / 255.0, 0.0, input_color.a);
}
