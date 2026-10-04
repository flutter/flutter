// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

out vec4 frag_color;

void main() {
  // Valid SkSL to initialize and set constant values for an array.
  float nums[2];
  nums[0] = 1.0;
  nums[1] = 0.5;

  // Valid SkSL to set a value of an array to a variable.
  float num1 = 0.0;
  nums[1] = num1;

  frag_color = vec4(nums[0], nums[1], 1.0, 1.0);
}
