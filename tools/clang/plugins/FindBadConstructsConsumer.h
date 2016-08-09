// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file defines a bunch of recurring problems in the Chromium C++ code.
//
// Checks that are implemented:
// - Constructors/Destructors should not be inlined if they are of a complex
//   class type.
// - Missing "virtual" keywords on methods that should be virtual.
// - Non-annotated overriding virtual methods.
// - Virtual methods with nonempty implementations in their headers.
// - Classes that derive from base::RefCounted / base::RefCountedThreadSafe
//   should have protected or private destructors.
// - WeakPtrFactory members that refer to their outer class should be the last
//   member.
// - Enum types with a xxxx_LAST or xxxxLast const actually have that constant
//   have the maximal value for that type.

#ifndef TOOLS_CLANG_PLUGINS_FINDBADCONSTRUCTSCONSUMER_H_
#define TOOLS_CLANG_PLUGINS_FINDBADCONSTRUCTSCONSUMER_H_

#include "clang/AST/AST.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/Attr.h"
#include "clang/AST/CXXInheritance.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/AST/TypeLoc.h"
#include "clang/Basic/SourceManager.h"
#include "clang/Basic/SourceLocation.h"

#include "ChromeClassTester.h"
#include "Options.h"
#include "SuppressibleDiagnosticBuilder.h"

namespace chrome_checker {

// Searches for constructs that we know we don't want in the Chromium code base.
class FindBadConstructsConsumer
    : public clang::RecursiveASTVisitor<FindBadConstructsConsumer>,
      public ChromeClassTester {
 public:
  FindBadConstructsConsumer(clang::CompilerInstance& instance,
                            const Options& options);

  // RecursiveASTVisitor:
  bool VisitDecl(clang::Decl* decl);

  // ChromeClassTester overrides:
  void CheckChromeClass(clang::SourceLocation record_location,
                        clang::CXXRecordDecl* record) override;
  void CheckChromeEnum(clang::SourceLocation enum_location,
                       clang::EnumDecl* enum_decl) override;

 private:
  // The type of problematic ref-counting pattern that was encountered.
  enum RefcountIssue { None, ImplicitDestructor, PublicDestructor };

  void CheckCtorDtorWeight(clang::SourceLocation record_location,
                           clang::CXXRecordDecl* record);

  bool InTestingNamespace(const clang::Decl* record);
  bool IsMethodInBannedOrTestingNamespace(const clang::CXXMethodDecl* method);

  // Returns a diagnostic builder that only emits the diagnostic if the spelling
  // location (the actual characters that make up the token) is not in an
  // ignored file. This is useful for situations where the token might originate
  // from a macro in a system header: warning isn't useful, since system headers
  // generally can't be easily updated.
  SuppressibleDiagnosticBuilder ReportIfSpellingLocNotIgnored(
      clang::SourceLocation loc,
      unsigned diagnostic_id);

  void CheckVirtualMethods(clang::SourceLocation record_location,
                           clang::CXXRecordDecl* record,
                           bool warn_on_inline_bodies);
  void CheckVirtualSpecifiers(const clang::CXXMethodDecl* method);
  void CheckVirtualBodies(const clang::CXXMethodDecl* method);

  void CountType(const clang::Type* type,
                 int* trivial_member,
                 int* non_trivial_member,
                 int* templated_non_trivial_member);

  static RefcountIssue CheckRecordForRefcountIssue(
      const clang::CXXRecordDecl* record,
      clang::SourceLocation& loc);
  static bool IsRefCountedCallback(const clang::CXXBaseSpecifier* base,
                                   clang::CXXBasePath& path,
                                   void* user_data);
  static bool HasPublicDtorCallback(const clang::CXXBaseSpecifier* base,
                                    clang::CXXBasePath& path,
                                    void* user_data);
  void PrintInheritanceChain(const clang::CXXBasePath& path);
  unsigned DiagnosticForIssue(RefcountIssue issue);
  void CheckRefCountedDtors(clang::SourceLocation record_location,
                            clang::CXXRecordDecl* record);

  void CheckWeakPtrFactoryMembers(clang::SourceLocation record_location,
                                  clang::CXXRecordDecl* record);

  unsigned diag_method_requires_override_;
  unsigned diag_redundant_virtual_specifier_;
  unsigned diag_base_method_virtual_and_final_;
  unsigned diag_no_explicit_dtor_;
  unsigned diag_public_dtor_;
  unsigned diag_protected_non_virtual_dtor_;
  unsigned diag_weak_ptr_factory_order_;
  unsigned diag_bad_enum_last_value_;
  unsigned diag_note_inheritance_;
  unsigned diag_note_implicit_dtor_;
  unsigned diag_note_public_dtor_;
  unsigned diag_note_protected_non_virtual_dtor_;
};

}  // namespace chrome_checker

#endif  // TOOLS_CLANG_PLUGINS_FINDBADCONSTRUCTSCONSUMER_H_
