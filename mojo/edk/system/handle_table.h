// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_HANDLE_TABLE_H_
#define MOJO_EDK_SYSTEM_HANDLE_TABLE_H_

#include <unordered_map>
#include <utility>
#include <vector>

#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/c/system/types.h"
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
// (valid) |MojoHandle|s to |Dispatcher|s. This is abstracted so that, e.g.,
// caching may be added.
//
// This class is NOT thread-safe; locking is left to |Core| (since it may need
// to make several changes -- "atomically" or in rapid successsion, in which
// case the extra locking/unlocking would be unnecessary overhead).

class HandleTable {
 public:
  HandleTable();
  ~HandleTable();

  // Gets the dispatcher for a given handle (which should not be
  // |MOJO_HANDLE_INVALID|). Returns null if there's no dispatcher for the given
  // handle.
  // WARNING: For efficiency, this returns a dumb pointer. If you're going to
  // use the result outside |Core|'s lock, you MUST take a reference (e.g., by
  // storing the result inside a |util::RefPtr|).
  Dispatcher* GetDispatcher(MojoHandle handle);

  // On success, gets the dispatcher for a given handle (which should not be
  // |MOJO_HANDLE_INVALID|) and removes it. (On failure, returns an appropriate
  // result (and leaves |dispatcher| alone), namely
  // |MOJO_RESULT_INVALID_ARGUMENT| if there's no dispatcher for the given
  // handle or |MOJO_RESULT_BUSY| if the handle is marked as busy.)
  MojoResult GetAndRemoveDispatcher(MojoHandle handle,
                                    util::RefPtr<Dispatcher>* dispatcher);

  // Adds a dispatcher (which must be valid), returning the handle for it.
  // Returns |MOJO_HANDLE_INVALID| on failure (if the handle table is full).
  MojoHandle AddDispatcher(Dispatcher* dispatcher);

  // Adds a pair of dispatchers (which must be valid), return a pair of handles
  // for them. On failure (if the handle table is full), the first (and second)
  // handles will be |MOJO_HANDLE_INVALID|, and neither dispatcher will be
  // added.
  std::pair<MojoHandle, MojoHandle> AddDispatcherPair(Dispatcher* dispatcher0,
                                                      Dispatcher* dispatcher1);

  // Adds the given vector of dispatchers (of size at most
  // |kMaxMessageNumHandles|). |handles| must point to an array of size at least
  // |dispatchers.size()|. Unlike the other |AddDispatcher...()| functions, some
  // of the dispatchers may be invalid (null). Returns true on success and false
  // on failure (if the handle table is full), in which case it leaves
  // |handles[...]| untouched (and all dispatchers unadded).
  bool AddDispatcherVector(const DispatcherVector& dispatchers,
                           MojoHandle* handles);

  // Tries to mark the given handles as busy and start transport on them (i.e.,
  // take their dispatcher locks); |transports| must be sized to contain
  // |num_handles| elements. On failure, returns them to their original
  // (non-busy, unlocked state).
  MojoResult MarkBusyAndStartTransport(
      MojoHandle disallowed_handle,
      const MojoHandle* handles,
      uint32_t num_handles,
      std::vector<DispatcherTransport>* transports);

  // Remove the given handles, which must all be present and which should have
  // previously been marked busy by |MarkBusyAndStartTransport()|.
  void RemoveBusyHandles(const MojoHandle* handles, uint32_t num_handles);

  // Restores the given handles, which must all be present and which should have
  // previously been marked busy by |MarkBusyAndStartTransport()|, to a non-busy
  // state.
  void RestoreBusyHandles(const MojoHandle* handles, uint32_t num_handles);

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
    explicit Entry(util::RefPtr<Dispatcher>&& dispatcher);
    ~Entry();

    util::RefPtr<Dispatcher> dispatcher;
    bool busy;
  };
  using HandleToEntryMap = std::unordered_map<MojoHandle, Entry>;

  // Adds the given dispatcher to the handle table, not doing any size checks.
  MojoHandle AddDispatcherNoSizeCheck(util::RefPtr<Dispatcher>&& dispatcher);

  HandleToEntryMap handle_to_entry_map_;
  MojoHandle next_handle_;  // Invariant: never |MOJO_HANDLE_INVALID|.

  MOJO_DISALLOW_COPY_AND_ASSIGN(HandleTable);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_HANDLE_TABLE_H_
