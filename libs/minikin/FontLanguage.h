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

namespace android {

// FontLanguage is a compact representation of a BCP 47 language tag. It
// does not capture all possible information, only what directly affects
// font rendering.
struct FontLanguage {
public:
    // Default constructor creates the unsupported language.
    FontLanguage() : mScript(0ul), mLanguage(0ul), mSubScriptBits(0ul) {}

    // Parse from string
    FontLanguage(const char* buf, size_t length);

    bool operator==(const FontLanguage other) const {
        return !isUnsupported() && isEqualScript(other) && mLanguage == other.mLanguage;
    }

    bool operator!=(const FontLanguage other) const {
        return !(*this == other);
    }

    bool isUnsupported() const { return mLanguage == 0ul; }
    bool hasEmojiFlag() const { return mSubScriptBits & kEmojiFlag; }

    bool isEqualScript(const FontLanguage& other) const;

    // Returns true if this script supports the given script. For example, ja-Jpan supports Hira,
    // ja-Hira doesn't support Jpan.
    bool supportsHbScript(hb_script_t script) const;

    std::string getString() const;

    // 0 = no match, 1 = script match, 2 = script and primary language match.
    int getScoreFor(const FontLanguage other) const;

    uint64_t getIdentifier() const { return (uint64_t)mScript << 32 | (uint64_t)mLanguage; }

private:
    // ISO 15924 compliant script code. The 4 chars script code are packed into a 32 bit integer.
    uint32_t mScript;

    // ISO 639-1 or ISO 639-2 compliant language code.
    // The two or three letter language code is packed into 32 bit integer.
    // mLanguage = 0 means the FontLanguage is unsupported.
    uint32_t mLanguage;

    // For faster comparing, use 8 bits for specific scripts.
    static const uint8_t kBopomofoFlag = 1u;
    static const uint8_t kEmojiFlag = 1u << 1;
    static const uint8_t kHanFlag = 1u << 2;
    static const uint8_t kHangulFlag = 1u << 3;
    static const uint8_t kHiraganaFlag = 1u << 4;
    static const uint8_t kKatakanaFlag = 1u << 5;
    static const uint8_t kSimplifiedChineseFlag = 1u << 6;
    static const uint8_t kTraditionalChineseFlag = 1u << 7;
    uint8_t mSubScriptBits;

    static uint8_t scriptToSubScriptBits(uint32_t script);
    bool supportsScript(uint8_t requestedBits) const;
};

// Due to the limit of font fallback cost calculation, we can't use anything more than 17 languages.
const size_t FONT_LANGUAGES_LIMIT = 17;
typedef std::vector<FontLanguage> FontLanguages;

}  // namespace android

#endif  // MINIKIN_FONT_LANGUAGE_H
