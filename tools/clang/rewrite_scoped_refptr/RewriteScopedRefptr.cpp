// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This implements a Clang tool to rewrite all instances of
// scoped_refptr<T>'s implicit cast to T (operator T*) to an explicit call to
// the .get() method.

#include <assert.h>
#include <algorithm>
#include <memory>
#include <string>

#include "clang/AST/ASTContext.h"
#include "clang/ASTMatchers/ASTMatchers.h"
#include "clang/ASTMatchers/ASTMatchersMacros.h"
#include "clang/ASTMatchers/ASTMatchFinder.h"
#include "clang/Basic/SourceManager.h"
#include "clang/Frontend/FrontendActions.h"
#include "clang/Lex/Lexer.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Refactoring.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/support/TargetSelect.h"

using namespace clang::ast_matchers;
using clang::tooling::CommonOptionsParser;
using clang::tooling::Replacement;
using clang::tooling::Replacements;
using llvm::StringRef;

namespace clang {
namespace ast_matchers {

const internal::VariadicDynCastAllOfMatcher<Decl, CXXConversionDecl>
    conversionDecl;

AST_MATCHER(QualType, isBoolean) {
  return Node->isBooleanType();
}

}  // namespace ast_matchers
}  // namespace clang

namespace {

// Returns true if expr needs to be put in parens (eg: when it is an operator
// syntactically).
bool NeedsParens(const clang::Expr* expr) {
  if (llvm::dyn_cast<clang::UnaryOperator>(expr) ||
      llvm::dyn_cast<clang::BinaryOperator>(expr) ||
      llvm::dyn_cast<clang::ConditionalOperator>(expr)) {
    return true;
  }
  // Calls to an overloaded operator also need parens, except for foo(...) and
  // foo[...] expressions.
  if (const clang::CXXOperatorCallExpr* op =
          llvm::dyn_cast<clang::CXXOperatorCallExpr>(expr)) {
    return op->getOperator() != clang::OO_Call &&
           op->getOperator() != clang::OO_Subscript;
  }
  return false;
}

Replacement RewriteImplicitToExplicitConversion(
    const MatchFinder::MatchResult& result,
    const clang::Expr* expr) {
  clang::CharSourceRange range = clang::CharSourceRange::getTokenRange(
      result.SourceManager->getSpellingLoc(expr->getLocStart()),
      result.SourceManager->getSpellingLoc(expr->getLocEnd()));
  assert(range.isValid() && "Invalid range!");

  // Handle cases where an implicit cast is being done by dereferencing a
  // pointer to a scoped_refptr<> (sadly, it happens...)
  //
  // This rewrites both "*foo" and "*(foo)" as "foo->get()".
  if (const clang::UnaryOperator* op =
          llvm::dyn_cast<clang::UnaryOperator>(expr)) {
    if (op->getOpcode() == clang::UO_Deref) {
      const clang::Expr* const sub_expr =
          op->getSubExpr()->IgnoreParenImpCasts();
      clang::CharSourceRange sub_expr_range =
          clang::CharSourceRange::getTokenRange(
              result.SourceManager->getSpellingLoc(sub_expr->getLocStart()),
              result.SourceManager->getSpellingLoc(sub_expr->getLocEnd()));
      assert(sub_expr_range.isValid() && "Invalid subexpression range!");

      std::string inner_text = clang::Lexer::getSourceText(
          sub_expr_range, *result.SourceManager, result.Context->getLangOpts());
      assert(!inner_text.empty() && "No text for subexpression!");
      if (NeedsParens(sub_expr)) {
        inner_text.insert(0, "(");
        inner_text.append(")");
      }
      inner_text.append("->get()");
      return Replacement(*result.SourceManager, range, inner_text);
    }
  }

  std::string text = clang::Lexer::getSourceText(
      range, *result.SourceManager, result.Context->getLangOpts());
  assert(!text.empty() && "No text for expression!");

  // Unwrap any temporaries - for example, custom iterators that return
  // scoped_refptr<T> as part of operator*. Any such iterators should also
  // be declaring a scoped_refptr<T>* operator->, per C++03 24.4.1.1 (Table 72)
  if (const clang::CXXBindTemporaryExpr* op =
          llvm::dyn_cast<clang::CXXBindTemporaryExpr>(expr)) {
    expr = op->getSubExpr();
  }

  // Handle iterators (which are operator* calls, followed by implicit
  // conversions) by rewriting *it as it->get()
  if (const clang::CXXOperatorCallExpr* op =
          llvm::dyn_cast<clang::CXXOperatorCallExpr>(expr)) {
    if (op->getOperator() == clang::OO_Star) {
      // Note that this doesn't rewrite **it correctly, since it should be
      // rewritten using parens, e.g. (*it)->get(). However, this shouldn't
      // happen frequently, if at all, since it would likely indicate code is
      // storing pointers to a scoped_refptr in a container.
      text.erase(0, 1);
      text.append("->get()");
      return Replacement(*result.SourceManager, range, text);
    }
  }

  // The only remaining calls should be non-dereferencing calls (eg: member
  // calls), so a simple ".get()" appending should suffice.
  if (NeedsParens(expr)) {
    text.insert(0, "(");
    text.append(")");
  }
  text.append(".get()");
  return Replacement(*result.SourceManager, range, text);
}

Replacement RewriteRawPtrToScopedRefptr(const MatchFinder::MatchResult& result,
                                        clang::SourceLocation begin,
                                        clang::SourceLocation end) {
  clang::CharSourceRange range = clang::CharSourceRange::getTokenRange(
      result.SourceManager->getSpellingLoc(begin),
      result.SourceManager->getSpellingLoc(end));
  assert(range.isValid() && "Invalid range!");

  std::string text = clang::Lexer::getSourceText(
      range, *result.SourceManager, result.Context->getLangOpts());
  text.erase(text.rfind('*'));

  std::string replacement_text("scoped_refptr<");
  replacement_text += text;
  replacement_text += ">";

  return Replacement(*result.SourceManager, range, replacement_text);
}

class GetRewriterCallback : public MatchFinder::MatchCallback {
 public:
  explicit GetRewriterCallback(Replacements* replacements)
      : replacements_(replacements) {}
  virtual void run(const MatchFinder::MatchResult& result) override;

 private:
  Replacements* const replacements_;
};

void GetRewriterCallback::run(const MatchFinder::MatchResult& result) {
  const clang::Expr* arg = result.Nodes.getNodeAs<clang::Expr>("arg");
  assert(arg && "Unexpected match! No Expr captured!");
  replacements_->insert(RewriteImplicitToExplicitConversion(result, arg));
}

class VarRewriterCallback : public MatchFinder::MatchCallback {
 public:
  explicit VarRewriterCallback(Replacements* replacements)
      : replacements_(replacements) {}
  virtual void run(const MatchFinder::MatchResult& result) override;

 private:
  Replacements* const replacements_;
};

void VarRewriterCallback::run(const MatchFinder::MatchResult& result) {
  const clang::DeclaratorDecl* const var_decl =
      result.Nodes.getNodeAs<clang::DeclaratorDecl>("var");
  assert(var_decl && "Unexpected match! No VarDecl captured!");

  const clang::TypeSourceInfo* tsi = var_decl->getTypeSourceInfo();

  // TODO(dcheng): This mishandles a case where a variable has multiple
  // declarations, e.g.:
  //
  // in .h:
  // Foo* my_global_magical_foo;
  //
  // in .cc:
  // Foo* my_global_magical_foo = CreateFoo();
  //
  // In this case, it will only rewrite the .cc definition. Oh well. This should
  // be rare enough that these cases can be manually handled, since the style
  // guide prohibits globals of non-POD type.
  replacements_->insert(RewriteRawPtrToScopedRefptr(
      result, tsi->getTypeLoc().getBeginLoc(), tsi->getTypeLoc().getEndLoc()));
}

class FunctionRewriterCallback : public MatchFinder::MatchCallback {
 public:
  explicit FunctionRewriterCallback(Replacements* replacements)
      : replacements_(replacements) {}
  virtual void run(const MatchFinder::MatchResult& result) override;

 private:
  Replacements* const replacements_;
};

void FunctionRewriterCallback::run(const MatchFinder::MatchResult& result) {
  const clang::FunctionDecl* const function_decl =
      result.Nodes.getNodeAs<clang::FunctionDecl>("fn");
  assert(function_decl && "Unexpected match! No FunctionDecl captured!");

  // If matched against an implicit conversion to a DeclRefExpr, make sure the
  // referenced declaration is of class type, e.g. the tool skips trying to
  // chase pointers/references to determine if the pointee is a scoped_refptr<T>
  // with local storage. Instead, let a human manually handle those cases.
  const clang::VarDecl* const var_decl =
      result.Nodes.getNodeAs<clang::VarDecl>("var");
  if (var_decl && !var_decl->getTypeSourceInfo()->getType()->isClassType()) {
    return;
  }

  for (clang::FunctionDecl* f : function_decl->redecls()) {
    clang::SourceRange range = f->getReturnTypeSourceRange();
    replacements_->insert(
        RewriteRawPtrToScopedRefptr(result, range.getBegin(), range.getEnd()));
  }
}

class MacroRewriterCallback : public MatchFinder::MatchCallback {
 public:
  explicit MacroRewriterCallback(Replacements* replacements)
      : replacements_(replacements) {}
  virtual void run(const MatchFinder::MatchResult& result) override;

 private:
  Replacements* const replacements_;
};

void MacroRewriterCallback::run(const MatchFinder::MatchResult& result) {
  const clang::Expr* const expr = result.Nodes.getNodeAs<clang::Expr>("expr");
  assert(expr && "Unexpected match! No Expr captured!");
  replacements_->insert(RewriteImplicitToExplicitConversion(result, expr));
}

}  // namespace

static llvm::cl::extrahelp common_help(CommonOptionsParser::HelpMessage);

int main(int argc, const char* argv[]) {
  // TODO(dcheng): Clang tooling should do this itself.
  // http://llvm.org/bugs/show_bug.cgi?id=21627
  llvm::InitializeNativeTarget();
  llvm::InitializeNativeTargetAsmParser();
  llvm::cl::OptionCategory category("Remove scoped_refptr conversions");
  CommonOptionsParser options(argc, argv, category);
  clang::tooling::ClangTool tool(options.getCompilations(),
                                 options.getSourcePathList());

  MatchFinder match_finder;
  Replacements replacements;

  auto is_scoped_refptr = recordDecl(isSameOrDerivedFrom("::scoped_refptr"),
                                     isTemplateInstantiation());

  // Finds all calls to conversion operator member function. This catches calls
  // to "operator T*", "operator Testable", and "operator bool" equally.
  auto base_matcher = memberCallExpr(thisPointerType(is_scoped_refptr),
                                     callee(conversionDecl()),
                                     on(id("arg", expr())));

  // The heuristic for whether or not converting a temporary is 'unsafe'. An
  // unsafe conversion is one where a temporary scoped_refptr<T> is converted to
  // another type. The matcher provides an exception for a temporary
  // scoped_refptr that is the result of an operator call. In this case, assume
  // that it's the result of an iterator dereference, and the container itself
  // retains the necessary reference, since this is a common idiom to see in
  // loop bodies.
  auto is_unsafe_temporary_conversion =
      on(bindTemporaryExpr(unless(has(operatorCallExpr()))));

  // Returning a scoped_refptr<T> as a T* is considered unsafe if either are
  // true:
  // - The scoped_refptr<T> is a temporary.
  // - The scoped_refptr<T> has local lifetime.
  auto returned_as_raw_ptr = hasParent(
      returnStmt(hasAncestor(id("fn", functionDecl(returns(pointerType()))))));
  // This matcher intentionally matches more than it should. For example, this
  // will match:
  //   scoped_refptr<Foo>& foo = some_other_foo;
  //   return foo;
  // The matcher callback filters out VarDecls that aren't a scoped_refptr<T>,
  // so those cases can be manually handled.
  auto is_local_variable =
      on(declRefExpr(to(id("var", varDecl(hasLocalStorage())))));
  auto is_unsafe_return =
      anyOf(allOf(hasParent(implicitCastExpr(returned_as_raw_ptr)),
                  is_local_variable),
            allOf(hasParent(implicitCastExpr(
                      hasParent(exprWithCleanups(returned_as_raw_ptr)))),
                  is_unsafe_temporary_conversion));

  // This catches both user-defined conversions (eg: "operator bool") and
  // standard conversion sequence (C++03 13.3.3.1.1), such as converting a
  // pointer to a bool.
  auto implicit_to_bool =
      implicitCastExpr(hasImplicitDestinationType(isBoolean()));

  // Avoid converting calls to of "operator Testable" -> "bool" and calls of
  // "operator T*" -> "bool".
  auto bool_conversion_matcher = hasParent(
      expr(anyOf(implicit_to_bool, expr(hasParent(implicit_to_bool)))));

  auto is_logging_helper =
      functionDecl(anyOf(hasName("CheckEQImpl"), hasName("CheckNEImpl")));
  auto is_gtest_helper = functionDecl(
      anyOf(methodDecl(ofClass(recordDecl(isSameOrDerivedFrom(
                           hasName("::testing::internal::EqHelper")))),
                       hasName("Compare")),
            hasName("::testing::internal::CmpHelperNE")));
  auto is_gtest_assertion_result_ctor = constructorDecl(ofClass(
      recordDecl(isSameOrDerivedFrom(hasName("::testing::AssertionResult")))));

  // Find all calls to an operator overload that are 'safe'.
  //
  // All bool conversions will be handled with the Testable trick, but that
  // can only be used once "operator T*" is removed, since otherwise it leaves
  // the call ambiguous.
  GetRewriterCallback get_callback(&replacements);
  match_finder.addMatcher(
      memberCallExpr(
          base_matcher,
          // Excluded since the conversion may be unsafe.
          unless(anyOf(is_unsafe_temporary_conversion, is_unsafe_return)),
          // Excluded since the conversion occurs inside a helper function that
          // the macro wraps. Letting this callback handle the rewrite would
          // result in an incorrect replacement that changes the helper function
          // itself. Instead, the right replacement is to rewrite the macro's
          // arguments.
          unless(hasAncestor(decl(anyOf(is_logging_helper,
                                        is_gtest_helper,
                                        is_gtest_assertion_result_ctor))))),
      &get_callback);

  // Find temporary scoped_refptr<T>'s being unsafely assigned to a T*.
  VarRewriterCallback var_callback(&replacements);
  auto initialized_with_temporary = ignoringImpCasts(exprWithCleanups(
      has(memberCallExpr(base_matcher, is_unsafe_temporary_conversion))));
  match_finder.addMatcher(id("var",
                             varDecl(hasInitializer(initialized_with_temporary),
                                     hasType(pointerType()))),
                          &var_callback);
  match_finder.addMatcher(
      constructorDecl(forEachConstructorInitializer(
          allOf(withInitializer(initialized_with_temporary),
                forField(id("var", fieldDecl(hasType(pointerType()))))))),
      &var_callback);

  // Rewrite functions that unsafely turn a scoped_refptr<T> into a T* when
  // returning a value.
  FunctionRewriterCallback fn_callback(&replacements);
  match_finder.addMatcher(memberCallExpr(base_matcher, is_unsafe_return),
                          &fn_callback);

  // Rewrite logging / gtest expressions that result in an implicit conversion.
  // Luckily, the matchers don't need to handle the case where one of the macro
  // arguments is NULL, such as:
  // CHECK_EQ(my_scoped_refptr, NULL)
  // because it simply doesn't compile--since NULL is actually of integral type,
  // this doesn't trigger scoped_refptr<T>'s implicit conversion. Since there is
  // no comparison overload for scoped_refptr<T> and int, this fails to compile.
  MacroRewriterCallback macro_callback(&replacements);
  // CHECK_EQ/CHECK_NE helpers.
  match_finder.addMatcher(
      callExpr(callee(is_logging_helper),
               argumentCountIs(3),
               hasAnyArgument(id("expr", expr(hasType(is_scoped_refptr)))),
               hasAnyArgument(hasType(pointerType())),
               hasArgument(2, stringLiteral())),
      &macro_callback);
  // ASSERT_EQ/ASSERT_NE/EXPECT_EQ/EXPECT_EQ, which use the same underlying
  // helper functions. Even though gtest has special handling for pointer to
  // NULL comparisons, it doesn't trigger in this case, so no special handling
  // is needed for the replacements.
  match_finder.addMatcher(
      callExpr(callee(is_gtest_helper),
               argumentCountIs(4),
               hasArgument(0, stringLiteral()),
               hasArgument(1, stringLiteral()),
               hasAnyArgument(id("expr", expr(hasType(is_scoped_refptr)))),
               hasAnyArgument(hasType(pointerType()))),
      &macro_callback);
  // ASSERT_TRUE/EXPECT_TRUE helpers. Note that this matcher doesn't need to
  // handle ASSERT_FALSE/EXPECT_FALSE, because it gets coerced to bool before
  // being passed as an argument to AssertionResult's constructor. As a result,
  // GetRewriterCallback handles this case properly since the conversion isn't
  // hidden inside AssertionResult, and the generated replacement properly
  // rewrites the macro argument.
  // However, the tool does need to handle the _TRUE counterparts, since the
  // conversion occurs inside the constructor in those cases.
  match_finder.addMatcher(
      constructExpr(
          argumentCountIs(2),
          hasArgument(0, id("expr", expr(hasType(is_scoped_refptr)))),
          hasDeclaration(is_gtest_assertion_result_ctor)),
      &macro_callback);

  std::unique_ptr<clang::tooling::FrontendActionFactory> factory =
      clang::tooling::newFrontendActionFactory(&match_finder);
  int result = tool.run(factory.get());
  if (result != 0)
    return result;

  // Serialization format is documented in tools/clang/scripts/run_tool.py
  llvm::outs() << "==== BEGIN EDITS ====\n";
  for (const auto& r : replacements) {
    std::string replacement_text = r.getReplacementText().str();
    std::replace(replacement_text.begin(), replacement_text.end(), '\n', '\0');
    llvm::outs() << "r:::" << r.getFilePath() << ":::" << r.getOffset() << ":::"
                 << r.getLength() << ":::" << replacement_text << "\n";
  }
  llvm::outs() << "==== END EDITS ====\n";

  return 0;
}
