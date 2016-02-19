// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "base/values.h"
#include "base/json/json_reader.h"
#include "services/asset_bundle/zip_asset_bundle.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/platform/fonts/FontData.h"
#include "sky/engine/platform/fonts/FontFaceCreationParams.h"
#include "sky/engine/platform/fonts/SimpleFontData.h"
#include "sky/shell/ui/flutter_font_selector.h"
#include "third_party/skia/include/core/SkStream.h"
#include "third_party/skia/include/core/SkTypeface.h"
#include "third_party/skia/include/ports/SkFontMgr.h"

namespace sky {
namespace shell {

namespace {
const char kFontManifestAssetPath[] = "FontManifest.json";
}

using base::DictionaryValue;
using base::JSONReader;
using base::ListValue;
using base::StringValue;
using base::Value;
using blink::FontCacheKey;
using blink::FontData;
using blink::FontDescription;
using blink::FontFaceCreationParams;
using blink::FontPlatformData;
using blink::SimpleFontData;
using mojo::asset_bundle::ZipAssetBundle;

void FlutterFontSelector::install(
    const scoped_refptr<ZipAssetBundle>& zip_asset_bundle) {
  RefPtr<FlutterFontSelector> font_selector = adoptRef(
      new FlutterFontSelector(zip_asset_bundle));
  font_selector->parseFontManifest();
  blink::DOMDartState::Current()->set_font_selector(font_selector);
}

FlutterFontSelector::FlutterFontSelector(
    const scoped_refptr<ZipAssetBundle>& zip_asset_bundle)
    : zip_asset_bundle_(zip_asset_bundle) {
}

FlutterFontSelector::~FlutterFontSelector() {
}

FlutterFontSelector::TypefaceAsset::TypefaceAsset() {
}

FlutterFontSelector::TypefaceAsset::~TypefaceAsset() {
}

void FlutterFontSelector::parseFontManifest() {
  std::vector<uint8_t> font_manifest_data;
  if (!zip_asset_bundle_->GetAsBuffer(kFontManifestAssetPath,
                                      &font_manifest_data))
    return;

  base::StringPiece font_manifest_str(
      reinterpret_cast<const char*>(font_manifest_data.data()),
      font_manifest_data.size());
  scoped_ptr<Value> font_manifest_json = JSONReader::Read(font_manifest_str);
  if (font_manifest_json == nullptr)
    return;

  ListValue* family_list;
  if (!font_manifest_json->GetAsList(&family_list))
    return;

  for (auto family : *family_list) {
    DictionaryValue* family_dict;
    if (!family->GetAsDictionary(&family_dict))
      continue;
    std::string family_name;
    if (!family_dict->GetString("family", &family_name))
      continue;

    ListValue* font_list;
    if (!family_dict->GetList("fonts", &font_list))
      continue;

    if (font_list->GetSize() != 1) {
      LOG(WARNING) << "Font family " << family_name
                   << " must have exactly one font";
      continue;
    }
    DictionaryValue* font_dict;
    if (!font_list->GetDictionary(0, &font_dict))
      continue;

    std::string asset_path;
    if (!font_dict->GetString("asset", &asset_path))
      continue;

    font_asset_path_map_.set(AtomicString::fromUTF8(family_name.c_str()),
                             AtomicString::fromUTF8(asset_path.c_str()));
  }
}

PassRefPtr<FontData> FlutterFontSelector::getFontData(
    const FontDescription& font_description,
    const AtomicString& family_name) {
  FontFaceCreationParams creationParams(family_name);
  FontCacheKey key = font_description.cacheKey(creationParams);
  RefPtr<SimpleFontData> font_data = font_platform_data_cache_.get(key);

  if (font_data == nullptr) {
    SkTypeface* typeface = getTypefaceAsset(family_name);
    if (typeface == nullptr)
      return nullptr;

    bool synthetic_bold =
        (font_description.weight() >= blink::FontWeight600 && !typeface->isBold()) ||
        font_description.isSyntheticBold();
    bool synthetic_italic =
        (font_description.style() && !typeface->isItalic()) ||
        font_description.isSyntheticItalic();
    FontPlatformData platform_data(
        typeface,
        family_name.utf8().data(),
        font_description.effectiveFontSize(),
        synthetic_bold,
        synthetic_italic,
        font_description.orientation(),
        font_description.useSubpixelPositioning());

    font_data = SimpleFontData::create(platform_data);
    font_platform_data_cache_.set(key, font_data);
  }

  return font_data;
}

SkTypeface* FlutterFontSelector::getTypefaceAsset(
    const AtomicString& family_name) {
  auto it = typeface_cache_.find(family_name);
  if (it != typeface_cache_.end()) {
    const TypefaceAsset* cache_asset = it->value.get();
    return cache_asset ? cache_asset->typeface.get() : nullptr;
  }

  String font_asset_path = font_asset_path_map_.get(family_name);
  if (font_asset_path.isEmpty())
    return nullptr;

  std::unique_ptr<TypefaceAsset> typeface_asset(new TypefaceAsset);
  if (!zip_asset_bundle_->GetAsBuffer(font_asset_path.toUTF8(),
                                      &typeface_asset->data)) {
    typeface_cache_.set(family_name, nullptr);
    return nullptr;
  }

  SkAutoTUnref<SkFontMgr> font_mgr(SkFontMgr::RefDefault());
  SkMemoryStream* typeface_stream = new SkMemoryStream(
      typeface_asset->data.data(), typeface_asset->data.size());
  typeface_asset->typeface = adoptRef(
      font_mgr->createFromStream(typeface_stream));
  if (typeface_asset->typeface == nullptr) {
    typeface_cache_.set(family_name, nullptr);
    return nullptr;
  }

  SkTypeface* result = typeface_asset->typeface.get();
  typeface_cache_.set(family_name, adoptPtr(typeface_asset.release()));
  return result;
}

void FlutterFontSelector::willUseFontData(
    const FontDescription& font_description,
    const AtomicString& family,
    UChar32 character) {
}

unsigned FlutterFontSelector::version() const {
  return 0;
}

void FlutterFontSelector::fontCacheInvalidated() {
}

}  // namespace shell
}  // namespace sky
