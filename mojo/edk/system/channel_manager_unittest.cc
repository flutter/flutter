// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/channel_manager.h"

#include "base/callback.h"
#include "base/message_loop/message_loop.h"
#include "base/run_loop.h"
#include "base/thread_task_runner_handle.h"
#include "mojo/edk/embedder/platform_channel_pair.h"
#include "mojo/edk/embedder/platform_task_runner.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/message_pipe_dispatcher.h"
#include "mojo/edk/test/simple_test_thread.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace {

class ChannelManagerTest : public testing::Test {
 public:
  ChannelManagerTest()
      : message_loop_(base::MessageLoop::TYPE_IO),
        channel_manager_(&platform_support_,
                         message_loop_.task_runner(),
                         nullptr) {}
  ~ChannelManagerTest() override {}

 protected:
  ChannelManager& channel_manager() { return channel_manager_; }

 private:
  embedder::SimplePlatformSupport platform_support_;
  base::MessageLoop message_loop_;
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

  channel_manager().WillShutdownChannel(id);

  channel_manager().ShutdownChannelOnIOThread(id);
  // |ChannelManager| should have given up its ref.
  ch->AssertHasOneRef();

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
  // Not calling |WillShutdownChannel()| (on |id2|) is okay too.

  channel_manager().ShutdownChannelOnIOThread(id1);
  ch1->AssertHasOneRef();
  channel_manager().ShutdownChannelOnIOThread(id2);
  ch2->AssertHasOneRef();

  EXPECT_EQ(MOJO_RESULT_OK, d1->Close());
  EXPECT_EQ(MOJO_RESULT_OK, d2->Close());
}

class OtherThread : public mojo::test::SimpleTestThread {
 public:
  // Note: There should be no other refs to the channel identified by
  // |channel_id| outside the channel manager.
  OtherThread(embedder::PlatformTaskRunnerRefPtr task_runner,
              ChannelManager* channel_manager,
              ChannelId channel_id,
              const base::Closure& quit_closure)
      : task_runner_(task_runner),
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

    channel_manager_->WillShutdownChannel(channel_id_);

    {
      base::MessageLoop message_loop;
      base::RunLoop run_loop;
      channel_manager_->ShutdownChannel(channel_id_, run_loop.QuitClosure(),
                                        message_loop.task_runner());
      run_loop.Run();
    }

    embedder::PlatformPostTask(task_runner_.get(), quit_closure_);
  }

  const embedder::PlatformTaskRunnerRefPtr task_runner_;
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

  base::RunLoop run_loop;
  OtherThread thread(base::ThreadTaskRunnerHandle::Get(), &channel_manager(),
                     id, run_loop.QuitClosure());
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
