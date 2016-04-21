// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(vtl): I currently potentially overflow in doing index calculations.
// E.g., |start_index_| and |current_num_bytes_| fit into a |uint32_t|, but
// their sum may not. This is bad and poses a security risk. (We're currently
// saved by the limit on capacity -- the maximum size of the buffer, checked in
// |DataPipe::ValidateOptions()|, is currently sufficiently small.)

#include "mojo/edk/system/local_data_pipe_impl.h"

#include <string.h>

#include <algorithm>
#include <utility>

#include "base/logging.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/data_pipe.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/system/message_in_transit_queue.h"
#include "mojo/edk/system/remote_consumer_data_pipe_impl.h"
#include "mojo/edk/system/remote_producer_data_pipe_impl.h"
#include "mojo/edk/util/make_unique.h"

using mojo::platform::AlignedAlloc;
using mojo::platform::ScopedPlatformHandle;
using mojo::util::MakeUnique;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

// Assert some things about some things defined in data_pipe_impl.h (don't make
// the assertions there, to avoid including message_in_transit.h).
static_assert(MOJO_ALIGNOF(SerializedDataPipeConsumerDispatcher) ==
                  MessageInTransit::kMessageAlignment,
              "Wrong alignment");
static_assert(sizeof(SerializedDataPipeConsumerDispatcher) %
                      MessageInTransit::kMessageAlignment ==
                  0,
              "Wrong size");

LocalDataPipeImpl::LocalDataPipeImpl()
    : start_index_(0), current_num_bytes_(0) {
  // Note: |buffer_| is lazily allocated, since a common case will be that one
  // of the handles is immediately passed off to another process.
}

LocalDataPipeImpl::~LocalDataPipeImpl() {
}

void LocalDataPipeImpl::ProducerClose() {
  // If the consumer is still open and we still have data, we have to keep the
  // buffer around. Currently, we won't free it even if it empties later. (We
  // could do this -- requiring a check on every read -- but that seems to be
  // optimizing for the uncommon case.)
  if (!consumer_open() || !current_num_bytes_) {
    // Note: There can only be a two-phase *read* (by the consumer) if we still
    // have data.
    DCHECK(!consumer_in_two_phase_read());
    DestroyBuffer();
  }
}

MojoResult LocalDataPipeImpl::ProducerWriteData(
    UserPointer<const void> elements,
    UserPointer<uint32_t> num_bytes,
    uint32_t max_num_bytes_to_write,
    uint32_t min_num_bytes_to_write) {
  DCHECK_EQ(max_num_bytes_to_write % element_num_bytes(), 0u);
  DCHECK_EQ(min_num_bytes_to_write % element_num_bytes(), 0u);
  DCHECK_GT(max_num_bytes_to_write, 0u);
  DCHECK_GE(max_num_bytes_to_write, min_num_bytes_to_write);
  DCHECK(consumer_open());

  if (min_num_bytes_to_write > capacity_num_bytes() - current_num_bytes_) {
    // Don't return "should wait" since you can't wait for a specified amount
    // of data.
    return MOJO_RESULT_OUT_OF_RANGE;
  }

  size_t num_bytes_to_write =
      std::min(static_cast<size_t>(max_num_bytes_to_write),
               capacity_num_bytes() - current_num_bytes_);
  if (num_bytes_to_write == 0)
    return MOJO_RESULT_SHOULD_WAIT;

  // The amount we can write in our first copy.
  size_t num_bytes_to_write_first =
      std::min(num_bytes_to_write, GetMaxNumBytesToWrite());
  // Do the first (and possibly only) copy.
  size_t first_write_index =
      (start_index_ + current_num_bytes_) % capacity_num_bytes();
  EnsureBuffer();
  elements.GetArray(buffer_.get() + first_write_index,
                    num_bytes_to_write_first);

  if (num_bytes_to_write_first < num_bytes_to_write) {
    // The "second write index" is zero.
    elements.At(num_bytes_to_write_first)
        .GetArray(buffer_.get(), num_bytes_to_write - num_bytes_to_write_first);
  }

  current_num_bytes_ += num_bytes_to_write;
  DCHECK_LE(current_num_bytes_, capacity_num_bytes());
  num_bytes.Put(static_cast<uint32_t>(num_bytes_to_write));
  return MOJO_RESULT_OK;
}

MojoResult LocalDataPipeImpl::ProducerBeginWriteData(
    UserPointer<void*> buffer,
    UserPointer<uint32_t> buffer_num_bytes) {
  DCHECK(consumer_open());

  // The index we need to start writing at.
  size_t write_index =
      (start_index_ + current_num_bytes_) % capacity_num_bytes();

  size_t max_num_bytes_to_write = GetMaxNumBytesToWrite();
  // Don't go into a two-phase write if there's no room.
  if (max_num_bytes_to_write == 0)
    return MOJO_RESULT_SHOULD_WAIT;

  EnsureBuffer();
  buffer.Put(buffer_.get() + write_index);
  buffer_num_bytes.Put(static_cast<uint32_t>(max_num_bytes_to_write));
  set_producer_two_phase_max_num_bytes_written(
      static_cast<uint32_t>(max_num_bytes_to_write));
  return MOJO_RESULT_OK;
}

MojoResult LocalDataPipeImpl::ProducerEndWriteData(uint32_t num_bytes_written) {
  DCHECK_LE(num_bytes_written, producer_two_phase_max_num_bytes_written());
  DCHECK_EQ(num_bytes_written % element_num_bytes(), 0u);
  current_num_bytes_ += num_bytes_written;
  DCHECK_LE(current_num_bytes_, capacity_num_bytes());
  set_producer_two_phase_max_num_bytes_written(0);
  return MOJO_RESULT_OK;
}

HandleSignalsState LocalDataPipeImpl::ProducerGetHandleSignalsState() const {
  HandleSignalsState rv;
  if (consumer_open()) {
    if (!producer_in_two_phase_write()) {
      // |producer_write_threshold_num_bytes()| is always at least 1.
      if (capacity_num_bytes() - current_num_bytes_ >=
          producer_write_threshold_num_bytes()) {
        rv.satisfied_signals |=
            MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_WRITE_THRESHOLD;
      } else if (current_num_bytes_ < capacity_num_bytes()) {
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

void LocalDataPipeImpl::ProducerStartSerialize(Channel* channel,
                                               size_t* max_size,
                                               size_t* max_platform_handles) {
  *max_size = sizeof(SerializedDataPipeProducerDispatcher) +
              channel->GetSerializedEndpointSize();
  *max_platform_handles = 0;
}

bool LocalDataPipeImpl::ProducerEndSerialize(
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

  // Case 2: The consumer isn't closed. We'll replace ourselves with a
  // |RemoteProducerDataPipeImpl|.

  s->consumer_num_bytes = current_num_bytes_;
  // Note: We don't use |port|.
  RefPtr<ChannelEndpoint> channel_endpoint =
      channel->SerializeEndpointWithLocalPeer(
          destination_for_endpoint, nullptr,
          RefPtr<ChannelEndpointClient>(channel_endpoint_client()), 0);
  // Note: Keep |*this| alive until the end of this method, to make things
  // slightly easier on ourselves.
  std::unique_ptr<DataPipeImpl> self(
      ReplaceImpl(MakeUnique<RemoteProducerDataPipeImpl>(
          std::move(channel_endpoint), std::move(buffer_), start_index_,
          current_num_bytes_)));

  *actual_size = sizeof(SerializedDataPipeProducerDispatcher) +
                 channel->GetSerializedEndpointSize();
  return true;
}

void LocalDataPipeImpl::ConsumerClose() {
  // If the producer is around and in a two-phase write, we have to keep the
  // buffer around. (We then don't free it until the producer is closed. This
  // could be rectified, but again seems like optimizing for the uncommon case.)
  if (!producer_open() || !producer_in_two_phase_write())
    DestroyBuffer();
  current_num_bytes_ = 0;
}

MojoResult LocalDataPipeImpl::ConsumerReadData(UserPointer<void> elements,
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

  // The amount we can read in our first copy.
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

MojoResult LocalDataPipeImpl::ConsumerDiscardData(
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

MojoResult LocalDataPipeImpl::ConsumerQueryData(
    UserPointer<uint32_t> num_bytes) {
  // Note: This cast is safe, since the capacity fits into a |uint32_t|.
  num_bytes.Put(static_cast<uint32_t>(current_num_bytes_));
  return MOJO_RESULT_OK;
}

MojoResult LocalDataPipeImpl::ConsumerBeginReadData(
    UserPointer<const void*> buffer,
    UserPointer<uint32_t> buffer_num_bytes) {
  size_t max_num_bytes_to_read = GetMaxNumBytesToRead();
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

MojoResult LocalDataPipeImpl::ConsumerEndReadData(uint32_t num_bytes_read) {
  DCHECK_LE(num_bytes_read, consumer_two_phase_max_num_bytes_read());
  DCHECK_EQ(num_bytes_read % element_num_bytes(), 0u);
  DCHECK_LE(start_index_ + num_bytes_read, capacity_num_bytes());
  MarkDataAsConsumed(num_bytes_read);
  set_consumer_two_phase_max_num_bytes_read(0);
  return MOJO_RESULT_OK;
}

HandleSignalsState LocalDataPipeImpl::ConsumerGetHandleSignalsState() const {
  HandleSignalsState rv;
  // |consumer_read_threshold_num_bytes()| is always at least 1.
  if (current_num_bytes_ >= consumer_read_threshold_num_bytes()) {
    if (!consumer_in_two_phase_read()) {
      rv.satisfied_signals |=
          MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD;
    }
    rv.satisfiable_signals |=
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_READ_THRESHOLD;
  } else if (current_num_bytes_ > 0u) {
    if (!consumer_in_two_phase_read())
      rv.satisfied_signals |= MOJO_HANDLE_SIGNAL_READABLE;
    rv.satisfiable_signals |= MOJO_HANDLE_SIGNAL_READABLE;
  }
  if (producer_open()) {
    rv.satisfiable_signals |= MOJO_HANDLE_SIGNAL_READABLE |
                              MOJO_HANDLE_SIGNAL_PEER_CLOSED |
                              MOJO_HANDLE_SIGNAL_READ_THRESHOLD;
  } else {
    rv.satisfied_signals |= MOJO_HANDLE_SIGNAL_PEER_CLOSED;
    rv.satisfiable_signals |= MOJO_HANDLE_SIGNAL_PEER_CLOSED;
  }
  return rv;
}

void LocalDataPipeImpl::ConsumerStartSerialize(Channel* channel,
                                               size_t* max_size,
                                               size_t* max_platform_handles) {
  *max_size = sizeof(SerializedDataPipeConsumerDispatcher) +
              channel->GetSerializedEndpointSize();
  *max_platform_handles = 0;
}

bool LocalDataPipeImpl::ConsumerEndSerialize(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    std::vector<ScopedPlatformHandle>* /*platform_handles*/) {
  SerializedDataPipeConsumerDispatcher* s =
      static_cast<SerializedDataPipeConsumerDispatcher*>(destination);
  s->validated_options = validated_options();
  void* destination_for_endpoint = static_cast<char*>(destination) +
                                   sizeof(SerializedDataPipeConsumerDispatcher);

  size_t old_num_bytes = current_num_bytes_;
  MessageInTransitQueue message_queue;
  ConvertDataToMessages(buffer_.get(), &start_index_, &current_num_bytes_,
                        &message_queue);

  if (!producer_open()) {
    // Case 1: The producer is closed.
    DestroyBuffer();
    channel->SerializeEndpointWithClosedPeer(destination_for_endpoint,
                                             &message_queue);
    *actual_size = sizeof(SerializedDataPipeConsumerDispatcher) +
                   channel->GetSerializedEndpointSize();
    return true;
  }

  // Case 2: The producer isn't closed. We'll replace ourselves with a
  // |RemoteConsumerDataPipeImpl|.

  // Note: We don't use |port|.
  RefPtr<ChannelEndpoint> channel_endpoint =
      channel->SerializeEndpointWithLocalPeer(
          destination_for_endpoint, &message_queue,
          RefPtr<ChannelEndpointClient>(channel_endpoint_client()), 0);
  // Note: Keep |*this| alive until the end of this method, to make things
  // slightly easier on ourselves.
  std::unique_ptr<DataPipeImpl> self(
      ReplaceImpl(MakeUnique<RemoteConsumerDataPipeImpl>(
          std::move(channel_endpoint), old_num_bytes, std::move(buffer_),
          start_index_)));
  DestroyBuffer();

  *actual_size = sizeof(SerializedDataPipeConsumerDispatcher) +
                 channel->GetSerializedEndpointSize();
  return true;
}

bool LocalDataPipeImpl::OnReadMessage(unsigned /*port*/,
                                      MessageInTransit* /*message*/) {
  NOTREACHED();
  return false;
}

void LocalDataPipeImpl::OnDetachFromChannel(unsigned /*port*/) {
  NOTREACHED();
}

void LocalDataPipeImpl::EnsureBuffer() {
  DCHECK(producer_open());
  if (buffer_)
    return;
  buffer_ =
      AlignedAlloc<char>(GetConfiguration().data_pipe_buffer_alignment_bytes,
                         capacity_num_bytes());
}

void LocalDataPipeImpl::DestroyBuffer() {
#ifndef NDEBUG
  // Scribble on the buffer to help detect use-after-frees. (This also helps the
  // unit test detect certain bugs without needing ASAN or similar.)
  if (buffer_)
    memset(buffer_.get(), 0xcd, capacity_num_bytes());
#endif
  buffer_.reset();
  start_index_ = 0;
  current_num_bytes_ = 0;
}

size_t LocalDataPipeImpl::GetMaxNumBytesToWrite() {
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

size_t LocalDataPipeImpl::GetMaxNumBytesToRead() {
  if (start_index_ + current_num_bytes_ > capacity_num_bytes())
    return capacity_num_bytes() - start_index_;
  return current_num_bytes_;
}

void LocalDataPipeImpl::MarkDataAsConsumed(size_t num_bytes) {
  DCHECK_LE(num_bytes, current_num_bytes_);
  start_index_ += num_bytes;
  start_index_ %= capacity_num_bytes();
  current_num_bytes_ -= num_bytes;
}

}  // namespace system
}  // namespace mojo
