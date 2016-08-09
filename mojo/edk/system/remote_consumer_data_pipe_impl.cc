// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/remote_consumer_data_pipe_impl.h"

#include <string.h>

#include <algorithm>
#include <memory>
#include <utility>

#include "base/logging.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/data_pipe.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/system/remote_data_pipe_ack.h"

using mojo::platform::AlignedAlloc;
using mojo::platform::AlignedUniquePtr;
using mojo::platform::ScopedPlatformHandle;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

namespace {

bool ValidateIncomingMessage(size_t element_num_bytes,
                             size_t capacity_num_bytes,
                             size_t consumer_num_bytes,
                             const MessageInTransit* message) {
  // We should only receive endpoint client messages.
  DCHECK_EQ(message->type(), MessageInTransit::Type::ENDPOINT_CLIENT);

  // But we should check the subtype; only take data pipe acks.
  if (message->subtype() !=
      MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA_PIPE_ACK) {
    LOG(WARNING) << "Received message of unexpected subtype: "
                 << message->subtype();
    return false;
  }

  if (message->num_bytes() != sizeof(RemoteDataPipeAck)) {
    LOG(WARNING) << "Incorrect message size: " << message->num_bytes()
                 << " bytes (expected: " << sizeof(RemoteDataPipeAck)
                 << " bytes)";
    return false;
  }

  const RemoteDataPipeAck* ack =
      static_cast<const RemoteDataPipeAck*>(message->bytes());
  size_t num_bytes_consumed = ack->num_bytes_consumed;

  if (num_bytes_consumed > consumer_num_bytes) {
    LOG(WARNING) << "Number of bytes consumed too large: " << num_bytes_consumed
                 << " bytes (outstanding: " << consumer_num_bytes << " bytes)";
    return false;
  }

  if (num_bytes_consumed % element_num_bytes != 0) {
    LOG(WARNING) << "Number of bytes consumed not a multiple of element size: "
                 << num_bytes_consumed
                 << " bytes (element size: " << element_num_bytes << " bytes)";
    return false;
  }

  return true;
}

}  // namespace

RemoteConsumerDataPipeImpl::RemoteConsumerDataPipeImpl(
    RefPtr<ChannelEndpoint>&& channel_endpoint,
    size_t consumer_num_bytes,
    AlignedUniquePtr<char> buffer,
    size_t start_index)
    : channel_endpoint_(std::move(channel_endpoint)),
      consumer_num_bytes_(consumer_num_bytes),
      buffer_(std::move(buffer)),
      start_index_(start_index) {
  // Note: |buffer_| may be null (in which case it'll be lazily allocated).
}

RemoteConsumerDataPipeImpl::~RemoteConsumerDataPipeImpl() {
}

void RemoteConsumerDataPipeImpl::ProducerClose() {
  if (!consumer_open()) {
    DCHECK(!channel_endpoint_);
    return;
  }

  Disconnect();
}

// static
bool RemoteConsumerDataPipeImpl::ProcessMessagesFromIncomingEndpoint(
    const MojoCreateDataPipeOptions& validated_options,
    size_t* consumer_num_bytes,
    MessageInTransitQueue* messages) {
  const size_t element_num_bytes = validated_options.element_num_bytes;
  const size_t capacity_num_bytes = validated_options.capacity_num_bytes;

  if (messages) {
    while (!messages->IsEmpty()) {
      std::unique_ptr<MessageInTransit> message(messages->GetMessage());
      if (!ValidateIncomingMessage(element_num_bytes, capacity_num_bytes,
                                   *consumer_num_bytes, message.get())) {
        messages->Clear();
        return false;
      }

      const RemoteDataPipeAck* ack =
          static_cast<const RemoteDataPipeAck*>(message->bytes());
      size_t num_bytes_consumed = ack->num_bytes_consumed;
      *consumer_num_bytes -= num_bytes_consumed;
    }
  }

  return true;
}

MojoResult RemoteConsumerDataPipeImpl::ProducerWriteData(
    UserPointer<const void> elements,
    UserPointer<uint32_t> num_bytes,
    uint32_t max_num_bytes_to_write,
    uint32_t min_num_bytes_to_write) {
  DCHECK_EQ(max_num_bytes_to_write % element_num_bytes(), 0u);
  DCHECK_EQ(min_num_bytes_to_write % element_num_bytes(), 0u);
  DCHECK_GT(max_num_bytes_to_write, 0u);
  DCHECK_GE(max_num_bytes_to_write, min_num_bytes_to_write);
  DCHECK(consumer_open());
  DCHECK(channel_endpoint_);

  DCHECK_LE(consumer_num_bytes_, capacity_num_bytes());
  DCHECK_EQ(consumer_num_bytes_ % element_num_bytes(), 0u);

  if (min_num_bytes_to_write > capacity_num_bytes() - consumer_num_bytes_)
    return MOJO_RESULT_OUT_OF_RANGE;

  size_t num_bytes_to_write =
      std::min(static_cast<size_t>(max_num_bytes_to_write),
               capacity_num_bytes() - consumer_num_bytes_);
  if (num_bytes_to_write == 0)
    return MOJO_RESULT_SHOULD_WAIT;

  // The maximum amount of data to send per message (make it a multiple of the
  // element size.
  // TODO(vtl): Copied from |LocalDataPipeImpl::ConvertDataToMessages()|.
  size_t max_message_num_bytes = GetConfiguration().max_message_num_bytes;
  max_message_num_bytes -= max_message_num_bytes % element_num_bytes();
  DCHECK_GT(max_message_num_bytes, 0u);

  size_t offset = 0;
  while (offset < num_bytes_to_write) {
    size_t message_num_bytes =
        std::min(max_message_num_bytes, num_bytes_to_write - offset);
    std::unique_ptr<MessageInTransit> message(new MessageInTransit(
        MessageInTransit::Type::ENDPOINT_CLIENT,
        MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA,
        static_cast<uint32_t>(message_num_bytes), elements.At(offset)));
    if (!channel_endpoint_->EnqueueMessage(std::move(message))) {
      Disconnect();
      break;
    }

    offset += message_num_bytes;
    consumer_num_bytes_ += message_num_bytes;
  }

  DCHECK_LE(consumer_num_bytes_, capacity_num_bytes());
  // TODO(vtl): We report |num_bytes_to_write|, instead of |offset|, even if we
  // failed at some point. This is consistent with the idea that writes either
  // "succeed" or "fail" (and since some bytes may have been sent, we opt for
  // "succeed"). Think about this some more.
  num_bytes.Put(static_cast<uint32_t>(num_bytes_to_write));
  return MOJO_RESULT_OK;
}

MojoResult RemoteConsumerDataPipeImpl::ProducerBeginWriteData(
    UserPointer<void*> buffer,
    UserPointer<uint32_t> buffer_num_bytes) {
  DCHECK(consumer_open());
  DCHECK(channel_endpoint_);

  DCHECK_LE(consumer_num_bytes_, capacity_num_bytes());
  DCHECK_EQ(consumer_num_bytes_ % element_num_bytes(), 0u);

  size_t max_num_bytes_to_write = capacity_num_bytes() - consumer_num_bytes_;
  // Don't go into a two-phase write if there's no room.
  if (max_num_bytes_to_write == 0)
    return MOJO_RESULT_SHOULD_WAIT;

  EnsureBuffer();
  start_index_ = 0;  // We always have the full buffer.
  buffer.Put(buffer_.get());
  buffer_num_bytes.Put(static_cast<uint32_t>(max_num_bytes_to_write));
  set_producer_two_phase_max_num_bytes_written(
      static_cast<uint32_t>(max_num_bytes_to_write));
  return MOJO_RESULT_OK;
}

MojoResult RemoteConsumerDataPipeImpl::ProducerEndWriteData(
    uint32_t num_bytes_written) {
  DCHECK(buffer_);
  DCHECK_LE(num_bytes_written, producer_two_phase_max_num_bytes_written());
  DCHECK_EQ(num_bytes_written % element_num_bytes(), 0u);
  DCHECK_LE(num_bytes_written, capacity_num_bytes() - consumer_num_bytes_);

  if (!consumer_open()) {
    set_producer_two_phase_max_num_bytes_written(0);
    DestroyBuffer();
    return MOJO_RESULT_OK;
  }

  // TODO(vtl): The following code is copied almost verbatim from
  // |ProducerWriteData()| (it's touchy to factor it out since it uses a
  // |UserPointer| while we have a plain pointer.

  // The maximum amount of data to send per message (make it a multiple of the
  // element size.
  // TODO(vtl): Mostly copied from |LocalDataPipeImpl::ConvertDataToMessages()|.
  size_t max_message_num_bytes = GetConfiguration().max_message_num_bytes;
  max_message_num_bytes -= max_message_num_bytes % element_num_bytes();
  DCHECK_GT(max_message_num_bytes, 0u);

  size_t offset = 0;
  while (offset < num_bytes_written) {
    size_t message_num_bytes =
        std::min(max_message_num_bytes, num_bytes_written - offset);
    std::unique_ptr<MessageInTransit> message(
        new MessageInTransit(MessageInTransit::Type::ENDPOINT_CLIENT,
                             MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA,
                             static_cast<uint32_t>(message_num_bytes),
                             buffer_.get() + start_index_ + offset));
    if (!channel_endpoint_->EnqueueMessage(std::move(message))) {
      set_producer_two_phase_max_num_bytes_written(0);
      Disconnect();
      return MOJO_RESULT_OK;
    }

    offset += message_num_bytes;
    consumer_num_bytes_ += message_num_bytes;
  }

  DCHECK_LE(consumer_num_bytes_, capacity_num_bytes());
  // TODO(vtl): (End of mostly copied code.)

  set_producer_two_phase_max_num_bytes_written(0);
  return MOJO_RESULT_OK;
}

HandleSignalsState RemoteConsumerDataPipeImpl::ProducerGetHandleSignalsState()
    const {
  HandleSignalsState rv;
  if (consumer_open()) {
    if (!producer_in_two_phase_write()) {
      // |producer_write_threshold_num_bytes()| is always at least 1.
      if (capacity_num_bytes() - consumer_num_bytes_ >=
          producer_write_threshold_num_bytes()) {
        rv.satisfied_signals |=
            MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD;
      } else if (consumer_num_bytes_ < capacity_num_bytes()) {
        rv.satisfied_signals |= MOJO_HANDLE_SIGNAL_WRITABLE;
      }
    }
    rv.satisfiable_signals |=
        MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD;
  } else {
    rv.satisfied_signals |= MOJO_HANDLE_SIGNAL_PEER_CLOSED;
  }
  rv.satisfiable_signals |= MOJO_HANDLE_SIGNAL_PEER_CLOSED;
  return rv;
}

void RemoteConsumerDataPipeImpl::ProducerStartSerialize(
    Channel* channel,
    size_t* max_size,
    size_t* max_platform_handles) {
  *max_size = sizeof(SerializedDataPipeProducerDispatcher) +
              channel->GetSerializedEndpointSize();
  *max_platform_handles = 0;
}

bool RemoteConsumerDataPipeImpl::ProducerEndSerialize(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    std::vector<ScopedPlatformHandle>* /*platform_handles*/) {
  SerializedDataPipeProducerDispatcher* s =
      static_cast<SerializedDataPipeProducerDispatcher*>(destination);
  s->validated_options = validated_options();
  void* destination_for_endpoint = static_cast<char*>(destination) +
                                   sizeof(SerializedDataPipeProducerDispatcher);

  if (!consumer_open()) {
    // Case 1: The consumer is closed.
    s->consumer_num_bytes = static_cast<size_t>(-1);
    *actual_size = sizeof(SerializedDataPipeProducerDispatcher);
    return true;
  }

  // Case 2: The consumer isn't closed. We pass |channel_endpoint| back to the
  // |Channel|. There's no reason for us to continue to exist afterwards.

  s->consumer_num_bytes = consumer_num_bytes_;
  // Note: We don't use |port|.
  RefPtr<ChannelEndpoint> channel_endpoint;
  channel_endpoint.swap(channel_endpoint_);
  channel->SerializeEndpointWithRemotePeer(destination_for_endpoint, nullptr,
                                           std::move(channel_endpoint));
  SetConsumerClosed();

  *actual_size = sizeof(SerializedDataPipeProducerDispatcher) +
                 channel->GetSerializedEndpointSize();
  return true;
}

void RemoteConsumerDataPipeImpl::ConsumerClose() {
  NOTREACHED();
}

MojoResult RemoteConsumerDataPipeImpl::ConsumerReadData(
    UserPointer<void> /*elements*/,
    UserPointer<uint32_t> /*num_bytes*/,
    uint32_t /*max_num_bytes_to_read*/,
    uint32_t /*min_num_bytes_to_read*/,
    bool /*peek*/) {
  NOTREACHED();
  return MOJO_RESULT_INTERNAL;
}

MojoResult RemoteConsumerDataPipeImpl::ConsumerDiscardData(
    UserPointer<uint32_t> /*num_bytes*/,
    uint32_t /*max_num_bytes_to_discard*/,
    uint32_t /*min_num_bytes_to_discard*/) {
  NOTREACHED();
  return MOJO_RESULT_INTERNAL;
}

MojoResult RemoteConsumerDataPipeImpl::ConsumerQueryData(
    UserPointer<uint32_t> /*num_bytes*/) {
  NOTREACHED();
  return MOJO_RESULT_INTERNAL;
}

MojoResult RemoteConsumerDataPipeImpl::ConsumerBeginReadData(
    UserPointer<const void*> /*buffer*/,
    UserPointer<uint32_t> /*buffer_num_bytes*/) {
  NOTREACHED();
  return MOJO_RESULT_INTERNAL;
}

MojoResult RemoteConsumerDataPipeImpl::ConsumerEndReadData(
    uint32_t /*num_bytes_read*/) {
  NOTREACHED();
  return MOJO_RESULT_INTERNAL;
}

HandleSignalsState RemoteConsumerDataPipeImpl::ConsumerGetHandleSignalsState()
    const {
  return HandleSignalsState();
}

void RemoteConsumerDataPipeImpl::ConsumerStartSerialize(
    Channel* /*channel*/,
    size_t* /*max_size*/,
    size_t* /*max_platform_handles*/) {
  NOTREACHED();
}

bool RemoteConsumerDataPipeImpl::ConsumerEndSerialize(
    Channel* /*channel*/,
    void* /*destination*/,
    size_t* /*actual_size*/,
    std::vector<ScopedPlatformHandle>* /*platform_handles*/) {
  NOTREACHED();
  return false;
}

bool RemoteConsumerDataPipeImpl::OnReadMessage(unsigned /*port*/,
                                               MessageInTransit* message) {
  // Always take ownership of the message. (This means that we should always
  // return true.)
  std::unique_ptr<MessageInTransit> msg(message);

  if (!ValidateIncomingMessage(element_num_bytes(), capacity_num_bytes(),
                               consumer_num_bytes_, msg.get())) {
    Disconnect();
    return true;
  }

  const RemoteDataPipeAck* ack =
      static_cast<const RemoteDataPipeAck*>(msg->bytes());
  size_t num_bytes_consumed = ack->num_bytes_consumed;
  consumer_num_bytes_ -= num_bytes_consumed;
  return true;
}

void RemoteConsumerDataPipeImpl::OnDetachFromChannel(unsigned /*port*/) {
  if (!consumer_open()) {
    DCHECK(!channel_endpoint_);
    return;
  }

  Disconnect();
}

void RemoteConsumerDataPipeImpl::EnsureBuffer() {
  DCHECK(producer_open());
  if (buffer_)
    return;
  buffer_ =
      AlignedAlloc<char>(GetConfiguration().data_pipe_buffer_alignment_bytes,
                         capacity_num_bytes());
}

void RemoteConsumerDataPipeImpl::DestroyBuffer() {
#ifndef NDEBUG
  // Scribble on the buffer to help detect use-after-frees. (This also helps the
  // unit test detect certain bugs without needing ASAN or similar.)
  if (buffer_)
    memset(buffer_.get(), 0xcd, capacity_num_bytes());
#endif
  buffer_.reset();
}

void RemoteConsumerDataPipeImpl::Disconnect() {
  DCHECK(consumer_open());
  DCHECK(channel_endpoint_);
  SetConsumerClosed();
  channel_endpoint_->DetachFromClient();
  channel_endpoint_ = nullptr;
  if (!producer_in_two_phase_write())
    DestroyBuffer();
}

}  // namespace system
}  // namespace mojo
