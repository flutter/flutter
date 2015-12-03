// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/channel_endpoint.h"

#include <memory>
#include <utility>

#include "mojo/edk/system/channel_test_base.h"
#include "mojo/edk/system/message_in_transit_queue.h"
#include "mojo/edk/system/message_in_transit_test_utils.h"
#include "mojo/edk/system/test/timeouts.h"
#include "mojo/edk/system/test_channel_endpoint_client.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/waitable_event.h"
#include "mojo/public/cpp/system/macros.h"

using mojo::util::MakeRefCounted;
using mojo::util::ManualResetWaitableEvent;

namespace mojo {
namespace system {
namespace {

class ChannelEndpointTest : public test::ChannelTestBase {
 public:
  ChannelEndpointTest() {}
  ~ChannelEndpointTest() override {}

  void SetUp() override {
    test::ChannelTestBase::SetUp();

    io_thread()->PostTaskAndWait([this]() {
      CreateAndInitChannelOnIOThread(0);
      CreateAndInitChannelOnIOThread(1);
    });
  }

  void TearDown() override {
    io_thread()->PostTaskAndWait([this]() {
      ShutdownChannelOnIOThread(0);
      ShutdownChannelOnIOThread(1);
    });

    test::ChannelTestBase::TearDown();
  }

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(ChannelEndpointTest);
};

TEST_F(ChannelEndpointTest, Basic) {
  auto client0 = MakeRefCounted<test::TestChannelEndpointClient>();
  auto endpoint0 = MakeRefCounted<ChannelEndpoint>(client0.Clone(), 0);
  client0->Init(0, endpoint0.Clone());
  channel(0)->SetBootstrapEndpoint(std::move(endpoint0));

  auto client1 = MakeRefCounted<test::TestChannelEndpointClient>();
  auto endpoint1 = MakeRefCounted<ChannelEndpoint>(client1.Clone(), 1);
  client1->Init(1, endpoint1.Clone());
  channel(1)->SetBootstrapEndpoint(endpoint1.Clone());

  // We'll receive a message on channel/client 0.
  ManualResetWaitableEvent read_event;
  client0->SetReadEvent(&read_event);

  // Make a test message.
  unsigned message_id = 0x12345678;
  std::unique_ptr<MessageInTransit> send_message =
      test::MakeTestMessage(message_id);
  // Check that our test utility works (at least in one direction).
  test::VerifyTestMessage(send_message.get(), message_id);

  // Event shouldn't be signaled yet.
  EXPECT_FALSE(read_event.IsSignaledForTest());

  // Send it through channel/endpoint 1.
  EXPECT_TRUE(endpoint1->EnqueueMessage(std::move(send_message)));

  // Wait to receive it.
  EXPECT_FALSE(read_event.WaitWithTimeout(test::TinyTimeout()));
  client0->SetReadEvent(nullptr);

  // Check the received message.
  ASSERT_EQ(1u, client0->NumMessages());
  std::unique_ptr<MessageInTransit> read_message = client0->PopMessage();
  ASSERT_TRUE(read_message);
  test::VerifyTestMessage(read_message.get(), message_id);
}

// Checks that prequeued messages and messages sent at various stages later on
// are all sent/received (and in the correct order). (Note: Due to the way
// bootstrap endpoints work, the receiving side has to be set up first.)
TEST_F(ChannelEndpointTest, Prequeued) {
  auto client0 = MakeRefCounted<test::TestChannelEndpointClient>();
  auto endpoint0 = MakeRefCounted<ChannelEndpoint>(client0.Clone(), 0);
  client0->Init(0, endpoint0.Clone());

  channel(0)->SetBootstrapEndpoint(std::move(endpoint0));
  MessageInTransitQueue prequeued_messages;
  prequeued_messages.AddMessage(test::MakeTestMessage(1));
  prequeued_messages.AddMessage(test::MakeTestMessage(2));

  auto client1 = MakeRefCounted<test::TestChannelEndpointClient>();
  auto endpoint1 =
      MakeRefCounted<ChannelEndpoint>(client1.Clone(), 1, &prequeued_messages);
  client1->Init(1, endpoint1.Clone());

  EXPECT_TRUE(endpoint1->EnqueueMessage(test::MakeTestMessage(3)));
  EXPECT_TRUE(endpoint1->EnqueueMessage(test::MakeTestMessage(4)));

  channel(1)->SetBootstrapEndpoint(endpoint1.Clone());

  EXPECT_TRUE(endpoint1->EnqueueMessage(test::MakeTestMessage(5)));
  EXPECT_TRUE(endpoint1->EnqueueMessage(test::MakeTestMessage(6)));

  // Wait for the messages.
  ManualResetWaitableEvent read_event;
  client0->SetReadEvent(&read_event);
  for (size_t i = 0; client0->NumMessages() < 6 && i < 6; i++) {
    EXPECT_FALSE(read_event.WaitWithTimeout(test::TinyTimeout()));
    read_event.Reset();
  }
  client0->SetReadEvent(nullptr);

  // Check the received messages.
  ASSERT_EQ(6u, client0->NumMessages());
  for (unsigned message_id = 1; message_id <= 6; message_id++) {
    std::unique_ptr<MessageInTransit> read_message = client0->PopMessage();
    ASSERT_TRUE(read_message);
    test::VerifyTestMessage(read_message.get(), message_id);
  }
}

}  // namespace
}  // namespace system
}  // namespace mojo
