// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/handle_table.h"

#include <limits>
#include <utility>

#include "base/logging.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/system/handle_transport.h"

using mojo::util::RefPtr;

namespace mojo {
namespace system {

HandleTable::Entry::Entry() : busy(false) {}

HandleTable::Entry::Entry(Handle&& handle)
    : handle(std::move(handle)), busy(false) {}

HandleTable::Entry::~Entry() {
  DCHECK(!busy);
}

HandleTable::HandleTable(size_t max_handle_table_size)
    : max_handle_table_size_(max_handle_table_size),
      next_handle_value_(MOJO_HANDLE_INVALID + 1) {}

HandleTable::~HandleTable() {
  // This should usually not be reached (the only instance should be owned by
  // the singleton |Core|, which lives forever), except in tests.
}

MojoResult HandleTable::GetHandle(MojoHandle handle_value, Handle* handle) {
  DCHECK_NE(handle_value, MOJO_HANDLE_INVALID);
  DCHECK(handle);

  HandleToEntryMap::iterator it = handle_to_entry_map_.find(handle_value);
  if (it == handle_to_entry_map_.end())
    return MOJO_RESULT_INVALID_ARGUMENT;
  if (it->second.busy)
    return MOJO_RESULT_BUSY;
  *handle = it->second.handle;

  return MOJO_RESULT_OK;
}

MojoResult HandleTable::GetAndRemoveHandle(MojoHandle handle_value,
                                           Handle* handle) {
  DCHECK_NE(handle_value, MOJO_HANDLE_INVALID);
  DCHECK(handle);

  HandleToEntryMap::iterator it = handle_to_entry_map_.find(handle_value);
  if (it == handle_to_entry_map_.end())
    return MOJO_RESULT_INVALID_ARGUMENT;
  if (it->second.busy)
    return MOJO_RESULT_BUSY;
  *handle = std::move(it->second.handle);
  handle_to_entry_map_.erase(it);

  return MOJO_RESULT_OK;
}

MojoHandle HandleTable::AddHandle(Handle&& handle) {
  DCHECK(handle);
  return (handle_to_entry_map_.size() < max_handle_table_size_)
             ? AddHandleNoSizeCheck(std::move(handle))
             : MOJO_HANDLE_INVALID;
}

std::pair<MojoHandle, MojoHandle> HandleTable::AddHandlePair(Handle&& handle0,
                                                             Handle&& handle1) {
  DCHECK(handle0);
  DCHECK(handle1);
  return (handle_to_entry_map_.size() + 1u < max_handle_table_size_)
             ? std::make_pair(AddHandleNoSizeCheck(std::move(handle0)),
                              AddHandleNoSizeCheck(std::move(handle1)))
             : std::make_pair(MOJO_HANDLE_INVALID, MOJO_HANDLE_INVALID);
}

bool HandleTable::AddHandleVector(HandleVector* handles,
                                  MojoHandle* handle_values) {
  size_t max_message_num_handles = GetConfiguration().max_message_num_handles;

  DCHECK(handles);
  DCHECK_LE(handles->size(), max_message_num_handles);
  DCHECK(handle_values);
  DCHECK_LT(
      static_cast<uint64_t>(max_handle_table_size_) + max_message_num_handles,
      std::numeric_limits<size_t>::max())
      << "Addition may overflow";

  if (handle_to_entry_map_.size() + handles->size() > max_handle_table_size_)
    return false;

  for (size_t i = 0; i < handles->size(); i++) {
    if (handles->at(i)) {
      handle_values[i] = AddHandleNoSizeCheck(std::move(handles->at(i)));
    } else {
      LOG(WARNING) << "Invalid dispatcher at index " << i;
      handle_values[i] = MOJO_HANDLE_INVALID;
    }
  }
  return true;
}

MojoResult HandleTable::MarkBusyAndStartTransport(
    MojoHandle disallowed_handle,
    const MojoHandle* handle_values,
    uint32_t num_handles,
    std::vector<HandleTransport>* transports) {
  DCHECK_NE(disallowed_handle, MOJO_HANDLE_INVALID);
  DCHECK(handle_values);
  DCHECK_LE(num_handles, GetConfiguration().max_message_num_handles);
  DCHECK(transports);
  DCHECK_EQ(transports->size(), num_handles);

  std::vector<Entry*> entries(num_handles);

  // First verify all the handle values and get their dispatchers.
  uint32_t i;
  MojoResult error_result = MOJO_RESULT_INTERNAL;
  for (i = 0; i < num_handles; i++) {
    // Sending your own handle is not allowed (and, for consistency, returns
    // "busy").
    if (handle_values[i] == disallowed_handle) {
      error_result = MOJO_RESULT_BUSY;
      break;
    }

    HandleToEntryMap::iterator it = handle_to_entry_map_.find(handle_values[i]);
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
    HandleTransport transport =
        Dispatcher::HandleTableAccess::TryStartTransport(entries[i]->handle);
    if (!transport.is_valid()) {
      // Only log for Debug builds, since this is not a problem with the system
      // code, but with user code.
      DLOG(WARNING) << "Likely race condition in user code detected: attempt "
                       "to transfer handle "
                    << handle_values[i]
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

MojoHandle HandleTable::AddHandleNoSizeCheck(Handle&& handle) {
  DCHECK(handle);
  DCHECK_LT(handle_to_entry_map_.size(), max_handle_table_size_);
  DCHECK_NE(next_handle_value_, MOJO_HANDLE_INVALID);

  // TODO(vtl): Maybe we want to do something different/smarter. (Or maybe try
  // assigning randomly?)
  while (handle_to_entry_map_.find(next_handle_value_) !=
         handle_to_entry_map_.end()) {
    next_handle_value_++;
    if (next_handle_value_ == MOJO_HANDLE_INVALID)
      next_handle_value_++;
  }

  MojoHandle new_handle_value = next_handle_value_;
  handle_to_entry_map_[new_handle_value] = Entry(std::move(handle));

  next_handle_value_++;
  if (next_handle_value_ == MOJO_HANDLE_INVALID)
    next_handle_value_++;

  return new_handle_value;
}

void HandleTable::RemoveBusyHandles(const MojoHandle* handle_values,
                                    uint32_t num_handles) {
  DCHECK(handle_values);
  DCHECK_LE(num_handles, GetConfiguration().max_message_num_handles);

  for (uint32_t i = 0; i < num_handles; i++) {
    HandleToEntryMap::iterator it = handle_to_entry_map_.find(handle_values[i]);
    DCHECK(it != handle_to_entry_map_.end());
    DCHECK(it->second.busy);
    it->second.busy = false;  // For the sake of a |DCHECK()|.
    handle_to_entry_map_.erase(it);
  }
}

void HandleTable::RestoreBusyHandles(const MojoHandle* handle_values,
                                     uint32_t num_handles) {
  DCHECK(handle_values);
  DCHECK_LE(num_handles, GetConfiguration().max_message_num_handles);

  for (uint32_t i = 0; i < num_handles; i++) {
    HandleToEntryMap::iterator it = handle_to_entry_map_.find(handle_values[i]);
    DCHECK(it != handle_to_entry_map_.end());
    DCHECK(it->second.busy);
    it->second.busy = false;
  }
}

}  // namespace system
}  // namespace mojo
