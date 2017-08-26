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

#define LOG_TAG "Minikin"

#include "FontLanguage.h"

#include <hb.h>
#include <string.h>
#include <unicode/uloc.h>
#include <algorithm>

namespace minikin {

#define SCRIPT_TAG(c1, c2, c3, c4)                                           \
  (((uint32_t)(c1)) << 24 | ((uint32_t)(c2)) << 16 | ((uint32_t)(c3)) << 8 | \
   ((uint32_t)(c4)))

// Check if a language code supports emoji according to its subtag
static bool isEmojiSubtag(const char* buf,
                          size_t bufLen,
                          const char* subtag,
                          size_t subtagLen) {
  if (bufLen < subtagLen) {
    return false;
  }
  if (strncmp(buf, subtag, subtagLen) != 0) {
    return false;  // no match between two strings
  }
  return (bufLen == subtagLen || buf[subtagLen] == '\0' ||
          buf[subtagLen] == '-' || buf[subtagLen] == '_');
}

// Pack the three letter code into 15 bits and stored to 16 bit integer. The
// highest bit is 0. For the region code, the letters must be all digits in
// three letter case, so the number of possible values are 10. For the language
// code, the letters must be all small alphabets, so the number of possible
// values are 26. Thus, 5 bits are sufficient for each case and we can pack the
// three letter language code or region code to 15 bits.
//
// In case of two letter code, use fullbit(0x1f) for the first letter instead.
static uint16_t packLanguageOrRegion(const char* c,
                                     size_t length,
                                     uint8_t twoLetterBase,
                                     uint8_t threeLetterBase) {
  if (length == 2) {
    return 0x7c00u |  // 0x1fu << 10
           (uint16_t)(c[0] - twoLetterBase) << 5 |
           (uint16_t)(c[1] - twoLetterBase);
  } else {
    return ((uint16_t)(c[0] - threeLetterBase) << 10) |
           (uint16_t)(c[1] - threeLetterBase) << 5 |
           (uint16_t)(c[2] - threeLetterBase);
  }
}

static size_t unpackLanguageOrRegion(uint16_t in,
                                     char* out,
                                     uint8_t twoLetterBase,
                                     uint8_t threeLetterBase) {
  uint8_t first = (in >> 10) & 0x1f;
  uint8_t second = (in >> 5) & 0x1f;
  uint8_t third = in & 0x1f;

  if (first == 0x1f) {
    out[0] = second + twoLetterBase;
    out[1] = third + twoLetterBase;
    return 2;
  } else {
    out[0] = first + threeLetterBase;
    out[1] = second + threeLetterBase;
    out[2] = third + threeLetterBase;
    return 3;
  }
}

// Find the next '-' or '_' index from startOffset position. If not found,
// returns bufferLength.
static size_t nextDelimiterIndex(const char* buffer,
                                 size_t bufferLength,
                                 size_t startOffset) {
  for (size_t i = startOffset; i < bufferLength; ++i) {
    if (buffer[i] == '-' || buffer[i] == '_') {
      return i;
    }
  }
  return bufferLength;
}

static inline bool isLowercase(char c) {
  return 'a' <= c && c <= 'z';
}

static inline bool isUppercase(char c) {
  return 'A' <= c && c <= 'Z';
}

static inline bool isDigit(char c) {
  return '0' <= c && c <= '9';
}

// Returns true if the buffer is valid for language code.
static inline bool isValidLanguageCode(const char* buffer, size_t length) {
  if (length != 2 && length != 3)
    return false;
  if (!isLowercase(buffer[0]))
    return false;
  if (!isLowercase(buffer[1]))
    return false;
  if (length == 3 && !isLowercase(buffer[2]))
    return false;
  return true;
}

// Returns true if buffer is valid for script code. The length of buffer must
// be 4.
static inline bool isValidScriptCode(const char* buffer) {
  return isUppercase(buffer[0]) && isLowercase(buffer[1]) &&
         isLowercase(buffer[2]) && isLowercase(buffer[3]);
}

// Returns true if the buffer is valid for region code.
static inline bool isValidRegionCode(const char* buffer, size_t length) {
  return (length == 2 && isUppercase(buffer[0]) && isUppercase(buffer[1])) ||
         (length == 3 && isDigit(buffer[0]) && isDigit(buffer[1]) &&
          isDigit(buffer[2]));
}

// Parse BCP 47 language identifier into internal structure
FontLanguage::FontLanguage(const char* buf, size_t length) : FontLanguage() {
  size_t firstDelimiterPos = nextDelimiterIndex(buf, length, 0);
  if (isValidLanguageCode(buf, firstDelimiterPos)) {
    mLanguage = packLanguageOrRegion(buf, firstDelimiterPos, 'a', 'a');
  } else {
    // We don't understand anything other than two-letter or three-letter
    // language codes, so we skip parsing the rest of the string.
    return;
  }

  if (firstDelimiterPos == length) {
    mHbLanguage = hb_language_from_string(getString().c_str(), -1);
    return;  // Language code only.
  }

  size_t nextComponentStartPos = firstDelimiterPos + 1;
  size_t nextDelimiterPos =
      nextDelimiterIndex(buf, length, nextComponentStartPos);
  size_t componentLength = nextDelimiterPos - nextComponentStartPos;

  if (componentLength == 4) {
    // Possibly script code.
    const char* p = buf + nextComponentStartPos;
    if (isValidScriptCode(p)) {
      mScript = SCRIPT_TAG(p[0], p[1], p[2], p[3]);
      mSubScriptBits = scriptToSubScriptBits(mScript);
    }

    if (nextDelimiterPos == length) {
      mHbLanguage = hb_language_from_string(getString().c_str(), -1);
      mEmojiStyle = resolveEmojiStyle(buf, length, mScript);
      return;  // No region code.
    }

    nextComponentStartPos = nextDelimiterPos + 1;
    nextDelimiterPos = nextDelimiterIndex(buf, length, nextComponentStartPos);
    componentLength = nextDelimiterPos - nextComponentStartPos;
  }

  if (componentLength == 2 || componentLength == 3) {
    // Possibly region code.
    const char* p = buf + nextComponentStartPos;
    if (isValidRegionCode(p, componentLength)) {
      mRegion = packLanguageOrRegion(p, componentLength, 'A', '0');
    }
  }

  mHbLanguage = hb_language_from_string(getString().c_str(), -1);
  mEmojiStyle = resolveEmojiStyle(buf, length, mScript);
}

// static
FontLanguage::EmojiStyle FontLanguage::resolveEmojiStyle(const char* buf,
                                                         size_t length,
                                                         uint32_t script) {
  // First, lookup emoji subtag.
  // 10 is the length of "-u-em-text", which is the shortest emoji subtag,
  // unnecessary comparison can be avoided if total length is smaller than 10.
  const size_t kMinSubtagLength = 10;
  if (length >= kMinSubtagLength) {
    static const char kPrefix[] = "-u-em-";
    const char* pos =
        std::search(buf, buf + length, kPrefix, kPrefix + strlen(kPrefix));
    if (pos != buf + length) {  // found
      pos += strlen(kPrefix);
      const size_t remainingLength = length - (pos - buf);
      if (isEmojiSubtag(pos, remainingLength, "emoji", 5)) {
        return EMSTYLE_EMOJI;
      } else if (isEmojiSubtag(pos, remainingLength, "text", 4)) {
        return EMSTYLE_TEXT;
      } else if (isEmojiSubtag(pos, remainingLength, "default", 7)) {
        return EMSTYLE_DEFAULT;
      }
    }
  }

  // If no emoji subtag was provided, resolve the emoji style from script code.
  if (script == SCRIPT_TAG('Z', 's', 'y', 'e')) {
    return EMSTYLE_EMOJI;
  } else if (script == SCRIPT_TAG('Z', 's', 'y', 'm')) {
    return EMSTYLE_TEXT;
  }

  return EMSTYLE_EMPTY;
}

// static
uint8_t FontLanguage::scriptToSubScriptBits(uint32_t script) {
  uint8_t subScriptBits = 0u;
  switch (script) {
    case SCRIPT_TAG('B', 'o', 'p', 'o'):
      subScriptBits = kBopomofoFlag;
      break;
    case SCRIPT_TAG('H', 'a', 'n', 'g'):
      subScriptBits = kHangulFlag;
      break;
    case SCRIPT_TAG('H', 'a', 'n', 'b'):
      // Bopomofo is almost exclusively used in Taiwan.
      subScriptBits = kHanFlag | kBopomofoFlag;
      break;
    case SCRIPT_TAG('H', 'a', 'n', 'i'):
      subScriptBits = kHanFlag;
      break;
    case SCRIPT_TAG('H', 'a', 'n', 's'):
      subScriptBits = kHanFlag | kSimplifiedChineseFlag;
      break;
    case SCRIPT_TAG('H', 'a', 'n', 't'):
      subScriptBits = kHanFlag | kTraditionalChineseFlag;
      break;
    case SCRIPT_TAG('H', 'i', 'r', 'a'):
      subScriptBits = kHiraganaFlag;
      break;
    case SCRIPT_TAG('H', 'r', 'k', 't'):
      subScriptBits = kKatakanaFlag | kHiraganaFlag;
      break;
    case SCRIPT_TAG('J', 'p', 'a', 'n'):
      subScriptBits = kHanFlag | kKatakanaFlag | kHiraganaFlag;
      break;
    case SCRIPT_TAG('K', 'a', 'n', 'a'):
      subScriptBits = kKatakanaFlag;
      break;
    case SCRIPT_TAG('K', 'o', 'r', 'e'):
      subScriptBits = kHanFlag | kHangulFlag;
      break;
  }
  return subScriptBits;
}

std::string FontLanguage::getString() const {
  if (isUnsupported()) {
    return "und";
  }
  char buf[16];
  size_t i = unpackLanguageOrRegion(mLanguage, buf, 'a', 'a');
  if (mScript != 0) {
    buf[i++] = '-';
    buf[i++] = (mScript >> 24) & 0xFFu;
    buf[i++] = (mScript >> 16) & 0xFFu;
    buf[i++] = (mScript >> 8) & 0xFFu;
    buf[i++] = mScript & 0xFFu;
  }
  if (mRegion != INVALID_CODE) {
    buf[i++] = '-';
    i += unpackLanguageOrRegion(mRegion, buf + i, 'A', '0');
  }
  return std::string(buf, i);
}

bool FontLanguage::isEqualScript(const FontLanguage& other) const {
  return other.mScript == mScript;
}

// static
bool FontLanguage::supportsScript(uint8_t providedBits, uint8_t requestedBits) {
  return requestedBits != 0 && (providedBits & requestedBits) == requestedBits;
}

bool FontLanguage::supportsHbScript(hb_script_t script) const {
  static_assert(
      SCRIPT_TAG('J', 'p', 'a', 'n') == HB_TAG('J', 'p', 'a', 'n'),
      "The Minikin script and HarfBuzz hb_script_t have different encodings.");
  if (script == mScript)
    return true;
  return supportsScript(mSubScriptBits, scriptToSubScriptBits(script));
}

int FontLanguage::calcScoreFor(const FontLanguages& supported) const {
  bool languageScriptMatch = false;
  bool subtagMatch = false;
  bool scriptMatch = false;

  for (size_t i = 0; i < supported.size(); ++i) {
    if (mEmojiStyle != EMSTYLE_EMPTY &&
        mEmojiStyle == supported[i].mEmojiStyle) {
      subtagMatch = true;
      if (mLanguage == supported[i].mLanguage) {
        return 4;
      }
    }
    if (isEqualScript(supported[i]) ||
        supportsScript(supported[i].mSubScriptBits, mSubScriptBits)) {
      scriptMatch = true;
      if (mLanguage == supported[i].mLanguage) {
        languageScriptMatch = true;
      }
    }
  }

  if (supportsScript(supported.getUnionOfSubScriptBits(), mSubScriptBits)) {
    scriptMatch = true;
    if (mLanguage == supported[0].mLanguage &&
        supported.isAllTheSameLanguage()) {
      return 3;
    }
  }

  if (languageScriptMatch) {
    return 3;
  } else if (subtagMatch) {
    return 2;
  } else if (scriptMatch) {
    return 1;
  }
  return 0;
}

FontLanguages::FontLanguages(std::vector<FontLanguage>&& languages)
    : mLanguages(std::move(languages)) {
  if (mLanguages.empty()) {
    return;
  }

  const FontLanguage& lang = mLanguages[0];

  mIsAllTheSameLanguage = true;
  mUnionOfSubScriptBits = lang.mSubScriptBits;
  for (size_t i = 1; i < mLanguages.size(); ++i) {
    mUnionOfSubScriptBits |= mLanguages[i].mSubScriptBits;
    if (mIsAllTheSameLanguage && lang.mLanguage != mLanguages[i].mLanguage) {
      mIsAllTheSameLanguage = false;
    }
  }
}

#undef SCRIPT_TAG
}  // namespace minikin
