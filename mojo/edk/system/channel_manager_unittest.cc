// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/channel_manager.h"

#include <functional>
#include <memory>
#include <thread>

#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/platform/message_loop.h"
#include "mojo/edk/platform/platform_pipe.h"
#include "mojo/edk/platform/task_runner.h"
#include "mojo/edk/platform/test_message_loops.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/message_pipe_dispatcher.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::MessageLoop;
using mojo::platform::PlatformHandleWatcher;
using mojo::platform::PlatformPipe;
using mojo::platform::TaskRunner;
using mojo::platform::test::CreateTestMessageLoop;
using mojo::platform::test::CreateTestMessageLoopForIO;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace {

class ChannelManagerTest : public testing::Test {
 public:
  ChannelManagerTest()
      : platform_support_(embedder::CreateSimplePlatformSupport()),
        platform_handle_watcher_(nullptr),
        message_loop_(CreateTestMessageLoopForIO(&platform_handle_watcher_)),
        channel_manager_(platform_support_.get(),
                         message_loop_->GetTaskRunner().Clone(),
                         platform_handle_watcher_,
                         nullptr) {}
  ~ChannelManagerTest() override {}

 protected:
  MessageLoop* message_loop() { return message_loop_.get(); }
  const RefPtr<TaskRunner>& task_runner() {
    return message_loop_->GetTaskRunner();
  }
  ChannelManager& channel_manager() { return channel_manager_; }

 private:
  std::unique_ptr<embedder::PlatformSupport> platform_support_;
  // TODO(vtl): The |PlatformHandleWatcher| and |MessageLoop| should be injected
  // into the |ChannelManager|.
  // Valid while |message_loop_| is valid.
  PlatformHandleWatcher* platform_handle_watcher_;
  std::unique_ptr<MessageLoop> message_loop_;
  // Note: This should be *after* the above, since they must be initialized
  // before it (and should outlive it).
  ChannelManager channel_manager_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ChannelManagerTest);
};

TEST_F(ChannelManagerTest, Basic) {
  PlatformPipe channel_pair;

  const ChannelId id = 1;
  RefPtr<MessagePipeDispatcher> d = channel_manager().CreateChannelOnIOThread(
      id, channel_pair.handle0.Pass());

  RefPtr<Channel> ch = channel_manager().GetChannel(id);
  EXPECT_TRUE(ch);
  // |ChannelManager| should have a ref.
  EXPECT_FALSE(ch->HasOneRef());

  channel_manager().WillShutdownChannel(id);
  // |ChannelManager| should still have a ref.
  EXPECT_FALSE(ch->HasOneRef());

  channel_manager().ShutdownChannelOnIOThread(id);
  // |ChannelManager| should have given up its ref.
  EXPECT_TRUE(ch->HasOneRef());

  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
}

TEST_F(ChannelManagerTest, TwoChannels) {
  PlatformPipe channel_pair;

  const ChannelId id1 = 1;
  RefPtr<MessagePipeDispatcher> d1 = channel_manager().CreateChannelOnIOThread(
      id1, channel_pair.handle0.Pass());

  const ChannelId id2 = 2;
  RefPtr<MessagePipeDispatcher> d2 = channel_manager().CreateChannelOnIOThread(
      id2, channel_pair.handle1.Pass());

  RefPtr<Channel> ch1 = channel_manager().GetChannel(id1);
  EXPECT_TRUE(ch1);

  RefPtr<Channel> ch2 = channel_manager().GetChannel(id2);
  EXPECT_TRUE(ch2);

  // Calling |WillShutdownChannel()| multiple times (on |id1|) is okay.
  channel_manager().WillShutdownChannel(id1);
  channel_manager().WillShutdownChannel(id1);
  EXPECT_FALSE(ch1->HasOneRef());
  // Not calling |WillShutdownChannel()| (on |id2|) is okay too.

  channel_manager().ShutdownChannelOnIOThread(id1);
  EXPECT_TRUE(ch1->HasOneRef());
  channel_manager().ShutdownChannelOnIOThread(id2);
  EXPECT_TRUE(ch2->HasOneRef());

  EXPECT_EQ(MOJO_RESULT_OK, d1->Close());
  EXPECT_EQ(MOJO_RESULT_OK, d2->Close());
}

TEST_F(ChannelManagerTest, CallsFromOtherThread) {
  PlatformPipe channel_pair;

  const ChannelId id = 1;
  RefPtr<MessagePipeDispatcher> d = channel_manager().CreateChannelOnIOThread(
      id, channel_pair.handle0.Pass());

  std::thread other_thread([this, id]() {
    // TODO(vtl): Once we have a way of creating a channel from off the I/O
    // thread, do that here instead.

    // You can use any unique, nonzero value as the ID.
    RefPtr<Channel> ch = channel_manager().GetChannel(id);
    // |ChannelManager| should have a ref.
    EXPECT_FALSE(ch->HasOneRef());

    channel_manager().WillShutdownChannel(id);
    // |ChannelManager| should still have a ref.
    EXPECT_FALSE(ch->HasOneRef());

    {
      std::unique_ptr<MessageLoop> message_loop(CreateTestMessageLoop());
      channel_manager().ShutdownChannel(
          id, [&message_loop]() { message_loop->QuitNow(); },
          message_loop->GetTaskRunner().Clone());
      message_loop->Run();
    }

    task_runner()->PostTask([this]() { message_loop()->QuitNow(); });
  });
  message_loop()->Run();
  other_thread.join();

  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
}

// TODO(vtl): Test |CreateChannelWithoutBootstrapOnIOThread()|. (This will
// require additional functionality in |Channel|.)

}  // namespace
}  // namespace system
}  // namespace mojo
