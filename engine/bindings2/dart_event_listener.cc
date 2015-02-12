// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/bindings2/dart_event_listener.h"

#include "sky/engine/core/events/Event.h"
#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_gc_visitor.h"
#include "sky/engine/tonic/dart_isolate_scope.h"

namespace blink {

PassRefPtr<DartEventListener> DartEventListener::FromDart(Dart_Handle handle) {
  if (!Dart_IsClosure(handle))
    return nullptr;
  void* peer = nullptr;
  CHECK(!Dart_IsError(Dart_GetPeer(handle, &peer)));
  if (DartEventListener* listener = static_cast<DartEventListener*>(peer))
    return listener;
  RefPtr<DartEventListener> listener = adoptRef(new DartEventListener(handle));
  listener->data_state_ = DartState::Current()->GetWeakPtr();
  DCHECK(Dart_IsClosure(handle));
  listener->ref();  // Balanced in Finalize
  listener->closure_ = Dart_NewPrologueWeakPersistentHandle(
      handle, listener.get(), sizeof(*listener), &DartEventListener::Finalize);
  CHECK(!Dart_IsError(Dart_SetPeer(handle, listener.get())));
  return listener.release();
}

DartEventListener::DartEventListener(Dart_Handle handle) : closure_(nullptr) {
}

DartEventListener::~DartEventListener() {
}

void DartEventListener::handleEvent(ExecutionContext* context, Event* event) {
  if (!closure_ || !data_state_)
    return;

  DartIsolateScope scope(data_state_->isolate());
  DartApiScope api_scope;

  // Notice that we protect ourselves as well as the closure object in the VM.
  RefPtr<DartEventListener> protect(this);
  Dart_Handle closure_handle = Dart_HandleFromWeakPersistent(closure_);
  Dart_Handle event_handle = ToDart(event);
  DCHECK(event_handle);

  Dart_Handle params[] = {event_handle};
  LogIfError(Dart_InvokeClosure(closure_handle, arraysize(params), params));
}

void DartEventListener::AcceptDartGCVisitor(DartGCVisitor& visitor) const {
  CHECK(!Dart_IsError(Dart_AppendValueToWeakReferenceSet(
      visitor.current_set(), closure_)));
}

void DartEventListener::Finalize(void* isolate_callback_data,
                                 Dart_WeakPersistentHandle handle,
                                 void* peer) {
  DartEventListener* listener = static_cast<DartEventListener*>(peer);
  listener->closure_ = nullptr;
  listener->deref();  // Balances ref in DartEventListener::DartEventListener
}

}  // namespace blink
