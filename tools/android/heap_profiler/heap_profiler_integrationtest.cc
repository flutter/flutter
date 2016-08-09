// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <dlfcn.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <map>

#include "base/compiler_specific.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "tools/android/heap_profiler/heap_profiler.h"

namespace {

typedef void* (*AllocatorFn)(size_t);
typedef int (*FreeFn)(void*, size_t);

const size_t kSize1 = 499 * PAGE_SIZE;
const size_t kSize2 = 503 * PAGE_SIZE;
const size_t kSize3 = 509 * PAGE_SIZE;

// The purpose of the four functions below is to create watermarked allocations,
// so the test fixture can ascertain that the hooks work end-to-end.
__attribute__((noinline)) void* MallocInner(size_t size) {
  void* ptr = malloc(size);
  // The memset below is to avoid tail-call elimination optimizations and ensure
  // that this function will be part of the stack trace.
  memset(ptr, 0, size);
  return ptr;
}

__attribute__((noinline)) void* MallocOuter(size_t size) {
  void* ptr = MallocInner(size);
  memset(ptr, 0, size);
  return ptr;
}

__attribute__((noinline)) void* DoMmap(size_t size) {
  return mmap(
      0, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, 0, 0);
}

__attribute__((noinline)) void* MmapInner(size_t size) {
  void* ptr = DoMmap(size);
  memset(ptr, 0, size);
  return ptr;
}

__attribute__((noinline)) void* MmapOuter(size_t size) {
  void* ptr = MmapInner(size);
  memset(ptr, 0, size);
  return ptr;
}

const HeapStats* GetHeapStats() {
  HeapStats* const* stats_ptr = reinterpret_cast<HeapStats* const*>(
      dlsym(RTLD_DEFAULT, "heap_profiler_stats_for_tests"));
  EXPECT_TRUE(stats_ptr != NULL);
  const HeapStats* stats = *stats_ptr;
  EXPECT_TRUE(stats != NULL);
  EXPECT_EQ(HEAP_PROFILER_MAGIC_MARKER, stats->magic_start);
  return stats;
}

bool StackTraceContains(const StacktraceEntry* s, AllocatorFn fn) {
  // kExpectedFnLen is a gross estimation of the watermark functions' size.
  // It tries to address the following problem: the addrs in the unwound stack
  // stack frames will NOT point to the beginning of the functions, but to the
  // PC after the call to malloc/mmap.
  const size_t kExpectedFnLen = 16;
  const uintptr_t fn_addr = reinterpret_cast<uintptr_t>(fn);
  for (size_t i = 0; i < HEAP_PROFILER_MAX_DEPTH; ++i) {
    if (s->frames[i] >= fn_addr && s->frames[i] <= fn_addr + kExpectedFnLen)
      return true;
  }
  return false;
}

const StacktraceEntry* LookupStackTrace(size_t size, AllocatorFn fn) {
  const HeapStats* stats = GetHeapStats();
  for (size_t i = 0; i < stats->max_stack_traces; ++i) {
    const StacktraceEntry* st = &stats->stack_traces[i];
    if (st->alloc_bytes == size && StackTraceContains(st, fn))
      return st;
  }
  return NULL;
}

int DoFree(void* addr, size_t /*size, ignored.*/) {
  free(addr);
  return 0;
}

void TestStackTracesWithParams(AllocatorFn outer_fn,
                               AllocatorFn inner_fn,
                               FreeFn free_fn) {
  const HeapStats* stats = GetHeapStats();

  void* m1 = outer_fn(kSize1);
  void* m2 = inner_fn(kSize2);
  void* m3 = inner_fn(kSize3);
  free_fn(m3, kSize3);

  const StacktraceEntry* st1 = LookupStackTrace(kSize1, inner_fn);
  const StacktraceEntry* st2 = LookupStackTrace(kSize2, inner_fn);
  const StacktraceEntry* st3 = LookupStackTrace(kSize3, inner_fn);

  EXPECT_TRUE(st1 != NULL);
  EXPECT_TRUE(StackTraceContains(st1, outer_fn));
  EXPECT_TRUE(StackTraceContains(st1, inner_fn));

  EXPECT_TRUE(st2 != NULL);
  EXPECT_FALSE(StackTraceContains(st2, outer_fn));
  EXPECT_TRUE(StackTraceContains(st2, inner_fn));

  EXPECT_EQ(NULL, st3);

  const size_t total_alloc_start = stats->total_alloc_bytes;
  const size_t num_stack_traces_start = stats->num_stack_traces;

  free_fn(m1, kSize1);
  free_fn(m2, kSize2);

  const size_t total_alloc_end = stats->total_alloc_bytes;
  const size_t num_stack_traces_end = stats->num_stack_traces;

  EXPECT_EQ(kSize1 + kSize2, total_alloc_start - total_alloc_end);
  EXPECT_EQ(2, num_stack_traces_start - num_stack_traces_end);
  EXPECT_EQ(NULL, LookupStackTrace(kSize1, inner_fn));
  EXPECT_EQ(NULL, LookupStackTrace(kSize2, inner_fn));
  EXPECT_EQ(NULL, LookupStackTrace(kSize3, inner_fn));
}

TEST(HeapProfilerIntegrationTest, TestMallocStackTraces) {
  TestStackTracesWithParams(&MallocOuter, &MallocInner, &DoFree);
}

TEST(HeapProfilerIntegrationTest, TestMmapStackTraces) {
  TestStackTracesWithParams(&MmapOuter, &MmapInner, &munmap);
}

// Returns the path of the directory containing the current executable.
std::string GetExePath() {
  char buf[1024];
  ssize_t len = readlink("/proc/self/exe", buf, sizeof(buf) - 1);
  if (len == -1)
    return std::string();
  std::string path(buf, len);
  size_t sep = path.find_last_of('/');
  if (sep == std::string::npos)
    return std::string();
  path.erase(sep);
  return path;
}

}  // namespace

int main(int argc, char** argv) {
  // Re-launch the process itself forcing the preload of the libheap_profiler.
  char* ld_preload = getenv("LD_PRELOAD");
  if (ld_preload == NULL || strstr(ld_preload, "libheap_profiler.so") == NULL) {
    char env_ld_lib_path[256];
    strlcpy(env_ld_lib_path, "LD_LIBRARY_PATH=", sizeof(env_ld_lib_path));
    strlcat(env_ld_lib_path, GetExePath().c_str(), sizeof(env_ld_lib_path));
    char env_ld_preload[] = "LD_PRELOAD=libheap_profiler.so";
    char* const env[] = {env_ld_preload, env_ld_lib_path, 0};
    execve("/proc/self/exe", argv, env);
    // execve() never returns, unless something goes wrong.
    perror("execve");
    assert(false);
  }

  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
