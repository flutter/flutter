// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_SIMPLE_DISPATCHER_H_
#define MOJO_EDK_SYSTEM_SIMPLE_DISPATCHER_H_

#include <list>

#include "mojo/edk/system/awakable_list.h"
#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/system/handle_signals_state.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

// A base class for simple dispatchers. "Simple" means that there's a one-to-one
// correspondence between handles and dispatchers (see the explanatory comment
// in core.cc). This class implements the standard waiter-signaling mechanism in
// that case.
class SimpleDispatcher : public Dispatcher {
 protected:
  SimpleDispatcher();
  ~SimpleDispatcher() override;

  // To be called by subclasses when the state changes.
  void OnHandleSignalsStateChangeNoLock(const HandleSignalsState& old_state,
                                        const HandleSignalsState& new_state)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex());

  // |Dispatcher| protected methods:
  void CancelAllStateNoLock() override;
  MojoResult AddAwakableImplNoLock(Awakable* awakable,
                                   uint64_t context,
                                   bool persistent,
                                   MojoHandleSignals signals,
                                   HandleSignalsState* signals_state) override;
  void RemoveAwakableImplNoLock(bool match_context,
                                Awakable* awakable,
                                uint64_t context,
                                HandleSignalsState* signals_state) override;

 private:
  AwakableList awakable_list_ MOJO_GUARDED_BY(mutex());

  MOJO_DISALLOW_COPY_AND_ASSIGN(SimpleDispatcher);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_SIMPLE_DISPATCHER_H_
