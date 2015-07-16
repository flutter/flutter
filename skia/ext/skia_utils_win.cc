// Copyright (c) 2006-2008 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/skia_utils_win.h"

#include <stddef.h>
#include <windows.h>

#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkTypes.h"
#include "third_party/skia/include/effects/SkGradientShader.h"

namespace {

SK_COMPILE_ASSERT(offsetof(RECT, left) == offsetof(SkIRect, fLeft), o1);
SK_COMPILE_ASSERT(offsetof(RECT, top) == offsetof(SkIRect, fTop), o2);
SK_COMPILE_ASSERT(offsetof(RECT, right) == offsetof(SkIRect, fRight), o3);
SK_COMPILE_ASSERT(offsetof(RECT, bottom) == offsetof(SkIRect, fBottom), o4);
SK_COMPILE_ASSERT(sizeof(RECT().left) == sizeof(SkIRect().fLeft), o5);
SK_COMPILE_ASSERT(sizeof(RECT().top) == sizeof(SkIRect().fTop), o6);
SK_COMPILE_ASSERT(sizeof(RECT().right) == sizeof(SkIRect().fRight), o7);
SK_COMPILE_ASSERT(sizeof(RECT().bottom) == sizeof(SkIRect().fBottom), o8);
SK_COMPILE_ASSERT(sizeof(RECT) == sizeof(SkIRect), o9);

}  // namespace

namespace skia {

POINT SkPointToPOINT(const SkPoint& point) {
  POINT win_point = {
      SkScalarRoundToInt(point.fX), SkScalarRoundToInt(point.fY)
  };
  return win_point;
}

SkRect RECTToSkRect(const RECT& rect) {
  SkRect sk_rect = { SkIntToScalar(rect.left), SkIntToScalar(rect.top),
                     SkIntToScalar(rect.right), SkIntToScalar(rect.bottom) };
  return sk_rect;
}

SkColor COLORREFToSkColor(COLORREF color) {
#ifndef _MSC_VER
  return SkColorSetRGB(GetRValue(color), GetGValue(color), GetBValue(color));
#else
  // ARGB = 0xFF000000 | ((0BGR -> RGB0) >> 8)
  return 0xFF000000u | (_byteswap_ulong(color) >> 8);
#endif
}

COLORREF SkColorToCOLORREF(SkColor color) {
#ifndef _MSC_VER
  return RGB(SkColorGetR(color), SkColorGetG(color), SkColorGetB(color));
#else
  // 0BGR = ((ARGB -> BGRA) >> 8)
  return (_byteswap_ulong(color) >> 8);
#endif
}

}  // namespace skia

