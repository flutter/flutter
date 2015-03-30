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

class Trie {
public:
    std::vector<uint8_t> result;
    std::unordered_map<uint16_t, Trie> succ;
};

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

private:
    void addPattern(const uint16_t* pattern, size_t size);

    void hyphenateSoft(std::vector<uint8_t>* result, const uint16_t* word, size_t len);

    // TODO: these should become parameters, as they might vary by locale, screen size, and
    // possibly explicit user control.
    static const int MIN_PREFIX = 2;
    static const int MIN_SUFFIX = 3;

    Trie root;
};

}  // namespace android

#endif   // MINIKIN_HYPHENATOR_H