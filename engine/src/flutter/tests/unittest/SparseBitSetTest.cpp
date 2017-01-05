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

#include <random>

#include <gtest/gtest.h>
#include <minikin/SparseBitSet.h>

namespace minikin {

TEST(SparseBitSetTest, randomTest) {
    const uint32_t kTestRangeNum = 4096;

    std::mt19937 mt;  // Fix seeds to be able to reproduce the result.
    std::uniform_int_distribution<uint16_t> distribution(1, 512);

    std::vector<uint32_t> range { distribution(mt) };
    for (size_t i = 1; i < kTestRangeNum * 2; ++i) {
        range.push_back((range.back() - 1) + distribution(mt));
    }

    SparseBitSet bitset;
    bitset.initFromRanges(range.data(), range.size() / 2);

    uint32_t ch = 0;
    for (size_t i = 0; i < range.size() / 2; ++i) {
        uint32_t start = range[i * 2];
        uint32_t end = range[i * 2 + 1];

        for (; ch < start; ch++) {
            ASSERT_FALSE(bitset.get(ch)) << std::hex << ch;
        }
        for (; ch < end; ch++) {
            ASSERT_TRUE(bitset.get(ch)) << std::hex << ch;
        }
    }
    for (; ch < 0x1FFFFFF; ++ch) {
        ASSERT_FALSE(bitset.get(ch)) << std::hex << ch;
    }
}

TEST(SparseBitSetTest, randomTest_restoredFromBuffer) {
    const uint32_t kTestRangeNum = 4096;

    std::mt19937 mt;  // Fix seeds to be able to reproduce the result.
    std::uniform_int_distribution<uint16_t> distribution(1, 512);

    std::vector<uint32_t> range { distribution(mt) };
    for (size_t i = 1; i < kTestRangeNum * 2; ++i) {
        range.push_back((range.back() - 1) + distribution(mt));
    }

    SparseBitSet tmpBitset;
    tmpBitset.initFromRanges(range.data(), range.size() / 2);

    size_t bufSize = tmpBitset.writeToBuffer(nullptr);
    ASSERT_NE(0U, bufSize);
    std::vector<uint8_t> buffer(bufSize);
    tmpBitset.writeToBuffer(buffer.data());

    SparseBitSet bitset;
    bitset.initFromBuffer(buffer.data(), buffer.size());

    uint32_t ch = 0;
    for (size_t i = 0; i < range.size() / 2; ++i) {
        uint32_t start = range[i * 2];
        uint32_t end = range[i * 2 + 1];

        for (; ch < start; ch++) {
            ASSERT_FALSE(bitset.get(ch)) << std::hex << ch;
        }
        for (; ch < end; ch++) {
            ASSERT_TRUE(bitset.get(ch)) << std::hex << ch;
        }
    }
    for (; ch < 0x1FFFFFF; ++ch) {
        ASSERT_FALSE(bitset.get(ch)) << std::hex << ch;
    }
}

TEST(SparseBitSetTest, emptyBitSet) {
    SparseBitSet bitset;
    uint32_t empty_bitset[4] = {
        0 /* max value */, 0 /* zero page index */, 0 /* index size */, 0 /* bitmap size */
    };
    EXPECT_TRUE(bitset.initFromBuffer(
            reinterpret_cast<uint8_t*>(empty_bitset), sizeof(empty_bitset)));
}

TEST(SparseBitSetTest, invalidData) {
    SparseBitSet bitset;
    EXPECT_FALSE(bitset.initFromBuffer(nullptr, 0));

    // Buffer is too small.
    uint32_t small_buffer[3] = { 0, 0, 0 };
    EXPECT_FALSE(bitset.initFromBuffer(
            reinterpret_cast<uint8_t*>(small_buffer), sizeof(small_buffer)));

    // Buffer size does not match with necessary size.
    uint32_t invalid_size_buffer[4] = {
        0x12345678 /* max value */, 0 /* zero page index */, 0x50 /* index size*/,
        0x80 /* bitmap size */
    };
    EXPECT_FALSE(bitset.initFromBuffer(
            reinterpret_cast<uint8_t*>(invalid_size_buffer), sizeof(invalid_size_buffer)));

    // max value, index size, bitmap size must be zero if the bitset is empty.
    uint32_t invalid_empty_bitset1[4] = {
        1 /* max value */, 0 /* zero page index */, 0 /* index size */, 0 /* bitmap size */
    };
    EXPECT_FALSE(bitset.initFromBuffer(
            reinterpret_cast<uint8_t*>(invalid_empty_bitset1), sizeof(invalid_empty_bitset1)));

    uint32_t invalid_empty_bitset2[4] = {
        0 /* max value */, 0 /* zero page index */, 1 /* index size */, 0 /* bitmap size */
    };
    EXPECT_FALSE(bitset.initFromBuffer(
            reinterpret_cast<uint8_t*>(invalid_empty_bitset2), sizeof(invalid_empty_bitset2)));

    uint32_t invalid_empty_bitset3[4] = {
        0 /* max value */, 0 /* zero page index */, 0 /* index size */, 1 /* bitmap size */
    };
    EXPECT_FALSE(bitset.initFromBuffer(
            reinterpret_cast<uint8_t*>(invalid_empty_bitset3), sizeof(invalid_empty_bitset3)));
}

}  // namespace minikin
