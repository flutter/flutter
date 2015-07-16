// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include <stddef.h>
#include <stdio.h>

#include "testing/gtest/include/gtest/gtest.h"

// TCMalloc header files.
#include "common.h"  // For TCMalloc constants like page size, etc.

// TCMalloc implementation.
#include "debugallocation_shim.cc"

namespace {

void* TCMallocDoMallocForTest(size_t size) {
  return do_malloc(size);
}

void TCMallocDoFreeForTest(void* ptr) {
  do_free(ptr);
}

size_t ExcludeSpaceForMarkForTest(size_t size) {
  return ExcludeSpaceForMark(size);
}

}  // namespace

TEST(TCMallocFreeCheck, BadPointerInFirstPageOfTheLargeObject) {
  char* p = reinterpret_cast<char*>(
      TCMallocDoMallocForTest(ExcludeSpaceForMarkForTest(kMaxSize + 1)));
  for (int offset = 1; offset < kPageSize ; offset <<= 1) {
    ASSERT_DEATH(TCMallocDoFreeForTest(p + offset),
                 "Pointer is not pointing to the start of a span");
  }
}

TEST(TCMallocFreeCheck, BadPageAlignedPointerInsideLargeObject) {
  char* p = reinterpret_cast<char*>(
      TCMallocDoMallocForTest(ExcludeSpaceForMarkForTest(kMaxSize + 1)));

  for (int offset = kPageSize; offset < kMaxSize; offset += kPageSize) {
    // Only the first and last page of a span are in heap map. So for others
    // tcmalloc will give a general error of invalid pointer.
    ASSERT_DEATH(TCMallocDoFreeForTest(p + offset),
                 "Attempt to free invalid pointer");
  }
  ASSERT_DEATH(TCMallocDoFreeForTest(p + kMaxSize),
               "Pointer is not pointing to the start of a span");
}

TEST(TCMallocFreeCheck, DoubleFreeLargeObject) {
  char* p = reinterpret_cast<char*>(
      TCMallocDoMallocForTest(ExcludeSpaceForMarkForTest(kMaxSize + 1)));
  ASSERT_DEATH(TCMallocDoFreeForTest(p); TCMallocDoFreeForTest(p),
               "Object was not in-use");
}


#ifdef NDEBUG
TEST(TCMallocFreeCheck, DoubleFreeSmallObject) {
  for (size_t size = 1;
       size <= ExcludeSpaceForMarkForTest(kMaxSize);
       size <<= 1) {
    char* p = reinterpret_cast<char*>(TCMallocDoMallocForTest(size));
    ASSERT_DEATH(TCMallocDoFreeForTest(p); TCMallocDoFreeForTest(p),
                 "Circular loop in list detected");
  }
}
#else
TEST(TCMallocFreeCheck, DoubleFreeSmallObject) {
  size_t size = 1;

  // When the object is small, tcmalloc validation can not distinguish normal
  // memory corruption or double free, because there's not enough space in
  // freed objects to keep the mark.
  for (; size <= ExcludeSpaceForMarkForTest(kMinClassSize); size <<= 1) {
    char* p = reinterpret_cast<char*>(TCMallocDoMallocForTest(size));
    ASSERT_DEATH(TCMallocDoFreeForTest(p); TCMallocDoFreeForTest(p),
                 "Memory corrupted");
  }

  for (; size <= ExcludeSpaceForMarkForTest(kMaxSize); size <<= 1) {
    char* p = reinterpret_cast<char*>(TCMallocDoMallocForTest(size));
    ASSERT_DEATH(TCMallocDoFreeForTest(p); TCMallocDoFreeForTest(p),
                 "Attempt to double free");
  }
}
#endif

int main(int argc, char **argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
