// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
sk_sp<SkFontStyleSet> TypefaceFontAssetProvider::MatchFamily(
    const std::string& family_name) {
  auto found = registered_families_.find(CanonicalFamilyName(family_name));
  if (found == registered_families_.end()) {
    return nullptr;
  }
  return found->second;
}

void TypefaceFontAssetProvider::RegisterTypeface(sk_sp<SkTypeface> typeface) {
  if (typeface == nullptr) {
    return;
  }

  SkString sk_family_name;
  typeface->getFamilyName(&sk_family_name);

  std::string family_name(sk_family_name.c_str(), sk_family_name.size());
  RegisterTypeface(std::move(typeface), family_name);
}

void TypefaceFontAssetProvider::RegisterTypeface(
    sk_sp<SkTypeface> typeface,
    const std::string& family_name_alias) {
  if (family_name_alias.empty()) {
    return;
  }

  std::string canonical_name = CanonicalFamilyName(family_name_alias);
  auto family_it = registered_families_.find(canonical_name);
  if (family_it == registered_families_.end()) {
    family_names_.push_back(family_name_alias);
    auto value =
        std::make_pair(canonical_name, sk_make_sp<TypefaceFontStyleSet>());
    family_it = registered_families_.emplace(value).first;
  }
  family_it->second->registerTypeface(std::move(typeface));
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

void TypefaceFontStyleSet::getStyle(int index,
                                    SkFontStyle* style,
                                    SkString* name) {
  FML_DCHECK(static_cast<size_t>(index) < typefaces_.size());
  if (style) {
    *style = typefaces_[index]->fontStyle();
  }
  if (name) {
    name->reset();
  }
}

sk_sp<SkTypeface> TypefaceFontStyleSet::createTypeface(int i) {
  size_t index = i;
  if (index >= typefaces_.size()) {
    return nullptr;
  }
  return typefaces_[index];
}

sk_sp<SkTypeface> TypefaceFontStyleSet::matchStyle(const SkFontStyle& pattern) {
  return matchStyleCSS3(pattern);
}

}  // namespace txt
