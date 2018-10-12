/*
 * Copyright 2018 Google Inc.
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

#include "txt/typeface_font_asset_provider.h"

#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/skia/include/core/SkTypeface.h"

namespace txt {

TypefaceFontAssetProvider::TypefaceFontAssetProvider() = default;

TypefaceFontAssetProvider::~TypefaceFontAssetProvider() = default;

// |FontAssetProvider|
size_t TypefaceFontAssetProvider::GetFamilyCount() const {
  return family_names_.size();
}

// |FontAssetProvider|
std::string TypefaceFontAssetProvider::GetFamilyName(int index) const {
  return family_names_[index];
}

// |FontAssetProvider|
SkFontStyleSet* TypefaceFontAssetProvider::MatchFamily(
    const std::string& family_name) {
  auto found = registered_families_.find(CanonicalFamilyName(family_name));
  if (found == registered_families_.end()) {
    return nullptr;
  }
  return SkRef(&found->second);
}

void TypefaceFontAssetProvider::RegisterTypeface(sk_sp<SkTypeface> typeface) {
  if (typeface == nullptr) {
    return;
  }

  SkString sk_family_name;
  typeface->getFamilyName(&sk_family_name);

  std::string family_name(sk_family_name.c_str(), sk_family_name.size());
  RegisterTypeface(std::move(typeface), std::move(family_name));
}

void TypefaceFontAssetProvider::RegisterTypeface(
    sk_sp<SkTypeface> typeface,
    std::string family_name_alias) {
  if (family_name_alias.empty()) {
    return;
  }

  std::string canonical_name = CanonicalFamilyName(family_name_alias);
  auto family_it = registered_families_.find(canonical_name);
  if (family_it == registered_families_.end()) {
    family_names_.push_back(family_name_alias);
    family_it = registered_families_
                    .emplace(std::piecewise_construct,
                             std::forward_as_tuple(canonical_name),
                             std::forward_as_tuple())
                    .first;
  }
  family_it->second.registerTypeface(std::move(typeface));
}

TypefaceFontStyleSet::TypefaceFontStyleSet() = default;

TypefaceFontStyleSet::~TypefaceFontStyleSet() = default;

void TypefaceFontStyleSet::registerTypeface(sk_sp<SkTypeface> typeface) {
  if (typeface == nullptr) {
    return;
  }
  typefaces_.emplace_back(std::move(typeface));
}

int TypefaceFontStyleSet::count() {
  return typefaces_.size();
}

void TypefaceFontStyleSet::getStyle(int index, SkFontStyle*, SkString* style) {
  FML_DCHECK(false);
}

SkTypeface* TypefaceFontStyleSet::createTypeface(int i) {
  size_t index = i;
  if (index >= typefaces_.size()) {
    return nullptr;
  }
  return SkRef(typefaces_[index].get());
}

SkTypeface* TypefaceFontStyleSet::matchStyle(const SkFontStyle& pattern) {
  if (typefaces_.empty())
    return nullptr;

  for (const sk_sp<SkTypeface>& typeface : typefaces_)
    if (typeface->fontStyle() == pattern)
      return SkRef(typeface.get());

  return SkRef(typefaces_[0].get());
}

}  // namespace txt
