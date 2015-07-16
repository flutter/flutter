// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef REGISTER_WEAK_MEMBERS_TEMPLATE_H_
#define REGISTER_WEAK_MEMBERS_TEMPLATE_H_

#include "heap/stubs.h"

namespace blink {

class X : public GarbageCollected<X> {
 public:
  void trace(Visitor* visitor) { traceImpl(visitor); }
  void trace(InlinedGlobalMarkingVisitor visitor) { traceImpl(visitor); }

 private:
  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher visitor) {}
};

class HasUntracedWeakMembers : public GarbageCollected<HasUntracedWeakMembers> {
 public:
  void trace(Visitor* visitor) { traceImpl(visitor); }
  void trace(InlinedGlobalMarkingVisitor visitor) { traceImpl(visitor); }

  // Don't have to be defined for the purpose of this test.
  void clearWeakMembers(Visitor* visitor);

 private:
  template <typename VisitorDispatcher>
  void traceImpl(VisitorDispatcher visitor) {
    visitor->template registerWeakMembers<
        HasUntracedWeakMembers,
        &HasUntracedWeakMembers::clearWeakMembers>(this);
  }

  WeakMember<X> x_;
};

}

#endif  // REGISTER_WEAK_MEMBERS_TEMPLATE_H_
