// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MEMORY_DISCARDABLE_SHARED_MEMORY_H_
#define BASE_MEMORY_DISCARDABLE_SHARED_MEMORY_H_

#include "base/base_export.h"
#include "base/logging.h"
#include "base/memory/shared_memory.h"
#include "base/threading/thread_collision_warner.h"
#include "base/time/time.h"

#if DCHECK_IS_ON()
#include <set>
#endif

// Define DISCARDABLE_SHARED_MEMORY_SHRINKING if platform supports shrinking
// of discardable shared memory segments.
#if defined(OS_POSIX) && !defined(OS_ANDROID)
#define DISCARDABLE_SHARED_MEMORY_SHRINKING
#endif

namespace base {

// Platform abstraction for discardable shared memory.
//
// This class is not thread-safe. Clients are responsible for synchronizing
// access to an instance of this class.
class BASE_EXPORT DiscardableSharedMemory {
 public:
  enum LockResult { SUCCESS, PURGED, FAILED };

  DiscardableSharedMemory();

  // Create a new DiscardableSharedMemory object from an existing, open shared
  // memory file. Memory must be locked.
  explicit DiscardableSharedMemory(SharedMemoryHandle handle);

  // Closes any open files.
  virtual ~DiscardableSharedMemory();

  // Creates and maps a locked DiscardableSharedMemory object with |size|.
  // Returns true on success and false on failure.
  bool CreateAndMap(size_t size);

  // Maps the locked discardable memory into the caller's address space.
  // Returns true on success, false otherwise.
  bool Map(size_t size);

  // Unmaps the discardable shared memory from the caller's address space.
  // Returns true if successful; returns false on error or if the memory is
  // not mapped.
  bool Unmap();

  // The actual size of the mapped memory (may be larger than requested).
  size_t mapped_size() const { return mapped_size_; }

  // Returns a shared memory handle for this DiscardableSharedMemory object.
  SharedMemoryHandle handle() const { return shared_memory_.handle(); }

  // Locks a range of memory so that it will not be purged by the system.
  // The range of memory must be unlocked. The result of trying to lock an
  // already locked range is undefined. |offset| and |length| must both be
  // a multiple of the page size as returned by GetPageSize().
  // Passing 0 for |length| means "everything onward".
  // Returns SUCCESS if range was successfully locked and the memory is still
  // resident, PURGED if range was successfully locked but has been purged
  // since last time it was locked and FAILED if range could not be locked.
  // Locking can fail for two reasons; object might have been purged, our
  // last known usage timestamp might be out of date. Last known usage time
  // is updated to the actual last usage timestamp if memory is still resident
  // or 0 if not.
  LockResult Lock(size_t offset, size_t length);

  // Unlock a previously successfully locked range of memory. The range of
  // memory must be locked. The result of trying to unlock a not
  // previously locked range is undefined.
  // |offset| and |length| must both be a multiple of the page size as returned
  // by GetPageSize().
  // Passing 0 for |length| means "everything onward".
  void Unlock(size_t offset, size_t length);

  // Gets a pointer to the opened discardable memory space. Discardable memory
  // must have been mapped via Map().
  void* memory() const;

  // Returns the last known usage time for DiscardableSharedMemory object. This
  // may be earlier than the "true" usage time when memory has been used by a
  // different process. Returns NULL time if purged.
  Time last_known_usage() const { return last_known_usage_; }

  // This returns true and sets |last_known_usage_| to 0 if
  // DiscardableSharedMemory object was successfully purged. Purging can fail
  // for two reasons; object might be locked or our last known usage timestamp
  // might be out of date. Last known usage time is updated to |current_time|
  // if locked or the actual last usage timestamp if unlocked. It is often
  // necessary to call this function twice for the object to successfully be
  // purged. First call, updates |last_known_usage_|. Second call, successfully
  // purges the object using the updated |last_known_usage_|.
  // Note: there is no guarantee that multiple calls to this function will
  // successfully purge object. DiscardableSharedMemory object might be locked
  // or another thread/process might be able to lock and unlock it in between
  // each call.
  bool Purge(Time current_time);

  // Returns true if memory is still resident.
  bool IsMemoryResident() const;

  // Closes the open discardable memory segment.
  // It is safe to call Close repeatedly.
  void Close();

  // Shares the discardable memory segment to another process. Attempts to
  // create a platform-specific |new_handle| which can be used in a remote
  // process to access the discardable memory segment. |new_handle| is an
  // output parameter to receive the handle for use in the remote process.
  // Returns true on success, false otherwise.
  bool ShareToProcess(ProcessHandle process_handle,
                      SharedMemoryHandle* new_handle) {
    return shared_memory_.ShareToProcess(process_handle, new_handle);
  }

#if defined(DISCARDABLE_SHARED_MEMORY_SHRINKING)
  // Release as much memory as possible to the OS. The change in size will
  // be reflected by the return value of mapped_size().
  void Shrink();
#endif

 private:
  // Virtual for tests.
  virtual Time Now() const;

  SharedMemory shared_memory_;
  size_t mapped_size_;
  size_t locked_page_count_;
#if DCHECK_IS_ON()
  std::set<size_t> locked_pages_;
#endif
  // Implementation is not thread-safe but still usable if clients are
  // synchronized somehow. Use a collision warner to detect incorrect usage.
  DFAKE_MUTEX(thread_collision_warner_);
  Time last_known_usage_;

  DISALLOW_COPY_AND_ASSIGN(DiscardableSharedMemory);
};

}  // namespace base

#endif  // BASE_MEMORY_DISCARDABLE_SHARED_MEMORY_H_
