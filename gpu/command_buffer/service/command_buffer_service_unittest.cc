// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/threading/thread.h"
#include "gpu/command_buffer/common/cmd_buffer_common.h"
#include "gpu/command_buffer/service/command_buffer_service.h"
#include "gpu/command_buffer/service/transfer_buffer_manager.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/gmock/include/gmock/gmock.h"

using base::SharedMemory;
using testing::_;
using testing::DoAll;
using testing::Return;
using testing::SetArgumentPointee;
using testing::StrictMock;

namespace gpu {

class CommandBufferServiceTest : public testing::Test {
 protected:
  void SetUp() override {
    {
      TransferBufferManager* manager = new TransferBufferManager();
      transfer_buffer_manager_.reset(manager);
      EXPECT_TRUE(manager->Initialize());
    }
    command_buffer_.reset(
        new CommandBufferService(transfer_buffer_manager_.get()));
    EXPECT_TRUE(command_buffer_->Initialize());
  }

  int32 GetGetOffset() {
    return command_buffer_->GetLastState().get_offset;
  }

  int32 GetPutOffset() {
    return command_buffer_->GetPutOffset();
  }

  int32 GetToken() {
    return command_buffer_->GetLastState().token;
  }

  int32 GetError() {
    return command_buffer_->GetLastState().error;
  }

  bool Initialize(size_t size) {
    int32 id;
    command_buffer_->CreateTransferBuffer(size, &id);
    EXPECT_GT(id, 0);
    command_buffer_->SetGetBuffer(id);
    return true;
  }

  scoped_ptr<TransferBufferManagerInterface> transfer_buffer_manager_;
  scoped_ptr<CommandBufferService> command_buffer_;
};

TEST_F(CommandBufferServiceTest, InitializesCommandBuffer) {
  EXPECT_TRUE(Initialize(1024));
  CommandBuffer::State state = command_buffer_->GetLastState();
  EXPECT_EQ(0, state.get_offset);
  EXPECT_EQ(0, command_buffer_->GetPutOffset());
  EXPECT_EQ(0, state.token);
  EXPECT_EQ(error::kNoError, state.error);
}

namespace {

class CallbackTest {
 public:
  virtual void PutOffsetChanged() = 0;
  virtual bool GetBufferChanged(int32 id) = 0;
};

class MockCallbackTest : public CallbackTest {
 public:
   MOCK_METHOD0(PutOffsetChanged, void());
   MOCK_METHOD1(GetBufferChanged, bool(int32));
};

}  // anonymous namespace

TEST_F(CommandBufferServiceTest, CanSyncGetAndPutOffset) {
  Initialize(1024);

  scoped_ptr<StrictMock<MockCallbackTest> > change_callback(
      new StrictMock<MockCallbackTest>);
  command_buffer_->SetPutOffsetChangeCallback(
      base::Bind(
          &CallbackTest::PutOffsetChanged,
          base::Unretained(change_callback.get())));

  EXPECT_CALL(*change_callback, PutOffsetChanged());
  command_buffer_->Flush(2);
  EXPECT_EQ(0, GetGetOffset());
  EXPECT_EQ(2, GetPutOffset());

  EXPECT_CALL(*change_callback, PutOffsetChanged());
  command_buffer_->Flush(4);
  EXPECT_EQ(0, GetGetOffset());
  EXPECT_EQ(4, GetPutOffset());

  command_buffer_->SetGetOffset(2);
  EXPECT_EQ(2, GetGetOffset());
  EXPECT_CALL(*change_callback, PutOffsetChanged());
  command_buffer_->Flush(6);

  command_buffer_->Flush(-1);
  EXPECT_NE(error::kNoError, GetError());
  command_buffer_->Flush(1024);
  EXPECT_NE(error::kNoError, GetError());
}

TEST_F(CommandBufferServiceTest, SetGetBuffer) {
  int32 ring_buffer_id;
  command_buffer_->CreateTransferBuffer(1024, &ring_buffer_id);
  EXPECT_GT(ring_buffer_id, 0);

  scoped_ptr<StrictMock<MockCallbackTest> > change_callback(
      new StrictMock<MockCallbackTest>);
  command_buffer_->SetGetBufferChangeCallback(
      base::Bind(
          &CallbackTest::GetBufferChanged,
          base::Unretained(change_callback.get())));

  EXPECT_CALL(*change_callback, GetBufferChanged(ring_buffer_id))
      .WillOnce(Return(true));

  command_buffer_->SetGetBuffer(ring_buffer_id);
  EXPECT_EQ(0, GetGetOffset());
}

TEST_F(CommandBufferServiceTest, DefaultTokenIsZero) {
  EXPECT_EQ(0, GetToken());
}

TEST_F(CommandBufferServiceTest, CanSetToken) {
  command_buffer_->SetToken(7);
  EXPECT_EQ(7, GetToken());
}

TEST_F(CommandBufferServiceTest, DefaultParseErrorIsNoError) {
  EXPECT_EQ(0, GetError());
}

TEST_F(CommandBufferServiceTest, CanSetParseError) {
  command_buffer_->SetParseError(error::kInvalidSize);
  EXPECT_EQ(1, GetError());
}
}  // namespace gpu
