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

#ifndef TXT_ASSET_DATA_PROVIDER_H_
#define TXT_ASSET_DATA_PROVIDER_H_

#include <string>
#include <unordered_map>
#include "lib/fxl/macros.h"
#include "third_party/skia/include/core/SkTypeface.h"
#include "txt/asset_font_style_set.h"

namespace txt {

class AssetDataProvider {
 public:
  AssetDataProvider();

  virtual ~AssetDataProvider();

  size_t GetFamilyCount() const;

  AssetFontStyleSet* MatchFamily(const std::string& family_name);

  void RegisterTypeface(sk_sp<SkTypeface> typeface);

  void RegisterTypeface(sk_sp<SkTypeface> typeface,
                        std::string family_name_alias);

 private:
  std::unordered_map<std::string, AssetFontStyleSet> registered_families_;

  FXL_DISALLOW_COPY_AND_ASSIGN(AssetDataProvider);
};

}  // namespace txt

#endif  // TXT_ASSET_DATA_PROVIDER_H_
