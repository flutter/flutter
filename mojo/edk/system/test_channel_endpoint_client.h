// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_TEST_CHANNEL_ENDPOINT_CLIENT_H_
#define MOJO_EDK_SYSTEM_TEST_CHANNEL_ENDPOINT_CLIENT_H_

#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/channel_endpoint_client.h"
#include "mojo/edk/system/message_in_transit_queue.h"
#include "mojo/edk/system/mutex.h"
#include "mojo/public/cpp/system/macros.h"

namespace base {
class WaitableEvent;
}

namespace mojo {
namespace system {
namespace test {

class TestChannelEndpointClient final : public ChannelEndpointClient {
 public:
  TestChannelEndpointClient();

  // Initializes with the given port and endpoint.
  void Init(unsigned port, ChannelEndpoint* endpoint);

  // Returns true if we're detached from the |ChannelEndpoint|.
  bool IsDetached() const;

  // Gets the current number of messages received (but not dequeued).
  size_t NumMessages() const;

  // Gets/removes a message that was received (|NumMessages()| must be
  // non-zero), in FIFO order.
  scoped_ptr<MessageInTransit> PopMessage();

  // Sets an event to signal when we receive a message. (|read_event| must live
  // until this object is destroyed or the read event is reset to null.)
  void SetReadEvent(base::WaitableEvent* read_event);

  // |ChannelEndpointClient| implementation:
  bool OnReadMessage(unsigned port, MessageInTransit* message) override;
  void OnDetachFromChannel(unsigned port) override;

 private:
  ~TestChannelEndpointClient() override;

  mutable Mutex mutex_;

  unsigned port_ MOJO_GUARDED_BY(mutex_);
  scoped_refptr<ChannelEndpoint> endpoint_ MOJO_GUARDED_BY(mutex_);

  MessageInTransitQueue messages_ MOJO_GUARDED_BY(mutex_);

  // Event to trigger if we read a message (may be null).
  base::WaitableEvent* read_event_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestChannelEndpointClient);
};

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_TEST_CHANNEL_ENDPOINT_CLIENT_H_
