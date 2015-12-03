// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/channel_manager.h"

#include <memory>

#include "base/callback.h"
#include "base/run_loop.h"
#include "mojo/edk/embedder/platform_channel_pair.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/platform/message_loop.h"
#include "mojo/edk/platform/message_loop_for_io.h"
#include "mojo/edk/platform/task_runner.h"
#include "mojo/edk/platform/test_message_loops.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/message_pipe_dispatcher.h"
#include "mojo/edk/system/test/simple_test_thread.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::MessageLoop;
using mojo::platform::MessageLoopForIO;
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
      : message_loop_(CreateTestMessageLoopForIO()),
        channel_manager_(&platform_support_,
                         message_loop_->GetTaskRunner().Clone(),
                         nullptr) {}
  ~ChannelManagerTest() override {}

 protected:
  const RefPtr<TaskRunner>& task_runner() {
    return message_loop_->GetTaskRunner();
  }
  ChannelManager& channel_manager() { return channel_manager_; }

 private:
  embedder::SimplePlatformSupport platform_support_;
  std::unique_ptr<MessageLoopForIO> message_loop_;
  // Note: This should be *after* the above, since they must be initialized
  // before it (and should outlive it).
  ChannelManager channel_manager_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ChannelManagerTest);
};

TEST_F(ChannelManagerTest, Basic) {
  embedder::PlatformChannelPair channel_pair;

  const ChannelId id = 1;
  RefPtr<MessagePipeDispatcher> d = channel_manager().CreateChannelOnIOThread(
      id, channel_pair.PassServerHandle());

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
  embedder::PlatformChannelPair channel_pair;

  const ChannelId id1 = 1;
  RefPtr<MessagePipeDispatcher> d1 = channel_manager().CreateChannelOnIOThread(
      id1, channel_pair.PassServerHandle());

  const ChannelId id2 = 2;
  RefPtr<MessagePipeDispatcher> d2 = channel_manager().CreateChannelOnIOThread(
      id2, channel_pair.PassClientHandle());

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

class OtherThread : public test::SimpleTestThread {
 public:
  // Note: There should be no other refs to the channel identified by
  // |channel_id| outside the channel manager.
  OtherThread(RefPtr<TaskRunner>&& task_runner,
              ChannelManager* channel_manager,
              ChannelId channel_id,
              const base::Closure& quit_closure)
      : task_runner_(std::move(task_runner)),
        channel_manager_(channel_manager),
        channel_id_(channel_id),
        quit_closure_(quit_closure) {}
  ~OtherThread() override {}

 private:
  void Run() override {
    // TODO(vtl): Once we have a way of creating a channel from off the I/O
    // thread, do that here instead.

    // You can use any unique, nonzero value as the ID.
    RefPtr<Channel> ch = channel_manager_->GetChannel(channel_id_);
    // |ChannelManager| should have a ref.
    EXPECT_FALSE(ch->HasOneRef());

    channel_manager_->WillShutdownChannel(channel_id_);
    // |ChannelManager| should still have a ref.
    EXPECT_FALSE(ch->HasOneRef());

    {
      std::unique_ptr<MessageLoop> message_loop(CreateTestMessageLoop());
      // TODO(vtl): Using |base::RunLoop| here is shady.
      base::RunLoop run_loop;
      channel_manager_->ShutdownChannel(channel_id_, run_loop.QuitClosure(),
                                        message_loop->GetTaskRunner().Clone());
      run_loop.Run();
    }

    task_runner_->PostTask(quit_closure_);
  }

  const RefPtr<TaskRunner> task_runner_;
  ChannelManager* const channel_manager_;
  const ChannelId channel_id_;
  base::Closure quit_closure_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(OtherThread);
};

TEST_F(ChannelManagerTest, CallsFromOtherThread) {
  embedder::PlatformChannelPair channel_pair;

  const ChannelId id = 1;
  RefPtr<MessagePipeDispatcher> d = channel_manager().CreateChannelOnIOThread(
      id, channel_pair.PassServerHandle());

  // TODO(vtl): Using |base::RunLoop| here is shady.
  base::RunLoop run_loop;
  OtherThread thread(task_runner().Clone(), &channel_manager(), id,
                     run_loop.QuitClosure());
  thread.Start();
  run_loop.Run();
  thread.Join();

  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
}

// TODO(vtl): Test |CreateChannelWithoutBootstrapOnIOThread()|. (This will
// require additional functionality in |Channel|.)

}  // namespace
}  // namespace system
}  // namespace mojo
