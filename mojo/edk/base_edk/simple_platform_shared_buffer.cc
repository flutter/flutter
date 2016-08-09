// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file implements the factory functions declared in
// //mojo/edk/platform/simple_platform_shared_buffer.h.

#include "mojo/edk/platform/simple_platform_shared_buffer.h"

#include <stdint.h>
#include <stdio.h>     // For |fileno()|.
#include <sys/mman.h>  // For |mmap()|/|munmap()|.
#include <sys/stat.h>
#include <sys/types.h>  // For |off_t|.
#include <unistd.h>

#include <limits>
#include <utility>

#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/posix/eintr_wrapper.h"
#include "base/threading/thread_restrictions.h"
#include "build/build_config.h"
#include "mojo/edk/util/scoped_file.h"
#include "mojo/public/cpp/system/macros.h"

#if defined(OS_ANDROID)
#include "third_party/ashmem/ashmem.h"
#endif  // defined(OS_ANDROID)

using mojo::util::RefPtr;

// We assume that |size_t| and |off_t| (type for |ftruncate()|) fits in a
// |uint64_t|.
static_assert(sizeof(size_t) <= sizeof(uint64_t), "size_t too big");
static_assert(sizeof(off_t) <= sizeof(uint64_t), "off_t too big");

namespace mojo {
namespace platform {
namespace {

// SimplePlatformSharedBufferMapping -------------------------------------------

// An implementation of |PlatformSharedBufferMapping|, produced by
// |SimplePlatformSharedBuffer| (declared further below).
class SimplePlatformSharedBufferMapping final
    : public PlatformSharedBufferMapping {
 public:
  ~SimplePlatformSharedBufferMapping() override { Unmap(); }

  void* GetBase() const override { return base_; }
  size_t GetLength() const override { return length_; }

 private:
  friend class SimplePlatformSharedBuffer;

  SimplePlatformSharedBufferMapping(void* base,
                                    size_t length,
                                    void* real_base,
                                    size_t real_length)
      : base_(base),
        length_(length),
        real_base_(real_base),
        real_length_(real_length) {}

  void Unmap() {
    int result = munmap(real_base_, real_length_);
    PLOG_IF(ERROR, result != 0) << "munmap";
  }

  void* const base_;
  const size_t length_;

  void* const real_base_;
  const size_t real_length_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(SimplePlatformSharedBufferMapping);
};

// SimplePlatformSharedBuffer --------------------------------------------------

// A simple implementation of |PlatformSharedBuffer|.
class SimplePlatformSharedBuffer final : public PlatformSharedBuffer {
 public:
  explicit SimplePlatformSharedBuffer(size_t num_bytes)
      : num_bytes_(num_bytes) {}

  // This is called by |CreateSimplePlatformSharedBuffer()| before this object
  // is given to anyone.
  bool Init();

  // This is like |Init()|, but for
  // |CreateSimplePlatformSharedBufferFromPlatformHandle()|. (Note: It should
  // verify that |platform_handle| is an appropriate handle for the claimed
  // |num_bytes_|.)
  bool InitFromPlatformHandle(ScopedPlatformHandle platform_handle);

  // |PlatformSharedBuffer| implementation:
  size_t GetNumBytes() const override;
  std::unique_ptr<PlatformSharedBufferMapping> Map(size_t offset,
                                                   size_t length) override;
  bool IsValidMap(size_t offset, size_t length) override;
  std::unique_ptr<PlatformSharedBufferMapping> MapNoCheck(
      size_t offset,
      size_t length) override;
  ScopedPlatformHandle DuplicatePlatformHandle() override;
  ScopedPlatformHandle PassPlatformHandle() override;

 private:
  ~SimplePlatformSharedBuffer() override {}

  const size_t num_bytes_;

  // This is set in |Init()|/|InitFromPlatformHandle()| and never modified
  // (except by |PassPlatformHandle()|; see the comments above its declaration),
  // hence does not need to be protected by a lock.
  ScopedPlatformHandle handle_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(SimplePlatformSharedBuffer);
};

bool SimplePlatformSharedBuffer::Init() {
  DCHECK(!handle_.is_valid());

  if (static_cast<uint64_t>(num_bytes_) >
      static_cast<uint64_t>(std::numeric_limits<off_t>::max())) {
    return false;
  }

  ScopedPlatformHandle handle;

// Use ashmem on Android.
#if defined(OS_ANDROID)
  handle.reset(PlatformHandle(ashmem_create_region(nullptr, num_bytes_)));
  if (!handle.is_valid()) {
    DPLOG(ERROR) << "ashmem_create_region()";
    return false;
  }

  if (ashmem_set_prot_region(handle.get().fd, PROT_READ | PROT_WRITE) < 0) {
    DPLOG(ERROR) << "ashmem_set_prot_region()";
    return false;
  }
#else
  base::ThreadRestrictions::ScopedAllowIO allow_io;

  // TODO(vtl): This is stupid. The implementation of
  // |CreateAndOpenTemporaryFileInDir()| starts with an FD, |fdopen()|s to get a
  // |FILE*|, and then we have to |dup(fileno(fp))| to get back to an FD that we
  // can own. (base/memory/shared_memory_posix.cc does this too, with more
  // |fstat()|s thrown in for good measure.)
  base::FilePath shared_buffer_dir;
  if (!base::GetShmemTempDir(false, &shared_buffer_dir)) {
    LOG(ERROR) << "Failed to get temporary directory for shared memory";
    return false;
  }
  base::FilePath shared_buffer_file;
  util::ScopedFILE fp(base::CreateAndOpenTemporaryFileInDir(
      shared_buffer_dir, &shared_buffer_file));
  if (!fp) {
    LOG(ERROR) << "Failed to create/open temporary file for shared memory";
    return false;
  }
  // Note: |unlink()| is not interruptible.
  if (unlink(shared_buffer_file.value().c_str()) != 0) {
    PLOG(WARNING) << "unlink";
    // This isn't "fatal" (e.g., someone else may have unlinked the file first),
    // so we may as well continue.
  }

  // Note: |dup()| is not interruptible (but |dup2()|/|dup3()| are).
  handle.reset(PlatformHandle(dup(fileno(fp.get()))));
  if (!handle.is_valid()) {
    PLOG(ERROR) << "dup";
    return false;
  }

  if (HANDLE_EINTR(
          ftruncate(handle.get().fd, static_cast<off_t>(num_bytes_))) != 0) {
    PLOG(ERROR) << "ftruncate";
    return false;
  }
#endif  // defined(OS_ANDROID)

  handle_ = std::move(handle);
  return true;
}

bool SimplePlatformSharedBuffer::InitFromPlatformHandle(
    ScopedPlatformHandle platform_handle) {
  DCHECK(!handle_.is_valid());

  if (static_cast<uint64_t>(num_bytes_) >
      static_cast<uint64_t>(std::numeric_limits<off_t>::max())) {
    return false;
  }

// Use ashmem on Android.
#if defined(OS_ANDROID)
  int size = ashmem_get_size_region(platform_handle.get().fd);
  if (size < 0) {
    DPLOG(ERROR) << "ashmem_get_size_region()";
    return false;
  }

  if (static_cast<size_t>(size) != num_bytes_) {
    LOG(ERROR) << "Shared memory region has the wrong size";
    return false;
  }
#else
  struct stat sb = {};
  // Note: |fstat()| isn't interruptible.
  if (fstat(platform_handle.get().fd, &sb) != 0) {
    PLOG(ERROR) << "fstat";
    return false;
  }

  if (!S_ISREG(sb.st_mode)) {
    LOG(ERROR) << "Platform handle not to a regular file";
    return false;
  }

  if (sb.st_size != static_cast<off_t>(num_bytes_)) {
    LOG(ERROR) << "Shared memory file has the wrong size";
    return false;
  }

// TODO(vtl): More checks?
#endif  // defined(OS_ANDROID)

  handle_ = platform_handle.Pass();
  return true;
}

size_t SimplePlatformSharedBuffer::GetNumBytes() const {
  return num_bytes_;
}

std::unique_ptr<PlatformSharedBufferMapping> SimplePlatformSharedBuffer::Map(
    size_t offset,
    size_t length) {
  if (!IsValidMap(offset, length))
    return nullptr;

  return MapNoCheck(offset, length);
}

bool SimplePlatformSharedBuffer::IsValidMap(size_t offset, size_t length) {
  if (offset > num_bytes_ || length == 0)
    return false;

  // Note: This is an overflow-safe check of |offset + length > num_bytes_|
  // (that |num_bytes >= offset| is verified above).
  if (length > num_bytes_ - offset)
    return false;

  return true;
}

std::unique_ptr<PlatformSharedBufferMapping>
SimplePlatformSharedBuffer::MapNoCheck(size_t offset, size_t length) {
  DCHECK(IsValidMap(offset, length));

  long page_size = sysconf(_SC_PAGESIZE);
  // This is a Debug-only check, since (according to POSIX), the only possible
  // error is EINVAL (if the argument is unrecognized).
  DPCHECK(page_size != -1);
  size_t offset_rounding = offset % static_cast<size_t>(page_size);
  size_t real_offset = offset - offset_rounding;
  size_t real_length = length + offset_rounding;

  // This should hold (since we checked |num_bytes| versus the maximum value of
  // |off_t| on creation, but it never hurts to be paranoid.
  DCHECK_LE(static_cast<uint64_t>(real_offset),
            static_cast<uint64_t>(std::numeric_limits<off_t>::max()));

  void* real_base =
      mmap(nullptr, real_length, PROT_READ | PROT_WRITE, MAP_SHARED,
           handle_.get().fd, static_cast<off_t>(real_offset));
  // |mmap()| should return |MAP_FAILED| (a.k.a. -1) on error. But it shouldn't
  // return null either.
  if (real_base == MAP_FAILED || !real_base) {
    PLOG(ERROR) << "mmap";
    return nullptr;
  }

  void* base = static_cast<char*>(real_base) + offset_rounding;
  // Note: We can't use |MakeUnique| here, since it's not a friend of
  // |SimplePlatformSharedBufferMapping| (only we are).
  return std::unique_ptr<SimplePlatformSharedBufferMapping>(
      new SimplePlatformSharedBufferMapping(base, length, real_base,
                                            real_length));
}

ScopedPlatformHandle SimplePlatformSharedBuffer::DuplicatePlatformHandle() {
  return handle_.Duplicate();
}

ScopedPlatformHandle SimplePlatformSharedBuffer::PassPlatformHandle() {
  DCHECK(HasOneRef());
  return std::move(handle_);
}

}  // namespace

// Public factory functions ----------------------------------------------------

util::RefPtr<PlatformSharedBuffer> CreateSimplePlatformSharedBuffer(
    size_t num_bytes) {
  DCHECK_GT(num_bytes, 0u);

  RefPtr<SimplePlatformSharedBuffer> rv(
      AdoptRef(new SimplePlatformSharedBuffer(num_bytes)));
  return rv->Init() ? rv : nullptr;
}

RefPtr<PlatformSharedBuffer> CreateSimplePlatformSharedBufferFromPlatformHandle(
    size_t num_bytes,
    ScopedPlatformHandle platform_handle) {
  DCHECK_GT(num_bytes, 0u);

  RefPtr<SimplePlatformSharedBuffer> rv(
      AdoptRef(new SimplePlatformSharedBuffer(num_bytes)));
  return rv->InitFromPlatformHandle(std::move(platform_handle)) ? rv : nullptr;
}

}  // namespace platform
}  // namespace mojo
