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

#include "FontLanguageListCache.h"

#include <unicode/uloc.h>
#include <unordered_set>
#include <unordered_map>
#include <minikin/FontFamily.h>

#include <log/log.h>

#include "FontLanguage.h"
#include "MinikinInternal.h"

namespace minikin {

// Returns the text length of output.
static size_t toLanguageTag(char* output, size_t outSize, const std::string& locale) {
    output[0] = '\0';
    if (locale.empty()) {
        return 0;
    }

    size_t outLength = 0;
    UErrorCode uErr = U_ZERO_ERROR;
    outLength = uloc_canonicalize(locale.c_str(), output, outSize, &uErr);
    if (U_FAILURE(uErr)) {
        // unable to build a proper language identifier
        ALOGD("uloc_canonicalize(\"%s\") failed: %s", locale.c_str(), u_errorName(uErr));
        output[0] = '\0';
        return 0;
    }

    // Preserve "und" and "und-****" since uloc_addLikelySubtags changes "und" to "en-Latn-US".
    if (strncmp(output, "und", 3) == 0 &&
        (outLength == 3 || (outLength == 8 && output[3]  == '_'))) {
        return outLength;
    }

    char likelyChars[ULOC_FULLNAME_CAPACITY];
    uErr = U_ZERO_ERROR;
    uloc_addLikelySubtags(output, likelyChars, ULOC_FULLNAME_CAPACITY, &uErr);
    if (U_FAILURE(uErr)) {
        // unable to build a proper language identifier
        ALOGD("uloc_addLikelySubtags(\"%s\") failed: %s", output, u_errorName(uErr));
        output[0] = '\0';
        return 0;
    }

    uErr = U_ZERO_ERROR;
    outLength = uloc_toLanguageTag(likelyChars, output, outSize, FALSE, &uErr);
    if (U_FAILURE(uErr)) {
        // unable to build a proper language identifier
        ALOGD("uloc_toLanguageTag(\"%s\") failed: %s", likelyChars, u_errorName(uErr));
        output[0] = '\0';
        return 0;
    }
#ifdef VERBOSE_DEBUG
    ALOGD("ICU normalized '%s' to '%s'", locale.c_str(), output);
#endif
    return outLength;
}

static std::vector<FontLanguage> parseLanguageList(const std::string& input) {
    std::vector<FontLanguage> result;
    size_t currentIdx = 0;
    size_t commaLoc = 0;
    char langTag[ULOC_FULLNAME_CAPACITY];
    std::unordered_set<uint64_t> seen;
    std::string locale(input.size(), 0);

    while ((commaLoc = input.find_first_of(',', currentIdx)) != std::string::npos) {
        locale.assign(input, currentIdx, commaLoc - currentIdx);
        currentIdx = commaLoc + 1;
        size_t length = toLanguageTag(langTag, ULOC_FULLNAME_CAPACITY, locale);
        FontLanguage lang(langTag, length);
        uint64_t identifier = lang.getIdentifier();
        if (!lang.isUnsupported() && seen.count(identifier) == 0) {
            result.push_back(lang);
            if (result.size() == FONT_LANGUAGES_LIMIT) {
              break;
            }
            seen.insert(identifier);
        }
    }
    if (result.size() < FONT_LANGUAGES_LIMIT) {
      locale.assign(input, currentIdx, input.size() - currentIdx);
      size_t length = toLanguageTag(langTag, ULOC_FULLNAME_CAPACITY, locale);
      FontLanguage lang(langTag, length);
      uint64_t identifier = lang.getIdentifier();
      if (!lang.isUnsupported() && seen.count(identifier) == 0) {
          result.push_back(lang);
      }
    }
    return result;
}

class FontLanguageListCache {
public:
    FontLanguageListCache() {
        // Insert an empty language list for mapping default language list to kEmptyListId.
        // The default language list has only one FontLanguage and it is the unsupported language.
        mLanguageLists.emplace(kEmptyLanguageListId, FontLanguages());
        mLanguageListLookupTable.emplace("", kEmptyLanguageListId);
    }

    uint32_t put(const std::string& languages) {
        assertLocked(gLock);

        const auto& it = mLanguageListLookupTable.find(languages);
        if (it != mLanguageListLookupTable.end()) {
            return it->second;
        }

        // Given language list is not in cache. Insert it and return newly assigned ID.
        const uint32_t nextId = mLanguageLists.size();
        FontLanguages fontLanguages(parseLanguageList(languages));
        if (fontLanguages.empty()) {
            mLanguageListLookupTable.emplace(languages, kEmptyLanguageListId);
            return kEmptyLanguageListId;
        }
        mLanguageLists.emplace(nextId, std::move(fontLanguages));
        mLanguageListLookupTable.emplace(languages, nextId);
        return nextId;
    }

    const FontLanguages& get(uint32_t id) {
        assertLocked(gLock);

        return mLanguageLists[id];
    }

private:
    std::unordered_map<uint32_t, FontLanguages> mLanguageLists;

    // A map from string representation of the font language list to the ID.
    std::unordered_map<std::string, uint32_t> mLanguageListLookupTable;
};

static FontLanguageListCache& getInstance() {
    static FontLanguageListCache instance;
    return instance;
}

// static
uint32_t putLanguageListToCacheLocked(const std::string& languages) {
    return getInstance().put(languages);
}

// static
const FontLanguages& getFontLanguagesFromCacheLocked(uint32_t id) {
    return getInstance().get(id);
}

}  // namespace minikin
