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

#include <stdint.h>
#include <stdlib.h>

#include "FontUtils.h"

namespace minikin {

static uint16_t readU16(const uint8_t* data, size_t offset) {
  return data[offset] << 8 | data[offset + 1];
}

static uint32_t readU32(const uint8_t* data, size_t offset) {
  return ((uint32_t)data[offset]) << 24 | ((uint32_t)data[offset + 1]) << 16 |
         ((uint32_t)data[offset + 2]) << 8 | ((uint32_t)data[offset + 3]);
}

bool analyzeStyle(const uint8_t* os2_data,
                  size_t os2_size,
                  int* weight,
                  bool* italic) {
  const size_t kUsWeightClassOffset = 4;
  const size_t kFsSelectionOffset = 62;
  const uint16_t kItalicFlag = (1 << 0);
  if (os2_size < kFsSelectionOffset + 2) {
    return false;
  }
  uint16_t weightClass = readU16(os2_data, kUsWeightClassOffset);
  *weight = weightClass / 100;
  uint16_t fsSelection = readU16(os2_data, kFsSelectionOffset);
  *italic = (fsSelection & kItalicFlag) != 0;
  return true;
}

void analyzeAxes(const uint8_t* fvar_data,
                 size_t fvar_size,
                 std::unordered_set<uint32_t>* axes) {
  const size_t kMajorVersionOffset = 0;
  const size_t kMinorVersionOffset = 2;
  const size_t kOffsetToAxesArrayOffset = 4;
  const size_t kAxisCountOffset = 8;
  const size_t kAxisSizeOffset = 10;

  axes->clear();

  if (fvar_size < kAxisSizeOffset + 2) {
    return;
  }
  const uint16_t majorVersion = readU16(fvar_data, kMajorVersionOffset);
  const uint16_t minorVersion = readU16(fvar_data, kMinorVersionOffset);
  const uint32_t axisOffset = readU16(fvar_data, kOffsetToAxesArrayOffset);
  const uint32_t axisCount = readU16(fvar_data, kAxisCountOffset);
  const uint32_t axisSize = readU16(fvar_data, kAxisSizeOffset);

  if (majorVersion != 1 || minorVersion != 0 || axisOffset != 0x10 ||
      axisSize != 0x14) {
    return;  // Unsupported version.
  }
  if (fvar_size < axisOffset + axisOffset * axisCount) {
    return;  // Invalid table size.
  }
  for (uint32_t i = 0; i < axisCount; ++i) {
    size_t axisRecordOffset = axisOffset + i * axisSize;
    uint32_t tag = readU32(fvar_data, axisRecordOffset);
    axes->insert(tag);
  }
}
}  // namespace minikin
