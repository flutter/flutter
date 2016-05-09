// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_HANDLE_TABLE_H_
#define MOJO_EDK_SYSTEM_HANDLE_TABLE_H_

#include <stddef.h>

#include <unordered_map>
#include <utility>
#include <vector>

#include "mojo/edk/system/handle.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/c/system/handle.h"
#include "mojo/public/c/system/result.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class Core;
class Dispatcher;
class HandleTransport;

// Test-only function (defined/used in embedder/test_embedder.cc). Declared here
// so it can be friended.
namespace internal {
bool ShutdownCheckNoLeaks(Core*);
}

// This class provides the (global) handle table (owned by |Core|), which maps
// (valid) |MojoHandle|s to |Handle|s (basically, |Dispatcher|s plus rights).
// This is abstracted so that, e.g., caching may be added.
//
// This class is NOT thread-safe; locking is left to |Core| (since it may need
// to make several changes -- "atomically" or in rapid successsion, in which
// case the extra locking/unlocking would be unnecessary overhead).
class HandleTable {
 public:
  explicit HandleTable(size_t max_handle_table_size);
  ~HandleTable();

  // On success, gets the handle for the given handle value (which should not be
  // |MOJO_HANDLE_INVALID|). On failure, returns an appropriate result (and
  // leaves |*handle| alone), namely |MOJO_RESULT_INVALID_ARGUMENT| if there's
  // no handle for the given handle value or |MOJO_RESULT_BUSY| if the handle is
  // marked as busy.
  MojoResult GetHandle(MojoHandle handle_value, Handle* handle);

  // Like |GetHandle()|, but on success also removes the handle value from the
  // handle table.
  MojoResult GetAndRemoveHandle(MojoHandle handle_value, Handle* handle);

  // Adds a handle (which must have a dispatcher), returning the handle value
  // for it. Returns |MOJO_HANDLE_INVALID| on failure (if the handle table is
  // full).
  MojoHandle AddHandle(Handle&& handle);

  // Adds a pair of handles (both of which must be valid), returning a pair of
  // handle values for them. On failure (if the handle table is full), the
  // (first and second) handle values will be |MOJO_HANDLE_INVALID|, and neither
  // dispatcher will be added.
  std::pair<MojoHandle, MojoHandle> AddHandlePair(Handle&& handle0,
                                                  Handle&& handle1);

  // Adds the given vector of handles (of size at most
  // |kMaxMessageNumHandles|). |handle_values| must point to an array of size at
  // least |handles->size()|. Unlike the other |AddHandle...()| functions, some
  // of the handles may be invalid ("null"). Returns true on success in which
  // case all the handles in |*handles| are moved from, and false on failure (if
  // the handle table is full), in which case it leaves all |handles->at(...)||
  // (and all the handles unadded) and |handle_values[...]| untouched.
  bool AddHandleVector(HandleVector* handles, MojoHandle* handle_values);

  // Tries to mark the given handle values as busy and start transport on them
  // (i.e., take their dispatcher locks); |transports| must be sized to contain
  // |num_handles| elements. On failure, returns them to their original
  // (non-busy, unlocked state).
  MojoResult MarkBusyAndStartTransport(
      MojoHandle disallowed_handle,
      const MojoHandle* handle_values,
      uint32_t num_handles,
      std::vector<HandleTransport>* transports);

  // Remove the given handle values, which must all be present and which should
  // have previously been marked busy by |MarkBusyAndStartTransport()|.
  void RemoveBusyHandles(const MojoHandle* handle_values, uint32_t num_handles);

  // Restores the given handle values, which must all be present and which
  // should have previously been marked busy by |MarkBusyAndStartTransport()|,
  // to a non-busy state.
  void RestoreBusyHandles(const MojoHandle* handle_values,
                          uint32_t num_handles);

 private:
  friend bool internal::ShutdownCheckNoLeaks(Core*);

  // The |busy| member is used only to deal with functions (in particular
  // |Core::WriteMessage()|) that want to hold on to a dispatcher and later
  // remove it from the handle table, without holding on to the handle table
  // lock.
  //
  // For example, if |Core::WriteMessage()| is called with a handle to be sent,
  // (under the handle table lock) it must first check that that handle is not
  // busy (if it is busy, then it fails with |MOJO_RESULT_BUSY|) and then marks
  // it as busy. To avoid deadlock, it should also try to acquire the locks for
  // all the dispatchers for the handles that it is sending (and fail with
  // |MOJO_RESULT_BUSY| if the attempt fails). At this point, it can release the
  // handle table lock.
  //
  // If |Core::Close()| is simultaneously called on that handle, it too checks
  // if the handle is marked busy. If it is, it fails (with |MOJO_RESULT_BUSY|).
  // This prevents |Core::WriteMessage()| from sending a handle that has been
  // closed (or learning about this too late).
  struct Entry {
    Entry();
    explicit Entry(Handle&& handle);
    ~Entry();

    Handle handle;
    bool busy;
  };
  using HandleToEntryMap = std::unordered_map<MojoHandle, Entry>;

  // Adds the given handle to the handle table, not doing any size checks.
  MojoHandle AddHandleNoSizeCheck(Handle&& handle);

  const size_t max_handle_table_size_;
  HandleToEntryMap handle_to_entry_map_;
  MojoHandle next_handle_value_;  // Invariant: never |MOJO_HANDLE_INVALID|.

  MOJO_DISALLOW_COPY_AND_ASSIGN(HandleTable);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_HANDLE_TABLE_H_
