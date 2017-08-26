/*
 * Copyright (C) 2015 The Android Open Source Project
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

#ifndef MINIKIN_FONT_LANGUAGE_H
#define MINIKIN_FONT_LANGUAGE_H

#include <string>
#include <vector>

#include <hb.h>

namespace minikin {

// Due to the limits in font fallback score calculation, we can't use anything
// more than 12 languages.
const size_t FONT_LANGUAGES_LIMIT = 12;

// The language or region code is encoded to 15 bits.
const uint16_t INVALID_CODE = 0x7fff;

class FontLanguages;

// FontLanguage is a compact representation of a BCP 47 language tag. It
// does not capture all possible information, only what directly affects
// font rendering.
struct FontLanguage {
 public:
  enum EmojiStyle : uint8_t {
    EMSTYLE_EMPTY = 0,
    EMSTYLE_DEFAULT = 1,
    EMSTYLE_EMOJI = 2,
    EMSTYLE_TEXT = 3,
  };
  // Default constructor creates the unsupported language.
  FontLanguage()
      : mScript(0ul),
        mLanguage(INVALID_CODE),
        mRegion(INVALID_CODE),
        mHbLanguage(HB_LANGUAGE_INVALID),
        mSubScriptBits(0ul),
        mEmojiStyle(EMSTYLE_EMPTY) {}

  // Parse from string
  FontLanguage(const char* buf, size_t length);

  bool operator==(const FontLanguage other) const {
    return !isUnsupported() && isEqualScript(other) &&
           mLanguage == other.mLanguage && mRegion == other.mRegion &&
           mEmojiStyle == other.mEmojiStyle;
  }

  bool operator!=(const FontLanguage other) const { return !(*this == other); }

  bool isUnsupported() const { return mLanguage == INVALID_CODE; }
  EmojiStyle getEmojiStyle() const { return mEmojiStyle; }
  hb_language_t getHbLanguage() const { return mHbLanguage; }

  bool isEqualScript(const FontLanguage& other) const;

  // Returns true if this script supports the given script. For example, ja-Jpan
  // supports Hira, ja-Hira doesn't support Jpan.
  bool supportsHbScript(hb_script_t script) const;

  std::string getString() const;

  // Calculates a matching score. This score represents how well the input
  // languages cover this language. The maximum score in the language list is
  // returned. 0 = no match, 1 = script match, 2 = script and primary language
  // match.
  int calcScoreFor(const FontLanguages& supported) const;

  uint64_t getIdentifier() const {
    return ((uint64_t)mLanguage << 49) | ((uint64_t)mScript << 17) |
           ((uint64_t)mRegion << 2) | mEmojiStyle;
  }

 private:
  friend class FontLanguages;  // for FontLanguages constructor

  // ISO 15924 compliant script code. The 4 chars script code are packed into a
  // 32 bit integer.
  uint32_t mScript;

  // ISO 639-1 or ISO 639-2 compliant language code.
  // The two- or three-letter language code is packed into a 15 bit integer.
  // mLanguage = 0 means the FontLanguage is unsupported.
  uint16_t mLanguage;

  // ISO 3166-1 or UN M.49 compliant region code. The two-letter or three-digit
  // region code is packed into a 15 bit integer.
  uint16_t mRegion;

  // The language to be passed HarfBuzz shaper.
  hb_language_t mHbLanguage;

  // For faster comparing, use 7 bits for specific scripts.
  static const uint8_t kBopomofoFlag = 1u;
  static const uint8_t kHanFlag = 1u << 1;
  static const uint8_t kHangulFlag = 1u << 2;
  static const uint8_t kHiraganaFlag = 1u << 3;
  static const uint8_t kKatakanaFlag = 1u << 4;
  static const uint8_t kSimplifiedChineseFlag = 1u << 5;
  static const uint8_t kTraditionalChineseFlag = 1u << 6;
  uint8_t mSubScriptBits;

  EmojiStyle mEmojiStyle;

  static uint8_t scriptToSubScriptBits(uint32_t script);

  static EmojiStyle resolveEmojiStyle(const char* buf,
                                      size_t length,
                                      uint32_t script);

  // Returns true if the provide subscript bits has the requested subscript
  // bits. Note that this function returns false if the requested subscript bits
  // are empty.
  static bool supportsScript(uint8_t providedBits, uint8_t requestedBits);
};

// An immutable list of languages.
class FontLanguages {
 public:
  explicit FontLanguages(std::vector<FontLanguage>&& languages);
  FontLanguages() : mUnionOfSubScriptBits(0), mIsAllTheSameLanguage(false) {}
  FontLanguages(FontLanguages&&) = default;

  size_t size() const { return mLanguages.size(); }
  bool empty() const { return mLanguages.empty(); }
  const FontLanguage& operator[](size_t n) const { return mLanguages[n]; }

 private:
  friend struct FontLanguage;  // for calcScoreFor

  std::vector<FontLanguage> mLanguages;
  uint8_t mUnionOfSubScriptBits;
  bool mIsAllTheSameLanguage;

  uint8_t getUnionOfSubScriptBits() const { return mUnionOfSubScriptBits; }
  bool isAllTheSameLanguage() const { return mIsAllTheSameLanguage; }

  // Do not copy and assign.
  FontLanguages(const FontLanguages&) = delete;
  void operator=(const FontLanguages&) = delete;
};

}  // namespace minikin

#endif  // MINIKIN_FONT_LANGUAGE_H
