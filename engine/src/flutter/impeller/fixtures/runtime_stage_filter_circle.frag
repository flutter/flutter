// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform sampler2D u_texture;

out vec4 frag_color;

vec2 origin = vec2(30.0, 30.0);
float radius = 30.0;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  vec2 fixed_uv = uv;
#ifdef IMPELLER_TARGET_OPENGLES
  fixed_uv.y = 1.0 - fixed_uv.y;
#endif
  vec2 norm_origin = origin / u_size;
  float norm_radius = radius / max(u_size.x, u_size.y);
  if (distance(uv, norm_origin) < norm_radius) {
    frag_color = vec4(1.0, 0.0, 0.0, 1.0);
  } else {
    frag_color = texture(u_texture, fixed_uv);
  }
}
