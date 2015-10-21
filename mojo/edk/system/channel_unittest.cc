// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/channel.h"

#include <utility>

#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/channel_endpoint_id.h"
#include "mojo/edk/system/channel_test_base.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/ref_ptr.h"
#include "mojo/edk/system/test_utils.h"
#include "mojo/edk/system/waiter.h"

namespace mojo {
namespace system {
namespace {

using ChannelTest = test::ChannelTestBase;

void DoNothing() {}

// ChannelTest.InitShutdown ----------------------------------------------------

TEST_F(ChannelTest, InitShutdown) {
  PostMethodToIOThreadAndWait(&ChannelTest::CreateAndInitChannelOnIOThread, 0);
  PostMethodToIOThreadAndWait(&ChannelTest::ShutdownChannelOnIOThread, 0);

  // Okay to destroy |Channel| on not-the-I/O-thread.
  channel(0)->AssertHasOneRef();
  *mutable_channel(0) = nullptr;
}

// ChannelTest.CloseBeforeAttachAndRun -----------------------------------------

TEST_F(ChannelTest, CloseBeforeRun) {
  PostMethodToIOThreadAndWait(&ChannelTest::CreateAndInitChannelOnIOThread, 0);

  RefPtr<ChannelEndpoint> channel_endpoint;
  auto mp = MessagePipe::CreateLocalProxy(&channel_endpoint);

  mp->Close(0);

  channel(0)->SetBootstrapEndpoint(std::move(channel_endpoint));

  PostMethodToIOThreadAndWait(&ChannelTest::ShutdownChannelOnIOThread, 0);

  channel(0)->AssertHasOneRef();
}

// ChannelTest.ShutdownAfterAttachAndRun ---------------------------------------

TEST_F(ChannelTest, ShutdownAfterAttach) {
  PostMethodToIOThreadAndWait(&ChannelTest::CreateAndInitChannelOnIOThread, 0);

  RefPtr<ChannelEndpoint> channel_endpoint;
  auto mp = MessagePipe::CreateLocalProxy(&channel_endpoint);

  channel(0)->SetBootstrapEndpoint(std::move(channel_endpoint));

  Waiter waiter;
  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp->AddAwakable(0, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));

  // Don't wait for the shutdown to run ...
  PostMethodToIOThreadAndWait(&ChannelTest::ShutdownChannelOnIOThread, 0);

  // ... since this |Wait()| should fail once the channel is shut down.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            waiter.Wait(MOJO_DEADLINE_INDEFINITE, nullptr));
  HandleSignalsState hss;
  mp->RemoveAwakable(0, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  mp->Close(0);

  channel(0)->AssertHasOneRef();
}

// ChannelTest.WaitAfterAttachRunAndShutdown -----------------------------------

TEST_F(ChannelTest, WaitAfterAttachRunAndShutdown) {
  PostMethodToIOThreadAndWait(&ChannelTest::CreateAndInitChannelOnIOThread, 0);

  RefPtr<ChannelEndpoint> channel_endpoint;
  auto mp = MessagePipe::CreateLocalProxy(&channel_endpoint);

  channel(0)->SetBootstrapEndpoint(std::move(channel_endpoint));

  PostMethodToIOThreadAndWait(&ChannelTest::ShutdownChannelOnIOThread, 0);

  Waiter waiter;
  waiter.Init();
  HandleSignalsState hss;
  EXPECT_EQ(
      MOJO_RESULT_FAILED_PRECONDITION,
      mp->AddAwakable(0, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  mp->Close(0);

  channel(0)->AssertHasOneRef();
}

// ChannelTest.EndpointChannelShutdownRace -------------------------------------

TEST_F(ChannelTest, EndpointChannelShutdownRace) {
  const size_t kIterations = 1000;

  for (size_t i = 0; i < kIterations; i++) {
    // Need a new set of |RawChannel|s on every iteration.
    SetUp();
    PostMethodToIOThreadAndWait(&ChannelTest::CreateAndInitChannelOnIOThread,
                                0);

    RefPtr<ChannelEndpoint> channel_endpoint;
    auto mp = MessagePipe::CreateLocalProxy(&channel_endpoint);

    channel(0)->SetBootstrapEndpoint(std::move(channel_endpoint));

    io_thread()->PostTask(
        base::Bind(&ChannelTest::ShutdownAndReleaseChannelOnIOThread,
                   base::Unretained(this), 0));
    mp->Close(0);

    // Wait for the IO thread to finish shutting down the channel.
    io_thread()->PostTaskAndWait(base::Bind(&DoNothing));
    EXPECT_FALSE(channel(0));
  }
}

// TODO(vtl): More. ------------------------------------------------------------

}  // namespace
}  // namespace system
}  // namespace mojo
