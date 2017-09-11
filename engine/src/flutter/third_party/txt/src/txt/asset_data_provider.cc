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

#include "txt/asset_data_provider.h"
#include "lib/fxl/logging.h"

namespace txt {

AssetDataProvider::AssetDataProvider() = default;

AssetDataProvider::~AssetDataProvider() = default;

size_t AssetDataProvider::GetFamilyCount() const {
  return registered_families_.size();
}

AssetFontStyleSet* AssetDataProvider::MatchFamily(
    const std::string& family_name) {
  auto found = registered_families_.find(family_name);
  if (found == registered_families_.end()) {
    return nullptr;
  }
  return &found->second;
}

void AssetDataProvider::RegisterTypeface(sk_sp<SkTypeface> typeface) {
  if (typeface == nullptr) {
    return;
  }

  SkString sk_family_name;
  typeface->getFamilyName(&sk_family_name);

  if (sk_family_name.isEmpty()) {
    return;
  }

  std::string family_name(sk_family_name.c_str(), sk_family_name.size());
  RegisterTypeface(std::move(typeface), std::move(family_name));
}

void AssetDataProvider::RegisterTypeface(sk_sp<SkTypeface> typeface,
                                         std::string family_name_alias) {
  registered_families_[std::move(family_name_alias)].registerTypeface(
      std::move(typeface));
}

}  // namespace txt
