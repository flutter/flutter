// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_BLINK_GC_PLUGIN_EDGE_H_
#define TOOLS_BLINK_GC_PLUGIN_EDGE_H_

#include <deque>

#include "TracingStatus.h"

class RecordInfo;

class Edge;
class Value;
class RawPtr;
class RefPtr;
class OwnPtr;
class Member;
class WeakMember;
class Persistent;
class Collection;

// Bare-bones visitor.
class EdgeVisitor {
 public:
  virtual ~EdgeVisitor() {}
  virtual void VisitValue(Value*) {}
  virtual void VisitRawPtr(RawPtr*) {}
  virtual void VisitRefPtr(RefPtr*) {}
  virtual void VisitOwnPtr(OwnPtr*) {}
  virtual void VisitMember(Member*) {}
  virtual void VisitWeakMember(WeakMember*) {}
  virtual void VisitPersistent(Persistent*) {}
  virtual void VisitCollection(Collection*) {}
};

// Recursive edge visitor. The traversed path is accessible in context.
class RecursiveEdgeVisitor : public EdgeVisitor {
 public:
  // Overrides that recursively walk the edges and record the path.
  void VisitValue(Value*) override;
  void VisitRawPtr(RawPtr*) override;
  void VisitRefPtr(RefPtr*) override;
  void VisitOwnPtr(OwnPtr*) override;
  void VisitMember(Member*) override;
  void VisitWeakMember(WeakMember*) override;
  void VisitPersistent(Persistent*) override;
  void VisitCollection(Collection*) override;

 protected:
  typedef std::deque<Edge*> Context;
  Context& context() { return context_; }
  Edge* Parent() { return context_.empty() ? 0 : context_.front(); }
  void Enter(Edge* e) { return context_.push_front(e); }
  void Leave() { context_.pop_front(); }

  // Default callback to overwrite in visitor subclass.
  virtual void AtValue(Value*);
  virtual void AtRawPtr(RawPtr*);
  virtual void AtRefPtr(RefPtr*);
  virtual void AtOwnPtr(OwnPtr*);
  virtual void AtMember(Member*);
  virtual void AtWeakMember(WeakMember*);
  virtual void AtPersistent(Persistent*);
  virtual void AtCollection(Collection*);

 private:
  Context context_;
};

// Base class for all edges.
class Edge {
 public:
  enum NeedsTracingOption { kRecursive, kNonRecursive };
  enum LivenessKind { kWeak, kStrong, kRoot };

  virtual ~Edge() {}
  virtual LivenessKind Kind() = 0;
  virtual void Accept(EdgeVisitor*) = 0;
  virtual bool NeedsFinalization() = 0;
  virtual TracingStatus NeedsTracing(NeedsTracingOption) {
    return TracingStatus::Unknown();
  }

  virtual bool IsValue() { return false; }
  virtual bool IsRawPtr() { return false; }
  virtual bool IsRawPtrClass() { return false; }
  virtual bool IsRefPtr() { return false; }
  virtual bool IsOwnPtr() { return false; }
  virtual bool IsMember() { return false; }
  virtual bool IsWeakMember() { return false; }
  virtual bool IsPersistent() { return false; }
  virtual bool IsCollection() { return false; }
};

// A value edge is a direct edge to some type, eg, part-object edges.
class Value : public Edge {
 public:
  explicit Value(RecordInfo* value) : value_(value) {};
  bool IsValue() override { return true; }
  LivenessKind Kind() override { return kStrong; }
  bool NeedsFinalization() override;
  TracingStatus NeedsTracing(NeedsTracingOption) override;
  void Accept(EdgeVisitor* visitor) override { visitor->VisitValue(this); }
  RecordInfo* value() { return value_; }

 private:
  RecordInfo* value_;
};

// Shared base for smart-pointer edges.
class PtrEdge : public Edge {
 public:
  ~PtrEdge() { delete ptr_; }
  Edge* ptr() { return ptr_; }
 protected:
  PtrEdge(Edge* ptr) : ptr_(ptr) {
    assert(ptr && "EdgePtr pointer must be non-null");
  }
 private:
  Edge* ptr_;
};

class RawPtr : public PtrEdge {
 public:
  explicit RawPtr(Edge* ptr, bool is_ptr_class)
      : PtrEdge(ptr), is_ptr_class_(is_ptr_class) { }
  bool IsRawPtr() { return true; }
  bool IsRawPtrClass() { return is_ptr_class_; }
  LivenessKind Kind() { return kWeak; }
  bool NeedsFinalization() { return false; }
  TracingStatus NeedsTracing(NeedsTracingOption) {
    return TracingStatus::Unneeded();
  }
  void Accept(EdgeVisitor* visitor) { visitor->VisitRawPtr(this); }
 private:
  bool is_ptr_class_;
};

class RefPtr : public PtrEdge {
 public:
  explicit RefPtr(Edge* ptr) : PtrEdge(ptr) { }
  bool IsRefPtr() { return true; }
  LivenessKind Kind() { return kStrong; }
  bool NeedsFinalization() { return true; }
  TracingStatus NeedsTracing(NeedsTracingOption) {
    return TracingStatus::Unneeded();
  }
  void Accept(EdgeVisitor* visitor) { visitor->VisitRefPtr(this); }
};

class OwnPtr : public PtrEdge {
 public:
  explicit OwnPtr(Edge* ptr) : PtrEdge(ptr) { }
  bool IsOwnPtr() { return true; }
  LivenessKind Kind() { return kStrong; }
  bool NeedsFinalization() { return true; }
  TracingStatus NeedsTracing(NeedsTracingOption) {
    return TracingStatus::Unneeded();
  }
  void Accept(EdgeVisitor* visitor) { visitor->VisitOwnPtr(this); }
};

class Member : public PtrEdge {
 public:
  explicit Member(Edge* ptr) : PtrEdge(ptr) { }
  bool IsMember() { return true; }
  LivenessKind Kind() { return kStrong; }
  bool NeedsFinalization() { return false; }
  TracingStatus NeedsTracing(NeedsTracingOption) {
    return TracingStatus::Needed();
  }
  void Accept(EdgeVisitor* visitor) { visitor->VisitMember(this); }
};

class WeakMember : public PtrEdge {
 public:
  explicit WeakMember(Edge* ptr) : PtrEdge(ptr) { }
  bool IsWeakMember() { return true; }
  LivenessKind Kind() { return kWeak; }
  bool NeedsFinalization() { return false; }
  TracingStatus NeedsTracing(NeedsTracingOption) {
    return TracingStatus::Needed();
  }
  void Accept(EdgeVisitor* visitor) { visitor->VisitWeakMember(this); }
};

class Persistent : public PtrEdge {
 public:
  explicit Persistent(Edge* ptr) : PtrEdge(ptr) { }
  bool IsPersistent() { return true; }
  LivenessKind Kind() { return kRoot; }
  bool NeedsFinalization() { return true; }
  TracingStatus NeedsTracing(NeedsTracingOption) {
    return TracingStatus::Unneeded();
  }
  void Accept(EdgeVisitor* visitor) { visitor->VisitPersistent(this); }
};

class Collection : public Edge {
 public:
  typedef std::vector<Edge*> Members;
  Collection(RecordInfo* info, bool on_heap, bool is_root)
      : info_(info),
        on_heap_(on_heap),
        is_root_(is_root) {}
  ~Collection() {
    for (Members::iterator it = members_.begin(); it != members_.end(); ++it) {
      assert(*it && "Collection-edge members must be non-null");
      delete *it;
    }
  }
  bool IsCollection() { return true; }
  LivenessKind Kind() { return is_root_ ? kRoot : kStrong; }
  bool on_heap() { return on_heap_; }
  bool is_root() { return is_root_; }
  Members& members() { return members_; }
  void Accept(EdgeVisitor* visitor) { visitor->VisitCollection(this); }
  void AcceptMembers(EdgeVisitor* visitor) {
    for (Members::iterator it = members_.begin(); it != members_.end(); ++it)
      (*it)->Accept(visitor);
  }
  bool NeedsFinalization();
  TracingStatus NeedsTracing(NeedsTracingOption) {
    if (is_root_)
      return TracingStatus::Unneeded();
    if (on_heap_)
      return TracingStatus::Needed();
    // For off-heap collections, determine tracing status of members.
    TracingStatus status = TracingStatus::Unneeded();
    for (Members::iterator it = members_.begin(); it != members_.end(); ++it) {
      // Do a non-recursive test here since members could equal the holder.
      status = status.LUB((*it)->NeedsTracing(kNonRecursive));
    }
    return status;
  }

 private:
  RecordInfo* info_;
  Members members_;
  bool on_heap_;
  bool is_root_;
};

#endif  // TOOLS_BLINK_GC_PLUGIN_EDGE_H_
