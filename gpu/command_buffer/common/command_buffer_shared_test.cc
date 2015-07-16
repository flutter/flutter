// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the tests for the CommandBufferSharedState class.

#include "gpu/command_buffer/common/command_buffer_shared.h"
#include "base/bind.h"
#include "base/memory/scoped_ptr.h"
#include "base/threading/thread.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

class CommandBufferSharedTest : public testing::Test {
 protected:
  void SetUp() override {
    shared_state_.reset(new CommandBufferSharedState());
    shared_state_->Initialize();
  }

  scoped_ptr<CommandBufferSharedState> shared_state_;
};

TEST_F(CommandBufferSharedTest, TestBasic) {
  CommandBuffer::State state;

  shared_state_->Read(&state);

  EXPECT_LT(state.generation, 0x80000000);
  EXPECT_EQ(state.get_offset, 0);
  EXPECT_EQ(state.token, -1);
  EXPECT_EQ(state.error, gpu::error::kNoError);
  EXPECT_EQ(state.context_lost_reason, gpu::error::kUnknown);
}

static const int kSize = 100000;

void WriteToState(int32 *buffer,
                  CommandBufferSharedState* shared_state) {
  CommandBuffer::State state;
  for (int i = 0; i < kSize; i++) {
    state.token = i - 1;
    state.get_offset = i + 1;
    state.generation = i + 2;
    state.error = static_cast<gpu::error::Error>(i + 3);
    // Ensure that the producer doesn't update the buffer until after the
    // consumer reads from it.
    EXPECT_EQ(buffer[i], 0);

    shared_state->Write(state);
  }
}

TEST_F(CommandBufferSharedTest, TestConsistency) {
  scoped_ptr<int32[]> buffer;
  buffer.reset(new int32[kSize]);
  base::Thread consumer("Reader Thread");

  memset(buffer.get(), 0, kSize * sizeof(int32));

  consumer.Start();
  consumer.message_loop()->PostTask(
      FROM_HERE, base::Bind(&WriteToState, buffer.get(),
                            shared_state_.get()));

  CommandBuffer::State last_state;
  while (1) {
    CommandBuffer::State state = last_state;

    shared_state_->Read(&state);

    if (state.generation < last_state.generation)
      continue;

    if (state.get_offset >= 1) {
      buffer[state.get_offset - 1] = 1;
      // Check that the state is consistent
      EXPECT_LE(last_state.token, state.token);
      EXPECT_LE(last_state.generation, state.generation);
      last_state = state;
      EXPECT_EQ(state.token, state.get_offset - 2);
      EXPECT_EQ(state.generation,
                static_cast<unsigned int>(state.get_offset) + 1);
      EXPECT_EQ(state.error, state.get_offset + 2);

      if (state.get_offset == kSize)
        break;
    }
  }
}

}  // namespace gpu

