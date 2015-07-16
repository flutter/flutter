// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_loop.h"
#include "gpu/command_buffer/common/command_buffer_mock.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder_mock.h"
#include "gpu/command_buffer/service/gpu_scheduler.h"
#include "gpu/command_buffer/service/mocks.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

#if defined(OS_MACOSX)
#include "base/mac/scoped_nsautorelease_pool.h"
#endif

using testing::_;
using testing::DoAll;
using testing::Invoke;
using testing::NiceMock;
using testing::Return;
using testing::SetArgumentPointee;
using testing::StrictMock;

namespace gpu {

const size_t kRingBufferSize = 1024;

class GpuSchedulerTest : public testing::Test {
 protected:
  static const int32 kTransferBufferId = 123;

  void SetUp() override {
    scoped_ptr<base::SharedMemory> shared_memory(new ::base::SharedMemory);
    shared_memory->CreateAndMapAnonymous(kRingBufferSize);
    buffer_ = static_cast<int32*>(shared_memory->memory());
    shared_memory_buffer_ =
        MakeBufferFromSharedMemory(shared_memory.Pass(), kRingBufferSize);
    memset(buffer_, 0, kRingBufferSize);

    command_buffer_.reset(new MockCommandBuffer);

    CommandBuffer::State default_state;
    ON_CALL(*command_buffer_.get(), GetLastState())
        .WillByDefault(Return(default_state));
    ON_CALL(*command_buffer_.get(), GetPutOffset())
        .WillByDefault(Return(0));

    decoder_.reset(new gles2::MockGLES2Decoder());
    // Install FakeDoCommands handler so we can use individual DoCommand()
    // expectations.
    EXPECT_CALL(*decoder_, DoCommands(_, _, _, _)).WillRepeatedly(
        Invoke(decoder_.get(), &gles2::MockGLES2Decoder::FakeDoCommands));

    scheduler_.reset(new gpu::GpuScheduler(command_buffer_.get(),
                                           decoder_.get(),
                                           decoder_.get()));
    EXPECT_CALL(*command_buffer_, GetTransferBuffer(kTransferBufferId))
       .WillOnce(Return(shared_memory_buffer_));
    EXPECT_CALL(*command_buffer_, SetGetOffset(0));
    EXPECT_TRUE(scheduler_->SetGetBuffer(kTransferBufferId));
  }

  void TearDown() override {
    // Ensure that any unexpected tasks posted by the GPU scheduler are executed
    // in order to fail the test.
    base::MessageLoop::current()->RunUntilIdle();
  }

  error::Error GetError() {
    return command_buffer_->GetLastState().error;
  }

#if defined(OS_MACOSX)
  base::mac::ScopedNSAutoreleasePool autorelease_pool_;
#endif
  base::MessageLoop message_loop;
  scoped_ptr<MockCommandBuffer> command_buffer_;
  scoped_refptr<Buffer> shared_memory_buffer_;
  int32* buffer_;
  scoped_ptr<gles2::MockGLES2Decoder> decoder_;
  scoped_ptr<GpuScheduler> scheduler_;
};

TEST_F(GpuSchedulerTest, SchedulerDoesNothingIfRingBufferIsEmpty) {
  CommandBuffer::State state;

  EXPECT_CALL(*command_buffer_, GetLastState())
    .WillRepeatedly(Return(state));

  EXPECT_CALL(*command_buffer_, SetParseError(_))
    .Times(0);

  scheduler_->PutChanged();
}

TEST_F(GpuSchedulerTest, GetSetBuffer) {
  CommandBuffer::State state;

  // Set the get offset to something not 0.
  EXPECT_CALL(*command_buffer_, SetGetOffset(2));
  scheduler_->SetGetOffset(2);
  EXPECT_EQ(2, scheduler_->GetGetOffset());

  // Set the buffer.
  EXPECT_CALL(*command_buffer_, GetTransferBuffer(kTransferBufferId))
     .WillOnce(Return(shared_memory_buffer_));
  EXPECT_CALL(*command_buffer_, SetGetOffset(0));
  EXPECT_TRUE(scheduler_->SetGetBuffer(kTransferBufferId));

  // Check the get offset was reset.
  EXPECT_EQ(0, scheduler_->GetGetOffset());
}

TEST_F(GpuSchedulerTest, ProcessesOneCommand) {
  CommandHeader* header = reinterpret_cast<CommandHeader*>(&buffer_[0]);
  header[0].command = 7;
  header[0].size = 2;
  buffer_[1] = 123;

  CommandBuffer::State state;

  EXPECT_CALL(*command_buffer_, GetLastState())
    .WillRepeatedly(Return(state));
  EXPECT_CALL(*command_buffer_, GetPutOffset())
    .WillRepeatedly(Return(2));
  EXPECT_CALL(*command_buffer_, SetGetOffset(2));

  EXPECT_CALL(*decoder_, DoCommand(7, 1, &buffer_[0]))
    .WillOnce(Return(error::kNoError));

  EXPECT_CALL(*command_buffer_, SetParseError(_))
    .Times(0);

  scheduler_->PutChanged();
}

TEST_F(GpuSchedulerTest, ProcessesTwoCommands) {
  CommandHeader* header = reinterpret_cast<CommandHeader*>(&buffer_[0]);
  header[0].command = 7;
  header[0].size = 2;
  buffer_[1] = 123;
  header[2].command = 8;
  header[2].size = 1;

  CommandBuffer::State state;

  EXPECT_CALL(*command_buffer_, GetLastState())
    .WillRepeatedly(Return(state));
  EXPECT_CALL(*command_buffer_, GetPutOffset())
    .WillRepeatedly(Return(3));

  EXPECT_CALL(*decoder_, DoCommand(7, 1, &buffer_[0]))
    .WillOnce(Return(error::kNoError));

  EXPECT_CALL(*decoder_, DoCommand(8, 0, &buffer_[2]))
    .WillOnce(Return(error::kNoError));
  EXPECT_CALL(*command_buffer_, SetGetOffset(3));

  scheduler_->PutChanged();
}

TEST_F(GpuSchedulerTest, SetsErrorCodeOnCommandBuffer) {
  CommandHeader* header = reinterpret_cast<CommandHeader*>(&buffer_[0]);
  header[0].command = 7;
  header[0].size = 1;

  CommandBuffer::State state;

  EXPECT_CALL(*command_buffer_, GetLastState())
    .WillRepeatedly(Return(state));
  EXPECT_CALL(*command_buffer_, GetPutOffset())
    .WillRepeatedly(Return(1));

  EXPECT_CALL(*decoder_, DoCommand(7, 0, &buffer_[0]))
    .WillOnce(Return(
        error::kUnknownCommand));
  EXPECT_CALL(*command_buffer_, SetGetOffset(1));

  EXPECT_CALL(*command_buffer_, SetContextLostReason(_));
  EXPECT_CALL(*decoder_, GetContextLostReason())
    .WillOnce(Return(error::kUnknown));
  EXPECT_CALL(*command_buffer_,
      SetParseError(error::kUnknownCommand));

  scheduler_->PutChanged();
}

TEST_F(GpuSchedulerTest, ProcessCommandsDoesNothingAfterError) {
  CommandBuffer::State state;
  state.error = error::kGenericError;

  EXPECT_CALL(*command_buffer_, GetLastState())
    .WillRepeatedly(Return(state));

  scheduler_->PutChanged();
}

TEST_F(GpuSchedulerTest, CanGetAddressOfSharedMemory) {
  EXPECT_CALL(*command_buffer_.get(), GetTransferBuffer(7))
    .WillOnce(Return(shared_memory_buffer_));

  EXPECT_EQ(&buffer_[0], scheduler_->GetSharedMemoryBuffer(7)->memory());
}

ACTION_P2(SetPointee, address, value) {
  *address = value;
}

TEST_F(GpuSchedulerTest, CanGetSizeOfSharedMemory) {
  EXPECT_CALL(*command_buffer_.get(), GetTransferBuffer(7))
    .WillOnce(Return(shared_memory_buffer_));

  EXPECT_EQ(kRingBufferSize, scheduler_->GetSharedMemoryBuffer(7)->size());
}

TEST_F(GpuSchedulerTest, SetTokenForwardsToCommandBuffer) {
  EXPECT_CALL(*command_buffer_, SetToken(7));
  scheduler_->set_token(7);
}

}  // namespace gpu
