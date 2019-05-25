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
#include <log/log.h>
#include <minikin/CmapCoverage.h>
#include <minikin/SparseBitSet.h>
#include <utils/WindowsUtils.h>

namespace minikin {

size_t writeU16(uint16_t x, uint8_t* out, size_t offset) {
  out[offset] = x >> 8;
  out[offset + 1] = x;
  return offset + 2;
}

size_t writeI16(int16_t sx, uint8_t* out, size_t offset) {
  return writeU16(static_cast<uint16_t>(sx), out, offset);
}

size_t writeU32(uint32_t x, uint8_t* out, size_t offset) {
  out[offset] = x >> 24;
  out[offset + 1] = x >> 16;
  out[offset + 2] = x >> 8;
  out[offset + 3] = x;
  return offset + 4;
}

// Returns valid cmap format 4 table contents. All glyph ID is same value as
// code point. (e.g. 'a' (U+0061) is mapped to Glyph ID = 0x0061). 'range'
// should be specified with inclusive-inclusive values.
static std::vector<uint8_t> buildCmapFormat4Table(
    const std::vector<uint16_t>& ranges) {
  uint16_t segmentCount = ranges.size() / 2 + 1 /* +1 for end marker */;

  const size_t numOfUint16 =
      8 /* format, length, languages, segCountX2, searchRange, entrySelector,
           rangeShift, pad */
      + segmentCount * 4 /* endCount, startCount, idRange, idRangeOffset */;
  const size_t finalLength = sizeof(uint16_t) * numOfUint16;

  std::vector<uint8_t> out(finalLength);
  size_t head = 0;
  head = writeU16(4, out.data(), head);            // format
  head = writeU16(finalLength, out.data(), head);  // length
  head = writeU16(0, out.data(), head);            // language

  const uint16_t searchRange =
      2 * (1 << static_cast<int>(floor(log2(segmentCount))));

  head = writeU16(segmentCount * 2, out.data(), head);  // segCountX2
  head = writeU16(searchRange, out.data(), head);       // searchRange
#if defined(_WIN32)
  head = writeU16(ctz_win(searchRange) - 1, out.data(), head);
#else
  head = writeU16(__builtin_ctz(searchRange) - 1, out.data(),
                  head);  // entrySelector
#endif
  head =
      writeU16(segmentCount * 2 - searchRange, out.data(), head);  // rangeShift

  size_t endCountHead = head;
  size_t startCountHead =
      head + segmentCount * sizeof(uint16_t) + 2 /* padding */;
  size_t idDeltaHead = startCountHead + segmentCount * sizeof(uint16_t);
  size_t idRangeOffsetHead = idDeltaHead + segmentCount * sizeof(uint16_t);

  for (size_t i = 0; i < ranges.size() / 2; ++i) {
    const uint16_t begin = ranges[i * 2];
    const uint16_t end = ranges[i * 2 + 1];
    startCountHead = writeU16(begin, out.data(), startCountHead);
    endCountHead = writeU16(end, out.data(), endCountHead);
    // map glyph ID as the same value of the code point.
    idDeltaHead = writeU16(0, out.data(), idDeltaHead);
    idRangeOffsetHead =
        writeU16(0 /* we don't use this */, out.data(), idRangeOffsetHead);
  }

  // fill end marker
  endCountHead = writeU16(0xFFFF, out.data(), endCountHead);
  startCountHead = writeU16(0xFFFF, out.data(), startCountHead);
  idDeltaHead = writeU16(1, out.data(), idDeltaHead);
  idRangeOffsetHead = writeU16(0, out.data(), idRangeOffsetHead);
  LOG_ALWAYS_FATAL_IF(endCountHead > finalLength);
  LOG_ALWAYS_FATAL_IF(startCountHead > finalLength);
  LOG_ALWAYS_FATAL_IF(idDeltaHead > finalLength);
  LOG_ALWAYS_FATAL_IF(idRangeOffsetHead != finalLength);
  return out;
}

// Returns valid cmap format 4 table contents. All glyph ID is same value as
// code point. (e.g. 'a' (U+0061) is mapped to Glyph ID = 0x0061). 'range'
// should be specified with inclusive-inclusive values.
static std::vector<uint8_t> buildCmapFormat12Table(
    const std::vector<uint32_t>& ranges) {
  uint32_t numGroups = ranges.size() / 2;

  const size_t finalLength =
      2 /* format */ + 2 /* reserved */ + 4 /* length */ + 4 /* languages */ +
      4 /* numGroups */ + 12 /* size of a group */ * numGroups;

  std::vector<uint8_t> out(finalLength);
  size_t head = 0;
  head = writeU16(12, out.data(), head);           // format
  head = writeU16(0, out.data(), head);            // reserved
  head = writeU32(finalLength, out.data(), head);  // length
  head = writeU32(0, out.data(), head);            // language
  head = writeU32(numGroups, out.data(), head);    // numGroups

  for (uint32_t i = 0; i < numGroups; ++i) {
    const uint32_t start = ranges[2 * i];
    const uint32_t end = ranges[2 * i + 1];
    head = writeU32(start, out.data(), head);
    head = writeU32(end, out.data(), head);
    // map glyph ID as the same value of the code point.
    // TODO: Use glyph IDs lower than 65535.
    // Cmap can store 32 bit glyph ID but due to the size of numGlyph, a font
    // file can contain up to 65535 glyphs in a file.
    head = writeU32(start, out.data(), head);
  }

  LOG_ALWAYS_FATAL_IF(head != finalLength);
  return out;
}

class CmapBuilder {
 public:
  static constexpr size_t kEncodingTableHead = 4;
  static constexpr size_t kEncodingTableSize = 8;

  CmapBuilder(int numTables) : mNumTables(numTables), mCurrentTableIndex(0) {
    const size_t headerSize =
        2 /* version */ + 2 /* numTables */ + kEncodingTableSize * numTables;
    out.resize(headerSize);
    writeU16(0, out.data(), 0);
    writeU16(numTables, out.data(), 2);
  }

  void appendTable(uint16_t platformId,
                   uint16_t encodingId,
                   const std::vector<uint8_t>& table) {
    appendEncodingTable(platformId, encodingId, out.size());
    out.insert(out.end(), table.begin(), table.end());
  }

  // TODO: Introduce Format 14 table builder.

  std::vector<uint8_t> build() {
    LOG_ALWAYS_FATAL_IF(mCurrentTableIndex != mNumTables);
    return out;
  }

  // Helper functions.
  static std::vector<uint8_t> buildSingleFormat4Cmap(
      uint16_t platformId,
      uint16_t encodingId,
      const std::vector<uint16_t>& ranges) {
    CmapBuilder builder(1);
    builder.appendTable(platformId, encodingId, buildCmapFormat4Table(ranges));
    return builder.build();
  }

  static std::vector<uint8_t> buildSingleFormat12Cmap(
      uint16_t platformId,
      uint16_t encodingId,
      const std::vector<uint32_t>& ranges) {
    CmapBuilder builder(1);
    builder.appendTable(platformId, encodingId, buildCmapFormat12Table(ranges));
    return builder.build();
  }

 private:
  void appendEncodingTable(uint16_t platformId,
                           uint16_t encodingId,
                           uint32_t offset) {
    LOG_ALWAYS_FATAL_IF(mCurrentTableIndex == mNumTables);

    const size_t currentEncodingTableHead =
        kEncodingTableHead + mCurrentTableIndex * kEncodingTableSize;
    size_t head = writeU16(platformId, out.data(), currentEncodingTableHead);
    head = writeU16(encodingId, out.data(), head);
    head = writeU32(offset, out.data(), head);
    LOG_ALWAYS_FATAL_IF((head - currentEncodingTableHead) !=
                        kEncodingTableSize);
    mCurrentTableIndex++;
  }

  int mNumTables;
  int mCurrentTableIndex;
  std::vector<uint8_t> out;
};

TEST(CmapCoverageTest, SingleFormat4_brokenCmap) {
  bool has_cmap_format_14_subtable = false;
  {
    SCOPED_TRACE("Reading beyond buffer size - Too small cmap size");
    std::vector<uint8_t> cmap = CmapBuilder::buildSingleFormat4Cmap(
        0, 0, std::vector<uint16_t>({'a', 'a'}));

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), 3 /* too small */, &has_cmap_format_14_subtable);
    EXPECT_EQ(0U, coverage.length());
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
  {
    SCOPED_TRACE(
        "Reading beyond buffer size - space needed for tables goes beyond cmap "
        "size");
    std::vector<uint8_t> cmap = CmapBuilder::buildSingleFormat4Cmap(
        0, 0, std::vector<uint16_t>({'a', 'a'}));

    writeU16(1000, cmap.data(), 2 /* offset of num tables in cmap header */);
    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_EQ(0U, coverage.length());
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
  {
    SCOPED_TRACE(
        "Reading beyond buffer size - Invalid offset in encoding table");
    std::vector<uint8_t> cmap = CmapBuilder::buildSingleFormat4Cmap(
        0, 0, std::vector<uint16_t>({'a', 'a'}));

    writeU16(1000, cmap.data(),
             8 /* offset of the offset in the first encoding record */);
    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_EQ(0U, coverage.length());
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
}

TEST(CmapCoverageTest, SingleFormat4) {
  bool has_cmap_format_14_subtable = false;
  struct TestCast {
    std::string testTitle;
    uint16_t platformId;
    uint16_t encodingId;
  } TEST_CASES[] = {
      {"Platform 0, Encoding 0", 0, 0}, {"Platform 0, Encoding 1", 0, 1},
      {"Platform 0, Encoding 2", 0, 2}, {"Platform 0, Encoding 3", 0, 3},
      {"Platform 3, Encoding 1", 3, 1},
  };

  for (const auto& testCase : TEST_CASES) {
    SCOPED_TRACE(testCase.testTitle.c_str());
    std::vector<uint8_t> cmap = CmapBuilder::buildSingleFormat4Cmap(
        testCase.platformId, testCase.encodingId,
        std::vector<uint16_t>({'a', 'a'}));
    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_TRUE(coverage.get('a'));
    EXPECT_FALSE(coverage.get('b'));
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
}

TEST(CmapCoverageTest, SingleFormat12) {
  bool has_cmap_format_14_subtable = false;

  struct TestCast {
    std::string testTitle;
    uint16_t platformId;
    uint16_t encodingId;
  } TEST_CASES[] = {
      {"Platform 0, Encoding 4", 0, 4},
      {"Platform 0, Encoding 6", 0, 6},
      {"Platform 3, Encoding 10", 3, 10},
  };

  for (const auto& testCase : TEST_CASES) {
    SCOPED_TRACE(testCase.testTitle.c_str());
    std::vector<uint8_t> cmap = CmapBuilder::buildSingleFormat12Cmap(
        testCase.platformId, testCase.encodingId,
        std::vector<uint32_t>({'a', 'a'}));
    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_TRUE(coverage.get('a'));
    EXPECT_FALSE(coverage.get('b'));
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
}

TEST(CmapCoverageTest, Format12_beyondTheUnicodeLimit) {
  bool has_cmap_format_14_subtable = false;
  {
    SCOPED_TRACE(
        "Starting range is out of Unicode code point. Should be ignored.");
    std::vector<uint8_t> cmap = CmapBuilder::buildSingleFormat12Cmap(
        0, 0, std::vector<uint32_t>({'a', 'a', 0x110000, 0x110000}));

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_TRUE(coverage.get('a'));
    EXPECT_FALSE(coverage.get(0x110000));
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
  {
    SCOPED_TRACE(
        "Ending range is out of Unicode code point. Should be ignored.");
    std::vector<uint8_t> cmap = CmapBuilder::buildSingleFormat12Cmap(
        0, 0, std::vector<uint32_t>({'a', 'a', 0x10FF00, 0x110000}));

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_TRUE(coverage.get('a'));
    EXPECT_TRUE(coverage.get(0x10FF00));
    EXPECT_TRUE(coverage.get(0x10FFFF));
    EXPECT_FALSE(coverage.get(0x110000));
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
}

TEST(CmapCoverageTest, notSupportedEncodings) {
  bool has_cmap_format_14_subtable = false;

  struct TestCast {
    std::string testTitle;
    uint16_t platformId;
    uint16_t encodingId;
  } TEST_CASES[] = {
      // Any encodings with platform 2 is not supported.
      {"Platform 2, Encoding 0", 2, 0},
      {"Platform 2, Encoding 1", 2, 1},
      {"Platform 2, Encoding 2", 2, 2},
      {"Platform 2, Encoding 3", 2, 3},
      // UCS-2 or UCS-4 are supported on Platform == 3. Others are not
      // supported.
      {"Platform 3, Encoding 0", 3, 0},  // Symbol
      {"Platform 3, Encoding 2", 3, 2},  // ShiftJIS
      {"Platform 3, Encoding 3", 3, 3},  // RPC
      {"Platform 3, Encoding 4", 3, 4},  // Big5
      {"Platform 3, Encoding 5", 3, 5},  // Wansung
      {"Platform 3, Encoding 6", 3, 6},  // Johab
      {"Platform 3, Encoding 7", 3, 7},  // Reserved
      {"Platform 3, Encoding 8", 3, 8},  // Reserved
      {"Platform 3, Encoding 9", 3, 9},  // Reserved
      // Uknown platforms
      {"Platform 4, Encoding 0", 4, 0},
      {"Platform 5, Encoding 1", 5, 1},
      {"Platform 6, Encoding 0", 6, 0},
      {"Platform 7, Encoding 1", 7, 1},
  };

  for (const auto& testCase : TEST_CASES) {
    SCOPED_TRACE(testCase.testTitle.c_str());
    CmapBuilder builder(1);
    std::vector<uint8_t> cmap = CmapBuilder::buildSingleFormat4Cmap(
        testCase.platformId, testCase.encodingId,
        std::vector<uint16_t>({'a', 'a'}));
    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_EQ(0U, coverage.length());
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
}

TEST(CmapCoverageTest, brokenFormat4Table) {
  bool has_cmap_format_14_subtable = false;
  {
    SCOPED_TRACE("Too small table cmap size");
    std::vector<uint8_t> table =
        buildCmapFormat4Table(std::vector<uint16_t>({'a', 'a'}));
    table.resize(2);  // Remove trailing data.

    CmapBuilder builder(1);
    builder.appendTable(0, 0, table);
    std::vector<uint8_t> cmap = builder.build();

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_EQ(0U, coverage.length());
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
  {
    SCOPED_TRACE("Too many segments");
    std::vector<uint8_t> table =
        buildCmapFormat4Table(std::vector<uint16_t>({'a', 'a'}));
    writeU16(5000, table.data(),
             6 /* segment count offset */);  // 5000 segments.
    CmapBuilder builder(1);
    builder.appendTable(0, 0, table);
    std::vector<uint8_t> cmap = builder.build();

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_EQ(0U, coverage.length());
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
  {
    SCOPED_TRACE("Inversed range");
    std::vector<uint8_t> table =
        buildCmapFormat4Table(std::vector<uint16_t>({'b', 'b'}));
    // Put smaller end code point to inverse the range.
    writeU16('a', table.data(), 14 /* the first element of endCount offset */);
    CmapBuilder builder(1);
    builder.appendTable(0, 0, table);
    std::vector<uint8_t> cmap = builder.build();

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_EQ(0U, coverage.length());
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
}

TEST(CmapCoverageTest, brokenFormat12Table) {
  bool has_cmap_format_14_subtable = false;
  {
    SCOPED_TRACE("Too small cmap size");
    std::vector<uint8_t> table =
        buildCmapFormat12Table(std::vector<uint32_t>({'a', 'a'}));
    table.resize(2);  // Remove trailing data.

    CmapBuilder builder(1);
    builder.appendTable(0, 0, table);
    std::vector<uint8_t> cmap = builder.build();

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_EQ(0U, coverage.length());
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
  {
    SCOPED_TRACE("Too many groups");
    std::vector<uint8_t> table =
        buildCmapFormat12Table(std::vector<uint32_t>({'a', 'a'}));
    writeU32(5000, table.data(), 12 /* num group offset */);  // 5000 groups.

    CmapBuilder builder(1);
    builder.appendTable(0, 0, table);
    std::vector<uint8_t> cmap = builder.build();

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_EQ(0U, coverage.length());
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
  {
    SCOPED_TRACE("Inversed range.");
    std::vector<uint8_t> table =
        buildCmapFormat12Table(std::vector<uint32_t>({'a', 'a'}));
    // Put larger start code point to inverse the range.
    writeU32('b', table.data(),
             16 /* start code point offset in the first  group */);

    CmapBuilder builder(1);
    builder.appendTable(0, 0, table);
    std::vector<uint8_t> cmap = builder.build();

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_EQ(0U, coverage.length());
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
  {
    SCOPED_TRACE("Too large code point");
    std::vector<uint8_t> cmap = CmapBuilder::buildSingleFormat12Cmap(
        0, 0, std::vector<uint32_t>({0x110000, 0x110000}));

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_EQ(0U, coverage.length());
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
}

TEST(CmapCoverageTest, TableSelection_Priority) {
  bool has_cmap_format_14_subtable = false;
  std::vector<uint8_t> highestFormat12Table =
      buildCmapFormat12Table(std::vector<uint32_t>({'a', 'a'}));
  std::vector<uint8_t> highestFormat4Table =
      buildCmapFormat4Table(std::vector<uint16_t>({'a', 'a'}));
  std::vector<uint8_t> format4 =
      buildCmapFormat4Table(std::vector<uint16_t>({'b', 'b'}));
  std::vector<uint8_t> format12 =
      buildCmapFormat12Table(std::vector<uint32_t>({'b', 'b'}));

  {
    SCOPED_TRACE("(platform, encoding) = (3, 10) is the highest priority.");

    struct LowerPriorityTable {
      uint16_t platformId;
      uint16_t encodingId;
      const std::vector<uint8_t>& table;
    } LOWER_PRIORITY_TABLES[] = {
        {0, 0, format4},  {0, 1, format4},  {0, 2, format4}, {0, 3, format4},
        {0, 4, format12}, {0, 6, format12}, {3, 1, format4},
    };

    for (const auto& table : LOWER_PRIORITY_TABLES) {
      CmapBuilder builder(2);
      builder.appendTable(table.platformId, table.encodingId, table.table);
      builder.appendTable(3, 10, highestFormat12Table);
      std::vector<uint8_t> cmap = builder.build();

      SparseBitSet coverage = CmapCoverage::getCoverage(
          cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
      EXPECT_TRUE(coverage.get('a'));   // comes from highest table
      EXPECT_FALSE(coverage.get('b'));  // should not use other table.
      EXPECT_FALSE(has_cmap_format_14_subtable);
    }
  }
  {
    SCOPED_TRACE("(platform, encoding) = (3, 1) case");

    struct LowerPriorityTable {
      uint16_t platformId;
      uint16_t encodingId;
      const std::vector<uint8_t>& table;
    } LOWER_PRIORITY_TABLES[] = {
        {0, 0, format4},
        {0, 1, format4},
        {0, 2, format4},
        {0, 3, format4},
    };

    for (const auto& table : LOWER_PRIORITY_TABLES) {
      CmapBuilder builder(2);
      builder.appendTable(table.platformId, table.encodingId, table.table);
      builder.appendTable(3, 1, highestFormat4Table);
      std::vector<uint8_t> cmap = builder.build();

      SparseBitSet coverage = CmapCoverage::getCoverage(
          cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
      EXPECT_TRUE(coverage.get('a'));   // comes from highest table
      EXPECT_FALSE(coverage.get('b'));  // should not use other table.
      EXPECT_FALSE(has_cmap_format_14_subtable);
    }
  }
}

TEST(CmapCoverageTest, TableSelection_SkipBrokenFormat4Table) {
  SparseBitSet coverage;
  bool has_cmap_format_14_subtable = false;
  std::vector<uint8_t> validTable =
      buildCmapFormat4Table(std::vector<uint16_t>({'a', 'a'}));
  {
    SCOPED_TRACE("Unsupported format");
    CmapBuilder builder(2);
    std::vector<uint8_t> table =
        buildCmapFormat4Table(std::vector<uint16_t>({'b', 'b'}));
    writeU16(0, table.data(), 0 /* format offset */);
    builder.appendTable(3, 1, table);
    builder.appendTable(0, 0, validTable);
    std::vector<uint8_t> cmap = builder.build();

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_TRUE(coverage.get('a'));   // comes from valid table
    EXPECT_FALSE(coverage.get('b'));  // should not use invalid table.
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
  {
    SCOPED_TRACE("Invalid language");
    CmapBuilder builder(2);
    std::vector<uint8_t> table =
        buildCmapFormat4Table(std::vector<uint16_t>({'b', 'b'}));
    writeU16(1, table.data(), 4 /* language offset */);
    builder.appendTable(3, 1, table);
    builder.appendTable(0, 0, validTable);
    std::vector<uint8_t> cmap = builder.build();

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_TRUE(coverage.get('a'));   // comes from valid table
    EXPECT_FALSE(coverage.get('b'));  // should not use invalid table.
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
  {
    SCOPED_TRACE("Invalid length");
    CmapBuilder builder(2);
    std::vector<uint8_t> table =
        buildCmapFormat4Table(std::vector<uint16_t>({'b', 'b'}));
    writeU16(5000, table.data(), 2 /* length offset */);
    builder.appendTable(3, 1, table);
    builder.appendTable(0, 0, validTable);
    std::vector<uint8_t> cmap = builder.build();

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_TRUE(coverage.get('a'));   // comes from valid table
    EXPECT_FALSE(coverage.get('b'));  // should not use invalid table.
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
}

TEST(CmapCoverageTest, TableSelection_SkipBrokenFormat12Table) {
  SparseBitSet coverage;
  bool has_cmap_format_14_subtable = false;
  std::vector<uint8_t> validTable =
      buildCmapFormat12Table(std::vector<uint32_t>({'a', 'a'}));
  {
    SCOPED_TRACE("Unsupported format");
    CmapBuilder builder(2);
    std::vector<uint8_t> table =
        buildCmapFormat12Table(std::vector<uint32_t>({'b', 'b'}));
    writeU16(0, table.data(), 0 /* format offset */);
    builder.appendTable(3, 1, table);
    builder.appendTable(0, 0, validTable);
    std::vector<uint8_t> cmap = builder.build();

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_TRUE(coverage.get('a'));   // comes from valid table
    EXPECT_FALSE(coverage.get('b'));  // should not use invalid table.
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
  {
    SCOPED_TRACE("Invalid language");
    CmapBuilder builder(2);
    std::vector<uint8_t> table =
        buildCmapFormat12Table(std::vector<uint32_t>({'b', 'b'}));
    writeU32(1, table.data(), 8 /* language offset */);
    builder.appendTable(3, 1, table);
    builder.appendTable(0, 0, validTable);
    std::vector<uint8_t> cmap = builder.build();

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_TRUE(coverage.get('a'));   // comes from valid table
    EXPECT_FALSE(coverage.get('b'));  // should not use invalid table.
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
  {
    SCOPED_TRACE("Invalid length");
    CmapBuilder builder(2);
    std::vector<uint8_t> table =
        buildCmapFormat12Table(std::vector<uint32_t>({'b', 'b'}));
    writeU32(5000, table.data(), 4 /* length offset */);
    builder.appendTable(3, 1, table);
    builder.appendTable(0, 0, validTable);
    std::vector<uint8_t> cmap = builder.build();

    SparseBitSet coverage = CmapCoverage::getCoverage(
        cmap.data(), cmap.size(), &has_cmap_format_14_subtable);
    EXPECT_TRUE(coverage.get('a'));   // comes from valid table
    EXPECT_FALSE(coverage.get('b'));  // should not use invalid table.
    EXPECT_FALSE(has_cmap_format_14_subtable);
  }
}

}  // namespace minikin
