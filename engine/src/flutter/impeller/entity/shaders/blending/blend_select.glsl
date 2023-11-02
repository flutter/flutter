// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/blending.glsl>
#include <impeller/color.glsl>
#include <impeller/types.glsl>

// kScreen = 0,
// kOverlay,
// kDarken,
// kLighten,
// kColorDodge,
// kColorBurn,
// kHardLight,
// kSoftLight,
// kDifference,
// kExclusion,
// kMultiply,
// kHue,
// kSaturation,
// kColor,
// kLuminosity,
// Note, this isn't a switch as GLSL ES 1.0 does not support them.
#define AdvancedBlend(blend_type)           \
  f16vec3 Blend(f16vec3 dst, f16vec3 src) { \
    if (blend_type == 0) {                  \
      return IPBlendScreen(dst, src);       \
    } else if (blend_type == 1) {           \
      return IPBlendOverlay(dst, src);      \
    } else if (blend_type == 2) {           \
      return IPBlendDarken(dst, src);       \
    } else if (blend_type == 3) {           \
      return IPBlendLighten(dst, src);      \
    } else if (blend_type == 4) {           \
      return IPBlendColorDodge(dst, src);   \
    } else if (blend_type == 5) {           \
      return IPBlendColorBurn(dst, src);    \
    } else if (blend_type == 6) {           \
      return IPBlendHardLight(dst, src);    \
    } else if (blend_type == 7) {           \
      return IPBlendSoftLight(dst, src);    \
    } else if (blend_type == 8) {           \
      return IPBlendDifference(dst, src);   \
    } else if (blend_type == 9) {           \
      return IPBlendExclusion(dst, src);    \
    } else if (blend_type == 10) {          \
      return IPBlendMultiply(dst, src);     \
    } else if (blend_type == 11) {          \
      return IPBlendHue(dst, src);          \
    } else if (blend_type == 12) {          \
      return IPBlendSaturation(dst, src);   \
    } else if (blend_type == 13) {          \
      return IPBlendColor(dst, src);        \
    } else if (blend_type == 14) {          \
      return IPBlendLuminosity(dst, src);   \
    } else {                                \
      return f16vec3(0.0hf);                \
    }                                       \
  }
