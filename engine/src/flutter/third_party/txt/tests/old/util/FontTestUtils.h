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

#ifndef MINIKIN_FONT_TEST_UTILS_H
#define MINIKIN_FONT_TEST_UTILS_H

#include <minikin/FontCollection.h>

#include <memory>

namespace minikin {

/**
 * Returns list of FontFamily from installed fonts.
 *
 * This function reads an XML file and makes font families.
 *
 * Caller must unref the returned pointer.
 */
std::vector<std::shared_ptr<FontFamily>> getFontFamilies(const char* fontDir,
                                                         const char* fontXml);

/**
 * Returns FontCollection from installed fonts.
 *
 * This function reads an XML file and makes font families and collections of
 * them. MinikinFontForTest is used for FontFamily creation.
 *
 * Caller must unref the returned pointer.
 */
std::shared_ptr<FontCollection> getFontCollection(const char* fontDir,
                                                  const char* fontXml);

}  // namespace minikin
#endif  // MINIKIN_FONT_TEST_UTILS_H
