// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Declare floats in different order than usage.
uniform float floatA;
uniform float floatB;

out vec4 frag_color;

void main() {
  vec4 sample_1 = vec4(floatB);
  vec4 sample_2 = vec4(floatA);
  frag_color = sample_1 + sample_2;
}
