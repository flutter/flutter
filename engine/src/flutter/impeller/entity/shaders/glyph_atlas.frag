// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/types.glsl>

uniform sampler2D glyph_atlas_sampler;

uniform FragInfo {
  vec4 text_color;
}
frag_info;

in vec2 v_uv;
in float v_has_color;

out vec4 frag_color;

void main() {
  vec4 value = texture(glyph_atlas_sampler, v_uv);
  if (v_has_color != 1.0) {
    frag_color = value.aaaa * frag_info.text_color;
  } else {
    frag_color = value * frag_info.text_color.a;
  }
}
