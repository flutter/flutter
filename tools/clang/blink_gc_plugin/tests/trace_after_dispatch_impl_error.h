// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TRACE_AFTER_DISPATCH_IMPL_ERROR_H_
#define TRACE_AFTER_DISPATCH_IMPL_ERROR_H_

#include "heap/stubs.h"

namespace blink {

class X : public GarbageCollected<X> {
 public:
  void trace(Visitor*) {}
};

enum ClassTag {
  BASE, DERIVED
};

class TraceAfterDispatchInlinedBase
    : public GarbageCollected<TraceAfterDispatchInlinedBase> {
 public:
  explicit TraceAfterDispatchInlinedBase(ClassTag tag) : tag_(tag) {}

  void trace(Visitor* visitor) { traceImpl(visitor); }
  void trace(InlinedGlobalMarkingVisitor visitor) { traceImpl(visitor); }

  void traceAfterDispatch(Visitor* visitor) { traceAfterDispatchImpl(visitor); }
  void traceAfterDispatch(InlinedGlobalMarkingVisitor visitor) {
    traceAfterDispatchImpl(visitor);
  }

 private:
  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher visitor);

  template <typename VisitorDispatcher>
  void traceAfterDispatchImpl(VisitorDispatcher visitor) {
    // No trace call; should get a warning.
  }

  ClassTag tag_;
  Member<X> x_base_;
};

class TraceAfterDispatchInlinedDerived : public TraceAfterDispatchInlinedBase {
 public:
  TraceAfterDispatchInlinedDerived() : TraceAfterDispatchInlinedBase(DERIVED) {}

  void traceAfterDispatch(Visitor* visitor) { traceAfterDispatchImpl(visitor); }
  void traceAfterDispatch(InlinedGlobalMarkingVisitor visitor) {
    traceAfterDispatchImpl(visitor);
  }

 private:
  template <typename VisitorDispatcher>
  void traceAfterDispatchImpl(VisitorDispatcher visitor) {
    // No trace call (for member and base class).
  }

  Member<X> x_derived_;
};

class TraceAfterDispatchExternBase
    : public GarbageCollected<TraceAfterDispatchExternBase> {
 public:
  explicit TraceAfterDispatchExternBase(ClassTag tag) : tag_(tag) {}

  void trace(Visitor* visitor);
  void trace(InlinedGlobalMarkingVisitor visitor);

  void traceAfterDispatch(Visitor* visitor);
  void traceAfterDispatch(InlinedGlobalMarkingVisitor visitor);

 private:
  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher visitor);

  template <typename VisitorDispatcher>
  void traceAfterDispatchImpl(VisitorDispatcher visitor);

  ClassTag tag_;
  Member<X> x_base_;
};

class TraceAfterDispatchExternDerived : public TraceAfterDispatchExternBase {
 public:
  TraceAfterDispatchExternDerived() : TraceAfterDispatchExternBase(DERIVED) {}

  void traceAfterDispatch(Visitor* visitor);
  void traceAfterDispatch(InlinedGlobalMarkingVisitor visitor);

 private:
  template <typename VisitorDispatcher>
  void traceAfterDispatchImpl(VisitorDispatcher visitor);

  Member<X> x_derived_;
};

}

#endif  // TRACE_AFTER_DISPATCH_IMPL_ERROR_H_
