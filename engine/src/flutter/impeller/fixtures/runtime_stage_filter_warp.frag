// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform sampler2D u_texture;

out vec4 frag_color;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  uv = uv + vec2(0.0, 0.1 * sin(uv.x * 3.14 * 5.0));
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  frag_color = texture(u_texture, uv);
}
