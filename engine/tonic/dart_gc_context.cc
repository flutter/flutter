// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/tonic/dart_gc_context.h"

namespace blink {

DartGCContext::DartGCContext() : builder_(Dart_NewWeakReferenceSetBuilder()) {
}

DartGCContext::~DartGCContext() {
}

Dart_WeakReferenceSet DartGCContext::AddToSetForRoot(
    const void* root,
    Dart_WeakPersistentHandle handle) {
  const auto& it = references_.add(root, nullptr);
  if (!it.isNewEntry) {
    Dart_AppendToWeakReferenceSet(it.storedValue->value, handle, handle);
    return it.storedValue->value;
  }
  it.storedValue->value = Dart_NewWeakReferenceSet(builder_, handle, handle);
  return it.storedValue->value;
}

}  // namespace blink
