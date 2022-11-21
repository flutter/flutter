// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/color.glsl>
#include <impeller/texture.glsl>

uniform sampler2D y_texture;
uniform sampler2D uv_texture;

// These values must correspond to the order of the items in the
// 'YUVColorSpace' enum class.
const float kBT601LimitedRange = 0;
const float kBT601FullRange = 1;

uniform FragInfo {
  float texture_sampler_y_coord_scale;
  mat4 matrix;
  float yuv_color_space;
}
frag_info;

in vec2 v_position;
out vec4 frag_color;

void main() {
  vec3 yuv;
  vec3 yuv_offset = vec3(0.0, 0.5, 0.5);
  if (frag_info.yuv_color_space == kBT601LimitedRange) {
    yuv_offset.x = 16.0 / 255.0;
  }

  yuv.x =
      IPSample(y_texture, v_position, frag_info.texture_sampler_y_coord_scale)
          .r;
  yuv.yz =
      IPSample(uv_texture, v_position, frag_info.texture_sampler_y_coord_scale)
          .rg;
  frag_color = frag_info.matrix * vec4(yuv - yuv_offset, 1);
}
