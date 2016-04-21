// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_HANDLE_TABLE_H_
#define MOJO_EDK_SYSTEM_HANDLE_TABLE_H_

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
class DispatcherTransport;

using DispatcherVector = std::vector<util::RefPtr<Dispatcher>>;

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
  HandleTable();
  ~HandleTable();

  // TODO(vtl): Replace the dispatcher-only methods with ones that either take a
  // handle, or ones that deal in dispatchers *and* rights. (E.g., it might be
  // convenient for there to be a "GetDispatcher()" that automatically does
  // rights-checking.)

  // On success, gets the dispatcher for a given handle value (which should not
  // be |MOJO_HANDLE_INVALID|). On failure, returns an appropriate result (and
  // leaves |dispatcher| alone), namely |MOJO_RESULT_INVALID_ARGUMENT| if
  // there's no dispatcher for the given handle value or |MOJO_RESULT_BUSY| if
  // the handle value is marked as busy.
  MojoResult GetDispatcher(MojoHandle handle_value,
                           util::RefPtr<Dispatcher>* dispatcher);

  // Like |GetDispatcher()|, but on success also removes the handle value from
  // the handle table.
  MojoResult GetAndRemoveDispatcher(MojoHandle handle_value,
                                    util::RefPtr<Dispatcher>* dispatcher);

  // Adds a dispatcher (which must be valid), returning the handle value for it.
  // Returns |MOJO_HANDLE_INVALID| on failure (if the handle table is full).
  MojoHandle AddDispatcher(Dispatcher* dispatcher);

  // Adds a pair of dispatchers (which must be valid), return a pair of handle
  // values for them. On failure (if the handle table is full), the (first and
  // second) handle values will be |MOJO_HANDLE_INVALID|, and neither dispatcher
  // will be added.
  std::pair<MojoHandle, MojoHandle> AddDispatcherPair(Dispatcher* dispatcher0,
                                                      Dispatcher* dispatcher1);

  // Adds the given vector of dispatchers (of size at most
  // |kMaxMessageNumHandles|). |handle_values| must point to an array of size at
  // least |dispatchers.size()|. Unlike the other |AddDispatcher...()|
  // functions, some of the dispatchers may be invalid (null). Returns true on
  // success and false on failure (if the handle table is full), in which case
  // it leaves |handle_values[...]| untouched (and all dispatchers unadded).
  bool AddDispatcherVector(const DispatcherVector& dispatchers,
                           MojoHandle* handle_values);

  // Tries to mark the given handle values as busy and start transport on them
  // (i.e., take their dispatcher locks); |transports| must be sized to contain
  // |num_handles| elements. On failure, returns them to their original
  // (non-busy, unlocked state).
  MojoResult MarkBusyAndStartTransport(
      MojoHandle disallowed_handle,
      const MojoHandle* handle_values,
      uint32_t num_handles,
      std::vector<DispatcherTransport>* transports);

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
    util::RefPtr<Dispatcher> dispatcher;
    bool busy;
  };
  using HandleToEntryMap = std::unordered_map<MojoHandle, Entry>;

  // Adds the given handle to the handle table, not doing any size checks.
  MojoHandle AddHandleNoSizeCheck(Handle&& handle);

  HandleToEntryMap handle_to_entry_map_;
  MojoHandle next_handle_value_;  // Invariant: never |MOJO_HANDLE_INVALID|.

  MOJO_DISALLOW_COPY_AND_ASSIGN(HandleTable);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_HANDLE_TABLE_H_
