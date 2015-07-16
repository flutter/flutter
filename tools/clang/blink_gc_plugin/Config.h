// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file defines the names used by GC infrastructure.

// TODO: Restructure the name determination to use fully qualified names (ala,
// blink::Foo) so that the plugin can be enabled for all of chromium. Doing so
// would allow us to catch errors with structures outside of blink that might
// have unsafe pointers to GC allocated blink structures.

#ifndef TOOLS_BLINK_GC_PLUGIN_CONFIG_H_
#define TOOLS_BLINK_GC_PLUGIN_CONFIG_H_

#include <cassert>

#include "clang/AST/AST.h"
#include "clang/AST/Attr.h"

const char kNewOperatorName[] = "operator new";
const char kCreateName[] = "create";
const char kTraceName[] = "trace";
const char kTraceImplName[] = "traceImpl";
const char kFinalizeName[] = "finalizeGarbageCollectedObject";
const char kTraceAfterDispatchName[] = "traceAfterDispatch";
const char kTraceAfterDispatchImplName[] = "traceAfterDispatchImpl";
const char kRegisterWeakMembersName[] = "registerWeakMembers";
const char kHeapAllocatorName[] = "HeapAllocator";
const char kTraceIfNeededName[] = "TraceIfNeeded";
const char kVisitorDispatcherName[] = "VisitorDispatcher";
const char kVisitorVarName[] = "visitor";
const char kAdjustAndMarkName[] = "adjustAndMark";
const char kIsHeapObjectAliveName[] = "isHeapObjectAlive";
const char kIsEagerlyFinalizedName[] = "IsEagerlyFinalizedMarker";

class Config {
 public:
  static bool IsMember(const std::string& name) {
    return name == "Member";
  }

  static bool IsWeakMember(const std::string& name) {
    return name == "WeakMember";
  }

  static bool IsMemberHandle(const std::string& name) {
    return IsMember(name) ||
           IsWeakMember(name);
  }

  static bool IsPersistent(const std::string& name) {
    return name == "Persistent";
  }

  static bool IsPersistentHandle(const std::string& name) {
    return IsPersistent(name) ||
           IsPersistentGCCollection(name);
  }

  static bool IsRawPtr(const std::string& name) {
    return name == "RawPtr";
  }

  static bool IsRefPtr(const std::string& name) {
    return name == "RefPtr";
  }

  static bool IsOwnPtr(const std::string& name) {
    return name == "OwnPtr";
  }

  static bool IsWTFCollection(const std::string& name) {
    return name == "Vector" ||
           name == "Deque" ||
           name == "HashSet" ||
           name == "ListHashSet" ||
           name == "LinkedHashSet" ||
           name == "HashCountedSet" ||
           name == "HashMap";
  }

  static bool IsGCCollection(const std::string& name) {
    return name == "HeapVector" ||
           name == "HeapDeque" ||
           name == "HeapHashSet" ||
           name == "HeapListHashSet" ||
           name == "HeapLinkedHashSet" ||
           name == "HeapHashCountedSet" ||
           name == "HeapHashMap" ||
           IsPersistentGCCollection(name);
  }

  static bool IsPersistentGCCollection(const std::string& name) {
    return name == "PersistentHeapVector" ||
           name == "PersistentHeapDeque" ||
           name == "PersistentHeapHashSet" ||
           name == "PersistentHeapListHashSet" ||
           name == "PersistentHeapLinkedHashSet" ||
           name == "PersistentHeapHashCountedSet" ||
           name == "PersistentHeapHashMap";
  }

  static bool IsHashMap(const std::string& name) {
    return name == "HashMap" ||
           name == "HeapHashMap" ||
           name == "PersistentHeapHashMap";
  }

  // Following http://crrev.com/369633033 (Blink r177436),
  // ignore blink::ScriptWrappable's destructor.
  // TODO: remove when its non-Oilpan destructor is removed.
  static bool HasIgnorableDestructor(const std::string& ns,
                                     const std::string& name) {
    return ns == "blink" && name == "ScriptWrappable";
  }

  // Assumes name is a valid collection name.
  static size_t CollectionDimension(const std::string& name) {
    return (IsHashMap(name) || name == "pair") ? 2 : 1;
  }

  static bool IsDummyBase(const std::string& name) {
    return name == "DummyBase";
  }

  static bool IsRefCountedBase(const std::string& name) {
    return name == "RefCounted" ||
           name == "ThreadSafeRefCounted";
  }

  static bool IsGCMixinBase(const std::string& name) {
    return name == "GarbageCollectedMixin";
  }

  static bool IsGCFinalizedBase(const std::string& name) {
    return name == "GarbageCollectedFinalized" ||
           name == "RefCountedGarbageCollected" ||
           name == "ThreadSafeRefCountedGarbageCollected";
  }

  static bool IsGCBase(const std::string& name) {
    return name == "GarbageCollected" ||
           IsGCFinalizedBase(name) ||
           IsGCMixinBase(name);
  }

  // Returns true of the base classes that do not need a vtable entry for trace
  // because they cannot possibly initiate a GC during construction.
  static bool IsSafePolymorphicBase(const std::string& name) {
    return IsGCBase(name) || IsDummyBase(name) || IsRefCountedBase(name);
  }

  static bool IsAnnotated(clang::Decl* decl, const std::string& anno) {
    clang::AnnotateAttr* attr = decl->getAttr<clang::AnnotateAttr>();
    return attr && (attr->getAnnotation() == anno);
  }

  static bool IsStackAnnotated(clang::Decl* decl) {
    return IsAnnotated(decl, "blink_stack_allocated");
  }

  static bool IsIgnoreAnnotated(clang::Decl* decl) {
    return IsAnnotated(decl, "blink_gc_plugin_ignore");
  }

  static bool IsIgnoreCycleAnnotated(clang::Decl* decl) {
    return IsAnnotated(decl, "blink_gc_plugin_ignore_cycle") ||
           IsIgnoreAnnotated(decl);
  }

  static bool IsVisitor(const std::string& name) {
    return name == "Visitor" || name == "VisitorHelper";
  }

  static bool IsVisitorPtrType(const clang::QualType& formal_type) {
    if (!formal_type->isPointerType())
      return false;

    clang::CXXRecordDecl* pointee_type =
        formal_type->getPointeeType()->getAsCXXRecordDecl();
    if (!pointee_type)
      return false;

    if (!IsVisitor(pointee_type->getName()))
      return false;

    return true;
  }

  static bool IsVisitorDispatcherType(const clang::QualType& formal_type) {
    if (const clang::SubstTemplateTypeParmType* subst_type =
            clang::dyn_cast<clang::SubstTemplateTypeParmType>(
                formal_type.getTypePtr())) {
      if (IsVisitorPtrType(subst_type->getReplacementType())) {
        // VisitorDispatcher template parameter substituted to Visitor*.
        return true;
      }
    } else if (const clang::TemplateTypeParmType* parm_type =
                   clang::dyn_cast<clang::TemplateTypeParmType>(
                       formal_type.getTypePtr())) {
      if (parm_type->getDecl()->getName() == kVisitorDispatcherName) {
        // Unresolved, but its parameter name is VisitorDispatcher.
        return true;
      }
    }

    return IsVisitorPtrType(formal_type);
  }

  enum TraceMethodType {
    NOT_TRACE_METHOD,
    TRACE_METHOD,
    TRACE_AFTER_DISPATCH_METHOD,
    TRACE_IMPL_METHOD,
    TRACE_AFTER_DISPATCH_IMPL_METHOD
  };

  static TraceMethodType GetTraceMethodType(const clang::FunctionDecl* method) {
    if (method->getNumParams() != 1)
      return NOT_TRACE_METHOD;

    const std::string& name = method->getNameAsString();
    if (name != kTraceName && name != kTraceAfterDispatchName &&
        name != kTraceImplName && name != kTraceAfterDispatchImplName)
      return NOT_TRACE_METHOD;

    const clang::QualType& formal_type = method->getParamDecl(0)->getType();
    if (name == kTraceImplName || name == kTraceAfterDispatchImplName) {
      if (!IsVisitorDispatcherType(formal_type))
        return NOT_TRACE_METHOD;
    } else if (!IsVisitorPtrType(formal_type)) {
      return NOT_TRACE_METHOD;
    }

    if (name == kTraceName)
      return TRACE_METHOD;
    if (name == kTraceAfterDispatchName)
      return TRACE_AFTER_DISPATCH_METHOD;
    if (name == kTraceImplName)
      return TRACE_IMPL_METHOD;
    if (name == kTraceAfterDispatchImplName)
      return TRACE_AFTER_DISPATCH_IMPL_METHOD;

    assert(false && "Should not reach here");
    return NOT_TRACE_METHOD;
  }

  static bool IsTraceMethod(const clang::FunctionDecl* method) {
    return GetTraceMethodType(method) != NOT_TRACE_METHOD;
  }

  static bool IsTraceImplName(const std::string& name) {
    return name == kTraceImplName || name == kTraceAfterDispatchImplName;
  }

  static bool StartsWith(const std::string& str, const std::string& prefix) {
    if (prefix.size() > str.size())
      return false;
    return str.compare(0, prefix.size(), prefix) == 0;
  }

  static bool EndsWith(const std::string& str, const std::string& suffix) {
    if (suffix.size() > str.size())
      return false;
    return str.compare(str.size() - suffix.size(), suffix.size(), suffix) == 0;
  }
};

#endif  // TOOLS_BLINK_GC_PLUGIN_CONFIG_H_
