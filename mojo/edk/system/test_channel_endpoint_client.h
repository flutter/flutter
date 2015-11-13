// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_TEST_CHANNEL_ENDPOINT_CLIENT_H_
#define MOJO_EDK_SYSTEM_TEST_CHANNEL_ENDPOINT_CLIENT_H_

#include <memory>

#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/channel_endpoint_client.h"
#include "mojo/edk/system/message_in_transit_queue.h"
#include "mojo/edk/util/mutex.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {

namespace util {
class ManualResetWaitableEvent;
}

namespace system {
namespace test {

class TestChannelEndpointClient final : public ChannelEndpointClient {
 public:
  // Note: Use |util::MakeRefCounted<TestChannelEndpointClient>()|.

  // Initializes with the given port and endpoint.
  void Init(unsigned port, util::RefPtr<ChannelEndpoint>&& endpoint);

  // Returns true if we're detached from the |ChannelEndpoint|.
  bool IsDetached() const;

  // Gets the current number of messages received (but not dequeued).
  size_t NumMessages() const;

  // Gets/removes a message that was received (|NumMessages()| must be
  // non-zero), in FIFO order.
  std::unique_ptr<MessageInTransit> PopMessage();

  // Sets an event to signal when we receive a message. (|read_event| must live
  // until this object is destroyed or the read event is reset to null.)
  void SetReadEvent(util::ManualResetWaitableEvent* read_event);

  // |ChannelEndpointClient| implementation:
  bool OnReadMessage(unsigned port, MessageInTransit* message) override;
  void OnDetachFromChannel(unsigned port) override;

 private:
  FRIEND_MAKE_REF_COUNTED(TestChannelEndpointClient);

  TestChannelEndpointClient();
  ~TestChannelEndpointClient() override;

  mutable util::Mutex mutex_;

  unsigned port_ MOJO_GUARDED_BY(mutex_);
  util::RefPtr<ChannelEndpoint> endpoint_ MOJO_GUARDED_BY(mutex_);

  MessageInTransitQueue messages_ MOJO_GUARDED_BY(mutex_);

  // Event to trigger if we read a message (may be null).
  util::ManualResetWaitableEvent* read_event_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestChannelEndpointClient);
};

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_TEST_CHANNEL_ENDPOINT_CLIENT_H_
