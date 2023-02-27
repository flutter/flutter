// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/color.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

uniform sampler2D y_texture;
uniform sampler2D uv_texture;

// These values must correspond to the order of the items in the
// 'YUVColorSpace' enum class.
const float kBT601LimitedRange = 0;
const float kBT601FullRange = 1;

uniform FragInfo {
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

  yuv.x = texture(y_texture, v_position).r;
  yuv.yz = texture(uv_texture, v_position).rg;
  frag_color = frag_info.matrix * vec4(yuv - yuv_offset, 1);
}
