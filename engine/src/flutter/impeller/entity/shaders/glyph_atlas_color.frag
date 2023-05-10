// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/types.glsl>

uniform f16sampler2D glyph_atlas_sampler;

uniform FragInfo {
  f16vec4 text_color;
}
frag_info;

in vec2 v_uv;

out f16vec4 frag_color;

void main() {
  f16vec4 value = texture(glyph_atlas_sampler, v_uv);
  frag_color = value * frag_info.text_color.aaaa;
}
