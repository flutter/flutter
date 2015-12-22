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

#include <cutils/log.h>

#include "MinikinInternal.h"

namespace android {

const uint32_t FontLanguageListCache::kEmptyListId;

// static
uint32_t FontLanguageListCache::getId(const std::string& languages) {
    FontLanguageListCache* inst = FontLanguageListCache::getInstance();
    std::unordered_map<std::string, uint32_t>::const_iterator it =
            inst->mLanguageListLookupTable.find(languages);
    if (it != inst->mLanguageListLookupTable.end()) {
        return it->second;
    }

    // Given language list is not in cache. Insert it and return newly assigned ID.
    const uint32_t nextId = inst->mLanguageLists.size();
    inst->mLanguageLists.push_back(FontLanguages(languages.c_str(), languages.size()));
    inst->mLanguageListLookupTable.insert(std::make_pair(languages, nextId));
    return nextId;
}

// static
const FontLanguages& FontLanguageListCache::getById(uint32_t id) {
    FontLanguageListCache* inst = FontLanguageListCache::getInstance();
    LOG_ALWAYS_FATAL_IF(id >= inst->mLanguageLists.size(), "Lookup by unknown language list ID.");
    return inst->mLanguageLists[id];
}

// static
FontLanguageListCache* FontLanguageListCache::getInstance() {
    assertMinikinLocked();
    static FontLanguageListCache* instance = nullptr;
    if (instance == nullptr) {
        instance = new FontLanguageListCache();

        // Insert an empty language list for mapping empty language list to kEmptyListId.
        instance->mLanguageLists.push_back(FontLanguages());
        instance->mLanguageListLookupTable.insert(std::make_pair("", kEmptyListId));
    }
    return instance;
}

}  // namespace android
