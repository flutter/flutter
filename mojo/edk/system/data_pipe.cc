// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/data_pipe.h"

#include <string.h>

#include <algorithm>
#include <limits>

#include "base/logging.h"
#include "base/memory/aligned_memory.h"
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
DataPipe* DataPipe::CreateLocal(
    const MojoCreateDataPipeOptions& validated_options) {
  return new DataPipe(true, true, validated_options,
                      make_scoped_ptr(new LocalDataPipeImpl()));
}

// static
DataPipe* DataPipe::CreateRemoteProducerFromExisting(
    const MojoCreateDataPipeOptions& validated_options,
    MessageInTransitQueue* message_queue,
    ChannelEndpoint* channel_endpoint) {
  scoped_ptr<char, base::AlignedFreeDeleter> buffer;
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
  DataPipe* data_pipe =
      new DataPipe(false, true, validated_options,
                   make_scoped_ptr(new RemoteProducerDataPipeImpl(
                       channel_endpoint, buffer.Pass(), 0, buffer_num_bytes)));
  if (channel_endpoint) {
    if (!channel_endpoint->ReplaceClient(data_pipe, 0))
      data_pipe->OnDetachFromChannel(0);
  } else {
    data_pipe->SetProducerClosed();
  }
  return data_pipe;
}

// static
DataPipe* DataPipe::CreateRemoteConsumerFromExisting(
    const MojoCreateDataPipeOptions& validated_options,
    size_t consumer_num_bytes,
    MessageInTransitQueue* message_queue,
    ChannelEndpoint* channel_endpoint) {
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
  DataPipe* data_pipe =
      new DataPipe(true, false, validated_options,
                   make_scoped_ptr(new RemoteConsumerDataPipeImpl(
                       channel_endpoint, consumer_num_bytes)));
  if (channel_endpoint) {
    if (!channel_endpoint->ReplaceClient(data_pipe, 0))
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
                                   scoped_refptr<DataPipe>* data_pipe) {
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

    *data_pipe = new DataPipe(
        true, false, revalidated_options,
        make_scoped_ptr(new RemoteConsumerDataPipeImpl(nullptr, 0)));
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
  scoped_refptr<IncomingEndpoint> incoming_endpoint =
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
                                   scoped_refptr<DataPipe>* data_pipe) {
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
  scoped_refptr<IncomingEndpoint> incoming_endpoint =
      channel->DeserializeEndpoint(endpoint_source);
  if (!incoming_endpoint)
    return false;

  *data_pipe =
      incoming_endpoint->ConvertToDataPipeConsumer(revalidated_options);
  if (!*data_pipe)
    return false;

  return true;
}

void DataPipe::ProducerCancelAllAwakables() {
  base::AutoLock locker(lock_);
  DCHECK(has_local_producer_no_lock());
  producer_awakable_list_->CancelAll();
}

void DataPipe::ProducerClose() {
  base::AutoLock locker(lock_);
  ProducerCloseNoLock();
}

MojoResult DataPipe::ProducerWriteData(UserPointer<const void> elements,
                                       UserPointer<uint32_t> num_bytes,
                                       bool all_or_none) {
  base::AutoLock locker(lock_);
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
  HandleSignalsState new_consumer_state =
      impl_->ConsumerGetHandleSignalsState();
  if (!new_consumer_state.equals(old_consumer_state))
    AwakeConsumerAwakablesForStateChangeNoLock(new_consumer_state);
  return rv;
}

MojoResult DataPipe::ProducerBeginWriteData(
    UserPointer<void*> buffer,
    UserPointer<uint32_t> buffer_num_bytes,
    bool all_or_none) {
  base::AutoLock locker(lock_);
  DCHECK(has_local_producer_no_lock());

  if (producer_in_two_phase_write_no_lock())
    return MOJO_RESULT_BUSY;
  if (!consumer_open_no_lock())
    return MOJO_RESULT_FAILED_PRECONDITION;

  uint32_t min_num_bytes_to_write = 0;
  if (all_or_none) {
    min_num_bytes_to_write = buffer_num_bytes.Get();
    if (min_num_bytes_to_write % element_num_bytes() != 0)
      return MOJO_RESULT_INVALID_ARGUMENT;
  }

  MojoResult rv = impl_->ProducerBeginWriteData(buffer, buffer_num_bytes,
                                                min_num_bytes_to_write);
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
  base::AutoLock locker(lock_);
  DCHECK(has_local_producer_no_lock());

  if (!producer_in_two_phase_write_no_lock())
    return MOJO_RESULT_FAILED_PRECONDITION;
  // Note: Allow successful completion of the two-phase write even if the
  // consumer has been closed.

  HandleSignalsState old_consumer_state =
      impl_->ConsumerGetHandleSignalsState();
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
  HandleSignalsState new_producer_state =
      impl_->ProducerGetHandleSignalsState();
  if (new_producer_state.satisfies(MOJO_HANDLE_SIGNAL_WRITABLE))
    AwakeProducerAwakablesForStateChangeNoLock(new_producer_state);
  HandleSignalsState new_consumer_state =
      impl_->ConsumerGetHandleSignalsState();
  if (!new_consumer_state.equals(old_consumer_state))
    AwakeConsumerAwakablesForStateChangeNoLock(new_consumer_state);
  return rv;
}

HandleSignalsState DataPipe::ProducerGetHandleSignalsState() {
  base::AutoLock locker(lock_);
  DCHECK(has_local_producer_no_lock());
  return impl_->ProducerGetHandleSignalsState();
}

MojoResult DataPipe::ProducerAddAwakable(Awakable* awakable,
                                         MojoHandleSignals signals,
                                         uint32_t context,
                                         HandleSignalsState* signals_state) {
  base::AutoLock locker(lock_);
  DCHECK(has_local_producer_no_lock());

  HandleSignalsState producer_state = impl_->ProducerGetHandleSignalsState();
  if (producer_state.satisfies(signals)) {
    if (signals_state)
      *signals_state = producer_state;
    return MOJO_RESULT_ALREADY_EXISTS;
  }
  if (!producer_state.can_satisfy(signals)) {
    if (signals_state)
      *signals_state = producer_state;
    return MOJO_RESULT_FAILED_PRECONDITION;
  }

  producer_awakable_list_->Add(awakable, signals, context);
  return MOJO_RESULT_OK;
}

void DataPipe::ProducerRemoveAwakable(Awakable* awakable,
                                      HandleSignalsState* signals_state) {
  base::AutoLock locker(lock_);
  DCHECK(has_local_producer_no_lock());
  producer_awakable_list_->Remove(awakable);
  if (signals_state)
    *signals_state = impl_->ProducerGetHandleSignalsState();
}

void DataPipe::ProducerStartSerialize(Channel* channel,
                                      size_t* max_size,
                                      size_t* max_platform_handles) {
  base::AutoLock locker(lock_);
  DCHECK(has_local_producer_no_lock());
  impl_->ProducerStartSerialize(channel, max_size, max_platform_handles);
}

bool DataPipe::ProducerEndSerialize(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    embedder::PlatformHandleVector* platform_handles) {
  base::AutoLock locker(lock_);
  DCHECK(has_local_producer_no_lock());
  // Warning: After |ProducerEndSerialize()|, quite probably |impl_| has
  // changed.
  bool rv = impl_->ProducerEndSerialize(channel, destination, actual_size,
                                        platform_handles);

  // TODO(vtl): The code below is similar to, but not quite the same as,
  // |ProducerCloseNoLock()|.
  DCHECK(has_local_producer_no_lock());
  producer_awakable_list_->CancelAll();
  producer_awakable_list_.reset();
  // Not a bug, except possibly in "user" code.
  DVLOG_IF(2, producer_in_two_phase_write_no_lock())
      << "Producer transferred with active two-phase write";
  producer_two_phase_max_num_bytes_written_ = 0;
  if (!has_local_consumer_no_lock())
    producer_open_ = false;

  return rv;
}

bool DataPipe::ProducerIsBusy() const {
  base::AutoLock locker(lock_);
  return producer_in_two_phase_write_no_lock();
}

void DataPipe::ConsumerCancelAllAwakables() {
  base::AutoLock locker(lock_);
  DCHECK(has_local_consumer_no_lock());
  consumer_awakable_list_->CancelAll();
}

void DataPipe::ConsumerClose() {
  base::AutoLock locker(lock_);
  ConsumerCloseNoLock();
}

MojoResult DataPipe::ConsumerReadData(UserPointer<void> elements,
                                      UserPointer<uint32_t> num_bytes,
                                      bool all_or_none,
                                      bool peek) {
  base::AutoLock locker(lock_);
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
  HandleSignalsState new_producer_state =
      impl_->ProducerGetHandleSignalsState();
  if (!new_producer_state.equals(old_producer_state))
    AwakeProducerAwakablesForStateChangeNoLock(new_producer_state);
  return rv;
}

MojoResult DataPipe::ConsumerDiscardData(UserPointer<uint32_t> num_bytes,
                                         bool all_or_none) {
  base::AutoLock locker(lock_);
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
  HandleSignalsState new_producer_state =
      impl_->ProducerGetHandleSignalsState();
  if (!new_producer_state.equals(old_producer_state))
    AwakeProducerAwakablesForStateChangeNoLock(new_producer_state);
  return rv;
}

MojoResult DataPipe::ConsumerQueryData(UserPointer<uint32_t> num_bytes) {
  base::AutoLock locker(lock_);
  DCHECK(has_local_consumer_no_lock());

  if (consumer_in_two_phase_read_no_lock())
    return MOJO_RESULT_BUSY;

  // Note: Don't need to validate |*num_bytes| for query.
  return impl_->ConsumerQueryData(num_bytes);
}

MojoResult DataPipe::ConsumerBeginReadData(
    UserPointer<const void*> buffer,
    UserPointer<uint32_t> buffer_num_bytes,
    bool all_or_none) {
  base::AutoLock locker(lock_);
  DCHECK(has_local_consumer_no_lock());

  if (consumer_in_two_phase_read_no_lock())
    return MOJO_RESULT_BUSY;

  uint32_t min_num_bytes_to_read = 0;
  if (all_or_none) {
    min_num_bytes_to_read = buffer_num_bytes.Get();
    if (min_num_bytes_to_read % element_num_bytes() != 0)
      return MOJO_RESULT_INVALID_ARGUMENT;
  }

  MojoResult rv = impl_->ConsumerBeginReadData(buffer, buffer_num_bytes,
                                               min_num_bytes_to_read);
  if (rv != MOJO_RESULT_OK)
    return rv;
  DCHECK(consumer_in_two_phase_read_no_lock());
  return MOJO_RESULT_OK;
}

MojoResult DataPipe::ConsumerEndReadData(uint32_t num_bytes_read) {
  base::AutoLock locker(lock_);
  DCHECK(has_local_consumer_no_lock());

  if (!consumer_in_two_phase_read_no_lock())
    return MOJO_RESULT_FAILED_PRECONDITION;

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
  HandleSignalsState new_consumer_state =
      impl_->ConsumerGetHandleSignalsState();
  if (new_consumer_state.satisfies(MOJO_HANDLE_SIGNAL_READABLE))
    AwakeConsumerAwakablesForStateChangeNoLock(new_consumer_state);
  HandleSignalsState new_producer_state =
      impl_->ProducerGetHandleSignalsState();
  if (!new_producer_state.equals(old_producer_state))
    AwakeProducerAwakablesForStateChangeNoLock(new_producer_state);
  return rv;
}

HandleSignalsState DataPipe::ConsumerGetHandleSignalsState() {
  base::AutoLock locker(lock_);
  DCHECK(has_local_consumer_no_lock());
  return impl_->ConsumerGetHandleSignalsState();
}

MojoResult DataPipe::ConsumerAddAwakable(Awakable* awakable,
                                         MojoHandleSignals signals,
                                         uint32_t context,
                                         HandleSignalsState* signals_state) {
  base::AutoLock locker(lock_);
  DCHECK(has_local_consumer_no_lock());

  HandleSignalsState consumer_state = impl_->ConsumerGetHandleSignalsState();
  if (consumer_state.satisfies(signals)) {
    if (signals_state)
      *signals_state = consumer_state;
    return MOJO_RESULT_ALREADY_EXISTS;
  }
  if (!consumer_state.can_satisfy(signals)) {
    if (signals_state)
      *signals_state = consumer_state;
    return MOJO_RESULT_FAILED_PRECONDITION;
  }

  consumer_awakable_list_->Add(awakable, signals, context);
  return MOJO_RESULT_OK;
}

void DataPipe::ConsumerRemoveAwakable(Awakable* awakable,
                                      HandleSignalsState* signals_state) {
  base::AutoLock locker(lock_);
  DCHECK(has_local_consumer_no_lock());
  consumer_awakable_list_->Remove(awakable);
  if (signals_state)
    *signals_state = impl_->ConsumerGetHandleSignalsState();
}

void DataPipe::ConsumerStartSerialize(Channel* channel,
                                      size_t* max_size,
                                      size_t* max_platform_handles) {
  base::AutoLock locker(lock_);
  DCHECK(has_local_consumer_no_lock());
  impl_->ConsumerStartSerialize(channel, max_size, max_platform_handles);
}

bool DataPipe::ConsumerEndSerialize(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    embedder::PlatformHandleVector* platform_handles) {
  base::AutoLock locker(lock_);
  DCHECK(has_local_consumer_no_lock());
  // Warning: After |ConsumerEndSerialize()|, quite probably |impl_| has
  // changed.
  bool rv = impl_->ConsumerEndSerialize(channel, destination, actual_size,
                                        platform_handles);

  // TODO(vtl): The code below is similar to, but not quite the same as,
  // |ConsumerCloseNoLock()|.
  consumer_awakable_list_->CancelAll();
  consumer_awakable_list_.reset();
  // Not a bug, except possibly in "user" code.
  DVLOG_IF(2, consumer_in_two_phase_read_no_lock())
      << "Consumer transferred with active two-phase read";
  consumer_two_phase_max_num_bytes_read_ = 0;
  if (!has_local_producer_no_lock())
    consumer_open_ = false;

  return rv;
}

bool DataPipe::ConsumerIsBusy() const {
  base::AutoLock locker(lock_);
  return consumer_in_two_phase_read_no_lock();
}

DataPipe::DataPipe(bool has_local_producer,
                   bool has_local_consumer,
                   const MojoCreateDataPipeOptions& validated_options,
                   scoped_ptr<DataPipeImpl> impl)
    : validated_options_(validated_options),
      producer_open_(true),
      consumer_open_(true),
      producer_awakable_list_(has_local_producer ? new AwakableList()
                                                 : nullptr),
      consumer_awakable_list_(has_local_consumer ? new AwakableList()
                                                 : nullptr),
      producer_two_phase_max_num_bytes_written_(0),
      consumer_two_phase_max_num_bytes_read_(0),
      impl_(impl.Pass()) {
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

scoped_ptr<DataPipeImpl> DataPipe::ReplaceImplNoLock(
    scoped_ptr<DataPipeImpl> new_impl) {
  lock_.AssertAcquired();
  DCHECK(new_impl);

  impl_->set_owner(nullptr);
  scoped_ptr<DataPipeImpl> rv(impl_.Pass());
  impl_ = new_impl.Pass();
  impl_->set_owner(this);
  return rv.Pass();
}

void DataPipe::SetProducerClosedNoLock() {
  lock_.AssertAcquired();
  DCHECK(!has_local_producer_no_lock());
  DCHECK(producer_open_);
  producer_open_ = false;
}

void DataPipe::SetConsumerClosedNoLock() {
  lock_.AssertAcquired();
  DCHECK(!has_local_consumer_no_lock());
  DCHECK(consumer_open_);
  consumer_open_ = false;
}

void DataPipe::ProducerCloseNoLock() {
  lock_.AssertAcquired();
  DCHECK(producer_open_);
  producer_open_ = false;
  if (has_local_producer_no_lock()) {
    producer_awakable_list_.reset();
    // Not a bug, except possibly in "user" code.
    DVLOG_IF(2, producer_in_two_phase_write_no_lock())
        << "Producer closed with active two-phase write";
    producer_two_phase_max_num_bytes_written_ = 0;
    impl_->ProducerClose();
    AwakeConsumerAwakablesForStateChangeNoLock(
        impl_->ConsumerGetHandleSignalsState());
  }
}

void DataPipe::ConsumerCloseNoLock() {
  lock_.AssertAcquired();
  DCHECK(consumer_open_);
  consumer_open_ = false;
  if (has_local_consumer_no_lock()) {
    consumer_awakable_list_.reset();
    // Not a bug, except possibly in "user" code.
    DVLOG_IF(2, consumer_in_two_phase_read_no_lock())
        << "Consumer closed with active two-phase read";
    consumer_two_phase_max_num_bytes_read_ = 0;
    impl_->ConsumerClose();
    AwakeProducerAwakablesForStateChangeNoLock(
        impl_->ProducerGetHandleSignalsState());
  }
}

bool DataPipe::OnReadMessage(unsigned port, MessageInTransit* message) {
  base::AutoLock locker(lock_);
  DCHECK(!has_local_producer_no_lock() || !has_local_consumer_no_lock());

  HandleSignalsState old_producer_state =
      impl_->ProducerGetHandleSignalsState();
  HandleSignalsState old_consumer_state =
      impl_->ConsumerGetHandleSignalsState();

  bool rv = impl_->OnReadMessage(port, message);

  HandleSignalsState new_producer_state =
      impl_->ProducerGetHandleSignalsState();
  if (!new_producer_state.equals(old_producer_state))
    AwakeProducerAwakablesForStateChangeNoLock(new_producer_state);
  HandleSignalsState new_consumer_state =
      impl_->ConsumerGetHandleSignalsState();
  if (!new_consumer_state.equals(old_consumer_state))
    AwakeConsumerAwakablesForStateChangeNoLock(new_consumer_state);

  return rv;
}

void DataPipe::OnDetachFromChannel(unsigned port) {
  base::AutoLock locker(lock_);
  DCHECK(!has_local_producer_no_lock() || !has_local_consumer_no_lock());

  HandleSignalsState old_producer_state =
      impl_->ProducerGetHandleSignalsState();
  HandleSignalsState old_consumer_state =
      impl_->ConsumerGetHandleSignalsState();

  impl_->OnDetachFromChannel(port);

  HandleSignalsState new_producer_state =
      impl_->ProducerGetHandleSignalsState();
  if (!new_producer_state.equals(old_producer_state))
    AwakeProducerAwakablesForStateChangeNoLock(new_producer_state);
  HandleSignalsState new_consumer_state =
      impl_->ConsumerGetHandleSignalsState();
  if (!new_consumer_state.equals(old_consumer_state))
    AwakeConsumerAwakablesForStateChangeNoLock(new_consumer_state);
}

void DataPipe::AwakeProducerAwakablesForStateChangeNoLock(
    const HandleSignalsState& new_producer_state) {
  lock_.AssertAcquired();
  if (!has_local_producer_no_lock())
    return;
  producer_awakable_list_->AwakeForStateChange(new_producer_state);
}

void DataPipe::AwakeConsumerAwakablesForStateChangeNoLock(
    const HandleSignalsState& new_consumer_state) {
  lock_.AssertAcquired();
  if (!has_local_consumer_no_lock())
    return;
  consumer_awakable_list_->AwakeForStateChange(new_consumer_state);
}

void DataPipe::SetProducerClosed() {
  base::AutoLock locker(lock_);
  SetProducerClosedNoLock();
}

void DataPipe::SetConsumerClosed() {
  base::AutoLock locker(lock_);
  SetConsumerClosedNoLock();
}

}  // namespace system
}  // namespace mojo
