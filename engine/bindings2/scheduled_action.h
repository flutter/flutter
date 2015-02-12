// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS2_SCHEDULED_ACTION_H_
#define SKY_ENGINE_BINDINGS2_SCHEDULED_ACTION_H_

#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_persistent_value.h"
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

class ExecutionContext;

class ScheduledAction {
 public:
  static PassOwnPtr<ScheduledAction> Create(DartState* dart_state,
                                            Dart_Handle closure) {
    return adoptPtr(new ScheduledAction(dart_state, closure));
  }

  ~ScheduledAction();

  void Execute(ExecutionContext*);

 private:
  ScheduledAction(DartState* dart_state, Dart_Handle closure);

  DartPersistentValue closure_;
};

}  // namespace blink

#endif  // SKY_ENGINE_BINDINGS2_SCHEDULED_ACTION_H_
