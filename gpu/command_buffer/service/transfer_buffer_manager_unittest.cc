// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/transfer_buffer_manager.h"

#include "base/memory/scoped_ptr.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/gmock/include/gmock/gmock.h"

using base::SharedMemory;

namespace gpu {

const static size_t kBufferSize = 1024;

class TransferBufferManagerTest : public testing::Test {
 protected:
  void SetUp() override {
    TransferBufferManager* manager = new TransferBufferManager();
    transfer_buffer_manager_.reset(manager);
    ASSERT_TRUE(manager->Initialize());
  }

  scoped_ptr<TransferBufferManagerInterface> transfer_buffer_manager_;
};

TEST_F(TransferBufferManagerTest, ZeroHandleMapsToNull) {
  EXPECT_TRUE(NULL == transfer_buffer_manager_->GetTransferBuffer(0).get());
}

TEST_F(TransferBufferManagerTest, NegativeHandleMapsToNull) {
  EXPECT_TRUE(NULL == transfer_buffer_manager_->GetTransferBuffer(-1).get());
}

TEST_F(TransferBufferManagerTest, OutOfRangeHandleMapsToNull) {
  EXPECT_TRUE(NULL == transfer_buffer_manager_->GetTransferBuffer(1).get());
}

TEST_F(TransferBufferManagerTest, CanRegisterTransferBuffer) {
  scoped_ptr<base::SharedMemory> shm(new base::SharedMemory());
  shm->CreateAndMapAnonymous(kBufferSize);
  base::SharedMemory* shm_raw_pointer = shm.get();
  scoped_ptr<SharedMemoryBufferBacking> backing(
      new SharedMemoryBufferBacking(shm.Pass(), kBufferSize));
  SharedMemoryBufferBacking* backing_raw_ptr = backing.get();

  EXPECT_TRUE(
      transfer_buffer_manager_->RegisterTransferBuffer(1, backing.Pass()));
  scoped_refptr<Buffer> registered =
      transfer_buffer_manager_->GetTransferBuffer(1);

  // Shared-memory ownership is transfered. It should be the same memory.
  EXPECT_EQ(backing_raw_ptr, registered->backing());
  EXPECT_EQ(shm_raw_pointer, backing_raw_ptr->shared_memory());
}

class FakeBufferBacking : public BufferBacking {
 public:
  void* GetMemory() const override {
    return reinterpret_cast<void*>(0xBADF00D0);
  }
  size_t GetSize() const override { return 42; }
  static scoped_ptr<BufferBacking> Make() {
    return scoped_ptr<BufferBacking>(new FakeBufferBacking);
  }
};

TEST_F(TransferBufferManagerTest, CanDestroyTransferBuffer) {
  EXPECT_TRUE(transfer_buffer_manager_->RegisterTransferBuffer(
      1, scoped_ptr<BufferBacking>(new FakeBufferBacking)));
  transfer_buffer_manager_->DestroyTransferBuffer(1);
  scoped_refptr<Buffer> registered =
      transfer_buffer_manager_->GetTransferBuffer(1);

  scoped_refptr<Buffer> null_buffer;
  EXPECT_EQ(null_buffer, registered);
}

TEST_F(TransferBufferManagerTest, CannotRegregisterTransferBufferId) {
  EXPECT_TRUE(transfer_buffer_manager_->RegisterTransferBuffer(
      1, FakeBufferBacking::Make()));
  EXPECT_FALSE(transfer_buffer_manager_->RegisterTransferBuffer(
      1, FakeBufferBacking::Make()));
  EXPECT_FALSE(transfer_buffer_manager_->RegisterTransferBuffer(
      1, FakeBufferBacking::Make()));
}

TEST_F(TransferBufferManagerTest, CanReuseTransferBufferIdAfterDestroying) {
  EXPECT_TRUE(transfer_buffer_manager_->RegisterTransferBuffer(
      1, FakeBufferBacking::Make()));
  transfer_buffer_manager_->DestroyTransferBuffer(1);
  EXPECT_TRUE(transfer_buffer_manager_->RegisterTransferBuffer(
      1, FakeBufferBacking::Make()));
}

TEST_F(TransferBufferManagerTest, DestroyUnusedTransferBufferIdDoesNotCrash) {
  transfer_buffer_manager_->DestroyTransferBuffer(1);
}

TEST_F(TransferBufferManagerTest, CannotRegisterNullTransferBuffer) {
  EXPECT_FALSE(transfer_buffer_manager_->RegisterTransferBuffer(
      0, FakeBufferBacking::Make()));
}

TEST_F(TransferBufferManagerTest, CannotRegisterNegativeTransferBufferId) {
  scoped_ptr<base::SharedMemory> shm(new base::SharedMemory());
  shm->CreateAndMapAnonymous(kBufferSize);
  EXPECT_FALSE(transfer_buffer_manager_->RegisterTransferBuffer(
      -1, FakeBufferBacking::Make()));
}

}  // namespace gpu
