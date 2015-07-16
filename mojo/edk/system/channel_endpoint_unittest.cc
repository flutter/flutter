// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/channel_endpoint.h"

#include "base/synchronization/waitable_event.h"
#include "base/test/test_timeouts.h"
#include "mojo/edk/system/channel_test_base.h"
#include "mojo/edk/system/message_in_transit_queue.h"
#include "mojo/edk/system/message_in_transit_test_utils.h"
#include "mojo/edk/system/test_channel_endpoint_client.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {
namespace {

class ChannelEndpointTest : public test::ChannelTestBase {
 public:
  ChannelEndpointTest() {}
  ~ChannelEndpointTest() override {}

  void SetUp() override {
    test::ChannelTestBase::SetUp();

    PostMethodToIOThreadAndWait(
        FROM_HERE, &ChannelEndpointTest::CreateAndInitChannelOnIOThread, 0);
    PostMethodToIOThreadAndWait(
        FROM_HERE, &ChannelEndpointTest::CreateAndInitChannelOnIOThread, 1);
  }

  void TearDown() override {
    PostMethodToIOThreadAndWait(
        FROM_HERE, &ChannelEndpointTest::ShutdownChannelOnIOThread, 0);
    PostMethodToIOThreadAndWait(
        FROM_HERE, &ChannelEndpointTest::ShutdownChannelOnIOThread, 1);

    test::ChannelTestBase::TearDown();
  }

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(ChannelEndpointTest);
};

TEST_F(ChannelEndpointTest, Basic) {
  scoped_refptr<test::TestChannelEndpointClient> client0(
      new test::TestChannelEndpointClient());
  scoped_refptr<ChannelEndpoint> endpoint0(
      new ChannelEndpoint(client0.get(), 0));
  client0->Init(0, endpoint0.get());
  channel(0)->SetBootstrapEndpoint(endpoint0);

  scoped_refptr<test::TestChannelEndpointClient> client1(
      new test::TestChannelEndpointClient());
  scoped_refptr<ChannelEndpoint> endpoint1(
      new ChannelEndpoint(client1.get(), 1));
  client1->Init(1, endpoint1.get());
  channel(1)->SetBootstrapEndpoint(endpoint1);

  // We'll receive a message on channel/client 0.
  base::WaitableEvent read_event(true, false);
  client0->SetReadEvent(&read_event);

  // Make a test message.
  unsigned message_id = 0x12345678;
  scoped_ptr<MessageInTransit> send_message = test::MakeTestMessage(message_id);
  // Check that our test utility works (at least in one direction).
  test::VerifyTestMessage(send_message.get(), message_id);

  // Event shouldn't be signalled yet.
  EXPECT_FALSE(read_event.IsSignaled());

  // Send it through channel/endpoint 1.
  EXPECT_TRUE(endpoint1->EnqueueMessage(send_message.Pass()));

  // Wait to receive it.
  EXPECT_TRUE(read_event.TimedWait(TestTimeouts::tiny_timeout()));
  client0->SetReadEvent(nullptr);

  // Check the received message.
  ASSERT_EQ(1u, client0->NumMessages());
  scoped_ptr<MessageInTransit> read_message = client0->PopMessage();
  ASSERT_TRUE(read_message);
  test::VerifyTestMessage(read_message.get(), message_id);
}

// Checks that prequeued messages and messages sent at various stages later on
// are all sent/received (and in the correct order). (Note: Due to the way
// bootstrap endpoints work, the receiving side has to be set up first.)
TEST_F(ChannelEndpointTest, Prequeued) {
  scoped_refptr<test::TestChannelEndpointClient> client0(
      new test::TestChannelEndpointClient());
  scoped_refptr<ChannelEndpoint> endpoint0(
      new ChannelEndpoint(client0.get(), 0));
  client0->Init(0, endpoint0.get());

  channel(0)->SetBootstrapEndpoint(endpoint0);
  MessageInTransitQueue prequeued_messages;
  prequeued_messages.AddMessage(test::MakeTestMessage(1));
  prequeued_messages.AddMessage(test::MakeTestMessage(2));

  scoped_refptr<test::TestChannelEndpointClient> client1(
      new test::TestChannelEndpointClient());
  scoped_refptr<ChannelEndpoint> endpoint1(
      new ChannelEndpoint(client1.get(), 1, &prequeued_messages));
  client1->Init(1, endpoint1.get());

  EXPECT_TRUE(endpoint1->EnqueueMessage(test::MakeTestMessage(3)));
  EXPECT_TRUE(endpoint1->EnqueueMessage(test::MakeTestMessage(4)));

  channel(1)->SetBootstrapEndpoint(endpoint1);

  EXPECT_TRUE(endpoint1->EnqueueMessage(test::MakeTestMessage(5)));
  EXPECT_TRUE(endpoint1->EnqueueMessage(test::MakeTestMessage(6)));

  // Wait for the messages.
  base::WaitableEvent read_event(true, false);
  client0->SetReadEvent(&read_event);
  for (size_t i = 0; client0->NumMessages() < 6 && i < 6; i++) {
    EXPECT_TRUE(read_event.TimedWait(TestTimeouts::tiny_timeout()));
    read_event.Reset();
  }
  client0->SetReadEvent(nullptr);

  // Check the received messages.
  ASSERT_EQ(6u, client0->NumMessages());
  for (unsigned message_id = 1; message_id <= 6; message_id++) {
    scoped_ptr<MessageInTransit> read_message = client0->PopMessage();
    ASSERT_TRUE(read_message);
    test::VerifyTestMessage(read_message.get(), message_id);
  }
}

}  // namespace
}  // namespace system
}  // namespace mojo
