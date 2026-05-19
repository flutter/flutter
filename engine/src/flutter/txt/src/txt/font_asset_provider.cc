// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <string>

#include "txt/font_asset_provider.h"

namespace txt {

// Return a canonicalized version of a family name that is suitable for
// matching.
std::string FontAssetProvider::CanonicalFamilyName(std::string family_name) {
  std::string result(family_name.length(), 0);

  // Convert ASCII characters to lower case.
  std::transform(family_name.begin(), family_name.end(), result.begin(),
                 [](char c) { return (c & 0x80) ? c : ::tolower(c); });

  return result;
}

}  // namespace txt
