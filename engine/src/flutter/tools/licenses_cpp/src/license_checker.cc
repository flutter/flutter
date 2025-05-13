// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/license_checker.h"

#include <filesystem>
#include <vector>
#include "flutter/third_party/abseil-cpp/absl/status/statusor.h"

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
  std::vector<std::filesystem::path> git_repos = GetGitRepos(working_dir);
  for (const std::filesystem::path& entry : git_repos) {
    absl::StatusOr<std::vector<std::string>> git_files = GitLsFiles(entry);
    if (!git_files.ok()) {
      return 1;
    }
    for (const std::string& foo : git_files.value()) {
      std::cout << (entry / foo) << std::endl;
    }
  }

  return 0;
}
