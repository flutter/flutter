// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/branching.glsl>
#include <impeller/color.glsl>
#include <impeller/texture.glsl>

uniform BlendInfo {
  float color_factor;
  vec4 color;  // This color input is expected to be unpremultiplied.
}
blend_info;

uniform sampler2D texture_sampler_dst;
uniform sampler2D texture_sampler_src;

in vec2 v_dst_texture_coords;
in vec2 v_src_texture_coords;

out vec4 frag_color;

void main() {
  vec4 dst = IPUnpremultiply(
      IPSampleClampToBorder(texture_sampler_dst, v_dst_texture_coords));
  vec4 src = blend_info.color_factor > 0
                 ? blend_info.color
                 : IPUnpremultiply(IPSampleClampToBorder(texture_sampler_src,
                                                         v_src_texture_coords));

  vec3 blended = Blend(dst.rgb, src.rgb);

  frag_color = vec4(blended * src.a, src.a);
}
