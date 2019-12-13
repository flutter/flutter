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

// #define VERBOSE_DEBUG

#define LOG_TAG "Minikin"

#include <algorithm>

#include <log/log.h>
#include "unicode/unistr.h"
#include "unicode/unorm2.h"
#include "unicode/utf16.h"

#include <minikin/Emoji.h>
#include <minikin/FontCollection.h>
#include "FontLanguage.h"
#include "FontLanguageListCache.h"
#include "MinikinInternal.h"

using std::vector;

namespace minikin {

template <typename T>
static inline T max(T a, T b) {
  return a > b ? a : b;
}

const uint32_t EMOJI_STYLE_VS = 0xFE0F;
const uint32_t TEXT_STYLE_VS = 0xFE0E;

uint32_t FontCollection::sNextId = 0;

// libtxt: return a locale string for a language list ID
std::string GetFontLocale(uint32_t langListId) {
  const FontLanguages& langs = FontLanguageListCache::getById(langListId);
  return langs.size() ? langs[0].getString() : "";
}

FontCollection::FontCollection(std::shared_ptr<FontFamily>&& typeface)
    : mMaxChar(0) {
  std::vector<std::shared_ptr<FontFamily>> typefaces;
  typefaces.push_back(typeface);
  init(typefaces);
}

FontCollection::FontCollection(
    const vector<std::shared_ptr<FontFamily>>& typefaces)
    : mMaxChar(0) {
  init(typefaces);
}

void FontCollection::init(
    const vector<std::shared_ptr<FontFamily>>& typefaces) {
  std::scoped_lock _l(gMinikinLock);
  mId = sNextId++;
  vector<uint32_t> lastChar;
  size_t nTypefaces = typefaces.size();
#ifdef VERBOSE_DEBUG
  ALOGD("nTypefaces = %zd\n", nTypefaces);
#endif
  const FontStyle defaultStyle;
  for (size_t i = 0; i < nTypefaces; i++) {
    const std::shared_ptr<FontFamily>& family = typefaces[i];
    if (family->getClosestMatch(defaultStyle).font == nullptr) {
      continue;
    }
    const SparseBitSet& coverage = family->getCoverage();
    mFamilies.push_back(family);  // emplace_back would be better
    if (family->hasVSTable()) {
      mVSFamilyVec.push_back(family);
    }
    mMaxChar = max(mMaxChar, coverage.length());
    lastChar.push_back(coverage.nextSetBit(0));

    const std::unordered_set<AxisTag>& supportedAxes = family->supportedAxes();
    mSupportedAxes.insert(supportedAxes.begin(), supportedAxes.end());
  }
  nTypefaces = mFamilies.size();
  LOG_ALWAYS_FATAL_IF(nTypefaces == 0,
                      "Font collection must have at least one valid typeface");
  LOG_ALWAYS_FATAL_IF(nTypefaces > 254,
                      "Font collection may only have up to 254 font families.");
  size_t nPages = (mMaxChar + kPageMask) >> kLogCharsPerPage;
  // TODO: Use variation selector map for mRanges construction.
  // A font can have a glyph for a base code point and variation selector pair
  // but no glyph for the base code point without variation selector. The family
  // won't be listed in the range in this case.
  for (size_t i = 0; i < nPages; i++) {
    Range dummy;
    mRanges.push_back(dummy);
    Range* range = &mRanges.back();
#ifdef VERBOSE_DEBUG
    ALOGD("i=%zd: range start = %zd\n", i, offset);
#endif
    range->start = mFamilyVec.size();
    for (size_t j = 0; j < nTypefaces; j++) {
      if (lastChar[j] < (i + 1) << kLogCharsPerPage) {
        const std::shared_ptr<FontFamily>& family = mFamilies[j];
        mFamilyVec.push_back(static_cast<uint8_t>(j));
        uint32_t nextChar =
            family->getCoverage().nextSetBit((i + 1) << kLogCharsPerPage);
#ifdef VERBOSE_DEBUG
        ALOGD("nextChar = %d (j = %zd)\n", nextChar, j);
#endif
        lastChar[j] = nextChar;
      }
    }
    range->end = mFamilyVec.size();
  }
  // See the comment in Range for more details.
  LOG_ALWAYS_FATAL_IF(mFamilyVec.size() >= 0xFFFF,
                      "Exceeded the maximum indexable cmap coverage.");
}

// Special scores for the font fallback.
const uint32_t kUnsupportedFontScore = 0;
const uint32_t kFirstFontScore = UINT32_MAX;

// Calculates a font score.
// The score of the font family is based on three subscores.
//  - Coverage Score: How well the font family covers the given character or
//  variation sequence.
//  - Language Score: How well the font family is appropriate for the language.
//  - Variant Score: Whether the font family matches the variant. Note that this
//  variant is not the
//    one in BCP47. This is our own font variant (e.g., elegant, compact).
//
// Then, there is a priority for these three subscores as follow:
//   Coverage Score > Language Score > Variant Score
// The returned score reflects this priority order.
//
// Note that there are two special scores.
//  - kUnsupportedFontScore: When the font family doesn't support the variation
//  sequence or even its
//    base character.
//  - kFirstFontScore: When the font is the first font family in the collection
//  and it supports the
//    given character or variation sequence.
uint32_t FontCollection::calcFamilyScore(
    uint32_t ch,
    uint32_t vs,
    int variant,
    uint32_t langListId,
    const std::shared_ptr<FontFamily>& fontFamily) const {
  const uint32_t coverageScore = calcCoverageScore(ch, vs, fontFamily);
  if (coverageScore == kFirstFontScore ||
      coverageScore == kUnsupportedFontScore) {
    // No need to calculate other scores.
    return coverageScore;
  }

  const uint32_t languageScore =
      calcLanguageMatchingScore(langListId, *fontFamily);
  const uint32_t variantScore = calcVariantMatchingScore(variant, *fontFamily);

  // Subscores are encoded into 31 bits representation to meet the subscore
  // priority. The highest 2 bits are for coverage score, then following 28 bits
  // are for language score, then the last 1 bit is for variant score.
  return coverageScore << 29 | languageScore << 1 | variantScore;
}

// Calculates a font score based on variation sequence coverage.
// - Returns kUnsupportedFontScore if the font doesn't support the variation
// sequence or its base
//   character.
// - Returns kFirstFontScore if the font family is the first font family in the
// collection and it
//   supports the given character or variation sequence.
// - Returns 3 if the font family supports the variation sequence.
// - Returns 2 if the vs is a color variation selector (U+FE0F) and if the font
// is an emoji font.
// - Returns 2 if the vs is a text variation selector (U+FE0E) and if the font
// is not an emoji font.
// - Returns 1 if the variation selector is not specified or if the font family
// only supports the
//   variation sequence's base character.
uint32_t FontCollection::calcCoverageScore(
    uint32_t ch,
    uint32_t vs,
    const std::shared_ptr<FontFamily>& fontFamily) const {
  const bool hasVSGlyph = (vs != 0) && fontFamily->hasGlyph(ch, vs);
  if (!hasVSGlyph && !fontFamily->getCoverage().get(ch)) {
    // The font doesn't support either variation sequence or even the base
    // character.
    return kUnsupportedFontScore;
  }

  if ((vs == 0 || hasVSGlyph) && mFamilies[0] == fontFamily) {
    // If the first font family supports the given character or variation
    // sequence, always use it.
    return kFirstFontScore;
  }

  if (vs == 0) {
    return 1;
  }

  if (hasVSGlyph) {
    return 3;
  }

  if (vs == EMOJI_STYLE_VS || vs == TEXT_STYLE_VS) {
    const FontLanguages& langs =
        FontLanguageListCache::getById(fontFamily->langId());
    bool hasEmojiFlag = false;
    for (size_t i = 0; i < langs.size(); ++i) {
      if (langs[i].getEmojiStyle() == FontLanguage::EMSTYLE_EMOJI) {
        hasEmojiFlag = true;
        break;
      }
    }

    if (vs == EMOJI_STYLE_VS) {
      return hasEmojiFlag ? 2 : 1;
    } else {  // vs == TEXT_STYLE_VS
      return hasEmojiFlag ? 1 : 2;
    }
  }
  return 1;
}

// Calculate font scores based on the script matching, subtag matching and
// primary language matching.
//
// 1. If only the font's language matches or there is no matches between
// requested font and
//    supported font, then the font obtains a score of 0.
// 2. Without a match in language, considering subtag may change font's
// EmojiStyle over script,
//    a match in subtag gets a score of 2 and a match in scripts gains a score
//    of 1.
// 3. Regarding to two elements matchings, language-and-subtag matching has a
// score of 4, while
//    language-and-script obtains a socre of 3 with the same reason above.
//
// If two languages in the requested list have the same language score, the font
// matching with higher priority language gets a higher score. For example, in
// the case the user requested language list is "ja-Jpan,en-Latn". The score of
// for the font of "ja-Jpan" gets a higher score than the font of "en-Latn".
//
// To achieve score calculation with priorities, the language score is
// determined as follows:
//   LanguageScore = s(0) * 5^(m - 1) + s(1) * 5^(m - 2) + ... + s(m - 2) * 5 +
//   s(m - 1)
// Here, m is the maximum number of languages to be compared, and s(i) is the
// i-th language's matching score. The possible values of s(i) are 0, 1, 2, 3
// and 4.
uint32_t FontCollection::calcLanguageMatchingScore(
    uint32_t userLangListId,
    const FontFamily& fontFamily) {
  const FontLanguages& langList =
      FontLanguageListCache::getById(userLangListId);
  const FontLanguages& fontLanguages =
      FontLanguageListCache::getById(fontFamily.langId());

  const size_t maxCompareNum = std::min(langList.size(), FONT_LANGUAGES_LIMIT);
  uint32_t score = 0;
  for (size_t i = 0; i < maxCompareNum; ++i) {
    score = score * 5u + langList[i].calcScoreFor(fontLanguages);
  }
  return score;
}

// Calculates a font score based on variant ("compact" or "elegant") matching.
//  - Returns 1 if the font doesn't have variant or the variant matches with the
//  text style.
//  - No score if the font has a variant but it doesn't match with the text
//  style.
uint32_t FontCollection::calcVariantMatchingScore(
    int variant,
    const FontFamily& fontFamily) {
  return (fontFamily.variant() == 0 || fontFamily.variant() == variant) ? 1 : 0;
}

// Implement heuristic for choosing best-match font. Here are the rules:
// 1. If first font in the collection has the character, it wins.
// 2. Calculate a score for the font family. See comments in calcFamilyScore for
// the detail.
// 3. Highest score wins, with ties resolved to the first font.
// This method never returns nullptr.
const std::shared_ptr<FontFamily>& FontCollection::getFamilyForChar(
    uint32_t ch,
    uint32_t vs,
    uint32_t langListId,
    int variant) const {
  if (ch >= mMaxChar) {
    // libtxt: check if the fallback font provider can match this character
    if (mFallbackFontProvider) {
      const std::shared_ptr<FontFamily>& fallback =
          findFallbackFont(ch, vs, langListId);
      if (fallback) {
        return fallback;
      }
    }
    return mFamilies[0];
  }

  Range range = mRanges[ch >> kLogCharsPerPage];

  if (vs != 0) {
    range = {0, static_cast<uint16_t>(mFamilies.size())};
  }

#ifdef VERBOSE_DEBUG
  ALOGD("querying range %zd:%zd\n", range.start, range.end);
#endif
  int bestFamilyIndex = -1;
  uint32_t bestScore = kUnsupportedFontScore;
  for (size_t i = range.start; i < range.end; i++) {
    const std::shared_ptr<FontFamily>& family =
        vs == 0 ? mFamilies[mFamilyVec[i]] : mFamilies[i];
    const uint32_t score = calcFamilyScore(ch, vs, variant, langListId, family);
    if (score == kFirstFontScore) {
      // If the first font family supports the given character or variation
      // sequence, always use it.
      return family;
    }
    if (score > bestScore) {
      bestScore = score;
      bestFamilyIndex = i;
    }
  }
  if (bestFamilyIndex == -1) {
    // libtxt: check if the fallback font provider can match this character
    if (mFallbackFontProvider) {
      const std::shared_ptr<FontFamily>& fallback =
          findFallbackFont(ch, vs, langListId);
      if (fallback) {
        return fallback;
      }
    }

    UErrorCode errorCode = U_ZERO_ERROR;
    const UNormalizer2* normalizer = unorm2_getNFDInstance(&errorCode);
    if (U_SUCCESS(errorCode)) {
      UChar decomposed[4];
      int len =
          unorm2_getRawDecomposition(normalizer, ch, decomposed, 4, &errorCode);
      if (U_SUCCESS(errorCode) && len > 0) {
        int off = 0;
        U16_NEXT_UNSAFE(decomposed, off, ch);
        return getFamilyForChar(ch, vs, langListId, variant);
      }
    }
    return mFamilies[0];
  }
  return vs == 0 ? mFamilies[mFamilyVec[bestFamilyIndex]]
                 : mFamilies[bestFamilyIndex];
}

const std::shared_ptr<FontFamily>& FontCollection::findFallbackFont(
    uint32_t ch,
    uint32_t vs,
    uint32_t langListId) const {
  std::string locale = GetFontLocale(langListId);

  const auto it = mCachedFallbackFamilies.find(locale);
  if (it != mCachedFallbackFamilies.end()) {
    for (const auto& fallbackFamily : it->second) {
      if (calcCoverageScore(ch, vs, fallbackFamily)) {
        return fallbackFamily;
      }
    }
  }

  const std::shared_ptr<FontFamily>& fallback =
      mFallbackFontProvider->matchFallbackFont(ch, GetFontLocale(langListId));

  if (fallback) {
    mCachedFallbackFamilies[locale].push_back(fallback);
  }
  return fallback;
}

const uint32_t NBSP = 0x00A0;
const uint32_t SOFT_HYPHEN = 0x00AD;
const uint32_t ZWJ = 0x200C;
const uint32_t ZWNJ = 0x200D;
const uint32_t HYPHEN = 0x2010;
const uint32_t NB_HYPHEN = 0x2011;
const uint32_t NNBSP = 0x202F;
const uint32_t FEMALE_SIGN = 0x2640;
const uint32_t MALE_SIGN = 0x2642;
const uint32_t STAFF_OF_AESCULAPIUS = 0x2695;

// Characters where we want to continue using existing font run instead of
// recomputing the best match in the fallback list.
static const uint32_t stickyWhitelist[] = {
    '!',   ',',         '-',       '.',
    ':',   ';',         '?',       NBSP,
    ZWJ,   ZWNJ,        HYPHEN,    NB_HYPHEN,
    NNBSP, FEMALE_SIGN, MALE_SIGN, STAFF_OF_AESCULAPIUS};

static bool isStickyWhitelisted(uint32_t c) {
  for (size_t i = 0; i < sizeof(stickyWhitelist) / sizeof(stickyWhitelist[0]);
       i++) {
    if (stickyWhitelist[i] == c)
      return true;
  }
  return false;
}

static bool isVariationSelector(uint32_t c) {
  return (0xFE00 <= c && c <= 0xFE0F) || (0xE0100 <= c && c <= 0xE01EF);
}

bool FontCollection::hasVariationSelector(uint32_t baseCodepoint,
                                          uint32_t variationSelector) const {
  if (!isVariationSelector(variationSelector)) {
    return false;
  }
  if (baseCodepoint >= mMaxChar) {
    return false;
  }

  std::scoped_lock _l(gMinikinLock);

  // Currently mRanges can not be used here since it isn't aware of the
  // variation sequence.
  for (size_t i = 0; i < mVSFamilyVec.size(); i++) {
    if (mVSFamilyVec[i]->hasGlyph(baseCodepoint, variationSelector)) {
      return true;
    }
  }

  // Even if there is no cmap format 14 subtable entry for the given sequence,
  // should return true for <char, text presentation selector> case since we
  // have special fallback rule for the sequence. Note that we don't need to
  // restrict this to already standardized variation sequences, since Unicode is
  // adding variation sequences more frequently now and may even move towards
  // allowing text and emoji variation selectors on any character.
  if (variationSelector == TEXT_STYLE_VS) {
    for (size_t i = 0; i < mFamilies.size(); ++i) {
      if (!mFamilies[i]->isColorEmojiFamily() &&
          mFamilies[i]->hasGlyph(baseCodepoint, 0)) {
        return true;
      }
    }
  }

  return false;
}

void FontCollection::itemize(const uint16_t* string,
                             size_t string_size,
                             FontStyle style,
                             vector<Run>* result) const {
  const uint32_t langListId = style.getLanguageListId();
  int variant = style.getVariant();
  const FontFamily* lastFamily = nullptr;
  Run* run = NULL;

  if (string_size == 0) {
    return;
  }

  const uint32_t kEndOfString = 0xFFFFFFFF;

  uint32_t nextCh = 0;
  uint32_t prevCh = 0;
  size_t nextUtf16Pos = 0;
  size_t readLength = 0;
  U16_NEXT(string, readLength, string_size, nextCh);

  do {
    const uint32_t ch = nextCh;
    const size_t utf16Pos = nextUtf16Pos;
    nextUtf16Pos = readLength;
    if (readLength < string_size) {
      U16_NEXT(string, readLength, string_size, nextCh);
    } else {
      nextCh = kEndOfString;
    }

    bool shouldContinueRun = false;
    if (lastFamily != nullptr) {
      if (isStickyWhitelisted(ch)) {
        // Continue using existing font as long as it has coverage and is
        // whitelisted
        shouldContinueRun = lastFamily->getCoverage().get(ch);
      } else if (ch == SOFT_HYPHEN || isVariationSelector(ch)) {
        // Always continue if the character is the soft hyphen or a variation
        // selector.
        shouldContinueRun = true;
      }
    }

    if (!shouldContinueRun) {
      const std::shared_ptr<FontFamily>& family = getFamilyForChar(
          ch, isVariationSelector(nextCh) ? nextCh : 0, langListId, variant);
      if (utf16Pos == 0 || family.get() != lastFamily) {
        size_t start = utf16Pos;
        // Workaround for combining marks and emoji modifiers until we implement
        // per-cluster font selection: if a combining mark or an emoji modifier
        // is found in a different font that also supports the previous
        // character, attach previous character to the new run. U+20E3 COMBINING
        // ENCLOSING KEYCAP, used in emoji, is handled properly by this since
        // it's a combining mark too.
        if (utf16Pos != 0 &&
            ((U_GET_GC_MASK(ch) & U_GC_M_MASK) != 0 ||
             (isEmojiModifier(ch) && isEmojiBase(prevCh))) &&
            family != nullptr && family->getCoverage().get(prevCh)) {
          const size_t prevChLength = U16_LENGTH(prevCh);
          run->end -= prevChLength;
          if (run->start == run->end) {
            result->pop_back();
          }
          start -= prevChLength;
        }
        result->push_back(
            {family->getClosestMatch(style), static_cast<int>(start), 0});
        run = &result->back();
        lastFamily = family.get();
      }
    }
    prevCh = ch;
    run->end = nextUtf16Pos;  // exclusive
  } while (nextCh != kEndOfString);
}

FakedFont FontCollection::baseFontFaked(FontStyle style) {
  return mFamilies[0]->getClosestMatch(style);
}

std::shared_ptr<FontCollection> FontCollection::createCollectionWithVariation(
    const std::vector<FontVariation>& variations) {
  if (variations.empty() || mSupportedAxes.empty()) {
    return nullptr;
  }

  bool hasSupportedAxis = false;
  for (const FontVariation& variation : variations) {
    if (mSupportedAxes.find(variation.axisTag) != mSupportedAxes.end()) {
      hasSupportedAxis = true;
      break;
    }
  }
  if (!hasSupportedAxis) {
    // None of variation axes are supported by this font collection.
    return nullptr;
  }

  std::vector<std::shared_ptr<FontFamily>> families;
  for (const std::shared_ptr<FontFamily>& family : mFamilies) {
    std::shared_ptr<FontFamily> newFamily =
        family->createFamilyWithVariation(variations);
    if (newFamily) {
      families.push_back(newFamily);
    } else {
      families.push_back(family);
    }
  }

  return std::shared_ptr<FontCollection>(new FontCollection(families));
}

uint32_t FontCollection::getId() const {
  return mId;
}

}  // namespace minikin
