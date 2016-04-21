// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_MOCK_SIMPLE_DISPATCHER_H_
#define MOJO_EDK_SYSTEM_MOCK_SIMPLE_DISPATCHER_H_

#include "mojo/edk/system/handle_signals_state.h"
#include "mojo/edk/system/simple_dispatcher.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/c/system/handle.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {
namespace test {

// This is a "simple" dispatcher to be used in tests. The state of its signals
// can be set "manually", if desired.
class MockSimpleDispatcher final : public SimpleDispatcher {
 public:
  // Note: Use |MakeRefCounted<MockSimpleDispatcher>()|.

  Type GetType() const override;

  void SetSatisfiedSignals(MojoHandleSignals new_satisfied_signals);
  void SetSatisfiableSignals(MojoHandleSignals new_satisfiable_signals);

 private:
  FRIEND_MAKE_REF_COUNTED(MockSimpleDispatcher);

  MockSimpleDispatcher(
      MojoHandleSignals satisfied_signals = MOJO_HANDLE_SIGNAL_NONE,
      MojoHandleSignals satisfiable_signals = MOJO_HANDLE_SIGNAL_READABLE |
                                              MOJO_HANDLE_SIGNAL_WRITABLE);
  explicit MockSimpleDispatcher(const HandleSignalsState& state);
  ~MockSimpleDispatcher() override;

  util::RefPtr<Dispatcher> CreateEquivalentDispatcherAndCloseImplNoLock()
      override;

  // |Dispatcher| override:
  HandleSignalsState GetHandleSignalsStateImplNoLock() const override;

  HandleSignalsState state_ MOJO_GUARDED_BY(mutex());

  MOJO_DISALLOW_COPY_AND_ASSIGN(MockSimpleDispatcher);
};

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_MOCK_SIMPLE_DISPATCHER_H_
