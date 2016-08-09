// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_INCOMING_ENDPOINT_H_
#define MOJO_EDK_SYSTEM_INCOMING_ENDPOINT_H_

#include <stddef.h>

#include "mojo/edk/system/channel_endpoint_client.h"
#include "mojo/edk/system/message_in_transit_queue.h"
#include "mojo/edk/util/mutex.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/cpp/system/macros.h"

struct MojoCreateDataPipeOptions;

namespace mojo {
namespace system {

class ChannelEndpoint;
class DataPipe;
class MessagePipe;

// This is a simple |ChannelEndpointClient| that only receives messages. It's
// used for endpoints that are "received" by |Channel|, but not yet turned into
// |MessagePipe|s or |DataPipe|s.
class IncomingEndpoint final : public ChannelEndpointClient {
 public:
  // Note: Use |util::MakeRefCounted<IncomingEndpoint>()|.

  // Must be called before any other method.
  util::RefPtr<ChannelEndpoint> Init() MOJO_NOT_THREAD_SAFE;

  util::RefPtr<MessagePipe> ConvertToMessagePipe();
  util::RefPtr<DataPipe> ConvertToDataPipeProducer(
      const MojoCreateDataPipeOptions& validated_options,
      size_t consumer_num_bytes);
  util::RefPtr<DataPipe> ConvertToDataPipeConsumer(
      const MojoCreateDataPipeOptions& validated_options);

  // Must be called before destroying this object if |ConvertToMessagePipe()|
  // wasn't called (but |Init()| was).
  void Close();

  // |ChannelEndpointClient| methods:
  bool OnReadMessage(unsigned port, MessageInTransit* message) override;
  void OnDetachFromChannel(unsigned port) override;

 private:
  FRIEND_MAKE_REF_COUNTED(IncomingEndpoint);

  IncomingEndpoint();
  ~IncomingEndpoint() override;

  util::Mutex mutex_;
  util::RefPtr<ChannelEndpoint> endpoint_ MOJO_GUARDED_BY(mutex_);
  MessageInTransitQueue message_queue_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(IncomingEndpoint);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_INCOMING_ENDPOINT_H_
