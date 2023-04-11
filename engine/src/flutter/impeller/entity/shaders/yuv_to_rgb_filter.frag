// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/color.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

uniform f16sampler2D y_texture;
uniform f16sampler2D uv_texture;

// These values must correspond to the order of the items in the
// 'YUVColorSpace' enum class.
const float16_t kBT601LimitedRange = 0.0hf;
const float16_t kBT601FullRange = 1.0hf;

uniform FragInfo {
  mat4 matrix;
  float16_t yuv_color_space;
}
frag_info;

in highp vec2 texture_coords;

out f16vec4 frag_color;

void main() {
  f16vec3 yuv;
  f16vec3 yuv_offset = f16vec3(0.0hf, 0.5hf, 0.5hf);
  if (frag_info.yuv_color_space == kBT601LimitedRange) {
    yuv_offset.x = 16.0hf / 255.0hf;
  }

  yuv.x = texture(y_texture, texture_coords).r;
  yuv.yz = texture(uv_texture, texture_coords).rg;
  frag_color = f16mat4(frag_info.matrix) * f16vec4(yuv - yuv_offset, 1.0hf);
}
