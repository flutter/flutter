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

/**
 * An implementation of Liang's hyphenation algorithm.
 */

#include <memory>
#include <unordered_map>

#ifndef MINIKIN_HYPHENATOR_H
#define MINIKIN_HYPHENATOR_H

namespace android {

// hyb file header; implementation details are in the .cpp file
struct Header;

class Hyphenator {
public:
    // Note: this will also require a locale, for proper case folding behavior
    static Hyphenator* load(const uint16_t* patternData, size_t size);

    // Compute the hyphenation of a word, storing the hyphenation in result vector. Each
    // entry in the vector is a "hyphen edit" to be applied at the corresponding code unit
    // offset in the word. Currently 0 means no hyphen and 1 means insert hyphen and break,
    // but this will be expanded to other edits for nonstandard hyphenation.
    // Example: word is "hyphen", result is [0 0 1 0 0 0], corresponding to "hy-phen".
    void hyphenate(std::vector<uint8_t>* result, const uint16_t* word, size_t len);

    // pattern data is in binary format, as described in doc/hyb_file_format.md. Note:
    // the caller is responsible for ensuring that the lifetime of the pattern data is
    // at least as long as the Hyphenator object.

    // Note: nullptr is valid input, in which case the hyphenator only processes soft hyphens
    static Hyphenator* loadBinary(const uint8_t* patternData);

private:
    // apply soft hyphens only, ignoring patterns
    void hyphenateSoft(uint8_t* result, const uint16_t* word, size_t len);

    // try looking up word in alphabet table, return false if any code units fail to map
    // Note that this methor writes len+2 entries into alpha_codes (including start and stop)
    bool alphabetLookup(uint16_t* alpha_codes, const uint16_t* word, size_t len);

    // calculate hyphenation from patterns, assuming alphabet lookup has already been done
    void hyphenateFromCodes(uint8_t* result, const uint16_t* codes, size_t len);

    // TODO: these should become parameters, as they might vary by locale, screen size, and
    // possibly explicit user control.
    static const int MIN_PREFIX = 2;
    static const int MIN_SUFFIX = 3;

    // See also LONGEST_HYPHENATED_WORD in LineBreaker.cpp. Here the constant is used so
    // that temporary buffers can be stack-allocated without waste, which is a slightly
    // different use case. It measures UTF-16 code units.
    static const size_t MAX_HYPHENATED_SIZE = 64;

    const uint8_t* patternData;

    // accessors for binary data
    const Header* getHeader() const {
        return reinterpret_cast<const Header*>(patternData);
    }

};

}  // namespace android

#endif   // MINIKIN_HYPHENATOR_H
