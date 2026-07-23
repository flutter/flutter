// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Vertex shader with an early return; exercises the y-flip wrap-main
// path. See flutter/flutter#186554.

uniform UniformBufferObject {
  float discard_flag;
}
ubo;

in vec2 inPosition;

void main() {
  if (ubo.discard_flag > 0.5) {
    gl_Position = vec4(0.0);
    return;
  }
  gl_Position = vec4(inPosition, 0.0, 1.0);
}
