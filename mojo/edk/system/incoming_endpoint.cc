// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/incoming_endpoint.h"

#include "base/logging.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/data_pipe.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/remote_producer_data_pipe_impl.h"

namespace mojo {
namespace system {

IncomingEndpoint::IncomingEndpoint() {
}

scoped_refptr<ChannelEndpoint> IncomingEndpoint::Init() {
  endpoint_ = new ChannelEndpoint(this, 0);
  return endpoint_;
}

scoped_refptr<MessagePipe> IncomingEndpoint::ConvertToMessagePipe() {
  MutexLocker locker(&mutex_);
  scoped_refptr<MessagePipe> message_pipe(
      MessagePipe::CreateLocalProxyFromExisting(&message_queue_,
                                                endpoint_.get()));
  DCHECK(message_queue_.IsEmpty());
  endpoint_ = nullptr;
  return message_pipe;
}

scoped_refptr<DataPipe> IncomingEndpoint::ConvertToDataPipeProducer(
    const MojoCreateDataPipeOptions& validated_options,
    size_t consumer_num_bytes) {
  MutexLocker locker(&mutex_);
  scoped_refptr<DataPipe> data_pipe(DataPipe::CreateRemoteConsumerFromExisting(
      validated_options, consumer_num_bytes, &message_queue_, endpoint_.get()));
  DCHECK(message_queue_.IsEmpty());
  endpoint_ = nullptr;
  return data_pipe;
}

scoped_refptr<DataPipe> IncomingEndpoint::ConvertToDataPipeConsumer(
    const MojoCreateDataPipeOptions& validated_options) {
  MutexLocker locker(&mutex_);
  scoped_refptr<DataPipe> data_pipe(DataPipe::CreateRemoteProducerFromExisting(
      validated_options, &message_queue_, endpoint_.get()));
  DCHECK(message_queue_.IsEmpty());
  endpoint_ = nullptr;
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

  message_queue_.AddMessage(make_scoped_ptr(message));
  return true;
}

void IncomingEndpoint::OnDetachFromChannel(unsigned /*port*/) {
  Close();
}

IncomingEndpoint::~IncomingEndpoint() {
}

}  // namespace system
}  // namespace mojo
