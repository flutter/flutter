// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_CLANG_PLUGINS_FINDBADCONSTRUCTIONS_ACTION_H_
#define TOOLS_CLANG_PLUGINS_FINDBADCONSTRUCTIONS_ACTION_H_

#include "clang/Frontend/FrontendAction.h"

#include "Options.h"

namespace chrome_checker {

class FindBadConstructsAction : public clang::PluginASTAction {
 public:
  FindBadConstructsAction();

 protected:
  // Overridden from PluginASTAction:
  virtual std::unique_ptr<clang::ASTConsumer> CreateASTConsumer(
      clang::CompilerInstance& instance,
      llvm::StringRef ref);
  virtual bool ParseArgs(const clang::CompilerInstance& instance,
                         const std::vector<std::string>& args);

 private:
  Options options_;
};

}  // namespace chrome_checker

#endif  // TOOLS_CLANG_PLUGINS_FINDBADCONSTRUCTIONS_ACTION_H_
