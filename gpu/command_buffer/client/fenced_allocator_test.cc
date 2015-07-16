// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the tests for the FencedAllocator class.

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/memory/aligned_memory.h"
#include "base/message_loop/message_loop.h"
#include "gpu/command_buffer/client/cmd_buffer_helper.h"
#include "gpu/command_buffer/client/fenced_allocator.h"
#include "gpu/command_buffer/service/cmd_buffer_engine.h"
#include "gpu/command_buffer/service/command_buffer_service.h"
#include "gpu/command_buffer/service/gpu_scheduler.h"
#include "gpu/command_buffer/service/mocks.h"
#include "gpu/command_buffer/service/transfer_buffer_manager.h"
#include "testing/gtest/include/gtest/gtest.h"

#if defined(OS_MACOSX)
#include "base/mac/scoped_nsautorelease_pool.h"
#endif

namespace gpu {

using testing::Return;
using testing::Mock;
using testing::Truly;
using testing::Sequence;
using testing::DoAll;
using testing::Invoke;
using testing::InvokeWithoutArgs;
using testing::_;

class BaseFencedAllocatorTest : public testing::Test {
 protected:
  static const unsigned int kBufferSize = 1024;
  static const int kAllocAlignment = 16;

  void SetUp() override {
    api_mock_.reset(new AsyncAPIMock(true));
    // ignore noops in the mock - we don't want to inspect the internals of the
    // helper.
    EXPECT_CALL(*api_mock_, DoCommand(cmd::kNoop, 0, _))
        .WillRepeatedly(Return(error::kNoError));
    // Forward the SetToken calls to the engine
    EXPECT_CALL(*api_mock_.get(), DoCommand(cmd::kSetToken, 1, _))
        .WillRepeatedly(DoAll(Invoke(api_mock_.get(), &AsyncAPIMock::SetToken),
                              Return(error::kNoError)));

    {
      TransferBufferManager* manager = new TransferBufferManager();
      transfer_buffer_manager_.reset(manager);
      EXPECT_TRUE(manager->Initialize());
    }
    command_buffer_.reset(
        new CommandBufferService(transfer_buffer_manager_.get()));
    EXPECT_TRUE(command_buffer_->Initialize());

    gpu_scheduler_.reset(new GpuScheduler(
        command_buffer_.get(), api_mock_.get(), NULL));
    command_buffer_->SetPutOffsetChangeCallback(base::Bind(
        &GpuScheduler::PutChanged, base::Unretained(gpu_scheduler_.get())));
    command_buffer_->SetGetBufferChangeCallback(base::Bind(
        &GpuScheduler::SetGetBuffer, base::Unretained(gpu_scheduler_.get())));

    api_mock_->set_engine(gpu_scheduler_.get());

    helper_.reset(new CommandBufferHelper(command_buffer_.get()));
    helper_->Initialize(kBufferSize);
  }

  int32 GetToken() {
    return command_buffer_->GetLastState().token;
  }

#if defined(OS_MACOSX)
  base::mac::ScopedNSAutoreleasePool autorelease_pool_;
#endif
  base::MessageLoop message_loop_;
  scoped_ptr<AsyncAPIMock> api_mock_;
  scoped_ptr<TransferBufferManagerInterface> transfer_buffer_manager_;
  scoped_ptr<CommandBufferService> command_buffer_;
  scoped_ptr<GpuScheduler> gpu_scheduler_;
  scoped_ptr<CommandBufferHelper> helper_;
};

#ifndef _MSC_VER
const unsigned int BaseFencedAllocatorTest::kBufferSize;
#endif

namespace {
void EmptyPoll() {
}
}

// Test fixture for FencedAllocator test - Creates a FencedAllocator, using a
// CommandBufferHelper with a mock AsyncAPIInterface for its interface (calling
// it directly, not through the RPC mechanism), making sure Noops are ignored
// and SetToken are properly forwarded to the engine.
class FencedAllocatorTest : public BaseFencedAllocatorTest {
 protected:
  void SetUp() override {
    BaseFencedAllocatorTest::SetUp();
    allocator_.reset(new FencedAllocator(kBufferSize,
                                         helper_.get(),
                                         base::Bind(&EmptyPoll)));
  }

  void TearDown() override {
    // If the GpuScheduler posts any tasks, this forces them to run.
    base::MessageLoop::current()->RunUntilIdle();

    EXPECT_TRUE(allocator_->CheckConsistency());

    BaseFencedAllocatorTest::TearDown();
  }

  scoped_ptr<FencedAllocator> allocator_;
};

// Checks basic alloc and free.
TEST_F(FencedAllocatorTest, TestBasic) {
  allocator_->CheckConsistency();
  EXPECT_FALSE(allocator_->InUse());

  const unsigned int kSize = 16;
  FencedAllocator::Offset offset = allocator_->Alloc(kSize);
  EXPECT_TRUE(allocator_->InUse());
  EXPECT_NE(FencedAllocator::kInvalidOffset, offset);
  EXPECT_GE(kBufferSize, offset+kSize);
  EXPECT_TRUE(allocator_->CheckConsistency());

  allocator_->Free(offset);
  EXPECT_FALSE(allocator_->InUse());
  EXPECT_TRUE(allocator_->CheckConsistency());
}

// Test alloc 0 fails.
TEST_F(FencedAllocatorTest, TestAllocZero) {
  FencedAllocator::Offset offset = allocator_->Alloc(0);
  EXPECT_EQ(FencedAllocator::kInvalidOffset, offset);
  EXPECT_FALSE(allocator_->InUse());
  EXPECT_TRUE(allocator_->CheckConsistency());
}

// Checks out-of-memory condition.
TEST_F(FencedAllocatorTest, TestOutOfMemory) {
  EXPECT_TRUE(allocator_->CheckConsistency());

  const unsigned int kSize = 16;
  const unsigned int kAllocCount = kBufferSize / kSize;
  CHECK(kAllocCount * kSize == kBufferSize);

  // Allocate several buffers to fill in the memory.
  FencedAllocator::Offset offsets[kAllocCount];
  for (unsigned int i = 0; i < kAllocCount; ++i) {
    offsets[i] = allocator_->Alloc(kSize);
    EXPECT_NE(FencedAllocator::kInvalidOffset, offsets[i]);
    EXPECT_GE(kBufferSize, offsets[i]+kSize);
    EXPECT_TRUE(allocator_->CheckConsistency());
  }

  // This allocation should fail.
  FencedAllocator::Offset offset_failed = allocator_->Alloc(kSize);
  EXPECT_EQ(FencedAllocator::kInvalidOffset, offset_failed);
  EXPECT_TRUE(allocator_->CheckConsistency());

  // Free one successful allocation, reallocate with half the size
  allocator_->Free(offsets[0]);
  EXPECT_TRUE(allocator_->CheckConsistency());
  offsets[0] = allocator_->Alloc(kSize/2);
  EXPECT_NE(FencedAllocator::kInvalidOffset, offsets[0]);
  EXPECT_GE(kBufferSize, offsets[0]+kSize);
  EXPECT_TRUE(allocator_->CheckConsistency());

  // This allocation should fail as well.
  offset_failed = allocator_->Alloc(kSize);
  EXPECT_EQ(FencedAllocator::kInvalidOffset, offset_failed);
  EXPECT_TRUE(allocator_->CheckConsistency());

  // Free up everything.
  for (unsigned int i = 0; i < kAllocCount; ++i) {
    allocator_->Free(offsets[i]);
    EXPECT_TRUE(allocator_->CheckConsistency());
  }
}

// Checks the free-pending-token mechanism.
TEST_F(FencedAllocatorTest, TestFreePendingToken) {
  EXPECT_TRUE(allocator_->CheckConsistency());

  const unsigned int kSize = 16;
  const unsigned int kAllocCount = kBufferSize / kSize;
  CHECK(kAllocCount * kSize == kBufferSize);

  // Allocate several buffers to fill in the memory.
  FencedAllocator::Offset offsets[kAllocCount];
  for (unsigned int i = 0; i < kAllocCount; ++i) {
    offsets[i] = allocator_->Alloc(kSize);
    EXPECT_NE(FencedAllocator::kInvalidOffset, offsets[i]);
    EXPECT_GE(kBufferSize, offsets[i]+kSize);
    EXPECT_TRUE(allocator_->CheckConsistency());
  }

  // This allocation should fail.
  FencedAllocator::Offset offset_failed = allocator_->Alloc(kSize);
  EXPECT_EQ(FencedAllocator::kInvalidOffset, offset_failed);
  EXPECT_TRUE(allocator_->CheckConsistency());

  // Free one successful allocation, pending fence.
  int32 token = helper_.get()->InsertToken();
  allocator_->FreePendingToken(offsets[0], token);
  EXPECT_TRUE(allocator_->CheckConsistency());

  // The way we hooked up the helper and engine, it won't process commands
  // until it has to wait for something. Which means the token shouldn't have
  // passed yet at this point.
  EXPECT_GT(token, GetToken());

  // This allocation will need to reclaim the space freed above, so that should
  // process the commands until the token is passed.
  offsets[0] = allocator_->Alloc(kSize);
  EXPECT_NE(FencedAllocator::kInvalidOffset, offsets[0]);
  EXPECT_GE(kBufferSize, offsets[0]+kSize);
  EXPECT_TRUE(allocator_->CheckConsistency());
  // Check that the token has indeed passed.
  EXPECT_LE(token, GetToken());

  // Free up everything.
  for (unsigned int i = 0; i < kAllocCount; ++i) {
    allocator_->Free(offsets[i]);
    EXPECT_TRUE(allocator_->CheckConsistency());
  }
}

// Checks the free-pending-token mechanism using FreeUnused
TEST_F(FencedAllocatorTest, FreeUnused) {
  EXPECT_TRUE(allocator_->CheckConsistency());

  const unsigned int kSize = 16;
  const unsigned int kAllocCount = kBufferSize / kSize;
  CHECK(kAllocCount * kSize == kBufferSize);

  // Allocate several buffers to fill in the memory.
  FencedAllocator::Offset offsets[kAllocCount];
  for (unsigned int i = 0; i < kAllocCount; ++i) {
    offsets[i] = allocator_->Alloc(kSize);
    EXPECT_NE(FencedAllocator::kInvalidOffset, offsets[i]);
    EXPECT_GE(kBufferSize, offsets[i]+kSize);
    EXPECT_TRUE(allocator_->CheckConsistency());
  }
  EXPECT_TRUE(allocator_->InUse());

  // No memory should be available.
  EXPECT_EQ(0u, allocator_->GetLargestFreeSize());

  // Free one successful allocation, pending fence.
  int32 token = helper_.get()->InsertToken();
  allocator_->FreePendingToken(offsets[0], token);
  EXPECT_TRUE(allocator_->CheckConsistency());

  // Force the command buffer to process the token.
  helper_->Finish();

  // Tell the allocator to update what's available based on the current token.
  allocator_->FreeUnused();

  // Check that the new largest free size takes into account the unused block.
  EXPECT_EQ(kSize, allocator_->GetLargestFreeSize());

  // Free two more.
  token = helper_.get()->InsertToken();
  allocator_->FreePendingToken(offsets[1], token);
  token = helper_.get()->InsertToken();
  allocator_->FreePendingToken(offsets[2], token);
  EXPECT_TRUE(allocator_->CheckConsistency());

  // Check that nothing has changed.
  EXPECT_EQ(kSize, allocator_->GetLargestFreeSize());

  // Force the command buffer to process the token.
  helper_->Finish();

  // Tell the allocator to update what's available based on the current token.
  allocator_->FreeUnused();

  // Check that the new largest free size takes into account the unused blocks.
  EXPECT_EQ(kSize * 3, allocator_->GetLargestFreeSize());
  EXPECT_TRUE(allocator_->InUse());

  // Free up everything.
  for (unsigned int i = 3; i < kAllocCount; ++i) {
    allocator_->Free(offsets[i]);
    EXPECT_TRUE(allocator_->CheckConsistency());
  }
  EXPECT_FALSE(allocator_->InUse());
}

// Tests GetLargestFreeSize
TEST_F(FencedAllocatorTest, TestGetLargestFreeSize) {
  EXPECT_TRUE(allocator_->CheckConsistency());
  EXPECT_EQ(kBufferSize, allocator_->GetLargestFreeSize());

  FencedAllocator::Offset offset = allocator_->Alloc(kBufferSize);
  ASSERT_NE(FencedAllocator::kInvalidOffset, offset);
  EXPECT_EQ(0u, allocator_->GetLargestFreeSize());
  allocator_->Free(offset);
  EXPECT_EQ(kBufferSize, allocator_->GetLargestFreeSize());

  const unsigned int kSize = 16;
  offset = allocator_->Alloc(kSize);
  ASSERT_NE(FencedAllocator::kInvalidOffset, offset);
  // The following checks that the buffer is allocated "smartly" - which is
  // dependent on the implementation. But both first-fit or best-fit would
  // ensure that.
  EXPECT_EQ(kBufferSize - kSize, allocator_->GetLargestFreeSize());

  // Allocate 2 more buffers (now 3), and then free the first two. This is to
  // ensure a hole. Note that this is dependent on the first-fit current
  // implementation.
  FencedAllocator::Offset offset1 = allocator_->Alloc(kSize);
  ASSERT_NE(FencedAllocator::kInvalidOffset, offset1);
  FencedAllocator::Offset offset2 = allocator_->Alloc(kSize);
  ASSERT_NE(FencedAllocator::kInvalidOffset, offset2);
  allocator_->Free(offset);
  allocator_->Free(offset1);
  EXPECT_EQ(kBufferSize - 3 * kSize, allocator_->GetLargestFreeSize());

  offset = allocator_->Alloc(kBufferSize - 3 * kSize);
  ASSERT_NE(FencedAllocator::kInvalidOffset, offset);
  EXPECT_EQ(2 * kSize, allocator_->GetLargestFreeSize());

  offset1 = allocator_->Alloc(2 * kSize);
  ASSERT_NE(FencedAllocator::kInvalidOffset, offset1);
  EXPECT_EQ(0u, allocator_->GetLargestFreeSize());

  allocator_->Free(offset);
  allocator_->Free(offset1);
  allocator_->Free(offset2);
}

// Tests GetLargestFreeOrPendingSize
TEST_F(FencedAllocatorTest, TestGetLargestFreeOrPendingSize) {
  EXPECT_TRUE(allocator_->CheckConsistency());
  EXPECT_EQ(kBufferSize, allocator_->GetLargestFreeOrPendingSize());

  FencedAllocator::Offset offset = allocator_->Alloc(kBufferSize);
  ASSERT_NE(FencedAllocator::kInvalidOffset, offset);
  EXPECT_EQ(0u, allocator_->GetLargestFreeOrPendingSize());
  allocator_->Free(offset);
  EXPECT_EQ(kBufferSize, allocator_->GetLargestFreeOrPendingSize());

  const unsigned int kSize = 16;
  offset = allocator_->Alloc(kSize);
  ASSERT_NE(FencedAllocator::kInvalidOffset, offset);
  // The following checks that the buffer is allocates "smartly" - which is
  // dependent on the implementation. But both first-fit or best-fit would
  // ensure that.
  EXPECT_EQ(kBufferSize - kSize, allocator_->GetLargestFreeOrPendingSize());

  // Allocate 2 more buffers (now 3), and then free the first two. This is to
  // ensure a hole. Note that this is dependent on the first-fit current
  // implementation.
  FencedAllocator::Offset offset1 = allocator_->Alloc(kSize);
  ASSERT_NE(FencedAllocator::kInvalidOffset, offset1);
  FencedAllocator::Offset offset2 = allocator_->Alloc(kSize);
  ASSERT_NE(FencedAllocator::kInvalidOffset, offset2);
  allocator_->Free(offset);
  allocator_->Free(offset1);
  EXPECT_EQ(kBufferSize - 3 * kSize,
            allocator_->GetLargestFreeOrPendingSize());

  // Free the last one, pending a token.
  int32 token = helper_.get()->InsertToken();
  allocator_->FreePendingToken(offset2, token);

  // Now all the buffers have been freed...
  EXPECT_EQ(kBufferSize, allocator_->GetLargestFreeOrPendingSize());
  // .. but one is still waiting for the token.
  EXPECT_EQ(kBufferSize - 3 * kSize,
            allocator_->GetLargestFreeSize());

  // The way we hooked up the helper and engine, it won't process commands
  // until it has to wait for something. Which means the token shouldn't have
  // passed yet at this point.
  EXPECT_GT(token, GetToken());
  // This allocation will need to reclaim the space freed above, so that should
  // process the commands until the token is passed, but it will succeed.
  offset = allocator_->Alloc(kBufferSize);
  ASSERT_NE(FencedAllocator::kInvalidOffset, offset);
  // Check that the token has indeed passed.
  EXPECT_LE(token, GetToken());
  allocator_->Free(offset);

  // Everything now has been freed...
  EXPECT_EQ(kBufferSize, allocator_->GetLargestFreeOrPendingSize());
  // ... for real.
  EXPECT_EQ(kBufferSize, allocator_->GetLargestFreeSize());
}

class FencedAllocatorPollTest : public BaseFencedAllocatorTest {
 public:
  static const unsigned int kAllocSize = 128;

  MOCK_METHOD0(MockedPoll, void());

 protected:
  virtual void TearDown() {
    // If the GpuScheduler posts any tasks, this forces them to run.
    base::MessageLoop::current()->RunUntilIdle();

    BaseFencedAllocatorTest::TearDown();
  }
};

TEST_F(FencedAllocatorPollTest, TestPoll) {
  scoped_ptr<FencedAllocator> allocator(
      new FencedAllocator(kBufferSize,
                          helper_.get(),
                          base::Bind(&FencedAllocatorPollTest::MockedPoll,
                                     base::Unretained(this))));

  FencedAllocator::Offset mem1 = allocator->Alloc(kAllocSize);
  FencedAllocator::Offset mem2 = allocator->Alloc(kAllocSize);
  EXPECT_NE(mem1, FencedAllocator::kInvalidOffset);
  EXPECT_NE(mem2, FencedAllocator::kInvalidOffset);
  EXPECT_TRUE(allocator->CheckConsistency());
  EXPECT_EQ(allocator->bytes_in_use(), kAllocSize * 2);

  // Check that no-op Poll doesn't affect the state.
  EXPECT_CALL(*this, MockedPoll()).RetiresOnSaturation();
  allocator->FreeUnused();
  EXPECT_TRUE(allocator->CheckConsistency());
  EXPECT_EQ(allocator->bytes_in_use(), kAllocSize * 2);

  // Check that freeing in Poll works.
  base::Closure free_mem1_closure =
      base::Bind(&FencedAllocator::Free,
                 base::Unretained(allocator.get()),
                 mem1);
  EXPECT_CALL(*this, MockedPoll())
      .WillOnce(InvokeWithoutArgs(&free_mem1_closure, &base::Closure::Run))
      .RetiresOnSaturation();
  allocator->FreeUnused();
  EXPECT_TRUE(allocator->CheckConsistency());
  EXPECT_EQ(allocator->bytes_in_use(), kAllocSize * 1);

  // Check that freeing still works.
  EXPECT_CALL(*this, MockedPoll()).RetiresOnSaturation();
  allocator->Free(mem2);
  allocator->FreeUnused();
  EXPECT_TRUE(allocator->CheckConsistency());
  EXPECT_EQ(allocator->bytes_in_use(), 0u);

  allocator.reset();
}

// Test fixture for FencedAllocatorWrapper test - Creates a
// FencedAllocatorWrapper, using a CommandBufferHelper with a mock
// AsyncAPIInterface for its interface (calling it directly, not through the
// RPC mechanism), making sure Noops are ignored and SetToken are properly
// forwarded to the engine.
class FencedAllocatorWrapperTest : public BaseFencedAllocatorTest {
 protected:
  void SetUp() override {
    BaseFencedAllocatorTest::SetUp();

    // Though allocating this buffer isn't strictly necessary, it makes
    // allocations point to valid addresses, so they could be used for
    // something.
    buffer_.reset(static_cast<char*>(base::AlignedAlloc(
        kBufferSize, kAllocAlignment)));
    allocator_.reset(new FencedAllocatorWrapper(kBufferSize,
                                                helper_.get(),
                                                base::Bind(&EmptyPoll),
                                                buffer_.get()));
  }

  void TearDown() override {
    // If the GpuScheduler posts any tasks, this forces them to run.
    base::MessageLoop::current()->RunUntilIdle();

    EXPECT_TRUE(allocator_->CheckConsistency());

    BaseFencedAllocatorTest::TearDown();
  }

  scoped_ptr<FencedAllocatorWrapper> allocator_;
  scoped_ptr<char, base::AlignedFreeDeleter> buffer_;
};

// Checks basic alloc and free.
TEST_F(FencedAllocatorWrapperTest, TestBasic) {
  allocator_->CheckConsistency();

  const unsigned int kSize = 16;
  void *pointer = allocator_->Alloc(kSize);
  ASSERT_TRUE(pointer);
  EXPECT_LE(buffer_.get(), static_cast<char *>(pointer));
  EXPECT_GE(kBufferSize, static_cast<char *>(pointer) - buffer_.get() + kSize);
  EXPECT_TRUE(allocator_->CheckConsistency());

  allocator_->Free(pointer);
  EXPECT_TRUE(allocator_->CheckConsistency());

  char *pointer_char = allocator_->AllocTyped<char>(kSize);
  ASSERT_TRUE(pointer_char);
  EXPECT_LE(buffer_.get(), pointer_char);
  EXPECT_GE(buffer_.get() + kBufferSize, pointer_char + kSize);
  allocator_->Free(pointer_char);
  EXPECT_TRUE(allocator_->CheckConsistency());

  unsigned int *pointer_uint = allocator_->AllocTyped<unsigned int>(kSize);
  ASSERT_TRUE(pointer_uint);
  EXPECT_LE(buffer_.get(), reinterpret_cast<char *>(pointer_uint));
  EXPECT_GE(buffer_.get() + kBufferSize,
            reinterpret_cast<char *>(pointer_uint + kSize));

  // Check that it did allocate kSize * sizeof(unsigned int). We can't tell
  // directly, except from the remaining size.
  EXPECT_EQ(kBufferSize - kSize * sizeof(*pointer_uint),
            allocator_->GetLargestFreeSize());
  allocator_->Free(pointer_uint);
}

// Test alloc 0 fails.
TEST_F(FencedAllocatorWrapperTest, TestAllocZero) {
  allocator_->CheckConsistency();

  void *pointer = allocator_->Alloc(0);
  ASSERT_FALSE(pointer);
  EXPECT_TRUE(allocator_->CheckConsistency());
}

// Checks that allocation offsets are aligned to multiples of 16 bytes.
TEST_F(FencedAllocatorWrapperTest, TestAlignment) {
  allocator_->CheckConsistency();

  const unsigned int kSize1 = 75;
  void *pointer1 = allocator_->Alloc(kSize1);
  ASSERT_TRUE(pointer1);
  EXPECT_EQ(reinterpret_cast<intptr_t>(pointer1) & (kAllocAlignment - 1), 0);
  EXPECT_TRUE(allocator_->CheckConsistency());

  const unsigned int kSize2 = 43;
  void *pointer2 = allocator_->Alloc(kSize2);
  ASSERT_TRUE(pointer2);
  EXPECT_EQ(reinterpret_cast<intptr_t>(pointer2) & (kAllocAlignment - 1), 0);
  EXPECT_TRUE(allocator_->CheckConsistency());

  allocator_->Free(pointer2);
  EXPECT_TRUE(allocator_->CheckConsistency());

  allocator_->Free(pointer1);
  EXPECT_TRUE(allocator_->CheckConsistency());
}

// Checks out-of-memory condition.
TEST_F(FencedAllocatorWrapperTest, TestOutOfMemory) {
  allocator_->CheckConsistency();

  const unsigned int kSize = 16;
  const unsigned int kAllocCount = kBufferSize / kSize;
  CHECK(kAllocCount * kSize == kBufferSize);

  // Allocate several buffers to fill in the memory.
  void *pointers[kAllocCount];
  for (unsigned int i = 0; i < kAllocCount; ++i) {
    pointers[i] = allocator_->Alloc(kSize);
    EXPECT_TRUE(pointers[i]);
    EXPECT_TRUE(allocator_->CheckConsistency());
  }

  // This allocation should fail.
  void *pointer_failed = allocator_->Alloc(kSize);
  EXPECT_FALSE(pointer_failed);
  EXPECT_TRUE(allocator_->CheckConsistency());

  // Free one successful allocation, reallocate with half the size
  allocator_->Free(pointers[0]);
  EXPECT_TRUE(allocator_->CheckConsistency());
  pointers[0] = allocator_->Alloc(kSize/2);
  EXPECT_TRUE(pointers[0]);
  EXPECT_TRUE(allocator_->CheckConsistency());

  // This allocation should fail as well.
  pointer_failed = allocator_->Alloc(kSize);
  EXPECT_FALSE(pointer_failed);
  EXPECT_TRUE(allocator_->CheckConsistency());

  // Free up everything.
  for (unsigned int i = 0; i < kAllocCount; ++i) {
    allocator_->Free(pointers[i]);
    EXPECT_TRUE(allocator_->CheckConsistency());
  }
}

// Checks the free-pending-token mechanism.
TEST_F(FencedAllocatorWrapperTest, TestFreePendingToken) {
  allocator_->CheckConsistency();

  const unsigned int kSize = 16;
  const unsigned int kAllocCount = kBufferSize / kSize;
  CHECK(kAllocCount * kSize == kBufferSize);

  // Allocate several buffers to fill in the memory.
  void *pointers[kAllocCount];
  for (unsigned int i = 0; i < kAllocCount; ++i) {
    pointers[i] = allocator_->Alloc(kSize);
    EXPECT_TRUE(pointers[i]);
    EXPECT_TRUE(allocator_->CheckConsistency());
  }

  // This allocation should fail.
  void *pointer_failed = allocator_->Alloc(kSize);
  EXPECT_FALSE(pointer_failed);
  EXPECT_TRUE(allocator_->CheckConsistency());

  // Free one successful allocation, pending fence.
  int32 token = helper_.get()->InsertToken();
  allocator_->FreePendingToken(pointers[0], token);
  EXPECT_TRUE(allocator_->CheckConsistency());

  // The way we hooked up the helper and engine, it won't process commands
  // until it has to wait for something. Which means the token shouldn't have
  // passed yet at this point.
  EXPECT_GT(token, GetToken());

  // This allocation will need to reclaim the space freed above, so that should
  // process the commands until the token is passed.
  pointers[0] = allocator_->Alloc(kSize);
  EXPECT_TRUE(pointers[0]);
  EXPECT_TRUE(allocator_->CheckConsistency());
  // Check that the token has indeed passed.
  EXPECT_LE(token, GetToken());

  // Free up everything.
  for (unsigned int i = 0; i < kAllocCount; ++i) {
    allocator_->Free(pointers[i]);
    EXPECT_TRUE(allocator_->CheckConsistency());
  }
}

}  // namespace gpu
