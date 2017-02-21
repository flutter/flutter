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

#include "FontLanguage.h"

namespace minikin {

// A special ID for the empty language list.
// This value must be 0 since the empty language list is inserted into mLanguageLists by default.
const uint32_t kEmptyLanguageListId = 0;

// Looks up from internal cache and returns associated ID if FontLanguages constructed from given
// string is already registered. If it is new to internal cache, put it to internal cache and
// returns newly assigned ID.
uint32_t putLanguageListToCacheLocked(const std::string& languages);

// Returns FontLanguages associated with given ID.
const FontLanguages& getFontLanguagesFromCacheLocked(uint32_t id);

}  // namespace minikin

#endif  // MINIKIN_FONT_LANGUAGE_LIST_CACHE_H
