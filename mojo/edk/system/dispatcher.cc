// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/dispatcher.h"

#include "base/logging.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/data_pipe_consumer_dispatcher.h"
#include "mojo/edk/system/data_pipe_producer_dispatcher.h"
#include "mojo/edk/system/handle.h"
#include "mojo/edk/system/handle_transport.h"
#include "mojo/edk/system/message_pipe_dispatcher.h"
#include "mojo/edk/system/platform_handle_dispatcher.h"
#include "mojo/edk/system/shared_buffer_dispatcher.h"

using mojo::platform::PlatformSharedBufferMapping;
using mojo::platform::ScopedPlatformHandle;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

namespace test {

// TODO(vtl): Maybe this should be defined in a test-only file instead.
HandleTransport HandleTryStartTransport(const Handle& handle) {
  return Dispatcher::HandleTableAccess::TryStartTransport(handle);
}

}  // namespace test

// TODO(vtl): The thread-safety analyzer isn't smart enough to deal with the
// fact that we give up if |TryLock()| fails.
// static
HandleTransport Dispatcher::HandleTableAccess::TryStartTransport(
    const Handle& handle) MOJO_NO_THREAD_SAFETY_ANALYSIS {
  DCHECK(handle.dispatcher);

  if (!handle.dispatcher->mutex_.TryLock())
    return HandleTransport();

  // We shouldn't race with things that close dispatchers, since closing can
  // only take place either under |handle_table_mutex_| or when the handle is
  // marked as busy.
  DCHECK(!handle.dispatcher->is_closed_);

  return HandleTransport(handle);
}

// static
void Dispatcher::TransportDataAccess::StartSerialize(
    Dispatcher* dispatcher,
    Channel* channel,
    size_t* max_size,
    size_t* max_platform_handles) {
  DCHECK(dispatcher);
  dispatcher->StartSerialize(channel, max_size, max_platform_handles);
}

// static
bool Dispatcher::TransportDataAccess::EndSerializeAndClose(
    Dispatcher* dispatcher,
    Channel* channel,
    void* destination,
    size_t* actual_size,
    std::vector<ScopedPlatformHandle>* platform_handles) {
  DCHECK(dispatcher);
  return dispatcher->EndSerializeAndClose(channel, destination, actual_size,
                                          platform_handles);
}

// static
RefPtr<Dispatcher> Dispatcher::TransportDataAccess::Deserialize(
    Channel* channel,
    int32_t type,
    const void* source,
    size_t size,
    std::vector<ScopedPlatformHandle>* platform_handles) {
  switch (static_cast<Dispatcher::Type>(type)) {
    case Type::UNKNOWN:
      DVLOG(2) << "Deserializing invalid handle";
      return nullptr;
    case Type::MESSAGE_PIPE:
      return MessagePipeDispatcher::Deserialize(channel, source, size);
    case Type::DATA_PIPE_PRODUCER:
      return DataPipeProducerDispatcher::Deserialize(channel, source, size);
    case Type::DATA_PIPE_CONSUMER:
      return DataPipeConsumerDispatcher::Deserialize(channel, source, size);
    case Type::SHARED_BUFFER:
      return SharedBufferDispatcher::Deserialize(channel, source, size,
                                                 platform_handles);
    case Type::PLATFORM_HANDLE:
      return PlatformHandleDispatcher::Deserialize(channel, source, size,
                                                   platform_handles);
  }
  LOG(WARNING) << "Unknown dispatcher type " << type;
  return nullptr;
}

MojoResult Dispatcher::Close() {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  CloseNoLock();
  return MOJO_RESULT_OK;
}

MojoResult Dispatcher::WriteMessage(UserPointer<const void> bytes,
                                    uint32_t num_bytes,
                                    std::vector<HandleTransport>* transports,
                                    MojoWriteMessageFlags flags) {
  DCHECK(!transports ||
         (transports->size() > 0 &&
          transports->size() < GetConfiguration().max_message_num_handles));

  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return WriteMessageImplNoLock(bytes, num_bytes, transports, flags);
}

MojoResult Dispatcher::ReadMessage(UserPointer<void> bytes,
                                   UserPointer<uint32_t> num_bytes,
                                   HandleVector* handles,
                                   uint32_t* num_handles,
                                   MojoReadMessageFlags flags) {
  DCHECK(!num_handles || *num_handles == 0 || (handles && handles->empty()));

  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return ReadMessageImplNoLock(bytes, num_bytes, handles, num_handles, flags);
}

MojoResult Dispatcher::SetDataPipeProducerOptions(
    UserPointer<const MojoDataPipeProducerOptions> options) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return SetDataPipeProducerOptionsImplNoLock(options);
}

MojoResult Dispatcher::GetDataPipeProducerOptions(
    UserPointer<MojoDataPipeProducerOptions> options,
    uint32_t options_num_bytes) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return GetDataPipeProducerOptionsImplNoLock(options, options_num_bytes);
}

MojoResult Dispatcher::WriteData(UserPointer<const void> elements,
                                 UserPointer<uint32_t> num_bytes,
                                 MojoWriteDataFlags flags) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return WriteDataImplNoLock(elements, num_bytes, flags);
}

MojoResult Dispatcher::BeginWriteData(UserPointer<void*> buffer,
                                      UserPointer<uint32_t> buffer_num_bytes,
                                      MojoWriteDataFlags flags) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return BeginWriteDataImplNoLock(buffer, buffer_num_bytes, flags);
}

MojoResult Dispatcher::EndWriteData(uint32_t num_bytes_written) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return EndWriteDataImplNoLock(num_bytes_written);
}

MojoResult Dispatcher::SetDataPipeConsumerOptions(
    UserPointer<const MojoDataPipeConsumerOptions> options) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return SetDataPipeConsumerOptionsImplNoLock(options);
}

MojoResult Dispatcher::GetDataPipeConsumerOptions(
    UserPointer<MojoDataPipeConsumerOptions> options,
    uint32_t options_num_bytes) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return GetDataPipeConsumerOptionsImplNoLock(options, options_num_bytes);
}

MojoResult Dispatcher::ReadData(UserPointer<void> elements,
                                UserPointer<uint32_t> num_bytes,
                                MojoReadDataFlags flags) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return ReadDataImplNoLock(elements, num_bytes, flags);
}

MojoResult Dispatcher::BeginReadData(UserPointer<const void*> buffer,
                                     UserPointer<uint32_t> buffer_num_bytes,
                                     MojoReadDataFlags flags) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return BeginReadDataImplNoLock(buffer, buffer_num_bytes, flags);
}

MojoResult Dispatcher::EndReadData(uint32_t num_bytes_read) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return EndReadDataImplNoLock(num_bytes_read);
}

MojoResult Dispatcher::DuplicateBufferHandle(
    UserPointer<const MojoDuplicateBufferHandleOptions> options,
    RefPtr<Dispatcher>* new_dispatcher) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return DuplicateBufferHandleImplNoLock(options, new_dispatcher);
}

MojoResult Dispatcher::GetBufferInformation(
    UserPointer<MojoBufferInformation> info,
    uint32_t info_num_bytes) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return GetBufferInformationImplNoLock(info, info_num_bytes);
}

MojoResult Dispatcher::MapBuffer(
    uint64_t offset,
    uint64_t num_bytes,
    MojoMapBufferFlags flags,
    std::unique_ptr<PlatformSharedBufferMapping>* mapping) {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return MOJO_RESULT_INVALID_ARGUMENT;

  return MapBufferImplNoLock(offset, num_bytes, flags, mapping);
}

HandleSignalsState Dispatcher::GetHandleSignalsState() const {
  MutexLocker locker(&mutex_);
  if (is_closed_)
    return HandleSignalsState();

  return GetHandleSignalsStateImplNoLock();
}

MojoResult Dispatcher::AddAwakable(Awakable* awakable,
                                   MojoHandleSignals signals,
                                   uint32_t context,
                                   HandleSignalsState* signals_state) {
  MutexLocker locker(&mutex_);
  if (is_closed_) {
    if (signals_state)
      *signals_state = HandleSignalsState();
    return MOJO_RESULT_INVALID_ARGUMENT;
  }

  return AddAwakableImplNoLock(awakable, signals, context, signals_state);
}

void Dispatcher::RemoveAwakable(Awakable* awakable,
                                HandleSignalsState* handle_signals_state) {
  MutexLocker locker(&mutex_);
  if (is_closed_) {
    if (handle_signals_state)
      *handle_signals_state = HandleSignalsState();
    return;
  }

  RemoveAwakableImplNoLock(awakable, handle_signals_state);
}

Dispatcher::Dispatcher() : is_closed_(false) {}

Dispatcher::~Dispatcher() {
  // Make sure that |Close()| was called.
  DCHECK(is_closed_);
}

void Dispatcher::CancelAllAwakablesNoLock() {
  mutex_.AssertHeld();
  DCHECK(is_closed_);
  // By default, waiting isn't supported. Only dispatchers that can be waited on
  // will do something nontrivial.
}

void Dispatcher::CloseImplNoLock() {
  mutex_.AssertHeld();
  DCHECK(is_closed_);
  // This may not need to do anything. Dispatchers should override this to do
  // any actual close-time cleanup necessary.
}

MojoResult Dispatcher::WriteMessageImplNoLock(
    UserPointer<const void> /*bytes*/,
    uint32_t /*num_bytes*/,
    std::vector<HandleTransport>* /*transports*/,
    MojoWriteMessageFlags /*flags*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, not supported. Only needed for message pipe dispatchers.
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::ReadMessageImplNoLock(
    UserPointer<void> /*bytes*/,
    UserPointer<uint32_t> /*num_bytes*/,
    HandleVector* /*handles*/,
    uint32_t* /*num_handles*/,
    MojoReadMessageFlags /*flags*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, not supported. Only needed for message pipe dispatchers.
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::SetDataPipeProducerOptionsImplNoLock(
    UserPointer<const MojoDataPipeProducerOptions> /*options*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::GetDataPipeProducerOptionsImplNoLock(
    UserPointer<MojoDataPipeProducerOptions> /*options*/,
    uint32_t /*options_num_bytes*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::WriteDataImplNoLock(UserPointer<const void> /*elements*/,
                                           UserPointer<uint32_t> /*num_bytes*/,
                                           MojoWriteDataFlags /*flags*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, not supported. Only needed for data pipe dispatchers.
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::BeginWriteDataImplNoLock(
    UserPointer<void*> /*buffer*/,
    UserPointer<uint32_t> /*buffer_num_bytes*/,
    MojoWriteDataFlags /*flags*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, not supported. Only needed for data pipe dispatchers.
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::EndWriteDataImplNoLock(uint32_t /*num_bytes_written*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, not supported. Only needed for data pipe dispatchers.
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::ReadDataImplNoLock(UserPointer<void> /*elements*/,
                                          UserPointer<uint32_t> /*num_bytes*/,
                                          MojoReadDataFlags /*flags*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, not supported. Only needed for data pipe dispatchers.
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::SetDataPipeConsumerOptionsImplNoLock(
    UserPointer<const MojoDataPipeConsumerOptions> /*options*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::GetDataPipeConsumerOptionsImplNoLock(
    UserPointer<MojoDataPipeConsumerOptions> /*options*/,
    uint32_t /*options_num_bytes*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::BeginReadDataImplNoLock(
    UserPointer<const void*> /*buffer*/,
    UserPointer<uint32_t> /*buffer_num_bytes*/,
    MojoReadDataFlags /*flags*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, not supported. Only needed for data pipe dispatchers.
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::EndReadDataImplNoLock(uint32_t /*num_bytes_read*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, not supported. Only needed for data pipe dispatchers.
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::DuplicateBufferHandleImplNoLock(
    UserPointer<const MojoDuplicateBufferHandleOptions> /*options*/,
    RefPtr<Dispatcher>* /*new_dispatcher*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, not supported. Only needed for buffer dispatchers.
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::GetBufferInformationImplNoLock(
    UserPointer<MojoBufferInformation> /*info*/,
    uint32_t /*info_num_bytes*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, not supported. Only needed for buffer dispatchers.
  return MOJO_RESULT_INVALID_ARGUMENT;
}

MojoResult Dispatcher::MapBufferImplNoLock(
    uint64_t /*offset*/,
    uint64_t /*num_bytes*/,
    MojoMapBufferFlags /*flags*/,
    std::unique_ptr<PlatformSharedBufferMapping>* /*mapping*/) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, not supported. Only needed for buffer dispatchers.
  return MOJO_RESULT_INVALID_ARGUMENT;
}

HandleSignalsState Dispatcher::GetHandleSignalsStateImplNoLock() const {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, waiting isn't supported. Only dispatchers that can be waited on
  // will do something nontrivial.
  return HandleSignalsState();
}

MojoResult Dispatcher::AddAwakableImplNoLock(
    Awakable* /*awakable*/,
    MojoHandleSignals /*signals*/,
    uint32_t /*context*/,
    HandleSignalsState* signals_state) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, waiting isn't supported. Only dispatchers that can be waited on
  // will do something nontrivial.
  if (signals_state)
    *signals_state = HandleSignalsState();
  return MOJO_RESULT_FAILED_PRECONDITION;
}

void Dispatcher::RemoveAwakableImplNoLock(Awakable* /*awakable*/,
                                          HandleSignalsState* signals_state) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // By default, waiting isn't supported. Only dispatchers that can be waited on
  // will do something nontrivial.
  if (signals_state)
    *signals_state = HandleSignalsState();
}

void Dispatcher::StartSerializeImplNoLock(Channel* /*channel*/,
                                          size_t* max_size,
                                          size_t* max_platform_handles) {
  AssertHasOneRef();  // Only one ref => no need to take the lock.
  DCHECK(!is_closed_);
  *max_size = 0;
  *max_platform_handles = 0;
}

bool Dispatcher::EndSerializeAndCloseImplNoLock(
    Channel* /*channel*/,
    void* /*destination*/,
    size_t* /*actual_size*/,
    std::vector<ScopedPlatformHandle>* /*platform_handles*/) {
  AssertHasOneRef();  // Only one ref => no need to take the lock.
  DCHECK(is_closed_);
  // By default, serializing isn't supported, so just close.
  CloseImplNoLock();
  return false;
}

bool Dispatcher::IsBusyNoLock() const {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);
  // Most dispatchers support only "atomic" operations, so they are never busy
  // (in this sense).
  return false;
}

void Dispatcher::CloseNoLock() {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);

  is_closed_ = true;
  CancelAllAwakablesNoLock();
  CloseImplNoLock();
}

RefPtr<Dispatcher> Dispatcher::CreateEquivalentDispatcherAndCloseNoLock(
    MessagePipe* message_pipe,
    unsigned port) {
  mutex_.AssertHeld();
  DCHECK(!is_closed_);

  is_closed_ = true;
  return CreateEquivalentDispatcherAndCloseImplNoLock(message_pipe, port);
}

void Dispatcher::StartSerialize(Channel* channel,
                                size_t* max_size,
                                size_t* max_platform_handles) {
  DCHECK(channel);
  DCHECK(max_size);
  DCHECK(max_platform_handles);
  AssertHasOneRef();  // Only one ref => no need to take the lock.
  DCHECK(!is_closed_);
  StartSerializeImplNoLock(channel, max_size, max_platform_handles);
}

bool Dispatcher::EndSerializeAndClose(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    std::vector<ScopedPlatformHandle>* platform_handles) {
  DCHECK(channel);
  DCHECK(actual_size);
  AssertHasOneRef();  // Only one ref => no need to take the lock.
  DCHECK(!is_closed_);

  // Like other |...Close()| methods, we mark ourselves as closed before calling
  // the impl. But there's no need to cancel waiters: we shouldn't have any (and
  // shouldn't be in |Core|'s handle table.
  is_closed_ = true;

#if !defined(NDEBUG)
  // See the comment above |EndSerializeAndCloseImplNoLock()|. In brief: Locking
  // isn't actually needed, but we need to satisfy assertions (which we don't
  // want to remove or weaken).
  MutexLocker locker(&mutex_);
#endif

  return EndSerializeAndCloseImplNoLock(channel, destination, actual_size,
                                        platform_handles);
}

}  // namespace system
}  // namespace mojo
