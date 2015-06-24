// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_timer_heap.h"

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "base/time/time.h"
#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_invoke.h"
#include "sky/engine/tonic/dart_isolate_scope.h"
#include "sky/engine/tonic/dart_state.h"

namespace blink {

DartTimerHeap::DartTimerHeap() : next_timer_id_(1), weak_factory_(this) {
}

DartTimerHeap::~DartTimerHeap() {
}

int DartTimerHeap::Add(PassOwnPtr<Task> task) {
  int id = next_timer_id_++;
  Schedule(id, task);
  return id;
}

void DartTimerHeap::Remove(int id) {
  heap_.remove(id);
}

void DartTimerHeap::Schedule(int id, PassOwnPtr<Task> task) {
  base::TimeDelta delay = task->delay;
  heap_.add(id, task);
  base::MessageLoop::current()->PostDelayedTask(FROM_HERE,
    base::Bind(&DartTimerHeap::Run, weak_factory_.GetWeakPtr(), id), delay);
}

void DartTimerHeap::Run(int id) {
  auto it = heap_.find(id);
  if (it == heap_.end())
    return;
  OwnPtr<Task> task = it->value.release();
  heap_.remove(it);
  if (!task->closure.dart_state())
    return;
  DartIsolateScope scope(task->closure.dart_state()->isolate());
  DartApiScope api_scope;
  DartInvokeAppClosure(task->closure.value(), 0, nullptr);
  if (task->repeating)
    Schedule(id, task.release());
}

}
