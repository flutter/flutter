// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/font_collection.h"

#include <mutex>

#include "flutter/runtime/test_font_data.h"
#include "third_party/rapidjson/rapidjson/document.h"
#include "third_party/rapidjson/rapidjson/rapidjson.h"
#include "third_party/skia/include/core/SkStream.h"
#include "third_party/skia/include/ports/SkFontMgr.h"
#include "txt/asset_font_manager.h"
#include "txt/test_font_manager.h"

namespace blink {

FontCollection& FontCollection::ForProcess() {
  static std::once_flag once = {};
  static FontCollection* gCollection = nullptr;
  std::call_once(once, []() { gCollection = new FontCollection(); });
  return *gCollection;
}

FontCollection::FontCollection()
    : collection_(std::make_shared<txt::FontCollection>()) {
  collection_->PushBack(SkFontMgr::RefDefault());
}

FontCollection::~FontCollection() = default;

std::shared_ptr<txt::FontCollection> FontCollection::GetFontCollection() const {
  return collection_;
}

void FontCollection::RegisterFontsFromAssetProvider(
    fxl::RefPtr<blink::AssetProvider> asset_provider) {

  if (!asset_provider){
    return;
  }

  std::vector<uint8_t> manifest_data;
  if (!asset_provider->GetAsBuffer("FontManifest.json", &manifest_data)) {
    FXL_DLOG(WARNING) << "Could not find the font manifest in the asset store.";
    return;
  }

  rapidjson::Document document;
  static_assert(sizeof(decltype(manifest_data)::value_type) ==
                    sizeof(decltype(document)::Ch),
                "");
  document.Parse(
      reinterpret_cast<decltype(document)::Ch*>(manifest_data.data()),
      manifest_data.size());

  if (document.HasParseError()) {
    FXL_DLOG(WARNING) << "Error parsing the font manifest in the asset store.";
    return;
  }

  // Structure described in https://flutter.io/custom-fonts/

  if (!document.IsArray()) {
    return;
  }

  auto font_asset_data_provider = std::make_unique<txt::AssetDataProvider>();

  for (const auto& family : document.GetArray()) {
    auto family_name = family.FindMember("family");
    if (family_name == family.MemberEnd() || !family_name->value.IsString()) {
      continue;
    }

    auto family_fonts = family.FindMember("fonts");
    if (family_fonts == family.MemberEnd() || !family_fonts->value.IsArray()) {
      continue;
    }

    for (const auto& family_font : family_fonts->value.GetArray()) {
      if (!family_font.IsObject()) {
        continue;
      }

      auto font_asset = family_font.FindMember("asset");
      if (font_asset == family_font.MemberEnd() ||
          !font_asset->value.IsString()) {
        continue;
      }

      // TODO: Handle weights and styles.
      std::vector<uint8_t> font_data;
      if (asset_provider->GetAsBuffer(font_asset->value.GetString(),
                                      &font_data)) {
        // The data must be copied because it needs to be moved into the
        // typeface as a stream.
        auto data =
            SkMemoryStream::MakeCopy(font_data.data(), font_data.size());
        // Ownership of the stream is transferred.
        auto typeface = SkTypeface::MakeFromStream(data.release());
        font_asset_data_provider->RegisterTypeface(
            std::move(typeface), family_name->value.GetString());
      }
    }
  }

  collection_->PushFront(
      sk_make_sp<txt::AssetFontManager>(std::move(font_asset_data_provider)));
}

void FontCollection::RegisterTestFonts() {
  sk_sp<SkTypeface> test_typeface =
      SkTypeface::MakeFromStream(GetTestFontData().release());

  std::unique_ptr<txt::AssetDataProvider> asset_data_provider =
      std::make_unique<txt::AssetDataProvider>();

  asset_data_provider->RegisterTypeface(std::move(test_typeface),
                                        GetTestFontFamilyName());

  collection_->PushFront(sk_make_sp<txt::TestFontManager>(
      std::move(asset_data_provider), GetTestFontFamilyName()));

  collection_->DisableFontFallback();
}

}  // namespace blink
