// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/data_pipe_consumer_dispatcher.h"

#include "base/logging.h"
#include "mojo/edk/system/data_pipe.h"
#include "mojo/edk/system/memory.h"

namespace mojo {
namespace system {

void DataPipeConsumerDispatcher::Init(scoped_refptr<DataPipe> data_pipe) {
  DCHECK(data_pipe);
  data_pipe_ = data_pipe;
}

Dispatcher::Type DataPipeConsumerDispatcher::GetType() const {
  return Type::DATA_PIPE_CONSUMER;
}

// static
scoped_refptr<DataPipeConsumerDispatcher>
DataPipeConsumerDispatcher::Deserialize(Channel* channel,
                                        const void* source,
                                        size_t size) {
  scoped_refptr<DataPipe> data_pipe;
  if (!DataPipe::ConsumerDeserialize(channel, source, size, &data_pipe))
    return nullptr;
  DCHECK(data_pipe);

  scoped_refptr<DataPipeConsumerDispatcher> dispatcher = Create();
  dispatcher->Init(data_pipe);
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

void DataPipeConsumerDispatcher::CancelAllAwakablesNoLock() {
  mutex().AssertHeld();
  data_pipe_->ConsumerCancelAllAwakables();
}

void DataPipeConsumerDispatcher::CloseImplNoLock() {
  mutex().AssertHeld();
  data_pipe_->ConsumerClose();
  data_pipe_ = nullptr;
}

scoped_refptr<Dispatcher>
DataPipeConsumerDispatcher::CreateEquivalentDispatcherAndCloseImplNoLock() {
  mutex().AssertHeld();

  scoped_refptr<DataPipeConsumerDispatcher> rv = Create();
  rv->Init(data_pipe_);
  data_pipe_ = nullptr;
  return scoped_refptr<Dispatcher>(rv.get());
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
  if ((flags & MOJO_READ_DATA_FLAG_DISCARD) ||
      (flags & MOJO_READ_DATA_FLAG_QUERY) || (flags & MOJO_READ_DATA_FLAG_PEEK))
    return MOJO_RESULT_INVALID_ARGUMENT;

  return data_pipe_->ConsumerBeginReadData(
      buffer, buffer_num_bytes, (flags & MOJO_READ_DATA_FLAG_ALL_OR_NONE));
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
    MojoHandleSignals signals,
    uint32_t context,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();
  return data_pipe_->ConsumerAddAwakable(awakable, signals, context,
                                         signals_state);
}

void DataPipeConsumerDispatcher::RemoveAwakableImplNoLock(
    Awakable* awakable,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();
  data_pipe_->ConsumerRemoveAwakable(awakable, signals_state);
}

void DataPipeConsumerDispatcher::StartSerializeImplNoLock(
    Channel* channel,
    size_t* max_size,
    size_t* max_platform_handles) {
  DCHECK(HasOneRef());  // Only one ref => no need to take the lock.
  data_pipe_->ConsumerStartSerialize(channel, max_size, max_platform_handles);
}

bool DataPipeConsumerDispatcher::EndSerializeAndCloseImplNoLock(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    embedder::PlatformHandleVector* platform_handles) {
  DCHECK(HasOneRef());  // Only one ref => no need to take the lock.

  bool rv = data_pipe_->ConsumerEndSerialize(channel, destination, actual_size,
                                             platform_handles);
  data_pipe_ = nullptr;
  return rv;
}

bool DataPipeConsumerDispatcher::IsBusyNoLock() const {
  mutex().AssertHeld();
  return data_pipe_->ConsumerIsBusy();
}

}  // namespace system
}  // namespace mojo
