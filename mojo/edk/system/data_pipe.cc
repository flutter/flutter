// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/data_pipe.h"

#include <string.h>

#include <algorithm>
#include <limits>
#include <memory>
#include <utility>

#include "base/logging.h"
#include "mojo/edk/platform/aligned_alloc.h"
#include "mojo/edk/system/awakable_list.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/data_pipe_impl.h"
#include "mojo/edk/system/incoming_endpoint.h"
#include "mojo/edk/system/local_data_pipe_impl.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/options_validation.h"
#include "mojo/edk/system/remote_consumer_data_pipe_impl.h"
#include "mojo/edk/system/remote_producer_data_pipe_impl.h"
#include "mojo/edk/util/make_unique.h"

using mojo::platform::AlignedUniquePtr;
using mojo::platform::ScopedPlatformHandle;
using mojo::util::MakeUnique;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

// static
MojoCreateDataPipeOptions DataPipe::GetDefaultCreateOptions() {
  MojoCreateDataPipeOptions result = {
      static_cast<uint32_t>(sizeof(MojoCreateDataPipeOptions)),
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,
      1u,
      static_cast<uint32_t>(
          GetConfiguration().default_data_pipe_capacity_bytes)};
  return result;
}

// static
MojoResult DataPipe::ValidateCreateOptions(
    UserPointer<const MojoCreateDataPipeOptions> in_options,
    MojoCreateDataPipeOptions* out_options) {
  const MojoCreateDataPipeOptionsFlags kKnownFlags =
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE;

  *out_options = GetDefaultCreateOptions();
  if (in_options.IsNull())
    return MOJO_RESULT_OK;

  UserOptionsReader<MojoCreateDataPipeOptions> reader(in_options);
  if (!reader.is_valid())
    return MOJO_RESULT_INVALID_ARGUMENT;

  if (!OPTIONS_STRUCT_HAS_MEMBER(MojoCreateDataPipeOptions, flags, reader))
    return MOJO_RESULT_OK;
  if ((reader.options().flags & ~kKnownFlags))
    return MOJO_RESULT_UNIMPLEMENTED;
  out_options->flags = reader.options().flags;

  // Checks for fields beyond |flags|:

  if (!OPTIONS_STRUCT_HAS_MEMBER(MojoCreateDataPipeOptions, element_num_bytes,
                                 reader))
    return MOJO_RESULT_OK;
  if (reader.options().element_num_bytes == 0)
    return MOJO_RESULT_INVALID_ARGUMENT;
  out_options->element_num_bytes = reader.options().element_num_bytes;

  if (!OPTIONS_STRUCT_HAS_MEMBER(MojoCreateDataPipeOptions, capacity_num_bytes,
                                 reader) ||
      reader.options().capacity_num_bytes == 0) {
    // Round the default capacity down to a multiple of the element size (but at
    // least one element).
    size_t default_data_pipe_capacity_bytes =
        GetConfiguration().default_data_pipe_capacity_bytes;
    out_options->capacity_num_bytes =
        std::max(static_cast<uint32_t>(default_data_pipe_capacity_bytes -
                                       (default_data_pipe_capacity_bytes %
                                        out_options->element_num_bytes)),
                 out_options->element_num_bytes);
    return MOJO_RESULT_OK;
  }
  if (reader.options().capacity_num_bytes % out_options->element_num_bytes != 0)
    return MOJO_RESULT_INVALID_ARGUMENT;
  if (reader.options().capacity_num_bytes >
      GetConfiguration().max_data_pipe_capacity_bytes)
    return MOJO_RESULT_RESOURCE_EXHAUSTED;
  out_options->capacity_num_bytes = reader.options().capacity_num_bytes;

  return MOJO_RESULT_OK;
}

// static
RefPtr<DataPipe> DataPipe::CreateLocal(
    const MojoCreateDataPipeOptions& validated_options) {
  return AdoptRef(new DataPipe(true, true, validated_options,
                               MakeUnique<LocalDataPipeImpl>()));
}

// static
RefPtr<DataPipe> DataPipe::CreateRemoteProducerFromExisting(
    const MojoCreateDataPipeOptions& validated_options,
    MessageInTransitQueue* message_queue,
    RefPtr<ChannelEndpoint>&& channel_endpoint) {
  AlignedUniquePtr<char> buffer;
  size_t buffer_num_bytes = 0;
  if (!RemoteProducerDataPipeImpl::ProcessMessagesFromIncomingEndpoint(
          validated_options, message_queue, &buffer, &buffer_num_bytes))
    return nullptr;

  // Important: This is called under |IncomingEndpoint|'s (which is a
  // |ChannelEndpointClient|) lock, in particular from
  // |IncomingEndpoint::ConvertToDataPipeConsumer()|. Before releasing that
  // lock, it will reset its |endpoint_| member, which makes any later or
  // ongoing call to |IncomingEndpoint::OnReadMessage()| return false. This will
  // make |ChannelEndpoint::OnReadMessage()| retry, until its |ReplaceClient()|
  // is called.
  RefPtr<DataPipe> data_pipe = AdoptRef(new DataPipe(
      false, true, validated_options,
      MakeUnique<RemoteProducerDataPipeImpl>(
          channel_endpoint.Clone(), std::move(buffer), 0, buffer_num_bytes)));
  if (channel_endpoint) {
    if (!channel_endpoint->ReplaceClient(data_pipe.Clone(), 0))
      data_pipe->OnDetachFromChannel(0);
  } else {
    data_pipe->SetProducerClosed();
  }
  return data_pipe;
}

// static
RefPtr<DataPipe> DataPipe::CreateRemoteConsumerFromExisting(
    const MojoCreateDataPipeOptions& validated_options,
    size_t consumer_num_bytes,
    MessageInTransitQueue* message_queue,
    RefPtr<ChannelEndpoint>&& channel_endpoint) {
  if (!RemoteConsumerDataPipeImpl::ProcessMessagesFromIncomingEndpoint(
          validated_options, &consumer_num_bytes, message_queue))
    return nullptr;

  // Important: This is called under |IncomingEndpoint|'s (which is a
  // |ChannelEndpointClient|) lock, in particular from
  // |IncomingEndpoint::ConvertToDataPipeProducer()|. Before releasing that
  // lock, it will reset its |endpoint_| member, which makes any later or
  // ongoing call to |IncomingEndpoint::OnReadMessage()| return false. This will
  // make |ChannelEndpoint::OnReadMessage()| retry, until its |ReplaceClient()|
  // is called.
  RefPtr<DataPipe> data_pipe = AdoptRef(new DataPipe(
      true, false, validated_options,
      MakeUnique<RemoteConsumerDataPipeImpl>(channel_endpoint.Clone(),
                                             consumer_num_bytes, nullptr, 0)));
  if (channel_endpoint) {
    if (!channel_endpoint->ReplaceClient(data_pipe.Clone(), 0))
      data_pipe->OnDetachFromChannel(0);
  } else {
    data_pipe->SetConsumerClosed();
  }
  return data_pipe;
}

// static
bool DataPipe::ProducerDeserialize(Channel* channel,
                                   const void* source,
                                   size_t size,
                                   RefPtr<DataPipe>* data_pipe) {
  DCHECK(!*data_pipe);  // Not technically wrong, but unlikely.

  bool consumer_open = false;
  if (size == sizeof(SerializedDataPipeProducerDispatcher)) {
    consumer_open = false;
  } else if (size ==
             sizeof(SerializedDataPipeProducerDispatcher) +
                 channel->GetSerializedEndpointSize()) {
    consumer_open = true;
  } else {
    LOG(ERROR) << "Invalid serialized data pipe producer";
    return false;
  }

  const SerializedDataPipeProducerDispatcher* s =
      static_cast<const SerializedDataPipeProducerDispatcher*>(source);
  MojoCreateDataPipeOptions revalidated_options = {};
  if (ValidateCreateOptions(MakeUserPointer(&s->validated_options),
                            &revalidated_options) != MOJO_RESULT_OK) {
    LOG(ERROR) << "Invalid serialized data pipe producer (bad options)";
    return false;
  }

  if (!consumer_open) {
    if (s->consumer_num_bytes != static_cast<size_t>(-1)) {
      LOG(ERROR)
          << "Invalid serialized data pipe producer (bad consumer_num_bytes)";
      return false;
    }

    *data_pipe = AdoptRef(new DataPipe(
        true, false, revalidated_options,
        MakeUnique<RemoteConsumerDataPipeImpl>(nullptr, 0, nullptr, 0)));
    (*data_pipe)->SetConsumerClosed();

    return true;
  }

  if (s->consumer_num_bytes > revalidated_options.capacity_num_bytes ||
      s->consumer_num_bytes % revalidated_options.element_num_bytes != 0) {
    LOG(ERROR)
        << "Invalid serialized data pipe producer (bad consumer_num_bytes)";
    return false;
  }

  const void* endpoint_source = static_cast<const char*>(source) +
                                sizeof(SerializedDataPipeProducerDispatcher);
  RefPtr<IncomingEndpoint> incoming_endpoint =
      channel->DeserializeEndpoint(endpoint_source);
  if (!incoming_endpoint)
    return false;

  *data_pipe = incoming_endpoint->ConvertToDataPipeProducer(
      revalidated_options, s->consumer_num_bytes);
  if (!*data_pipe)
    return false;

  return true;
}

// static
bool DataPipe::ConsumerDeserialize(Channel* channel,
                                   const void* source,
                                   size_t size,
                                   RefPtr<DataPipe>* data_pipe) {
  DCHECK(!*data_pipe);  // Not technically wrong, but unlikely.

  if (size !=
      sizeof(SerializedDataPipeConsumerDispatcher) +
          channel->GetSerializedEndpointSize()) {
    LOG(ERROR) << "Invalid serialized data pipe consumer";
    return false;
  }

  const SerializedDataPipeConsumerDispatcher* s =
      static_cast<const SerializedDataPipeConsumerDispatcher*>(source);
  MojoCreateDataPipeOptions revalidated_options = {};
  if (ValidateCreateOptions(MakeUserPointer(&s->validated_options),
                            &revalidated_options) != MOJO_RESULT_OK) {
    LOG(ERROR) << "Invalid serialized data pipe consumer (bad options)";
    return false;
  }

  const void* endpoint_source = static_cast<const char*>(source) +
                                sizeof(SerializedDataPipeConsumerDispatcher);
  RefPtr<IncomingEndpoint> incoming_endpoint =
      channel->DeserializeEndpoint(endpoint_source);
  if (!incoming_endpoint)
    return false;

  *data_pipe =
      incoming_endpoint->ConvertToDataPipeConsumer(revalidated_options);
  if (!*data_pipe)
    return false;

  return true;
}

void DataPipe::ProducerCancelAllState() {
  MutexLocker locker(&mutex_);
  ProducerCancelAllStateNoLock();
}

void DataPipe::ProducerClose() {
  MutexLocker locker(&mutex_);
  ProducerCloseNoLock();
}

MojoResult DataPipe::ProducerSetOptions(uint32_t write_threshold_num_bytes) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_producer_no_lock());

  if (write_threshold_num_bytes % element_num_bytes() != 0)
    return MOJO_RESULT_INVALID_ARGUMENT;

  HandleSignalsState old_producer_state =
      impl_->ProducerGetHandleSignalsState();
  producer_write_threshold_num_bytes_ = write_threshold_num_bytes;
  OnProducerMaybeStateChange(old_producer_state,
                             impl_->ProducerGetHandleSignalsState());
  return MOJO_RESULT_OK;
}

void DataPipe::ProducerGetOptions(uint32_t* write_threshold_num_bytes) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_producer_no_lock());
  *write_threshold_num_bytes = producer_write_threshold_num_bytes_;
}

MojoResult DataPipe::ProducerWriteData(UserPointer<const void> elements,
                                       UserPointer<uint32_t> num_bytes,
                                       bool all_or_none) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_producer_no_lock());

  if (producer_in_two_phase_write_no_lock())
    return MOJO_RESULT_BUSY;
  if (!consumer_open_no_lock())
    return MOJO_RESULT_FAILED_PRECONDITION;

  // Returning "busy" takes priority over "invalid argument".
  uint32_t max_num_bytes_to_write = num_bytes.Get();
  if (max_num_bytes_to_write % element_num_bytes() != 0)
    return MOJO_RESULT_INVALID_ARGUMENT;

  if (max_num_bytes_to_write == 0)
    return MOJO_RESULT_OK;  // Nothing to do.

  uint32_t min_num_bytes_to_write = all_or_none ? max_num_bytes_to_write : 0;

  HandleSignalsState old_consumer_state =
      impl_->ConsumerGetHandleSignalsState();
  MojoResult rv = impl_->ProducerWriteData(
      elements, num_bytes, max_num_bytes_to_write, min_num_bytes_to_write);
  OnConsumerMaybeStateChange(old_consumer_state,
                             impl_->ConsumerGetHandleSignalsState());
  return rv;
}

MojoResult DataPipe::ProducerBeginWriteData(
    UserPointer<void*> buffer,
    UserPointer<uint32_t> buffer_num_bytes) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_producer_no_lock());

  if (producer_in_two_phase_write_no_lock())
    return MOJO_RESULT_BUSY;
  if (!consumer_open_no_lock())
    return MOJO_RESULT_FAILED_PRECONDITION;

  MojoResult rv = impl_->ProducerBeginWriteData(buffer, buffer_num_bytes);
  if (rv != MOJO_RESULT_OK)
    return rv;
  // Note: No need to awake producer awakables, even though we're going from
  // writable to non-writable (since you can't wait on non-writability).
  // Similarly, though this may have discarded data (in "may discard" mode),
  // making it non-readable, there's still no need to awake consumer awakables.
  DCHECK(producer_in_two_phase_write_no_lock());
  return MOJO_RESULT_OK;
}

MojoResult DataPipe::ProducerEndWriteData(uint32_t num_bytes_written) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_producer_no_lock());

  if (!producer_in_two_phase_write_no_lock())
    return MOJO_RESULT_FAILED_PRECONDITION;
  // Note: Allow successful completion of the two-phase write even if the
  // consumer has been closed.

  HandleSignalsState old_consumer_state =
      impl_->ConsumerGetHandleSignalsState();
  HandleSignalsState old_producer_state =
      impl_->ProducerGetHandleSignalsState();
  MojoResult rv;
  if (num_bytes_written > producer_two_phase_max_num_bytes_written_ ||
      num_bytes_written % element_num_bytes() != 0) {
    rv = MOJO_RESULT_INVALID_ARGUMENT;
    producer_two_phase_max_num_bytes_written_ = 0;
  } else {
    rv = impl_->ProducerEndWriteData(num_bytes_written);
  }
  // Two-phase write ended even on failure.
  DCHECK(!producer_in_two_phase_write_no_lock());
  // If we're now writable, we *became* writable (since we weren't writable
  // during the two-phase write), so awake producer awakables.
  OnProducerMaybeStateChange(old_producer_state,
                             impl_->ProducerGetHandleSignalsState());
  OnConsumerMaybeStateChange(old_consumer_state,
                             impl_->ConsumerGetHandleSignalsState());
  return rv;
}

HandleSignalsState DataPipe::ProducerGetHandleSignalsState() {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_producer_no_lock());
  return impl_->ProducerGetHandleSignalsState();
}

MojoResult DataPipe::ProducerAddAwakable(Awakable* awakable,
                                         uint64_t context,
                                         bool persistent,
                                         MojoHandleSignals signals,
                                         HandleSignalsState* signals_state) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_producer_no_lock());

  HandleSignalsState producer_state = impl_->ProducerGetHandleSignalsState();
  if (signals_state)
    *signals_state = producer_state;
  MojoResult rv = MOJO_RESULT_OK;
  bool should_add = persistent;
  if (producer_state.satisfies(signals))
    rv = MOJO_RESULT_ALREADY_EXISTS;
  else if (!producer_state.can_satisfy(signals))
    rv = MOJO_RESULT_FAILED_PRECONDITION;
  else
    should_add = true;

  if (should_add) {
    producer_awakable_list_->Add(awakable, context, persistent, signals,
                                 producer_state);
  }
  return rv;
}

void DataPipe::ProducerRemoveAwakable(bool match_context,
                                      Awakable* awakable,
                                      uint64_t context,
                                      HandleSignalsState* signals_state) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_producer_no_lock());
  producer_awakable_list_->Remove(match_context, awakable, context);
  if (signals_state)
    *signals_state = impl_->ProducerGetHandleSignalsState();
}

void DataPipe::ProducerStartSerialize(Channel* channel,
                                      size_t* max_size,
                                      size_t* max_platform_handles) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_producer_no_lock());
  impl_->ProducerStartSerialize(channel, max_size, max_platform_handles);
}

bool DataPipe::ProducerEndSerialize(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    std::vector<ScopedPlatformHandle>* platform_handles) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_producer_no_lock());
  // Warning: After |ProducerEndSerialize()|, quite probably |impl_| has
  // changed.
  bool rv = impl_->ProducerEndSerialize(channel, destination, actual_size,
                                        platform_handles);

  ProducerCancelAllStateNoLock();
  producer_awakable_list_.reset();
  if (!has_local_consumer_no_lock())
    producer_open_ = false;

  return rv;
}

void DataPipe::ConsumerCancelAllState() {
  MutexLocker locker(&mutex_);
  ConsumerCancelAllStateNoLock();
}

void DataPipe::ConsumerClose() {
  MutexLocker locker(&mutex_);
  ConsumerCloseNoLock();
}

MojoResult DataPipe::ConsumerSetOptions(uint32_t read_threshold_num_bytes) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_consumer_no_lock());

  if (read_threshold_num_bytes % element_num_bytes() != 0)
    return MOJO_RESULT_INVALID_ARGUMENT;

  HandleSignalsState old_consumer_state =
      impl_->ConsumerGetHandleSignalsState();
  consumer_read_threshold_num_bytes_ = read_threshold_num_bytes;
  OnConsumerMaybeStateChange(old_consumer_state,
                             impl_->ConsumerGetHandleSignalsState());
  return MOJO_RESULT_OK;
}

void DataPipe::ConsumerGetOptions(uint32_t* read_threshold_num_bytes) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_consumer_no_lock());
  *read_threshold_num_bytes = consumer_read_threshold_num_bytes_;
}

MojoResult DataPipe::ConsumerReadData(UserPointer<void> elements,
                                      UserPointer<uint32_t> num_bytes,
                                      bool all_or_none,
                                      bool peek) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_consumer_no_lock());

  if (consumer_in_two_phase_read_no_lock())
    return MOJO_RESULT_BUSY;

  uint32_t max_num_bytes_to_read = num_bytes.Get();
  if (max_num_bytes_to_read % element_num_bytes() != 0)
    return MOJO_RESULT_INVALID_ARGUMENT;

  if (max_num_bytes_to_read == 0)
    return MOJO_RESULT_OK;  // Nothing to do.

  uint32_t min_num_bytes_to_read = all_or_none ? max_num_bytes_to_read : 0;

  HandleSignalsState old_producer_state =
      impl_->ProducerGetHandleSignalsState();
  MojoResult rv = impl_->ConsumerReadData(
      elements, num_bytes, max_num_bytes_to_read, min_num_bytes_to_read, peek);
  OnProducerMaybeStateChange(old_producer_state,
                             impl_->ProducerGetHandleSignalsState());
  return rv;
}

MojoResult DataPipe::ConsumerDiscardData(UserPointer<uint32_t> num_bytes,
                                         bool all_or_none) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_consumer_no_lock());

  if (consumer_in_two_phase_read_no_lock())
    return MOJO_RESULT_BUSY;

  uint32_t max_num_bytes_to_discard = num_bytes.Get();
  if (max_num_bytes_to_discard % element_num_bytes() != 0)
    return MOJO_RESULT_INVALID_ARGUMENT;

  if (max_num_bytes_to_discard == 0)
    return MOJO_RESULT_OK;  // Nothing to do.

  uint32_t min_num_bytes_to_discard =
      all_or_none ? max_num_bytes_to_discard : 0;

  HandleSignalsState old_producer_state =
      impl_->ProducerGetHandleSignalsState();
  MojoResult rv = impl_->ConsumerDiscardData(
      num_bytes, max_num_bytes_to_discard, min_num_bytes_to_discard);
  OnProducerMaybeStateChange(old_producer_state,
                             impl_->ProducerGetHandleSignalsState());
  return rv;
}

MojoResult DataPipe::ConsumerQueryData(UserPointer<uint32_t> num_bytes) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_consumer_no_lock());

  if (consumer_in_two_phase_read_no_lock())
    return MOJO_RESULT_BUSY;

  // Note: Don't need to validate |*num_bytes| for query.
  return impl_->ConsumerQueryData(num_bytes);
}

MojoResult DataPipe::ConsumerBeginReadData(
    UserPointer<const void*> buffer,
    UserPointer<uint32_t> buffer_num_bytes) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_consumer_no_lock());

  if (consumer_in_two_phase_read_no_lock())
    return MOJO_RESULT_BUSY;

  MojoResult rv = impl_->ConsumerBeginReadData(buffer, buffer_num_bytes);
  if (rv != MOJO_RESULT_OK)
    return rv;
  DCHECK(consumer_in_two_phase_read_no_lock());
  return MOJO_RESULT_OK;
}

MojoResult DataPipe::ConsumerEndReadData(uint32_t num_bytes_read) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_consumer_no_lock());

  if (!consumer_in_two_phase_read_no_lock())
    return MOJO_RESULT_FAILED_PRECONDITION;

  HandleSignalsState old_consumer_state =
      impl_->ConsumerGetHandleSignalsState();
  HandleSignalsState old_producer_state =
      impl_->ProducerGetHandleSignalsState();
  MojoResult rv;
  if (num_bytes_read > consumer_two_phase_max_num_bytes_read_ ||
      num_bytes_read % element_num_bytes() != 0) {
    rv = MOJO_RESULT_INVALID_ARGUMENT;
    consumer_two_phase_max_num_bytes_read_ = 0;
  } else {
    rv = impl_->ConsumerEndReadData(num_bytes_read);
  }
  // Two-phase read ended even on failure.
  DCHECK(!consumer_in_two_phase_read_no_lock());
  // If we're now readable, we *became* readable (since we weren't readable
  // during the two-phase read), so awake consumer awakables.
  OnConsumerMaybeStateChange(old_consumer_state,
                             impl_->ConsumerGetHandleSignalsState());
  OnProducerMaybeStateChange(old_producer_state,
                             impl_->ProducerGetHandleSignalsState());
  return rv;
}

HandleSignalsState DataPipe::ConsumerGetHandleSignalsState() {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_consumer_no_lock());
  return impl_->ConsumerGetHandleSignalsState();
}

MojoResult DataPipe::ConsumerAddAwakable(Awakable* awakable,
                                         uint64_t context,
                                         bool persistent,
                                         MojoHandleSignals signals,
                                         HandleSignalsState* signals_state) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_consumer_no_lock());

  HandleSignalsState consumer_state = impl_->ConsumerGetHandleSignalsState();
  if (signals_state)
    *signals_state = consumer_state;
  MojoResult rv = MOJO_RESULT_OK;
  bool should_add = persistent;
  if (consumer_state.satisfies(signals))
    rv = MOJO_RESULT_ALREADY_EXISTS;
  else if (!consumer_state.can_satisfy(signals))
    rv = MOJO_RESULT_FAILED_PRECONDITION;
  else
    should_add = true;

  if (should_add) {
    consumer_awakable_list_->Add(awakable, context, persistent, signals,
                                 consumer_state);
  }
  return rv;
}

void DataPipe::ConsumerRemoveAwakable(bool match_context,
                                      Awakable* awakable,
                                      uint64_t context,
                                      HandleSignalsState* signals_state) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_consumer_no_lock());
  consumer_awakable_list_->Remove(match_context, awakable, context);
  if (signals_state)
    *signals_state = impl_->ConsumerGetHandleSignalsState();
}

void DataPipe::ConsumerStartSerialize(Channel* channel,
                                      size_t* max_size,
                                      size_t* max_platform_handles) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_consumer_no_lock());
  impl_->ConsumerStartSerialize(channel, max_size, max_platform_handles);
}

bool DataPipe::ConsumerEndSerialize(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    std::vector<ScopedPlatformHandle>* platform_handles) {
  MutexLocker locker(&mutex_);
  DCHECK(has_local_consumer_no_lock());
  // Warning: After |ConsumerEndSerialize()|, quite probably |impl_| has
  // changed.
  bool rv = impl_->ConsumerEndSerialize(channel, destination, actual_size,
                                        platform_handles);

  ConsumerCancelAllStateNoLock();
  consumer_awakable_list_.reset();
  if (!has_local_producer_no_lock())
    consumer_open_ = false;

  return rv;
}

DataPipe::DataPipe(bool has_local_producer,
                   bool has_local_consumer,
                   const MojoCreateDataPipeOptions& validated_options,
                   std::unique_ptr<DataPipeImpl> impl)
    : element_num_bytes_(validated_options.element_num_bytes),
      capacity_num_bytes_(validated_options.capacity_num_bytes),
      producer_open_(true),
      consumer_open_(true),
      producer_write_threshold_num_bytes_(0),
      consumer_read_threshold_num_bytes_(0),
      producer_awakable_list_(has_local_producer ? new AwakableList()
                                                 : nullptr),
      consumer_awakable_list_(has_local_consumer ? new AwakableList()
                                                 : nullptr),
      producer_two_phase_max_num_bytes_written_(0),
      consumer_two_phase_max_num_bytes_read_(0),
      impl_(std::move(impl)) {
  impl_->set_owner(this);

#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  // Check that the passed in options actually are validated.
  MojoCreateDataPipeOptions unused = {};
  DCHECK_EQ(ValidateCreateOptions(MakeUserPointer(&validated_options), &unused),
            MOJO_RESULT_OK);
#endif  // !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
}

DataPipe::~DataPipe() {
  DCHECK(!producer_open_);
  DCHECK(!consumer_open_);
  DCHECK(!producer_awakable_list_);
  DCHECK(!consumer_awakable_list_);
}

std::unique_ptr<DataPipeImpl> DataPipe::ReplaceImplNoLock(
    std::unique_ptr<DataPipeImpl> new_impl) {
  mutex_.AssertHeld();
  DCHECK(new_impl);

  impl_->set_owner(nullptr);
  std::unique_ptr<DataPipeImpl> rv(std::move(impl_));
  impl_ = std::move(new_impl);
  impl_->set_owner(this);
  return rv;
}

void DataPipe::ProducerCancelAllStateNoLock() {
  DCHECK(has_local_producer_no_lock());
  if (producer_awakable_list_)
    producer_awakable_list_->CancelAndRemoveAll();
  // Not a bug, except possibly in "user" code.
  DVLOG_IF(2, producer_in_two_phase_write_no_lock())
      << "Active two-phase write cancelled";
  producer_two_phase_max_num_bytes_written_ = 0;
}

void DataPipe::ConsumerCancelAllStateNoLock() {
  DCHECK(has_local_consumer_no_lock());
  if (consumer_awakable_list_)
    consumer_awakable_list_->CancelAndRemoveAll();
  // Not a bug, except possibly in "user" code.
  DVLOG_IF(2, consumer_in_two_phase_read_no_lock())
      << "Active two-phase read cancelled";
  consumer_two_phase_max_num_bytes_read_ = 0;
}

void DataPipe::SetProducerClosedNoLock() {
  mutex_.AssertHeld();
  DCHECK(!has_local_producer_no_lock());
  DCHECK(producer_open_);
  producer_open_ = false;
}

void DataPipe::SetConsumerClosedNoLock() {
  mutex_.AssertHeld();
  DCHECK(!has_local_consumer_no_lock());
  DCHECK(consumer_open_);
  consumer_open_ = false;
}

void DataPipe::ProducerCloseNoLock() {
  mutex_.AssertHeld();
  DCHECK(producer_open_);
  HandleSignalsState old_consumer_state =
      impl_->ConsumerGetHandleSignalsState();
  producer_open_ = false;
  if (has_local_producer_no_lock()) {
    ProducerCancelAllStateNoLock();
    producer_awakable_list_.reset();
    impl_->ProducerClose();
  }
  OnConsumerMaybeStateChange(old_consumer_state,
                             impl_->ConsumerGetHandleSignalsState());
}

void DataPipe::ConsumerCloseNoLock() {
  mutex_.AssertHeld();
  DCHECK(consumer_open_);
  HandleSignalsState old_producer_state =
      impl_->ProducerGetHandleSignalsState();
  consumer_open_ = false;
  if (has_local_consumer_no_lock()) {
    ConsumerCancelAllStateNoLock();
    consumer_awakable_list_.reset();
    impl_->ConsumerClose();
  }
  OnProducerMaybeStateChange(old_producer_state,
                             impl_->ProducerGetHandleSignalsState());
}

bool DataPipe::OnReadMessage(unsigned port, MessageInTransit* message) {
  MutexLocker locker(&mutex_);
  DCHECK(!has_local_producer_no_lock() || !has_local_consumer_no_lock());

  HandleSignalsState old_producer_state =
      impl_->ProducerGetHandleSignalsState();
  HandleSignalsState old_consumer_state =
      impl_->ConsumerGetHandleSignalsState();

  bool rv = impl_->OnReadMessage(port, message);

  OnProducerMaybeStateChange(old_producer_state,
                             impl_->ProducerGetHandleSignalsState());
  OnConsumerMaybeStateChange(old_consumer_state,
                             impl_->ConsumerGetHandleSignalsState());

  return rv;
}

void DataPipe::OnDetachFromChannel(unsigned port) {
  MutexLocker locker(&mutex_);
  DCHECK(!has_local_producer_no_lock() || !has_local_consumer_no_lock());

  HandleSignalsState old_producer_state =
      impl_->ProducerGetHandleSignalsState();
  HandleSignalsState old_consumer_state =
      impl_->ConsumerGetHandleSignalsState();

  impl_->OnDetachFromChannel(port);

  OnProducerMaybeStateChange(old_producer_state,
                             impl_->ProducerGetHandleSignalsState());
  OnConsumerMaybeStateChange(old_consumer_state,
                             impl_->ConsumerGetHandleSignalsState());
}

void DataPipe::OnProducerMaybeStateChange(
    const HandleSignalsState& old_producer_state,
    const HandleSignalsState& new_producer_state) {
  mutex_.AssertHeld();
  if (!new_producer_state.equals(old_producer_state) &&
      has_local_producer_no_lock()) {
    producer_awakable_list_->OnStateChange(old_producer_state,
                                           new_producer_state);
  }
}

void DataPipe::OnConsumerMaybeStateChange(
    const HandleSignalsState& old_consumer_state,
    const HandleSignalsState& new_consumer_state) {
  mutex_.AssertHeld();
  if (!new_consumer_state.equals(old_consumer_state) &&
      has_local_consumer_no_lock()) {
    consumer_awakable_list_->OnStateChange(old_consumer_state,
                                           new_consumer_state);
  }
}

void DataPipe::SetProducerClosed() {
  MutexLocker locker(&mutex_);
  SetProducerClosedNoLock();
}

void DataPipe::SetConsumerClosed() {
  MutexLocker locker(&mutex_);
  SetConsumerClosedNoLock();
}

}  // namespace system
}  // namespace mojo
