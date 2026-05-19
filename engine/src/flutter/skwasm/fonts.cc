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

// Calculates the code points that are not covered by the specified typefaces.
// This function mutates the `code_points` buffer in place and returns the count
// of code points that are not covered by the fonts.
SKWASM_EXPORT int typefaces_filterCoveredCodePoints(SkTypeface** typefaces,
                                                    int typeface_count,
                                                    SkUnichar* code_points,
                                                    int code_point_count) {
  std::unique_ptr<SkGlyphID[]> glyph_buffer =
      std::make_unique<SkGlyphID[]>(code_point_count);
  SkGlyphID* glyph_pointer = glyph_buffer.get();
  int remaining_code_point_count = code_point_count;
  for (int typeface_index = 0; typeface_index < typeface_count;
       typeface_index++) {
    typefaces[typeface_index]->unicharsToGlyphs(
        {code_points, remaining_code_point_count},
        {glyph_pointer, remaining_code_point_count});
    int output_index = 0;
    for (int input_index = 0; input_index < remaining_code_point_count;
         input_index++) {
      if (glyph_pointer[input_index] == 0) {
        if (output_index != input_index) {
          code_points[output_index] = code_points[input_index];
        }
        output_index++;
      }
    }
    if (output_index == 0) {
      return 0;
    } else {
      remaining_code_point_count = output_index;
    }
  }
  return remaining_code_point_count;
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
