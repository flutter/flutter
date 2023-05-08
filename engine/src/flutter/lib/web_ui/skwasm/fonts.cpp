// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "third_party/skia/include/core/SkFontMgr.h"
#include "third_party/skia/modules/skparagraph/include/FontCollection.h"
#include "third_party/skia/modules/skparagraph/include/TypefaceFontProvider.h"

using namespace skia::textlayout;

struct FlutterFontCollection {
  sk_sp<FontCollection> collection;
  sk_sp<TypefaceFontProvider> provider;
};

SKWASM_EXPORT FlutterFontCollection* fontCollection_create() {
  auto collection = sk_make_sp<FontCollection>();
  auto provider = sk_make_sp<TypefaceFontProvider>();
  collection->enableFontFallback();
  collection->setDefaultFontManager(provider);
  return new FlutterFontCollection{
      std::move(collection),
      std::move(provider),
  };
}

SKWASM_EXPORT void fontCollection_dispose(FlutterFontCollection* collection) {
  delete collection;
}

SKWASM_EXPORT bool fontCollection_registerFont(
    FlutterFontCollection* collection,
    SkData* fontData,
    SkString* fontName) {
  fontData->ref();
  auto typeFace =
      SkFontMgr::RefDefault()->makeFromData(sk_sp<SkData>(fontData));
  if (!typeFace) {
    return false;
  }
  if (fontName) {
    SkString alias = *fontName;
    collection->provider->registerTypeface(std::move(typeFace), alias);
  } else {
    collection->provider->registerTypeface(std::move(typeFace));
  }
  return true;
}
