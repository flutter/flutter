/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "txt/asset_font_manager.h"
#include "lib/fxl/logging.h"

namespace txt {

AssetFontManager::AssetFontManager(
    std::unique_ptr<AssetDataProvider> data_provider)
    : data_provider_(std::move(data_provider)) {
  FXL_DCHECK(data_provider_ != nullptr);
}

AssetFontManager::~AssetFontManager() = default;

int AssetFontManager::onCountFamilies() const {
  return data_provider_->GetFamilyCount();
}

void AssetFontManager::onGetFamilyName(int index, SkString* familyName) const {
  FXL_DCHECK(false);
}

SkFontStyleSet* AssetFontManager::onCreateStyleSet(int index) const {
  FXL_DCHECK(false);
  return nullptr;
}

SkFontStyleSet* AssetFontManager::onMatchFamily(
    const char family_name_string[]) const {
  std::string family_name(family_name_string);
  return data_provider_->MatchFamily(family_name);
}

SkTypeface* AssetFontManager::onMatchFamilyStyle(const char familyName[],
                                                 const SkFontStyle&) const {
  FXL_DCHECK(false);
  return nullptr;
}

SkTypeface* AssetFontManager::onMatchFamilyStyleCharacter(
    const char familyName[],
    const SkFontStyle&,
    const char* bcp47[],
    int bcp47Count,
    SkUnichar character) const {
  return nullptr;
}

SkTypeface* AssetFontManager::onMatchFaceStyle(const SkTypeface*,
                                               const SkFontStyle&) const {
  FXL_DCHECK(false);
  return nullptr;
}

SkTypeface* AssetFontManager::onCreateFromData(SkData*, int ttcIndex) const {
  FXL_DCHECK(false);
  return nullptr;
}

SkTypeface* AssetFontManager::onCreateFromStream(SkStreamAsset*,
                                                 int ttcIndex) const {
  FXL_DCHECK(false);
  return nullptr;
}

SkTypeface* AssetFontManager::onCreateFromStream(SkStreamAsset*,
                                                 const SkFontArguments&) const {
  FXL_DCHECK(false);
  return nullptr;
}

SkTypeface* AssetFontManager::onCreateFromFile(const char path[],
                                               int ttcIndex) const {
  FXL_DCHECK(false);
  return nullptr;
}

SkTypeface* AssetFontManager::onLegacyCreateTypeface(const char familyName[],
                                                     SkFontStyle) const {
  FXL_DCHECK(false);
  return nullptr;
}

}  // namespace txt
