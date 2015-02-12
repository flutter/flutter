// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/bindings2/scheduled_action.h"

#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_isolate_scope.h"

namespace blink {

ScheduledAction::ScheduledAction(DartState* dart_state, Dart_Handle closure)
    : closure_(dart_state, closure) {
  DCHECK(Dart_IsClosure(closure));
}

ScheduledAction::~ScheduledAction() {
}

void ScheduledAction::Execute(ExecutionContext*) {
  if (!closure_.dart_state())
    return;
  DartIsolateScope scope(closure_.dart_state()->isolate());
  DartApiScope api_scope;
  LogIfError(Dart_InvokeClosure(closure_.value(), 0, nullptr));
}

}  // namespace blink
