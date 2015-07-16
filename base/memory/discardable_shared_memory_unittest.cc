// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "base/memory/discardable_shared_memory.h"
#include "base/process/process_metrics.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace {

class TestDiscardableSharedMemory : public DiscardableSharedMemory {
 public:
  TestDiscardableSharedMemory() {}

  explicit TestDiscardableSharedMemory(SharedMemoryHandle handle)
      : DiscardableSharedMemory(handle) {}

  void SetNow(Time now) { now_ = now; }

 private:
  // Overriden from DiscardableSharedMemory:
  Time Now() const override { return now_; }

  Time now_;
};

TEST(DiscardableSharedMemoryTest, CreateAndMap) {
  const uint32 kDataSize = 1024;

  TestDiscardableSharedMemory memory;
  bool rv = memory.CreateAndMap(kDataSize);
  ASSERT_TRUE(rv);
  EXPECT_GE(memory.mapped_size(), kDataSize);
}

TEST(DiscardableSharedMemoryTest, CreateFromHandle) {
  const uint32 kDataSize = 1024;

  TestDiscardableSharedMemory memory1;
  bool rv = memory1.CreateAndMap(kDataSize);
  ASSERT_TRUE(rv);

  SharedMemoryHandle shared_handle;
  ASSERT_TRUE(
      memory1.ShareToProcess(GetCurrentProcessHandle(), &shared_handle));
  ASSERT_TRUE(SharedMemory::IsHandleValid(shared_handle));

  TestDiscardableSharedMemory memory2(shared_handle);
  rv = memory2.Map(kDataSize);
  ASSERT_TRUE(rv);
}

TEST(DiscardableSharedMemoryTest, LockAndUnlock) {
  const uint32 kDataSize = 1024;

  TestDiscardableSharedMemory memory1;
  bool rv = memory1.CreateAndMap(kDataSize);
  ASSERT_TRUE(rv);

  // Memory is initially locked. Unlock it.
  memory1.SetNow(Time::FromDoubleT(1));
  memory1.Unlock(0, 0);

  // Lock and unlock memory.
  auto lock_rv = memory1.Lock(0, 0);
  EXPECT_EQ(DiscardableSharedMemory::SUCCESS, lock_rv);
  memory1.SetNow(Time::FromDoubleT(2));
  memory1.Unlock(0, 0);

  // Lock again before duplicating and passing ownership to new instance.
  lock_rv = memory1.Lock(0, 0);
  EXPECT_EQ(DiscardableSharedMemory::SUCCESS, lock_rv);

  SharedMemoryHandle shared_handle;
  ASSERT_TRUE(
      memory1.ShareToProcess(GetCurrentProcessHandle(), &shared_handle));
  ASSERT_TRUE(SharedMemory::IsHandleValid(shared_handle));

  TestDiscardableSharedMemory memory2(shared_handle);
  rv = memory2.Map(kDataSize);
  ASSERT_TRUE(rv);

  // Unlock second instance.
  memory2.SetNow(Time::FromDoubleT(3));
  memory2.Unlock(0, 0);

  // Lock second instance before passing ownership back to first instance.
  lock_rv = memory2.Lock(0, 0);
  EXPECT_EQ(DiscardableSharedMemory::SUCCESS, lock_rv);

  // Memory should still be resident.
  rv = memory1.IsMemoryResident();
  EXPECT_TRUE(rv);

  // Unlock first instance.
  memory1.SetNow(Time::FromDoubleT(4));
  memory1.Unlock(0, 0);
}

TEST(DiscardableSharedMemoryTest, Purge) {
  const uint32 kDataSize = 1024;

  TestDiscardableSharedMemory memory1;
  bool rv = memory1.CreateAndMap(kDataSize);
  ASSERT_TRUE(rv);

  SharedMemoryHandle shared_handle;
  ASSERT_TRUE(
      memory1.ShareToProcess(GetCurrentProcessHandle(), &shared_handle));
  ASSERT_TRUE(SharedMemory::IsHandleValid(shared_handle));

  TestDiscardableSharedMemory memory2(shared_handle);
  rv = memory2.Map(kDataSize);
  ASSERT_TRUE(rv);

  // This should fail as memory is locked.
  rv = memory1.Purge(Time::FromDoubleT(1));
  EXPECT_FALSE(rv);

  memory2.SetNow(Time::FromDoubleT(2));
  memory2.Unlock(0, 0);

  ASSERT_TRUE(memory2.IsMemoryResident());

  // Memory is unlocked, but our usage timestamp is incorrect.
  rv = memory1.Purge(Time::FromDoubleT(3));
  EXPECT_FALSE(rv);

  ASSERT_TRUE(memory2.IsMemoryResident());

  // Memory is unlocked and our usage timestamp should be correct.
  rv = memory1.Purge(Time::FromDoubleT(4));
  EXPECT_TRUE(rv);

  // Lock should fail as memory has been purged.
  auto lock_rv = memory2.Lock(0, 0);
  EXPECT_EQ(DiscardableSharedMemory::FAILED, lock_rv);

  ASSERT_FALSE(memory2.IsMemoryResident());
}

TEST(DiscardableSharedMemoryTest, LastUsed) {
  const uint32 kDataSize = 1024;

  TestDiscardableSharedMemory memory1;
  bool rv = memory1.CreateAndMap(kDataSize);
  ASSERT_TRUE(rv);

  SharedMemoryHandle shared_handle;
  ASSERT_TRUE(
      memory1.ShareToProcess(GetCurrentProcessHandle(), &shared_handle));
  ASSERT_TRUE(SharedMemory::IsHandleValid(shared_handle));

  TestDiscardableSharedMemory memory2(shared_handle);
  rv = memory2.Map(kDataSize);
  ASSERT_TRUE(rv);

  memory2.SetNow(Time::FromDoubleT(1));
  memory2.Unlock(0, 0);

  EXPECT_EQ(memory2.last_known_usage(), Time::FromDoubleT(1));

  auto lock_rv = memory2.Lock(0, 0);
  EXPECT_EQ(DiscardableSharedMemory::SUCCESS, lock_rv);

  // This should fail as memory is locked.
  rv = memory1.Purge(Time::FromDoubleT(2));
  ASSERT_FALSE(rv);

  // Last usage should have been updated to timestamp passed to Purge above.
  EXPECT_EQ(memory1.last_known_usage(), Time::FromDoubleT(2));

  memory2.SetNow(Time::FromDoubleT(3));
  memory2.Unlock(0, 0);

  // Usage time should be correct for |memory2| instance.
  EXPECT_EQ(memory2.last_known_usage(), Time::FromDoubleT(3));

  // However, usage time has not changed as far as |memory1| instance knows.
  EXPECT_EQ(memory1.last_known_usage(), Time::FromDoubleT(2));

  // Memory is unlocked, but our usage timestamp is incorrect.
  rv = memory1.Purge(Time::FromDoubleT(4));
  EXPECT_FALSE(rv);

  // The failed purge attempt should have updated usage time to the correct
  // value.
  EXPECT_EQ(memory1.last_known_usage(), Time::FromDoubleT(3));

  // Purge memory through |memory2| instance. The last usage time should be
  // set to 0 as a result of this.
  rv = memory2.Purge(Time::FromDoubleT(5));
  EXPECT_TRUE(rv);
  EXPECT_TRUE(memory2.last_known_usage().is_null());

  // This should fail as memory has already been purged and |memory1|'s usage
  // time is incorrect as a result.
  rv = memory1.Purge(Time::FromDoubleT(6));
  EXPECT_FALSE(rv);

  // The failed purge attempt should have updated usage time to the correct
  // value.
  EXPECT_TRUE(memory1.last_known_usage().is_null());

  // Purge should succeed now that usage time is correct.
  rv = memory1.Purge(Time::FromDoubleT(7));
  EXPECT_TRUE(rv);
}

TEST(DiscardableSharedMemoryTest, LockShouldAlwaysFailAfterSuccessfulPurge) {
  const uint32 kDataSize = 1024;

  TestDiscardableSharedMemory memory1;
  bool rv = memory1.CreateAndMap(kDataSize);
  ASSERT_TRUE(rv);

  SharedMemoryHandle shared_handle;
  ASSERT_TRUE(
      memory1.ShareToProcess(GetCurrentProcessHandle(), &shared_handle));
  ASSERT_TRUE(SharedMemory::IsHandleValid(shared_handle));

  TestDiscardableSharedMemory memory2(shared_handle);
  rv = memory2.Map(kDataSize);
  ASSERT_TRUE(rv);

  memory2.SetNow(Time::FromDoubleT(1));
  memory2.Unlock(0, 0);

  rv = memory2.Purge(Time::FromDoubleT(2));
  EXPECT_TRUE(rv);

  // Lock should fail as memory has been purged.
  auto lock_rv = memory2.Lock(0, 0);
  EXPECT_EQ(DiscardableSharedMemory::FAILED, lock_rv);
}

TEST(DiscardableSharedMemoryTest, LockAndUnlockRange) {
  const uint32 kDataSize = 32;

  uint32 data_size_in_bytes = kDataSize * base::GetPageSize();

  TestDiscardableSharedMemory memory1;
  bool rv = memory1.CreateAndMap(data_size_in_bytes);
  ASSERT_TRUE(rv);

  SharedMemoryHandle shared_handle;
  ASSERT_TRUE(
      memory1.ShareToProcess(GetCurrentProcessHandle(), &shared_handle));
  ASSERT_TRUE(SharedMemory::IsHandleValid(shared_handle));

  TestDiscardableSharedMemory memory2(shared_handle);
  rv = memory2.Map(data_size_in_bytes);
  ASSERT_TRUE(rv);

  // Unlock first page.
  memory2.SetNow(Time::FromDoubleT(1));
  memory2.Unlock(0, base::GetPageSize());

  rv = memory1.Purge(Time::FromDoubleT(2));
  EXPECT_FALSE(rv);

  // Lock first page again.
  memory2.SetNow(Time::FromDoubleT(3));
  auto lock_rv = memory2.Lock(0, base::GetPageSize());
  EXPECT_NE(DiscardableSharedMemory::FAILED, lock_rv);

  // Unlock first page.
  memory2.SetNow(Time::FromDoubleT(4));
  memory2.Unlock(0, base::GetPageSize());

  rv = memory1.Purge(Time::FromDoubleT(5));
  EXPECT_FALSE(rv);

  // Unlock second page.
  memory2.SetNow(Time::FromDoubleT(6));
  memory2.Unlock(base::GetPageSize(), base::GetPageSize());

  rv = memory1.Purge(Time::FromDoubleT(7));
  EXPECT_FALSE(rv);

  // Unlock anything onwards.
  memory2.SetNow(Time::FromDoubleT(8));
  memory2.Unlock(2 * base::GetPageSize(), 0);

  // Memory is unlocked, but our usage timestamp is incorrect.
  rv = memory1.Purge(Time::FromDoubleT(9));
  EXPECT_FALSE(rv);

  // The failed purge attempt should have updated usage time to the correct
  // value.
  EXPECT_EQ(Time::FromDoubleT(8), memory1.last_known_usage());

  // Purge should now succeed.
  rv = memory1.Purge(Time::FromDoubleT(10));
  EXPECT_TRUE(rv);
}

TEST(DiscardableSharedMemoryTest, MappedSize) {
  const uint32 kDataSize = 1024;

  TestDiscardableSharedMemory memory;
  bool rv = memory.CreateAndMap(kDataSize);
  ASSERT_TRUE(rv);

  EXPECT_LE(kDataSize, memory.mapped_size());

  // Mapped size should be 0 after memory segment has been unmapped.
  rv = memory.Unmap();
  EXPECT_TRUE(rv);
  EXPECT_EQ(0u, memory.mapped_size());
}

TEST(DiscardableSharedMemoryTest, Close) {
  const uint32 kDataSize = 1024;

  TestDiscardableSharedMemory memory;
  bool rv = memory.CreateAndMap(kDataSize);
  ASSERT_TRUE(rv);

  // Mapped size should be unchanged after memory segment has been closed.
  memory.Close();
  EXPECT_LE(kDataSize, memory.mapped_size());

  // Memory is initially locked. Unlock it.
  memory.SetNow(Time::FromDoubleT(1));
  memory.Unlock(0, 0);

  // Lock and unlock memory.
  auto lock_rv = memory.Lock(0, 0);
  EXPECT_EQ(DiscardableSharedMemory::SUCCESS, lock_rv);
  memory.SetNow(Time::FromDoubleT(2));
  memory.Unlock(0, 0);
}

#if defined(DISCARDABLE_SHARED_MEMORY_SHRINKING)
TEST(DiscardableSharedMemoryTest, Shrink) {
  const uint32 kDataSize = 1024;

  TestDiscardableSharedMemory memory;
  bool rv = memory.CreateAndMap(kDataSize);
  ASSERT_TRUE(rv);

  EXPECT_NE(0u, memory.mapped_size());

  // Mapped size should be 0 after shrinking memory segment.
  memory.Shrink();
  EXPECT_EQ(0u, memory.mapped_size());
}
#endif

}  // namespace
}  // namespace base
