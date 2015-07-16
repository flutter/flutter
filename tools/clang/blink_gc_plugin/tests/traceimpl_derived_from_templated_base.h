// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TRACEIMPL_DERIVED_FROM_TEMPLATED_BASE_H_
#define TRACEIMPL_DERIVED_FROM_TEMPLATED_BASE_H_

#include "heap/stubs.h"

namespace blink {

class X : public GarbageCollected<X> {
 public:
  virtual void trace(Visitor*) {}
};

template <int Y>
class TraceImplTemplatedBase
    : public GarbageCollected<TraceImplTemplatedBase<Y> > {
 public:
  void trace(Visitor* visitor) { traceImpl(visitor); }

  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher visitor) {
    visitor->trace(x_);
  }

 private:
  Member<X> x_;
};

class TraceImplDerivedFromTemplatedBase : public TraceImplTemplatedBase<0> {
};

}

#endif  // TRACEIMPL_DERIVED_FROM_TEMPLATED_BASE_H_
