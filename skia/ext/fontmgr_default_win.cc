// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/fontmgr_default_win.h"

#include "third_party/skia/include/ports/SkFontMgr.h"
#include "third_party/skia/include/ports/SkTypeface_win.h"

namespace {

SkFontMgr* g_default_fontmgr;

}  // namespace

void SetDefaultSkiaFactory(SkFontMgr* fontmgr) {
  g_default_fontmgr = fontmgr;
}

SK_API SkFontMgr* SkFontMgr::Factory() {
  // This will be set when DirectWrite is in use, and an SkFontMgr has been
  // created with the pre-sandbox warmed up one. Otherwise, we fallback to a
  // GDI SkFontMgr which is used in the browser.
  if (g_default_fontmgr)
    return SkRef(g_default_fontmgr);
  return SkFontMgr_New_GDI();
}
