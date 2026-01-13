// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

out vec4 frag_color;

void main() {
  float nums[2];
  nums[0] = 1.0;
  nums[1] = 0.5;

  float more_nums[2];
  // SkSL does not support array assignment.
  more_nums = nums;

  frag_color = vec4(nums[0], nums[1], 1.0, 1.0);
}
