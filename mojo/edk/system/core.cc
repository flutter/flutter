// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/core.h"

#include <memory>
#include <utility>
#include <vector>

#include "base/logging.h"
#include "mojo/edk/embedder/platform_support.h"
#include "mojo/edk/platform/platform_shared_buffer.h"
#include "mojo/edk/platform/time_ticks.h"
#include "mojo/edk/system/async_waiter.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/data_pipe.h"
#include "mojo/edk/system/data_pipe_consumer_dispatcher.h"
#include "mojo/edk/system/data_pipe_producer_dispatcher.h"
#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/system/handle_signals_state.h"
#include "mojo/edk/system/handle_transport.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/message_pipe_dispatcher.h"
#include "mojo/edk/system/shared_buffer_dispatcher.h"
#include "mojo/edk/system/waiter.h"
#include "mojo/public/c/system/macros.h"
#include "mojo/public/cpp/system/macros.h"

using mojo::platform::GetTimeTicks;
using mojo::platform::PlatformSharedBufferMapping;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

// Implementation notes
//
// Mojo primitives are implemented by the singleton |Core| object. Most calls
// are for a "primary" handle (the first argument). |Core::GetHandle()| is used
// to look up a |Handle| (in particular, a |Dispatcher| object) for a given
// handle value. The |Dispatcher| object implements most primitives for that
// (conceptual/logical) object. The wait primitives are not attached to objects
// and are implemented by |Core| itself.
//
// Some objects have multiple handles associated to them, e.g., message pipes
// (which have two). In such a case, there is still a |Dispatcher| (e.g.,
// |MessagePipeDispatcher|) for each handle, with each handle having a strong
// reference to the common "secondary" object (e.g., |MessagePipe|). This
// secondary object does NOT have any references to the |Dispatcher|s (even if
// it did, it wouldn't be able to do anything with them due to lock order
// requirements -- see below).
//
// Waiting is implemented by having the thread that wants to wait call the
// |Dispatcher|s for the handles that it wants to wait on with a |Waiter|
// object; this |Waiter| object may be created on the stack of that thread or be
// kept in thread local storage for that thread (TODO(vtl): future improvement).
// The |Dispatcher| then adds the |Waiter| to an |AwakableList| that's either
// owned by that |Dispatcher| (see |SimpleDispatcher|) or by a secondary object
// (e.g., |MessagePipe|). To signal/wake a |Waiter|, the object in question --
// either a |SimpleDispatcher| or a secondary object -- talks to its
// |AwakableList|.

// Thread-safety notes
//
// Mojo primitives calls are thread-safe. We achieve this with relatively
// fine-grained locking. There is a global handle table lock. This lock should
// be held as briefly as possible (TODO(vtl): a future improvement would be to
// switch it to a reader-writer lock). Each |Dispatcher| object then has a lock
// (which subclasses can use to protect their data).
//
// The lock ordering is as follows:
//   1. global handle table lock, global mapping table lock
//   2. |Dispatcher| locks
//   3. secondary object locks
//   ...
//   INF. |Waiter| locks
//
// Notes:
//    - While holding a |Dispatcher| lock, you may not unconditionally attempt
//      to take another |Dispatcher| lock. (This has consequences on the
//      concurrency semantics of |MojoWriteMessage()| when passing handles.)
//      Doing so would lead to deadlock.
//    - Locks at the "INF" level may not have any locks taken while they are
//      held.

Core::Core(embedder::PlatformSupport* platform_support)
    : platform_support_(platform_support),
      handle_table_(GetConfiguration().max_handle_table_size) {}

Core::~Core() {}

MojoHandle Core::AddHandle(Handle&& handle) {
  MutexLocker locker(&handle_table_mutex_);
  return handle_table_.AddHandle(std::move(handle));
}

MojoResult Core::GetHandle(MojoHandle handle, Handle* h) {
  if (handle == MOJO_HANDLE_INVALID)
    return MOJO_RESULT_INVALID_ARGUMENT;

  MutexLocker locker(&handle_table_mutex_);
  return handle_table_.GetHandle(handle, h);
}

MojoResult Core::GetAndRemoveHandle(MojoHandle handle, Handle* h) {
  if (handle == MOJO_HANDLE_INVALID)
    return MOJO_RESULT_INVALID_ARGUMENT;

  MutexLocker locker(&handle_table_mutex_);
  return handle_table_.GetAndRemoveHandle(handle, h);
}

MojoResult Core::GetDispatcherAndCheckRights(
    MojoHandle handle,
    MojoHandleRights required_handle_rights,
    EntrypointClass entrypoint_class,
    util::RefPtr<Dispatcher>* dispatcher) {
  if (handle == MOJO_HANDLE_INVALID)
    return MOJO_RESULT_INVALID_ARGUMENT;

  Handle h;
  MojoResult result = GetHandle(handle, &h);
  if (result != MOJO_RESULT_OK)
    return result;

  if (!h.has_all_rights(required_handle_rights)) {
    return h.dispatcher->SupportsEntrypointClass(entrypoint_class)
               ? MOJO_RESULT_PERMISSION_DENIED
               : MOJO_RESULT_INVALID_ARGUMENT;
  }

  *dispatcher = std::move(h.dispatcher);
  return MOJO_RESULT_OK;
}

MojoResult Core::AsyncWait(MojoHandle handle,
                           MojoHandleSignals signals,
                           const std::function<void(MojoResult)>& callback) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result = GetDispatcherAndCheckRights(
      handle, MOJO_HANDLE_RIGHT_NONE, EntrypointClass::NONE, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  std::unique_ptr<AsyncWaiter> waiter(new AsyncWaiter(callback));
  result = dispatcher->AddAwakable(waiter.get(), signals, 0, nullptr);
  if (result == MOJO_RESULT_OK)
    ignore_result(waiter.release());
  return result;
}

MojoTimeTicks Core::GetTimeTicksNow() {
  return GetTimeTicks();
}

MojoResult Core::Close(MojoHandle handle) {
  if (handle == MOJO_HANDLE_INVALID)
    return MOJO_RESULT_INVALID_ARGUMENT;

  Handle h;
  {
    MutexLocker locker(&handle_table_mutex_);
    MojoResult result = handle_table_.GetAndRemoveHandle(handle, &h);
    if (result != MOJO_RESULT_OK)
      return result;
  }

  // The dispatcher doesn't have a say in being closed, but gets notified of it.
  // Note: This is done outside of |handle_table_mutex_|. As a result, there's a
  // race condition that the dispatcher must handle; see the comment in
  // |Dispatcher| in dispatcher.h.
  return h.dispatcher->Close();
}

MojoResult Core::GetRights(MojoHandle handle,
                           UserPointer<MojoHandleRights> rights) {
  Handle h;
  MojoResult result = GetHandle(handle, &h);
  if (result != MOJO_RESULT_OK)
    return result;

  rights.Put(h.rights);
  return MOJO_RESULT_OK;
}

MojoResult Core::DuplicateHandleWithReducedRights(
    MojoHandle handle,
    MojoHandleRights rights_to_remove,
    UserPointer<MojoHandle> new_handle) {
  Handle h;
  MojoResult result = GetHandle(handle, &h);
  if (result != MOJO_RESULT_OK)
    return result;

  if (!h.has_all_rights(MOJO_HANDLE_RIGHT_DUPLICATE))
    return MOJO_RESULT_PERMISSION_DENIED;

  RefPtr<Dispatcher> new_dispatcher;
  result = h.dispatcher->DuplicateDispatcher(&new_dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  MojoHandle new_handle_value =
      AddHandle(Handle(new_dispatcher.Clone(), h.rights & ~rights_to_remove));
  if (new_handle_value == MOJO_HANDLE_INVALID) {
    LOG(ERROR) << "Handle table full";
    new_dispatcher->Close();
    return MOJO_RESULT_RESOURCE_EXHAUSTED;
  }

  new_handle.Put(new_handle_value);
  return MOJO_RESULT_OK;
}

MojoResult Core::Wait(MojoHandle handle,
                      MojoHandleSignals signals,
                      MojoDeadline deadline,
                      UserPointer<MojoHandleSignalsState> signals_state) {
  uint32_t unused = static_cast<uint32_t>(-1);
  HandleSignalsState hss;
  MojoResult result = WaitManyInternal(&handle, &signals, 1, deadline, &unused,
                                       signals_state.IsNull() ? nullptr : &hss);
  if (result != MOJO_RESULT_INVALID_ARGUMENT && !signals_state.IsNull())
    signals_state.Put(hss);
  return result;
}

MojoResult Core::WaitMany(UserPointer<const MojoHandle> handles,
                          UserPointer<const MojoHandleSignals> signals,
                          uint32_t num_handles,
                          MojoDeadline deadline,
                          UserPointer<uint32_t> result_index,
                          UserPointer<MojoHandleSignalsState> signals_states) {
  if (num_handles < 1)
    return MOJO_RESULT_INVALID_ARGUMENT;
  if (num_handles > GetConfiguration().max_wait_many_num_handles)
    return MOJO_RESULT_RESOURCE_EXHAUSTED;

  UserPointer<const MojoHandle>::Reader handles_reader(handles, num_handles);
  UserPointer<const MojoHandleSignals>::Reader signals_reader(signals,
                                                              num_handles);
  uint32_t index = static_cast<uint32_t>(-1);
  MojoResult result;
  if (signals_states.IsNull()) {
    result = WaitManyInternal(handles_reader.GetPointer(),
                              signals_reader.GetPointer(), num_handles,
                              deadline, &index, nullptr);
  } else {
    UserPointer<MojoHandleSignalsState>::Writer signals_states_writer(
        signals_states, num_handles);
    // Note: The |reinterpret_cast| is safe, since |HandleSignalsState| is a
    // subclass of |MojoHandleSignalsState| that doesn't add any data members.
    result = WaitManyInternal(
        handles_reader.GetPointer(), signals_reader.GetPointer(), num_handles,
        deadline, &index, reinterpret_cast<HandleSignalsState*>(
                              signals_states_writer.GetPointer()));
    if (result != MOJO_RESULT_INVALID_ARGUMENT)
      signals_states_writer.Commit();
  }
  if (index != static_cast<uint32_t>(-1) && !result_index.IsNull())
    result_index.Put(index);
  return result;
}

MojoResult Core::CreateMessagePipe(
    UserPointer<const MojoCreateMessagePipeOptions> options,
    UserPointer<MojoHandle> message_pipe_handle0,
    UserPointer<MojoHandle> message_pipe_handle1) {
  MojoCreateMessagePipeOptions validated_options = {};
  MojoResult result =
      MessagePipeDispatcher::ValidateCreateOptions(options, &validated_options);
  if (result != MOJO_RESULT_OK)
    return result;

  auto dispatcher0 = MessagePipeDispatcher::Create(validated_options);
  auto dispatcher1 = MessagePipeDispatcher::Create(validated_options);

  std::pair<MojoHandle, MojoHandle> handle_pair;
  {
    MutexLocker locker(&handle_table_mutex_);
    handle_pair = handle_table_.AddHandlePair(
        Handle(dispatcher0.Clone(),
               MessagePipeDispatcher::kDefaultHandleRights),
        Handle(dispatcher1.Clone(),
               MessagePipeDispatcher::kDefaultHandleRights));
  }
  if (handle_pair.first == MOJO_HANDLE_INVALID) {
    DCHECK_EQ(handle_pair.second, MOJO_HANDLE_INVALID);
    LOG(ERROR) << "Handle table full";
    dispatcher0->Close();
    dispatcher1->Close();
    return MOJO_RESULT_RESOURCE_EXHAUSTED;
  }

  auto message_pipe = MessagePipe::CreateLocalLocal();
  dispatcher0->Init(message_pipe.Clone(), 0);
  dispatcher1->Init(std::move(message_pipe), 1);

  message_pipe_handle0.Put(handle_pair.first);
  message_pipe_handle1.Put(handle_pair.second);
  return MOJO_RESULT_OK;
}

// Implementation note: To properly cancel waiters and avoid other races, this
// does not transfer dispatchers from one handle to another, even when sending a
// message in-process. Instead, it must transfer the "contents" of the
// dispatcher to a new dispatcher, and then close the old dispatcher. If this
// isn't done, in the in-process case, calls on the old handle may complete
// after the the message has been received and a new handle created (and
// possibly even after calls have been made on the new handle).
MojoResult Core::WriteMessage(MojoHandle message_pipe_handle,
                              UserPointer<const void> bytes,
                              uint32_t num_bytes,
                              UserPointer<const MojoHandle> handles,
                              uint32_t num_handles,
                              MojoWriteMessageFlags flags) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result =
      GetDispatcherAndCheckRights(message_pipe_handle, MOJO_HANDLE_RIGHT_WRITE,
                                  EntrypointClass::MESSAGE_PIPE, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  // Easy case: not sending any handles.
  if (num_handles == 0)
    return dispatcher->WriteMessage(bytes, num_bytes, nullptr, flags);

  // We have to handle |handles| here, since we have to mark them busy in the
  // global handle table. We can't delegate this to the dispatcher, since the
  // handle table lock must be acquired before the dispatcher lock.
  //
  // (This leads to an oddity: |handles|/|num_handles| are always verified for
  // validity, even for dispatchers that don't support |WriteMessage()| and will
  // simply return failure unconditionally. It also breaks the usual
  // left-to-right verification order of arguments.)
  if (num_handles > GetConfiguration().max_message_num_handles)
    return MOJO_RESULT_RESOURCE_EXHAUSTED;

  UserPointer<const MojoHandle>::Reader handles_reader(handles, num_handles);

  // We'll need to hold on to the dispatchers so that we can pass them on to
  // |WriteMessage()| and also so that we can unlock their locks afterwards
  // without accessing the handle table. These can be dumb pointers, since their
  // entries in the handle table won't get removed (since they'll be marked as
  // busy).
  std::vector<HandleTransport> transports(num_handles);

  // When we pass handles, we have to try to take all their dispatchers' locks
  // and mark the handles as busy. If the call succeeds, we then remove the
  // handles from the handle table.
  {
    MutexLocker locker(&handle_table_mutex_);
    MojoResult result = handle_table_.MarkBusyAndStartTransport(
        message_pipe_handle, handles_reader.GetPointer(), num_handles,
        &transports);
    if (result != MOJO_RESULT_OK)
      return result;
  }

  result = dispatcher->WriteMessage(bytes, num_bytes, &transports, flags);

  // We need to release the dispatcher locks before we take the handle table
  // lock.
  for (uint32_t i = 0; i < num_handles; i++)
    transports[i].End();

  {
    MutexLocker locker(&handle_table_mutex_);
    if (result == MOJO_RESULT_OK) {
      handle_table_.RemoveBusyHandles(handles_reader.GetPointer(), num_handles);
    } else {
      handle_table_.RestoreBusyHandles(handles_reader.GetPointer(),
                                       num_handles);
    }
  }

  return result;
}

MojoResult Core::ReadMessage(MojoHandle message_pipe_handle,
                             UserPointer<void> bytes,
                             UserPointer<uint32_t> num_bytes,
                             UserPointer<MojoHandle> handles,
                             UserPointer<uint32_t> num_handles,
                             MojoReadMessageFlags flags) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result =
      GetDispatcherAndCheckRights(message_pipe_handle, MOJO_HANDLE_RIGHT_READ,
                                  EntrypointClass::MESSAGE_PIPE, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  uint32_t num_handles_value = num_handles.IsNull() ? 0 : num_handles.Get();

  if (num_handles_value == 0) {
    // Easy case: won't receive any handles.
    result = dispatcher->ReadMessage(bytes, num_bytes, nullptr,
                                     &num_handles_value, flags);
  } else {
    HandleVector hs;
    result = dispatcher->ReadMessage(bytes, num_bytes, &hs, &num_handles_value,
                                     flags);
    if (!hs.empty()) {
      DCHECK_EQ(result, MOJO_RESULT_OK);
      DCHECK(!num_handles.IsNull());
      DCHECK_LE(hs.size(), static_cast<size_t>(num_handles_value));

      bool success;
      UserPointer<MojoHandle>::Writer handles_writer(handles, hs.size());
      {
        MutexLocker locker(&handle_table_mutex_);
        success =
            handle_table_.AddHandleVector(&hs, handles_writer.GetPointer());
      }
      if (success) {
        handles_writer.Commit();
      } else {
        LOG(ERROR) << "Received message with " << hs.size()
                   << " handles, but handle table full";
        // Close dispatchers (outside the lock).
        for (size_t i = 0; i < hs.size(); i++) {
          if (hs[i])
            hs[i].dispatcher->Close();
        }
        if (result == MOJO_RESULT_OK)
          result = MOJO_RESULT_RESOURCE_EXHAUSTED;
      }
    }
  }

  if (!num_handles.IsNull())
    num_handles.Put(num_handles_value);
  return result;
}

MojoResult Core::CreateDataPipe(
    UserPointer<const MojoCreateDataPipeOptions> options,
    UserPointer<MojoHandle> data_pipe_producer_handle,
    UserPointer<MojoHandle> data_pipe_consumer_handle) {
  MojoCreateDataPipeOptions validated_options = {};
  MojoResult result =
      DataPipe::ValidateCreateOptions(options, &validated_options);
  if (result != MOJO_RESULT_OK)
    return result;

  auto producer_dispatcher = DataPipeProducerDispatcher::Create();
  auto consumer_dispatcher = DataPipeConsumerDispatcher::Create();

  std::pair<MojoHandle, MojoHandle> handle_pair;
  {
    MutexLocker locker(&handle_table_mutex_);
    handle_pair = handle_table_.AddHandlePair(
        Handle(producer_dispatcher.Clone(),
               DataPipeProducerDispatcher::kDefaultHandleRights),
        Handle(consumer_dispatcher.Clone(),
               DataPipeConsumerDispatcher::kDefaultHandleRights));
  }
  if (handle_pair.first == MOJO_HANDLE_INVALID) {
    DCHECK_EQ(handle_pair.second, MOJO_HANDLE_INVALID);
    LOG(ERROR) << "Handle table full";
    producer_dispatcher->Close();
    consumer_dispatcher->Close();
    return MOJO_RESULT_RESOURCE_EXHAUSTED;
  }
  DCHECK_NE(handle_pair.second, MOJO_HANDLE_INVALID);

  auto data_pipe = DataPipe::CreateLocal(validated_options);
  producer_dispatcher->Init(data_pipe.Clone());
  consumer_dispatcher->Init(std::move(data_pipe));

  data_pipe_producer_handle.Put(handle_pair.first);
  data_pipe_consumer_handle.Put(handle_pair.second);
  return MOJO_RESULT_OK;
}

MojoResult Core::SetDataPipeProducerOptions(
    MojoHandle data_pipe_producer_handle,
    UserPointer<const MojoDataPipeProducerOptions> options) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result = GetDispatcherAndCheckRights(
      data_pipe_producer_handle, MOJO_HANDLE_RIGHT_SET_OPTIONS,
      EntrypointClass::DATA_PIPE_PRODUCER, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  return dispatcher->SetDataPipeProducerOptions(options);
}

MojoResult Core::GetDataPipeProducerOptions(
    MojoHandle data_pipe_producer_handle,
    UserPointer<MojoDataPipeProducerOptions> options,
    uint32_t options_num_bytes) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result = GetDispatcherAndCheckRights(
      data_pipe_producer_handle, MOJO_HANDLE_RIGHT_GET_OPTIONS,
      EntrypointClass::DATA_PIPE_PRODUCER, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  return dispatcher->GetDataPipeProducerOptions(options, options_num_bytes);
}

MojoResult Core::WriteData(MojoHandle data_pipe_producer_handle,
                           UserPointer<const void> elements,
                           UserPointer<uint32_t> num_bytes,
                           MojoWriteDataFlags flags) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result = GetDispatcherAndCheckRights(
      data_pipe_producer_handle, MOJO_HANDLE_RIGHT_WRITE,
      EntrypointClass::DATA_PIPE_PRODUCER, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  return dispatcher->WriteData(elements, num_bytes, flags);
}

MojoResult Core::BeginWriteData(MojoHandle data_pipe_producer_handle,
                                UserPointer<void*> buffer,
                                UserPointer<uint32_t> buffer_num_bytes,
                                MojoWriteDataFlags flags) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result = GetDispatcherAndCheckRights(
      data_pipe_producer_handle, MOJO_HANDLE_RIGHT_WRITE,
      EntrypointClass::DATA_PIPE_PRODUCER, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  return dispatcher->BeginWriteData(buffer, buffer_num_bytes, flags);
}

MojoResult Core::EndWriteData(MojoHandle data_pipe_producer_handle,
                              uint32_t num_bytes_written) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result = GetDispatcherAndCheckRights(
      data_pipe_producer_handle, MOJO_HANDLE_RIGHT_WRITE,
      EntrypointClass::DATA_PIPE_PRODUCER, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  return dispatcher->EndWriteData(num_bytes_written);
}

MojoResult Core::SetDataPipeConsumerOptions(
    MojoHandle data_pipe_consumer_handle,
    UserPointer<const MojoDataPipeConsumerOptions> options) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result = GetDispatcherAndCheckRights(
      data_pipe_consumer_handle, MOJO_HANDLE_RIGHT_SET_OPTIONS,
      EntrypointClass::DATA_PIPE_CONSUMER, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  return dispatcher->SetDataPipeConsumerOptions(options);
}

MojoResult Core::GetDataPipeConsumerOptions(
    MojoHandle data_pipe_consumer_handle,
    UserPointer<MojoDataPipeConsumerOptions> options,
    uint32_t options_num_bytes) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result = GetDispatcherAndCheckRights(
      data_pipe_consumer_handle, MOJO_HANDLE_RIGHT_GET_OPTIONS,
      EntrypointClass::DATA_PIPE_CONSUMER, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  return dispatcher->GetDataPipeConsumerOptions(options, options_num_bytes);
}

MojoResult Core::ReadData(MojoHandle data_pipe_consumer_handle,
                          UserPointer<void> elements,
                          UserPointer<uint32_t> num_bytes,
                          MojoReadDataFlags flags) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result = GetDispatcherAndCheckRights(
      data_pipe_consumer_handle, MOJO_HANDLE_RIGHT_READ,
      EntrypointClass::DATA_PIPE_CONSUMER, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  return dispatcher->ReadData(elements, num_bytes, flags);
}

MojoResult Core::BeginReadData(MojoHandle data_pipe_consumer_handle,
                               UserPointer<const void*> buffer,
                               UserPointer<uint32_t> buffer_num_bytes,
                               MojoReadDataFlags flags) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result = GetDispatcherAndCheckRights(
      data_pipe_consumer_handle, MOJO_HANDLE_RIGHT_READ,
      EntrypointClass::DATA_PIPE_CONSUMER, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  return dispatcher->BeginReadData(buffer, buffer_num_bytes, flags);
}

MojoResult Core::EndReadData(MojoHandle data_pipe_consumer_handle,
                             uint32_t num_bytes_read) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result = GetDispatcherAndCheckRights(
      data_pipe_consumer_handle, MOJO_HANDLE_RIGHT_READ,
      EntrypointClass::DATA_PIPE_CONSUMER, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  return dispatcher->EndReadData(num_bytes_read);
}

MojoResult Core::CreateSharedBuffer(
    UserPointer<const MojoCreateSharedBufferOptions> options,
    uint64_t num_bytes,
    UserPointer<MojoHandle> shared_buffer_handle) {
  MojoCreateSharedBufferOptions validated_options = {};
  MojoResult result = SharedBufferDispatcher::ValidateCreateOptions(
      options, &validated_options);
  if (result != MOJO_RESULT_OK)
    return result;

  auto dispatcher = SharedBufferDispatcher::Create(
      platform_support_, validated_options, num_bytes, &result);
  if (result != MOJO_RESULT_OK) {
    DCHECK(!dispatcher);
    return result;
  }

  MojoHandle handle = AddHandle(
      Handle(dispatcher.Clone(), SharedBufferDispatcher::kDefaultHandleRights));
  if (handle == MOJO_HANDLE_INVALID) {
    LOG(ERROR) << "Handle table full";
    dispatcher->Close();
    return MOJO_RESULT_RESOURCE_EXHAUSTED;
  }

  shared_buffer_handle.Put(handle);
  return MOJO_RESULT_OK;
}

MojoResult Core::DuplicateBufferHandle(
    MojoHandle buffer_handle,
    UserPointer<const MojoDuplicateBufferHandleOptions> options,
    UserPointer<MojoHandle> new_buffer_handle) {
  // TODO(vtl): This is a big ugly and duplicates some code, but the plan is to
  // remove this method anyway.
  Handle h;
  MojoResult result = GetHandle(buffer_handle, &h);
  if (result != MOJO_RESULT_OK)
    return result;

  if (!h.has_all_rights(MOJO_HANDLE_RIGHT_DUPLICATE)) {
    return h.dispatcher->SupportsEntrypointClass(EntrypointClass::BUFFER)
               ? MOJO_RESULT_PERMISSION_DENIED
               : MOJO_RESULT_INVALID_ARGUMENT;
  }

  // Don't verify |options| here; that's the dispatcher's job.
  RefPtr<Dispatcher> new_dispatcher;
  result = h.dispatcher->DuplicateBufferHandle(options, &new_dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  MojoHandle new_handle_value =
      AddHandle(Handle(new_dispatcher.Clone(), h.rights));
  if (new_handle_value == MOJO_HANDLE_INVALID) {
    LOG(ERROR) << "Handle table full";
    new_dispatcher->Close();
    return MOJO_RESULT_RESOURCE_EXHAUSTED;
  }

  new_buffer_handle.Put(new_handle_value);
  return MOJO_RESULT_OK;
}

MojoResult Core::GetBufferInformation(MojoHandle buffer_handle,
                                      UserPointer<MojoBufferInformation> info,
                                      uint32_t info_num_bytes) {
  RefPtr<Dispatcher> dispatcher;
  MojoResult result =
      GetDispatcherAndCheckRights(buffer_handle, MOJO_HANDLE_RIGHT_GET_OPTIONS,
                                  EntrypointClass::BUFFER, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  return dispatcher->GetBufferInformation(info, info_num_bytes);
}

MojoResult Core::MapBuffer(MojoHandle buffer_handle,
                           uint64_t offset,
                           uint64_t num_bytes,
                           UserPointer<void*> buffer,
                           MojoMapBufferFlags flags) {
  RefPtr<Dispatcher> dispatcher;
  // TODO(vtl): Currently we can only map read/write. So both
  // |MOJO_HANDLE_RIGHT_MAP_READABLE| and |MOJO_HANDLE_RIGHT_MAP_WRITABLE| are
  // required.
  MojoResult result = GetDispatcherAndCheckRights(
      buffer_handle,
      MOJO_HANDLE_RIGHT_MAP_READABLE | MOJO_HANDLE_RIGHT_MAP_WRITABLE,
      EntrypointClass::BUFFER, &dispatcher);
  if (result != MOJO_RESULT_OK)
    return result;

  std::unique_ptr<PlatformSharedBufferMapping> mapping;
  result = dispatcher->MapBuffer(offset, num_bytes, flags, &mapping);
  if (result != MOJO_RESULT_OK)
    return result;

  DCHECK(mapping);
  void* address = mapping->GetBase();
  {
    MutexLocker locker(&mapping_table_mutex_);
    result = mapping_table_.AddMapping(std::move(mapping));
  }
  if (result != MOJO_RESULT_OK)
    return result;

  buffer.Put(address);
  return MOJO_RESULT_OK;
}

MojoResult Core::UnmapBuffer(UserPointer<void> buffer) {
  MutexLocker locker(&mapping_table_mutex_);
  return mapping_table_.RemoveMapping(buffer.GetPointerValue());
}

// Note: We allow |handles| to repeat the same handle multiple times, since
// different flags may be specified.
// TODO(vtl): This incurs a performance cost in |Remove()|. Analyze this
// more carefully and address it if necessary.
MojoResult Core::WaitManyInternal(const MojoHandle* handles,
                                  const MojoHandleSignals* signals,
                                  uint32_t num_handles,
                                  MojoDeadline deadline,
                                  uint32_t* result_index,
                                  HandleSignalsState* signals_states) {
  DCHECK_GT(num_handles, 0u);
  DCHECK_EQ(*result_index, static_cast<uint32_t>(-1));

  DispatcherVector dispatchers;
  dispatchers.reserve(num_handles);

  {
    MutexLocker locker(&handle_table_mutex_);
    for (uint32_t i = 0; i < num_handles; i++) {
      if (handles[i] == MOJO_HANDLE_INVALID) {
        *result_index = i;
        return MOJO_RESULT_INVALID_ARGUMENT;
      }

      Handle handle;
      MojoResult result = handle_table_.GetHandle(handles[i], &handle);
      if (result != MOJO_RESULT_OK) {
        *result_index = i;
        return result;
      }
      dispatchers.push_back(std::move(handle.dispatcher));
    }
  }

  // TODO(vtl): Should make the waiter live (permanently) in TLS.
  Waiter waiter;
  waiter.Init();

  uint32_t i;
  MojoResult result = MOJO_RESULT_OK;
  for (i = 0; i < num_handles; i++) {
    result = dispatchers[i]->AddAwakable(
        &waiter, signals[i], i, signals_states ? &signals_states[i] : nullptr);
    if (result != MOJO_RESULT_OK) {
      *result_index = i;
      break;
    }
  }
  uint32_t num_added = i;

  if (result == MOJO_RESULT_ALREADY_EXISTS)
    result = MOJO_RESULT_OK;  // The i-th one is already "triggered".
  else if (result == MOJO_RESULT_OK)
    result = waiter.Wait(deadline, result_index);

  // Make sure no other dispatchers try to wake |waiter| for the current
  // |Wait()|/|WaitMany()| call. (Only after doing this can |waiter| be
  // destroyed, but this would still be required if the waiter were in TLS.)
  for (i = 0; i < num_added; i++) {
    dispatchers[i]->RemoveAwakable(
        &waiter, signals_states ? &signals_states[i] : nullptr);
  }
  if (signals_states) {
    for (; i < num_handles; i++)
      signals_states[i] = dispatchers[i]->GetHandleSignalsState();
  }

  return result;
}

}  // namespace system
}  // namespace mojo
