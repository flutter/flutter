// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/license_checker.h"

#include <filesystem>
#include <vector>
#include "flutter/third_party/abseil-cpp/absl/log/log.h"
#include "flutter/third_party/abseil-cpp/absl/status/statusor.h"
#include "flutter/third_party/re2/re2/re2.h"
#include "flutter/tools/licenses_cpp/src/comments.h"
#include "flutter/tools/licenses_cpp/src/filter.h"
#include "flutter/tools/licenses_cpp/src/mmap_file.h"

namespace fs = std::filesystem;

const char* LicenseChecker::kHeaderLicenseRegex = "(License|Copyright)";

namespace {
const std::array<std::string_view, 3> kLicenseFileNames = {
    "LICENSE", "LICENSE.TXT", "LICENSE.md"};
const char* kIncludeFilename = "include.txt";
const char* kExcludeFilename = "exclude.txt";

std::vector<fs::path> GetGitRepos(std::string_view dir) {
  std::vector<fs::path> result;
  result.push_back(dir);
  for (const fs::directory_entry& entry :
       fs::recursive_directory_iterator(dir)) {
    if (entry.path().stem() == ".git") {
      result.push_back(entry.path().parent_path());
    }
  }
  return result;
}

absl::StatusOr<std::vector<std::string>> GitLsFiles(const fs::path& repo_path) {
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

absl::Status CheckLicense(const fs::path& git_repo) {
  for (std::string_view license_name : kLicenseFileNames) {
    fs::path license_path = git_repo / license_name;
    if (fs::exists(license_path)) {
      return absl::UnimplementedError("");
    }
  }
  return absl::UnavailableError(
      absl::StrCat("Expected LICENSE at ", git_repo.string()));
}
}  // namespace

int LicenseChecker::Run(std::string_view working_dir,
                        std::string_view data_dir) {
  fs::path include_path = fs::path(data_dir) / kIncludeFilename;
  absl::StatusOr<Filter> include_filter = Filter::Open(include_path.string());
  if (!include_filter.ok()) {
    std::cerr << "Can't open include.txt at " << include_path << ": "
              << include_filter.status() << std::endl;
    return 1;
  }
  fs::path exclude_path = fs::path(data_dir) / kExcludeFilename;
  absl::StatusOr<Filter> exclude_filter = Filter::Open(exclude_path.string());
  if (!exclude_filter.ok()) {
    std::cerr << "Can't open include.txt at " << include_path << ": "
              << exclude_filter.status() << std::endl;
    return 1;
  }

  std::vector<fs::path> git_repos = GetGitRepos(working_dir);

  RE2 pattern(kHeaderLicenseRegex);
  int return_code = 0;

  for (const fs::path& git_repo : git_repos) {
    absl::Status license_status = CheckLicense(git_repo);
    if (!license_status.ok() &&
        license_status.code() != absl::StatusCode::kUnimplemented) {
      std::cerr << license_status << std::endl;
      return_code = 1;
    }

    absl::StatusOr<std::vector<std::string>> git_files = GitLsFiles(git_repo);
    if (!git_files.ok()) {
      std::cerr << git_files.status() << std::endl;
      return 1;
    }
    for (const std::string& git_file : git_files.value()) {
      bool did_find_copyright = false;
      fs::path full_path = git_repo / git_file;
      if (!include_filter->Matches(full_path.string()) ||
          exclude_filter->Matches(full_path.string())) {
        // Ignore file.
        continue;
      }
      VLOG(1) << full_path.string();
      absl::StatusOr<MMapFile> file = MMapFile::Make(full_path.string());
      if (!file.ok()) {
        if (file.status().code() == absl::StatusCode::kInvalidArgument) {
          // Zero byte file.
          continue;
        } else {
          // Failure to mmap file.
          std::cerr << full_path << " : " << file.status() << std::endl;
          return 1;
        }
      }
      lex(file->GetData(), file->GetSize(), [&](std::string_view comment) {
        VLOG(2) << comment;
        re2::StringPiece match;
        if (RE2::PartialMatch(comment, pattern, &match)) {
          did_find_copyright = true;
          VLOG(1) << comment;
        }
      });
      if (!did_find_copyright) {
        std::cerr << "Expected copyright in " << full_path << std::endl;
        return_code = 1;
      }
    }
  }

  return return_code;
}
