// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_GC_VISITOR_H_
#define SKY_ENGINE_TONIC_DART_GC_VISITOR_H_

#include "base/logging.h"
#include "dart/runtime/include/dart_api.h"

namespace blink {
class DartGCContext;

class DartGCVisitor {
 public:
  explicit DartGCVisitor(DartGCContext* context);
  ~DartGCVisitor();

  bool have_found_set() const {
    return !!current_set_;
  }

  Dart_WeakReferenceSet current_set() const {
    DCHECK(have_found_set());
    return current_set_;
  }

  void AddToSetForRoot(const void* root, Dart_WeakPersistentHandle handle);

 private:
  DartGCContext* context_;
  Dart_WeakReferenceSet current_set_;

  DISALLOW_COPY_AND_ASSIGN(DartGCVisitor);
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_GC_VISITOR_H_
