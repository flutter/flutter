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

#include <stdlib.h>
#include <stdint.h>

#include <minikin/AnalyzeStyle.h>

namespace minikin {

// should  we have a single FontAnalyzer class this stuff lives in, to avoid dup?
static int32_t readU16(const uint8_t* data, size_t offset) {
    return data[offset] << 8 | data[offset + 1];
}

bool analyzeStyle(const uint8_t* os2_data, size_t os2_size, int* weight, bool* italic) {
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

}  // namespace minikin
