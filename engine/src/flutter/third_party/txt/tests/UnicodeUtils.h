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

#include <cstdint>

namespace minikin {

void ParseUnicode(uint16_t* buf,
                  size_t buf_size,
                  const char* src,
                  size_t* result_size,
                  size_t* offset);

std::vector<uint16_t> parseUnicodeStringWithOffset(const std::string& in,
                                                   size_t* offset);
std::vector<uint16_t> parseUnicodeString(const std::string& in);

// Converts UTF-8 to UTF-16.
std::vector<uint16_t> utf8ToUtf16(const std::string& text);

}  // namespace minikin
