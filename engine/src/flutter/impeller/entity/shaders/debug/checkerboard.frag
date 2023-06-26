// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

uniform FragInfo {
  vec4 color;
  float square_size;
}
frag_info;

out vec4 frag_color;

void main() {
  vec2 square = floor(gl_FragCoord.xy / frag_info.square_size);
  frag_color = mod(square.x + square.y, 2.0) * frag_info.color;
}
