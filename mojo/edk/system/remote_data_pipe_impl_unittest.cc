// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file tests both |RemoteProducerDataPipeImpl| and
// |RemoteConsumerDataPipeImpl|.

#include <stdint.h>

#include "base/bind.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "base/test/test_io_thread.h"
#include "mojo/edk/embedder/platform_channel_pair.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/data_pipe.h"
#include "mojo/edk/system/data_pipe_consumer_dispatcher.h"
#include "mojo/edk/system/data_pipe_producer_dispatcher.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/raw_channel.h"
#include "mojo/edk/system/test_utils.h"
#include "mojo/edk/system/waiter.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace {

const MojoHandleSignals kAllSignals = MOJO_HANDLE_SIGNAL_READABLE |
                                      MOJO_HANDLE_SIGNAL_WRITABLE |
                                      MOJO_HANDLE_SIGNAL_PEER_CLOSED;

class RemoteDataPipeImplTest : public testing::Test {
 public:
  RemoteDataPipeImplTest() : io_thread_(base::TestIOThread::kAutoStart) {}
  ~RemoteDataPipeImplTest() override {}

  void SetUp() override {
    scoped_refptr<ChannelEndpoint> ep[2];
    message_pipes_[0] = MessagePipe::CreateLocalProxy(&ep[0]);
    message_pipes_[1] = MessagePipe::CreateLocalProxy(&ep[1]);

    io_thread_.PostTaskAndWait(
        FROM_HERE, base::Bind(&RemoteDataPipeImplTest::SetUpOnIOThread,
                              base::Unretained(this), ep[0], ep[1]));
  }

  void TearDown() override {
    EnsureMessagePipeClosed(0);
    EnsureMessagePipeClosed(1);
    io_thread_.PostTaskAndWait(
        FROM_HERE, base::Bind(&RemoteDataPipeImplTest::TearDownOnIOThread,
                              base::Unretained(this)));
  }

 protected:
  static DataPipe* CreateLocal(size_t element_size, size_t num_elements) {
    const MojoCreateDataPipeOptions options = {
        static_cast<uint32_t>(sizeof(MojoCreateDataPipeOptions)),
        MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,
        static_cast<uint32_t>(element_size),
        static_cast<uint32_t>(num_elements * element_size)};
    MojoCreateDataPipeOptions validated_options = {};
    CHECK_EQ(DataPipe::ValidateCreateOptions(MakeUserPointer(&options),
                                             &validated_options),
             MOJO_RESULT_OK);
    return DataPipe::CreateLocal(validated_options);
  }

  scoped_refptr<MessagePipe> message_pipe(size_t i) {
    return message_pipes_[i];
  }

  void EnsureMessagePipeClosed(size_t i) {
    if (!message_pipes_[i])
      return;
    message_pipes_[i]->Close(0);
    message_pipes_[i] = nullptr;
  }

 private:
  void SetUpOnIOThread(scoped_refptr<ChannelEndpoint> ep0,
                       scoped_refptr<ChannelEndpoint> ep1) {
    CHECK_EQ(base::MessageLoop::current(), io_thread_.message_loop());

    embedder::PlatformChannelPair channel_pair;
    channels_[0] = new Channel(&platform_support_);
    channels_[0]->Init(RawChannel::Create(channel_pair.PassServerHandle()));
    channels_[0]->SetBootstrapEndpoint(ep0);
    channels_[1] = new Channel(&platform_support_);
    channels_[1]->Init(RawChannel::Create(channel_pair.PassClientHandle()));
    channels_[1]->SetBootstrapEndpoint(ep1);
  }

  void TearDownOnIOThread() {
    CHECK_EQ(base::MessageLoop::current(), io_thread_.message_loop());

    if (channels_[0]) {
      channels_[0]->Shutdown();
      channels_[0] = nullptr;
    }
    if (channels_[1]) {
      channels_[1]->Shutdown();
      channels_[1] = nullptr;
    }
  }

  embedder::SimplePlatformSupport platform_support_;
  base::TestIOThread io_thread_;
  scoped_refptr<Channel> channels_[2];
  scoped_refptr<MessagePipe> message_pipes_[2];

  MOJO_DISALLOW_COPY_AND_ASSIGN(RemoteDataPipeImplTest);
};

// These tests are heavier-weight than ideal. They test remote data pipes by
// passing data pipe (producer/consumer) dispatchers over remote message pipes.
// Make sure that the test fixture works properly (i.e., that the message pipe
// works properly, and that things are shut down correctly).
// TODO(vtl): Make lighter-weight tests. Ideally, we'd have tests for remote
// data pipes which don't involve message pipes (or even data pipe dispatchers).
TEST_F(RemoteDataPipeImplTest, Sanity) {
  static const char kHello[] = "hello";
  char read_buffer[100] = {};
  uint32_t read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  Waiter waiter;
  HandleSignalsState hss;
  uint32_t context = 0;

  // Write on MP 0 (port 0). Wait and receive on MP 1 (port 0). (Add the waiter
  // first, to avoid any handling the case where it's already readable.)
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            message_pipe(1)->AddAwakable(
                0, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));
  EXPECT_EQ(MOJO_RESULT_OK,
            message_pipe(0)->WriteMessage(0, UserPointer<const void>(kHello),
                                          sizeof(kHello), nullptr,
                                          MOJO_WRITE_MESSAGE_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::ActionDeadline(), &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  message_pipe(1)->RemoveAwakable(0, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  EXPECT_EQ(MOJO_RESULT_OK, message_pipe(1)->ReadMessage(
                                0, UserPointer<void>(read_buffer),
                                MakeUserPointer(&read_buffer_size), nullptr,
                                nullptr, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kHello, read_buffer);
}

// TODO(vtl): This test doesn't have an obvious analogue in
// |LocalDataPipeImplTest|.
TEST_F(RemoteDataPipeImplTest, SendConsumerWithClosedProducer) {
  char read_buffer[100] = {};
  uint32_t read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  DispatcherVector read_dispatchers;
  uint32_t read_num_dispatchers = 10;  // Maximum to get.
  Waiter waiter;
  HandleSignalsState hss;
  uint32_t context = 0;

  scoped_refptr<DataPipe> dp(CreateLocal(sizeof(int32_t), 1000));
  // This is the consumer dispatcher we'll send.
  scoped_refptr<DataPipeConsumerDispatcher> consumer =
      DataPipeConsumerDispatcher::Create();
  consumer->Init(dp);

  // Write to the producer and close it, before sending the consumer.
  int32_t elements[10] = {123};
  uint32_t num_bytes = static_cast<uint32_t>(1u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK,
            dp->ProducerWriteData(UserPointer<const void>(elements),
                                  MakeUserPointer(&num_bytes), false));
  EXPECT_EQ(1u * sizeof(elements[0]), num_bytes);
  dp->ProducerClose();

  // Write the consumer to MP 0 (port 0). Wait and receive on MP 1 (port 0).
  // (Add the waiter first, to avoid any handling the case where it's already
  // readable.)
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            message_pipe(1)->AddAwakable(
                0, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));
  {
    DispatcherTransport transport(
        test::DispatcherTryStartTransport(consumer.get()));
    EXPECT_TRUE(transport.is_valid());

    std::vector<DispatcherTransport> transports;
    transports.push_back(transport);
    EXPECT_EQ(MOJO_RESULT_OK, message_pipe(0)->WriteMessage(
                                  0, NullUserPointer(), 0, &transports,
                                  MOJO_WRITE_MESSAGE_FLAG_NONE));
    transport.End();

    // |consumer| should have been closed. This is |DCHECK()|ed when it is
    // destroyed.
    EXPECT_TRUE(consumer->HasOneRef());
    consumer = nullptr;
  }
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::ActionDeadline(), &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  message_pipe(1)->RemoveAwakable(0, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  EXPECT_EQ(MOJO_RESULT_OK,
            message_pipe(1)->ReadMessage(
                0, UserPointer<void>(read_buffer),
                MakeUserPointer(&read_buffer_size), &read_dispatchers,
                &read_num_dispatchers, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(0u, static_cast<size_t>(read_buffer_size));
  EXPECT_EQ(1u, read_dispatchers.size());
  EXPECT_EQ(1u, read_num_dispatchers);
  ASSERT_TRUE(read_dispatchers[0]);
  EXPECT_TRUE(read_dispatchers[0]->HasOneRef());

  EXPECT_EQ(Dispatcher::Type::DATA_PIPE_CONSUMER,
            read_dispatchers[0]->GetType());
  consumer =
      static_cast<DataPipeConsumerDispatcher*>(read_dispatchers[0].get());
  read_dispatchers.clear();

  waiter.Init();
  hss = HandleSignalsState();
  MojoResult result =
      consumer->AddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE, 456, &hss);
  if (result == MOJO_RESULT_OK) {
    context = 0;
    EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(test::ActionDeadline(), &context));
    EXPECT_EQ(456u, context);
    consumer->RemoveAwakable(&waiter, &hss);
  } else {
    ASSERT_EQ(MOJO_RESULT_ALREADY_EXISTS, result);
  }
  // We don't know if the fact that the producer has been closed is known yet.
  EXPECT_TRUE((hss.satisfied_signals & MOJO_HANDLE_SIGNAL_READABLE));
  EXPECT_TRUE((hss.satisfiable_signals & MOJO_HANDLE_SIGNAL_READABLE));

  // Read one element.
  elements[0] = -1;
  elements[1] = -1;
  num_bytes = static_cast<uint32_t>(1u * sizeof(elements[0]));
  EXPECT_EQ(MOJO_RESULT_OK, consumer->ReadData(UserPointer<void>(elements),
                                               MakeUserPointer(&num_bytes),
                                               MOJO_READ_DATA_FLAG_NONE));
  EXPECT_EQ(1u * sizeof(elements[0]), num_bytes);
  EXPECT_EQ(123, elements[0]);
  EXPECT_EQ(-1, elements[1]);

  waiter.Init();
  hss = HandleSignalsState();
  result =
      consumer->AddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE, 789, &hss);
  if (result == MOJO_RESULT_OK) {
    context = 0;
    EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
              waiter.Wait(test::ActionDeadline(), &context));
    EXPECT_EQ(789u, context);
    consumer->RemoveAwakable(&waiter, &hss);
  } else {
    ASSERT_EQ(MOJO_RESULT_FAILED_PRECONDITION, result);
  }
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  consumer->Close();
}

}  // namespace
}  // namespace system
}  // namespace mojo
