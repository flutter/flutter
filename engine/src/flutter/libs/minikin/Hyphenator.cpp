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

// The following are structs that correspond to tables inside the hyb file format

struct AlphabetTable0 {
    uint32_t version;
    uint32_t min_codepoint;
    uint32_t max_codepoint;
    uint8_t data[1];  // actually flexible array, size is known at runtime
};

struct AlphabetTable1 {
    uint32_t version;
    uint32_t n_entries;
    uint32_t data[1]; // actually flexible array, size is known at runtime

    static uint32_t codepoint(uint32_t entry) { return entry >> 11; }
    static uint32_t value(uint32_t entry) { return entry & 0x7ff; }
};

struct Trie {
    uint32_t version;
    uint32_t char_mask;
    uint32_t link_shift;
    uint32_t link_mask;
    uint32_t pattern_shift;
    uint32_t n_entries;
    uint32_t data[1];  // actually flexible array, size is known at runtime
};

struct Pattern {
    uint32_t version;
    uint32_t n_entries;
    uint32_t pattern_offset;
    uint32_t pattern_size;
    uint32_t data[1];  // actually flexible array, size is known at runtime

    // accessors
    static uint32_t len(uint32_t entry) { return entry >> 26; }
    static uint32_t shift(uint32_t entry) { return (entry >> 20) & 0x3f; }
    const uint8_t* buf(uint32_t entry) const {
        return reinterpret_cast<const uint8_t*>(this) + pattern_offset + (entry & 0xfffff);
    }
};

struct Header {
    uint32_t magic;
    uint32_t version;
    uint32_t alphabet_offset;
    uint32_t trie_offset;
    uint32_t pattern_offset;
    uint32_t file_size;

    // accessors
    const uint8_t* bytes() const { return reinterpret_cast<const uint8_t*>(this); }
    uint32_t alphabetVersion() const {
        return *reinterpret_cast<const uint32_t*>(bytes() + alphabet_offset);
    }
    const AlphabetTable0* alphabetTable0() const {
        return reinterpret_cast<const AlphabetTable0*>(bytes() + alphabet_offset);
    }
    const AlphabetTable1* alphabetTable1() const {
        return reinterpret_cast<const AlphabetTable1*>(bytes() + alphabet_offset);
    }
    const Trie* trieTable() const {
        return reinterpret_cast<const Trie*>(bytes() + trie_offset);
    }
    const Pattern* patternTable() const {
        return reinterpret_cast<const Pattern*>(bytes() + pattern_offset);
    }
};

Hyphenator* Hyphenator::loadBinary(const uint8_t* patternData) {
    Hyphenator* result = new Hyphenator;
    result->patternData = patternData;
    return result;
}

void Hyphenator::hyphenate(vector<uint8_t>* result, const uint16_t* word, size_t len) {
    result->clear();
    result->resize(len);
    const size_t paddedLen = len + 2;  // start and stop code each count for 1
    if (patternData != nullptr &&
            (int)len >= MIN_PREFIX + MIN_SUFFIX && paddedLen <= MAX_HYPHENATED_SIZE) {
        uint16_t alpha_codes[MAX_HYPHENATED_SIZE];
        if (alphabetLookup(alpha_codes, word, len)) {
            hyphenateFromCodes(result->data(), alpha_codes, paddedLen);
            return;
        }
        // TODO: try NFC normalization
        // TODO: handle non-BMP Unicode (requires remapping of offsets)
    }
    hyphenateSoft(result->data(), word, len);
}

// If any soft hyphen is present in the word, use soft hyphens to decide hyphenation,
// as recommended in UAX #14 (Use of Soft Hyphen)
void Hyphenator::hyphenateSoft(uint8_t* result, const uint16_t* word, size_t len) {
    result[0] = 0;
    for (size_t i = 1; i < len; i++) {
        result[i] = word[i - 1] == CHAR_SOFT_HYPHEN;
     }
}

bool Hyphenator::alphabetLookup(uint16_t* alpha_codes, const uint16_t* word, size_t len) {
    const Header* header = getHeader();
    // TODO: check header magic
    uint32_t alphabetVersion = header->alphabetVersion();
    if (alphabetVersion == 0) {
        const AlphabetTable0* alphabet = header->alphabetTable0();
        uint32_t min_codepoint = alphabet->min_codepoint;
        uint32_t max_codepoint = alphabet->max_codepoint;
        alpha_codes[0] = 0;  // word start
        for (size_t i = 0; i < len; i++) {
            uint16_t c = word[i];
            if (c < min_codepoint || c >= max_codepoint) {
                return false;
            }
            uint8_t code = alphabet->data[c - min_codepoint];
            if (code == 0) {
                return false;
            }
            alpha_codes[i + 1] = code;
        }
        alpha_codes[len + 1] = 0;  // word termination
        return true;
    } else if (alphabetVersion == 1) {
        const AlphabetTable1* alphabet = header->alphabetTable1();
        size_t n_entries = alphabet->n_entries;
        const uint32_t* begin = alphabet->data;
        const uint32_t* end = begin + n_entries;
        alpha_codes[0] = 0;
        for (size_t i = 0; i < len; i++) {
            uint16_t c = word[i];
            auto p = std::lower_bound(begin, end, c << 11);
            if (p == end) {
                return false;
            }
            uint32_t entry = *p;
            if (AlphabetTable1::codepoint(entry) != c) {
                return false;
            }
            alpha_codes[i + 1] = AlphabetTable1::value(entry);
        }
        alpha_codes[len + 1] = 0;
        return true;
    }
    return false;
}

/**
 * Internal implementation, after conversion to codes. All case folding and normalization
 * has been done by now, and all characters have been found in the alphabet.
 * Note: len here is the padded length including 0 codes at start and end.
 **/
void Hyphenator::hyphenateFromCodes(uint8_t* result, const uint16_t* codes, size_t len) {
    const Header* header = getHeader();
    const Trie* trie = header->trieTable();
    const Pattern* pattern = header->patternTable();
    uint32_t char_mask = trie->char_mask;
    uint32_t link_shift = trie->link_shift;
    uint32_t link_mask = trie->link_mask;
    uint32_t pattern_shift = trie->pattern_shift;
    size_t maxOffset = len - MIN_SUFFIX - 1;
    for (size_t i = 0; i < len - 1; i++) {
        uint32_t node = 0;  // index into Trie table
        for (size_t j = i; j < len; j++) {
            uint16_t c = codes[j];
            uint32_t entry = trie->data[node + c];
            if ((entry & char_mask) == c) {
                node = (entry & link_mask) >> link_shift;
            } else {
                break;
            }
            uint32_t pat_ix = trie->data[node] >> pattern_shift;
            // pat_ix contains a 3-tuple of length, shift (number of trailing zeros), and an offset
            // into the buf pool. This is the pattern for the substring (i..j) we just matched,
            // which we combine (via point-wise max) into the result vector.
            if (pat_ix != 0) {
                uint32_t pat_entry = pattern->data[pat_ix];
                int pat_len = Pattern::len(pat_entry);
                int pat_shift = Pattern::shift(pat_entry);
                const uint8_t* pat_buf = pattern->buf(pat_entry);
                int offset = j + 1 - (pat_len + pat_shift);
                // offset is the index within result that lines up with the start of pat_buf
                int start = std::max(MIN_PREFIX - offset, 0);
                int end = std::min(pat_len, (int)maxOffset - offset);
                for (int k = start; k < end; k++) {
                    result[offset + k] = std::max(result[offset + k], pat_buf[k]);
                }
            }
        }
    }
    // Since the above calculation does not modify values outside
    // [MIN_PREFIX, len - MIN_SUFFIX], they are left as 0.
    for (size_t i = MIN_PREFIX; i < maxOffset; i++) {
        result[i] &= 1;
    }
}

}  // namespace android
