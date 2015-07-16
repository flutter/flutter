// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains unit tests for gles2 commmands

#include <limits>

#include "base/bind.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/thread.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"

namespace gpu {
namespace gles2 {

class GLES2FormatTest : public testing::Test {
 protected:
  static const unsigned char kInitialValue = 0xBD;

  void SetUp() override { memset(buffer_, kInitialValue, sizeof(buffer_)); }

  void TearDown() override {}

  template <typename T>
  T* GetBufferAs() {
    return static_cast<T*>(static_cast<void*>(&buffer_));
  }

  void CheckBytesWritten(
      const void* end, size_t expected_size, size_t written_size) {
    size_t actual_size = static_cast<const unsigned char*>(end) -
        GetBufferAs<const unsigned char>();
    EXPECT_LT(actual_size, sizeof(buffer_));
    EXPECT_GT(actual_size, 0u);
    EXPECT_EQ(expected_size, actual_size);
    EXPECT_EQ(kInitialValue, buffer_[written_size]);
    EXPECT_NE(kInitialValue, buffer_[written_size - 1]);
  }

  void CheckBytesWrittenMatchesExpectedSize(
      const void* end, size_t expected_size) {
    CheckBytesWritten(end, expected_size, expected_size);
  }

 private:
  unsigned char buffer_[1024];
};

void SignalCompletion(uint32* assigned_async_token_ptr,
                      uint32 async_token,
                      AsyncUploadSync* sync) {
  EXPECT_EQ(async_token, *assigned_async_token_ptr);
  sync->SetAsyncUploadToken(async_token);
}

TEST(GLES2FormatAsyncUploadSyncTest, AsyncUploadSync) {
  const size_t kSize = 10;
  const size_t kCount = 1000;

  base::Thread thread("GLES2FormatUploadSyncTest - Fake Upload Thread");
  thread.Start();

  // Run the same test 50 times so we retest the wrap as well.
  for (size_t test_run = 0; test_run < 50; ++test_run) {
    AsyncUploadSync sync;
    sync.Reset();

    uint32 buffer_tokens[kSize];
    memset(buffer_tokens, 0, sizeof(buffer_tokens));

    // Start with a token large enough so that we'll wrap.
    uint32 async_token = std::numeric_limits<uint32>::max() - kCount / 2;

    // Set initial async token.
    sync.SetAsyncUploadToken(async_token);

    for (size_t i = 0; i < kCount; ++i) {
      size_t buffer = i % kSize;

      // Loop until previous async token has passed if any was set.
      while (buffer_tokens[buffer] &&
             !sync.HasAsyncUploadTokenPassed(buffer_tokens[buffer]))
        base::PlatformThread::YieldCurrentThread();

      // Next token, skip 0.
      async_token++;
      if (async_token == 0)
        async_token++;

      // Set the buffer's associated token.
      buffer_tokens[buffer] = async_token;

      // Set the async upload token on the fake upload thread and assert that
      // the associated buffer still has the given token.
      thread.message_loop()->PostTask(FROM_HERE,
                                      base::Bind(&SignalCompletion,
                                                 &buffer_tokens[buffer],
                                                 async_token,
                                                 &sync));
    }

    // Flush the thread message loop before starting again.
    base::WaitableEvent waitable(false, false);
    thread.message_loop()->PostTask(FROM_HERE,
                                    base::Bind(&base::WaitableEvent::Signal,
                                               base::Unretained(&waitable)));
    waitable.Wait();
  }
}

// GCC requires these declarations, but MSVC requires they not be present
#ifndef _MSC_VER
const unsigned char GLES2FormatTest::kInitialValue;
#endif

#include "gpu/command_buffer/common/gles2_cmd_format_test_autogen.h"

}  // namespace gles2
}  // namespace gpu

