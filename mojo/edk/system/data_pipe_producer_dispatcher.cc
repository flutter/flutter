// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/data_pipe_producer_dispatcher.h"

#include "base/logging.h"
#include "mojo/edk/system/data_pipe.h"
#include "mojo/edk/system/memory.h"

namespace mojo {
namespace system {

void DataPipeProducerDispatcher::Init(scoped_refptr<DataPipe> data_pipe) {
  DCHECK(data_pipe);
  data_pipe_ = data_pipe;
}

Dispatcher::Type DataPipeProducerDispatcher::GetType() const {
  return Type::DATA_PIPE_PRODUCER;
}

// static
scoped_refptr<DataPipeProducerDispatcher>
DataPipeProducerDispatcher::Deserialize(Channel* channel,
                                        const void* source,
                                        size_t size) {
  scoped_refptr<DataPipe> data_pipe;
  if (!DataPipe::ProducerDeserialize(channel, source, size, &data_pipe))
    return nullptr;
  DCHECK(data_pipe);

  scoped_refptr<DataPipeProducerDispatcher> dispatcher = Create();
  dispatcher->Init(data_pipe);
  return dispatcher;
}

DataPipe* DataPipeProducerDispatcher::GetDataPipeForTest() {
  MutexLocker locker(&mutex());
  return data_pipe_.get();
}

DataPipeProducerDispatcher::DataPipeProducerDispatcher() {
}

DataPipeProducerDispatcher::~DataPipeProducerDispatcher() {
  // |Close()|/|CloseImplNoLock()| should have taken care of the pipe.
  DCHECK(!data_pipe_);
}

void DataPipeProducerDispatcher::CancelAllAwakablesNoLock() {
  mutex().AssertHeld();
  data_pipe_->ProducerCancelAllAwakables();
}

void DataPipeProducerDispatcher::CloseImplNoLock() {
  mutex().AssertHeld();
  data_pipe_->ProducerClose();
  data_pipe_ = nullptr;
}

scoped_refptr<Dispatcher>
DataPipeProducerDispatcher::CreateEquivalentDispatcherAndCloseImplNoLock() {
  mutex().AssertHeld();

  scoped_refptr<DataPipeProducerDispatcher> rv = Create();
  rv->Init(data_pipe_);
  data_pipe_ = nullptr;
  return scoped_refptr<Dispatcher>(rv.get());
}

MojoResult DataPipeProducerDispatcher::WriteDataImplNoLock(
    UserPointer<const void> elements,
    UserPointer<uint32_t> num_bytes,
    MojoWriteDataFlags flags) {
  mutex().AssertHeld();
  return data_pipe_->ProducerWriteData(
      elements, num_bytes, (flags & MOJO_WRITE_DATA_FLAG_ALL_OR_NONE));
}

MojoResult DataPipeProducerDispatcher::BeginWriteDataImplNoLock(
    UserPointer<void*> buffer,
    UserPointer<uint32_t> buffer_num_bytes,
    MojoWriteDataFlags flags) {
  mutex().AssertHeld();

  return data_pipe_->ProducerBeginWriteData(
      buffer, buffer_num_bytes, (flags & MOJO_WRITE_DATA_FLAG_ALL_OR_NONE));
}

MojoResult DataPipeProducerDispatcher::EndWriteDataImplNoLock(
    uint32_t num_bytes_written) {
  mutex().AssertHeld();

  return data_pipe_->ProducerEndWriteData(num_bytes_written);
}

HandleSignalsState DataPipeProducerDispatcher::GetHandleSignalsStateImplNoLock()
    const {
  mutex().AssertHeld();
  return data_pipe_->ProducerGetHandleSignalsState();
}

MojoResult DataPipeProducerDispatcher::AddAwakableImplNoLock(
    Awakable* awakable,
    MojoHandleSignals signals,
    uint32_t context,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();
  return data_pipe_->ProducerAddAwakable(awakable, signals, context,
                                         signals_state);
}

void DataPipeProducerDispatcher::RemoveAwakableImplNoLock(
    Awakable* awakable,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();
  data_pipe_->ProducerRemoveAwakable(awakable, signals_state);
}

void DataPipeProducerDispatcher::StartSerializeImplNoLock(
    Channel* channel,
    size_t* max_size,
    size_t* max_platform_handles) {
  DCHECK(HasOneRef());  // Only one ref => no need to take the lock.
  data_pipe_->ProducerStartSerialize(channel, max_size, max_platform_handles);
}

bool DataPipeProducerDispatcher::EndSerializeAndCloseImplNoLock(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    embedder::PlatformHandleVector* platform_handles) {
  DCHECK(HasOneRef());  // Only one ref => no need to take the lock.

  bool rv = data_pipe_->ProducerEndSerialize(channel, destination, actual_size,
                                             platform_handles);
  data_pipe_ = nullptr;
  return rv;
}

bool DataPipeProducerDispatcher::IsBusyNoLock() const {
  mutex().AssertHeld();
  return data_pipe_->ProducerIsBusy();
}

}  // namespace system
}  // namespace mojo
