// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <unwind.h>

#include "tools/android/heap_profiler/heap_profiler.h"

#define HEAP_PROFILER_EXPORT __attribute__((visibility("default")))


static inline __attribute__((always_inline))
uint32_t get_backtrace(uintptr_t* frames, uint32_t max_depth);

// Function pointers typedefs for the hooked symbols.
typedef void* (*mmap_t)(void*, size_t, int, int, int, off_t);
typedef void* (*mmap2_t)(void*, size_t, int, int, int, off_t);
typedef void* (*mmap64_t)(void*, size_t, int, int, int, off64_t);
typedef void* (*mremap_t)(void*, size_t, size_t, unsigned long);
typedef int (*munmap_t)(void*, size_t);
typedef void* (*malloc_t)(size_t);
typedef void* (*calloc_t)(size_t, size_t);
typedef void* (*realloc_t)(void*, size_t);
typedef void (*free_t)(void*);

// And their actual definitions.
static mmap_t real_mmap;
static mmap2_t real_mmap2;
static mmap64_t real_mmap64;
static mremap_t real_mremap;
static munmap_t real_munmap;
static malloc_t real_malloc;
static calloc_t real_calloc;
static realloc_t real_realloc;
static free_t real_free;
static int* has_forked_off_zygote;

HEAP_PROFILER_EXPORT const HeapStats* heap_profiler_stats_for_tests;

// +---------------------------------------------------------------------------+
// + Initialization of heap_profiler and lookup of hooks' addresses            +
// +---------------------------------------------------------------------------+
__attribute__((constructor))
static void initialize() {
  real_mmap = (mmap_t) dlsym(RTLD_NEXT, "mmap");
  real_mmap2 = (mmap_t) dlsym(RTLD_NEXT, "mmap2");
  real_mmap64 = (mmap64_t) dlsym(RTLD_NEXT, "mmap64");
  real_mremap = (mremap_t) dlsym(RTLD_NEXT, "mremap");
  real_munmap = (munmap_t) dlsym(RTLD_NEXT, "munmap");
  real_malloc = (malloc_t) dlsym(RTLD_NEXT, "malloc");
  real_calloc = (calloc_t) dlsym(RTLD_NEXT, "calloc");
  real_realloc = (realloc_t) dlsym(RTLD_NEXT, "realloc");
  real_free = (free_t) dlsym(RTLD_NEXT, "free");

  // gMallocLeakZygoteChild is an extra useful piece of information to have.
  // When available, it tells whether we're in the zygote (=0) or forked (=1)
  // a child off it. In the worst case it will be NULL and we'll just ignore it.
  has_forked_off_zygote = (int*) dlsym(RTLD_NEXT, "gMallocLeakZygoteChild");

  // Allocate room for the HeapStats area and initialize the heap profiler.
  // Make an explicit map of /dev/zero (instead of MAP_ANONYMOUS), so that the
  // heap_dump tool can easily spot the mapping in the target process.
  int fd = open("/dev/zero", O_RDONLY);
  if (fd < 0) {
    abort();  // This world has gone wrong. Good night Vienna.
  }

  HeapStats* stats = (HeapStats*) real_mmap(
      0, sizeof(HeapStats), PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);
  heap_profiler_stats_for_tests = stats;
  heap_profiler_init(stats);
}

static inline __attribute__((always_inline)) void unwind_and_record_alloc(
    void* start, size_t size, uint32_t flags) {
  const int errno_save = errno;
  uintptr_t frames[HEAP_PROFILER_MAX_DEPTH];
  const uint32_t depth = get_backtrace(frames, HEAP_PROFILER_MAX_DEPTH);
  if (has_forked_off_zygote != NULL && *has_forked_off_zygote == 0)
    flags |= HEAP_PROFILER_FLAGS_IN_ZYGOTE;
  heap_profiler_alloc(start, size, frames, depth, flags);
  errno = errno_save;
}

static inline __attribute__((always_inline)) void discard_alloc(
    void* start, size_t size, uint32_t* old_flags) {
  const int errno_save = errno;
  heap_profiler_free(start, size, old_flags);
  errno = errno_save;
}

// Flags are non-functional extra decorators that are made available to the
// final heap_dump tool, to get more details about the source of the allocation.
static uint32_t get_flags_for_mmap(int fd) {
  return HEAP_PROFILER_FLAGS_MMAP | (fd ? HEAP_PROFILER_FLAGS_MMAP_FILE : 0);
}

// +---------------------------------------------------------------------------+
// + Actual mmap/malloc hooks                                                  +
// +---------------------------------------------------------------------------+
HEAP_PROFILER_EXPORT void* mmap(
    void* addr, size_t size, int prot, int flags, int fd, off_t offset)  {
  void* ret = real_mmap(addr, size, prot, flags, fd, offset);
  if (ret != MAP_FAILED)
    unwind_and_record_alloc(ret, size, get_flags_for_mmap(fd));
  return ret;
}

HEAP_PROFILER_EXPORT void* mmap2(
    void* addr, size_t size, int prot, int flags, int fd, off_t pgoffset)  {
  void* ret = real_mmap2(addr, size, prot, flags, fd, pgoffset);
  if (ret != MAP_FAILED)
    unwind_and_record_alloc(ret, size, get_flags_for_mmap(fd));
  return ret;
}

HEAP_PROFILER_EXPORT void* mmap64(
    void* addr, size_t size, int prot, int flags, int fd, off64_t offset) {
  void* ret = real_mmap64(addr, size, prot, flags, fd, offset);
  if (ret != MAP_FAILED)
    unwind_and_record_alloc(ret, size, get_flags_for_mmap(fd));
  return ret;
}

HEAP_PROFILER_EXPORT void* mremap(
    void* addr, size_t oldlen, size_t newlen, unsigned long flags) {
  void* ret = real_mremap(addr, oldlen, newlen, flags);
  if (ret != MAP_FAILED) {
    uint32_t flags = 0;
    if (addr)
      discard_alloc(addr, oldlen, &flags);
    if (newlen > 0)
      unwind_and_record_alloc(ret, newlen, flags);
  }
  return ret;
}

HEAP_PROFILER_EXPORT int munmap(void* ptr, size_t size) {
  int ret = real_munmap(ptr, size);
  discard_alloc(ptr, size, /*old_flags=*/NULL);
  return ret;
}

HEAP_PROFILER_EXPORT void* malloc(size_t byte_count) {
  void* ret = real_malloc(byte_count);
  if (ret != NULL)
    unwind_and_record_alloc(ret, byte_count, HEAP_PROFILER_FLAGS_MALLOC);
  return ret;
}

HEAP_PROFILER_EXPORT void* calloc(size_t nmemb, size_t size) {
  void* ret = real_calloc(nmemb, size);
  if (ret != NULL)
    unwind_and_record_alloc(ret, nmemb * size, HEAP_PROFILER_FLAGS_MALLOC);
  return ret;
}

HEAP_PROFILER_EXPORT void* realloc(void* ptr, size_t size) {
  void* ret = real_realloc(ptr, size);
  uint32_t flags = 0;
  if (ptr)
    discard_alloc(ptr, 0, &flags);
  if (ret != NULL)
    unwind_and_record_alloc(ret, size, flags | HEAP_PROFILER_FLAGS_MALLOC);
  return ret;
}

HEAP_PROFILER_EXPORT void free(void* ptr) {
  real_free(ptr);
  discard_alloc(ptr, 0, /*old_flags=*/NULL);
}

// +---------------------------------------------------------------------------+
// + Stack unwinder                                                            +
// +---------------------------------------------------------------------------+
typedef struct {
  uintptr_t* frames;
  uint32_t frame_count;
  uint32_t max_depth;
  bool have_skipped_self;
} stack_crawl_state_t;

static _Unwind_Reason_Code unwind_fn(struct _Unwind_Context* ctx, void* arg) {
  stack_crawl_state_t* state = (stack_crawl_state_t*) arg;
  uintptr_t ip = _Unwind_GetIP(ctx);

  if (ip != 0 && !state->have_skipped_self) {
    state->have_skipped_self = true;
    return _URC_NO_REASON;
  }

  state->frames[state->frame_count++] = ip;
  return (state->frame_count >= state->max_depth) ?
          _URC_END_OF_STACK : _URC_NO_REASON;
}

static uint32_t get_backtrace(uintptr_t* frames, uint32_t max_depth) {
  stack_crawl_state_t state = {.frames = frames, .max_depth = max_depth};
  _Unwind_Backtrace(unwind_fn, &state);
  return state.frame_count;
}
