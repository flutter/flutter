// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/endpoint_relayer.h"

#include "base/logging.h"
#include "mojo/edk/system/channel_endpoint_id.h"
#include "mojo/edk/system/channel_test_base.h"
#include "mojo/edk/system/message_in_transit_queue.h"
#include "mojo/edk/system/message_in_transit_test_utils.h"
#include "mojo/edk/system/test/timeouts.h"
#include "mojo/edk/system/test_channel_endpoint_client.h"
#include "mojo/edk/util/make_unique.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/waitable_event.h"
#include "mojo/public/cpp/system/macros.h"

using mojo::util::MakeRefCounted;
using mojo::util::MakeUnique;
using mojo::util::ManualResetWaitableEvent;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace {

class EndpointRelayerTest : public test::ChannelTestBase {
 public:
  EndpointRelayerTest() {}
  ~EndpointRelayerTest() override {}

  void SetUp() override {
    test::ChannelTestBase::SetUp();

    io_thread()->PostTaskAndWait([this]() {
      CreateAndInitChannelOnIOThread(0);
      CreateAndInitChannelOnIOThread(1);
    });

    // The set up:
    // * Across the pair of channels, we'll have a pair of connections (call
    //   them "a" and "b").
    // * On channel 0, we'll have a pair of endpoints ("0a" and "0b") hooked up
    //   to an |EndpointRelayer|.
    // * On channel 1, we'll have a pair of endpoints hooked up to test endpoint
    //   clients ("1a" and "1b").
    LocalChannelEndpointIdGenerator id_generator;
    ChannelEndpointId ida = id_generator.GetNext();
    ChannelEndpointId idb = id_generator.GetNext();

    relayer_ = MakeRefCounted<EndpointRelayer>();
    endpoint0a_ = MakeRefCounted<ChannelEndpoint>(relayer_.Clone(), 0);
    endpoint0b_ = MakeRefCounted<ChannelEndpoint>(relayer_.Clone(), 1);
    relayer_->Init(endpoint0a_.Clone(), endpoint0b_.Clone());
    channel(0)->SetBootstrapEndpointWithIds(endpoint0a_.Clone(), ida, ida);
    channel(0)->SetBootstrapEndpointWithIds(endpoint0b_.Clone(), idb, idb);

    client1a_ = MakeRefCounted<test::TestChannelEndpointClient>();
    client1b_ = MakeRefCounted<test::TestChannelEndpointClient>();
    endpoint1a_ = MakeRefCounted<ChannelEndpoint>(client1a_.Clone(), 0);
    endpoint1b_ = MakeRefCounted<ChannelEndpoint>(client1b_.Clone(), 0);
    client1a_->Init(0, endpoint1a_.Clone());
    client1b_->Init(0, endpoint1b_.Clone());
    channel(1)->SetBootstrapEndpointWithIds(endpoint1a_.Clone(), ida, ida);
    channel(1)->SetBootstrapEndpointWithIds(endpoint1b_.Clone(), idb, idb);
  }

  void TearDown() override {
    io_thread()->PostTaskAndWait([this]() {
      ShutdownChannelOnIOThread(0);
      ShutdownChannelOnIOThread(1);
    });

    test::ChannelTestBase::TearDown();
  }

 protected:
  EndpointRelayer* relayer() { return relayer_.get(); }
  test::TestChannelEndpointClient* client1a() { return client1a_.get(); }
  test::TestChannelEndpointClient* client1b() { return client1b_.get(); }
  ChannelEndpoint* endpoint1a() { return endpoint1a_.get(); }
  ChannelEndpoint* endpoint1b() { return endpoint1b_.get(); }

 private:
  RefPtr<EndpointRelayer> relayer_;
  RefPtr<ChannelEndpoint> endpoint0a_;
  RefPtr<ChannelEndpoint> endpoint0b_;
  RefPtr<test::TestChannelEndpointClient> client1a_;
  RefPtr<test::TestChannelEndpointClient> client1b_;
  RefPtr<ChannelEndpoint> endpoint1a_;
  RefPtr<ChannelEndpoint> endpoint1b_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(EndpointRelayerTest);
};

TEST_F(EndpointRelayerTest, Basic) {
  ManualResetWaitableEvent read_event;
  client1b()->SetReadEvent(&read_event);
  EXPECT_EQ(0u, client1b()->NumMessages());

  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(12345)));

  EXPECT_FALSE(read_event.WaitWithTimeout(test::TinyTimeout()));
  client1b()->SetReadEvent(nullptr);

  ASSERT_EQ(1u, client1b()->NumMessages());
  std::unique_ptr<MessageInTransit> read_message = client1b()->PopMessage();
  ASSERT_TRUE(read_message);
  test::VerifyTestMessage(read_message.get(), 12345);

  // Now do the same thing in the opposite direction.
  read_event.Reset();
  client1a()->SetReadEvent(&read_event);
  EXPECT_EQ(0u, client1a()->NumMessages());

  EXPECT_TRUE(endpoint1b()->EnqueueMessage(test::MakeTestMessage(67890)));

  EXPECT_FALSE(read_event.WaitWithTimeout(test::TinyTimeout()));
  client1a()->SetReadEvent(nullptr);

  ASSERT_EQ(1u, client1a()->NumMessages());
  read_message = client1a()->PopMessage();
  ASSERT_TRUE(read_message);
  test::VerifyTestMessage(read_message.get(), 67890);
}

TEST_F(EndpointRelayerTest, MultipleMessages) {
  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(1)));
  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(2)));
  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(3)));
  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(4)));
  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(5)));

  ManualResetWaitableEvent read_event;
  client1b()->SetReadEvent(&read_event);
  for (size_t i = 0; client1b()->NumMessages() < 5 && i < 5; i++) {
    EXPECT_FALSE(read_event.WaitWithTimeout(test::TinyTimeout()));
    read_event.Reset();
  }
  client1b()->SetReadEvent(nullptr);

  // Check the received messages.
  ASSERT_EQ(5u, client1b()->NumMessages());
  for (unsigned message_id = 1; message_id <= 5; message_id++) {
    std::unique_ptr<MessageInTransit> read_message = client1b()->PopMessage();
    ASSERT_TRUE(read_message);
    test::VerifyTestMessage(read_message.get(), message_id);
  }
}

// A simple test filter. It will filter test messages made with
// |test::MakeTestMessage()| with |id >= 1000|, and not filter other messages.
class TestFilter : public EndpointRelayer::Filter {
 public:
  // |filtered_messages| will receive (and own) filtered messages; it will be
  // accessed under the owning |EndpointRelayer|'s lock, and must outlive this
  // filter.
  //
  // (Outside this class, you should only access |filtered_messages| once this
  // filter is no longer the |EndpointRelayer|'s filter.)
  explicit TestFilter(MessageInTransitQueue* filtered_messages)
      : filtered_messages_(filtered_messages) {
    CHECK(filtered_messages_);
  }

  ~TestFilter() override {}

  // Note: Recall that this is called under the |EndpointRelayer|'s lock.
  bool OnReadMessage(ChannelEndpoint* endpoint,
                     ChannelEndpoint* peer_endpoint,
                     MessageInTransit* message) override {
    CHECK(endpoint);
    CHECK(peer_endpoint);
    CHECK(message);

    unsigned id = 0;
    if (test::IsTestMessage(message, &id) && id >= 1000) {
      filtered_messages_->AddMessage(
          std::unique_ptr<MessageInTransit>(message));
      return true;
    }

    return false;
  }

 private:
  MessageInTransitQueue* const filtered_messages_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestFilter);
};

TEST_F(EndpointRelayerTest, Filter) {
  MessageInTransitQueue filtered_messages;
  relayer()->SetFilter(MakeUnique<TestFilter>(&filtered_messages));

  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(1)));
  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(2)));
  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(1001)));
  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(3)));
  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(4)));
  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(1002)));
  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(1003)));
  EXPECT_TRUE(endpoint1a()->EnqueueMessage(test::MakeTestMessage(5)));

  ManualResetWaitableEvent read_event;
  client1b()->SetReadEvent(&read_event);
  for (size_t i = 0; client1b()->NumMessages() < 5 && i < 5; i++) {
    EXPECT_FALSE(read_event.WaitWithTimeout(test::TinyTimeout()));
    read_event.Reset();
  }
  client1b()->SetReadEvent(nullptr);

  // Check the received messages: We should get "1"-"5".
  ASSERT_EQ(5u, client1b()->NumMessages());
  for (unsigned message_id = 1; message_id <= 5; message_id++) {
    std::unique_ptr<MessageInTransit> read_message = client1b()->PopMessage();
    ASSERT_TRUE(read_message);
    test::VerifyTestMessage(read_message.get(), message_id);
  }

  // Reset the filter, so we can safely examine |filtered_messages|.
  relayer()->SetFilter(nullptr);

  // Note that since "5" was sent after "1003" and it the former was received,
  // the latter must have also been "received"/filtered.
  ASSERT_EQ(3u, filtered_messages.Size());
  for (unsigned message_id = 1001; message_id <= 1003; message_id++) {
    std::unique_ptr<MessageInTransit> message = filtered_messages.GetMessage();
    ASSERT_TRUE(message);
    test::VerifyTestMessage(message.get(), message_id);
  }
}

// TODO(vtl): Add some "shutdown" tests.

}  // namespace
}  // namespace system
}  // namespace mojo
