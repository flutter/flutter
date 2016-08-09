// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This implements a Clang tool to generate compilation information that is
// sufficient to recompile the code with clang. For each compilation unit, all
// source files which are necessary for compiling it are determined. For each
// compilation unit, a file is created containing a list of all file paths of
// included files.

#include <assert.h>
#include <unistd.h>
#include <fstream>
#include <iostream>
#include <memory>
#include <set>
#include <stack>
#include <string>
#include <vector>

#include "clang/Basic/Diagnostic.h"
#include "clang/Basic/FileManager.h"
#include "clang/Basic/SourceManager.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendActions.h"
#include "clang/Lex/PPCallbacks.h"
#include "clang/Lex/Preprocessor.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/CompilationDatabase.h"
#include "clang/Tooling/Refactoring.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/Support/CommandLine.h"

using clang::tooling::CommonOptionsParser;
using std::set;
using std::stack;
using std::string;
using std::vector;

namespace {
// Set of preprocessor callbacks used to record files included.
class IncludeFinderPPCallbacks : public clang::PPCallbacks {
 public:
  IncludeFinderPPCallbacks(clang::SourceManager* source_manager,
                           string* main_source_file,
                           set<string>* source_file_paths)
      : source_manager_(source_manager),
        main_source_file_(main_source_file),
        source_file_paths_(source_file_paths) {}
  void FileChanged(clang::SourceLocation /*loc*/,
                   clang::PPCallbacks::FileChangeReason reason,
                   clang::SrcMgr::CharacteristicKind /*file_type*/,
                   clang::FileID /*prev_fid*/) override;
  void AddFile(const string& path);
  void InclusionDirective(clang::SourceLocation hash_loc,
                          const clang::Token& include_tok,
                          llvm::StringRef file_name,
                          bool is_angled,
                          clang::CharSourceRange range,
                          const clang::FileEntry* file,
                          llvm::StringRef search_path,
                          llvm::StringRef relative_path,
                          const clang::Module* imported) override;
  void EndOfMainFile() override;

 private:
  clang::SourceManager* const source_manager_;
  string* const main_source_file_;
  set<string>* const source_file_paths_;
  // The path of the file that was last referenced by an inclusion directive,
  // normalized for includes that are relative to a different source file.
  string last_inclusion_directive_;
  // The stack of currently parsed files. top() gives the current file.
  stack<string> current_files_;
};

void IncludeFinderPPCallbacks::FileChanged(
    clang::SourceLocation /*loc*/,
    clang::PPCallbacks::FileChangeReason reason,
    clang::SrcMgr::CharacteristicKind /*file_type*/,
    clang::FileID /*prev_fid*/) {
  if (reason == clang::PPCallbacks::EnterFile) {
    if (!last_inclusion_directive_.empty()) {
      current_files_.push(last_inclusion_directive_);
    } else {
      current_files_.push(
          source_manager_->getFileEntryForID(source_manager_->getMainFileID())
              ->getName());
    }
  } else if (reason == ExitFile) {
    current_files_.pop();
  }
  // Other reasons are not interesting for us.
}

void IncludeFinderPPCallbacks::AddFile(const string& path) {
  source_file_paths_->insert(path);
}

void IncludeFinderPPCallbacks::InclusionDirective(
    clang::SourceLocation hash_loc,
    const clang::Token& include_tok,
    llvm::StringRef file_name,
    bool is_angled,
    clang::CharSourceRange range,
    const clang::FileEntry* file,
    llvm::StringRef search_path,
    llvm::StringRef relative_path,
    const clang::Module* imported) {
  if (!file)
    return;

  assert(!current_files_.top().empty());
  const clang::DirectoryEntry* const search_path_entry =
      source_manager_->getFileManager().getDirectory(search_path);
  const clang::DirectoryEntry* const current_file_parent_entry =
      source_manager_->getFileManager()
          .getFile(current_files_.top().c_str())
          ->getDir();

  // If the include file was found relatively to the current file's parent
  // directory or a search path, we need to normalize it. This is necessary
  // because llvm internalizes the path by which an inode was first accessed,
  // and always returns that path afterwards. If we do not normalize this
  // we will get an error when we replay the compilation, as the virtual
  // file system is not aware of inodes.
  if (search_path_entry == current_file_parent_entry) {
    string parent =
        llvm::sys::path::parent_path(current_files_.top().c_str()).str();

    // If the file is a top level file ("file.cc"), we normalize to a path
    // relative to "./".
    if (parent.empty() || parent == "/")
      parent = ".";

    // Otherwise we take the literal path as we stored it for the current
    // file, and append the relative path.
    last_inclusion_directive_ = parent + "/" + relative_path.str();
  } else if (!search_path.empty()) {
    // We want to be able to extract the search path relative to which the
    // include statement is defined. Therefore if search_path is an absolute
    // path (indicating it is most likely a system header) we use "//" as a
    // separator between the search path and the relative path.
    last_inclusion_directive_ = search_path.str() +
        (llvm::sys::path::is_absolute(search_path) ? "//" : "/") +
        relative_path.str();
  } else {
    last_inclusion_directive_ = file_name.str();
  }
  AddFile(last_inclusion_directive_);
}

void IncludeFinderPPCallbacks::EndOfMainFile() {
  const clang::FileEntry* main_file =
      source_manager_->getFileEntryForID(source_manager_->getMainFileID());
  assert(*main_source_file_ == main_file->getName());
  AddFile(main_file->getName());
}

class CompilationIndexerAction : public clang::PreprocessorFrontendAction {
 public:
  CompilationIndexerAction() {}
  void ExecuteAction() override;

  // Runs the preprocessor over the translation unit.
  // This triggers the PPCallbacks we register to intercept all required
  // files for the compilation.
  void Preprocess();
  void EndSourceFileAction() override;

 private:
  // Set up the state extracted during the compilation, and run Clang over the
  // input.
  string main_source_file_;
  // Maps file names to their contents as read by Clang's source manager.
  set<string> source_file_paths_;
};

void CompilationIndexerAction::ExecuteAction() {
  vector<clang::FrontendInputFile> inputs =
      getCompilerInstance().getFrontendOpts().Inputs;
  assert(inputs.size() == 1);
  main_source_file_ = inputs[0].getFile();

  Preprocess();
}

void CompilationIndexerAction::Preprocess() {
  clang::Preprocessor& preprocessor = getCompilerInstance().getPreprocessor();
  preprocessor.addPPCallbacks(llvm::make_unique<IncludeFinderPPCallbacks>(
      &getCompilerInstance().getSourceManager(),
      &main_source_file_,
      &source_file_paths_));
  preprocessor.getDiagnostics().setIgnoreAllWarnings(true);
  preprocessor.SetSuppressIncludeNotFoundError(true);
  preprocessor.EnterMainSourceFile();
  clang::Token token;
  do {
    preprocessor.Lex(token);
  } while (token.isNot(clang::tok::eof));
}

void CompilationIndexerAction::EndSourceFileAction() {
  std::ofstream out(main_source_file_ + ".filepaths");
  for (string path : source_file_paths_) {
    out << path << std::endl;
  }
}
}  // namespace

static llvm::cl::extrahelp common_help(CommonOptionsParser::HelpMessage);

int main(int argc, const char* argv[]) {
  llvm::cl::OptionCategory category("TranslationUnitGenerator Tool");
  CommonOptionsParser options(argc, argv, category);
  std::unique_ptr<clang::tooling::FrontendActionFactory> frontend_factory =
      clang::tooling::newFrontendActionFactory<CompilationIndexerAction>();
  clang::tooling::ClangTool tool(options.getCompilations(),
                                 options.getSourcePathList());
  // This clang tool does not actually produce edits, but run_tool.py expects
  // this. So we just print an empty edit block.
  llvm::outs() << "==== BEGIN EDITS ====\n";
  llvm::outs() << "==== END EDITS ====\n";
  return tool.run(frontend_factory.get());
}
