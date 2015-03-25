// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/tonic/dart_gc_controller.h"

#include "base/trace_event/trace_event.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_gc_context.h"
#include "sky/engine/tonic/dart_gc_visitor.h"
#include "sky/engine/tonic/dart_wrappable.h"

namespace blink {
namespace {

DartGCContext* g_gc_context = nullptr;

DartWrappable* GetWrappable(intptr_t* fields) {
  return reinterpret_cast<DartWrappable*>(fields[DartWrappable::kPeerIndex]);
}

void Visit(void* isolate_callback_data,
           Dart_WeakPersistentHandle handle,
           intptr_t native_field_count,
           intptr_t* native_fields) {
  if (!native_field_count)
    return;
  DCHECK(native_field_count == DartWrappable::kNumberOfNativeFields);
  DartGCVisitor visitor(g_gc_context);
  GetWrappable(native_fields)->AcceptDartGCVisitor(visitor);
}

}  // namespace

void DartGCPrologue() {
  TRACE_EVENT_ASYNC_BEGIN0("sky", "DartGC", 0);

  Dart_EnterScope();
  DCHECK(!g_gc_context);
  g_gc_context = new DartGCContext();
  Dart_VisitPrologueWeakHandles(Visit);
}

void DartGCEpilogue() {
  delete g_gc_context;
  g_gc_context = nullptr;
  Dart_ExitScope();

  TRACE_EVENT_ASYNC_END0("sky", "DartGC", 0);
}

}  // namespace blink
