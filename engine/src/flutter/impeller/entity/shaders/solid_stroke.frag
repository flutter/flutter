// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

in vec4 stroke_color;
in float v_pen_down;

out vec4 frag_color;

void main() {
  frag_color = stroke_color * floor(v_pen_down);
}
