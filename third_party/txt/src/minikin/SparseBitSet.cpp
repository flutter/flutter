/*
 * Copyright (C) 2012 The Android Open Source Project
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

#define LOG_TAG "SparseBitSet"

#include <stddef.h>
#include <string.h>

#include <log/log.h>

#include <minikin/SparseBitSet.h>
#include <utils/WindowsUtils.h>

namespace minikin {

const uint32_t SparseBitSet::kNotFound;

uint32_t SparseBitSet::calcNumPages(const uint32_t* ranges, size_t nRanges) {
  bool haveZeroPage = false;
  uint32_t nonzeroPageEnd = 0;
  uint32_t nPages = 0;
  for (size_t i = 0; i < nRanges; i++) {
    uint32_t start = ranges[i * 2];
    uint32_t end = ranges[i * 2 + 1];
    uint32_t startPage = start >> kLogValuesPerPage;
    uint32_t endPage = (end - 1) >> kLogValuesPerPage;
    if (startPage >= nonzeroPageEnd) {
      if (startPage > nonzeroPageEnd) {
        if (!haveZeroPage) {
          haveZeroPage = true;
          nPages++;
        }
      }
      nPages++;
    }
    nPages += endPage - startPage;
    nonzeroPageEnd = endPage + 1;
  }
  return nPages;
}

void SparseBitSet::initFromRanges(const uint32_t* ranges, size_t nRanges) {
  if (nRanges == 0) {
    return;
  }
  const uint32_t maxVal = ranges[nRanges * 2 - 1];
  if (maxVal >= kMaximumCapacity) {
    return;
  }
  mMaxVal = maxVal;
  mIndices.reset(new uint16_t[(mMaxVal + kPageMask) >> kLogValuesPerPage]);
  uint32_t nPages = calcNumPages(ranges, nRanges);
  mBitmaps.reset(new element[nPages << (kLogValuesPerPage - kLogBitsPerEl)]());
  mZeroPageIndex = noZeroPage;
  uint32_t nonzeroPageEnd = 0;
  uint32_t currentPage = 0;
  for (size_t i = 0; i < nRanges; i++) {
    uint32_t start = ranges[i * 2];
    uint32_t end = ranges[i * 2 + 1];
    LOG_ALWAYS_FATAL_IF(end < start);  // make sure range size is nonnegative
    uint32_t startPage = start >> kLogValuesPerPage;
    uint32_t endPage = (end - 1) >> kLogValuesPerPage;
    if (startPage >= nonzeroPageEnd) {
      if (startPage > nonzeroPageEnd) {
        if (mZeroPageIndex == noZeroPage) {
          mZeroPageIndex = (currentPage++)
                           << (kLogValuesPerPage - kLogBitsPerEl);
        }
        for (uint32_t j = nonzeroPageEnd; j < startPage; j++) {
          mIndices[j] = mZeroPageIndex;
        }
      }
      mIndices[startPage] = (currentPage++)
                            << (kLogValuesPerPage - kLogBitsPerEl);
    }

    size_t index = ((currentPage - 1) << (kLogValuesPerPage - kLogBitsPerEl)) +
                   ((start & kPageMask) >> kLogBitsPerEl);
    size_t nElements = (end - (start & ~kElMask) + kElMask) >> kLogBitsPerEl;
    if (nElements == 1) {
      mBitmaps[index] |= (kElAllOnes >> (start & kElMask)) &
                         (kElAllOnes << ((~end + 1) & kElMask));
    } else {
      mBitmaps[index] |= kElAllOnes >> (start & kElMask);
      for (size_t j = 1; j < nElements - 1; j++) {
        mBitmaps[index + j] = kElAllOnes;
      }
      mBitmaps[index + nElements - 1] |= kElAllOnes << ((~end + 1) & kElMask);
    }
    for (size_t j = startPage + 1; j < endPage + 1; j++) {
      mIndices[j] = (currentPage++) << (kLogValuesPerPage - kLogBitsPerEl);
    }
    nonzeroPageEnd = endPage + 1;
  }
}

#if defined(_WIN32)
int SparseBitSet::CountLeadingZeros(element x) {
  return sizeof(element) <= sizeof(int) ? clz_win(x) : clzl_win(x);
}
#else
int SparseBitSet::CountLeadingZeros(element x) {
  // Note: GCC / clang builtin
  return sizeof(element) <= sizeof(int) ? __builtin_clz(x) : __builtin_clzl(x);
}
#endif

uint32_t SparseBitSet::nextSetBit(uint32_t fromIndex) const {
  if (fromIndex >= mMaxVal) {
    return kNotFound;
  }
  uint32_t fromPage = fromIndex >> kLogValuesPerPage;
  const element* bitmap = &mBitmaps[mIndices[fromPage]];
  uint32_t offset = (fromIndex & kPageMask) >> kLogBitsPerEl;
  element e = bitmap[offset] & (kElAllOnes >> (fromIndex & kElMask));
  if (e != 0) {
    return (fromIndex & ~kElMask) + CountLeadingZeros(e);
  }
  for (uint32_t j = offset + 1; j < (1 << (kLogValuesPerPage - kLogBitsPerEl));
       j++) {
    e = bitmap[j];
    if (e != 0) {
      return (fromIndex & ~kPageMask) + (j << kLogBitsPerEl) +
             CountLeadingZeros(e);
    }
  }
  uint32_t maxPage = (mMaxVal + kPageMask) >> kLogValuesPerPage;
  for (uint32_t page = fromPage + 1; page < maxPage; page++) {
    uint16_t index = mIndices[page];
    if (index == mZeroPageIndex) {
      continue;
    }
    bitmap = &mBitmaps[index];
    for (uint32_t j = 0; j < (1 << (kLogValuesPerPage - kLogBitsPerEl)); j++) {
      e = bitmap[j];
      if (e != 0) {
        return (page << kLogValuesPerPage) + (j << kLogBitsPerEl) +
               CountLeadingZeros(e);
      }
    }
  }
  return kNotFound;
}

}  // namespace minikin
