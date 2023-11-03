// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/blending.glsl>
#include <impeller/types.glsl>

f16vec3 Blend(f16vec3 dst, f16vec3 src) {
  return IPBlendLighten(dst, src);
}

#include "framebuffer_blend.glsl"
