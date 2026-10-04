// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// `tex` is sampled then overwritten, so the compiler drops it. Backs the test
// for binding an optimized-out sampler.
uniform sampler2D tex;

in vec4 v_color;
out vec4 frag_color;

void main() {
  frag_color = texture(tex, v_color.xy);
  frag_color = v_color;
}
