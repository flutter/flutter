// Copyright (c) 2005, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// Author: Sanjay Ghemawat <opensource@google.com>

// We define mmap() and mmap64(), which somewhat reimplements libc's mmap
// syscall stubs.  Unfortunately libc only exports the stubs via weak symbols
// (which we're overriding with our mmap64() and mmap() wrappers) so we can't
// just call through to them.

#ifndef __linux
# error Should only be including malloc_hook_mmap_linux.h on linux systems.
#endif

#include <unistd.h>
#include <syscall.h>
#include <sys/mman.h>
#include <errno.h>
#include "base/linux_syscall_support.h"

// The x86-32 case and the x86-64 case differ:
// 32b has a mmap2() syscall, 64b does not.
// 64b and 32b have different calling conventions for mmap().

// I test for 64-bit first so I don't have to do things like
// '#if (defined(__mips__) && !defined(__MIPS64__))' as a mips32 check.
#if defined(__x86_64__) || defined(__PPC64__) || (defined(_MIPS_SIM) && _MIPS_SIM == _ABI64)

static inline void* do_mmap64(void *start, size_t length,
                              int prot, int flags,
                              int fd, __off64_t offset) __THROW {
  return sys_mmap(start, length, prot, flags, fd, offset);
}

#define MALLOC_HOOK_HAVE_DO_MMAP64 1

#elif defined(__i386__) || defined(__PPC__) || defined(__mips__) || \
      defined(__arm__)

static inline void* do_mmap64(void *start, size_t length,
                              int prot, int flags,
                              int fd, __off64_t offset) __THROW {
  void *result;

  // Try mmap2() unless it's not supported
  static bool have_mmap2 = true;
  if (have_mmap2) {
    static int pagesize = 0;
    if (!pagesize) pagesize = getpagesize();

    // Check that the offset is page aligned
    if (offset & (pagesize - 1)) {
      result = MAP_FAILED;
      errno = EINVAL;
      goto out;
    }

    result = (void *)syscall(SYS_mmap2,
                             start, length, prot, flags, fd,
                             (off_t) (offset / pagesize));
    if (result != MAP_FAILED || errno != ENOSYS)  goto out;

    // We don't have mmap2() after all - don't bother trying it in future
    have_mmap2 = false;
  }

  if (((off_t)offset) != offset) {
    // If we're trying to map a 64-bit offset, fail now since we don't
    // have 64-bit mmap() support.
    result = MAP_FAILED;
    errno = EINVAL;
    goto out;
  }

#ifdef __NR_mmap
  {
    // Fall back to old 32-bit offset mmap() call
    // Old syscall interface cannot handle six args, so pass in an array
    int32 args[6] = { (int32) start, (int32) length, prot, flags, fd,
                      (off_t) offset };
    result = (void *)syscall(SYS_mmap, args);
  }
#else
  // Some Linux ports like ARM EABI Linux has no mmap, just mmap2.
  result = MAP_FAILED;
#endif

 out:
  return result;
}

#define MALLOC_HOOK_HAVE_DO_MMAP64 1

#endif  // #if defined(__x86_64__)


#ifdef MALLOC_HOOK_HAVE_DO_MMAP64

// We use do_mmap64 abstraction to put MallocHook::InvokeMmapHook
// calls right into mmap and mmap64, so that the stack frames in the caller's
// stack are at the same offsets for all the calls of memory allocating
// functions.

// Put all callers of MallocHook::Invoke* in this module into
// malloc_hook section,
// so that MallocHook::GetCallerStackTrace can function accurately:

// Make sure mmap doesn't get #define'd away by <sys/mman.h>
# undef mmap

extern "C" {
  void* mmap64(void *start, size_t length, int prot, int flags,
               int fd, __off64_t offset  ) __THROW
    ATTRIBUTE_SECTION(malloc_hook);
  void* mmap(void *start, size_t length,int prot, int flags,
             int fd, off_t offset) __THROW
    ATTRIBUTE_SECTION(malloc_hook);
  int munmap(void* start, size_t length) __THROW
    ATTRIBUTE_SECTION(malloc_hook);
  void* mremap(void* old_addr, size_t old_size, size_t new_size,
               int flags, ...) __THROW
    ATTRIBUTE_SECTION(malloc_hook);
  void* sbrk(ptrdiff_t increment) __THROW
    ATTRIBUTE_SECTION(malloc_hook);
}

extern "C" void* mmap64(void *start, size_t length, int prot, int flags,
                        int fd, __off64_t offset) __THROW {
  MallocHook::InvokePreMmapHook(start, length, prot, flags, fd, offset);
  void *result;
  if (!MallocHook::InvokeMmapReplacement(
          start, length, prot, flags, fd, offset, &result)) {
    result = do_mmap64(start, length, prot, flags, fd, offset);
  }
  MallocHook::InvokeMmapHook(result, start, length, prot, flags, fd, offset);
  return result;
}

# if !defined(__USE_FILE_OFFSET64) || !defined(__REDIRECT_NTH)

extern "C" void* mmap(void *start, size_t length, int prot, int flags,
                      int fd, off_t offset) __THROW {
  MallocHook::InvokePreMmapHook(start, length, prot, flags, fd, offset);
  void *result;
  if (!MallocHook::InvokeMmapReplacement(
          start, length, prot, flags, fd, offset, &result)) {
    result = do_mmap64(start, length, prot, flags, fd,
                       static_cast<size_t>(offset)); // avoid sign extension
  }
  MallocHook::InvokeMmapHook(result, start, length, prot, flags, fd, offset);
  return result;
}

# endif  // !defined(__USE_FILE_OFFSET64) || !defined(__REDIRECT_NTH)

extern "C" int munmap(void* start, size_t length) __THROW {
  MallocHook::InvokeMunmapHook(start, length);
  int result;
  if (!MallocHook::InvokeMunmapReplacement(start, length, &result)) {
    result = sys_munmap(start, length);
  }
  return result;
}

extern "C" void* mremap(void* old_addr, size_t old_size, size_t new_size,
                        int flags, ...) __THROW {
  va_list ap;
  va_start(ap, flags);
  void *new_address = va_arg(ap, void *);
  va_end(ap);
  void* result = sys_mremap(old_addr, old_size, new_size, flags, new_address);
  MallocHook::InvokeMremapHook(result, old_addr, old_size, new_size, flags,
                               new_address);
  return result;
}

// libc's version:
extern "C" void* __sbrk(ptrdiff_t increment);

extern "C" void* sbrk(ptrdiff_t increment) __THROW {
  MallocHook::InvokePreSbrkHook(increment);
  void *result = __sbrk(increment);
  MallocHook::InvokeSbrkHook(result, increment);
  return result;
}

/*static*/void* MallocHook::UnhookedMMap(void *start, size_t length, int prot,
                                         int flags, int fd, off_t offset) {
  void* result;
  if (!MallocHook::InvokeMmapReplacement(
          start, length, prot, flags, fd, offset, &result)) {
    result = do_mmap64(start, length, prot, flags, fd, offset);
  }
  return result;
}

/*static*/int MallocHook::UnhookedMUnmap(void *start, size_t length) {
  int result;
  if (!MallocHook::InvokeMunmapReplacement(start, length, &result)) {
    result = syscall(SYS_munmap, start, length);
  }
  return result;
}

#undef MALLOC_HOOK_HAVE_DO_MMAP64

#endif  // #ifdef MALLOC_HOOK_HAVE_DO_MMAP64
