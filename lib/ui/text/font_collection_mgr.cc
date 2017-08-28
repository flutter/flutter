// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This class creates and holds the txt::FontCollection that contains the
// Default and Custom fonts.

#include "flutter/lib/ui/text/font_collection_mgr.h"

#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"

using tonic::ToDart;

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(ui, FontCollectionMgr);

#define FOR_EACH_BINDING(V)                            \
  V(FontCollectionMgr, initializeFontCollection)       \
  V(FontCollectionMgr, initializeFontCollectionSingle) \
  V(FontCollectionMgr, initializeFontCollectionMultiple)

DART_BIND_ALL(FontCollectionMgr, FOR_EACH_BINDING)

txt::FontCollection* FontCollectionMgr::kFontCollection = nullptr;

void FontCollectionMgr::addFontDir(std::string font_dir) {
  if (kFontCollection == nullptr)
    initializeFontCollection();
  kFontCollection->AddFontMgr(font_dir);
}

void FontCollectionMgr::initializeFontCollection() {
  txt::FontCollection font_collection = txt::FontCollection();
  kFontCollection = &font_collection;
}

void FontCollectionMgr::initializeFontCollectionSingle(std::string font_dir) {
  txt::FontCollection font_collection = txt::FontCollection(font_dir);
  kFontCollection = &font_collection;
}

void FontCollectionMgr::initializeFontCollectionMultiple(
    std::vector<std::string> font_dirs) {
  txt::FontCollection font_collection = txt::FontCollection(font_dirs);
  kFontCollection = &font_collection;
}

}  // namespace blink
