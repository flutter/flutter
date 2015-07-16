// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test_channel_endpoint_client.h"

#include "base/synchronization/waitable_event.h"
#include "mojo/edk/system/message_in_transit.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace test {

TestChannelEndpointClient::TestChannelEndpointClient()
    : port_(0), read_event_(nullptr) {
}

void TestChannelEndpointClient::Init(unsigned port, ChannelEndpoint* endpoint) {
  MutexLocker locker(&mutex_);
  ASSERT_EQ(0u, port_);
  ASSERT_FALSE(endpoint_);
  port_ = port;
  endpoint_ = endpoint;
}

bool TestChannelEndpointClient::IsDetached() const {
  MutexLocker locker(&mutex_);
  return !endpoint_;
}

size_t TestChannelEndpointClient::NumMessages() const {
  MutexLocker locker(&mutex_);
  return messages_.Size();
}

scoped_ptr<MessageInTransit> TestChannelEndpointClient::PopMessage() {
  MutexLocker locker(&mutex_);
  if (messages_.IsEmpty())
    return nullptr;
  return messages_.GetMessage();
}

void TestChannelEndpointClient::SetReadEvent(base::WaitableEvent* read_event) {
  MutexLocker locker(&mutex_);
  read_event_ = read_event;
}

bool TestChannelEndpointClient::OnReadMessage(unsigned port,
                                              MessageInTransit* message) {
  MutexLocker locker(&mutex_);

  EXPECT_EQ(port_, port);
  EXPECT_TRUE(endpoint_);
  messages_.AddMessage(make_scoped_ptr(message));

  if (read_event_)
    read_event_->Signal();

  return true;
}

void TestChannelEndpointClient::OnDetachFromChannel(unsigned port) {
  MutexLocker locker(&mutex_);

  EXPECT_EQ(port_, port);
  ASSERT_TRUE(endpoint_);
  endpoint_->DetachFromClient();
  endpoint_ = nullptr;
}

TestChannelEndpointClient::~TestChannelEndpointClient() {
  EXPECT_FALSE(endpoint_);
}

}  // namespace test
}  // namespace system
}  // namespace mojo
