// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Writes the interpolated color to color attachment 0 and its inverse to
// color attachment 1.

in vec4 v_color;

layout(location = 0) out vec4 frag_color0;
layout(location = 1) out vec4 frag_color1;

void main() {
  frag_color0 = v_color;
  frag_color1 = vec4(1.0 - v_color.rgb, 1.0);
}
