// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/handle_table.h"

#include <limits>
#include <utility>

#include "base/logging.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/dispatcher.h"

using mojo::util::RefPtr;

namespace mojo {
namespace system {

HandleTable::Entry::Entry() : busy(false) {
}

HandleTable::Entry::Entry(RefPtr<Dispatcher>&& dispatcher)
    : dispatcher(std::move(dispatcher)), busy(false) {}

HandleTable::Entry::~Entry() {
  DCHECK(!busy);
}

HandleTable::HandleTable() : next_handle_(MOJO_HANDLE_INVALID + 1) {
}

HandleTable::~HandleTable() {
  // This should usually not be reached (the only instance should be owned by
  // the singleton |Core|, which lives forever), except in tests.
}

Dispatcher* HandleTable::GetDispatcher(MojoHandle handle) {
  DCHECK_NE(handle, MOJO_HANDLE_INVALID);

  HandleToEntryMap::iterator it = handle_to_entry_map_.find(handle);
  if (it == handle_to_entry_map_.end())
    return nullptr;
  return it->second.dispatcher.get();
}

MojoResult HandleTable::GetAndRemoveDispatcher(MojoHandle handle,
                                               RefPtr<Dispatcher>* dispatcher) {
  DCHECK_NE(handle, MOJO_HANDLE_INVALID);
  DCHECK(dispatcher);

  HandleToEntryMap::iterator it = handle_to_entry_map_.find(handle);
  if (it == handle_to_entry_map_.end())
    return MOJO_RESULT_INVALID_ARGUMENT;
  if (it->second.busy)
    return MOJO_RESULT_BUSY;
  *dispatcher = std::move(it->second.dispatcher);
  handle_to_entry_map_.erase(it);

  return MOJO_RESULT_OK;
}

MojoHandle HandleTable::AddDispatcher(Dispatcher* dispatcher) {
  if (handle_to_entry_map_.size() >= GetConfiguration().max_handle_table_size)
    return MOJO_HANDLE_INVALID;
  return AddDispatcherNoSizeCheck(RefPtr<Dispatcher>(dispatcher));
}

std::pair<MojoHandle, MojoHandle> HandleTable::AddDispatcherPair(
    Dispatcher* dispatcher0,
    Dispatcher* dispatcher1) {
  if (handle_to_entry_map_.size() + 1 >=
      GetConfiguration().max_handle_table_size)
    return std::make_pair(MOJO_HANDLE_INVALID, MOJO_HANDLE_INVALID);
  return std::make_pair(
      AddDispatcherNoSizeCheck(RefPtr<Dispatcher>(dispatcher0)),
      AddDispatcherNoSizeCheck(RefPtr<Dispatcher>(dispatcher1)));
}

bool HandleTable::AddDispatcherVector(const DispatcherVector& dispatchers,
                                      MojoHandle* handles) {
  size_t max_message_num_handles = GetConfiguration().max_message_num_handles;
  size_t max_handle_table_size = GetConfiguration().max_handle_table_size;

  DCHECK_LE(dispatchers.size(), max_message_num_handles);
  DCHECK(handles);
  DCHECK_LT(
      static_cast<uint64_t>(max_handle_table_size) + max_message_num_handles,
      std::numeric_limits<size_t>::max())
      << "Addition may overflow";

  if (handle_to_entry_map_.size() + dispatchers.size() > max_handle_table_size)
    return false;

  for (size_t i = 0; i < dispatchers.size(); i++) {
    if (dispatchers[i]) {
      handles[i] = AddDispatcherNoSizeCheck(dispatchers[i].Clone());
    } else {
      LOG(WARNING) << "Invalid dispatcher at index " << i;
      handles[i] = MOJO_HANDLE_INVALID;
    }
  }
  return true;
}

MojoResult HandleTable::MarkBusyAndStartTransport(
    MojoHandle disallowed_handle,
    const MojoHandle* handles,
    uint32_t num_handles,
    std::vector<DispatcherTransport>* transports) {
  DCHECK_NE(disallowed_handle, MOJO_HANDLE_INVALID);
  DCHECK(handles);
  DCHECK_LE(num_handles, GetConfiguration().max_message_num_handles);
  DCHECK(transports);
  DCHECK_EQ(transports->size(), num_handles);

  std::vector<Entry*> entries(num_handles);

  // First verify all the handles and get their dispatchers.
  uint32_t i;
  MojoResult error_result = MOJO_RESULT_INTERNAL;
  for (i = 0; i < num_handles; i++) {
    // Sending your own handle is not allowed (and, for consistency, returns
    // "busy").
    if (handles[i] == disallowed_handle) {
      error_result = MOJO_RESULT_BUSY;
      break;
    }

    HandleToEntryMap::iterator it = handle_to_entry_map_.find(handles[i]);
    if (it == handle_to_entry_map_.end()) {
      error_result = MOJO_RESULT_INVALID_ARGUMENT;
      break;
    }

    entries[i] = &it->second;
    if (entries[i]->busy) {
      error_result = MOJO_RESULT_BUSY;
      break;
    }
    // Note: By marking the handle as busy here, we're also preventing the
    // same handle from being sent multiple times in the same message.
    entries[i]->busy = true;

    // Try to start the transport.
    DispatcherTransport transport =
        Dispatcher::HandleTableAccess::TryStartTransport(
            entries[i]->dispatcher.get());
    if (!transport.is_valid()) {
      // Only log for Debug builds, since this is not a problem with the system
      // code, but with user code.
      DLOG(WARNING) << "Likely race condition in user code detected: attempt "
                       "to transfer handle " << handles[i]
                    << " while it is in use on a different thread";

      // Unset the busy flag (since it won't be unset below).
      entries[i]->busy = false;
      error_result = MOJO_RESULT_BUSY;
      break;
    }

    // Check if the dispatcher is busy (e.g., in a two-phase read/write).
    // (Note that this must be done after the dispatcher's lock is acquired.)
    if (transport.IsBusy()) {
      // Unset the busy flag and end the transport (since it won't be done
      // below).
      entries[i]->busy = false;
      transport.End();
      error_result = MOJO_RESULT_BUSY;
      break;
    }

    // Hang on to the transport (which we'll need to end the transport).
    (*transports)[i] = transport;
  }
  if (i < num_handles) {
    DCHECK_NE(error_result, MOJO_RESULT_INTERNAL);

    // Unset the busy flags and release the locks.
    for (uint32_t j = 0; j < i; j++) {
      DCHECK(entries[j]->busy);
      entries[j]->busy = false;
      (*transports)[j].End();
    }
    return error_result;
  }

  return MOJO_RESULT_OK;
}

MojoHandle HandleTable::AddDispatcherNoSizeCheck(
    RefPtr<Dispatcher>&& dispatcher) {
  DCHECK(dispatcher);
  DCHECK_LT(handle_to_entry_map_.size(),
            GetConfiguration().max_handle_table_size);
  DCHECK_NE(next_handle_, MOJO_HANDLE_INVALID);

  // TODO(vtl): Maybe we want to do something different/smarter. (Or maybe try
  // assigning randomly?)
  while (handle_to_entry_map_.find(next_handle_) !=
         handle_to_entry_map_.end()) {
    next_handle_++;
    if (next_handle_ == MOJO_HANDLE_INVALID)
      next_handle_++;
  }

  MojoHandle new_handle = next_handle_;
  handle_to_entry_map_[new_handle] = Entry(std::move(dispatcher));

  next_handle_++;
  if (next_handle_ == MOJO_HANDLE_INVALID)
    next_handle_++;

  return new_handle;
}

void HandleTable::RemoveBusyHandles(const MojoHandle* handles,
                                    uint32_t num_handles) {
  DCHECK(handles);
  DCHECK_LE(num_handles, GetConfiguration().max_message_num_handles);

  for (uint32_t i = 0; i < num_handles; i++) {
    HandleToEntryMap::iterator it = handle_to_entry_map_.find(handles[i]);
    DCHECK(it != handle_to_entry_map_.end());
    DCHECK(it->second.busy);
    it->second.busy = false;  // For the sake of a |DCHECK()|.
    handle_to_entry_map_.erase(it);
  }
}

void HandleTable::RestoreBusyHandles(const MojoHandle* handles,
                                     uint32_t num_handles) {
  DCHECK(handles);
  DCHECK_LE(num_handles, GetConfiguration().max_message_num_handles);

  for (uint32_t i = 0; i < num_handles; i++) {
    HandleToEntryMap::iterator it = handle_to_entry_map_.find(handles[i]);
    DCHECK(it != handle_to_entry_map_.end());
    DCHECK(it->second.busy);
    it->second.busy = false;
  }
}

}  // namespace system
}  // namespace mojo
