// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/remote_producer_data_pipe_impl.h"

#include <string.h>

#include <algorithm>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/data_pipe.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/system/message_in_transit_queue.h"
#include "mojo/edk/system/remote_consumer_data_pipe_impl.h"
#include "mojo/edk/system/remote_data_pipe_ack.h"

namespace mojo {
namespace system {

namespace {

bool ValidateIncomingMessage(size_t element_num_bytes,
                             size_t capacity_num_bytes,
                             size_t current_num_bytes,
                             const MessageInTransit* message) {
  // We should only receive endpoint client messages.
  DCHECK_EQ(message->type(), MessageInTransit::Type::ENDPOINT_CLIENT);

  // But we should check the subtype; only take data messages.
  if (message->subtype() != MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA) {
    LOG(WARNING) << "Received message of unexpected subtype: "
                 << message->subtype();
    return false;
  }

  const size_t num_bytes = message->num_bytes();
  const size_t max_num_bytes = capacity_num_bytes - current_num_bytes;
  if (num_bytes > max_num_bytes) {
    LOG(WARNING) << "Received too much data: " << num_bytes
                 << " bytes (maximum: " << max_num_bytes << " bytes)";
    return false;
  }

  if (num_bytes % element_num_bytes != 0) {
    LOG(WARNING) << "Received data not a multiple of element size: "
                 << num_bytes << " bytes (element size: " << element_num_bytes
                 << " bytes)";
    return false;
  }

  return true;
}

}  // namespace

RemoteProducerDataPipeImpl::RemoteProducerDataPipeImpl(
    ChannelEndpoint* channel_endpoint)
    : channel_endpoint_(channel_endpoint),
      start_index_(0),
      current_num_bytes_(0) {
  // Note: |buffer_| is lazily allocated.
}

RemoteProducerDataPipeImpl::RemoteProducerDataPipeImpl(
    ChannelEndpoint* channel_endpoint,
    scoped_ptr<char, base::AlignedFreeDeleter> buffer,
    size_t start_index,
    size_t current_num_bytes)
    : channel_endpoint_(channel_endpoint),
      buffer_(buffer.Pass()),
      start_index_(start_index),
      current_num_bytes_(current_num_bytes) {
  DCHECK(buffer_ || !current_num_bytes);
}

// static
bool RemoteProducerDataPipeImpl::ProcessMessagesFromIncomingEndpoint(
    const MojoCreateDataPipeOptions& validated_options,
    MessageInTransitQueue* messages,
    scoped_ptr<char, base::AlignedFreeDeleter>* buffer,
    size_t* buffer_num_bytes) {
  DCHECK(!*buffer);  // Not wrong, but unlikely.

  const size_t element_num_bytes = validated_options.element_num_bytes;
  const size_t capacity_num_bytes = validated_options.capacity_num_bytes;

  scoped_ptr<char, base::AlignedFreeDeleter> new_buffer(static_cast<char*>(
      base::AlignedAlloc(capacity_num_bytes,
                         GetConfiguration().data_pipe_buffer_alignment_bytes)));

  size_t current_num_bytes = 0;
  if (messages) {
    while (!messages->IsEmpty()) {
      scoped_ptr<MessageInTransit> message(messages->GetMessage());
      if (!ValidateIncomingMessage(element_num_bytes, capacity_num_bytes,
                                   current_num_bytes, message.get())) {
        messages->Clear();
        return false;
      }

      memcpy(new_buffer.get() + current_num_bytes, message->bytes(),
             message->num_bytes());
      current_num_bytes += message->num_bytes();
    }
  }

  *buffer = new_buffer.Pass();
  *buffer_num_bytes = current_num_bytes;
  return true;
}

RemoteProducerDataPipeImpl::~RemoteProducerDataPipeImpl() {
}

void RemoteProducerDataPipeImpl::ProducerClose() {
  NOTREACHED();
}

MojoResult RemoteProducerDataPipeImpl::ProducerWriteData(
    UserPointer<const void> /*elements*/,
    UserPointer<uint32_t> /*num_bytes*/,
    uint32_t /*max_num_bytes_to_write*/,
    uint32_t /*min_num_bytes_to_write*/) {
  NOTREACHED();
  return MOJO_RESULT_INTERNAL;
}

MojoResult RemoteProducerDataPipeImpl::ProducerBeginWriteData(
    UserPointer<void*> /*buffer*/,
    UserPointer<uint32_t> /*buffer_num_bytes*/,
    uint32_t /*min_num_bytes_to_write*/) {
  NOTREACHED();
  return MOJO_RESULT_INTERNAL;
}

MojoResult RemoteProducerDataPipeImpl::ProducerEndWriteData(
    uint32_t /*num_bytes_written*/) {
  NOTREACHED();
  return MOJO_RESULT_INTERNAL;
}

HandleSignalsState RemoteProducerDataPipeImpl::ProducerGetHandleSignalsState()
    const {
  return HandleSignalsState();
}

void RemoteProducerDataPipeImpl::ProducerStartSerialize(
    Channel* /*channel*/,
    size_t* /*max_size*/,
    size_t* /*max_platform_handles*/) {
  NOTREACHED();
}

bool RemoteProducerDataPipeImpl::ProducerEndSerialize(
    Channel* /*channel*/,
    void* /*destination*/,
    size_t* /*actual_size*/,
    embedder::PlatformHandleVector* /*platform_handles*/) {
  NOTREACHED();
  return false;
}

void RemoteProducerDataPipeImpl::ConsumerClose() {
  if (producer_open())
    Disconnect();
  current_num_bytes_ = 0;
}

MojoResult RemoteProducerDataPipeImpl::ConsumerReadData(
    UserPointer<void> elements,
    UserPointer<uint32_t> num_bytes,
    uint32_t max_num_bytes_to_read,
    uint32_t min_num_bytes_to_read,
    bool peek) {
  DCHECK_EQ(max_num_bytes_to_read % element_num_bytes(), 0u);
  DCHECK_EQ(min_num_bytes_to_read % element_num_bytes(), 0u);
  DCHECK_GT(max_num_bytes_to_read, 0u);

  if (min_num_bytes_to_read > current_num_bytes_) {
    // Don't return "should wait" since you can't wait for a specified amount of
    // data.
    return producer_open() ? MOJO_RESULT_OUT_OF_RANGE
                           : MOJO_RESULT_FAILED_PRECONDITION;
  }

  size_t num_bytes_to_read =
      std::min(static_cast<size_t>(max_num_bytes_to_read), current_num_bytes_);
  if (num_bytes_to_read == 0) {
    return producer_open() ? MOJO_RESULT_SHOULD_WAIT
                           : MOJO_RESULT_FAILED_PRECONDITION;
  }

  // The amount we can read in our first |memcpy()|.
  size_t num_bytes_to_read_first =
      std::min(num_bytes_to_read, GetMaxNumBytesToRead());
  elements.PutArray(buffer_.get() + start_index_, num_bytes_to_read_first);

  if (num_bytes_to_read_first < num_bytes_to_read) {
    // The "second read index" is zero.
    elements.At(num_bytes_to_read_first)
        .PutArray(buffer_.get(), num_bytes_to_read - num_bytes_to_read_first);
  }

  if (!peek)
    MarkDataAsConsumed(num_bytes_to_read);
  num_bytes.Put(static_cast<uint32_t>(num_bytes_to_read));
  return MOJO_RESULT_OK;
}

MojoResult RemoteProducerDataPipeImpl::ConsumerDiscardData(
    UserPointer<uint32_t> num_bytes,
    uint32_t max_num_bytes_to_discard,
    uint32_t min_num_bytes_to_discard) {
  DCHECK_EQ(max_num_bytes_to_discard % element_num_bytes(), 0u);
  DCHECK_EQ(min_num_bytes_to_discard % element_num_bytes(), 0u);
  DCHECK_GT(max_num_bytes_to_discard, 0u);

  if (min_num_bytes_to_discard > current_num_bytes_) {
    // Don't return "should wait" since you can't wait for a specified amount of
    // data.
    return producer_open() ? MOJO_RESULT_OUT_OF_RANGE
                           : MOJO_RESULT_FAILED_PRECONDITION;
  }

  // Be consistent with other operations; error if no data available.
  if (current_num_bytes_ == 0) {
    return producer_open() ? MOJO_RESULT_SHOULD_WAIT
                           : MOJO_RESULT_FAILED_PRECONDITION;
  }

  size_t num_bytes_to_discard = std::min(
      static_cast<size_t>(max_num_bytes_to_discard), current_num_bytes_);
  MarkDataAsConsumed(num_bytes_to_discard);
  num_bytes.Put(static_cast<uint32_t>(num_bytes_to_discard));
  return MOJO_RESULT_OK;
}

MojoResult RemoteProducerDataPipeImpl::ConsumerQueryData(
    UserPointer<uint32_t> num_bytes) {
  // Note: This cast is safe, since the capacity fits into a |uint32_t|.
  num_bytes.Put(static_cast<uint32_t>(current_num_bytes_));
  return MOJO_RESULT_OK;
}

MojoResult RemoteProducerDataPipeImpl::ConsumerBeginReadData(
    UserPointer<const void*> buffer,
    UserPointer<uint32_t> buffer_num_bytes,
    uint32_t min_num_bytes_to_read) {
  size_t max_num_bytes_to_read = GetMaxNumBytesToRead();
  if (min_num_bytes_to_read > max_num_bytes_to_read) {
    // Don't return "should wait" since you can't wait for a specified amount of
    // data.
    return producer_open() ? MOJO_RESULT_OUT_OF_RANGE
                           : MOJO_RESULT_FAILED_PRECONDITION;
  }

  // Don't go into a two-phase read if there's no data.
  if (max_num_bytes_to_read == 0) {
    return producer_open() ? MOJO_RESULT_SHOULD_WAIT
                           : MOJO_RESULT_FAILED_PRECONDITION;
  }

  buffer.Put(buffer_.get() + start_index_);
  buffer_num_bytes.Put(static_cast<uint32_t>(max_num_bytes_to_read));
  set_consumer_two_phase_max_num_bytes_read(
      static_cast<uint32_t>(max_num_bytes_to_read));
  return MOJO_RESULT_OK;
}

MojoResult RemoteProducerDataPipeImpl::ConsumerEndReadData(
    uint32_t num_bytes_read) {
  DCHECK_LE(num_bytes_read, consumer_two_phase_max_num_bytes_read());
  DCHECK_EQ(num_bytes_read % element_num_bytes(), 0u);
  DCHECK_LE(start_index_ + num_bytes_read, capacity_num_bytes());
  MarkDataAsConsumed(num_bytes_read);
  set_consumer_two_phase_max_num_bytes_read(0);
  return MOJO_RESULT_OK;
}

HandleSignalsState RemoteProducerDataPipeImpl::ConsumerGetHandleSignalsState()
    const {
  HandleSignalsState rv;
  if (current_num_bytes_ > 0) {
    if (!consumer_in_two_phase_read())
      rv.satisfied_signals |= MOJO_HANDLE_SIGNAL_READABLE;
    rv.satisfiable_signals |= MOJO_HANDLE_SIGNAL_READABLE;
  } else if (producer_open()) {
    rv.satisfiable_signals |= MOJO_HANDLE_SIGNAL_READABLE;
  }
  if (!producer_open())
    rv.satisfied_signals |= MOJO_HANDLE_SIGNAL_PEER_CLOSED;
  rv.satisfiable_signals |= MOJO_HANDLE_SIGNAL_PEER_CLOSED;
  return rv;
}

void RemoteProducerDataPipeImpl::ConsumerStartSerialize(
    Channel* channel,
    size_t* max_size,
    size_t* max_platform_handles) {
  *max_size = sizeof(SerializedDataPipeConsumerDispatcher) +
              channel->GetSerializedEndpointSize();
  *max_platform_handles = 0;
}

bool RemoteProducerDataPipeImpl::ConsumerEndSerialize(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    embedder::PlatformHandleVector* platform_handles) {
  SerializedDataPipeConsumerDispatcher* s =
      static_cast<SerializedDataPipeConsumerDispatcher*>(destination);
  s->validated_options = validated_options();
  void* destination_for_endpoint = static_cast<char*>(destination) +
                                   sizeof(SerializedDataPipeConsumerDispatcher);

  MessageInTransitQueue message_queue;
  ConvertDataToMessages(buffer_.get(), &start_index_, &current_num_bytes_,
                        &message_queue);

  if (!producer_open()) {
    // Case 1: The producer is closed.
    channel->SerializeEndpointWithClosedPeer(destination_for_endpoint,
                                             &message_queue);
    *actual_size = sizeof(SerializedDataPipeConsumerDispatcher) +
                   channel->GetSerializedEndpointSize();
    return true;
  }

  // Case 2: The producer isn't closed. We pass |channel_endpoint| back to the
  // |Channel|. There's no reason for us to continue to exist afterwards.

  // Note: We don't use |port|.
  scoped_refptr<ChannelEndpoint> channel_endpoint;
  channel_endpoint.swap(channel_endpoint_);
  channel->SerializeEndpointWithRemotePeer(destination_for_endpoint,
                                           &message_queue, channel_endpoint);
  owner()->SetProducerClosedNoLock();

  *actual_size = sizeof(SerializedDataPipeConsumerDispatcher) +
                 channel->GetSerializedEndpointSize();
  return true;
}

bool RemoteProducerDataPipeImpl::OnReadMessage(unsigned /*port*/,
                                               MessageInTransit* message) {
  if (!producer_open()) {
    // This will happen only on the rare occasion that the call to
    // |OnReadMessage()| is racing with us calling
    // |ChannelEndpoint::ReplaceClient()|, in which case we reject the message,
    // and the |ChannelEndpoint| can retry (calling the new client's
    // |OnReadMessage()|).
    DCHECK(!channel_endpoint_);
    return false;
  }

  // Otherwise, we take ownership of the message. (This means that we should
  // always return true below.)
  scoped_ptr<MessageInTransit> msg(message);

  if (!ValidateIncomingMessage(element_num_bytes(), capacity_num_bytes(),
                               current_num_bytes_, msg.get())) {
    Disconnect();
    return true;
  }

  size_t num_bytes = msg->num_bytes();
  // The amount we can write in our first copy.
  size_t num_bytes_to_copy_first = std::min(num_bytes, GetMaxNumBytesToWrite());
  // Do the first (and possibly only) copy.
  size_t first_write_index =
      (start_index_ + current_num_bytes_) % capacity_num_bytes();
  EnsureBuffer();
  memcpy(buffer_.get() + first_write_index, msg->bytes(),
         num_bytes_to_copy_first);

  if (num_bytes_to_copy_first < num_bytes) {
    // The "second write index" is zero.
    memcpy(buffer_.get(),
           static_cast<const char*>(msg->bytes()) + num_bytes_to_copy_first,
           num_bytes - num_bytes_to_copy_first);
  }

  current_num_bytes_ += num_bytes;
  DCHECK_LE(current_num_bytes_, capacity_num_bytes());
  return true;
}

void RemoteProducerDataPipeImpl::OnDetachFromChannel(unsigned /*port*/) {
  if (!producer_open()) {
    DCHECK(!channel_endpoint_);
    return;
  }

  Disconnect();
}

void RemoteProducerDataPipeImpl::EnsureBuffer() {
  DCHECK(producer_open());
  if (buffer_)
    return;
  buffer_.reset(static_cast<char*>(
      base::AlignedAlloc(capacity_num_bytes(),
                         GetConfiguration().data_pipe_buffer_alignment_bytes)));
}

void RemoteProducerDataPipeImpl::DestroyBuffer() {
#ifndef NDEBUG
  // Scribble on the buffer to help detect use-after-frees. (This also helps the
  // unit test detect certain bugs without needing ASAN or similar.)
  if (buffer_)
    memset(buffer_.get(), 0xcd, capacity_num_bytes());
#endif
  buffer_.reset();
}

size_t RemoteProducerDataPipeImpl::GetMaxNumBytesToWrite() {
  size_t next_index = start_index_ + current_num_bytes_;
  if (next_index >= capacity_num_bytes()) {
    next_index %= capacity_num_bytes();
    DCHECK_GE(start_index_, next_index);
    DCHECK_EQ(start_index_ - next_index,
              capacity_num_bytes() - current_num_bytes_);
    return start_index_ - next_index;
  }
  return capacity_num_bytes() - next_index;
}

size_t RemoteProducerDataPipeImpl::GetMaxNumBytesToRead() {
  if (start_index_ + current_num_bytes_ > capacity_num_bytes())
    return capacity_num_bytes() - start_index_;
  return current_num_bytes_;
}

void RemoteProducerDataPipeImpl::MarkDataAsConsumed(size_t num_bytes) {
  DCHECK_LE(num_bytes, current_num_bytes_);
  start_index_ += num_bytes;
  start_index_ %= capacity_num_bytes();
  current_num_bytes_ -= num_bytes;

  if (!producer_open()) {
    DCHECK(!channel_endpoint_);
    return;
  }

  RemoteDataPipeAck ack_data = {};
  ack_data.num_bytes_consumed = static_cast<uint32_t>(num_bytes);
  scoped_ptr<MessageInTransit> message(new MessageInTransit(
      MessageInTransit::Type::ENDPOINT_CLIENT,
      MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA_PIPE_ACK,
      static_cast<uint32_t>(sizeof(ack_data)), &ack_data));
  if (!channel_endpoint_->EnqueueMessage(message.Pass()))
    Disconnect();
}

void RemoteProducerDataPipeImpl::Disconnect() {
  DCHECK(producer_open());
  DCHECK(channel_endpoint_);
  owner()->SetProducerClosedNoLock();
  channel_endpoint_->DetachFromClient();
  channel_endpoint_ = nullptr;
  // If the consumer is still open and we still have data, we have to keep the
  // buffer around. Currently, we won't free it even if it empties later. (We
  // could do this -- requiring a check on every read -- but that seems to be
  // optimizing for the uncommon case.)
  if (!consumer_open() || !current_num_bytes_)
    DestroyBuffer();
}

}  // namespace system
}  // namespace mojo
