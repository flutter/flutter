// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "Config.h"
#include "Edge.h"
#include "RecordInfo.h"

TracingStatus Value::NeedsTracing(NeedsTracingOption option) {
  return value_->NeedsTracing(option);
}

bool Value::NeedsFinalization() { return value_->NeedsFinalization(); }
bool Collection::NeedsFinalization() { return info_->NeedsFinalization(); }

void RecursiveEdgeVisitor::AtValue(Value*) {}
void RecursiveEdgeVisitor::AtRawPtr(RawPtr*) {}
void RecursiveEdgeVisitor::AtRefPtr(RefPtr*) {}
void RecursiveEdgeVisitor::AtOwnPtr(OwnPtr*) {}
void RecursiveEdgeVisitor::AtMember(Member*) {}
void RecursiveEdgeVisitor::AtWeakMember(WeakMember*) {}
void RecursiveEdgeVisitor::AtPersistent(Persistent*) {}
void RecursiveEdgeVisitor::AtCollection(Collection*) {}

void RecursiveEdgeVisitor::VisitValue(Value* e) {
  AtValue(e);
}

void RecursiveEdgeVisitor::VisitRawPtr(RawPtr* e) {
  AtRawPtr(e);
  Enter(e);
  e->ptr()->Accept(this);
  Leave();
}

void RecursiveEdgeVisitor::VisitRefPtr(RefPtr* e) {
  AtRefPtr(e);
  Enter(e);
  e->ptr()->Accept(this);
  Leave();
}
void RecursiveEdgeVisitor::VisitOwnPtr(OwnPtr* e) {
  AtOwnPtr(e);
  Enter(e);
  e->ptr()->Accept(this);
  Leave();
}

void RecursiveEdgeVisitor::VisitMember(Member* e) {
  AtMember(e);
  Enter(e);
  e->ptr()->Accept(this);
  Leave();
}

void RecursiveEdgeVisitor::VisitWeakMember(WeakMember* e) {
  AtWeakMember(e);
  Enter(e);
  e->ptr()->Accept(this);
  Leave();
}

void RecursiveEdgeVisitor::VisitPersistent(Persistent* e) {
  AtPersistent(e);
  Enter(e);
  e->ptr()->Accept(this);
  Leave();
}

void RecursiveEdgeVisitor::VisitCollection(Collection* e) {
  AtCollection(e);
  Enter(e);
  e->AcceptMembers(this);
  Leave();
}
