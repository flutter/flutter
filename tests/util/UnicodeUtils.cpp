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

#include <gtest/gtest.h>
#include <unicode/utf.h>
#include <cstdlib>

// src is of the form "U+1F431 | 'h' 'i'". Position of "|" gets saved to offset if non-null.
// Size is returned in an out parameter because gtest needs a void return for ASSERT to work.
void ParseUnicode(uint16_t* buf, size_t buf_size, const char* src, size_t* result_size,
        size_t* offset) {
    size_t input_ix = 0;
    size_t output_ix = 0;
    bool seen_offset = false;

    while (src[input_ix] != 0) {
        switch (src[input_ix]) {
        case '\'':
            // single ASCII char
            ASSERT_LT(src[input_ix], 0x80);
            input_ix++;
            ASSERT_NE(src[input_ix], 0);
            ASSERT_LT(output_ix, buf_size);
            buf[output_ix++] = (uint16_t)src[input_ix++];
            ASSERT_EQ(src[input_ix], '\'');
            input_ix++;
            break;
        case 'u':
        case 'U': {
            // Unicode codepoint in hex syntax
            input_ix++;
            ASSERT_EQ(src[input_ix], '+');
            input_ix++;
            char* endptr = (char*)src + input_ix;
            unsigned long int codepoint = strtoul(src + input_ix, &endptr, 16);
            size_t num_hex_digits = endptr - (src + input_ix);
            ASSERT_GE(num_hex_digits, 4u);  // also triggers on invalid number syntax, digits = 0
            ASSERT_LE(num_hex_digits, 6u);
            ASSERT_LE(codepoint, 0x10FFFFu);
            input_ix += num_hex_digits;
            if (U16_LENGTH(codepoint) == 1) {
                ASSERT_LE(output_ix + 1, buf_size);
                buf[output_ix++] = codepoint;
            } else {
                // UTF-16 encoding
                ASSERT_LE(output_ix + 2, buf_size);
                buf[output_ix++] = U16_LEAD(codepoint);
                buf[output_ix++] = U16_TRAIL(codepoint);
            }
            break;
        }
        case ' ':
            input_ix++;
            break;
        case '|':
            ASSERT_FALSE(seen_offset);
            ASSERT_NE(offset, nullptr);
            *offset = output_ix;
            seen_offset = true;
            input_ix++;
            break;
        default:
            FAIL();  // unexpected character
        }
    }
    ASSERT_NE(result_size, nullptr);
    *result_size = output_ix;
    ASSERT_TRUE(seen_offset || offset == nullptr);
}

TEST(UnicodeUtils, parse) {
    const size_t BUF_SIZE = 256;
    uint16_t buf[BUF_SIZE];
    size_t offset;
    size_t size;
    ParseUnicode(buf, BUF_SIZE, "U+000D U+1F431 | 'a'", &size, &offset);
    EXPECT_EQ(size, 4u);
    EXPECT_EQ(offset, 3u);
    EXPECT_EQ(buf[0], 0x000D);
    EXPECT_EQ(buf[1], 0xD83D);
    EXPECT_EQ(buf[2], 0xDC31);
    EXPECT_EQ(buf[3], 'a');
}
