// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/data_pipe_producer_dispatcher.h"

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
constexpr MojoHandleRights DataPipeProducerDispatcher::kDefaultHandleRights;

void DataPipeProducerDispatcher::Init(RefPtr<DataPipe>&& data_pipe) {
  DCHECK(data_pipe);
  data_pipe_ = std::move(data_pipe);
}

Dispatcher::Type DataPipeProducerDispatcher::GetType() const {
  return Type::DATA_PIPE_PRODUCER;
}

bool DataPipeProducerDispatcher::SupportsEntrypointClass(
    EntrypointClass entrypoint_class) const {
  return (entrypoint_class == EntrypointClass::DATA_PIPE_PRODUCER);
}

// static
RefPtr<DataPipeProducerDispatcher> DataPipeProducerDispatcher::Deserialize(
    Channel* channel,
    const void* source,
    size_t size) {
  RefPtr<DataPipe> data_pipe;
  if (!DataPipe::ProducerDeserialize(channel, source, size, &data_pipe))
    return nullptr;
  DCHECK(data_pipe);

  auto dispatcher = DataPipeProducerDispatcher::Create();
  dispatcher->Init(std::move(data_pipe));
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

void DataPipeProducerDispatcher::CancelAllStateNoLock() {
  mutex().AssertHeld();
  data_pipe_->ProducerCancelAllState();
}

void DataPipeProducerDispatcher::CloseImplNoLock() {
  mutex().AssertHeld();
  data_pipe_->ProducerClose();
  data_pipe_ = nullptr;
}

RefPtr<Dispatcher>
DataPipeProducerDispatcher::CreateEquivalentDispatcherAndCloseImplNoLock(
    MessagePipe* /*message_pipe*/,
    unsigned /*port*/) {
  mutex().AssertHeld();

  CancelAllStateNoLock();

  auto dispatcher = DataPipeProducerDispatcher::Create();
  dispatcher->Init(std::move(data_pipe_));
  return dispatcher;
}

MojoResult DataPipeProducerDispatcher::SetDataPipeProducerOptionsImplNoLock(
    UserPointer<const MojoDataPipeProducerOptions> options) {
  mutex().AssertHeld();

  // The default of 0 means 1 element (however big that is).
  uint32_t write_threshold_num_bytes = 0;
  if (!options.IsNull()) {
    UserOptionsReader<MojoDataPipeProducerOptions> reader(options);
    if (!reader.is_valid())
      return MOJO_RESULT_INVALID_ARGUMENT;

    if (!OPTIONS_STRUCT_HAS_MEMBER(MojoDataPipeProducerOptions,
                                   write_threshold_num_bytes, reader))
      return MOJO_RESULT_OK;

    write_threshold_num_bytes = reader.options().write_threshold_num_bytes;
  }

  return data_pipe_->ProducerSetOptions(write_threshold_num_bytes);
}

MojoResult DataPipeProducerDispatcher::GetDataPipeProducerOptionsImplNoLock(
    UserPointer<MojoDataPipeProducerOptions> options,
    uint32_t options_num_bytes) {
  mutex().AssertHeld();

  // Note: If/when |MojoDataPipeProducerOptions| is extended beyond its initial
  // definition, more work will be necessary. (See the definition of
  // |MojoGetDataPipeProducerOptions()| in mojo/public/c/system/data_pipe.h.)
  static_assert(sizeof(MojoDataPipeProducerOptions) == 8u,
                "MojoDataPipeProducerOptions has been extended!");

  if (options_num_bytes < sizeof(MojoDataPipeProducerOptions))
    return MOJO_RESULT_INVALID_ARGUMENT;

  uint32_t write_threshold_num_bytes = 0;
  data_pipe_->ProducerGetOptions(&write_threshold_num_bytes);
  MojoDataPipeProducerOptions model_options = {
      sizeof(MojoDataPipeProducerOptions),  // |struct_size|.
      write_threshold_num_bytes,            // |write_threshold_num_bytes|.
  };
  options.Put(model_options);
  return MOJO_RESULT_OK;
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

  // This flag may not be used in two-phase mode.
  if ((flags & MOJO_WRITE_DATA_FLAG_ALL_OR_NONE))
    return MOJO_RESULT_INVALID_ARGUMENT;

  return data_pipe_->ProducerBeginWriteData(buffer, buffer_num_bytes);
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
    uint64_t context,
    bool persistent,
    MojoHandleSignals signals,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();
  return data_pipe_->ProducerAddAwakable(awakable, context, persistent, signals,
                                         signals_state);
}

void DataPipeProducerDispatcher::RemoveAwakableImplNoLock(
    bool match_context,
    Awakable* awakable,
    uint64_t context,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();
  data_pipe_->ProducerRemoveAwakable(match_context, awakable, context,
                                     signals_state);
}

void DataPipeProducerDispatcher::StartSerializeImplNoLock(
    Channel* channel,
    size_t* max_size,
    size_t* max_platform_handles) {
  AssertHasOneRef();  // Only one ref => no need to take the lock.
  data_pipe_->ProducerStartSerialize(channel, max_size, max_platform_handles);
}

bool DataPipeProducerDispatcher::EndSerializeAndCloseImplNoLock(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    std::vector<ScopedPlatformHandle>* platform_handles) {
  AssertHasOneRef();  // Only one ref => no need to take the lock.

  bool rv = data_pipe_->ProducerEndSerialize(channel, destination, actual_size,
                                             platform_handles);
  data_pipe_ = nullptr;
  return rv;
}

}  // namespace system
}  // namespace mojo
