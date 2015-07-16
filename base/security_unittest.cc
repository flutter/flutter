// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <algorithm>
#include <limits>

#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "build/build_config.h"
#include "testing/gtest/include/gtest/gtest.h"

#if defined(OS_POSIX)
#include <sys/mman.h>
#include <unistd.h>
#endif

#if defined(OS_WIN)
#include <new.h>
#endif

using std::nothrow;
using std::numeric_limits;

namespace {

#if defined(OS_WIN)
// This is a permitted size but exhausts memory pretty quickly.
const size_t kLargePermittedAllocation = 0x7FFFE000;

int OnNoMemory(size_t) {
  _exit(1);
}

void ExhaustMemoryWithMalloc() {
  for (;;) {
    // Without the |volatile|, clang optimizes away the allocation.
    void* volatile buf = malloc(kLargePermittedAllocation);
    if (!buf)
      break;
  }
}

void ExhaustMemoryWithRealloc() {
  size_t size = kLargePermittedAllocation;
  void* buf = malloc(size);
  if (!buf)
    return;
  for (;;) {
    size += kLargePermittedAllocation;
    void* new_buf = realloc(buf, size);
    if (!buf)
      break;
    buf = new_buf;
  }
}
#endif

// This function acts as a compiler optimization barrier. We use it to
// prevent the compiler from making an expression a compile-time constant.
// We also use it so that the compiler doesn't discard certain return values
// as something we don't need (see the comment with calloc below).
template <typename Type>
NOINLINE Type HideValueFromCompiler(volatile Type value) {
#if defined(__GNUC__)
  // In a GCC compatible compiler (GCC or Clang), make this compiler barrier
  // more robust than merely using "volatile".
  __asm__ volatile ("" : "+r" (value));
#endif  // __GNUC__
  return value;
}

// Tcmalloc and Windows allocator shim support setting malloc limits.
// - NO_TCMALLOC (should be defined if compiled with use_allocator!="tcmalloc")
// - ADDRESS_SANITIZER and SYZYASAN because they have their own memory allocator
// - IOS does not use tcmalloc
// - OS_MACOSX does not use tcmalloc
// - Windows allocator shim defines ALLOCATOR_SHIM
#if (!defined(NO_TCMALLOC) || defined(ALLOCATOR_SHIM)) &&                     \
    !defined(ADDRESS_SANITIZER) && !defined(OS_IOS) && !defined(OS_MACOSX) && \
    !defined(SYZYASAN)
#define MALLOC_OVERFLOW_TEST(function) function
#else
#define MALLOC_OVERFLOW_TEST(function) DISABLED_##function
#endif

// TODO(jln): switch to std::numeric_limits<int>::max() when we switch to
// C++11.
const size_t kTooBigAllocSize = INT_MAX;

// Detect runtime TCMalloc bypasses.
bool IsTcMallocBypassed() {
#if defined(OS_LINUX)
  // This should detect a TCMalloc bypass from Valgrind.
  char* g_slice = getenv("G_SLICE");
  if (g_slice && !strcmp(g_slice, "always-malloc"))
    return true;
#endif
  return false;
}

bool CallocDiesOnOOM() {
// The sanitizers' calloc dies on OOM instead of returning NULL.
// The wrapper function in base/process_util_linux.cc that is used when we
// compile without TCMalloc will just die on OOM instead of returning NULL.
#if defined(ADDRESS_SANITIZER) || \
    defined(MEMORY_SANITIZER) || \
    defined(THREAD_SANITIZER) || \
    (defined(OS_LINUX) && defined(NO_TCMALLOC))
  return true;
#else
  return false;
#endif
}

// Fake test that allow to know the state of TCMalloc by looking at bots.
TEST(SecurityTest, MALLOC_OVERFLOW_TEST(IsTCMallocDynamicallyBypassed)) {
  printf("Malloc is dynamically bypassed: %s\n",
         IsTcMallocBypassed() ? "yes." : "no.");
}

// The MemoryAllocationRestrictions* tests test that we can not allocate a
// memory range that cannot be indexed via an int. This is used to mitigate
// vulnerabilities in libraries that use int instead of size_t.  See
// crbug.com/169327.

TEST(SecurityTest, MALLOC_OVERFLOW_TEST(MemoryAllocationRestrictionsMalloc)) {
  if (!IsTcMallocBypassed()) {
    scoped_ptr<char, base::FreeDeleter> ptr(static_cast<char*>(
        HideValueFromCompiler(malloc(kTooBigAllocSize))));
    ASSERT_TRUE(!ptr);
  }
}

#if defined(GTEST_HAS_DEATH_TEST) && defined(OS_WIN)
TEST(SecurityTest, MALLOC_OVERFLOW_TEST(MemoryAllocationMallocDeathTest)) {
  _set_new_handler(&OnNoMemory);
  _set_new_mode(1);
  {
    scoped_ptr<char, base::FreeDeleter> ptr;
    EXPECT_DEATH(ptr.reset(static_cast<char*>(
                      HideValueFromCompiler(malloc(kTooBigAllocSize)))),
                  "");
    ASSERT_TRUE(!ptr);
  }
  _set_new_handler(NULL);
  _set_new_mode(0);
}

TEST(SecurityTest, MALLOC_OVERFLOW_TEST(MemoryAllocationExhaustDeathTest)) {
  _set_new_handler(&OnNoMemory);
  _set_new_mode(1);
  {
    ASSERT_DEATH(ExhaustMemoryWithMalloc(), "");
  }
  _set_new_handler(NULL);
  _set_new_mode(0);
}

TEST(SecurityTest, MALLOC_OVERFLOW_TEST(MemoryReallocationExhaustDeathTest)) {
  _set_new_handler(&OnNoMemory);
  _set_new_mode(1);
  {
    ASSERT_DEATH(ExhaustMemoryWithRealloc(), "");
  }
  _set_new_handler(NULL);
  _set_new_mode(0);
}
#endif

TEST(SecurityTest, MALLOC_OVERFLOW_TEST(MemoryAllocationRestrictionsCalloc)) {
  if (!IsTcMallocBypassed()) {
    scoped_ptr<char, base::FreeDeleter> ptr(static_cast<char*>(
        HideValueFromCompiler(calloc(kTooBigAllocSize, 1))));
    ASSERT_TRUE(!ptr);
  }
}

TEST(SecurityTest, MALLOC_OVERFLOW_TEST(MemoryAllocationRestrictionsRealloc)) {
  if (!IsTcMallocBypassed()) {
    char* orig_ptr = static_cast<char*>(malloc(1));
    ASSERT_TRUE(orig_ptr);
    scoped_ptr<char, base::FreeDeleter> ptr(static_cast<char*>(
        HideValueFromCompiler(realloc(orig_ptr, kTooBigAllocSize))));
    ASSERT_TRUE(!ptr);
    // If realloc() did not succeed, we need to free orig_ptr.
    free(orig_ptr);
  }
}

typedef struct {
  char large_array[kTooBigAllocSize];
} VeryLargeStruct;

TEST(SecurityTest, MALLOC_OVERFLOW_TEST(MemoryAllocationRestrictionsNew)) {
  if (!IsTcMallocBypassed()) {
    scoped_ptr<VeryLargeStruct> ptr(
        HideValueFromCompiler(new (nothrow) VeryLargeStruct));
    ASSERT_TRUE(!ptr);
  }
}

#if defined(GTEST_HAS_DEATH_TEST) && defined(OS_WIN)
TEST(SecurityTest, MALLOC_OVERFLOW_TEST(MemoryAllocationNewDeathTest)) {
  _set_new_handler(&OnNoMemory);
  {
    scoped_ptr<VeryLargeStruct> ptr;
    EXPECT_DEATH(
        ptr.reset(HideValueFromCompiler(new (nothrow) VeryLargeStruct)), "");
    ASSERT_TRUE(!ptr);
  }
  _set_new_handler(NULL);
}
#endif

TEST(SecurityTest, MALLOC_OVERFLOW_TEST(MemoryAllocationRestrictionsNewArray)) {
  if (!IsTcMallocBypassed()) {
    scoped_ptr<char[]> ptr(
        HideValueFromCompiler(new (nothrow) char[kTooBigAllocSize]));
    ASSERT_TRUE(!ptr);
  }
}

// The tests bellow check for overflows in new[] and calloc().

// There are platforms where these tests are known to fail. We would like to
// be able to easily check the status on the bots, but marking tests as
// FAILS_ is too clunky.
void OverflowTestsSoftExpectTrue(bool overflow_detected) {
  if (!overflow_detected) {
#if defined(OS_LINUX) || defined(OS_ANDROID) || defined(OS_MACOSX)
    // Sadly, on Linux, Android, and OSX we don't have a good story yet. Don't
    // fail the test, but report.
    printf("Platform has overflow: %s\n",
           !overflow_detected ? "yes." : "no.");
#else
    // Otherwise, fail the test. (Note: EXPECT are ok in subfunctions, ASSERT
    // aren't).
    EXPECT_TRUE(overflow_detected);
#endif
  }
}

#if defined(OS_IOS) || defined(OS_WIN) || defined(THREAD_SANITIZER) || defined(OS_MACOSX)
#define MAYBE_NewOverflow DISABLED_NewOverflow
#else
#define MAYBE_NewOverflow NewOverflow
#endif
// Test array[TooBig][X] and array[X][TooBig] allocations for int overflows.
// IOS doesn't honor nothrow, so disable the test there.
// Crashes on Windows Dbg builds, disable there as well.
// Fails on Mac 10.8 http://crbug.com/227092
TEST(SecurityTest, MAYBE_NewOverflow) {
  const size_t kArraySize = 4096;
  // We want something "dynamic" here, so that the compiler doesn't
  // immediately reject crazy arrays.
  const size_t kDynamicArraySize = HideValueFromCompiler(kArraySize);
  // numeric_limits are still not constexpr until we switch to C++11, so we
  // use an ugly cast.
  const size_t kMaxSizeT = ~static_cast<size_t>(0);
  ASSERT_EQ(numeric_limits<size_t>::max(), kMaxSizeT);
  const size_t kArraySize2 = kMaxSizeT / kArraySize + 10;
  const size_t kDynamicArraySize2 = HideValueFromCompiler(kArraySize2);
  {
    scoped_ptr<char[][kArraySize]> array_pointer(new (nothrow)
        char[kDynamicArraySize2][kArraySize]);
    OverflowTestsSoftExpectTrue(!array_pointer);
  }
  // On windows, the compiler prevents static array sizes of more than
  // 0x7fffffff (error C2148).
#if defined(OS_WIN) && defined(ARCH_CPU_64_BITS)
  ALLOW_UNUSED_LOCAL(kDynamicArraySize);
#else
  {
    scoped_ptr<char[][kArraySize2]> array_pointer(new (nothrow)
        char[kDynamicArraySize][kArraySize2]);
    OverflowTestsSoftExpectTrue(!array_pointer);
  }
#endif  // !defined(OS_WIN) || !defined(ARCH_CPU_64_BITS)
}

// Call calloc(), eventually free the memory and return whether or not
// calloc() did succeed.
bool CallocReturnsNull(size_t nmemb, size_t size) {
  scoped_ptr<char, base::FreeDeleter> array_pointer(
      static_cast<char*>(calloc(nmemb, size)));
  // We need the call to HideValueFromCompiler(): we have seen LLVM
  // optimize away the call to calloc() entirely and assume the pointer to not
  // be NULL.
  return HideValueFromCompiler(array_pointer.get()) == NULL;
}

// Test if calloc() can overflow.
TEST(SecurityTest, CallocOverflow) {
  const size_t kArraySize = 4096;
  const size_t kMaxSizeT = numeric_limits<size_t>::max();
  const size_t kArraySize2 = kMaxSizeT / kArraySize + 10;
  if (!CallocDiesOnOOM()) {
    EXPECT_TRUE(CallocReturnsNull(kArraySize, kArraySize2));
    EXPECT_TRUE(CallocReturnsNull(kArraySize2, kArraySize));
  } else {
    // It's also ok for calloc to just terminate the process.
#if defined(GTEST_HAS_DEATH_TEST)
    EXPECT_DEATH(CallocReturnsNull(kArraySize, kArraySize2), "");
    EXPECT_DEATH(CallocReturnsNull(kArraySize2, kArraySize), "");
#endif  // GTEST_HAS_DEATH_TEST
  }
}

#if defined(OS_LINUX) && defined(__x86_64__)
// Check if ptr1 and ptr2 are separated by less than size chars.
bool ArePointersToSameArea(void* ptr1, void* ptr2, size_t size) {
  ptrdiff_t ptr_diff = reinterpret_cast<char*>(std::max(ptr1, ptr2)) -
                       reinterpret_cast<char*>(std::min(ptr1, ptr2));
  return static_cast<size_t>(ptr_diff) <= size;
}

// Check if TCMalloc uses an underlying random memory allocator.
TEST(SecurityTest, MALLOC_OVERFLOW_TEST(RandomMemoryAllocations)) {
  if (IsTcMallocBypassed())
    return;
  size_t kPageSize = 4096;  // We support x86_64 only.
  // Check that malloc() returns an address that is neither the kernel's
  // un-hinted mmap area, nor the current brk() area. The first malloc() may
  // not be at a random address because TCMalloc will first exhaust any memory
  // that it has allocated early on, before starting the sophisticated
  // allocators.
  void* default_mmap_heap_address =
      mmap(0, kPageSize, PROT_READ|PROT_WRITE,
           MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
  ASSERT_NE(default_mmap_heap_address,
            static_cast<void*>(MAP_FAILED));
  ASSERT_EQ(munmap(default_mmap_heap_address, kPageSize), 0);
  void* brk_heap_address = sbrk(0);
  ASSERT_NE(brk_heap_address, reinterpret_cast<void*>(-1));
  ASSERT_TRUE(brk_heap_address != NULL);
  // 1 MB should get us past what TCMalloc pre-allocated before initializing
  // the sophisticated allocators.
  size_t kAllocSize = 1<<20;
  scoped_ptr<char, base::FreeDeleter> ptr(
      static_cast<char*>(malloc(kAllocSize)));
  ASSERT_TRUE(ptr != NULL);
  // If two pointers are separated by less than 512MB, they are considered
  // to be in the same area.
  // Our random pointer could be anywhere within 0x3fffffffffff (46bits),
  // and we are checking that it's not withing 1GB (30 bits) from two
  // addresses (brk and mmap heap). We have roughly one chance out of
  // 2^15 to flake.
  const size_t kAreaRadius = 1<<29;
  bool in_default_mmap_heap = ArePointersToSameArea(
      ptr.get(), default_mmap_heap_address, kAreaRadius);
  EXPECT_FALSE(in_default_mmap_heap);

  bool in_default_brk_heap = ArePointersToSameArea(
      ptr.get(), brk_heap_address, kAreaRadius);
  EXPECT_FALSE(in_default_brk_heap);

  // In the implementation, we always mask our random addresses with
  // kRandomMask, so we use it as an additional detection mechanism.
  const uintptr_t kRandomMask = 0x3fffffffffffULL;
  bool impossible_random_address =
      reinterpret_cast<uintptr_t>(ptr.get()) & ~kRandomMask;
  EXPECT_FALSE(impossible_random_address);
}

#endif  // defined(OS_LINUX) && defined(__x86_64__)

}  // namespace
