// Copyright (c) 2007, Google Inc.
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
// Author: Arun Sharma
//
// A tcmalloc system allocator that uses a memory based filesystem such as
// tmpfs or hugetlbfs
//
// Since these only exist on linux, we only register this allocator there.

#ifdef __linux

#include <config.h>
#include <errno.h>                      // for errno, EINVAL
#include <inttypes.h>                   // for PRId64
#include <limits.h>                     // for PATH_MAX
#include <stddef.h>                     // for size_t, NULL
#ifdef HAVE_STDINT_H
#include <stdint.h>                     // for int64_t, uintptr_t
#endif
#include <stdio.h>                      // for snprintf
#include <stdlib.h>                     // for mkstemp
#include <string.h>                     // for strerror
#include <sys/mman.h>                   // for mmap, MAP_FAILED, etc
#include <sys/statfs.h>                 // for fstatfs, statfs
#include <unistd.h>                     // for ftruncate, off_t, unlink
#include <new>                          // for operator new
#include <string>

#include <gperftools/malloc_extension.h>
#include "base/basictypes.h"
#include "base/googleinit.h"
#include "base/sysinfo.h"
#include "internal_logging.h"

// TODO(sanjay): Move the code below into the tcmalloc namespace
using tcmalloc::kLog;
using tcmalloc::kCrash;
using tcmalloc::Log;
using std::string;

DEFINE_string(memfs_malloc_path, EnvToString("TCMALLOC_MEMFS_MALLOC_PATH", ""),
              "Path where hugetlbfs or tmpfs is mounted. The caller is "
              "responsible for ensuring that the path is unique and does "
              "not conflict with another process");
DEFINE_int64(memfs_malloc_limit_mb,
             EnvToInt("TCMALLOC_MEMFS_LIMIT_MB", 0),
             "Limit total allocation size to the "
             "specified number of MiB.  0 == no limit.");
DEFINE_bool(memfs_malloc_abort_on_fail,
            EnvToBool("TCMALLOC_MEMFS_ABORT_ON_FAIL", false),
            "abort whenever memfs_malloc fails to satisfy an allocation "
            "for any reason.");
DEFINE_bool(memfs_malloc_ignore_mmap_fail,
            EnvToBool("TCMALLOC_MEMFS_IGNORE_MMAP_FAIL", false),
            "Ignore failures from mmap");
DEFINE_bool(memfs_malloc_map_private,
            EnvToBool("TCMALLOC_MEMFS_MAP_PRIVATE", false),
	    "Use MAP_PRIVATE with mmap");

// Hugetlbfs based allocator for tcmalloc
class HugetlbSysAllocator: public SysAllocator {
public:
  explicit HugetlbSysAllocator(SysAllocator* fallback)
    : failed_(true),  // To disable allocator until Initialize() is called.
      big_page_size_(0),
      hugetlb_fd_(-1),
      hugetlb_base_(0),
      fallback_(fallback) {
  }

  void* Alloc(size_t size, size_t *actual_size, size_t alignment);
  bool Initialize();

  bool failed_;          // Whether failed to allocate memory.

private:
  void* AllocInternal(size_t size, size_t *actual_size, size_t alignment);

  int64 big_page_size_;
  int hugetlb_fd_;       // file descriptor for hugetlb
  off_t hugetlb_base_;

  SysAllocator* fallback_;  // Default system allocator to fall back to.
};
static char hugetlb_space[sizeof(HugetlbSysAllocator)];

// No locking needed here since we assume that tcmalloc calls
// us with an internal lock held (see tcmalloc/system-alloc.cc).
void* HugetlbSysAllocator::Alloc(size_t size, size_t *actual_size,
                                 size_t alignment) {
  if (failed_) {
    return fallback_->Alloc(size, actual_size, alignment);
  }

  // We don't respond to allocation requests smaller than big_page_size_ unless
  // the caller is ok to take more than they asked for. Used by MetaDataAlloc.
  if (actual_size == NULL && size < big_page_size_) {
    return fallback_->Alloc(size, actual_size, alignment);
  }

  // Enforce huge page alignment.  Be careful to deal with overflow.
  size_t new_alignment = alignment;
  if (new_alignment < big_page_size_) new_alignment = big_page_size_;
  size_t aligned_size = ((size + new_alignment - 1) /
                         new_alignment) * new_alignment;
  if (aligned_size < size) {
    return fallback_->Alloc(size, actual_size, alignment);
  }

  void* result = AllocInternal(aligned_size, actual_size, new_alignment);
  if (result != NULL) {
    return result;
  }
  Log(kLog, __FILE__, __LINE__,
      "HugetlbSysAllocator: (failed, allocated)", failed_, hugetlb_base_);
  if (FLAGS_memfs_malloc_abort_on_fail) {
    Log(kCrash, __FILE__, __LINE__,
        "memfs_malloc_abort_on_fail is set");
  }
  return fallback_->Alloc(size, actual_size, alignment);
}

void* HugetlbSysAllocator::AllocInternal(size_t size, size_t* actual_size,
                                         size_t alignment) {
  // Ask for extra memory if alignment > pagesize
  size_t extra = 0;
  if (alignment > big_page_size_) {
    extra = alignment - big_page_size_;
  }

  // Test if this allocation would put us over the limit.
  off_t limit = FLAGS_memfs_malloc_limit_mb*1024*1024;
  if (limit > 0 && hugetlb_base_ + size + extra > limit) {
    // Disable the allocator when there's less than one page left.
    if (limit - hugetlb_base_ < big_page_size_) {
      Log(kLog, __FILE__, __LINE__, "reached memfs_malloc_limit_mb");
      failed_ = true;
    }
    else {
      Log(kLog, __FILE__, __LINE__,
          "alloc too large (size, bytes left)", size, limit-hugetlb_base_);
    }
    return NULL;
  }

  // This is not needed for hugetlbfs, but needed for tmpfs.  Annoyingly
  // hugetlbfs returns EINVAL for ftruncate.
  int ret = ftruncate(hugetlb_fd_, hugetlb_base_ + size + extra);
  if (ret != 0 && errno != EINVAL) {
    Log(kLog, __FILE__, __LINE__,
        "ftruncate failed", strerror(errno));
    failed_ = true;
    return NULL;
  }

  // Note: size + extra does not overflow since:
  //            size + alignment < (1<<NBITS).
  // and        extra <= alignment
  // therefore  size + extra < (1<<NBITS)
  void *result;
  result = mmap(0, size + extra, PROT_WRITE|PROT_READ,
                FLAGS_memfs_malloc_map_private ? MAP_PRIVATE : MAP_SHARED,
                hugetlb_fd_, hugetlb_base_);
  if (result == reinterpret_cast<void*>(MAP_FAILED)) {
    if (!FLAGS_memfs_malloc_ignore_mmap_fail) {
      Log(kLog, __FILE__, __LINE__,
          "mmap failed (size, error)", size + extra, strerror(errno));
      failed_ = true;
    }
    return NULL;
  }
  uintptr_t ptr = reinterpret_cast<uintptr_t>(result);

  // Adjust the return memory so it is aligned
  size_t adjust = 0;
  if ((ptr & (alignment - 1)) != 0) {
    adjust = alignment - (ptr & (alignment - 1));
  }
  ptr += adjust;
  hugetlb_base_ += (size + extra);

  if (actual_size) {
    *actual_size = size + extra - adjust;
  }

  return reinterpret_cast<void*>(ptr);
}

bool HugetlbSysAllocator::Initialize() {
  char path[PATH_MAX];
  const int pathlen = FLAGS_memfs_malloc_path.size();
  if (pathlen + 8 > sizeof(path)) {
    Log(kCrash, __FILE__, __LINE__, "XX fatal: memfs_malloc_path too long");
    return false;
  }
  memcpy(path, FLAGS_memfs_malloc_path.data(), pathlen);
  memcpy(path + pathlen, ".XXXXXX", 8);  // Also copies terminating \0

  int hugetlb_fd = mkstemp(path);
  if (hugetlb_fd == -1) {
    Log(kLog, __FILE__, __LINE__,
        "warning: unable to create memfs_malloc_path",
        path, strerror(errno));
    return false;
  }

  // Cleanup memory on process exit
  if (unlink(path) == -1) {
    Log(kCrash, __FILE__, __LINE__,
        "fatal: error unlinking memfs_malloc_path", path, strerror(errno));
    return false;
  }

  // Use fstatfs to figure out the default page size for memfs
  struct statfs sfs;
  if (fstatfs(hugetlb_fd, &sfs) == -1) {
    Log(kCrash, __FILE__, __LINE__,
        "fatal: error fstatfs of memfs_malloc_path", strerror(errno));
    return false;
  }
  int64 page_size = sfs.f_bsize;

  hugetlb_fd_ = hugetlb_fd;
  big_page_size_ = page_size;
  failed_ = false;
  return true;
}

REGISTER_MODULE_INITIALIZER(memfs_malloc, {
  if (FLAGS_memfs_malloc_path.length()) {
    SysAllocator* alloc = MallocExtension::instance()->GetSystemAllocator();
    HugetlbSysAllocator* hp = new (hugetlb_space) HugetlbSysAllocator(alloc);
    if (hp->Initialize()) {
      MallocExtension::instance()->SetSystemAllocator(hp);
    }
  }
});

#endif   /* ifdef __linux */
