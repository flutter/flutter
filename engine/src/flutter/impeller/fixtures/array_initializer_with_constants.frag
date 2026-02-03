// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// SkSL does not support array initialization.
float nums[2] = float[](1.0, 0.5);

out vec4 frag_color;

void main() {
  frag_color = vec4(nums[0], nums[1], 1.0, 1.0);
}
