// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <string>
#include <vector>

#include "base/bind.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/strings/stringprintf.h"
#include "base/test/perf_time_logger.h"
#include "mojo/edk/embedder/scoped_platform_handle.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/local_message_pipe_endpoint.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/message_pipe_test_utils.h"
#include "mojo/edk/system/proxy_message_pipe_endpoint.h"
#include "mojo/edk/system/raw_channel.h"
#include "mojo/edk/system/test_utils.h"
#include "mojo/edk/test/test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace {

class MultiprocessMessagePipePerfTest
    : public test::MultiprocessMessagePipeTestBase {
 public:
  MultiprocessMessagePipePerfTest() : message_count_(0), message_size_(0) {}

  void SetUpMeasurement(int message_count, size_t message_size) {
    message_count_ = message_count;
    message_size_ = message_size;
    payload_ = std::string(message_size, '*');
    read_buffer_.resize(message_size * 2);
  }

 protected:
  void WriteWaitThenRead(scoped_refptr<MessagePipe> mp) {
    CHECK_EQ(mp->WriteMessage(0, UserPointer<const void>(payload_.data()),
                              static_cast<uint32_t>(payload_.size()), nullptr,
                              MOJO_WRITE_MESSAGE_FLAG_NONE),
             MOJO_RESULT_OK);
    HandleSignalsState hss;
    CHECK_EQ(test::WaitIfNecessary(mp, MOJO_HANDLE_SIGNAL_READABLE, &hss),
             MOJO_RESULT_OK);
    uint32_t read_buffer_size = static_cast<uint32_t>(read_buffer_.size());
    CHECK_EQ(mp->ReadMessage(0, UserPointer<void>(&read_buffer_[0]),
                             MakeUserPointer(&read_buffer_size), nullptr,
                             nullptr, MOJO_READ_MESSAGE_FLAG_NONE),
             MOJO_RESULT_OK);
    CHECK_EQ(read_buffer_size, static_cast<uint32_t>(payload_.size()));
  }

  void SendQuitMessage(scoped_refptr<MessagePipe> mp) {
    CHECK_EQ(mp->WriteMessage(0, UserPointer<const void>(""), 0, nullptr,
                              MOJO_WRITE_MESSAGE_FLAG_NONE),
             MOJO_RESULT_OK);
  }

  void Measure(scoped_refptr<MessagePipe> mp) {
    // Have one ping-pong to ensure channel being established.
    WriteWaitThenRead(mp);

    std::string test_name =
        base::StringPrintf("IPC_Perf_%dx_%u", message_count_,
                           static_cast<unsigned>(message_size_));
    base::PerfTimeLogger logger(test_name.c_str());

    for (int i = 0; i < message_count_; ++i)
      WriteWaitThenRead(mp);

    logger.Done();
  }

 private:
  int message_count_;
  size_t message_size_;
  std::string payload_;
  std::string read_buffer_;
  scoped_ptr<base::PerfTimeLogger> perf_logger_;
};

// For each message received, sends a reply message with the same contents
// repeated twice, until the other end is closed or it receives "quitquitquit"
// (which it doesn't reply to). It'll return the number of messages received,
// not including any "quitquitquit" message, modulo 100.
MOJO_MULTIPROCESS_TEST_CHILD_MAIN(PingPongClient) {
  embedder::SimplePlatformSupport platform_support;
  test::ChannelThread channel_thread(&platform_support);
  embedder::ScopedPlatformHandle client_platform_handle =
      mojo::test::MultiprocessTestHelper::client_platform_handle.Pass();
  CHECK(client_platform_handle.is_valid());
  scoped_refptr<ChannelEndpoint> ep;
  scoped_refptr<MessagePipe> mp(MessagePipe::CreateLocalProxy(&ep));
  channel_thread.Start(client_platform_handle.Pass(), ep);

  std::string buffer(1000000, '\0');
  int rv = 0;
  while (true) {
    // Wait for our end of the message pipe to be readable.
    HandleSignalsState hss;
    MojoResult result =
        test::WaitIfNecessary(mp, MOJO_HANDLE_SIGNAL_READABLE, &hss);
    if (result != MOJO_RESULT_OK) {
      rv = result;
      break;
    }

    uint32_t read_size = static_cast<uint32_t>(buffer.size());
    CHECK_EQ(mp->ReadMessage(0, UserPointer<void>(&buffer[0]),
                             MakeUserPointer(&read_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE),
             MOJO_RESULT_OK);

    // Empty message indicates quit.
    if (read_size == 0)
      break;

    CHECK_EQ(mp->WriteMessage(0, UserPointer<const void>(&buffer[0]),
                              static_cast<uint32_t>(read_size), nullptr,
                              MOJO_WRITE_MESSAGE_FLAG_NONE),
             MOJO_RESULT_OK);
  }

  mp->Close(0);
  return rv;
}

// Repeatedly sends messages as previous one got replied by the child.
// Waits for the child to close its end before quitting once specified
// number of messages has been sent.
#if defined(OS_ANDROID)
// Android multi-process tests are not executing the new process. This is flaky.
#define MAYBE_PingPong DISABLED_PingPong
#else
#define MAYBE_PingPong PingPong
#endif  // defined(OS_ANDROID)
TEST_F(MultiprocessMessagePipePerfTest, MAYBE_PingPong) {
  helper()->StartChild("PingPongClient");

  scoped_refptr<ChannelEndpoint> ep;
  scoped_refptr<MessagePipe> mp(MessagePipe::CreateLocalProxy(&ep));
  Init(ep);

  // This values are set to align with one at ipc_pertests.cc for comparison.
  const size_t kMsgSize[5] = {12, 144, 1728, 20736, 248832};
  const int kMessageCount[5] = {50000, 50000, 50000, 12000, 1000};

  for (size_t i = 0; i < 5; i++) {
    SetUpMeasurement(kMessageCount[i], kMsgSize[i]);
    Measure(mp);
  }

  SendQuitMessage(mp);
  mp->Close(0);
  EXPECT_EQ(0, helper()->WaitForChildShutdown());
}

}  // namespace
}  // namespace system
}  // namespace mojo
