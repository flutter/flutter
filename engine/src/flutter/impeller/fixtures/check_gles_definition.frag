// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

out vec4 out_color;

void main() {
#ifdef IMPELLER_TARGET_OPENGLES
  fail
#else
  out_color = vec4(1, 0, 0, 0);
#endif
}
