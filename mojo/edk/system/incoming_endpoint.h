// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_INCOMING_ENDPOINT_H_
#define MOJO_EDK_SYSTEM_INCOMING_ENDPOINT_H_

#include <stddef.h>

#include "base/memory/ref_counted.h"
#include "mojo/edk/system/channel_endpoint_client.h"
#include "mojo/edk/system/message_in_transit_queue.h"
#include "mojo/edk/system/mutex.h"
#include "mojo/edk/system/system_impl_export.h"
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
class MOJO_SYSTEM_IMPL_EXPORT IncomingEndpoint final
    : public ChannelEndpointClient {
 public:
  IncomingEndpoint();

  // Must be called before any other method.
  scoped_refptr<ChannelEndpoint> Init() MOJO_NOT_THREAD_SAFE;

  scoped_refptr<MessagePipe> ConvertToMessagePipe();
  scoped_refptr<DataPipe> ConvertToDataPipeProducer(
      const MojoCreateDataPipeOptions& validated_options,
      size_t consumer_num_bytes);
  scoped_refptr<DataPipe> ConvertToDataPipeConsumer(
      const MojoCreateDataPipeOptions& validated_options);

  // Must be called before destroying this object if |ConvertToMessagePipe()|
  // wasn't called (but |Init()| was).
  void Close();

  // |ChannelEndpointClient| methods:
  bool OnReadMessage(unsigned port, MessageInTransit* message) override;
  void OnDetachFromChannel(unsigned port) override;

 private:
  ~IncomingEndpoint() override;

  Mutex mutex_;
  scoped_refptr<ChannelEndpoint> endpoint_ MOJO_GUARDED_BY(mutex_);
  MessageInTransitQueue message_queue_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(IncomingEndpoint);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_INCOMING_ENDPOINT_H_
