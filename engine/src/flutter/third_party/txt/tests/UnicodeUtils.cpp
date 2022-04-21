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

#include <log/log.h>
#include <unicode/utf.h>
#include <unicode/utf8.h>
#include <cstdlib>
#include <memory>
#include <string>
#include <vector>

namespace minikin {

// src is of the form "U+1F431 | 'h' 'i'". Position of "|" gets saved to offset
// if non-null. Size is returned in an out parameter because gtest needs a void
// return for ASSERT to work.
void ParseUnicode(uint16_t* buf,
                  size_t buf_size,
                  const char* src,
                  size_t* result_size,
                  size_t* offset) {
  size_t input_ix = 0;
  size_t output_ix = 0;
  bool seen_offset = false;

  while (src[input_ix] != 0) {
    switch (src[input_ix]) {
      case '\'':
        // single ASCII char
        LOG_ALWAYS_FATAL_IF(static_cast<uint8_t>(src[input_ix]) >= 0x80);
        input_ix++;
        LOG_ALWAYS_FATAL_IF(src[input_ix] == 0);
        LOG_ALWAYS_FATAL_IF(output_ix >= buf_size);
        buf[output_ix++] = (uint16_t)src[input_ix++];
        LOG_ALWAYS_FATAL_IF(src[input_ix] != '\'');
        input_ix++;
        break;
      case 'u':
      case 'U': {
        // Unicode codepoint in hex syntax
        input_ix++;
        LOG_ALWAYS_FATAL_IF(src[input_ix] != '+');
        input_ix++;
        char* endptr = (char*)src + input_ix;
        unsigned long int codepoint = strtoul(src + input_ix, &endptr, 16);
        size_t num_hex_digits = endptr - (src + input_ix);

        // also triggers on invalid number syntax, digits = 0
        LOG_ALWAYS_FATAL_IF(num_hex_digits < 4u);
        LOG_ALWAYS_FATAL_IF(num_hex_digits > 6u);
        LOG_ALWAYS_FATAL_IF(codepoint > 0x10FFFFu);
        input_ix += num_hex_digits;
        if (U16_LENGTH(codepoint) == 1) {
          LOG_ALWAYS_FATAL_IF(output_ix + 1 > buf_size);
          buf[output_ix++] = codepoint;
        } else {
          // UTF-16 encoding
          LOG_ALWAYS_FATAL_IF(output_ix + 2 > buf_size);
          buf[output_ix++] = U16_LEAD(codepoint);
          buf[output_ix++] = U16_TRAIL(codepoint);
        }
        break;
      }
      case ' ':
        input_ix++;
        break;
      case '|':
        LOG_ALWAYS_FATAL_IF(seen_offset);
        LOG_ALWAYS_FATAL_IF(offset == nullptr);
        *offset = output_ix;
        seen_offset = true;
        input_ix++;
        break;
      default:
        LOG_ALWAYS_FATAL("Unexpected Character");
    }
  }
  LOG_ALWAYS_FATAL_IF(result_size == nullptr);
  *result_size = output_ix;
  LOG_ALWAYS_FATAL_IF(!seen_offset && offset != nullptr);
}

std::vector<uint16_t> parseUnicodeStringWithOffset(const std::string& in,
                                                   size_t* offset) {
  std::unique_ptr<uint16_t[]> buffer = std::make_unique<uint16_t[]>(in.size());
  size_t result_size = 0;
  ParseUnicode(buffer.get(), in.size(), in.c_str(), &result_size, offset);
  return std::vector<uint16_t>(buffer.get(), buffer.get() + result_size);
}

std::vector<uint16_t> parseUnicodeString(const std::string& in) {
  return parseUnicodeStringWithOffset(in, nullptr);
}

std::vector<uint16_t> utf8ToUtf16(const std::string& text) {
  std::vector<uint16_t> result;
  int32_t i = 0;
  const int32_t textLength = static_cast<int32_t>(text.size());
  uint32_t c = 0;
  while (i < textLength) {
    U8_NEXT(text.c_str(), i, textLength, c);
    if (U16_LENGTH(c) == 1) {
      result.push_back(c);
    } else {
      result.push_back(U16_LEAD(c));
      result.push_back(U16_TRAIL(c));
    }
  }
  return result;
}

}  // namespace minikin
