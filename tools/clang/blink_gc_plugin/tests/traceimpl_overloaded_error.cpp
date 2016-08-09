// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "traceimpl_overloaded_error.h"

namespace blink {

void ExternBase::trace(Visitor* visitor) {
  traceImpl(visitor);
}

void ExternBase::trace(InlinedGlobalMarkingVisitor visitor) {
  traceImpl(visitor);
}

template <typename VisitorDispatcher>
inline void ExternBase::traceImpl(VisitorDispatcher visitor) {
  // Missing visitor->trace(x_base_).
}

void ExternDerived::trace(Visitor* visitor) {
  traceImpl(visitor);
}

void ExternDerived::trace(InlinedGlobalMarkingVisitor visitor) {
  traceImpl(visitor);
}

template <typename VisitorDispatcher>
inline void ExternDerived::traceImpl(VisitorDispatcher visitor) {
  // Missing visitor->trace(x_derived_) and ExternBase::trace(visitor).
}

}
