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

#ifndef MINIKIN_FONT_LANGUAGE_LIST_CACHE_H
#define MINIKIN_FONT_LANGUAGE_LIST_CACHE_H

#include <unordered_map>

#include <minikin/FontFamily.h>
#include "FontLanguage.h"

namespace minikin {

class FontLanguageListCache {
public:
    // A special ID for the empty language list.
    // This value must be 0 since the empty language list is inserted into mLanguageLists by
    // default.
    const static uint32_t kEmptyListId = 0;

    // Returns language list ID for the given string representation of FontLanguages.
    // Caller should acquire a lock before calling the method.
    static uint32_t getId(const std::string& languages);

    // Caller should acquire a lock before calling the method.
    static const FontLanguages& getById(uint32_t id);

private:
    FontLanguageListCache() {}  // Singleton
    ~FontLanguageListCache() {}

    // Caller should acquire a lock before calling the method.
    static FontLanguageListCache* getInstance();

    std::vector<FontLanguages> mLanguageLists;

    // A map from string representation of the font language list to the ID.
    std::unordered_map<std::string, uint32_t> mLanguageListLookupTable;
};

}  // namespace minikin

#endif  // MINIKIN_FONT_LANGUAGE_LIST_CACHE_H
