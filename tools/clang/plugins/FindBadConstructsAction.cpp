// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "FindBadConstructsAction.h"

#include "clang/AST/ASTConsumer.h"
#include "clang/Frontend/FrontendPluginRegistry.h"

#include "FindBadConstructsConsumer.h"

using namespace clang;

namespace chrome_checker {

namespace {

class PluginConsumer : public ASTConsumer {
 public:
  PluginConsumer(CompilerInstance* instance, const Options& options)
      : visitor_(*instance, options) {}

  void HandleTranslationUnit(clang::ASTContext& context) override {
    visitor_.TraverseDecl(context.getTranslationUnitDecl());
  }

 private:
  FindBadConstructsConsumer visitor_;
};

}  // namespace

FindBadConstructsAction::FindBadConstructsAction() {
}

std::unique_ptr<ASTConsumer> FindBadConstructsAction::CreateASTConsumer(
    CompilerInstance& instance,
    llvm::StringRef ref) {
  if (options_.with_ast_visitor)
    return llvm::make_unique<PluginConsumer>(&instance, options_);
  return llvm::make_unique<FindBadConstructsConsumer>(instance, options_);
}

bool FindBadConstructsAction::ParseArgs(const CompilerInstance& instance,
                                        const std::vector<std::string>& args) {
  bool parsed = true;

  for (size_t i = 0; i < args.size() && parsed; ++i) {
    if (args[i] == "check-base-classes") {
      // TODO(rsleevi): Remove this once http://crbug.com/123295 is fixed.
      options_.check_base_classes = true;
    } else if (args[i] == "check-enum-last-value") {
      // TODO(tsepez): Enable this by default once http://crbug.com/356815
      // and http://crbug.com/356816 are fixed.
      options_.check_enum_last_value = true;
    } else if (args[i] == "with-ast-visitor") {
      options_.with_ast_visitor = true;
    } else if (args[i] == "check-templates") {
      options_.check_templates = true;
    } else if (args[i] == "warn-only") {
      options_.warn_only = true;
    } else {
      parsed = false;
      llvm::errs() << "Unknown clang plugin argument: " << args[i] << "\n";
    }
  }

  return parsed;
}

}  // namespace chrome_checker

static FrontendPluginRegistry::Add<chrome_checker::FindBadConstructsAction> X(
    "find-bad-constructs",
    "Finds bad C++ constructs");
