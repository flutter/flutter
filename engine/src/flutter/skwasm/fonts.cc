// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/skwasm/export.h"
#include "flutter/skwasm/live_objects.h"
#include "flutter/skwasm/wrappers.h"
#include "third_party/skia/include/core/SkFontMgr.h"
#include "third_party/skia/include/ports/SkFontMgr_empty.h"
#include "third_party/skia/modules/skparagraph/include/FontCollection.h"
#include "third_party/skia/modules/skparagraph/include/TypefaceFontProvider.h"

SKWASM_EXPORT Skwasm::FlutterFontCollection* fontCollection_create() {
  Skwasm::live_font_collection_count++;
  auto collection = sk_make_sp<skia::textlayout::FontCollection>();
  auto provider = sk_make_sp<skia::textlayout::TypefaceFontProvider>();
  collection->enableFontFallback();
  collection->setDefaultFontManager(provider, "Roboto");
  return new Skwasm::FlutterFontCollection{
      std::move(collection),
      std::move(provider),
  };
}

SKWASM_EXPORT void fontCollection_dispose(
    Skwasm::FlutterFontCollection* collection) {
  Skwasm::live_font_collection_count--;
  delete collection;
}

static sk_sp<SkFontMgr> default_fontmgr() {
  static sk_sp<SkFontMgr> mgr = SkFontMgr_New_Custom_Empty();
  return mgr;
}

SKWASM_EXPORT SkTypeface* typeface_create(SkData* font_data) {
  Skwasm::live_typeface_count++;
  auto typeface = default_fontmgr()->makeFromData(sk_ref_sp<SkData>(font_data));
  return typeface.release();
}

SKWASM_EXPORT void typeface_dispose(SkTypeface* typeface) {
  Skwasm::live_typeface_count--;
  typeface->unref();
}

SKWASM_EXPORT void fontCollection_registerTypeface(
    Skwasm::FlutterFontCollection* collection,
    SkTypeface* typeface,
    SkString* font_name) {
  if (font_name) {
    SkString alias = *font_name;
    collection->provider->registerTypeface(sk_ref_sp<SkTypeface>(typeface),
                                           alias);
  } else {
    collection->provider->registerTypeface(sk_ref_sp<SkTypeface>(typeface));
  }
}

SKWASM_EXPORT void fontCollection_clearCaches(
    Skwasm::FlutterFontCollection* collection) {
  collection->collection->clearCaches();
}
