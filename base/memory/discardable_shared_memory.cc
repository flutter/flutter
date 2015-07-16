// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/discardable_shared_memory.h"

#if defined(OS_POSIX)
#include <unistd.h>
#endif

#include <algorithm>

#include "base/atomicops.h"
#include "base/logging.h"
#include "base/numerics/safe_math.h"
#include "base/process/process_metrics.h"

#if defined(OS_ANDROID)
#include "third_party/ashmem/ashmem.h"
#endif

namespace base {
namespace {

// Use a machine-sized pointer as atomic type. It will use the Atomic32 or
// Atomic64 routines, depending on the architecture.
typedef intptr_t AtomicType;
typedef uintptr_t UAtomicType;

// Template specialization for timestamp serialization/deserialization. This
// is used to serialize timestamps using Unix time on systems where AtomicType
// does not have enough precision to contain a timestamp in the standard
// serialized format.
template <int>
Time TimeFromWireFormat(int64 value);
template <int>
int64 TimeToWireFormat(Time time);

// Serialize to Unix time when using 4-byte wire format.
// Note: 19 January 2038, this will cease to work.
template <>
Time ALLOW_UNUSED_TYPE TimeFromWireFormat<4>(int64 value) {
  return value ? Time::UnixEpoch() + TimeDelta::FromSeconds(value) : Time();
}
template <>
int64 ALLOW_UNUSED_TYPE TimeToWireFormat<4>(Time time) {
  return time > Time::UnixEpoch() ? (time - Time::UnixEpoch()).InSeconds() : 0;
}

// Standard serialization format when using 8-byte wire format.
template <>
Time ALLOW_UNUSED_TYPE TimeFromWireFormat<8>(int64 value) {
  return Time::FromInternalValue(value);
}
template <>
int64 ALLOW_UNUSED_TYPE TimeToWireFormat<8>(Time time) {
  return time.ToInternalValue();
}

struct SharedState {
  enum LockState { UNLOCKED = 0, LOCKED = 1 };

  explicit SharedState(AtomicType ivalue) { value.i = ivalue; }
  SharedState(LockState lock_state, Time timestamp) {
    int64 wire_timestamp = TimeToWireFormat<sizeof(AtomicType)>(timestamp);
    DCHECK_GE(wire_timestamp, 0);
    DCHECK_EQ(lock_state & ~1, 0);
    value.u = (static_cast<UAtomicType>(wire_timestamp) << 1) | lock_state;
  }

  LockState GetLockState() const { return static_cast<LockState>(value.u & 1); }

  Time GetTimestamp() const {
    return TimeFromWireFormat<sizeof(AtomicType)>(value.u >> 1);
  }

  // Bit 1: Lock state. Bit is set when locked.
  // Bit 2..sizeof(AtomicType)*8: Usage timestamp. NULL time when locked or
  // purged.
  union {
    AtomicType i;
    UAtomicType u;
  } value;
};

// Shared state is stored at offset 0 in shared memory segments.
SharedState* SharedStateFromSharedMemory(const SharedMemory& shared_memory) {
  DCHECK(shared_memory.memory());
  return static_cast<SharedState*>(shared_memory.memory());
}

// Round up |size| to a multiple of alignment, which must be a power of two.
size_t Align(size_t alignment, size_t size) {
  DCHECK_EQ(alignment & (alignment - 1), 0u);
  return (size + alignment - 1) & ~(alignment - 1);
}

// Round up |size| to a multiple of page size.
size_t AlignToPageSize(size_t size) {
  return Align(base::GetPageSize(), size);
}

}  // namespace

DiscardableSharedMemory::DiscardableSharedMemory()
    : mapped_size_(0), locked_page_count_(0) {
}

DiscardableSharedMemory::DiscardableSharedMemory(
    SharedMemoryHandle shared_memory_handle)
    : shared_memory_(shared_memory_handle, false),
      mapped_size_(0),
      locked_page_count_(0) {
}

DiscardableSharedMemory::~DiscardableSharedMemory() {
}

bool DiscardableSharedMemory::CreateAndMap(size_t size) {
  CheckedNumeric<size_t> checked_size = size;
  checked_size += AlignToPageSize(sizeof(SharedState));
  if (!checked_size.IsValid())
    return false;

  if (!shared_memory_.CreateAndMapAnonymous(checked_size.ValueOrDie()))
    return false;

  mapped_size_ =
      shared_memory_.mapped_size() - AlignToPageSize(sizeof(SharedState));

  locked_page_count_ = AlignToPageSize(mapped_size_) / base::GetPageSize();
#if DCHECK_IS_ON()
  for (size_t page = 0; page < locked_page_count_; ++page)
    locked_pages_.insert(page);
#endif

  DCHECK(last_known_usage_.is_null());
  SharedState new_state(SharedState::LOCKED, Time());
  subtle::Release_Store(&SharedStateFromSharedMemory(shared_memory_)->value.i,
                        new_state.value.i);
  return true;
}

bool DiscardableSharedMemory::Map(size_t size) {
  if (!shared_memory_.Map(AlignToPageSize(sizeof(SharedState)) + size))
    return false;

  mapped_size_ =
      shared_memory_.mapped_size() - AlignToPageSize(sizeof(SharedState));

  locked_page_count_ = AlignToPageSize(mapped_size_) / base::GetPageSize();
#if DCHECK_IS_ON()
  for (size_t page = 0; page < locked_page_count_; ++page)
    locked_pages_.insert(page);
#endif

  return true;
}

bool DiscardableSharedMemory::Unmap() {
  if (!shared_memory_.Unmap())
    return false;

  mapped_size_ = 0;
  return true;
}

DiscardableSharedMemory::LockResult DiscardableSharedMemory::Lock(
    size_t offset, size_t length) {
  DCHECK_EQ(AlignToPageSize(offset), offset);
  DCHECK_EQ(AlignToPageSize(length), length);

  // Calls to this function must be synchronized properly.
  DFAKE_SCOPED_LOCK(thread_collision_warner_);

  DCHECK(shared_memory_.memory());

  // We need to successfully acquire the platform independent lock before
  // individual pages can be locked.
  if (!locked_page_count_) {
    // Return false when instance has been purged or not initialized properly
    // by checking if |last_known_usage_| is NULL.
    if (last_known_usage_.is_null())
      return FAILED;

    SharedState old_state(SharedState::UNLOCKED, last_known_usage_);
    SharedState new_state(SharedState::LOCKED, Time());
    SharedState result(subtle::Acquire_CompareAndSwap(
        &SharedStateFromSharedMemory(shared_memory_)->value.i,
        old_state.value.i,
        new_state.value.i));
    if (result.value.u != old_state.value.u) {
      // Update |last_known_usage_| in case the above CAS failed because of
      // an incorrect timestamp.
      last_known_usage_ = result.GetTimestamp();
      return FAILED;
    }
  }

  // Zero for length means "everything onward".
  if (!length)
    length = AlignToPageSize(mapped_size_) - offset;

  size_t start = offset / base::GetPageSize();
  size_t end = start + length / base::GetPageSize();
  DCHECK_LT(start, end);
  DCHECK_LE(end, AlignToPageSize(mapped_size_) / base::GetPageSize());

  // Add pages to |locked_page_count_|.
  // Note: Locking a page that is already locked is an error.
  locked_page_count_ += end - start;
#if DCHECK_IS_ON()
  // Detect incorrect usage by keeping track of exactly what pages are locked.
  for (auto page = start; page < end; ++page) {
    auto result = locked_pages_.insert(page);
    DCHECK(result.second);
  }
  DCHECK_EQ(locked_pages_.size(), locked_page_count_);
#endif

#if defined(OS_ANDROID)
  SharedMemoryHandle handle = shared_memory_.handle();
  if (SharedMemory::IsHandleValid(handle)) {
    if (ashmem_pin_region(
            handle.fd, AlignToPageSize(sizeof(SharedState)) + offset, length)) {
      return PURGED;
    }
  }
#endif

  return SUCCESS;
}

void DiscardableSharedMemory::Unlock(size_t offset, size_t length) {
  DCHECK_EQ(AlignToPageSize(offset), offset);
  DCHECK_EQ(AlignToPageSize(length), length);

  // Calls to this function must be synchronized properly.
  DFAKE_SCOPED_LOCK(thread_collision_warner_);

  // Zero for length means "everything onward".
  if (!length)
    length = AlignToPageSize(mapped_size_) - offset;

  DCHECK(shared_memory_.memory());

#if defined(OS_ANDROID)
  SharedMemoryHandle handle = shared_memory_.handle();
  if (SharedMemory::IsHandleValid(handle)) {
    if (ashmem_unpin_region(
            handle.fd, AlignToPageSize(sizeof(SharedState)) + offset, length)) {
      DPLOG(ERROR) << "ashmem_unpin_region() failed";
    }
  }
#endif

  size_t start = offset / base::GetPageSize();
  size_t end = start + length / base::GetPageSize();
  DCHECK_LT(start, end);
  DCHECK_LE(end, AlignToPageSize(mapped_size_) / base::GetPageSize());

  // Remove pages from |locked_page_count_|.
  // Note: Unlocking a page that is not locked is an error.
  DCHECK_GE(locked_page_count_, end - start);
  locked_page_count_ -= end - start;
#if DCHECK_IS_ON()
  // Detect incorrect usage by keeping track of exactly what pages are locked.
  for (auto page = start; page < end; ++page) {
    auto erased_count = locked_pages_.erase(page);
    DCHECK_EQ(1u, erased_count);
  }
  DCHECK_EQ(locked_pages_.size(), locked_page_count_);
#endif

  // Early out and avoid releasing the platform independent lock if some pages
  // are still locked.
  if (locked_page_count_)
    return;

  Time current_time = Now();
  DCHECK(!current_time.is_null());

  SharedState old_state(SharedState::LOCKED, Time());
  SharedState new_state(SharedState::UNLOCKED, current_time);
  // Note: timestamp cannot be NULL as that is a unique value used when
  // locked or purged.
  DCHECK(!new_state.GetTimestamp().is_null());
  // Timestamp precision should at least be accurate to the second.
  DCHECK_EQ((new_state.GetTimestamp() - Time::UnixEpoch()).InSeconds(),
            (current_time - Time::UnixEpoch()).InSeconds());
  SharedState result(subtle::Release_CompareAndSwap(
      &SharedStateFromSharedMemory(shared_memory_)->value.i,
      old_state.value.i,
      new_state.value.i));

  DCHECK_EQ(old_state.value.u, result.value.u);

  last_known_usage_ = current_time;
}

void* DiscardableSharedMemory::memory() const {
  return reinterpret_cast<uint8*>(shared_memory_.memory()) +
         AlignToPageSize(sizeof(SharedState));
}

bool DiscardableSharedMemory::Purge(Time current_time) {
  // Calls to this function must be synchronized properly.
  DFAKE_SCOPED_LOCK(thread_collision_warner_);

  // Early out if not mapped. This can happen if the segment was previously
  // unmapped using a call to Close().
  if (!shared_memory_.memory())
    return true;

  SharedState old_state(SharedState::UNLOCKED, last_known_usage_);
  SharedState new_state(SharedState::UNLOCKED, Time());
  SharedState result(subtle::Acquire_CompareAndSwap(
      &SharedStateFromSharedMemory(shared_memory_)->value.i,
      old_state.value.i,
      new_state.value.i));

  // Update |last_known_usage_| to |current_time| if the memory is locked. This
  // allows the caller to determine if purging failed because last known usage
  // was incorrect or memory was locked. In the second case, the caller should
  // most likely wait for some amount of time before attempting to purge the
  // the memory again.
  if (result.value.u != old_state.value.u) {
    last_known_usage_ = result.GetLockState() == SharedState::LOCKED
                            ? current_time
                            : result.GetTimestamp();
    return false;
  }

  last_known_usage_ = Time();
  return true;
}

bool DiscardableSharedMemory::IsMemoryResident() const {
  DCHECK(shared_memory_.memory());

  SharedState result(subtle::NoBarrier_Load(
      &SharedStateFromSharedMemory(shared_memory_)->value.i));

  return result.GetLockState() == SharedState::LOCKED ||
         !result.GetTimestamp().is_null();
}

void DiscardableSharedMemory::Close() {
  shared_memory_.Close();
}

#if defined(DISCARDABLE_SHARED_MEMORY_SHRINKING)
void DiscardableSharedMemory::Shrink() {
#if defined(OS_POSIX)
  SharedMemoryHandle handle = shared_memory_.handle();
  if (!SharedMemory::IsHandleValid(handle))
    return;

  // Truncate shared memory to size of SharedState.
  if (HANDLE_EINTR(ftruncate(SharedMemory::GetFdFromSharedMemoryHandle(handle),
                             AlignToPageSize(sizeof(SharedState)))) != 0) {
    DPLOG(ERROR) << "ftruncate() failed";
    return;
  }
  mapped_size_ = 0;
#else
  NOTIMPLEMENTED();
#endif
}
#endif

Time DiscardableSharedMemory::Now() const {
  return Time::Now();
}

}  // namespace base
