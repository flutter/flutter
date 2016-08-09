// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TRACEIMPL_OMITTED_TRACE_H_
#define TRACEIMPL_OMITTED_TRACE_H_

#include "heap/stubs.h"

namespace blink {

class A : public GarbageCollected<A> {
 public:
  virtual void trace(Visitor* visitor) { traceImpl(visitor); }
  virtual void trace(InlinedGlobalMarkingVisitor visitor) {
    traceImpl(visitor);
  }

 private:
  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher visitor) {}
};

class B : public A {
  // trace() isn't necessary because we've got nothing to trace here.
};

class C : public B {
 public:
  void trace(Visitor* visitor) override { traceImpl(visitor); }
  void trace(InlinedGlobalMarkingVisitor visitor) override {
    traceImpl(visitor);
  }

 private:
  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher visitor) {
    // B::trace() is actually A::trace(), and in certain cases we only get
    // limited information like "there is a function call that will be resolved
    // to A::trace()". We still want to mark B as traced.
    B::trace(visitor);
  }
};

}

#endif  // TRACEIMPL_OMITTED_TRACE_H_
