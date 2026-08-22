// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

Texture2D tex;
SamplerState tex_sampler;

float4 FragmentShader(float2 v_texture_coords : TEXCOORD0,
                      float4 v_color : TEXCOORD1) : SV_TARGET {
  return v_color * tex.Sample(tex_sampler, v_texture_coords);
}
