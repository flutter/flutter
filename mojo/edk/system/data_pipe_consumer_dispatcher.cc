// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/data_pipe_consumer_dispatcher.h"

#include <utility>

#include "base/logging.h"
#include "mojo/edk/system/data_pipe.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/options_validation.h"

using mojo::platform::ScopedPlatformHandle;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

// static
constexpr MojoHandleRights DataPipeConsumerDispatcher::kDefaultHandleRights;

void DataPipeConsumerDispatcher::Init(RefPtr<DataPipe>&& data_pipe) {
  DCHECK(data_pipe);
  data_pipe_ = std::move(data_pipe);
}

Dispatcher::Type DataPipeConsumerDispatcher::GetType() const {
  return Type::DATA_PIPE_CONSUMER;
}

bool DataPipeConsumerDispatcher::SupportsEntrypointClass(
    EntrypointClass entrypoint_class) const {
  return (entrypoint_class == EntrypointClass::NONE ||
          entrypoint_class == EntrypointClass::DATA_PIPE_CONSUMER);
}

// static
RefPtr<DataPipeConsumerDispatcher> DataPipeConsumerDispatcher::Deserialize(
    Channel* channel,
    const void* source,
    size_t size) {
  RefPtr<DataPipe> data_pipe;
  if (!DataPipe::ConsumerDeserialize(channel, source, size, &data_pipe))
    return nullptr;
  DCHECK(data_pipe);

  auto dispatcher = DataPipeConsumerDispatcher::Create();
  dispatcher->Init(std::move(data_pipe));
  return dispatcher;
}

DataPipe* DataPipeConsumerDispatcher::GetDataPipeForTest() {
  MutexLocker locker(&mutex());
  return data_pipe_.get();
}

DataPipeConsumerDispatcher::DataPipeConsumerDispatcher() {
}

DataPipeConsumerDispatcher::~DataPipeConsumerDispatcher() {
  // |Close()|/|CloseImplNoLock()| should have taken care of the pipe.
  DCHECK(!data_pipe_);
}

void DataPipeConsumerDispatcher::CancelAllStateNoLock() {
  mutex().AssertHeld();
  data_pipe_->ConsumerCancelAllState();
}

void DataPipeConsumerDispatcher::CloseImplNoLock() {
  mutex().AssertHeld();
  data_pipe_->ConsumerClose();
  data_pipe_ = nullptr;
}

RefPtr<Dispatcher>
DataPipeConsumerDispatcher::CreateEquivalentDispatcherAndCloseImplNoLock(
    MessagePipe* /*message_pipe*/,
    unsigned /*port*/) {
  mutex().AssertHeld();

  CancelAllStateNoLock();

  auto dispatcher = DataPipeConsumerDispatcher::Create();
  dispatcher->Init(std::move(data_pipe_));
  return dispatcher;
}

MojoResult DataPipeConsumerDispatcher::SetDataPipeConsumerOptionsImplNoLock(
    UserPointer<const MojoDataPipeConsumerOptions> options) {
  mutex().AssertHeld();

  // The default of 0 means 1 element (however big that is).
  uint32_t read_threshold_num_bytes = 0;
  if (!options.IsNull()) {
    UserOptionsReader<MojoDataPipeConsumerOptions> reader(options);
    if (!reader.is_valid())
      return MOJO_RESULT_INVALID_ARGUMENT;

    if (!OPTIONS_STRUCT_HAS_MEMBER(MojoDataPipeConsumerOptions,
                                   read_threshold_num_bytes, reader))
      return MOJO_RESULT_OK;

    read_threshold_num_bytes = reader.options().read_threshold_num_bytes;
  }

  return data_pipe_->ConsumerSetOptions(read_threshold_num_bytes);
}

MojoResult DataPipeConsumerDispatcher::GetDataPipeConsumerOptionsImplNoLock(
    UserPointer<MojoDataPipeConsumerOptions> options,
    uint32_t options_num_bytes) {
  mutex().AssertHeld();

  // Note: If/when |MojoDataPipeConsumerOptions| is extended beyond its initial
  // definition, more work will be necessary. (See the definition of
  // |MojoGetDataPipeConsumerOptions()| in mojo/public/c/system/data_pipe.h.)
  static_assert(sizeof(MojoDataPipeConsumerOptions) == 8u,
                "MojoDataPipeConsumerOptions has been extended!");

  if (options_num_bytes < sizeof(MojoDataPipeConsumerOptions))
    return MOJO_RESULT_INVALID_ARGUMENT;

  uint32_t read_threshold_num_bytes = 0;
  data_pipe_->ConsumerGetOptions(&read_threshold_num_bytes);
  MojoDataPipeConsumerOptions model_options = {
      sizeof(MojoDataPipeConsumerOptions),  // |struct_size|.
      read_threshold_num_bytes,             // |read_threshold_num_bytes|.
  };
  options.Put(model_options);
  return MOJO_RESULT_OK;
}

MojoResult DataPipeConsumerDispatcher::ReadDataImplNoLock(
    UserPointer<void> elements,
    UserPointer<uint32_t> num_bytes,
    MojoReadDataFlags flags) {
  mutex().AssertHeld();

  if ((flags & MOJO_READ_DATA_FLAG_DISCARD)) {
    // These flags are mutally exclusive.
    if ((flags & MOJO_READ_DATA_FLAG_QUERY) ||
        (flags & MOJO_READ_DATA_FLAG_PEEK))
      return MOJO_RESULT_INVALID_ARGUMENT;
    DVLOG_IF(2, !elements.IsNull())
        << "Discard mode: ignoring non-null |elements|";
    return data_pipe_->ConsumerDiscardData(
        num_bytes, (flags & MOJO_READ_DATA_FLAG_ALL_OR_NONE));
  }

  if ((flags & MOJO_READ_DATA_FLAG_QUERY)) {
    if ((flags & MOJO_READ_DATA_FLAG_PEEK))
      return MOJO_RESULT_INVALID_ARGUMENT;
    DCHECK(!(flags & MOJO_READ_DATA_FLAG_DISCARD));  // Handled above.
    DVLOG_IF(2, !elements.IsNull())
        << "Query mode: ignoring non-null |elements|";
    return data_pipe_->ConsumerQueryData(num_bytes);
  }

  return data_pipe_->ConsumerReadData(
      elements, num_bytes, !!(flags & MOJO_READ_DATA_FLAG_ALL_OR_NONE),
      !!(flags & MOJO_READ_DATA_FLAG_PEEK));
}

MojoResult DataPipeConsumerDispatcher::BeginReadDataImplNoLock(
    UserPointer<const void*> buffer,
    UserPointer<uint32_t> buffer_num_bytes,
    MojoReadDataFlags flags) {
  mutex().AssertHeld();

  // These flags may not be used in two-phase mode.
  if ((flags & MOJO_READ_DATA_FLAG_ALL_OR_NONE) ||
      (flags & MOJO_READ_DATA_FLAG_DISCARD) ||
      (flags & MOJO_READ_DATA_FLAG_QUERY) || (flags & MOJO_READ_DATA_FLAG_PEEK))
    return MOJO_RESULT_INVALID_ARGUMENT;

  return data_pipe_->ConsumerBeginReadData(buffer, buffer_num_bytes);
}

MojoResult DataPipeConsumerDispatcher::EndReadDataImplNoLock(
    uint32_t num_bytes_read) {
  mutex().AssertHeld();

  return data_pipe_->ConsumerEndReadData(num_bytes_read);
}

HandleSignalsState DataPipeConsumerDispatcher::GetHandleSignalsStateImplNoLock()
    const {
  mutex().AssertHeld();
  return data_pipe_->ConsumerGetHandleSignalsState();
}

MojoResult DataPipeConsumerDispatcher::AddAwakableImplNoLock(
    Awakable* awakable,
    uint64_t context,
    bool persistent,
    MojoHandleSignals signals,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();
  return data_pipe_->ConsumerAddAwakable(awakable, context, persistent, signals,
                                         signals_state);
}

void DataPipeConsumerDispatcher::RemoveAwakableImplNoLock(
    bool match_context,
    Awakable* awakable,
    uint64_t context,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();
  data_pipe_->ConsumerRemoveAwakable(match_context, awakable, context,
                                     signals_state);
}

void DataPipeConsumerDispatcher::StartSerializeImplNoLock(
    Channel* channel,
    size_t* max_size,
    size_t* max_platform_handles) {
  AssertHasOneRef();  // Only one ref => no need to take the lock.
  data_pipe_->ConsumerStartSerialize(channel, max_size, max_platform_handles);
}

bool DataPipeConsumerDispatcher::EndSerializeAndCloseImplNoLock(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    std::vector<ScopedPlatformHandle>* platform_handles) {
  AssertHasOneRef();  // Only one ref => no need to take the lock.

  bool rv = data_pipe_->ConsumerEndSerialize(channel, destination, actual_size,
                                             platform_handles);
  data_pipe_ = nullptr;
  return rv;
}

}  // namespace system
}  // namespace mojo
