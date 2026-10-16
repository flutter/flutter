// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Same interface as flutter_gpu_unlit.frag but a different body. Used by
// shader_reload_test.dart to verify reload marks only the changed shader
// dirty.

in vec4 v_color;
out vec4 frag_color;

void main() {
  frag_color = v_color * vec4(0.5, 0.5, 0.5, 1.0);
}
