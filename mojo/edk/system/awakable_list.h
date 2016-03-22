// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_AWAKABLE_LIST_H_
#define MOJO_EDK_SYSTEM_AWAKABLE_LIST_H_

#include <stdint.h>

#include <vector>

#include "mojo/public/c/system/types.h"
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

  void AwakeForStateChange(const HandleSignalsState& state);
  void CancelAll();
  void Add(Awakable* awakable, MojoHandleSignals signals, uint32_t context);
  void Remove(Awakable* awakable);

 private:
  struct AwakeInfo {
    AwakeInfo(Awakable* awakable, MojoHandleSignals signals, uint32_t context)
        : awakable(awakable), signals(signals), context(context) {}

    Awakable* awakable;
    MojoHandleSignals signals;
    uint32_t context;
  };
  using AwakeInfoList = std::vector<AwakeInfo>;

  AwakeInfoList awakables_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(AwakableList);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_AWAKABLE_LIST_H_
