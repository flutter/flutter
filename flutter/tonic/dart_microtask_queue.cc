// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_microtask_queue.h"

#include "base/trace_event/trace_event.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "flutter/tonic/dart_state.h"

using tonic::DartInvokeVoid;

namespace blink {
namespace {

typedef std::vector<DartPersistentValue> MicrotaskQueue;

static MicrotaskQueue& GetQueue() {
  static MicrotaskQueue* queue = new MicrotaskQueue();
  return *queue;
}

}  // namespace

void DartMicrotaskQueue::ScheduleMicrotask(Dart_Handle callback) {
  GetQueue().emplace_back(DartState::Current(), callback);
}

void DartMicrotaskQueue::RunMicrotasks() {
  MicrotaskQueue& queue = GetQueue();
  while (!queue.empty()) {
    TRACE_EVENT0("flutter", "DartMicrotaskQueue::RunMicrotasks");

    MicrotaskQueue local;
    std::swap(queue, local);
    for (const auto& callback : local) {
      base::WeakPtr<DartState> dart_state = callback.dart_state();
      if (!dart_state.get())
        continue;
      DartState::Scope dart_scope(dart_state.get());
      DartInvokeVoid(callback.value());
    }
  }
}
}
