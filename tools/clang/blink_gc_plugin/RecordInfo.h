// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file provides a wrapper for CXXRecordDecl that accumulates GC related
// information about a class. Accumulated information is memoized and the info
// objects are stored in a RecordCache.

#ifndef TOOLS_BLINK_GC_PLUGIN_RECORD_INFO_H_
#define TOOLS_BLINK_GC_PLUGIN_RECORD_INFO_H_

#include <map>
#include <vector>

#include "Edge.h"

#include "clang/AST/AST.h"
#include "clang/AST/CXXInheritance.h"

class RecordCache;

// A potentially tracable and/or lifetime affecting point in the object graph.
class GraphPoint {
 public:
  GraphPoint() : traced_(false) {}
  virtual ~GraphPoint() {}
  void MarkTraced() { traced_ = true; }
  bool IsProperlyTraced() { return traced_ || !NeedsTracing().IsNeeded(); }
  virtual const TracingStatus NeedsTracing() = 0;

 private:
  bool traced_;
};

class BasePoint : public GraphPoint {
 public:
  BasePoint(const clang::CXXBaseSpecifier& spec,
            RecordInfo* info,
            const TracingStatus& status)
      : spec_(spec), info_(info), status_(status) {}
  const TracingStatus NeedsTracing() { return status_; }
  const clang::CXXBaseSpecifier& spec() { return spec_; }
  RecordInfo* info() { return info_; }

 private:
  const clang::CXXBaseSpecifier& spec_;
  RecordInfo* info_;
  TracingStatus status_;
};

class FieldPoint : public GraphPoint {
 public:
  FieldPoint(clang::FieldDecl* field, Edge* edge)
      : field_(field), edge_(edge) {}
  const TracingStatus NeedsTracing() {
    return edge_->NeedsTracing(Edge::kRecursive);
  }
  clang::FieldDecl* field() { return field_; }
  Edge* edge() { return edge_; }

 private:
  clang::FieldDecl* field_;
  Edge* edge_;

  friend class RecordCache;
  void deleteEdge() { delete edge_; }
};

// Wrapper class to lazily collect information about a C++ record.
class RecordInfo {
 public:
  typedef std::map<clang::CXXRecordDecl*, BasePoint> Bases;
  typedef std::map<clang::FieldDecl*, FieldPoint> Fields;
  typedef std::vector<const clang::Type*> TemplateArgs;

  ~RecordInfo();

  clang::CXXRecordDecl* record() const { return record_; }
  const std::string& name() const { return name_; }
  Fields& GetFields();
  Bases& GetBases();
  clang::CXXMethodDecl* GetTraceMethod();
  clang::CXXMethodDecl* GetTraceDispatchMethod();
  clang::CXXMethodDecl* GetFinalizeDispatchMethod();

  bool GetTemplateArgs(size_t count, TemplateArgs* output_args);

  bool IsHeapAllocatedCollection();
  bool IsGCDerived();
  bool IsGCAllocated();
  bool IsGCFinalized();
  bool IsGCMixin();
  bool IsStackAllocated();
  bool IsNonNewable();
  bool IsOnlyPlacementNewable();
  bool IsGCMixinInstance();
  bool IsEagerlyFinalized();

  bool HasDefinition();

  clang::CXXMethodDecl* DeclaresNewOperator();

  bool RequiresTraceMethod();
  bool NeedsFinalization();
  bool DeclaresGCMixinMethods();
  bool DeclaresLocalTraceMethod();
  TracingStatus NeedsTracing(Edge::NeedsTracingOption);
  clang::CXXMethodDecl* InheritsNonVirtualTrace();
  bool IsConsideredAbstract();

  static clang::CXXRecordDecl* GetDependentTemplatedDecl(const clang::Type&);

 private:
  RecordInfo(clang::CXXRecordDecl* record, RecordCache* cache);

  void walkBases();

  Fields* CollectFields();
  Bases* CollectBases();
  void DetermineTracingMethods();
  bool InheritsTrace();

  Edge* CreateEdge(const clang::Type* type);

  RecordCache* cache_;
  clang::CXXRecordDecl* record_;
  const std::string name_;
  TracingStatus fields_need_tracing_;
  Bases* bases_;
  Fields* fields_;

  enum CachedBool { kFalse = 0, kTrue = 1, kNotComputed = 2 };
  CachedBool is_stack_allocated_;
  CachedBool is_non_newable_;
  CachedBool is_only_placement_newable_;
  CachedBool does_need_finalization_;
  CachedBool has_gc_mixin_methods_;
  CachedBool is_declaring_local_trace_;
  CachedBool is_eagerly_finalized_;

  bool determined_trace_methods_;
  clang::CXXMethodDecl* trace_method_;
  clang::CXXMethodDecl* trace_dispatch_method_;
  clang::CXXMethodDecl* finalize_dispatch_method_;

  bool is_gc_derived_;

  std::vector<std::string> gc_base_names_;

  friend class RecordCache;
};

class RecordCache {
 public:
  RecordInfo* Lookup(clang::CXXRecordDecl* record);

  RecordInfo* Lookup(const clang::CXXRecordDecl* record) {
    return Lookup(const_cast<clang::CXXRecordDecl*>(record));
  }

  RecordInfo* Lookup(clang::DeclContext* decl) {
    return Lookup(clang::dyn_cast<clang::CXXRecordDecl>(decl));
  }

  RecordInfo* Lookup(const clang::Type* type) {
    return Lookup(type->getAsCXXRecordDecl());
  }

  RecordInfo* Lookup(const clang::QualType& type) {
    return Lookup(type.getTypePtr());
  }

  ~RecordCache() {
    for (Cache::iterator it = cache_.begin(); it != cache_.end(); ++it) {
      if (!it->second.fields_)
        continue;
      for (RecordInfo::Fields::iterator fit = it->second.fields_->begin();
        fit != it->second.fields_->end();
        ++fit) {
        fit->second.deleteEdge();
      }
    }
  }

 private:
  typedef std::map<clang::CXXRecordDecl*, RecordInfo> Cache;
  Cache cache_;
};

#endif  // TOOLS_BLINK_GC_PLUGIN_RECORD_INFO_H_
