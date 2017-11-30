/*
 * Copyright (C) 2013 The Android Open Source Project
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

// Determine coverage of font given its raw "cmap" OpenType table

#define LOG_TAG "Minikin"

#include <vector>
using std::vector;

#include <log/log.h>

#include <minikin/CmapCoverage.h>
#include <minikin/SparseBitSet.h>
#include "MinikinInternal.h"

namespace minikin {

// These could perhaps be optimized to use __builtin_bswap16 and friends.
static uint32_t readU16(const uint8_t* data, size_t offset) {
  return ((uint32_t)data[offset]) << 8 | ((uint32_t)data[offset + 1]);
}

static uint32_t readU32(const uint8_t* data, size_t offset) {
  return ((uint32_t)data[offset]) << 24 | ((uint32_t)data[offset + 1]) << 16 |
         ((uint32_t)data[offset + 2]) << 8 | ((uint32_t)data[offset + 3]);
}

static void addRange(vector<uint32_t>& coverage, uint32_t start, uint32_t end) {
#ifdef VERBOSE_DEBUG
  ALOGD("adding range %d-%d\n", start, end);
#endif
  if (coverage.empty() || coverage.back() < start) {
    coverage.push_back(start);
    coverage.push_back(end);
  } else {
    coverage.back() = end;
  }
}

// Get the coverage information out of a Format 4 subtable, storing it in the
// coverage vector
static bool getCoverageFormat4(vector<uint32_t>& coverage,
                               const uint8_t* data,
                               size_t size) {
  const size_t kSegCountOffset = 6;
  const size_t kEndCountOffset = 14;
  const size_t kHeaderSize = 16;
  const size_t kSegmentSize =
      8;  // total size of array elements for one segment
  if (kEndCountOffset > size) {
    return false;
  }
  size_t segCount = readU16(data, kSegCountOffset) >> 1;
  if (kHeaderSize + segCount * kSegmentSize > size) {
    return false;
  }
  for (size_t i = 0; i < segCount; i++) {
    uint32_t end = readU16(data, kEndCountOffset + 2 * i);
    uint32_t start = readU16(data, kHeaderSize + 2 * (segCount + i));
    if (end < start) {
      // invalid segment range: size must be positive
      android_errorWriteLog(0x534e4554, "26413177");
      return false;
    }
    uint32_t rangeOffset = readU16(data, kHeaderSize + 2 * (3 * segCount + i));
    if (rangeOffset == 0) {
      uint32_t delta = readU16(data, kHeaderSize + 2 * (2 * segCount + i));
      if (((end + delta) & 0xffff) > end - start) {
        addRange(coverage, start, end + 1);
      } else {
        for (uint32_t j = start; j < end + 1; j++) {
          if (((j + delta) & 0xffff) != 0) {
            addRange(coverage, j, j + 1);
          }
        }
      }
    } else {
      for (uint32_t j = start; j < end + 1; j++) {
        uint32_t actualRangeOffset =
            kHeaderSize + 6 * segCount + rangeOffset + (i + j - start) * 2;
        if (actualRangeOffset + 2 > size) {
          // invalid rangeOffset is considered a "warning" by OpenType Sanitizer
          continue;
        }
        uint32_t glyphId = readU16(data, actualRangeOffset);
        if (glyphId != 0) {
          addRange(coverage, j, j + 1);
        }
      }
    }
  }
  return true;
}

// Get the coverage information out of a Format 12 subtable, storing it in the
// coverage vector
static bool getCoverageFormat12(vector<uint32_t>& coverage,
                                const uint8_t* data,
                                size_t size) {
  const size_t kNGroupsOffset = 12;
  const size_t kFirstGroupOffset = 16;
  const size_t kGroupSize = 12;
  const size_t kStartCharCodeOffset = 0;
  const size_t kEndCharCodeOffset = 4;
  const size_t kMaxNGroups =
      0xfffffff0 / kGroupSize;  // protection against overflow
  // For all values < kMaxNGroups, kFirstGroupOffset + nGroups * kGroupSize fits
  // in 32 bits.
  if (kFirstGroupOffset > size) {
    return false;
  }
  uint32_t nGroups = readU32(data, kNGroupsOffset);
  if (nGroups >= kMaxNGroups ||
      kFirstGroupOffset + nGroups * kGroupSize > size) {
    android_errorWriteLog(0x534e4554, "25645298");
    return false;
  }
  for (uint32_t i = 0; i < nGroups; i++) {
    uint32_t groupOffset = kFirstGroupOffset + i * kGroupSize;
    uint32_t start = readU32(data, groupOffset + kStartCharCodeOffset);
    uint32_t end = readU32(data, groupOffset + kEndCharCodeOffset);
    if (end < start) {
      // invalid group range: size must be positive
      android_errorWriteLog(0x534e4554, "26413177");
      return false;
    }

    // No need to read outside of Unicode code point range.
    if (start > MAX_UNICODE_CODE_POINT) {
      return true;
    }
    if (end > MAX_UNICODE_CODE_POINT) {
      // file is inclusive, vector is exclusive
      addRange(coverage, start, MAX_UNICODE_CODE_POINT + 1);
      return true;
    }
    addRange(coverage, start,
             end + 1);  // file is inclusive, vector is exclusive
  }
  return true;
}

// Lower value has higher priority. 0 for the highest priority table.
// kLowestPriority for unsupported tables.
// This order comes from HarfBuzz's hb-ot-font.cc and needs to be kept in sync
// with it.
constexpr uint8_t kLowestPriority = 255;
uint8_t getTablePriority(uint16_t platformId, uint16_t encodingId) {
  if (platformId == 3 && encodingId == 10) {
    return 0;
  }
  if (platformId == 0 && encodingId == 6) {
    return 1;
  }
  if (platformId == 0 && encodingId == 4) {
    return 2;
  }
  if (platformId == 3 && encodingId == 1) {
    return 3;
  }
  if (platformId == 0 && encodingId == 3) {
    return 4;
  }
  if (platformId == 0 && encodingId == 2) {
    return 5;
  }
  if (platformId == 0 && encodingId == 1) {
    return 6;
  }
  if (platformId == 0 && encodingId == 0) {
    return 7;
  }
  // Tables other than above are not supported.
  return kLowestPriority;
}

SparseBitSet CmapCoverage::getCoverage(const uint8_t* cmap_data,
                                       size_t cmap_size,
                                       bool* has_cmap_format14_subtable) {
  constexpr size_t kHeaderSize = 4;
  constexpr size_t kNumTablesOffset = 2;
  constexpr size_t kTableSize = 8;
  constexpr size_t kPlatformIdOffset = 0;
  constexpr size_t kEncodingIdOffset = 2;
  constexpr size_t kOffsetOffset = 4;
  constexpr size_t kFormatOffset = 0;
  constexpr uint32_t kInvalidOffset = UINT32_MAX;

  if (kHeaderSize > cmap_size) {
    return SparseBitSet();
  }
  uint32_t numTables = readU16(cmap_data, kNumTablesOffset);
  if (kHeaderSize + numTables * kTableSize > cmap_size) {
    return SparseBitSet();
  }

  uint32_t bestTableOffset = kInvalidOffset;
  uint16_t bestTableFormat = 0;
  uint8_t bestTablePriority = kLowestPriority;
  *has_cmap_format14_subtable = false;
  for (uint32_t i = 0; i < numTables; ++i) {
    const uint32_t tableHeadOffset = kHeaderSize + i * kTableSize;
    const uint16_t platformId =
        readU16(cmap_data, tableHeadOffset + kPlatformIdOffset);
    const uint16_t encodingId =
        readU16(cmap_data, tableHeadOffset + kEncodingIdOffset);
    const uint32_t offset = readU32(cmap_data, tableHeadOffset + kOffsetOffset);

    if (offset > cmap_size - 2) {
      continue;  // Invalid table: not enough space to read.
    }
    const uint16_t format = readU16(cmap_data, offset + kFormatOffset);

    if (platformId == 0 /* Unicode */ &&
        encodingId == 5 /* Variation Sequences */) {
      if (!(*has_cmap_format14_subtable) && format == 14) {
        *has_cmap_format14_subtable = true;
      } else {
        // Ignore the (0, 5) table if we have already seen another valid one or
        // it's in a format we don't understand.
      }
    } else {
      uint32_t length;
      uint32_t language;

      if (format == 4) {
        constexpr size_t lengthOffset = 2;
        constexpr size_t languageOffset = 4;
        constexpr size_t minTableSize = languageOffset + 2;
        if (offset > cmap_size - minTableSize) {
          continue;  // Invalid table: not enough space to read.
        }
        length = readU16(cmap_data, offset + lengthOffset);
        language = readU16(cmap_data, offset + languageOffset);
      } else if (format == 12) {
        constexpr size_t lengthOffset = 4;
        constexpr size_t languageOffset = 8;
        constexpr size_t minTableSize = languageOffset + 4;
        if (offset > cmap_size - minTableSize) {
          continue;  // Invalid table: not enough space to read.
        }
        length = readU32(cmap_data, offset + lengthOffset);
        language = readU32(cmap_data, offset + languageOffset);
      } else {
        continue;
      }

      if (length > cmap_size - offset) {
        continue;  // Invalid table: table length is larger than whole cmap data
                   // size.
      }
      if (language != 0) {
        // Unsupported or invalid table: this is either a subtable for the
        // Macintosh platform (which we don't support), or an invalid subtable
        // since language field should be zero for non-Macintosh subtables.
        continue;
      }
      const uint8_t priority = getTablePriority(platformId, encodingId);
      if (priority < bestTablePriority) {
        bestTableOffset = offset;
        bestTablePriority = priority;
        bestTableFormat = format;
      }
    }
    if (*has_cmap_format14_subtable &&
        bestTablePriority == 0 /* highest priority */) {
      // Already found the highest priority table and variation sequences table.
      // No need to look at remaining tables.
      break;
    }
  }
  if (bestTableOffset == kInvalidOffset) {
    return SparseBitSet();
  }
  const uint8_t* tableData = cmap_data + bestTableOffset;
  const size_t tableSize = cmap_size - bestTableOffset;
  vector<uint32_t> coverageVec;
  bool success;
  if (bestTableFormat == 4) {
    success = getCoverageFormat4(coverageVec, tableData, tableSize);
  } else {
    success = getCoverageFormat12(coverageVec, tableData, tableSize);
  }
  if (success && (coverageVec.size() != 0)) {
    return SparseBitSet(&coverageVec.front(), coverageVec.size() >> 1);
  } else {
    return SparseBitSet();
  }
}

}  // namespace minikin
