// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/license_checker.h"

#include <filesystem>
#include <vector>
#include "flutter/third_party/abseil-cpp/absl/log/log.h"
#include "flutter/third_party/abseil-cpp/absl/status/statusor.h"
#include "flutter/third_party/re2/re2/re2.h"
#include "flutter/tools/licenses_cpp/src/filter.h"
#include "flutter/tools/licenses_cpp/src/mmap_file.h"

namespace {
std::vector<std::filesystem::path> GetGitRepos(std::string_view dir) {
  std::vector<std::filesystem::path> result;
  result.push_back(dir);
  for (const std::filesystem::directory_entry& entry :
       std::filesystem::recursive_directory_iterator(dir)) {
    if (entry.path().stem() == ".git") {
      result.push_back(entry.path().parent_path());
    }
  }
  return result;
}

absl::StatusOr<std::vector<std::string>> GitLsFiles(
    const std::filesystem::path& repo_path) {
  std::vector<std::string> files;

  std::string cmd = "git -C \"" + repo_path.string() + "\" ls-files";
  std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"),
                                                pclose);

  if (!pipe) {
    return absl::InvalidArgumentError("can't run git ls-files in " +
                                      repo_path.string());
  }

  char buffer[4096];
  while (fgets(buffer, sizeof(buffer), pipe.get()) != nullptr) {
    std::string line(buffer);
    if (!line.empty() && line.back() == '\n') {
      line.pop_back();
    }
    files.emplace_back(std::move(line));
  }

  return files;
}
}  // namespace

int LicenseChecker::Run(std::string_view working_dir,
                        std::string_view data_dir) {
  std::filesystem::path include_path =
      std::filesystem::path(data_dir) / "include.txt";
  absl::StatusOr<Filter> include_filter = Filter::Open(include_path.string());
  if (!include_filter.ok()) {
    std::cerr << "Can't open include.txt at " << include_path << ": "
              << include_filter.status() << std::endl;
    return 1;
  }

  std::vector<std::filesystem::path> git_repos = GetGitRepos(working_dir);

  RE2 pattern("(.*Copyright.*)");

  for (const std::filesystem::path& entry : git_repos) {
    absl::StatusOr<std::vector<std::string>> git_files = GitLsFiles(entry);
    if (!git_files.ok()) {
      std::cerr << git_files.status() << std::endl;
      return 1;
    }
    bool did_print_path = false;
    for (const std::string& git_file : git_files.value()) {
      std::filesystem::path full_path = entry / git_file;
      if (!include_filter->Matches(full_path.string())) {
        continue;
      }
      VLOG(1) << full_path.string();
      absl::StatusOr<MMapFile> file = MMapFile::Make(full_path.string());
      if (!file.ok()) {
        if (file.status().code() == absl::StatusCode::kInvalidArgument) {
          continue;
        } else {
          std::cerr << full_path << " : " << file.status() << std::endl;
          return 1;
        }
      }
      re2::StringPiece input(file->GetData(), file->GetSize());
      re2::StringPiece match;
      while (RE2::FindAndConsume(&input, pattern, &match)) {
        if (!did_print_path) {
          std::cout << full_path << std::endl;
          did_print_path = true;
        }
        std::cout << "Found match: " << match << std::endl;
      }
    }
  }

  return 0;
}
