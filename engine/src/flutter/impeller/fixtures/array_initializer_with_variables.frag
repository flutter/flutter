// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

out vec4 frag_color;

void main() {
  float n0 = 1.0;
  float n1 = 0.5;

  // SkSL does not support array initialization.
  float nums[2] = float[](n0, n1);

  frag_color = vec4(nums[0], nums[1], 1.0, 1.0);
}
