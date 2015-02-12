// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_GC_CONTEXT_H_
#define SKY_ENGINE_TONIC_DART_GC_CONTEXT_H_

#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/wtf/HashMap.h"

namespace blink {

class DartGCContext {
 public:
  DartGCContext();
  ~DartGCContext();

  Dart_WeakReferenceSet AddToSetForRoot(const void* root,
                                        Dart_WeakPersistentHandle handle);

 private:
  Dart_WeakReferenceSetBuilder builder_;
  HashMap<const void*, Dart_WeakReferenceSet> references_;

  DISALLOW_COPY_AND_ASSIGN(DartGCContext);
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_GC_CONTEXT_H_
