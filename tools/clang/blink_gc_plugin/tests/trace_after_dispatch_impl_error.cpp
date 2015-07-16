// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "trace_after_dispatch_impl_error.h"

namespace blink {

template <typename VisitorDispatcher>
inline void TraceAfterDispatchInlinedBase::traceImpl(
    VisitorDispatcher visitor) {
  // Implement a simple form of manual dispatching, because BlinkGCPlugin
  // checks if the tracing is dispatched to all derived classes.
  //
  // This function has to be implemented out-of-line, since we need to know the
  // definition of derived classes here.
  if (tag_ == DERIVED) {
    // Missing dispatch call:
    // static_cast<TraceAfterDispatchInlinedDerived*>(this)->traceAfterDispatch(
    //     visitor);
  } else {
    traceAfterDispatch(visitor);
  }
}

void TraceAfterDispatchExternBase::trace(Visitor* visitor) {
  traceImpl(visitor);
}

void TraceAfterDispatchExternBase::trace(InlinedGlobalMarkingVisitor visitor) {
  traceImpl(visitor);
}

template <typename VisitorDispatcher>
inline void TraceAfterDispatchExternBase::traceImpl(VisitorDispatcher visitor) {
  if (tag_ == DERIVED) {
    // Missing dispatch call:
    // static_cast<TraceAfterDispatchExternDerived*>(this)->traceAfterDispatch(
    //     visitor);
  } else {
    traceAfterDispatch(visitor);
  }
}

void TraceAfterDispatchExternBase::traceAfterDispatch(Visitor* visitor) {
  traceAfterDispatchImpl(visitor);
}

void TraceAfterDispatchExternBase::traceAfterDispatch(
    InlinedGlobalMarkingVisitor visitor) {
  traceAfterDispatchImpl(visitor);
}

template <typename VisitorDispatcher>
inline void TraceAfterDispatchExternBase::traceAfterDispatchImpl(
    VisitorDispatcher visitor) {
  // No trace call.
}

void TraceAfterDispatchExternDerived::traceAfterDispatch(Visitor* visitor) {
  traceAfterDispatchImpl(visitor);
}

void TraceAfterDispatchExternDerived::traceAfterDispatch(
    InlinedGlobalMarkingVisitor visitor) {
  traceAfterDispatchImpl(visitor);
}

template <typename VisitorDispatcher>
inline void TraceAfterDispatchExternDerived::traceAfterDispatchImpl(
    VisitorDispatcher visitor) {
  // Ditto.
}

}
