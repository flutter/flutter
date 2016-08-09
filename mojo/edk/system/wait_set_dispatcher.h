// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_WAIT_SET_DISPATCHER_H_
#define MOJO_EDK_SYSTEM_WAIT_SET_DISPATCHER_H_

#include <map>
#include <memory>

#include "mojo/edk/system/awakable.h"
#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/util/cond_var.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

// This is the |Dispatcher| implementation for wait sets (created by the Mojo
// primitive |MojoCreateWaitSet()|). This class is thread-safe.
// TODO(vtl): We rely on |Dispatcher| itself never acquiring any other mutex
// under |mutex()|. We should specify (and double-check) this requirement.
class WaitSetDispatcher final : public Dispatcher, public Awakable {
 public:
  // The default/standard rights for a wait set handle. Note that wait set
  // handles are not transferrable.
  // TODO(vtl): Figure out if these are the correct rights. (E.g., we currently
  // don't have get/set options functions ... but maybe we should?)
  static constexpr MojoHandleRights kDefaultHandleRights =
      MOJO_HANDLE_RIGHT_READ | MOJO_HANDLE_RIGHT_WRITE |
      MOJO_HANDLE_RIGHT_GET_OPTIONS | MOJO_HANDLE_RIGHT_SET_OPTIONS;

  // The default options to use for |MojoCreateWaitSet()|. (Real uses should
  // obtain this via |ValidateCreateOptions()| with a null |in_options|; this is
  // exposed directly for testing convenience.)
  static const MojoCreateWaitSetOptions kDefaultCreateOptions;

  // Validates and/or sets default options for |MojoCreateWaitSetOptions|. If
  // non-null, |in_options| must point to a struct of at least
  // |in_options->struct_size| bytes. |out_options| must point to a (current)
  // |MojoCreateWaitSetOptions| and will be entirely overwritten on success (it
  // may be partly overwritten on failure).
  static MojoResult ValidateCreateOptions(
      UserPointer<const MojoCreateWaitSetOptions> in_options,
      MojoCreateWaitSetOptions* out_options);

  // Like |ValidateCreateOptions()|, but for |MojoWaitSetAddOptions|.
  static MojoResult ValidateWaitSetAddOptions(
      UserPointer<const MojoWaitSetAddOptions> in_options,
      MojoWaitSetAddOptions* out_options);

  static util::RefPtr<WaitSetDispatcher> Create(
      const MojoCreateWaitSetOptions& /*validated_options*/) {
    return AdoptRef(new WaitSetDispatcher());
  }

  // |Dispatcher| public methods:
  Type GetType() const override;
  bool SupportsEntrypointClass(EntrypointClass entrypoint_class) const override;

 private:
  // Represents an entry in the wait set.
  struct Entry {
    Entry(util::RefPtr<Dispatcher>&& dispatcher,
          MojoHandleSignals signals,
          uint64_t cookie);
    ~Entry();

    // |dispatcher| is only null for an |Entry| in |WaitSetDispatcher::entries_|
    // if the dispatcher was closed.
    util::RefPtr<Dispatcher> dispatcher;
    const MojoHandleSignals signals;
    const uint64_t cookie;

    // This is false until |WaitSetDispatcher::WaitSetAddImpl()| is "finished"
    // adding it. |...::WaitSetRemoveImpl()| won't acknowledge the existence of
    // this entry until this is true.
    bool ready = false;

    // This is set only "inside" |WaitSetDispatcher::WaitSetRemoveImpl()|: Since
    // we can only call |dispatcher|'s |RemoveAwakable()| with |mutex()|
    // unlocked, we may get awoken before that happens. So instead of removing
    // the entry from |entries_| immediately, we first set this to true under
    // |mutex()|, unlock and call |RemoveAwakable()|, and then reacquire
    // |mutex()| and actually remove the entry.
    bool is_being_removed = false;

    HandleSignalsState signals_state;
    bool is_triggered = false;

    // Only meaningful if |is_triggered| is true. This is used to maintain a
    // doubly linked list of entries that are triggered (for various reasons:
    // being satisfied, being never-satisfiable, being cancelled/closed).
    // |triggered_previous| and |triggered_next| are null if |this| is equal to
    // |WaitSetDispatcher::triggered_head_| and
    // |WaitSetDispatcher::triggered_tail_|, respectively.
    Entry* triggered_previous = nullptr;
    Entry* triggered_next = nullptr;
  };

  WaitSetDispatcher();
  ~WaitSetDispatcher() override;

  // |Dispatcher| protected methods:
  void CloseImplNoLock() override;
  util::RefPtr<Dispatcher> CreateEquivalentDispatcherAndCloseImplNoLock(
      MessagePipe* message_pipe,
      unsigned port) override;
  MojoResult WaitSetAddImpl(
      util::RefPtr<Dispatcher>&& dispatcher,
      MojoHandleSignals signals,
      uint64_t cookie,
      UserPointer<const MojoWaitSetAddOptions> options) override;
  MojoResult WaitSetRemoveImpl(uint64_t cookie) override;
  MojoResult WaitSetWaitImpl(MojoDeadline deadline,
                             UserPointer<uint32_t> num_results,
                             UserPointer<MojoWaitSetResult> results,
                             UserPointer<uint32_t> max_results) override;

  // |Awakable| implementation:
  void Awake(uint64_t context,
             AwakeReason reason,
             const HandleSignalsState& signals_state) override;

  void AddTriggeredNoLock(Entry* entry) MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex());
  void RemoveTriggeredNoLock(Entry* entry)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex());

  // Associated to |mutex_|. This should be signaled when |triggered_count_|
  // becomes nonzero or this dispatcher is closed.
  util::CondVar cv_;

  // Map of cookies to entries.
  using CookieToEntryMap = std::map<uint64_t, std::unique_ptr<Entry>>;
  CookieToEntryMap entries_ MOJO_GUARDED_BY(mutex());

  // Intrusive "doubly linked list" (via cookies) of entries that are triggered.
  Entry* triggered_head_ MOJO_GUARDED_BY(mutex()) = nullptr;
  Entry* triggered_tail_ MOJO_GUARDED_BY(mutex()) = nullptr;
  // Size of the above list.
  size_t triggered_count_ MOJO_GUARDED_BY(mutex()) = 0u;

  MOJO_DISALLOW_COPY_AND_ASSIGN(WaitSetDispatcher);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_WAIT_SET_DISPATCHER_H_
