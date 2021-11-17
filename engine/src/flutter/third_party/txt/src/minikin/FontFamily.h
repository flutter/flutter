/*
 * Copyright (C) 2013 The Android Open Source Project
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

#ifndef MINIKIN_FONT_FAMILY_H
#define MINIKIN_FONT_FAMILY_H

#include <memory>
#include <string>
#include <unordered_set>
#include <vector>

#include <hb.h>

#include <utils/TypeHelpers.h>

#include <minikin/SparseBitSet.h>

namespace minikin {

class MinikinFont;

// FontStyle represents all style information needed to select an actual font
// from a collection. The implementation is packed into two 32-bit words
// so it can be efficiently copied, embedded in other objects, etc.
class FontStyle {
 public:
  FontStyle()
      : FontStyle(0 /* variant */, 4 /* weight */, false /* italic */) {}
  FontStyle(int weight, bool italic)
      : FontStyle(0 /* variant */, weight, italic) {}
  FontStyle(uint32_t langListId)  // NOLINT(google-explicit-constructor)
      : FontStyle(langListId,
                  0 /* variant */,
                  4 /* weight */,
                  false /* italic */) {}

  FontStyle(int variant, int weight, bool italic);
  FontStyle(uint32_t langListId, int variant, int weight, bool italic);

  int getWeight() const { return bits & kWeightMask; }
  bool getItalic() const { return (bits & kItalicMask) != 0; }
  int getVariant() const { return (bits >> kVariantShift) & kVariantMask; }
  uint32_t getLanguageListId() const { return mLanguageListId; }

  bool operator==(const FontStyle other) const {
    return bits == other.bits && mLanguageListId == other.mLanguageListId;
  }

  android::hash_t hash() const;

  // Looks up a language list from an internal cache and returns its ID.
  // If the passed language list is not in the cache, registers it and returns
  // newly assigned ID.
  static uint32_t registerLanguageList(const std::string& languages);

 private:
  static const uint32_t kWeightMask = (1 << 4) - 1;
  static const uint32_t kItalicMask = 1 << 4;
  static const int kVariantShift = 5;
  static const uint32_t kVariantMask = (1 << 2) - 1;

  static uint32_t pack(int variant, int weight, bool italic);

  uint32_t bits;
  uint32_t mLanguageListId;
};

enum FontVariant {
  VARIANT_DEFAULT = 0,
  VARIANT_COMPACT = 1,
  VARIANT_ELEGANT = 2,
};

inline android::hash_t hash_type(const FontStyle& style) {
  return style.hash();
}

// attributes representing transforms (fake bold, fake italic) to match styles
class FontFakery {
 public:
  FontFakery() : mFakeBold(false), mFakeItalic(false) {}
  FontFakery(bool fakeBold, bool fakeItalic)
      : mFakeBold(fakeBold), mFakeItalic(fakeItalic) {}
  // TODO: want to support graded fake bolding
  bool isFakeBold() { return mFakeBold; }
  bool isFakeItalic() { return mFakeItalic; }

 private:
  bool mFakeBold;
  bool mFakeItalic;
};

struct FakedFont {
  // ownership is the enclosing FontCollection
  MinikinFont* font;
  FontFakery fakery;
};

typedef uint32_t AxisTag;

struct Font {
  Font(const std::shared_ptr<MinikinFont>& typeface, FontStyle style);
  Font(std::shared_ptr<MinikinFont>&& typeface, FontStyle style);
  Font(Font&& o);
  Font(const Font& o);

  std::shared_ptr<MinikinFont> typeface;
  FontStyle style;

  std::unordered_set<AxisTag> getSupportedAxesLocked() const;
};

struct FontVariation {
  FontVariation(AxisTag axisTag, float value)
      : axisTag(axisTag), value(value) {}
  AxisTag axisTag;
  float value;
};

class FontFamily {
 public:
  explicit FontFamily(std::vector<Font>&& fonts);
  FontFamily(int variant, std::vector<Font>&& fonts);
  FontFamily(uint32_t langId, int variant, std::vector<Font>&& fonts);

  // TODO: Good to expose FontUtil.h.
  static bool analyzeStyle(const std::shared_ptr<MinikinFont>& typeface,
                           int* weight,
                           bool* italic);
  FakedFont getClosestMatch(FontStyle style) const;

  uint32_t langId() const { return mLangId; }
  int variant() const { return mVariant; }

  // API's for enumerating the fonts in a family. These don't guarantee any
  // particular order
  size_t getNumFonts() const { return mFonts.size(); }
  const std::shared_ptr<MinikinFont>& getFont(size_t index) const {
    return mFonts[index].typeface;
  }
  FontStyle getStyle(size_t index) const { return mFonts[index].style; }
  bool isColorEmojiFamily() const;
  const std::unordered_set<AxisTag>& supportedAxes() const {
    return mSupportedAxes;
  }

  // Get Unicode coverage.
  const SparseBitSet& getCoverage() const { return mCoverage; }

  // Returns true if the font has a glyph for the code point and variation
  // selector pair. Caller should acquire a lock before calling the method.
  bool hasGlyph(uint32_t codepoint, uint32_t variationSelector) const;

  // Returns true if this font family has a variaion sequence table (cmap format
  // 14 subtable).
  bool hasVSTable() const { return mHasVSTable; }

  // Creates new FontFamily based on this family while applying font variations.
  // Returns nullptr if none of variations apply to this family.
  std::shared_ptr<FontFamily> createFamilyWithVariation(
      const std::vector<FontVariation>& variations) const;

 private:
  void computeCoverage();

  uint32_t mLangId;
  int mVariant;
  std::vector<Font> mFonts;
  std::unordered_set<AxisTag> mSupportedAxes;

  SparseBitSet mCoverage;
  bool mHasVSTable;

  // Forbid copying and assignment.
  FontFamily(const FontFamily&) = delete;
  void operator=(const FontFamily&) = delete;
};

}  // namespace minikin

#endif  // MINIKIN_FONT_FAMILY_H
