// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_TXT_FONT_ASSET_PROVIDER_H_
#define FLUTTER_TXT_SRC_TXT_FONT_ASSET_PROVIDER_H_

#include <string>

#include "third_party/skia/include/core/SkFontMgr.h"

namespace txt {

class FontAssetProvider {
 public:
  virtual ~FontAssetProvider() = default;

  virtual size_t GetFamilyCount() const = 0;
  virtual std::string GetFamilyName(int index) const = 0;
  virtual sk_sp<SkFontStyleSet> MatchFamily(const std::string& family_name) = 0;

 protected:
  static std::string CanonicalFamilyName(std::string family_name);
};

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_TXT_FONT_ASSET_PROVIDER_H_
