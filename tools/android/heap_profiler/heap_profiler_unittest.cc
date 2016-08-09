// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdint.h>
#include <string.h>
#include <map>

#include "base/compiler_specific.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "tools/android/heap_profiler/heap_profiler.h"

namespace {

class HeapProfilerTest : public testing::Test {
 public:
  void SetUp() override { heap_profiler_init(&stats_); }

  void TearDown() override {
    CheckAllocVsStacktaceConsistency();
    heap_profiler_cleanup();
  }

 protected:
  struct StackTrace {
    uintptr_t frames[HEAP_PROFILER_MAX_DEPTH];
    size_t depth;
  };

  StackTrace GenStackTrace(size_t depth, uintptr_t base) {
    assert(depth <= HEAP_PROFILER_MAX_DEPTH);
    StackTrace st;
    for (size_t i = 0; i < depth; ++i)
      st.frames[i] = base + i * 0x10UL;
    st.depth = depth;
    return st;
  }

  void ExpectAlloc(uintptr_t start,
                   uintptr_t end,
                   const StackTrace& st,
                   uint32_t flags) {
    for (uint32_t i = 0; i < stats_.max_allocs; ++i) {
      const Alloc& alloc = stats_.allocs[i];
      if (alloc.start != start || alloc.end != end)
        continue;
      // Check that the stack trace match.
      for (uint32_t j = 0; j < st.depth; ++j) {
        EXPECT_EQ(st.frames[j], alloc.st->frames[j])
            << "Stacktrace not matching @ depth " << j;
      }
      EXPECT_EQ(flags, alloc.flags);
      return;
    }

    FAIL() << "Alloc not found [" << std::hex << start << "," << end << "]";
  }

  void CheckAllocVsStacktaceConsistency() {
    uint32_t allocs_seen = 0;
    uint32_t stack_traces_seen = 0;
    std::map<StacktraceEntry*, uintptr_t> stacktrace_bytes_by_alloc;

    for (uint32_t i = 0; i < stats_.max_allocs; ++i) {
      Alloc* alloc = &stats_.allocs[i];
      if (alloc->start == 0 && alloc->end == 0)
        continue;
      ++allocs_seen;
      stacktrace_bytes_by_alloc[alloc->st] += alloc->end - alloc->start + 1;
    }

    for (uint32_t i = 0; i < stats_.max_stack_traces; ++i) {
      StacktraceEntry* st = &stats_.stack_traces[i];
      if (st->alloc_bytes == 0)
        continue;
      ++stack_traces_seen;
      EXPECT_EQ(1, stacktrace_bytes_by_alloc.count(st));
      EXPECT_EQ(stacktrace_bytes_by_alloc[st], st->alloc_bytes);
    }

    EXPECT_EQ(allocs_seen, stats_.num_allocs);
    EXPECT_EQ(stack_traces_seen, stats_.num_stack_traces);
  }

  HeapStats stats_;
};

TEST_F(HeapProfilerTest, SimpleAlloc) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  heap_profiler_alloc((void*)0x1000, 1024, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x2000, 2048, st1.frames, st1.depth, 0);

  EXPECT_EQ(2, stats_.num_allocs);
  EXPECT_EQ(1, stats_.num_stack_traces);
  EXPECT_EQ(1024 + 2048, stats_.total_alloc_bytes);
  ExpectAlloc(0x1000, 0x13ff, st1, 0);
  ExpectAlloc(0x2000, 0x27ff, st1, 0);
}

TEST_F(HeapProfilerTest, AllocMultipleStacks) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  StackTrace st2 = GenStackTrace(4, 0x1000);
  heap_profiler_alloc((void*)0x1000, 1024, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x2000, 2048, st2.frames, st2.depth, 0);
  heap_profiler_alloc((void*)0x3000, 32, st1.frames, st1.depth, 0);

  EXPECT_EQ(3, stats_.num_allocs);
  EXPECT_EQ(2, stats_.num_stack_traces);
  EXPECT_EQ(1024 + 2048 + 32, stats_.total_alloc_bytes);
  ExpectAlloc(0x1000, 0x13ff, st1, 0);
  ExpectAlloc(0x2000, 0x27ff, st2, 0);
  ExpectAlloc(0x3000, 0x301f, st1, 0);
}

TEST_F(HeapProfilerTest, SimpleAllocAndFree) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  heap_profiler_alloc((void*)0x1000, 1024, st1.frames, st1.depth, 0);
  heap_profiler_free((void*)0x1000, 1024, NULL);

  EXPECT_EQ(0, stats_.num_allocs);
  EXPECT_EQ(0, stats_.num_stack_traces);
  EXPECT_EQ(0, stats_.total_alloc_bytes);
}

TEST_F(HeapProfilerTest, Realloc) {
  StackTrace st1 = GenStackTrace(8, 0);
  heap_profiler_alloc((void*)0, 32, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0, 32, st1.frames, st1.depth, 0);
}

TEST_F(HeapProfilerTest, AllocAndFreeMultipleStacks) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  StackTrace st2 = GenStackTrace(6, 0x1000);
  heap_profiler_alloc((void*)0x1000, 1024, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x2000, 2048, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x3000, 32, st2.frames, st2.depth, 0);
  heap_profiler_alloc((void*)0x4000, 64, st2.frames, st2.depth, 0);

  heap_profiler_free((void*)0x1000, 1024, NULL);
  heap_profiler_free((void*)0x3000, 32, NULL);

  EXPECT_EQ(2, stats_.num_allocs);
  EXPECT_EQ(2, stats_.num_stack_traces);
  EXPECT_EQ(2048 + 64, stats_.total_alloc_bytes);
  ExpectAlloc(0x2000, 0x27ff, st1, 0);
  ExpectAlloc(0x4000, 0x403f, st2, 0);
}

TEST_F(HeapProfilerTest, AllocAndFreeAll) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  StackTrace st2 = GenStackTrace(6, 0x1000);
  heap_profiler_alloc((void*)0x1000, 1024, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x2000, 2048, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x3000, 32, st2.frames, st2.depth, 0);
  heap_profiler_alloc((void*)0x4000, 64, st2.frames, st2.depth, 0);

  heap_profiler_free((void*)0x1000, 1024, NULL);
  heap_profiler_free((void*)0x2000, 2048, NULL);
  heap_profiler_free((void*)0x3000, 32, NULL);
  heap_profiler_free((void*)0x4000, 64, NULL);

  EXPECT_EQ(0, stats_.num_allocs);
  EXPECT_EQ(0, stats_.num_stack_traces);
  EXPECT_EQ(0, stats_.total_alloc_bytes);
}

TEST_F(HeapProfilerTest, AllocAndFreeWithZeroSize) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  StackTrace st2 = GenStackTrace(6, 0x1000);
  heap_profiler_alloc((void*)0x1000, 1024, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x2000, 2048, st2.frames, st2.depth, 0);

  heap_profiler_free((void*)0x1000, 0, NULL);

  EXPECT_EQ(1, stats_.num_allocs);
  EXPECT_EQ(1, stats_.num_stack_traces);
  EXPECT_EQ(2048, stats_.total_alloc_bytes);
}

TEST_F(HeapProfilerTest, AllocAndFreeContiguous) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  StackTrace st2 = GenStackTrace(6, 0x1000);
  heap_profiler_alloc((void*)0x1000, 4096, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x2000, 4096, st2.frames, st2.depth, 0);

  heap_profiler_free((void*)0x1000, 8192, NULL);

  EXPECT_EQ(0, stats_.num_allocs);
  EXPECT_EQ(0, stats_.num_stack_traces);
  EXPECT_EQ(0, stats_.total_alloc_bytes);
}

TEST_F(HeapProfilerTest, SparseAllocsOneLargeOuterFree) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  StackTrace st2 = GenStackTrace(6, 0x1000);

  heap_profiler_alloc((void*)0x1010, 1, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x1400, 2, st2.frames, st2.depth, 0);
  heap_profiler_alloc((void*)0x1600, 5, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x9000, 4096, st2.frames, st2.depth, 0);

  heap_profiler_free((void*)0x0800, 8192, NULL);
  EXPECT_EQ(1, stats_.num_allocs);
  EXPECT_EQ(1, stats_.num_stack_traces);
  EXPECT_EQ(4096, stats_.total_alloc_bytes);
  ExpectAlloc(0x9000, 0x9fff, st2, 0);
}

TEST_F(HeapProfilerTest, SparseAllocsOneLargePartiallyOverlappingFree) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  StackTrace st2 = GenStackTrace(6, 0x1000);
  StackTrace st3 = GenStackTrace(4, 0x2000);

  // This will be untouched.
  heap_profiler_alloc((void*)0x1000, 1024, st1.frames, st1.depth, 0);

  // These will be partially freed in one shot (% 64 a bytes "margin").
  heap_profiler_alloc((void*)0x2000, 128, st2.frames, st2.depth, 0);
  heap_profiler_alloc((void*)0x2400, 128, st2.frames, st2.depth, 0);
  heap_profiler_alloc((void*)0x2f80, 128, st2.frames, st2.depth, 0);

  // This will be untouched.
  heap_profiler_alloc((void*)0x3000, 1024, st3.frames, st3.depth, 0);

  heap_profiler_free((void*)0x2040, 4096 - 64 - 64, NULL);
  EXPECT_EQ(4, stats_.num_allocs);
  EXPECT_EQ(3, stats_.num_stack_traces);
  EXPECT_EQ(1024 + 64 + 64 + 1024, stats_.total_alloc_bytes);

  ExpectAlloc(0x1000, 0x13ff, st1, 0);
  ExpectAlloc(0x2000, 0x203f, st2, 0);
  ExpectAlloc(0x2fc0, 0x2fff, st2, 0);
  ExpectAlloc(0x3000, 0x33ff, st3, 0);
}

TEST_F(HeapProfilerTest, AllocAndFreeScattered) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  heap_profiler_alloc((void*)0x1000, 4096, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x2000, 4096, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x3000, 4096, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x4000, 4096, st1.frames, st1.depth, 0);

  heap_profiler_free((void*)0x800, 4096, NULL);
  EXPECT_EQ(4, stats_.num_allocs);
  EXPECT_EQ(2048 + 4096 + 4096 + 4096, stats_.total_alloc_bytes);

  heap_profiler_free((void*)0x1800, 4096, NULL);
  EXPECT_EQ(3, stats_.num_allocs);
  EXPECT_EQ(2048 + 4096 + 4096, stats_.total_alloc_bytes);

  heap_profiler_free((void*)0x2800, 4096, NULL);
  EXPECT_EQ(2, stats_.num_allocs);
  EXPECT_EQ(2048 + 4096, stats_.total_alloc_bytes);

  heap_profiler_free((void*)0x3800, 4096, NULL);
  EXPECT_EQ(1, stats_.num_allocs);
  EXPECT_EQ(2048, stats_.total_alloc_bytes);

  heap_profiler_free((void*)0x4800, 4096, NULL);
  EXPECT_EQ(0, stats_.num_allocs);
  EXPECT_EQ(0, stats_.num_stack_traces);
  EXPECT_EQ(0, stats_.total_alloc_bytes);
}

TEST_F(HeapProfilerTest, AllocAndOverFreeContiguous) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  StackTrace st2 = GenStackTrace(6, 0x1000);
  heap_profiler_alloc((void*)0x1000, 4096, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x2000, 4096, st2.frames, st2.depth, 0);

  heap_profiler_free((void*)0, 16834, NULL);

  EXPECT_EQ(0, stats_.num_allocs);
  EXPECT_EQ(0, stats_.num_stack_traces);
  EXPECT_EQ(0, stats_.total_alloc_bytes);
}

TEST_F(HeapProfilerTest, AllocContiguousAndPunchHole) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  StackTrace st2 = GenStackTrace(6, 0x1000);
  heap_profiler_alloc((void*)0x1000, 4096, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x2000, 4096, st2.frames, st2.depth, 0);

  // Punch a 4k hole in the middle of the two contiguous 4k allocs.
  heap_profiler_free((void*)0x1800, 4096, NULL);

  EXPECT_EQ(2, stats_.num_allocs);
  EXPECT_EQ(2, stats_.num_stack_traces);
  EXPECT_EQ(4096, stats_.total_alloc_bytes);
}

TEST_F(HeapProfilerTest, AllocAndPartialFree) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  StackTrace st2 = GenStackTrace(6, 0x1000);
  StackTrace st3 = GenStackTrace(7, 0x2000);
  StackTrace st4 = GenStackTrace(9, 0x3000);
  heap_profiler_alloc((void*)0x1000, 1024, st1.frames, st1.depth, 0);
  heap_profiler_alloc((void*)0x2000, 1024, st2.frames, st2.depth, 0);
  heap_profiler_alloc((void*)0x3000, 1024, st3.frames, st3.depth, 0);
  heap_profiler_alloc((void*)0x4000, 1024, st4.frames, st4.depth, 0);

  heap_profiler_free((void*)0x1000, 128, NULL);  // Shrink left by 128B.
  heap_profiler_free((void*)0x2380, 128, NULL);  // Shrink right by 128B.
  heap_profiler_free((void*)0x3100, 512, NULL);  // 512B hole in the middle.
  heap_profiler_free((void*)0x4000, 512, NULL);  // Free up the 4th alloc...
  heap_profiler_free((void*)0x4200, 512, NULL);  // ...but do it in two halves.

  EXPECT_EQ(4, stats_.num_allocs);  // 1 + 2 + two sides around the hole 3.
  EXPECT_EQ(3, stats_.num_stack_traces);  // st4 should be gone.
  EXPECT_EQ(896 + 896 + 512, stats_.total_alloc_bytes);
}

TEST_F(HeapProfilerTest, RandomIndividualAllocAndFrees) {
  static const size_t NUM_ST = 128;
  static const size_t NUM_OPS = 1000;

  StackTrace st[NUM_ST];
  for (uint32_t i = 0; i < NUM_ST; ++i)
    st[i] = GenStackTrace((i % 10) + 2, i * 128);

  for (size_t i = 0; i < NUM_OPS; ++i) {
    uintptr_t start = ((i + 7) << 8) & (0xffffff);
    size_t size = (start >> 16) & 0x0fff;
    if (i & 1) {
      StackTrace* s = &st[start % NUM_ST];
      heap_profiler_alloc((void*)start, size, s->frames, s->depth, 0);
    } else {
      heap_profiler_free((void*)start, size, NULL);
    }
    CheckAllocVsStacktaceConsistency();
  }
}

TEST_F(HeapProfilerTest, RandomAllocAndFreesBatches) {
  static const size_t NUM_ST = 128;
  static const size_t NUM_ALLOCS = 100;

  StackTrace st[NUM_ST];
  for (size_t i = 0; i < NUM_ST; ++i)
    st[i] = GenStackTrace((i % 10) + 2, i * NUM_ST);

  for (int repeat = 0; repeat < 5; ++repeat) {
    for (size_t i = 0; i < NUM_ALLOCS; ++i) {
      StackTrace* s = &st[i % NUM_ST];
      heap_profiler_alloc(
          (void*)(i * 4096), ((i + 1) * 32) % 4097, s->frames, s->depth, 0);
      CheckAllocVsStacktaceConsistency();
    }

    for (size_t i = 0; i < NUM_ALLOCS; ++i) {
      heap_profiler_free((void*)(i * 1024), ((i + 1) * 64) % 16000, NULL);
      CheckAllocVsStacktaceConsistency();
    }
  }
}

TEST_F(HeapProfilerTest, UnwindStackTooLargeShouldSaturate) {
  StackTrace st1 = GenStackTrace(HEAP_PROFILER_MAX_DEPTH, 0x0);
  uintptr_t many_frames[100] = {};
  memcpy(many_frames, st1.frames, sizeof(uintptr_t) * st1.depth);
  heap_profiler_alloc((void*)0x1000, 1024, many_frames, 100, 0);
  ExpectAlloc(0x1000, 0x13ff, st1, 0);
}

TEST_F(HeapProfilerTest, NoUnwindShouldNotCrashButNoop) {
  heap_profiler_alloc((void*)0x1000, 1024, NULL, 0, 0);
  EXPECT_EQ(0, stats_.num_allocs);
  EXPECT_EQ(0, stats_.num_stack_traces);
  EXPECT_EQ(0, stats_.total_alloc_bytes);
}

TEST_F(HeapProfilerTest, FreeNonExisting) {
  StackTrace st1 = GenStackTrace(5, 0x0);
  heap_profiler_free((void*)0x1000, 1024, NULL);
  heap_profiler_free((void*)0x1400, 1024, NULL);
  EXPECT_EQ(0, stats_.num_allocs);
  EXPECT_EQ(0, stats_.num_stack_traces);
  EXPECT_EQ(0, stats_.total_alloc_bytes);
  heap_profiler_alloc((void*)0x1000, 1024, st1.frames, st1.depth, 0);
  EXPECT_EQ(1, stats_.num_allocs);
  EXPECT_EQ(1024, stats_.total_alloc_bytes);
}

TEST_F(HeapProfilerTest, FlagsConsistency) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  uint32_t flags = 0;
  heap_profiler_alloc((void*)0x1000, 4096, st1.frames, st1.depth, 42);
  heap_profiler_alloc((void*)0x2000, 4096, st1.frames, st1.depth, 142);

  ExpectAlloc(0x1000, 0x1fff, st1, 42);
  ExpectAlloc(0x2000, 0x2fff, st1, 142);

  // Punch a 4k hole in the middle of the two contiguous 4k allocs.
  heap_profiler_free((void*)0x1800, 4096, NULL);

  ExpectAlloc(0x1000, 0x17ff, st1, 42);
  heap_profiler_free((void*)0x1000, 2048, &flags);
  EXPECT_EQ(42, flags);

  ExpectAlloc(0x2800, 0x2fff, st1, 142);
  heap_profiler_free((void*)0x2800, 2048, &flags);
  EXPECT_EQ(142, flags);
}

TEST_F(HeapProfilerTest, BeConsistentOnOOM) {
  static const size_t NUM_ALLOCS = 512 * 1024;
  uintptr_t frames[1];

  for (uintptr_t i = 0; i < NUM_ALLOCS; ++i) {
    frames[0] = i;
    heap_profiler_alloc((void*)(i * 32), 32, frames, 1, 0);
  }

  CheckAllocVsStacktaceConsistency();
  // Check that we're saturating, otherwise this entire test is pointless.
  EXPECT_LT(stats_.num_allocs, NUM_ALLOCS);
  EXPECT_LT(stats_.num_stack_traces, NUM_ALLOCS);

  for (uintptr_t i = 0; i < NUM_ALLOCS; ++i)
    heap_profiler_free((void*)(i * 32), 32, NULL);

  EXPECT_EQ(0, stats_.num_allocs);
  EXPECT_EQ(0, stats_.total_alloc_bytes);
  EXPECT_EQ(0, stats_.num_stack_traces);
}

#ifdef __LP64__
TEST_F(HeapProfilerTest, Test64Bit) {
  StackTrace st1 = GenStackTrace(8, 0x0);
  StackTrace st2 = GenStackTrace(10, 0x7fffffff70000000L);
  StackTrace st3 = GenStackTrace(10, 0xffffffff70000000L);
  heap_profiler_alloc((void*)0x1000, 4096, st1.frames, st1.depth, 0);
  heap_profiler_alloc(
      (void*)0x7ffffffffffff000L, 4096, st2.frames, st2.depth, 0);
  heap_profiler_alloc(
      (void*)0xfffffffffffff000L, 4096, st3.frames, st3.depth, 0);
  EXPECT_EQ(3, stats_.num_allocs);
  EXPECT_EQ(3, stats_.num_stack_traces);
  EXPECT_EQ(4096 + 4096 + 4096, stats_.total_alloc_bytes);

  heap_profiler_free((void*)0x1000, 4096, NULL);
  EXPECT_EQ(2, stats_.num_allocs);
  EXPECT_EQ(2, stats_.num_stack_traces);
  EXPECT_EQ(4096 + 4096, stats_.total_alloc_bytes);

  heap_profiler_free((void*)0x7ffffffffffff000L, 4096, NULL);
  EXPECT_EQ(1, stats_.num_allocs);
  EXPECT_EQ(1, stats_.num_stack_traces);
  EXPECT_EQ(4096, stats_.total_alloc_bytes);

  heap_profiler_free((void*)0xfffffffffffff000L, 4096, NULL);
  EXPECT_EQ(0, stats_.num_allocs);
  EXPECT_EQ(0, stats_.num_stack_traces);
  EXPECT_EQ(0, stats_.total_alloc_bytes);
}
#endif

}  // namespace
