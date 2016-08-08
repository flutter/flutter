// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_AWAKABLE_LIST_H_
#define MOJO_EDK_SYSTEM_AWAKABLE_LIST_H_

#include <stdint.h>

#include <vector>

#include "mojo/public/c/system/handle.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class Awakable;
struct HandleSignalsState;

// |AwakableList| tracks all the |Awakable|s (usually |Waiter|s) that are
// waiting on a given handle/|Dispatcher|. There should be a |AwakableList| for
// each handle that can be waited on (in any way). In the simple case, the
// |AwakableList| is owned by the |Dispatcher|, whereas in more complex cases it
// is owned by the secondary object (see simple_dispatcher.* and the explanatory
// comment in core.cc). This class is thread-unsafe (all concurrent access must
// be protected by some lock).
class AwakableList {
 public:
  AwakableList();
  ~AwakableList();

  void OnStateChange(const HandleSignalsState& old_state,
                     const HandleSignalsState& new_state);
  // This will awake all awakables with |Awakable::AwakeReason::CANCELLED|, and
  // remove all awakes.
  void CancelAndRemoveAll();

  // Adds an awakable, identified by its pointer and its context.
  //
  // An awakable may either be persistent or one-shot (non-persistent).
  //   - A one-shot's |Awake()| will be called at most once per |Add()|, and
  //     will only be called if a watched signal goes from unsatisfied to
  //     satisfied (|Awake()| will be called with reason
  //     |Awakable::AwakeReason::SATISFIED|), all watched signals become
  //     never-satisfiable (|Awakable::AwakeReason::UNSATISFIABLE|), or
  //     |CancelAndRemoveAll()| is called (|Awakable::AwakeReason::CANCELLED|).
  //   - A persistent awakable's |Awake()| will be called inside |Add()| (under
  //     any mutex protecting the |AwakableList()| -- this is similar to
  //     |OnStateChange()|) (with reason |Awakable::AwakeReason::INITIALIZE|),
  //     and then subsequently for all state changes on watched signals
  //     (|Awakable::AwakeReason::CHANGED|) until |CancelAndRemoveAll()| is
  //     called (at which point its |Awake()| will be called a final time with
  //     reason |Awakable::AwakeReason::CANCELLED|).
  void Add(Awakable* awakable,
           uint64_t context,
           bool persistent,
           MojoHandleSignals signals,
           const HandleSignalsState& current_state);

  // Removes all awakables matching the given pointer and, if |match_context| is
  // true, the given context.
  void Remove(bool match_context, Awakable* awakable, uint64_t context);

 private:
  struct AwakeInfo {
    AwakeInfo(Awakable* awakable,
              uint64_t context,
              bool persistent,
              MojoHandleSignals signals)
        : awakable(awakable),
          context(context),
          persistent(persistent),
          signals(signals) {}

    Awakable* awakable;
    uint64_t context;
    bool persistent;
    MojoHandleSignals signals;
  };
  using AwakeInfoList = std::vector<AwakeInfo>;

  AwakeInfoList awakables_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(AwakableList);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_AWAKABLE_LIST_H_
