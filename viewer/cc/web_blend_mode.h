// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_BLEND_MODE_H_
#define SKY_VIEWER_CC_WEB_BLEND_MODE_H_

#include "sky/engine/public/platform/WebBlendMode.h"
#include "third_party/skia/include/core/SkXfermode.h"

namespace sky_viewer_cc {

inline SkXfermode::Mode BlendModeToSkia(blink::WebBlendMode blend_mode) {
  switch (blend_mode) {
    case blink::WebBlendModeNormal:
      return SkXfermode::kSrcOver_Mode;
    case blink::WebBlendModeMultiply:
      return SkXfermode::kMultiply_Mode;
    case blink::WebBlendModeScreen:
      return SkXfermode::kScreen_Mode;
    case blink::WebBlendModeOverlay:
      return SkXfermode::kOverlay_Mode;
    case blink::WebBlendModeDarken:
      return SkXfermode::kDarken_Mode;
    case blink::WebBlendModeLighten:
      return SkXfermode::kLighten_Mode;
    case blink::WebBlendModeColorDodge:
      return SkXfermode::kColorDodge_Mode;
    case blink::WebBlendModeColorBurn:
      return SkXfermode::kColorBurn_Mode;
    case blink::WebBlendModeHardLight:
      return SkXfermode::kHardLight_Mode;
    case blink::WebBlendModeSoftLight:
      return SkXfermode::kSoftLight_Mode;
    case blink::WebBlendModeDifference:
      return SkXfermode::kDifference_Mode;
    case blink::WebBlendModeExclusion:
      return SkXfermode::kExclusion_Mode;
    case blink::WebBlendModeHue:
      return SkXfermode::kHue_Mode;
    case blink::WebBlendModeSaturation:
      return SkXfermode::kSaturation_Mode;
    case blink::WebBlendModeColor:
      return SkXfermode::kColor_Mode;
    case blink::WebBlendModeLuminosity:
      return SkXfermode::kLuminosity_Mode;
  }
  return SkXfermode::kSrcOver_Mode;
}

inline blink::WebBlendMode BlendModeFromSkia(SkXfermode::Mode blend_mode) {
  switch (blend_mode) {
    case SkXfermode::kSrcOver_Mode:
      return blink::WebBlendModeNormal;
    case SkXfermode::kMultiply_Mode:
      return blink::WebBlendModeMultiply;
    case SkXfermode::kScreen_Mode:
      return blink::WebBlendModeScreen;
    case SkXfermode::kOverlay_Mode:
      return blink::WebBlendModeOverlay;
    case SkXfermode::kDarken_Mode:
      return blink::WebBlendModeDarken;
    case SkXfermode::kLighten_Mode:
      return blink::WebBlendModeLighten;
    case SkXfermode::kColorDodge_Mode:
      return blink::WebBlendModeColorDodge;
    case SkXfermode::kColorBurn_Mode:
      return blink::WebBlendModeColorBurn;
    case SkXfermode::kHardLight_Mode:
      return blink::WebBlendModeHardLight;
    case SkXfermode::kSoftLight_Mode:
      return blink::WebBlendModeSoftLight;
    case SkXfermode::kDifference_Mode:
      return blink::WebBlendModeDifference;
    case SkXfermode::kExclusion_Mode:
      return blink::WebBlendModeExclusion;
    case SkXfermode::kHue_Mode:
      return blink::WebBlendModeHue;
    case SkXfermode::kSaturation_Mode:
      return blink::WebBlendModeSaturation;
    case SkXfermode::kColor_Mode:
      return blink::WebBlendModeColor;
    case SkXfermode::kLuminosity_Mode:
      return blink::WebBlendModeLuminosity;

    // these value are SkXfermodes, but no blend modes.
    case SkXfermode::kClear_Mode:
    case SkXfermode::kSrc_Mode:
    case SkXfermode::kDst_Mode:
    case SkXfermode::kDstOver_Mode:
    case SkXfermode::kSrcIn_Mode:
    case SkXfermode::kDstIn_Mode:
    case SkXfermode::kSrcOut_Mode:
    case SkXfermode::kDstOut_Mode:
    case SkXfermode::kSrcATop_Mode:
    case SkXfermode::kDstATop_Mode:
    case SkXfermode::kXor_Mode:
    case SkXfermode::kPlus_Mode:
    case SkXfermode::kModulate_Mode:
      NOTREACHED();
  }
  return blink::WebBlendModeNormal;
}

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_BLEND_MODE_H_
