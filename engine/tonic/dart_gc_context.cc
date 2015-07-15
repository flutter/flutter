// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <utility>

#include "sky/engine/tonic/dart_gc_context.h"

namespace blink {

DartGCContext::DartGCContext() : builder_(Dart_NewWeakReferenceSetBuilder()) {
}

DartGCContext::~DartGCContext() {
}

Dart_WeakReferenceSet DartGCContext::AddToSetForRoot(
    const void* root,
    Dart_WeakPersistentHandle handle) {
  const auto& result = references_.insert(std::make_pair(root, nullptr));
  if (!result.second) {
    // Already present.
    Dart_AppendToWeakReferenceSet(result.first->second, handle, handle);
    return result.first->second;
  }
  result.first->second = Dart_NewWeakReferenceSet(builder_, handle, handle);
  return result.first->second;
}

}  // namespace blink
