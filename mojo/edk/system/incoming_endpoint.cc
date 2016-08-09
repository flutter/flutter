// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/incoming_endpoint.h"

#include <utility>

#include "base/logging.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/data_pipe.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/remote_producer_data_pipe_impl.h"

using mojo::util::MakeRefCounted;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

RefPtr<ChannelEndpoint> IncomingEndpoint::Init() {
  endpoint_ =
      MakeRefCounted<ChannelEndpoint>(RefPtr<IncomingEndpoint>(this), 0);
  return endpoint_;
}

RefPtr<MessagePipe> IncomingEndpoint::ConvertToMessagePipe() {
  MutexLocker locker(&mutex_);
  RefPtr<MessagePipe> message_pipe = MessagePipe::CreateLocalProxyFromExisting(
      &message_queue_, std::move(endpoint_));
  DCHECK(message_queue_.IsEmpty());
  return message_pipe;
}

RefPtr<DataPipe> IncomingEndpoint::ConvertToDataPipeProducer(
    const MojoCreateDataPipeOptions& validated_options,
    size_t consumer_num_bytes) {
  MutexLocker locker(&mutex_);
  auto data_pipe = DataPipe::CreateRemoteConsumerFromExisting(
      validated_options, consumer_num_bytes, &message_queue_,
      std::move(endpoint_));
  DCHECK(message_queue_.IsEmpty());
  return data_pipe;
}

RefPtr<DataPipe> IncomingEndpoint::ConvertToDataPipeConsumer(
    const MojoCreateDataPipeOptions& validated_options) {
  MutexLocker locker(&mutex_);
  auto data_pipe = DataPipe::CreateRemoteProducerFromExisting(
      validated_options, &message_queue_, std::move(endpoint_));
  DCHECK(message_queue_.IsEmpty());
  return data_pipe;
}

void IncomingEndpoint::Close() {
  MutexLocker locker(&mutex_);
  if (endpoint_) {
    endpoint_->DetachFromClient();
    endpoint_ = nullptr;
  }
}

bool IncomingEndpoint::OnReadMessage(unsigned /*port*/,
                                     MessageInTransit* message) {
  MutexLocker locker(&mutex_);
  if (!endpoint_)
    return false;

  message_queue_.AddMessage(std::unique_ptr<MessageInTransit>(message));
  return true;
}

void IncomingEndpoint::OnDetachFromChannel(unsigned /*port*/) {
  Close();
}

IncomingEndpoint::IncomingEndpoint() {}

IncomingEndpoint::~IncomingEndpoint() {}

}  // namespace system
}  // namespace mojo
