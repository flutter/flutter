// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This implements a Clang tool to convert all instances of std::string("") to
// std::string(). The latter is more efficient (as std::string doesn't have to
// take a copy of an empty string) and generates fewer instructions as well. It
// should be run using the tools/clang/scripts/run_tool.py helper.

#include <memory>
#include "clang/ASTMatchers/ASTMatchers.h"
#include "clang/ASTMatchers/ASTMatchFinder.h"
#include "clang/Basic/SourceManager.h"
#include "clang/Frontend/FrontendActions.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Refactoring.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/Support/CommandLine.h"

using clang::ast_matchers::MatchFinder;
using clang::ast_matchers::argumentCountIs;
using clang::ast_matchers::bindTemporaryExpr;
using clang::ast_matchers::constructorDecl;
using clang::ast_matchers::constructExpr;
using clang::ast_matchers::defaultArgExpr;
using clang::ast_matchers::expr;
using clang::ast_matchers::forEach;
using clang::ast_matchers::has;
using clang::ast_matchers::hasArgument;
using clang::ast_matchers::hasDeclaration;
using clang::ast_matchers::hasName;
using clang::ast_matchers::id;
using clang::ast_matchers::methodDecl;
using clang::ast_matchers::newExpr;
using clang::ast_matchers::ofClass;
using clang::ast_matchers::stringLiteral;
using clang::ast_matchers::varDecl;
using clang::tooling::CommonOptionsParser;
using clang::tooling::Replacement;
using clang::tooling::Replacements;

namespace {

// Handles replacements for stack and heap-allocated instances, e.g.:
// std::string a("");
// std::string* b = new std::string("");
class ConstructorCallback : public MatchFinder::MatchCallback {
 public:
  ConstructorCallback(Replacements* replacements)
      : replacements_(replacements) {}

  virtual void run(const MatchFinder::MatchResult& result) override;

 private:
  Replacements* const replacements_;
};

// Handles replacements for invocations of std::string("") in an initializer
// list.
class InitializerCallback : public MatchFinder::MatchCallback {
 public:
  InitializerCallback(Replacements* replacements)
      : replacements_(replacements) {}

  virtual void run(const MatchFinder::MatchResult& result) override;

 private:
  Replacements* const replacements_;
};

// Handles replacements for invocations of std::string("") in a temporary
// context, e.g. FunctionThatTakesString(std::string("")). Note that this
// handles implicits construction of std::string as well.
class TemporaryCallback : public MatchFinder::MatchCallback {
 public:
  TemporaryCallback(Replacements* replacements) : replacements_(replacements) {}

  virtual void run(const MatchFinder::MatchResult& result) override;

 private:
  Replacements* const replacements_;
};

class EmptyStringConverter {
 public:
  explicit EmptyStringConverter(Replacements* replacements)
      : constructor_callback_(replacements),
        initializer_callback_(replacements),
        temporary_callback_(replacements) {}

  void SetupMatchers(MatchFinder* match_finder);

 private:
  ConstructorCallback constructor_callback_;
  InitializerCallback initializer_callback_;
  TemporaryCallback temporary_callback_;
};

void EmptyStringConverter::SetupMatchers(MatchFinder* match_finder) {
  const clang::ast_matchers::StatementMatcher& constructor_call =
      id("call",
         constructExpr(
             hasDeclaration(methodDecl(ofClass(hasName("std::basic_string")))),
             argumentCountIs(2),
             hasArgument(0, id("literal", stringLiteral())),
             hasArgument(1, defaultArgExpr())));

  // Note that expr(has()) in the matcher is significant; the Clang AST wraps
  // calls to the std::string constructor with exprWithCleanups nodes. Without
  // the expr(has()) matcher, the first and last rules would not match anything!
  match_finder->addMatcher(varDecl(forEach(expr(has(constructor_call)))),
                           &constructor_callback_);
  match_finder->addMatcher(newExpr(has(constructor_call)),
                           &constructor_callback_);
  match_finder->addMatcher(bindTemporaryExpr(has(constructor_call)),
                           &temporary_callback_);
  match_finder->addMatcher(
      constructorDecl(forEach(expr(has(constructor_call)))),
      &initializer_callback_);
}

void ConstructorCallback::run(const MatchFinder::MatchResult& result) {
  const clang::StringLiteral* literal =
      result.Nodes.getNodeAs<clang::StringLiteral>("literal");
  if (literal->getLength() > 0)
    return;

  const clang::CXXConstructExpr* call =
      result.Nodes.getNodeAs<clang::CXXConstructExpr>("call");
  clang::CharSourceRange range =
      clang::CharSourceRange::getTokenRange(call->getParenOrBraceRange());
  replacements_->insert(Replacement(*result.SourceManager, range, ""));
}

void InitializerCallback::run(const MatchFinder::MatchResult& result) {
  const clang::StringLiteral* literal =
      result.Nodes.getNodeAs<clang::StringLiteral>("literal");
  if (literal->getLength() > 0)
    return;

  const clang::CXXConstructExpr* call =
      result.Nodes.getNodeAs<clang::CXXConstructExpr>("call");
  replacements_->insert(Replacement(*result.SourceManager, call, ""));
}

void TemporaryCallback::run(const MatchFinder::MatchResult& result) {
  const clang::StringLiteral* literal =
      result.Nodes.getNodeAs<clang::StringLiteral>("literal");
  if (literal->getLength() > 0)
    return;

  const clang::CXXConstructExpr* call =
      result.Nodes.getNodeAs<clang::CXXConstructExpr>("call");
  // Differentiate between explicit and implicit calls to std::string's
  // constructor. An implicitly generated constructor won't have a valid
  // source range for the parenthesis. We do this because the matched expression
  // for |call| in the explicit case doesn't include the closing parenthesis.
  clang::SourceRange range = call->getParenOrBraceRange();
  if (range.isValid()) {
    replacements_->insert(Replacement(*result.SourceManager, literal, ""));
  } else {
    replacements_->insert(
        Replacement(*result.SourceManager,
                    call,
                    literal->isWide() ? "std::wstring()" : "std::string()"));
  }
}

}  // namespace

static llvm::cl::extrahelp common_help(CommonOptionsParser::HelpMessage);

int main(int argc, const char* argv[]) {
  llvm::cl::OptionCategory category("EmptyString Tool");
  CommonOptionsParser options(argc, argv, category);
  clang::tooling::ClangTool tool(options.getCompilations(),
                                 options.getSourcePathList());

  Replacements replacements;
  EmptyStringConverter converter(&replacements);
  MatchFinder match_finder;
  converter.SetupMatchers(&match_finder);

  std::unique_ptr<clang::tooling::FrontendActionFactory> frontend_factory =
      clang::tooling::newFrontendActionFactory(&match_finder);
  int result = tool.run(frontend_factory.get());
  if (result != 0)
    return result;

  // Each replacement line should have the following format:
  // r:<file path>:<offset>:<length>:<replacement text>
  // Only the <replacement text> field can contain embedded ":" characters.
  // TODO(dcheng): Use a more clever serialization. Ideally we'd use the YAML
  // serialization and then use clang-apply-replacements, but that would require
  // copying and pasting a larger amount of boilerplate for all Chrome clang
  // tools.
  llvm::outs() << "==== BEGIN EDITS ====\n";
  for (const auto& r : replacements) {
    llvm::outs() << "r:::" << r.getFilePath() << ":::" << r.getOffset() << ":::"
                 << r.getLength() << ":::" << r.getReplacementText() << "\n";
  }
  llvm::outs() << "==== END EDITS ====\n";

  return 0;
}
