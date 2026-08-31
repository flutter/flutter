// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Fragment shader whose loop SPIRV-Cross cannot fold into a for-increment, so
// it emits a trailing `continue;` in the loop body. See
// flutter/flutter#167850.

uniform UniformBufferObject {
  vec2 size;
}
ubo;

in vec2 v_position;
out vec4 frag_color;

void main() {
  vec2 p = abs(v_position);
  vec2 ab = ubo.size;
  vec2 q = ab * (p - ab);
  float w = (q.x < q.y) ? 1.570796327 : 0.0;
  for (int i = 0; i < 5; i++) {
    vec2 cs = vec2(cos(w), sin(w));
    vec2 u = ab * cs;
    vec2 v = ab * vec2(-cs.y, cs.x);
    w = w + dot(p - u, v) / (dot(p - u, u) + dot(v, v));
  }
  frag_color = vec4(vec3(w), 1.0);
}
