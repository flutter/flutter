// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This clang plugin checks various invariants of the Blink garbage
// collection infrastructure.
//
// Errors are described at:
// http://www.chromium.org/developers/blink-gc-plugin-errors

#include <algorithm>

#include "Config.h"
#include "JsonWriter.h"
#include "RecordInfo.h"

#include "clang/AST/AST.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendPluginRegistry.h"
#include "clang/Sema/Sema.h"

using namespace clang;
using std::string;

namespace {

const char kClassMustLeftMostlyDeriveGC[] =
    "[blink-gc] Class %0 must derive its GC base in the left-most position.";

const char kClassRequiresTraceMethod[] =
    "[blink-gc] Class %0 requires a trace method.";

const char kBaseRequiresTracing[] =
    "[blink-gc] Base class %0 of derived class %1 requires tracing.";

const char kBaseRequiresTracingNote[] =
    "[blink-gc] Untraced base class %0 declared here:";

const char kFieldsRequireTracing[] =
    "[blink-gc] Class %0 has untraced fields that require tracing.";

const char kFieldRequiresTracingNote[] =
    "[blink-gc] Untraced field %0 declared here:";

const char kClassContainsInvalidFields[] =
    "[blink-gc] Class %0 contains invalid fields.";

const char kClassContainsGCRoot[] =
    "[blink-gc] Class %0 contains GC root in field %1.";

const char kClassRequiresFinalization[] =
    "[blink-gc] Class %0 requires finalization.";

const char kClassDoesNotRequireFinalization[] =
    "[blink-gc] Class %0 may not require finalization.";

const char kFinalizerAccessesFinalizedField[] =
    "[blink-gc] Finalizer %0 accesses potentially finalized field %1.";

const char kFinalizerAccessesEagerlyFinalizedField[] =
    "[blink-gc] Finalizer %0 accesses eagerly finalized field %1.";

const char kRawPtrToGCManagedClassNote[] =
    "[blink-gc] Raw pointer field %0 to a GC managed class declared here:";

const char kRefPtrToGCManagedClassNote[] =
    "[blink-gc] RefPtr field %0 to a GC managed class declared here:";

const char kOwnPtrToGCManagedClassNote[] =
    "[blink-gc] OwnPtr field %0 to a GC managed class declared here:";

const char kMemberToGCUnmanagedClassNote[] =
    "[blink-gc] Member field %0 to non-GC managed class declared here:";

const char kStackAllocatedFieldNote[] =
    "[blink-gc] Stack-allocated field %0 declared here:";

const char kMemberInUnmanagedClassNote[] =
    "[blink-gc] Member field %0 in unmanaged class declared here:";

const char kPartObjectToGCDerivedClassNote[] =
    "[blink-gc] Part-object field %0 to a GC derived class declared here:";

const char kPartObjectContainsGCRootNote[] =
    "[blink-gc] Field %0 with embedded GC root in %1 declared here:";

const char kFieldContainsGCRootNote[] =
    "[blink-gc] Field %0 defining a GC root declared here:";

const char kOverriddenNonVirtualTrace[] =
    "[blink-gc] Class %0 overrides non-virtual trace of base class %1.";

const char kOverriddenNonVirtualTraceNote[] =
    "[blink-gc] Non-virtual trace method declared here:";

const char kMissingTraceDispatchMethod[] =
    "[blink-gc] Class %0 is missing manual trace dispatch.";

const char kMissingFinalizeDispatchMethod[] =
    "[blink-gc] Class %0 is missing manual finalize dispatch.";

const char kVirtualAndManualDispatch[] =
    "[blink-gc] Class %0 contains or inherits virtual methods"
    " but implements manual dispatching.";

const char kMissingTraceDispatch[] =
    "[blink-gc] Missing dispatch to class %0 in manual trace dispatch.";

const char kMissingFinalizeDispatch[] =
    "[blink-gc] Missing dispatch to class %0 in manual finalize dispatch.";

const char kFinalizedFieldNote[] =
    "[blink-gc] Potentially finalized field %0 declared here:";

const char kEagerlyFinalizedFieldNote[] =
    "[blink-gc] Field %0 having eagerly finalized value, declared here:";

const char kUserDeclaredDestructorNote[] =
    "[blink-gc] User-declared destructor declared here:";

const char kUserDeclaredFinalizerNote[] =
    "[blink-gc] User-declared finalizer declared here:";

const char kBaseRequiresFinalizationNote[] =
    "[blink-gc] Base class %0 requiring finalization declared here:";

const char kFieldRequiresFinalizationNote[] =
    "[blink-gc] Field %0 requiring finalization declared here:";

const char kManualDispatchMethodNote[] =
    "[blink-gc] Manual dispatch %0 declared here:";

const char kDerivesNonStackAllocated[] =
    "[blink-gc] Stack-allocated class %0 derives class %1"
    " which is not stack allocated.";

const char kClassOverridesNew[] =
    "[blink-gc] Garbage collected class %0"
    " is not permitted to override its new operator.";

const char kClassDeclaresPureVirtualTrace[] =
    "[blink-gc] Garbage collected class %0"
    " is not permitted to declare a pure-virtual trace method.";

const char kLeftMostBaseMustBePolymorphic[] =
    "[blink-gc] Left-most base class %0 of derived class %1"
    " must be polymorphic.";

const char kBaseClassMustDeclareVirtualTrace[] =
    "[blink-gc] Left-most base class %0 of derived class %1"
    " must define a virtual trace method.";

const char kClassMustDeclareGCMixinTraceMethod[] =
    "[blink-gc] Class %0 which inherits from GarbageCollectedMixin must"
    " locally declare and override trace(Visitor*)";

// Use a local RAV implementation to simply collect all FunctionDecls marked for
// late template parsing. This happens with the flag -fdelayed-template-parsing,
// which is on by default in MSVC-compatible mode.
std::set<FunctionDecl*> GetLateParsedFunctionDecls(TranslationUnitDecl* decl) {
  struct Visitor : public RecursiveASTVisitor<Visitor> {
    bool VisitFunctionDecl(FunctionDecl* function_decl) {
      if (function_decl->isLateTemplateParsed())
        late_parsed_decls.insert(function_decl);
      return true;
    }

    std::set<FunctionDecl*> late_parsed_decls;
  } v;
  v.TraverseDecl(decl);
  return v.late_parsed_decls;
}

struct BlinkGCPluginOptions {
  BlinkGCPluginOptions()
    : enable_oilpan(false)
    , dump_graph(false)
    , warn_raw_ptr(false)
    , warn_unneeded_finalizer(false) {}
  bool enable_oilpan;
  bool dump_graph;
  bool warn_raw_ptr;
  bool warn_unneeded_finalizer;
  std::set<std::string> ignored_classes;
  std::set<std::string> checked_namespaces;
  std::vector<std::string> ignored_directories;
};

typedef std::vector<CXXRecordDecl*> RecordVector;
typedef std::vector<CXXMethodDecl*> MethodVector;

// Test if a template specialization is an instantiation.
static bool IsTemplateInstantiation(CXXRecordDecl* record) {
  ClassTemplateSpecializationDecl* spec =
      dyn_cast<ClassTemplateSpecializationDecl>(record);
  if (!spec)
    return false;
  switch (spec->getTemplateSpecializationKind()) {
    case TSK_ImplicitInstantiation:
    case TSK_ExplicitInstantiationDefinition:
      return true;
    case TSK_Undeclared:
    case TSK_ExplicitSpecialization:
      return false;
    // TODO: unsupported cases.
    case TSK_ExplicitInstantiationDeclaration:
      return false;
  }
  assert(false && "Unknown template specialization kind");
}

// This visitor collects the entry points for the checker.
class CollectVisitor : public RecursiveASTVisitor<CollectVisitor> {
 public:
  CollectVisitor() {}

  RecordVector& record_decls() { return record_decls_; }
  MethodVector& trace_decls() { return trace_decls_; }

  bool shouldVisitTemplateInstantiations() { return false; }

  // Collect record declarations, including nested declarations.
  bool VisitCXXRecordDecl(CXXRecordDecl* record) {
    if (record->hasDefinition() && record->isCompleteDefinition())
      record_decls_.push_back(record);
    return true;
  }

  // Collect tracing method definitions, but don't traverse method bodies.
  bool TraverseCXXMethodDecl(CXXMethodDecl* method) {
    if (method->isThisDeclarationADefinition() && Config::IsTraceMethod(method))
      trace_decls_.push_back(method);
    return true;
  }

 private:
  RecordVector record_decls_;
  MethodVector trace_decls_;
};

// This visitor checks that a finalizer method does not have invalid access to
// fields that are potentially finalized. A potentially finalized field is
// either a Member, a heap-allocated collection or an off-heap collection that
// contains Members.  Invalid uses are currently identified as passing the field
// as the argument of a procedure call or using the -> or [] operators on it.
class CheckFinalizerVisitor
    : public RecursiveASTVisitor<CheckFinalizerVisitor> {
 private:
  // Simple visitor to determine if the content of a field might be collected
  // during finalization.
  class MightBeCollectedVisitor : public EdgeVisitor {
   public:
    MightBeCollectedVisitor(bool is_eagerly_finalized)
        : might_be_collected_(false)
        , is_eagerly_finalized_(is_eagerly_finalized)
        , as_eagerly_finalized_(false) {}
    bool might_be_collected() { return might_be_collected_; }
    bool as_eagerly_finalized() { return as_eagerly_finalized_; }
    void VisitMember(Member* edge) override {
      if (is_eagerly_finalized_) {
        if (edge->ptr()->IsValue()) {
          Value* member = static_cast<Value*>(edge->ptr());
          if (member->value()->IsEagerlyFinalized()) {
            might_be_collected_ = true;
            as_eagerly_finalized_ = true;
          }
        }
        return;
      }
      might_be_collected_ = true;
    }
    void VisitCollection(Collection* edge) override {
      if (edge->on_heap() && !is_eagerly_finalized_) {
        might_be_collected_ = !edge->is_root();
      } else {
        edge->AcceptMembers(this);
      }
    }

   private:
    bool might_be_collected_;
    bool is_eagerly_finalized_;
    bool as_eagerly_finalized_;
  };

 public:
  class Error {
  public:
    Error(MemberExpr *member,
          bool as_eagerly_finalized,
          FieldPoint* field)
        : member_(member)
        , as_eagerly_finalized_(as_eagerly_finalized)
        , field_(field) {}

    MemberExpr* member_;
    bool as_eagerly_finalized_;
    FieldPoint* field_;
  };

  typedef std::vector<Error> Errors;

  CheckFinalizerVisitor(RecordCache* cache, bool is_eagerly_finalized)
      : blacklist_context_(false)
      , cache_(cache)
      , is_eagerly_finalized_(is_eagerly_finalized) {}

  Errors& finalized_fields() { return finalized_fields_; }

  bool WalkUpFromCXXOperatorCallExpr(CXXOperatorCallExpr* expr) {
    // Only continue the walk-up if the operator is a blacklisted one.
    switch (expr->getOperator()) {
      case OO_Arrow:
      case OO_Subscript:
        this->WalkUpFromCallExpr(expr);
      default:
        return true;
    }
  }

  // We consider all non-operator calls to be blacklisted contexts.
  bool WalkUpFromCallExpr(CallExpr* expr) {
    bool prev_blacklist_context = blacklist_context_;
    blacklist_context_ = true;
    for (size_t i = 0; i < expr->getNumArgs(); ++i)
      this->TraverseStmt(expr->getArg(i));
    blacklist_context_ = prev_blacklist_context;
    return true;
  }

  bool VisitMemberExpr(MemberExpr* member) {
    FieldDecl* field = dyn_cast<FieldDecl>(member->getMemberDecl());
    if (!field)
      return true;

    RecordInfo* info = cache_->Lookup(field->getParent());
    if (!info)
      return true;

    RecordInfo::Fields::iterator it = info->GetFields().find(field);
    if (it == info->GetFields().end())
      return true;

    if (seen_members_.find(member) != seen_members_.end())
      return true;

    bool as_eagerly_finalized = false;
    if (blacklist_context_ &&
        MightBeCollected(&it->second, as_eagerly_finalized)) {
      finalized_fields_.push_back(
          Error(member, as_eagerly_finalized, &it->second));
      seen_members_.insert(member);
    }
    return true;
  }

  bool MightBeCollected(FieldPoint* point, bool& as_eagerly_finalized) {
    MightBeCollectedVisitor visitor(is_eagerly_finalized_);
    point->edge()->Accept(&visitor);
    as_eagerly_finalized = visitor.as_eagerly_finalized();
    return visitor.might_be_collected();
  }

 private:
  bool blacklist_context_;
  Errors finalized_fields_;
  std::set<MemberExpr*> seen_members_;
  RecordCache* cache_;
  bool is_eagerly_finalized_;
};

// This visitor checks that a method contains within its body, a call to a
// method on the provided receiver class. This is used to check manual
// dispatching for trace and finalize methods.
class CheckDispatchVisitor : public RecursiveASTVisitor<CheckDispatchVisitor> {
 public:
  CheckDispatchVisitor(RecordInfo* receiver)
      : receiver_(receiver), dispatched_to_receiver_(false) {}

  bool dispatched_to_receiver() { return dispatched_to_receiver_; }

  bool VisitMemberExpr(MemberExpr* member) {
    if (CXXMethodDecl* fn = dyn_cast<CXXMethodDecl>(member->getMemberDecl())) {
      if (fn->getParent() == receiver_->record())
        dispatched_to_receiver_ = true;
    }
    return true;
  }

  bool VisitUnresolvedMemberExpr(UnresolvedMemberExpr* member) {
    for (Decl* decl : member->decls()) {
      if (CXXMethodDecl* method = dyn_cast<CXXMethodDecl>(decl)) {
        if (method->getParent() == receiver_->record() &&
            Config::GetTraceMethodType(method) ==
            Config::TRACE_AFTER_DISPATCH_METHOD) {
          dispatched_to_receiver_ = true;
          return true;
        }
      }
    }
    return true;
  }

 private:
  RecordInfo* receiver_;
  bool dispatched_to_receiver_;
};

// This visitor checks a tracing method by traversing its body.
// - A member field is considered traced if it is referenced in the body.
// - A base is traced if a base-qualified call to a trace method is found.
class CheckTraceVisitor : public RecursiveASTVisitor<CheckTraceVisitor> {
 public:
  CheckTraceVisitor(CXXMethodDecl* trace, RecordInfo* info, RecordCache* cache)
      : trace_(trace),
        info_(info),
        cache_(cache),
        delegates_to_traceimpl_(false) {
  }

  bool delegates_to_traceimpl() const { return delegates_to_traceimpl_; }

  bool VisitMemberExpr(MemberExpr* member) {
    // In weak callbacks, consider any occurrence as a correct usage.
    // TODO: We really want to require that isAlive is checked on manually
    // processed weak fields.
    if (IsWeakCallback()) {
      if (FieldDecl* field = dyn_cast<FieldDecl>(member->getMemberDecl()))
        FoundField(field);
    }
    return true;
  }

  bool VisitCallExpr(CallExpr* call) {
    // In weak callbacks we don't check calls (see VisitMemberExpr).
    if (IsWeakCallback())
      return true;

    Expr* callee = call->getCallee();

    // Trace calls from a templated derived class result in a
    // DependentScopeMemberExpr because the concrete trace call depends on the
    // instantiation of any shared template parameters. In this case the call is
    // "unresolved" and we resort to comparing the syntactic type names.
    if (CXXDependentScopeMemberExpr* expr =
        dyn_cast<CXXDependentScopeMemberExpr>(callee)) {
      CheckCXXDependentScopeMemberExpr(call, expr);
      return true;
    }

    // A tracing call will have either a |visitor| or a |m_field| argument.
    // A registerWeakMembers call will have a |this| argument.
    if (call->getNumArgs() != 1)
      return true;
    Expr* arg = call->getArg(0);

    if (UnresolvedMemberExpr* expr = dyn_cast<UnresolvedMemberExpr>(callee)) {
      // This could be a trace call of a base class, as explained in the
      // comments of CheckTraceBaseCall().
      if (CheckTraceBaseCall(call))
        return true;

      if (expr->getMemberName().getAsString() == kRegisterWeakMembersName)
        MarkAllWeakMembersTraced();

      QualType base = expr->getBaseType();
      if (!base->isPointerType())
        return true;
      CXXRecordDecl* decl = base->getPointeeType()->getAsCXXRecordDecl();
      if (decl)
        CheckTraceFieldCall(expr->getMemberName().getAsString(), decl, arg);
      if (Config::IsTraceImplName(expr->getMemberName().getAsString()))
        delegates_to_traceimpl_ = true;
      return true;
    }

    if (CXXMemberCallExpr* expr = dyn_cast<CXXMemberCallExpr>(call)) {
      if (CheckTraceFieldCall(expr) || CheckRegisterWeakMembers(expr))
        return true;

      if (Config::IsTraceImplName(expr->getMethodDecl()->getNameAsString())) {
        delegates_to_traceimpl_ = true;
        return true;
      }
    }

    CheckTraceBaseCall(call);
    return true;
  }

 private:
  bool IsTraceCallName(const std::string& name) {
    if (trace_->getName() == kTraceImplName)
      return name == kTraceName;
    if (trace_->getName() == kTraceAfterDispatchImplName)
      return name == kTraceAfterDispatchName;
    // Currently, a manually dispatched class cannot have mixin bases (having
    // one would add a vtable which we explicitly check against). This means
    // that we can only make calls to a trace method of the same name. Revisit
    // this if our mixin/vtable assumption changes.
    return name == trace_->getName();
  }

  CXXRecordDecl* GetDependentTemplatedDecl(CXXDependentScopeMemberExpr* expr) {
    NestedNameSpecifier* qual = expr->getQualifier();
    if (!qual)
      return 0;

    const Type* type = qual->getAsType();
    if (!type)
      return 0;

    return RecordInfo::GetDependentTemplatedDecl(*type);
  }

  void CheckCXXDependentScopeMemberExpr(CallExpr* call,
                                        CXXDependentScopeMemberExpr* expr) {
    string fn_name = expr->getMember().getAsString();

    // Check for VisitorDispatcher::trace(field) and
    // VisitorDispatcher::registerWeakMembers.
    if (!expr->isImplicitAccess()) {
      if (clang::DeclRefExpr* base_decl =
              clang::dyn_cast<clang::DeclRefExpr>(expr->getBase())) {
        if (Config::IsVisitorDispatcherType(base_decl->getType())) {
          if (call->getNumArgs() == 1 && fn_name == kTraceName) {
            FindFieldVisitor finder;
            finder.TraverseStmt(call->getArg(0));
            if (finder.field())
              FoundField(finder.field());

            return;
          } else if (call->getNumArgs() == 1 &&
                     fn_name == kRegisterWeakMembersName) {
            MarkAllWeakMembersTraced();
          }
        }
      }
    }

    CXXRecordDecl* tmpl = GetDependentTemplatedDecl(expr);
    if (!tmpl)
      return;

    // Check for Super<T>::trace(visitor)
    if (call->getNumArgs() == 1 && IsTraceCallName(fn_name)) {
      RecordInfo::Bases::iterator it = info_->GetBases().begin();
      for (; it != info_->GetBases().end(); ++it) {
        if (it->first->getName() == tmpl->getName())
          it->second.MarkTraced();
      }
    }

    // Check for TraceIfNeeded<T>::trace(visitor, &field)
    if (call->getNumArgs() == 2 && fn_name == kTraceName &&
        tmpl->getName() == kTraceIfNeededName) {
      FindFieldVisitor finder;
      finder.TraverseStmt(call->getArg(1));
      if (finder.field())
        FoundField(finder.field());
    }
  }

  bool CheckTraceBaseCall(CallExpr* call) {
    // Checks for "Base::trace(visitor)"-like calls.

    // Checking code for these two variables is shared among MemberExpr* case
    // and UnresolvedMemberCase* case below.
    //
    // For example, if we've got "Base::trace(visitor)" as |call|,
    // callee_record will be "Base", and func_name will be "trace".
    CXXRecordDecl* callee_record = nullptr;
    std::string func_name;

    if (MemberExpr* callee = dyn_cast<MemberExpr>(call->getCallee())) {
      if (!callee->hasQualifier())
        return false;

      FunctionDecl* trace_decl =
          dyn_cast<FunctionDecl>(callee->getMemberDecl());
      if (!trace_decl || !Config::IsTraceMethod(trace_decl))
        return false;

      const Type* type = callee->getQualifier()->getAsType();
      if (!type)
        return false;

      callee_record = type->getAsCXXRecordDecl();
      func_name = trace_decl->getName();
    } else if (UnresolvedMemberExpr* callee =
               dyn_cast<UnresolvedMemberExpr>(call->getCallee())) {
      // Callee part may become unresolved if the type of the argument
      // ("visitor") is a template parameter and the called function is
      // overloaded (i.e. trace(Visitor*) and
      // trace(InlinedGlobalMarkingVisitor)).
      //
      // Here, we try to find a function that looks like trace() from the
      // candidate overloaded functions, and if we find one, we assume it is
      // called here.

      CXXMethodDecl* trace_decl = nullptr;
      for (NamedDecl* named_decl : callee->decls()) {
        if (CXXMethodDecl* method_decl = dyn_cast<CXXMethodDecl>(named_decl)) {
          if (Config::IsTraceMethod(method_decl)) {
            trace_decl = method_decl;
            break;
          }
        }
      }
      if (!trace_decl)
        return false;

      // Check if the passed argument is named "visitor".
      if (call->getNumArgs() != 1)
        return false;
      DeclRefExpr* arg = dyn_cast<DeclRefExpr>(call->getArg(0));
      if (!arg || arg->getNameInfo().getAsString() != kVisitorVarName)
        return false;

      callee_record = trace_decl->getParent();
      func_name = callee->getMemberName().getAsString();
    }

    if (!callee_record)
      return false;

    if (!IsTraceCallName(func_name))
      return false;

    for (auto& base : info_->GetBases()) {
      // We want to deal with omitted trace() function in an intermediary
      // class in the class hierarchy, e.g.:
      //     class A : public GarbageCollected<A> { trace() { ... } };
      //     class B : public A { /* No trace(); have nothing to trace. */ };
      //     class C : public B { trace() { B::trace(visitor); } }
      // where, B::trace() is actually A::trace(), and in some cases we get
      // A as |callee_record| instead of B. We somehow need to mark B as
      // traced if we find A::trace() call.
      //
      // To solve this, here we keep going up the class hierarchy as long as
      // they are not required to have a trace method. The implementation is
      // a simple DFS, where |base_records| represents the set of base classes
      // we need to visit.

      std::vector<CXXRecordDecl*> base_records;
      base_records.push_back(base.first);

      while (!base_records.empty()) {
        CXXRecordDecl* base_record = base_records.back();
        base_records.pop_back();

        if (base_record == callee_record) {
          // If we find a matching trace method, pretend the user has written
          // a correct trace() method of the base; in the example above, we
          // find A::trace() here and mark B as correctly traced.
          base.second.MarkTraced();
          return true;
        }

        if (RecordInfo* base_info = cache_->Lookup(base_record)) {
          if (!base_info->RequiresTraceMethod()) {
            // If this base class is not required to have a trace method, then
            // the actual trace method may be defined in an ancestor.
            for (auto& inner_base : base_info->GetBases())
              base_records.push_back(inner_base.first);
          }
        }
      }
    }

    return false;
  }

  bool CheckTraceFieldCall(CXXMemberCallExpr* call) {
    return CheckTraceFieldCall(call->getMethodDecl()->getNameAsString(),
                               call->getRecordDecl(),
                               call->getArg(0));
  }

  bool CheckTraceFieldCall(string name, CXXRecordDecl* callee, Expr* arg) {
    if (name != kTraceName || !Config::IsVisitor(callee->getName()))
      return false;

    FindFieldVisitor finder;
    finder.TraverseStmt(arg);
    if (finder.field())
      FoundField(finder.field());

    return true;
  }

  bool CheckRegisterWeakMembers(CXXMemberCallExpr* call) {
    CXXMethodDecl* fn = call->getMethodDecl();
    if (fn->getName() != kRegisterWeakMembersName)
      return false;

    if (fn->isTemplateInstantiation()) {
      const TemplateArgumentList& args =
          *fn->getTemplateSpecializationInfo()->TemplateArguments;
      // The second template argument is the callback method.
      if (args.size() > 1 &&
          args[1].getKind() == TemplateArgument::Declaration) {
        if (FunctionDecl* callback =
            dyn_cast<FunctionDecl>(args[1].getAsDecl())) {
          if (callback->hasBody()) {
            CheckTraceVisitor nested_visitor(info_);
            nested_visitor.TraverseStmt(callback->getBody());
          }
        }
      }
    }
    return true;
  }

  class FindFieldVisitor : public RecursiveASTVisitor<FindFieldVisitor> {
   public:
    FindFieldVisitor() : member_(0), field_(0) {}
    MemberExpr* member() const { return member_; }
    FieldDecl* field() const { return field_; }
    bool TraverseMemberExpr(MemberExpr* member) {
      if (FieldDecl* field = dyn_cast<FieldDecl>(member->getMemberDecl())) {
        member_ = member;
        field_ = field;
        return false;
      }
      return true;
    }
   private:
    MemberExpr* member_;
    FieldDecl* field_;
  };

  // Nested checking for weak callbacks.
  CheckTraceVisitor(RecordInfo* info)
      : trace_(nullptr), info_(info), cache_(nullptr) {}

  bool IsWeakCallback() { return !trace_; }

  void MarkTraced(RecordInfo::Fields::iterator it) {
    // In a weak callback we can't mark strong fields as traced.
    if (IsWeakCallback() && !it->second.edge()->IsWeakMember())
      return;
    it->second.MarkTraced();
  }

  void FoundField(FieldDecl* field) {
    if (IsTemplateInstantiation(info_->record())) {
      // Pointer equality on fields does not work for template instantiations.
      // The trace method refers to fields of the template definition which
      // are different from the instantiated fields that need to be traced.
      const string& name = field->getNameAsString();
      for (RecordInfo::Fields::iterator it = info_->GetFields().begin();
           it != info_->GetFields().end();
           ++it) {
        if (it->first->getNameAsString() == name) {
          MarkTraced(it);
          break;
        }
      }
    } else {
      RecordInfo::Fields::iterator it = info_->GetFields().find(field);
      if (it != info_->GetFields().end())
        MarkTraced(it);
    }
  }

  void MarkAllWeakMembersTraced() {
    // If we find a call to registerWeakMembers which is unresolved we
    // unsoundly consider all weak members as traced.
    // TODO: Find out how to validate weak member tracing for unresolved call.
    for (auto& field : info_->GetFields()) {
      if (field.second.edge()->IsWeakMember())
        field.second.MarkTraced();
    }
  }

  CXXMethodDecl* trace_;
  RecordInfo* info_;
  RecordCache* cache_;
  bool delegates_to_traceimpl_;
};

// This visitor checks that the fields of a class and the fields of
// its part objects don't define GC roots.
class CheckGCRootsVisitor : public RecursiveEdgeVisitor {
 public:
  typedef std::vector<FieldPoint*> RootPath;
  typedef std::set<RecordInfo*> VisitingSet;
  typedef std::vector<RootPath> Errors;

  CheckGCRootsVisitor() {}

  Errors& gc_roots() { return gc_roots_; }

  bool ContainsGCRoots(RecordInfo* info) {
    for (RecordInfo::Fields::iterator it = info->GetFields().begin();
         it != info->GetFields().end();
         ++it) {
      current_.push_back(&it->second);
      it->second.edge()->Accept(this);
      current_.pop_back();
    }
    return !gc_roots_.empty();
  }

  void VisitValue(Value* edge) override {
    // TODO: what should we do to check unions?
    if (edge->value()->record()->isUnion())
      return;

    // Prevent infinite regress for cyclic part objects.
    if (visiting_set_.find(edge->value()) != visiting_set_.end())
      return;

    visiting_set_.insert(edge->value());
    // If the value is a part object, then continue checking for roots.
    for (Context::iterator it = context().begin();
         it != context().end();
         ++it) {
      if (!(*it)->IsCollection())
        return;
    }
    ContainsGCRoots(edge->value());
    visiting_set_.erase(edge->value());
  }

  void VisitPersistent(Persistent* edge) override {
    gc_roots_.push_back(current_);
  }

  void AtCollection(Collection* edge) override {
    if (edge->is_root())
      gc_roots_.push_back(current_);
  }

 protected:
  RootPath current_;
  VisitingSet visiting_set_;
  Errors gc_roots_;
};

// This visitor checks that the fields of a class are "well formed".
// - OwnPtr, RefPtr and RawPtr must not point to a GC derived types.
// - Part objects must not be GC derived types.
// - An on-heap class must never contain GC roots.
// - Only stack-allocated types may point to stack-allocated types.
class CheckFieldsVisitor : public RecursiveEdgeVisitor {
 public:

  enum Error {
    kRawPtrToGCManaged,
    kRawPtrToGCManagedWarning,
    kRefPtrToGCManaged,
    kOwnPtrToGCManaged,
    kMemberToGCUnmanaged,
    kMemberInUnmanaged,
    kPtrFromHeapToStack,
    kGCDerivedPartObject
  };

  typedef std::vector<std::pair<FieldPoint*, Error> > Errors;

  CheckFieldsVisitor(const BlinkGCPluginOptions& options)
      : options_(options), current_(0), stack_allocated_host_(false) {}

  Errors& invalid_fields() { return invalid_fields_; }

  bool ContainsInvalidFields(RecordInfo* info) {
    stack_allocated_host_ = info->IsStackAllocated();
    managed_host_ = stack_allocated_host_ ||
                    info->IsGCAllocated() ||
                    info->IsNonNewable() ||
                    info->IsOnlyPlacementNewable();
    for (RecordInfo::Fields::iterator it = info->GetFields().begin();
         it != info->GetFields().end();
         ++it) {
      context().clear();
      current_ = &it->second;
      current_->edge()->Accept(this);
    }
    return !invalid_fields_.empty();
  }

  void AtMember(Member* edge) override {
    if (managed_host_)
      return;
    // A member is allowed to appear in the context of a root.
    for (Context::iterator it = context().begin();
         it != context().end();
         ++it) {
      if ((*it)->Kind() == Edge::kRoot)
        return;
    }
    invalid_fields_.push_back(std::make_pair(current_, kMemberInUnmanaged));
  }

  void AtValue(Value* edge) override {
    // TODO: what should we do to check unions?
    if (edge->value()->record()->isUnion())
      return;

    if (!stack_allocated_host_ && edge->value()->IsStackAllocated()) {
      invalid_fields_.push_back(std::make_pair(current_, kPtrFromHeapToStack));
      return;
    }

    if (!Parent() &&
        edge->value()->IsGCDerived() &&
        !edge->value()->IsGCMixin()) {
      invalid_fields_.push_back(std::make_pair(current_, kGCDerivedPartObject));
      return;
    }

    // If in a stack allocated context, be fairly insistent that T in Member<T>
    // is GC allocated, as stack allocated objects do not have a trace()
    // that separately verifies the validity of Member<T>.
    //
    // Notice that an error is only reported if T's definition is in scope;
    // we do not require that it must be brought into scope as that would
    // prevent declarations of mutually dependent class types.
    //
    // (Note: Member<>'s constructor will at run-time verify that the
    // pointer it wraps is indeed heap allocated.)
    if (stack_allocated_host_ && Parent() && Parent()->IsMember() &&
        edge->value()->HasDefinition() && !edge->value()->IsGCAllocated()) {
      invalid_fields_.push_back(std::make_pair(current_,
                                               kMemberToGCUnmanaged));
      return;
    }

    if (!Parent() || !edge->value()->IsGCAllocated())
      return;

    // In transition mode, disallow  OwnPtr<T>, RawPtr<T> to GC allocated T's,
    // also disallow T* in stack-allocated types.
    if (options_.enable_oilpan) {
      if (Parent()->IsOwnPtr() ||
          Parent()->IsRawPtrClass() ||
          (stack_allocated_host_ && Parent()->IsRawPtr())) {
        invalid_fields_.push_back(std::make_pair(
            current_, InvalidSmartPtr(Parent())));
        return;
      }
      if (options_.warn_raw_ptr && Parent()->IsRawPtr()) {
        invalid_fields_.push_back(std::make_pair(
            current_, kRawPtrToGCManagedWarning));
      }
      return;
    }

    if (Parent()->IsRawPtr() || Parent()->IsRefPtr() || Parent()->IsOwnPtr()) {
      invalid_fields_.push_back(std::make_pair(
          current_, InvalidSmartPtr(Parent())));
      return;
    }
  }

  void AtCollection(Collection* edge) override {
    if (edge->on_heap() && Parent() && Parent()->IsOwnPtr())
      invalid_fields_.push_back(std::make_pair(current_, kOwnPtrToGCManaged));
  }

 private:
  Error InvalidSmartPtr(Edge* ptr) {
    if (ptr->IsRawPtr())
      return kRawPtrToGCManaged;
    if (ptr->IsRefPtr())
      return kRefPtrToGCManaged;
    if (ptr->IsOwnPtr())
      return kOwnPtrToGCManaged;
    assert(false && "Unknown smart pointer kind");
  }

  const BlinkGCPluginOptions& options_;
  FieldPoint* current_;
  bool stack_allocated_host_;
  bool managed_host_;
  Errors invalid_fields_;
};

class EmptyStmtVisitor
    : public RecursiveASTVisitor<EmptyStmtVisitor> {
public:
  static bool isEmpty(Stmt* stmt) {
    EmptyStmtVisitor visitor;
    visitor.TraverseStmt(stmt);
    return visitor.empty_;
  }

  bool WalkUpFromCompoundStmt(CompoundStmt* stmt) {
    empty_ = stmt->body_empty();
    return false;
  }
  bool VisitStmt(Stmt*) {
    empty_ = false;
    return false;
  }
private:
  EmptyStmtVisitor() : empty_(true) {}
  bool empty_;
};

// Main class containing checks for various invariants of the Blink
// garbage collection infrastructure.
class BlinkGCPluginConsumer : public ASTConsumer {
 public:
  BlinkGCPluginConsumer(CompilerInstance& instance,
                        const BlinkGCPluginOptions& options)
      : instance_(instance),
        diagnostic_(instance.getDiagnostics()),
        options_(options),
        json_(0) {

    // Only check structures in the blink and WebKit namespaces.
    options_.checked_namespaces.insert("blink");

    // Ignore GC implementation files.
    options_.ignored_directories.push_back("/heap/");

    // Register warning/error messages.
    diag_class_must_left_mostly_derive_gc_ = diagnostic_.getCustomDiagID(
        getErrorLevel(), kClassMustLeftMostlyDeriveGC);
    diag_class_requires_trace_method_ =
        diagnostic_.getCustomDiagID(getErrorLevel(), kClassRequiresTraceMethod);
    diag_base_requires_tracing_ =
        diagnostic_.getCustomDiagID(getErrorLevel(), kBaseRequiresTracing);
    diag_fields_require_tracing_ =
        diagnostic_.getCustomDiagID(getErrorLevel(), kFieldsRequireTracing);
    diag_class_contains_invalid_fields_ = diagnostic_.getCustomDiagID(
        getErrorLevel(), kClassContainsInvalidFields);
    diag_class_contains_invalid_fields_warning_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Warning, kClassContainsInvalidFields);
    diag_class_contains_gc_root_ =
        diagnostic_.getCustomDiagID(getErrorLevel(), kClassContainsGCRoot);
    diag_class_requires_finalization_ = diagnostic_.getCustomDiagID(
        getErrorLevel(), kClassRequiresFinalization);
    diag_class_does_not_require_finalization_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Warning, kClassDoesNotRequireFinalization);
    diag_finalizer_accesses_finalized_field_ = diagnostic_.getCustomDiagID(
        getErrorLevel(), kFinalizerAccessesFinalizedField);
    diag_finalizer_eagerly_finalized_field_ = diagnostic_.getCustomDiagID(
        getErrorLevel(), kFinalizerAccessesEagerlyFinalizedField);
    diag_overridden_non_virtual_trace_ = diagnostic_.getCustomDiagID(
        getErrorLevel(), kOverriddenNonVirtualTrace);
    diag_missing_trace_dispatch_method_ = diagnostic_.getCustomDiagID(
        getErrorLevel(), kMissingTraceDispatchMethod);
    diag_missing_finalize_dispatch_method_ = diagnostic_.getCustomDiagID(
        getErrorLevel(), kMissingFinalizeDispatchMethod);
    diag_virtual_and_manual_dispatch_ =
        diagnostic_.getCustomDiagID(getErrorLevel(), kVirtualAndManualDispatch);
    diag_missing_trace_dispatch_ =
        diagnostic_.getCustomDiagID(getErrorLevel(), kMissingTraceDispatch);
    diag_missing_finalize_dispatch_ =
        diagnostic_.getCustomDiagID(getErrorLevel(), kMissingFinalizeDispatch);
    diag_derives_non_stack_allocated_ =
        diagnostic_.getCustomDiagID(getErrorLevel(), kDerivesNonStackAllocated);
    diag_class_overrides_new_ =
        diagnostic_.getCustomDiagID(getErrorLevel(), kClassOverridesNew);
    diag_class_declares_pure_virtual_trace_ = diagnostic_.getCustomDiagID(
        getErrorLevel(), kClassDeclaresPureVirtualTrace);
    diag_left_most_base_must_be_polymorphic_ = diagnostic_.getCustomDiagID(
        getErrorLevel(), kLeftMostBaseMustBePolymorphic);
    diag_base_class_must_declare_virtual_trace_ = diagnostic_.getCustomDiagID(
        getErrorLevel(), kBaseClassMustDeclareVirtualTrace);
    diag_class_must_declare_gc_mixin_trace_method_ =
        diagnostic_.getCustomDiagID(getErrorLevel(),
                                    kClassMustDeclareGCMixinTraceMethod);

    // Register note messages.
    diag_base_requires_tracing_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kBaseRequiresTracingNote);
    diag_field_requires_tracing_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kFieldRequiresTracingNote);
    diag_raw_ptr_to_gc_managed_class_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kRawPtrToGCManagedClassNote);
    diag_ref_ptr_to_gc_managed_class_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kRefPtrToGCManagedClassNote);
    diag_own_ptr_to_gc_managed_class_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kOwnPtrToGCManagedClassNote);
    diag_member_to_gc_unmanaged_class_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kMemberToGCUnmanagedClassNote);
    diag_stack_allocated_field_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kStackAllocatedFieldNote);
    diag_member_in_unmanaged_class_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kMemberInUnmanagedClassNote);
    diag_part_object_to_gc_derived_class_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kPartObjectToGCDerivedClassNote);
    diag_part_object_contains_gc_root_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kPartObjectContainsGCRootNote);
    diag_field_contains_gc_root_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kFieldContainsGCRootNote);
    diag_finalized_field_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kFinalizedFieldNote);
    diag_eagerly_finalized_field_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kEagerlyFinalizedFieldNote);
    diag_user_declared_destructor_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kUserDeclaredDestructorNote);
    diag_user_declared_finalizer_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kUserDeclaredFinalizerNote);
    diag_base_requires_finalization_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kBaseRequiresFinalizationNote);
    diag_field_requires_finalization_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kFieldRequiresFinalizationNote);
    diag_overridden_non_virtual_trace_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kOverriddenNonVirtualTraceNote);
    diag_manual_dispatch_method_note_ = diagnostic_.getCustomDiagID(
        DiagnosticsEngine::Note, kManualDispatchMethodNote);
  }

  void HandleTranslationUnit(ASTContext& context) override {
    // Don't run the plugin if the compilation unit is already invalid.
    if (diagnostic_.hasErrorOccurred())
      return;

    ParseFunctionTemplates(context.getTranslationUnitDecl());

    CollectVisitor visitor;
    visitor.TraverseDecl(context.getTranslationUnitDecl());

    if (options_.dump_graph) {
      std::error_code err;
      // TODO: Make createDefaultOutputFile or a shorter createOutputFile work.
      json_ = JsonWriter::from(instance_.createOutputFile(
          "",                                      // OutputPath
          err,                                     // Errors
          true,                                    // Binary
          true,                                    // RemoveFileOnSignal
          instance_.getFrontendOpts().OutputFile,  // BaseInput
          "graph.json",                            // Extension
          false,                                   // UseTemporary
          false,                                   // CreateMissingDirectories
          0,                                       // ResultPathName
          0));                                     // TempPathName
      if (!err && json_) {
        json_->OpenList();
      } else {
        json_ = 0;
        llvm::errs()
            << "[blink-gc] "
            << "Failed to create an output file for the object graph.\n";
      }
    }

    for (RecordVector::iterator it = visitor.record_decls().begin();
         it != visitor.record_decls().end();
         ++it) {
      CheckRecord(cache_.Lookup(*it));
    }

    for (MethodVector::iterator it = visitor.trace_decls().begin();
         it != visitor.trace_decls().end();
         ++it) {
      CheckTracingMethod(*it);
    }

    if (json_) {
      json_->CloseList();
      delete json_;
      json_ = 0;
    }
  }

  void ParseFunctionTemplates(TranslationUnitDecl* decl) {
    if (!instance_.getLangOpts().DelayedTemplateParsing)
      return;  // Nothing to do.

    std::set<FunctionDecl*> late_parsed_decls =
        GetLateParsedFunctionDecls(decl);
    clang::Sema& sema = instance_.getSema();

    for (const FunctionDecl* fd : late_parsed_decls) {
      assert(fd->isLateTemplateParsed());

      if (!Config::IsTraceMethod(fd))
        continue;

      if (instance_.getSourceManager().isInSystemHeader(
              instance_.getSourceManager().getSpellingLoc(fd->getLocation())))
        continue;

      // Force parsing and AST building of the yet-uninstantiated function
      // template trace method bodies.
      clang::LateParsedTemplate* lpt = sema.LateParsedTemplateMap[fd];
      sema.LateTemplateParser(sema.OpaqueParser, *lpt);
    }
  }

  // Main entry for checking a record declaration.
  void CheckRecord(RecordInfo* info) {
    if (IsIgnored(info))
      return;

    CXXRecordDecl* record = info->record();

    // TODO: what should we do to check unions?
    if (record->isUnion())
      return;

    // If this is the primary template declaration, check its specializations.
    if (record->isThisDeclarationADefinition() &&
        record->getDescribedClassTemplate()) {
      ClassTemplateDecl* tmpl = record->getDescribedClassTemplate();
      for (ClassTemplateDecl::spec_iterator it = tmpl->spec_begin();
           it != tmpl->spec_end();
           ++it) {
        CheckClass(cache_.Lookup(*it));
      }
      return;
    }

    CheckClass(info);
  }

  // Check a class-like object (eg, class, specialization, instantiation).
  void CheckClass(RecordInfo* info) {
    if (!info)
      return;

    // Check consistency of stack-allocated hierarchies.
    if (info->IsStackAllocated()) {
      for (RecordInfo::Bases::iterator it = info->GetBases().begin();
           it != info->GetBases().end();
           ++it) {
        if (!it->second.info()->IsStackAllocated())
          ReportDerivesNonStackAllocated(info, &it->second);
      }
    }

    if (CXXMethodDecl* trace = info->GetTraceMethod()) {
      if (trace->isPure())
        ReportClassDeclaresPureVirtualTrace(info, trace);
    } else if (info->RequiresTraceMethod()) {
      ReportClassRequiresTraceMethod(info);
    }

    // Check polymorphic classes that are GC-derived or have a trace method.
    if (info->record()->hasDefinition() && info->record()->isPolymorphic()) {
      // TODO: Check classes that inherit a trace method.
      CXXMethodDecl* trace = info->GetTraceMethod();
      if (trace || info->IsGCDerived())
        CheckPolymorphicClass(info, trace);
    }

    {
      CheckFieldsVisitor visitor(options_);
      if (visitor.ContainsInvalidFields(info))
        ReportClassContainsInvalidFields(info, &visitor.invalid_fields());
    }

    if (info->IsGCDerived()) {

      if (!info->IsGCMixin()) {
        CheckLeftMostDerived(info);
        CheckDispatch(info);
        if (CXXMethodDecl* newop = info->DeclaresNewOperator())
          if (!Config::IsIgnoreAnnotated(newop))
            ReportClassOverridesNew(info, newop);
        if (info->IsGCMixinInstance()) {
          // Require that declared GCMixin implementations
          // also provide a trace() override.
          if (info->DeclaresGCMixinMethods()
              && !info->DeclaresLocalTraceMethod())
            ReportClassMustDeclareGCMixinTraceMethod(info);
        }
      }

      {
        CheckGCRootsVisitor visitor;
        if (visitor.ContainsGCRoots(info))
          ReportClassContainsGCRoots(info, &visitor.gc_roots());
      }

      if (info->NeedsFinalization())
        CheckFinalization(info);

      if (options_.warn_unneeded_finalizer && info->IsGCFinalized())
        CheckUnneededFinalization(info);
    }

    DumpClass(info);
  }

  CXXRecordDecl* GetDependentTemplatedDecl(const Type& type) {
    const TemplateSpecializationType* tmpl_type =
        type.getAs<TemplateSpecializationType>();
    if (!tmpl_type)
      return 0;

    TemplateDecl* tmpl_decl = tmpl_type->getTemplateName().getAsTemplateDecl();
    if (!tmpl_decl)
      return 0;

    return dyn_cast<CXXRecordDecl>(tmpl_decl->getTemplatedDecl());
  }

  // The GC infrastructure assumes that if the vtable of a polymorphic
  // base-class is not initialized for a given object (ie, it is partially
  // initialized) then the object does not need to be traced. Thus, we must
  // ensure that any polymorphic class with a trace method does not have any
  // tractable fields that are initialized before we are sure that the vtable
  // and the trace method are both defined.  There are two cases that need to
  // hold to satisfy that assumption:
  //
  // 1. If trace is virtual, then it must be defined in the left-most base.
  // This ensures that if the vtable is initialized then it contains a pointer
  // to the trace method.
  //
  // 2. If trace is non-virtual, then the trace method is defined and we must
  // ensure that the left-most base defines a vtable. This ensures that the
  // first thing to be initialized when constructing the object is the vtable
  // itself.
  void CheckPolymorphicClass(RecordInfo* info, CXXMethodDecl* trace) {
    CXXRecordDecl* left_most = info->record();
    CXXRecordDecl::base_class_iterator it = left_most->bases_begin();
    CXXRecordDecl* left_most_base = 0;
    while (it != left_most->bases_end()) {
      left_most_base = it->getType()->getAsCXXRecordDecl();
      if (!left_most_base && it->getType()->isDependentType())
        left_most_base = RecordInfo::GetDependentTemplatedDecl(*it->getType());

      // TODO: Find a way to correctly check actual instantiations
      // for dependent types. The escape below will be hit, eg, when
      // we have a primary template with no definition and
      // specializations for each case (such as SupplementBase) in
      // which case we don't succeed in checking the required
      // properties.
      if (!left_most_base || !left_most_base->hasDefinition())
        return;

      StringRef name = left_most_base->getName();
      // We know GCMixin base defines virtual trace.
      if (Config::IsGCMixinBase(name))
        return;

      // Stop with the left-most prior to a safe polymorphic base (a safe base
      // is non-polymorphic and contains no fields).
      if (Config::IsSafePolymorphicBase(name))
        break;

      left_most = left_most_base;
      it = left_most->bases_begin();
    }

    if (RecordInfo* left_most_info = cache_.Lookup(left_most)) {

      // Check condition (1):
      if (trace && trace->isVirtual()) {
        if (CXXMethodDecl* trace = left_most_info->GetTraceMethod()) {
          if (trace->isVirtual())
            return;
        }
        ReportBaseClassMustDeclareVirtualTrace(info, left_most);
        return;
      }

      // Check condition (2):
      if (DeclaresVirtualMethods(left_most))
        return;
      if (left_most_base) {
        // Get the base next to the "safe polymorphic base"
        if (it != left_most->bases_end())
          ++it;
        if (it != left_most->bases_end()) {
          if (CXXRecordDecl* next_base = it->getType()->getAsCXXRecordDecl()) {
            if (CXXRecordDecl* next_left_most = GetLeftMostBase(next_base)) {
              if (DeclaresVirtualMethods(next_left_most))
                return;
              ReportLeftMostBaseMustBePolymorphic(info, next_left_most);
              return;
            }
          }
        }
      }
      ReportLeftMostBaseMustBePolymorphic(info, left_most);
    }
  }

  CXXRecordDecl* GetLeftMostBase(CXXRecordDecl* left_most) {
    CXXRecordDecl::base_class_iterator it = left_most->bases_begin();
    while (it != left_most->bases_end()) {
      if (it->getType()->isDependentType())
        left_most = RecordInfo::GetDependentTemplatedDecl(*it->getType());
      else
        left_most = it->getType()->getAsCXXRecordDecl();
      if (!left_most || !left_most->hasDefinition())
        return 0;
      it = left_most->bases_begin();
    }
    return left_most;
  }

  bool DeclaresVirtualMethods(CXXRecordDecl* decl) {
    CXXRecordDecl::method_iterator it = decl->method_begin();
    for (; it != decl->method_end(); ++it)
      if (it->isVirtual() && !it->isPure())
        return true;
    return false;
  }

  void CheckLeftMostDerived(RecordInfo* info) {
    CXXRecordDecl* left_most = GetLeftMostBase(info->record());
    if (!left_most)
      return;
    if (!Config::IsGCBase(left_most->getName()))
      ReportClassMustLeftMostlyDeriveGC(info);
  }

  void CheckDispatch(RecordInfo* info) {
    bool finalized = info->IsGCFinalized();
    CXXMethodDecl* trace_dispatch = info->GetTraceDispatchMethod();
    CXXMethodDecl* finalize_dispatch = info->GetFinalizeDispatchMethod();
    if (!trace_dispatch && !finalize_dispatch)
      return;

    CXXRecordDecl* base = trace_dispatch ? trace_dispatch->getParent()
                                         : finalize_dispatch->getParent();

    // Check that dispatch methods are defined at the base.
    if (base == info->record()) {
      if (!trace_dispatch)
        ReportMissingTraceDispatchMethod(info);
      if (finalized && !finalize_dispatch)
        ReportMissingFinalizeDispatchMethod(info);
      if (!finalized && finalize_dispatch) {
        ReportClassRequiresFinalization(info);
        NoteUserDeclaredFinalizer(finalize_dispatch);
      }
    }

    // Check that classes implementing manual dispatch do not have vtables.
    if (info->record()->isPolymorphic())
      ReportVirtualAndManualDispatch(
          info, trace_dispatch ? trace_dispatch : finalize_dispatch);

    // If this is a non-abstract class check that it is dispatched to.
    // TODO: Create a global variant of this local check. We can only check if
    // the dispatch body is known in this compilation unit.
    if (info->IsConsideredAbstract())
      return;

    const FunctionDecl* defn;

    if (trace_dispatch && trace_dispatch->isDefined(defn)) {
      CheckDispatchVisitor visitor(info);
      visitor.TraverseStmt(defn->getBody());
      if (!visitor.dispatched_to_receiver())
        ReportMissingTraceDispatch(defn, info);
    }

    if (finalized && finalize_dispatch && finalize_dispatch->isDefined(defn)) {
      CheckDispatchVisitor visitor(info);
      visitor.TraverseStmt(defn->getBody());
      if (!visitor.dispatched_to_receiver())
        ReportMissingFinalizeDispatch(defn, info);
    }
  }

  // TODO: Should we collect destructors similar to trace methods?
  void CheckFinalization(RecordInfo* info) {
    CXXDestructorDecl* dtor = info->record()->getDestructor();

    // For finalized classes, check the finalization method if possible.
    if (info->IsGCFinalized()) {
      if (dtor && dtor->hasBody()) {
        CheckFinalizerVisitor visitor(&cache_, info->IsEagerlyFinalized());
        visitor.TraverseCXXMethodDecl(dtor);
        if (!visitor.finalized_fields().empty()) {
          ReportFinalizerAccessesFinalizedFields(
              dtor, &visitor.finalized_fields());
        }
      }
      return;
    }

    // Don't require finalization of a mixin that has not yet been "mixed in".
    if (info->IsGCMixin())
      return;

    // Report the finalization error, and proceed to print possible causes for
    // the finalization requirement.
    ReportClassRequiresFinalization(info);

    if (dtor && dtor->isUserProvided())
      NoteUserDeclaredDestructor(dtor);

    for (RecordInfo::Bases::iterator it = info->GetBases().begin();
         it != info->GetBases().end();
         ++it) {
      if (it->second.info()->NeedsFinalization())
        NoteBaseRequiresFinalization(&it->second);
    }

    for (RecordInfo::Fields::iterator it = info->GetFields().begin();
         it != info->GetFields().end();
         ++it) {
      if (it->second.edge()->NeedsFinalization())
        NoteField(&it->second, diag_field_requires_finalization_note_);
    }
  }

  void CheckUnneededFinalization(RecordInfo* info) {
    if (!HasNonEmptyFinalizer(info))
      ReportClassDoesNotRequireFinalization(info);
  }

  bool HasNonEmptyFinalizer(RecordInfo* info) {
    CXXDestructorDecl* dtor = info->record()->getDestructor();
    if (dtor && dtor->isUserProvided()) {
      if (!dtor->hasBody() || !EmptyStmtVisitor::isEmpty(dtor->getBody()))
        return true;
    }
    for (RecordInfo::Bases::iterator it = info->GetBases().begin();
         it != info->GetBases().end();
         ++it) {
      if (HasNonEmptyFinalizer(it->second.info()))
        return true;
    }
    for (RecordInfo::Fields::iterator it = info->GetFields().begin();
         it != info->GetFields().end();
         ++it) {
      if (it->second.edge()->NeedsFinalization())
        return true;
    }
    return false;
  }

  // This is the main entry for tracing method definitions.
  void CheckTracingMethod(CXXMethodDecl* method) {
    RecordInfo* parent = cache_.Lookup(method->getParent());
    if (IsIgnored(parent))
      return;

    // Check templated tracing methods by checking the template instantiations.
    // Specialized templates are handled as ordinary classes.
    if (ClassTemplateDecl* tmpl =
            parent->record()->getDescribedClassTemplate()) {
      for (ClassTemplateDecl::spec_iterator it = tmpl->spec_begin();
           it != tmpl->spec_end();
           ++it) {
        // Check trace using each template instantiation as the holder.
        if (IsTemplateInstantiation(*it))
          CheckTraceOrDispatchMethod(cache_.Lookup(*it), method);
      }
      return;
    }

    CheckTraceOrDispatchMethod(parent, method);
  }

  // Determine what type of tracing method this is (dispatch or trace).
  void CheckTraceOrDispatchMethod(RecordInfo* parent, CXXMethodDecl* method) {
    Config::TraceMethodType trace_type = Config::GetTraceMethodType(method);
    if (trace_type == Config::TRACE_AFTER_DISPATCH_METHOD ||
        trace_type == Config::TRACE_AFTER_DISPATCH_IMPL_METHOD ||
        !parent->GetTraceDispatchMethod()) {
      CheckTraceMethod(parent, method, trace_type);
    }
    // Dispatch methods are checked when we identify subclasses.
  }

  // Check an actual trace method.
  void CheckTraceMethod(RecordInfo* parent,
                        CXXMethodDecl* trace,
                        Config::TraceMethodType trace_type) {
    // A trace method must not override any non-virtual trace methods.
    if (trace_type == Config::TRACE_METHOD) {
      for (RecordInfo::Bases::iterator it = parent->GetBases().begin();
           it != parent->GetBases().end();
           ++it) {
        RecordInfo* base = it->second.info();
        if (CXXMethodDecl* other = base->InheritsNonVirtualTrace())
          ReportOverriddenNonVirtualTrace(parent, trace, other);
      }
    }

    CheckTraceVisitor visitor(trace, parent, &cache_);
    visitor.TraverseCXXMethodDecl(trace);

    // Skip reporting if this trace method is a just delegate to
    // traceImpl (or traceAfterDispatchImpl) method. We will report on
    // CheckTraceMethod on traceImpl method.
    if (visitor.delegates_to_traceimpl())
      return;

    for (RecordInfo::Bases::iterator it = parent->GetBases().begin();
         it != parent->GetBases().end();
         ++it) {
      if (!it->second.IsProperlyTraced())
        ReportBaseRequiresTracing(parent, trace, it->first);
    }

    for (RecordInfo::Fields::iterator it = parent->GetFields().begin();
         it != parent->GetFields().end();
         ++it) {
      if (!it->second.IsProperlyTraced()) {
        // Discontinue once an untraced-field error is found.
        ReportFieldsRequireTracing(parent, trace);
        break;
      }
    }
  }

  void DumpClass(RecordInfo* info) {
    if (!json_)
      return;

    json_->OpenObject();
    json_->Write("name", info->record()->getQualifiedNameAsString());
    json_->Write("loc", GetLocString(info->record()->getLocStart()));
    json_->CloseObject();

    class DumpEdgeVisitor : public RecursiveEdgeVisitor {
     public:
      DumpEdgeVisitor(JsonWriter* json) : json_(json) {}
      void DumpEdge(RecordInfo* src,
                    RecordInfo* dst,
                    const string& lbl,
                    const Edge::LivenessKind& kind,
                    const string& loc) {
        json_->OpenObject();
        json_->Write("src", src->record()->getQualifiedNameAsString());
        json_->Write("dst", dst->record()->getQualifiedNameAsString());
        json_->Write("lbl", lbl);
        json_->Write("kind", kind);
        json_->Write("loc", loc);
        json_->Write("ptr",
                     !Parent() ? "val" :
                     Parent()->IsRawPtr() ? "raw" :
                     Parent()->IsRefPtr() ? "ref" :
                     Parent()->IsOwnPtr() ? "own" :
                     (Parent()->IsMember() ||
                      Parent()->IsWeakMember()) ? "mem" :
                     "val");
        json_->CloseObject();
      }

      void DumpField(RecordInfo* src, FieldPoint* point, const string& loc) {
        src_ = src;
        point_ = point;
        loc_ = loc;
        point_->edge()->Accept(this);
      }

      void AtValue(Value* e) override {
        // The liveness kind of a path from the point to this value
        // is given by the innermost place that is non-strong.
        Edge::LivenessKind kind = Edge::kStrong;
        if (Config::IsIgnoreCycleAnnotated(point_->field())) {
          kind = Edge::kWeak;
        } else {
          for (Context::iterator it = context().begin();
               it != context().end();
               ++it) {
            Edge::LivenessKind pointer_kind = (*it)->Kind();
            if (pointer_kind != Edge::kStrong) {
              kind = pointer_kind;
              break;
            }
          }
        }
        DumpEdge(
            src_, e->value(), point_->field()->getNameAsString(), kind, loc_);
      }

     private:
      JsonWriter* json_;
      RecordInfo* src_;
      FieldPoint* point_;
      string loc_;
    };

    DumpEdgeVisitor visitor(json_);

    RecordInfo::Bases& bases = info->GetBases();
    for (RecordInfo::Bases::iterator it = bases.begin();
         it != bases.end();
         ++it) {
      visitor.DumpEdge(info,
                       it->second.info(),
                       "<super>",
                       Edge::kStrong,
                       GetLocString(it->second.spec().getLocStart()));
    }

    RecordInfo::Fields& fields = info->GetFields();
    for (RecordInfo::Fields::iterator it = fields.begin();
         it != fields.end();
         ++it) {
      visitor.DumpField(info,
                        &it->second,
                        GetLocString(it->second.field()->getLocStart()));
    }
  }

  // Adds either a warning or error, based on the current handling of -Werror.
  DiagnosticsEngine::Level getErrorLevel() {
    return diagnostic_.getWarningsAsErrors() ? DiagnosticsEngine::Error
                                             : DiagnosticsEngine::Warning;
  }

  const string GetLocString(SourceLocation loc) {
    const SourceManager& source_manager = instance_.getSourceManager();
    PresumedLoc ploc = source_manager.getPresumedLoc(loc);
    if (ploc.isInvalid())
      return "";
    string loc_str;
    llvm::raw_string_ostream OS(loc_str);
    OS << ploc.getFilename()
       << ":" << ploc.getLine()
       << ":" << ploc.getColumn();
    return OS.str();
  }

  bool IsIgnored(RecordInfo* record) {
    return !record ||
           !InCheckedNamespace(record) ||
           IsIgnoredClass(record) ||
           InIgnoredDirectory(record);
  }

  bool IsIgnoredClass(RecordInfo* info) {
    // Ignore any class prefixed by SameSizeAs. These are used in
    // Blink to verify class sizes and don't need checking.
    const string SameSizeAs = "SameSizeAs";
    if (info->name().compare(0, SameSizeAs.size(), SameSizeAs) == 0)
      return true;
    return options_.ignored_classes.find(info->name()) !=
           options_.ignored_classes.end();
  }

  bool InIgnoredDirectory(RecordInfo* info) {
    string filename;
    if (!GetFilename(info->record()->getLocStart(), &filename))
      return false;  // TODO: should we ignore non-existing file locations?
#if defined(LLVM_ON_WIN32)
    std::replace(filename.begin(), filename.end(), '\\', '/');
#endif
    std::vector<string>::iterator it = options_.ignored_directories.begin();
    for (; it != options_.ignored_directories.end(); ++it)
      if (filename.find(*it) != string::npos)
        return true;
    return false;
  }

  bool InCheckedNamespace(RecordInfo* info) {
    if (!info)
      return false;
    for (DeclContext* context = info->record()->getDeclContext();
         !context->isTranslationUnit();
         context = context->getParent()) {
      if (NamespaceDecl* decl = dyn_cast<NamespaceDecl>(context)) {
        if (decl->isAnonymousNamespace())
          return true;
        if (options_.checked_namespaces.find(decl->getNameAsString()) !=
            options_.checked_namespaces.end()) {
          return true;
        }
      }
    }
    return false;
  }

  bool GetFilename(SourceLocation loc, string* filename) {
    const SourceManager& source_manager = instance_.getSourceManager();
    SourceLocation spelling_location = source_manager.getSpellingLoc(loc);
    PresumedLoc ploc = source_manager.getPresumedLoc(spelling_location);
    if (ploc.isInvalid()) {
      // If we're in an invalid location, we're looking at things that aren't
      // actually stated in the source.
      return false;
    }
    *filename = ploc.getFilename();
    return true;
  }

  void ReportClassMustLeftMostlyDeriveGC(RecordInfo* info) {
    SourceLocation loc = info->record()->getInnerLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_class_must_left_mostly_derive_gc_)
        << info->record();
  }

  void ReportClassRequiresTraceMethod(RecordInfo* info) {
    SourceLocation loc = info->record()->getInnerLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_class_requires_trace_method_)
        << info->record();

    for (RecordInfo::Bases::iterator it = info->GetBases().begin();
         it != info->GetBases().end();
         ++it) {
      if (it->second.NeedsTracing().IsNeeded())
        NoteBaseRequiresTracing(&it->second);
    }

    for (RecordInfo::Fields::iterator it = info->GetFields().begin();
         it != info->GetFields().end();
         ++it) {
      if (!it->second.IsProperlyTraced())
        NoteFieldRequiresTracing(info, it->first);
    }
  }

  void ReportBaseRequiresTracing(RecordInfo* derived,
                                 CXXMethodDecl* trace,
                                 CXXRecordDecl* base) {
    SourceLocation loc = trace->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_base_requires_tracing_)
        << base << derived->record();
  }

  void ReportFieldsRequireTracing(RecordInfo* info, CXXMethodDecl* trace) {
    SourceLocation loc = trace->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_fields_require_tracing_)
        << info->record();
    for (RecordInfo::Fields::iterator it = info->GetFields().begin();
         it != info->GetFields().end();
         ++it) {
      if (!it->second.IsProperlyTraced())
        NoteFieldRequiresTracing(info, it->first);
    }
  }

  void ReportClassContainsInvalidFields(RecordInfo* info,
                                        CheckFieldsVisitor::Errors* errors) {
    SourceLocation loc = info->record()->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    bool only_warnings = options_.warn_raw_ptr;
    for (CheckFieldsVisitor::Errors::iterator it = errors->begin();
         only_warnings && it != errors->end();
         ++it) {
      if (it->second != CheckFieldsVisitor::kRawPtrToGCManagedWarning)
        only_warnings = false;
    }
    diagnostic_.Report(full_loc, only_warnings ?
                       diag_class_contains_invalid_fields_warning_ :
                       diag_class_contains_invalid_fields_)
        << info->record();
    for (CheckFieldsVisitor::Errors::iterator it = errors->begin();
         it != errors->end();
         ++it) {
      unsigned error;
      if (it->second == CheckFieldsVisitor::kRawPtrToGCManaged ||
          it->second == CheckFieldsVisitor::kRawPtrToGCManagedWarning) {
        error = diag_raw_ptr_to_gc_managed_class_note_;
      } else if (it->second == CheckFieldsVisitor::kRefPtrToGCManaged) {
        error = diag_ref_ptr_to_gc_managed_class_note_;
      } else if (it->second == CheckFieldsVisitor::kOwnPtrToGCManaged) {
        error = diag_own_ptr_to_gc_managed_class_note_;
      } else if (it->second == CheckFieldsVisitor::kMemberToGCUnmanaged) {
        error = diag_member_to_gc_unmanaged_class_note_;
      } else if (it->second == CheckFieldsVisitor::kMemberInUnmanaged) {
        error = diag_member_in_unmanaged_class_note_;
      } else if (it->second == CheckFieldsVisitor::kPtrFromHeapToStack) {
        error = diag_stack_allocated_field_note_;
      } else if (it->second == CheckFieldsVisitor::kGCDerivedPartObject) {
        error = diag_part_object_to_gc_derived_class_note_;
      } else {
        assert(false && "Unknown field error");
      }
      NoteField(it->first, error);
    }
  }

  void ReportClassContainsGCRoots(RecordInfo* info,
                                  CheckGCRootsVisitor::Errors* errors) {
    SourceLocation loc = info->record()->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    for (CheckGCRootsVisitor::Errors::iterator it = errors->begin();
         it != errors->end();
         ++it) {
      CheckGCRootsVisitor::RootPath::iterator path = it->begin();
      FieldPoint* point = *path;
      diagnostic_.Report(full_loc, diag_class_contains_gc_root_)
          << info->record() << point->field();
      while (++path != it->end()) {
        NotePartObjectContainsGCRoot(point);
        point = *path;
      }
      NoteFieldContainsGCRoot(point);
    }
  }

  void ReportFinalizerAccessesFinalizedFields(
      CXXMethodDecl* dtor,
      CheckFinalizerVisitor::Errors* fields) {
    for (CheckFinalizerVisitor::Errors::iterator it = fields->begin();
         it != fields->end();
         ++it) {
      SourceLocation loc = it->member_->getLocStart();
      SourceManager& manager = instance_.getSourceManager();
      bool as_eagerly_finalized = it->as_eagerly_finalized_;
      unsigned diag_error = as_eagerly_finalized ?
          diag_finalizer_eagerly_finalized_field_ :
          diag_finalizer_accesses_finalized_field_;
      unsigned diag_note = as_eagerly_finalized ?
          diag_eagerly_finalized_field_note_ :
          diag_finalized_field_note_;
      FullSourceLoc full_loc(loc, manager);
      diagnostic_.Report(full_loc, diag_error)
          << dtor << it->field_->field();
      NoteField(it->field_, diag_note);
    }
  }

  void ReportClassRequiresFinalization(RecordInfo* info) {
    SourceLocation loc = info->record()->getInnerLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_class_requires_finalization_)
        << info->record();
  }

  void ReportClassDoesNotRequireFinalization(RecordInfo* info) {
    SourceLocation loc = info->record()->getInnerLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_class_does_not_require_finalization_)
        << info->record();
  }

  void ReportClassMustDeclareGCMixinTraceMethod(RecordInfo* info) {
    SourceLocation loc = info->record()->getInnerLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(
        full_loc, diag_class_must_declare_gc_mixin_trace_method_)
        << info->record();
  }

  void ReportOverriddenNonVirtualTrace(RecordInfo* info,
                                       CXXMethodDecl* trace,
                                       CXXMethodDecl* overridden) {
    SourceLocation loc = trace->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_overridden_non_virtual_trace_)
        << info->record() << overridden->getParent();
    NoteOverriddenNonVirtualTrace(overridden);
  }

  void ReportMissingTraceDispatchMethod(RecordInfo* info) {
    ReportMissingDispatchMethod(info, diag_missing_trace_dispatch_method_);
  }

  void ReportMissingFinalizeDispatchMethod(RecordInfo* info) {
    ReportMissingDispatchMethod(info, diag_missing_finalize_dispatch_method_);
  }

  void ReportMissingDispatchMethod(RecordInfo* info, unsigned error) {
    SourceLocation loc = info->record()->getInnerLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, error) << info->record();
  }

  void ReportVirtualAndManualDispatch(RecordInfo* info,
                                      CXXMethodDecl* dispatch) {
    SourceLocation loc = info->record()->getInnerLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_virtual_and_manual_dispatch_)
        << info->record();
    NoteManualDispatchMethod(dispatch);
  }

  void ReportMissingTraceDispatch(const FunctionDecl* dispatch,
                                  RecordInfo* receiver) {
    ReportMissingDispatch(dispatch, receiver, diag_missing_trace_dispatch_);
  }

  void ReportMissingFinalizeDispatch(const FunctionDecl* dispatch,
                                     RecordInfo* receiver) {
    ReportMissingDispatch(dispatch, receiver, diag_missing_finalize_dispatch_);
  }

  void ReportMissingDispatch(const FunctionDecl* dispatch,
                             RecordInfo* receiver,
                             unsigned error) {
    SourceLocation loc = dispatch->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, error) << receiver->record();
  }

  void ReportDerivesNonStackAllocated(RecordInfo* info, BasePoint* base) {
    SourceLocation loc = base->spec().getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_derives_non_stack_allocated_)
        << info->record() << base->info()->record();
  }

  void ReportClassOverridesNew(RecordInfo* info, CXXMethodDecl* newop) {
    SourceLocation loc = newop->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_class_overrides_new_) << info->record();
  }

  void ReportClassDeclaresPureVirtualTrace(RecordInfo* info,
                                           CXXMethodDecl* trace) {
    SourceLocation loc = trace->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_class_declares_pure_virtual_trace_)
        << info->record();
  }

  void ReportLeftMostBaseMustBePolymorphic(RecordInfo* derived,
                                           CXXRecordDecl* base) {
    SourceLocation loc = base->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_left_most_base_must_be_polymorphic_)
        << base << derived->record();
  }

  void ReportBaseClassMustDeclareVirtualTrace(RecordInfo* derived,
                                              CXXRecordDecl* base) {
    SourceLocation loc = base->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_base_class_must_declare_virtual_trace_)
        << base << derived->record();
  }

  void NoteManualDispatchMethod(CXXMethodDecl* dispatch) {
    SourceLocation loc = dispatch->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_manual_dispatch_method_note_) << dispatch;
  }

  void NoteBaseRequiresTracing(BasePoint* base) {
    SourceLocation loc = base->spec().getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_base_requires_tracing_note_)
        << base->info()->record();
  }

  void NoteFieldRequiresTracing(RecordInfo* holder, FieldDecl* field) {
    NoteField(field, diag_field_requires_tracing_note_);
  }

  void NotePartObjectContainsGCRoot(FieldPoint* point) {
    FieldDecl* field = point->field();
    SourceLocation loc = field->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_part_object_contains_gc_root_note_)
        << field << field->getParent();
  }

  void NoteFieldContainsGCRoot(FieldPoint* point) {
    NoteField(point, diag_field_contains_gc_root_note_);
  }

  void NoteUserDeclaredDestructor(CXXMethodDecl* dtor) {
    SourceLocation loc = dtor->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_user_declared_destructor_note_);
  }

  void NoteUserDeclaredFinalizer(CXXMethodDecl* dtor) {
    SourceLocation loc = dtor->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_user_declared_finalizer_note_);
  }

  void NoteBaseRequiresFinalization(BasePoint* base) {
    SourceLocation loc = base->spec().getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_base_requires_finalization_note_)
        << base->info()->record();
  }

  void NoteField(FieldPoint* point, unsigned note) {
    NoteField(point->field(), note);
  }

  void NoteField(FieldDecl* field, unsigned note) {
    SourceLocation loc = field->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, note) << field;
  }

  void NoteOverriddenNonVirtualTrace(CXXMethodDecl* overridden) {
    SourceLocation loc = overridden->getLocStart();
    SourceManager& manager = instance_.getSourceManager();
    FullSourceLoc full_loc(loc, manager);
    diagnostic_.Report(full_loc, diag_overridden_non_virtual_trace_note_)
        << overridden;
  }

  unsigned diag_class_must_left_mostly_derive_gc_;
  unsigned diag_class_requires_trace_method_;
  unsigned diag_base_requires_tracing_;
  unsigned diag_fields_require_tracing_;
  unsigned diag_class_contains_invalid_fields_;
  unsigned diag_class_contains_invalid_fields_warning_;
  unsigned diag_class_contains_gc_root_;
  unsigned diag_class_requires_finalization_;
  unsigned diag_class_does_not_require_finalization_;
  unsigned diag_finalizer_accesses_finalized_field_;
  unsigned diag_finalizer_eagerly_finalized_field_;
  unsigned diag_overridden_non_virtual_trace_;
  unsigned diag_missing_trace_dispatch_method_;
  unsigned diag_missing_finalize_dispatch_method_;
  unsigned diag_virtual_and_manual_dispatch_;
  unsigned diag_missing_trace_dispatch_;
  unsigned diag_missing_finalize_dispatch_;
  unsigned diag_derives_non_stack_allocated_;
  unsigned diag_class_overrides_new_;
  unsigned diag_class_declares_pure_virtual_trace_;
  unsigned diag_left_most_base_must_be_polymorphic_;
  unsigned diag_base_class_must_declare_virtual_trace_;
  unsigned diag_class_must_declare_gc_mixin_trace_method_;

  unsigned diag_base_requires_tracing_note_;
  unsigned diag_field_requires_tracing_note_;
  unsigned diag_raw_ptr_to_gc_managed_class_note_;
  unsigned diag_ref_ptr_to_gc_managed_class_note_;
  unsigned diag_own_ptr_to_gc_managed_class_note_;
  unsigned diag_member_to_gc_unmanaged_class_note_;
  unsigned diag_stack_allocated_field_note_;
  unsigned diag_member_in_unmanaged_class_note_;
  unsigned diag_part_object_to_gc_derived_class_note_;
  unsigned diag_part_object_contains_gc_root_note_;
  unsigned diag_field_contains_gc_root_note_;
  unsigned diag_finalized_field_note_;
  unsigned diag_eagerly_finalized_field_note_;
  unsigned diag_user_declared_destructor_note_;
  unsigned diag_user_declared_finalizer_note_;
  unsigned diag_base_requires_finalization_note_;
  unsigned diag_field_requires_finalization_note_;
  unsigned diag_overridden_non_virtual_trace_note_;
  unsigned diag_manual_dispatch_method_note_;

  CompilerInstance& instance_;
  DiagnosticsEngine& diagnostic_;
  BlinkGCPluginOptions options_;
  RecordCache cache_;
  JsonWriter* json_;
};

class BlinkGCPluginAction : public PluginASTAction {
 public:
  BlinkGCPluginAction() {}

 protected:
  // Overridden from PluginASTAction:
  virtual std::unique_ptr<ASTConsumer> CreateASTConsumer(
      CompilerInstance& instance,
      llvm::StringRef ref) {
    return llvm::make_unique<BlinkGCPluginConsumer>(instance, options_);
  }

  virtual bool ParseArgs(const CompilerInstance& instance,
                         const std::vector<string>& args) {
    bool parsed = true;

    for (size_t i = 0; i < args.size() && parsed; ++i) {
      if (args[i] == "enable-oilpan") {
        options_.enable_oilpan = true;
      } else if (args[i] == "dump-graph") {
        options_.dump_graph = true;
      } else if (args[i] == "warn-raw-ptr") {
        options_.warn_raw_ptr = true;
      } else if (args[i] == "warn-unneeded-finalizer") {
        options_.warn_unneeded_finalizer = true;
      } else {
        parsed = false;
        llvm::errs() << "Unknown blink-gc-plugin argument: " << args[i] << "\n";
      }
    }

    return parsed;
  }

 private:
  BlinkGCPluginOptions options_;
};

}  // namespace

static FrontendPluginRegistry::Add<BlinkGCPluginAction> X(
    "blink-gc-plugin",
    "Check Blink GC invariants");
