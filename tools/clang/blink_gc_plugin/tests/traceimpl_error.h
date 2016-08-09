// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TRACEIMPL_ERROR_H_
#define TRACEIMPL_ERROR_H_

#include "heap/stubs.h"

namespace blink {

class X : public GarbageCollected<X> {
 public:
  virtual void trace(Visitor*) {}
};

class TraceImplInlinedWithUntracedMember
    : public GarbageCollected<TraceImplInlinedWithUntracedMember> {
 public:
  void trace(Visitor* visitor) { traceImpl(visitor); }

  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher visitor) {
    // Empty; should get complaints from the plugin for untraced x_.
  }

 private:
  Member<X> x_;
};

class TraceImplExternWithUntracedMember
    : public GarbageCollected<TraceImplExternWithUntracedMember> {
 public:
  void trace(Visitor* visitor);

  template <typename VisitorDispatcher>
  inline void traceImpl(VisitorDispatcher);

 private:
  Member<X> x_;
};

class Base : public GarbageCollected<Base> {
 public:
  virtual void trace(Visitor*) {}
};

class TraceImplInlineWithUntracedBase : public Base {
 public:
  void trace(Visitor* visitor) override { traceImpl(visitor); }

  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher visitor) {
    // Empty; should get complaints from the plugin for untraced Base.
  }
};

class TraceImplExternWithUntracedBase : public Base {
 public:
  void trace(Visitor*) override;

  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher visitor);
};

}

#endif  // TRACEIMPL_ERROR_H_
