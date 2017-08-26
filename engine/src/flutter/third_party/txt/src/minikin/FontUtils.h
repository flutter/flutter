/*
 * Copyright (C) 2017 The Android Open Source Project
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

#ifndef MINIKIN_FONT_UTILS_H
#define MINIKIN_FONT_UTILS_H

#include <unordered_set>

namespace minikin {

bool analyzeStyle(const uint8_t* os2_data,
                  size_t os2_size,
                  int* weight,
                  bool* italic);
void analyzeAxes(const uint8_t* fvar_data,
                 size_t fvar_size,
                 std::unordered_set<uint32_t>* axes);

}  // namespace minikin

#endif  // MINIKIN_ANALYZE_STYLE_H
