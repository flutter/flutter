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

#include <vector>
#include <memory>
#include <algorithm>
#include <string>
#include <unicode/uchar.h>

// HACK: for reading pattern file
#include <fcntl.h>

#define LOG_TAG "Minikin"
#include "utils/Log.h"

#include "minikin/Hyphenator.h"

using std::vector;

namespace android {

static const uint16_t CHAR_SOFT_HYPHEN = 0x00AD;

void Hyphenator::addPattern(const uint16_t* pattern, size_t size) {
    vector<uint16_t> word;
    vector<uint8_t> result;

    // start by parsing the Liang-format pattern into a word and a result vector, the
    // vector right-aligned but without leading zeros. Examples:
    // a1bc2d -> abcd [1, 0, 2, 0]
    // abc1 -> abc [1]
    // 1a2b3c4d5 -> abcd [1, 2, 3, 4, 5]
    bool lastWasLetter = false;
    bool haveSeenNumber = false;
    for (size_t i = 0; i < size; i++) {
        uint16_t c = pattern[i];
        if (isdigit(c)) {
            result.push_back(c - '0');
            lastWasLetter = false;
            haveSeenNumber = true;
        } else {
            word.push_back(c);
            if (lastWasLetter && haveSeenNumber) {
                result.push_back(0);
            }
            lastWasLetter = true;
        }
    }
    if (lastWasLetter) {
        result.push_back(0);
    }
    Trie* t = &root;
    for (size_t i = 0; i < word.size(); i++) {
        t = &t->succ[word[i]];
    }
    t->result = result;
}

// If any soft hyphen is present in the word, use soft hyphens to decide hyphenation,
// as recommended in UAX #14 (Use of Soft Hyphen)
void Hyphenator::hyphenateSoft(vector<uint8_t>* result, const uint16_t* word, size_t len) {
    (*result)[0] = 0;
    for (size_t i = 1; i < len; i++) {
        (*result)[i] = word[i - 1] == CHAR_SOFT_HYPHEN;
    }
}

void Hyphenator::hyphenate(vector<uint8_t>* result, const uint16_t* word, size_t len) {
    result->clear();
    result->resize(len);
    if (len < MIN_PREFIX + MIN_SUFFIX) return;
    size_t maxOffset = len - MIN_SUFFIX + 1;
    for (size_t i = 0; i < len + 1; i++) {
        const Trie* node = &root;
        for (size_t j = i; j < len + 2; j++) {
            uint16_t c;
            if (j == 0 || j == len + 1) {
                c = '.';  // word boundary character in pattern data files
            } else {
                c = word[j - 1];
                if (c == CHAR_SOFT_HYPHEN) {
                    hyphenateSoft(result, word, len);
                    return;
                }
                // TODO: This uses ICU's simple character to character lowercasing, which ignores
                // the locale, and ignores cases when lowercasing a character results in more than
                // one character. It should be fixed to consider the locale (in order for it to work
                // correctly for Turkish and Azerbaijani), as well as support one-to-many, and
                // many-to-many case conversions (including non-BMP cases).
                if (c < 0x00C0) { // U+00C0 is the lowest uppercase non-ASCII character
                    // Convert uppercase ASCII to lowercase ASCII, but keep other characters as-is
                    if (0x0041 <= c && c <= 0x005A) {
                        c += 0x0020;
                    }
                } else {
                    c = u_tolower(c);
                }
            }
            auto search = node->succ.find(c);
            if (search != node->succ.end()) {
                node = &search->second;
            } else {
                break;
            }
            if (!node->result.empty()) {
                int resultLen = node->result.size();
                int offset = j + 1 - resultLen;
                int start = std::max(MIN_PREFIX - offset, 0);
                int end = std::min(resultLen, (int)maxOffset - offset);
                // TODO performance: this inner loop can profitably be optimized
                for (int k = start; k < end; k++) {
                    (*result)[offset + k] = std::max((*result)[offset + k], node->result[k]);
                }
#if 0
                // debug printing of matched patterns
                std::string dbg;
                for (size_t k = i; k <= j + 1; k++) {
                    int off = k - j - 2 + resultLen;
                    if (off >= 0 && node->result[off] != 0) {
                        dbg.push_back((char)('0' + node->result[off]));
                    }
                    if (k < j + 1) {
                        uint16_t c = (k == 0 || k == len + 1) ? '.' : word[k - 1];
                        dbg.push_back((char)c);
                    }
                }
                ALOGD("%d:%d %s", i, j, dbg.c_str());
#endif
            }
        }
    }
    // Since the above calculation does not modify values outside
    // [MIN_PREFIX, len - MIN_SUFFIX], they are left as 0.
    for (size_t i = MIN_PREFIX; i < maxOffset; i++) {
        (*result)[i] &= 1;
    }
}

Hyphenator* Hyphenator::load(const uint16_t *patternData, size_t size) {
    Hyphenator* result = new Hyphenator;
    for (size_t i = 0; i < size; i++) {
        size_t end = i;
        while (patternData[end] != '\n') end++;
        result->addPattern(patternData + i, end - i);
        i = end;
    }
    return result;
}

}  // namespace android
