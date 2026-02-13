// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// If updating this file, also update
// engine/src/flutter/lib/web_ui/test/ui/fragment_shader_test.dart

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform sampler2D u_texture;

out vec4 frag_color;

void main() {
  vec2 tex_coords = FlutterFragCoord().xy / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  tex_coords.y = 1.0 - tex_coords.y;
#endif
  frag_color = texture(u_texture, tex_coords);
}
