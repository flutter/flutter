// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/memory.h"

#include <new>

#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/process/internal_linux.h"
#include "base/strings/string_number_conversions.h"

#if defined(USE_TCMALLOC)
// Used by UncheckedMalloc. If tcmalloc is linked to the executable
// this will be replaced by a strong symbol that actually implement
// the semantics and don't call new handler in case the allocation fails.
extern "C" {

__attribute__((weak, visibility("default")))
void* tc_malloc_skip_new_handler_weak(size_t size);

void* tc_malloc_skip_new_handler_weak(size_t size) {
  return malloc(size);
}

}
#endif

namespace base {

size_t g_oom_size = 0U;

namespace {

#if !defined(OS_ANDROID)
void OnNoMemorySize(size_t size) {
  g_oom_size = size;

  if (size != 0)
    LOG(FATAL) << "Out of memory, size = " << size;
  LOG(FATAL) << "Out of memory.";
}

void OnNoMemory() {
  OnNoMemorySize(0);
}
#endif  // !defined(OS_ANDROID)

}  // namespace

#if !defined(ADDRESS_SANITIZER) && !defined(MEMORY_SANITIZER) && \
    !defined(THREAD_SANITIZER) && !defined(LEAK_SANITIZER)

#if defined(LIBC_GLIBC) && !defined(USE_TCMALLOC)

extern "C" {
void* __libc_malloc(size_t size);
void* __libc_realloc(void* ptr, size_t size);
void* __libc_calloc(size_t nmemb, size_t size);
void* __libc_valloc(size_t size);
#if PVALLOC_AVAILABLE == 1
void* __libc_pvalloc(size_t size);
#endif
void* __libc_memalign(size_t alignment, size_t size);

// Overriding the system memory allocation functions:
//
// For security reasons, we want malloc failures to be fatal. Too much code
// doesn't check for a NULL return value from malloc and unconditionally uses
// the resulting pointer. If the first offset that they try to access is
// attacker controlled, then the attacker can direct the code to access any
// part of memory.
//
// Thus, we define all the standard malloc functions here and mark them as
// visibility 'default'. This means that they replace the malloc functions for
// all Chromium code and also for all code in shared libraries. There are tests
// for this in process_util_unittest.cc.
//
// If we are using tcmalloc, then the problem is moot since tcmalloc handles
// this for us. Thus this code is in a !defined(USE_TCMALLOC) block.
//
// If we are testing the binary with AddressSanitizer, we should not
// redefine malloc and let AddressSanitizer do it instead.
//
// We call the real libc functions in this code by using __libc_malloc etc.
// Previously we tried using dlsym(RTLD_NEXT, ...) but that failed depending on
// the link order. Since ld.so needs calloc during symbol resolution, it
// defines its own versions of several of these functions in dl-minimal.c.
// Depending on the runtime library order, dlsym ended up giving us those
// functions and bad things happened. See crbug.com/31809
//
// This means that any code which calls __libc_* gets the raw libc versions of
// these functions.

#define DIE_ON_OOM_1(function_name) \
  void* function_name(size_t) __attribute__ ((visibility("default"))); \
  \
  void* function_name(size_t size) { \
    void* ret = __libc_##function_name(size); \
    if (ret == NULL && size != 0) \
      OnNoMemorySize(size); \
    return ret; \
  }

#define DIE_ON_OOM_2(function_name, arg1_type) \
  void* function_name(arg1_type, size_t) \
      __attribute__ ((visibility("default"))); \
  \
  void* function_name(arg1_type arg1, size_t size) { \
    void* ret = __libc_##function_name(arg1, size); \
    if (ret == NULL && size != 0) \
      OnNoMemorySize(size); \
    return ret; \
  }

DIE_ON_OOM_1(malloc)
DIE_ON_OOM_1(valloc)
#if PVALLOC_AVAILABLE == 1
DIE_ON_OOM_1(pvalloc)
#endif

DIE_ON_OOM_2(calloc, size_t)
DIE_ON_OOM_2(realloc, void*)
DIE_ON_OOM_2(memalign, size_t)

// posix_memalign has a unique signature and doesn't have a __libc_ variant.
int posix_memalign(void** ptr, size_t alignment, size_t size)
    __attribute__ ((visibility("default")));

int posix_memalign(void** ptr, size_t alignment, size_t size) {
  // This will use the safe version of memalign, above.
  *ptr = memalign(alignment, size);
  return 0;
}

}  // extern C

#else

// TODO(mostynb@opera.com): dlsym dance

#endif  // LIBC_GLIBC && !USE_TCMALLOC

#endif  // !*_SANITIZER

void EnableTerminationOnHeapCorruption() {
  // On Linux, there nothing to do AFAIK.
}

void EnableTerminationOnOutOfMemory() {
#if defined(OS_ANDROID)
  // Android doesn't support setting a new handler.
  DLOG(WARNING) << "Not feasible.";
#else
  // Set the new-out of memory handler.
  std::set_new_handler(&OnNoMemory);
  // If we're using glibc's allocator, the above functions will override
  // malloc and friends and make them die on out of memory.
#endif
}

// NOTE: This is not the only version of this function in the source:
// the setuid sandbox (in process_util_linux.c, in the sandbox source)
// also has its own C version.
bool AdjustOOMScore(ProcessId process, int score) {
  if (score < 0 || score > kMaxOomScore)
    return false;

  FilePath oom_path(internal::GetProcPidDir(process));

  // Attempt to write the newer oom_score_adj file first.
  FilePath oom_file = oom_path.AppendASCII("oom_score_adj");
  if (PathExists(oom_file)) {
    std::string score_str = IntToString(score);
    DVLOG(1) << "Adjusting oom_score_adj of " << process << " to "
             << score_str;
    int score_len = static_cast<int>(score_str.length());
    return (score_len == WriteFile(oom_file, score_str.c_str(), score_len));
  }

  // If the oom_score_adj file doesn't exist, then we write the old
  // style file and translate the oom_adj score to the range 0-15.
  oom_file = oom_path.AppendASCII("oom_adj");
  if (PathExists(oom_file)) {
    // Max score for the old oom_adj range.  Used for conversion of new
    // values to old values.
    const int kMaxOldOomScore = 15;

    int converted_score = score * kMaxOldOomScore / kMaxOomScore;
    std::string score_str = IntToString(converted_score);
    DVLOG(1) << "Adjusting oom_adj of " << process << " to " << score_str;
    int score_len = static_cast<int>(score_str.length());
    return (score_len == WriteFile(oom_file, score_str.c_str(), score_len));
  }

  return false;
}

bool UncheckedMalloc(size_t size, void** result) {
#if defined(MEMORY_TOOL_REPLACES_ALLOCATOR) || \
    (!defined(LIBC_GLIBC) && !defined(USE_TCMALLOC))
  *result = malloc(size);
#elif defined(LIBC_GLIBC) && !defined(USE_TCMALLOC)
  *result = __libc_malloc(size);
#elif defined(USE_TCMALLOC)
  *result = tc_malloc_skip_new_handler_weak(size);
#endif
  return *result != NULL;
}

}  // namespace base
