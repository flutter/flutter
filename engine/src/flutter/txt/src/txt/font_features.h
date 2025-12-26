// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_TXT_FONT_FEATURES_H_
#define FLUTTER_TXT_SRC_TXT_FONT_FEATURES_H_

#include <map>
#include <string>
#include <vector>

namespace txt {

// Feature tags that can be applied in a text style to control how a font
// selects glyphs.
class FontFeatures {
 public:
  void SetFeature(const std::string& tag, int value);

  std::string GetFeatureSettings() const;

  const std::map<std::string, int>& GetFontFeatures() const;

 private:
  std::map<std::string, int> feature_map_;
};

// Axis tags and values that can be applied in a text style to control the
// attributes of variable fonts.
class FontVariations {
 public:
  void SetAxisValue(const std::string& tag, float value);

  const std::map<std::string, float>& GetAxisValues() const;

 private:
  std::map<std::string, float> axis_map_;
};

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_TXT_FONT_FEATURES_H_
