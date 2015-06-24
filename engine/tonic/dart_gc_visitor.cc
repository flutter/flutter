// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_gc_visitor.h"

#include "sky/engine/tonic/dart_gc_context.h"

namespace blink {

DartGCVisitor::DartGCVisitor(DartGCContext* context)
    : context_(context), current_set_(nullptr) {
}

DartGCVisitor::~DartGCVisitor() {
}

void DartGCVisitor::AddToSetForRoot(const void* root,
                                    Dart_WeakPersistentHandle handle) {
  Dart_WeakReferenceSet set = context_->AddToSetForRoot(root, handle);
  DCHECK(!current_set_ || current_set_ == set);
  current_set_ = set;
}

}  // namespace blink
