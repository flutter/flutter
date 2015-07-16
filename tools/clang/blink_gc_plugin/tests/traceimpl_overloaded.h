// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TRACEIMPL_OVERLOADED_H_
#define TRACEIMPL_OVERLOADED_H_

#include "heap/stubs.h"

namespace blink {

class X : public GarbageCollected<X> {
 public:
  void trace(Visitor*) {}
  void trace(InlinedGlobalMarkingVisitor) {}
};

class InlinedBase : public GarbageCollected<InlinedBase> {
 public:
  virtual void trace(Visitor* visitor) { traceImpl(visitor); }
  virtual void trace(InlinedGlobalMarkingVisitor visitor) {
    traceImpl(visitor);
  }

 private:
  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher visitor) { visitor->trace(x_base_); }

  Member<X> x_base_;
};

class InlinedDerived : public InlinedBase {
 public:
  void trace(Visitor* visitor) override { traceImpl(visitor); }
  void trace(InlinedGlobalMarkingVisitor visitor) override {
    traceImpl(visitor);
  }

 private:
  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher visitor) {
    visitor->trace(x_derived_);
    InlinedBase::trace(visitor);
  }

  Member<X> x_derived_;
};

class ExternBase : public GarbageCollected<ExternBase> {
 public:
  virtual void trace(Visitor*);
  virtual void trace(InlinedGlobalMarkingVisitor);

 private:
  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher);

  Member<X> x_base_;
};

class ExternDerived : public ExternBase {
 public:
  void trace(Visitor*) override;
  void trace(InlinedGlobalMarkingVisitor) override;

 private:
  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher);

  Member<X> x_derived_;
};

}

#endif  // TRACEIMPL_OVERLOADED_H_
