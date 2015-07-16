// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Tests for the Command Buffer Helper.

#include "gpu/command_buffer/client/transfer_buffer.h"

#include "base/compiler_specific.h"
#include "gpu/command_buffer/client/client_test_helper.h"
#include "gpu/command_buffer/client/cmd_buffer_helper.h"
#include "gpu/command_buffer/common/command_buffer.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/gmock/include/gmock/gmock.h"

using ::testing::_;
using ::testing::AtMost;
using ::testing::Invoke;
using ::testing::Return;
using ::testing::SetArgPointee;
using ::testing::StrictMock;

namespace gpu {


class TransferBufferTest : public testing::Test {
 protected:
  static const int32 kNumCommandEntries = 400;
  static const int32 kCommandBufferSizeBytes =
      kNumCommandEntries * sizeof(CommandBufferEntry);
  static const unsigned int kStartingOffset = 64;
  static const unsigned int kAlignment = 4;
  static const size_t kTransferBufferSize = 256;

  TransferBufferTest()
      : transfer_buffer_id_(0) {
  }

  void SetUp() override;
  void TearDown() override;

  virtual void Initialize(unsigned int size_to_flush) {
    ASSERT_TRUE(transfer_buffer_->Initialize(
        kTransferBufferSize,
        kStartingOffset,
        kTransferBufferSize,
        kTransferBufferSize,
        kAlignment,
        size_to_flush));
  }

  MockClientCommandBufferMockFlush* command_buffer() const {
    return command_buffer_.get();
  }

  scoped_ptr<MockClientCommandBufferMockFlush> command_buffer_;
  scoped_ptr<CommandBufferHelper> helper_;
  scoped_ptr<TransferBuffer> transfer_buffer_;
  int32 transfer_buffer_id_;
};

void TransferBufferTest::SetUp() {
  command_buffer_.reset(new StrictMock<MockClientCommandBufferMockFlush>());
  ASSERT_TRUE(command_buffer_->Initialize());

  helper_.reset(new CommandBufferHelper(command_buffer()));
  ASSERT_TRUE(helper_->Initialize(kCommandBufferSizeBytes));

  transfer_buffer_id_ = command_buffer()->GetNextFreeTransferBufferId();

  transfer_buffer_.reset(new TransferBuffer(helper_.get()));
}

void TransferBufferTest::TearDown() {
  if (transfer_buffer_->HaveBuffer()) {
    EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
        .Times(1)
        .RetiresOnSaturation();
  }
  // For command buffer.
  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*command_buffer(), OnFlush()).Times(AtMost(1));
  EXPECT_CALL(*command_buffer(), Flush(_)).Times(AtMost(1));
  transfer_buffer_.reset();
}

// GCC requires these declarations, but MSVC requires they not be present
#ifndef _MSC_VER
const int32 TransferBufferTest::kNumCommandEntries;
const int32 TransferBufferTest::kCommandBufferSizeBytes;
const unsigned int TransferBufferTest::kStartingOffset;
const unsigned int TransferBufferTest::kAlignment;
const size_t TransferBufferTest::kTransferBufferSize;
#endif

TEST_F(TransferBufferTest, Basic) {
  Initialize(0);
  EXPECT_TRUE(transfer_buffer_->HaveBuffer());
  EXPECT_EQ(transfer_buffer_id_, transfer_buffer_->GetShmId());
  EXPECT_EQ(
      kTransferBufferSize - kStartingOffset,
      transfer_buffer_->GetCurrentMaxAllocationWithoutRealloc());
}

TEST_F(TransferBufferTest, Free) {
  Initialize(0);
  EXPECT_TRUE(transfer_buffer_->HaveBuffer());
  EXPECT_EQ(transfer_buffer_id_, transfer_buffer_->GetShmId());

  // Free buffer.
  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  transfer_buffer_->Free();
  // See it's freed.
  EXPECT_FALSE(transfer_buffer_->HaveBuffer());
  // See that it gets reallocated.
  EXPECT_EQ(transfer_buffer_id_, transfer_buffer_->GetShmId());
  EXPECT_TRUE(transfer_buffer_->HaveBuffer());

  // Free buffer.
  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  transfer_buffer_->Free();
  // See it's freed.
  EXPECT_FALSE(transfer_buffer_->HaveBuffer());
  // See that it gets reallocated.
  EXPECT_TRUE(transfer_buffer_->GetResultBuffer() != NULL);
  EXPECT_TRUE(transfer_buffer_->HaveBuffer());

  // Free buffer.
  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  transfer_buffer_->Free();
  // See it's freed.
  EXPECT_FALSE(transfer_buffer_->HaveBuffer());
  // See that it gets reallocated.
  unsigned int size = 0;
  void* data = transfer_buffer_->AllocUpTo(1, &size);
  EXPECT_TRUE(data != NULL);
  EXPECT_TRUE(transfer_buffer_->HaveBuffer());
  transfer_buffer_->FreePendingToken(data, 1);

  // Free buffer.
  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  transfer_buffer_->Free();
  // See it's freed.
  EXPECT_FALSE(transfer_buffer_->HaveBuffer());
  // See that it gets reallocated.
  transfer_buffer_->GetResultOffset();
  EXPECT_TRUE(transfer_buffer_->HaveBuffer());

  EXPECT_EQ(
      kTransferBufferSize - kStartingOffset,
      transfer_buffer_->GetCurrentMaxAllocationWithoutRealloc());

  // Test freeing twice.
  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  transfer_buffer_->Free();
  transfer_buffer_->Free();
}

TEST_F(TransferBufferTest, TooLargeAllocation) {
  Initialize(0);
  // Check that we can't allocate large than max size.
  void* ptr = transfer_buffer_->Alloc(kTransferBufferSize + 1);
  EXPECT_TRUE(ptr == NULL);
  // Check we if we try to allocate larger than max we get max.
  unsigned int size_allocated = 0;
  ptr = transfer_buffer_->AllocUpTo(
      kTransferBufferSize + 1, &size_allocated);
  ASSERT_TRUE(ptr != NULL);
  EXPECT_EQ(kTransferBufferSize - kStartingOffset, size_allocated);
  transfer_buffer_->FreePendingToken(ptr, 1);
}

TEST_F(TransferBufferTest, MemoryAlignmentAfterZeroAllocation) {
  Initialize(32u);
  void* ptr = transfer_buffer_->Alloc(0);
  EXPECT_EQ((reinterpret_cast<uintptr_t>(ptr) & (kAlignment - 1)), 0u);
  transfer_buffer_->FreePendingToken(ptr, static_cast<unsigned int>(-1));
  // Check that the pointer is aligned on the following allocation.
  ptr = transfer_buffer_->Alloc(4);
  EXPECT_EQ((reinterpret_cast<uintptr_t>(ptr) & (kAlignment - 1)), 0u);
  transfer_buffer_->FreePendingToken(ptr, 1);
}

TEST_F(TransferBufferTest, Flush) {
  Initialize(16u);
  unsigned int size_allocated = 0;
  for (int i = 0; i < 8; ++i) {
    void* ptr = transfer_buffer_->AllocUpTo(8u, &size_allocated);
    ASSERT_TRUE(ptr != NULL);
    EXPECT_EQ(8u, size_allocated);
    if (i % 2) {
      EXPECT_CALL(*command_buffer(), Flush(_))
          .Times(1)
          .RetiresOnSaturation();
    }
    transfer_buffer_->FreePendingToken(ptr, helper_->InsertToken());
  }
  for (int i = 0; i < 8; ++i) {
    void* ptr = transfer_buffer_->Alloc(8u);
    ASSERT_TRUE(ptr != NULL);
    if (i % 2) {
      EXPECT_CALL(*command_buffer(), Flush(_))
          .Times(1)
          .RetiresOnSaturation();
    }
    transfer_buffer_->FreePendingToken(ptr, helper_->InsertToken());
  }
}

class MockClientCommandBufferCanFail : public MockClientCommandBufferMockFlush {
 public:
  MockClientCommandBufferCanFail() {
  }
  virtual ~MockClientCommandBufferCanFail() {
  }

  MOCK_METHOD2(CreateTransferBuffer,
               scoped_refptr<Buffer>(size_t size, int32* id));

  scoped_refptr<gpu::Buffer> RealCreateTransferBuffer(size_t size, int32* id) {
    return MockCommandBufferBase::CreateTransferBuffer(size, id);
  }
};

class TransferBufferExpandContractTest : public testing::Test {
 protected:
  static const int32 kNumCommandEntries = 400;
  static const int32 kCommandBufferSizeBytes =
      kNumCommandEntries * sizeof(CommandBufferEntry);
  static const unsigned int kStartingOffset = 64;
  static const unsigned int kAlignment = 4;
  static const size_t kStartTransferBufferSize = 256;
  static const size_t kMaxTransferBufferSize = 1024;
  static const size_t kMinTransferBufferSize = 128;

  TransferBufferExpandContractTest()
      : transfer_buffer_id_(0) {
  }

  void SetUp() override;
  void TearDown() override;

  MockClientCommandBufferCanFail* command_buffer() const {
    return command_buffer_.get();
  }

  scoped_ptr<MockClientCommandBufferCanFail> command_buffer_;
  scoped_ptr<CommandBufferHelper> helper_;
  scoped_ptr<TransferBuffer> transfer_buffer_;
  int32 transfer_buffer_id_;
};

void TransferBufferExpandContractTest::SetUp() {
  command_buffer_.reset(new StrictMock<MockClientCommandBufferCanFail>());
  ASSERT_TRUE(command_buffer_->Initialize());

  EXPECT_CALL(*command_buffer(),
              CreateTransferBuffer(kCommandBufferSizeBytes, _))
      .WillOnce(Invoke(
          command_buffer(),
          &MockClientCommandBufferCanFail::RealCreateTransferBuffer))
      .RetiresOnSaturation();

  helper_.reset(new CommandBufferHelper(command_buffer()));
  ASSERT_TRUE(helper_->Initialize(kCommandBufferSizeBytes));

  transfer_buffer_id_ = command_buffer()->GetNextFreeTransferBufferId();

  EXPECT_CALL(*command_buffer(),
              CreateTransferBuffer(kStartTransferBufferSize, _))
      .WillOnce(Invoke(
          command_buffer(),
          &MockClientCommandBufferCanFail::RealCreateTransferBuffer))
      .RetiresOnSaturation();

  transfer_buffer_.reset(new TransferBuffer(helper_.get()));
  ASSERT_TRUE(transfer_buffer_->Initialize(
      kStartTransferBufferSize,
      kStartingOffset,
      kMinTransferBufferSize,
      kMaxTransferBufferSize,
      kAlignment,
      0));
}

void TransferBufferExpandContractTest::TearDown() {
  if (transfer_buffer_->HaveBuffer()) {
    EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
        .Times(1)
        .RetiresOnSaturation();
  }
  // For command buffer.
  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  transfer_buffer_.reset();
}

// GCC requires these declarations, but MSVC requires they not be present
#ifndef _MSC_VER
const int32 TransferBufferExpandContractTest::kNumCommandEntries;
const int32 TransferBufferExpandContractTest::kCommandBufferSizeBytes;
const unsigned int TransferBufferExpandContractTest::kStartingOffset;
const unsigned int TransferBufferExpandContractTest::kAlignment;
const size_t TransferBufferExpandContractTest::kStartTransferBufferSize;
const size_t TransferBufferExpandContractTest::kMaxTransferBufferSize;
const size_t TransferBufferExpandContractTest::kMinTransferBufferSize;
#endif

TEST_F(TransferBufferExpandContractTest, Expand) {
  // Check it starts at starting size.
  EXPECT_EQ(
      kStartTransferBufferSize - kStartingOffset,
      transfer_buffer_->GetCurrentMaxAllocationWithoutRealloc());

  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*command_buffer(),
              CreateTransferBuffer(kStartTransferBufferSize * 2, _))
      .WillOnce(Invoke(
          command_buffer(),
          &MockClientCommandBufferCanFail::RealCreateTransferBuffer))
      .RetiresOnSaturation();

  // Try next power of 2.
  const size_t kSize1 = 512 - kStartingOffset;
  unsigned int size_allocated = 0;
  void* ptr = transfer_buffer_->AllocUpTo(kSize1, &size_allocated);
  ASSERT_TRUE(ptr != NULL);
  EXPECT_EQ(kSize1, size_allocated);
  EXPECT_EQ(kSize1, transfer_buffer_->GetCurrentMaxAllocationWithoutRealloc());
  transfer_buffer_->FreePendingToken(ptr, 1);

  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  EXPECT_CALL(*command_buffer(),
              CreateTransferBuffer(kMaxTransferBufferSize, _))
      .WillOnce(Invoke(
          command_buffer(),
          &MockClientCommandBufferCanFail::RealCreateTransferBuffer))
      .RetiresOnSaturation();

  // Try next power of 2.
  const size_t kSize2 = 1024 - kStartingOffset;
  ptr = transfer_buffer_->AllocUpTo(kSize2, &size_allocated);
  ASSERT_TRUE(ptr != NULL);
  EXPECT_EQ(kSize2, size_allocated);
  EXPECT_EQ(kSize2, transfer_buffer_->GetCurrentMaxAllocationWithoutRealloc());
  transfer_buffer_->FreePendingToken(ptr, 1);

  // Try next one more. Should not go past max.
  size_allocated = 0;
  const size_t kSize3 = kSize2 + 1;
  ptr = transfer_buffer_->AllocUpTo(kSize3, &size_allocated);
  EXPECT_EQ(kSize2, size_allocated);
  EXPECT_EQ(kSize2, transfer_buffer_->GetCurrentMaxAllocationWithoutRealloc());
  transfer_buffer_->FreePendingToken(ptr, 1);
}

TEST_F(TransferBufferExpandContractTest, Contract) {
  // Check it starts at starting size.
  EXPECT_EQ(
      kStartTransferBufferSize - kStartingOffset,
      transfer_buffer_->GetCurrentMaxAllocationWithoutRealloc());

  // Free buffer.
  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  transfer_buffer_->Free();
  // See it's freed.
  EXPECT_FALSE(transfer_buffer_->HaveBuffer());

  // Try to allocate again, fail first request
  EXPECT_CALL(*command_buffer(),
              CreateTransferBuffer(kStartTransferBufferSize, _))
      .WillOnce(
           DoAll(SetArgPointee<1>(-1), Return(scoped_refptr<gpu::Buffer>())))
      .RetiresOnSaturation();
  EXPECT_CALL(*command_buffer(),
              CreateTransferBuffer(kMinTransferBufferSize, _))
      .WillOnce(Invoke(
          command_buffer(),
          &MockClientCommandBufferCanFail::RealCreateTransferBuffer))
      .RetiresOnSaturation();

  const size_t kSize1 = 256 - kStartingOffset;
  const size_t kSize2 = 128 - kStartingOffset;
  unsigned int size_allocated = 0;
  void* ptr = transfer_buffer_->AllocUpTo(kSize1, &size_allocated);
  ASSERT_TRUE(ptr != NULL);
  EXPECT_EQ(kSize2, size_allocated);
  EXPECT_EQ(kSize2, transfer_buffer_->GetCurrentMaxAllocationWithoutRealloc());
  transfer_buffer_->FreePendingToken(ptr, 1);

  // Free buffer.
  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  transfer_buffer_->Free();
  // See it's freed.
  EXPECT_FALSE(transfer_buffer_->HaveBuffer());

  // Try to allocate again,
  EXPECT_CALL(*command_buffer(),
              CreateTransferBuffer(kMinTransferBufferSize, _))
      .WillOnce(Invoke(
          command_buffer(),
          &MockClientCommandBufferCanFail::RealCreateTransferBuffer))
      .RetiresOnSaturation();

  ptr = transfer_buffer_->AllocUpTo(kSize1, &size_allocated);
  ASSERT_TRUE(ptr != NULL);
  EXPECT_EQ(kSize2, size_allocated);
  EXPECT_EQ(kSize2, transfer_buffer_->GetCurrentMaxAllocationWithoutRealloc());
  transfer_buffer_->FreePendingToken(ptr, 1);
}

TEST_F(TransferBufferExpandContractTest, OutOfMemory) {
  // Free buffer.
  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  transfer_buffer_->Free();
  // See it's freed.
  EXPECT_FALSE(transfer_buffer_->HaveBuffer());

  // Try to allocate again, fail both requests.
  EXPECT_CALL(*command_buffer(), CreateTransferBuffer(_, _))
      .WillOnce(
           DoAll(SetArgPointee<1>(-1), Return(scoped_refptr<gpu::Buffer>())))
      .WillOnce(
           DoAll(SetArgPointee<1>(-1), Return(scoped_refptr<gpu::Buffer>())))
      .WillOnce(
           DoAll(SetArgPointee<1>(-1), Return(scoped_refptr<gpu::Buffer>())))
      .RetiresOnSaturation();

  const size_t kSize1 = 512 - kStartingOffset;
  unsigned int size_allocated = 0;
  void* ptr = transfer_buffer_->AllocUpTo(kSize1, &size_allocated);
  ASSERT_TRUE(ptr == NULL);
  EXPECT_FALSE(transfer_buffer_->HaveBuffer());
}

TEST_F(TransferBufferExpandContractTest, ReallocsToDefault) {
  // Free buffer.
  EXPECT_CALL(*command_buffer(), DestroyTransferBuffer(_))
      .Times(1)
      .RetiresOnSaturation();
  transfer_buffer_->Free();
  // See it's freed.
  EXPECT_FALSE(transfer_buffer_->HaveBuffer());

  // See that it gets reallocated.
  EXPECT_CALL(*command_buffer(),
              CreateTransferBuffer(kStartTransferBufferSize, _))
      .WillOnce(Invoke(
          command_buffer(),
          &MockClientCommandBufferCanFail::RealCreateTransferBuffer))
      .RetiresOnSaturation();
  EXPECT_EQ(transfer_buffer_id_, transfer_buffer_->GetShmId());
  EXPECT_TRUE(transfer_buffer_->HaveBuffer());

  // Check it's the default size.
  EXPECT_EQ(
      kStartTransferBufferSize - kStartingOffset,
      transfer_buffer_->GetCurrentMaxAllocationWithoutRealloc());
}

}  // namespace gpu


