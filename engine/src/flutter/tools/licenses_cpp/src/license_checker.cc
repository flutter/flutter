// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/license_checker.h"

#include <unistd.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <vector>

#include "flutter/third_party/abseil-cpp/absl/container/btree_map.h"
#include "flutter/third_party/abseil-cpp/absl/container/flat_hash_set.h"
#include "flutter/third_party/abseil-cpp/absl/log/log.h"
#include "flutter/third_party/abseil-cpp/absl/status/statusor.h"
#include "flutter/third_party/re2/re2/re2.h"
#include "flutter/tools/licenses_cpp/src/comments.h"
#include "flutter/tools/licenses_cpp/src/data.h"
#include "flutter/tools/licenses_cpp/src/filter.h"
#include "flutter/tools/licenses_cpp/src/mmap_file.h"

namespace fs = std::filesystem;

const char* LicenseChecker::kHeaderLicenseRegex = "(License|Copyright)";

namespace {
const std::array<std::string_view, 3> kLicenseFileNames = {
    "LICENSE", "LICENSE.TXT", "LICENSE.md"};

std::vector<fs::path> GetGitRepos(std::string_view dir) {
  std::vector<fs::path> result;
  for (const fs::directory_entry& entry :
       fs::recursive_directory_iterator(dir)) {
    if (entry.path().stem() == ".git") {
      result.push_back(entry.path().parent_path());
    }
  }
  // Put the query dir in there if we didn't get it yet.  This allows us to
  // query subdirectories, like `engine`.
  if (!result.empty() && result[0] != dir) {
    result.push_back(dir);
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

std::optional<fs::path> FindLicense(const fs::path& path) {
  for (std::string_view license_name : kLicenseFileNames) {
    fs::path license_path = path / license_name;
    if (fs::exists(license_path)) {
      return license_path;
    }
  }
  return std::nullopt;
}

void PrintProgress(size_t idx, size_t count) {
  std::cout << "\rprogress: [";
  double percent = static_cast<double>(idx) / count;
  int done = percent * 50;
  int left = 50 - done;
  for (int i = 0; i < done; ++i) {
    std::cout << "o";
  }
  for (int i = 0; i < left; ++i) {
    std::cout << ".";
  }
  std::cout << "]" << std::flush;
}

bool IsStdoutTerminal() {
  return isatty(STDOUT_FILENO);
}

class LicensesWriter {
 public:
  explicit LicensesWriter(std::ostream& licenses) : licenses_(licenses) {}

  void Write(const absl::flat_hash_set<std::string>& packages,
             std::string_view license) {
    std::vector<std::string_view> sorted;
    sorted.reserve(packages.size());
    sorted.insert(sorted.end(), packages.begin(), packages.end());
    std::sort(sorted.begin(), sorted.end());
    if (!first_write_) {
      for (int i = 0; i < 80; ++i) {
        licenses_.put('-');
      }
      licenses_.put('\n');
    }
    first_write_ = false;
    for (std::string_view package : sorted) {
      licenses_ << package << "\n";
    }
    licenses_ << "\n" << license << "\n";
  }

 private:
  std::ostream& licenses_;
  bool first_write_ = true;
};

struct Package {
  std::string name;
  std::optional<fs::path> license_file;
};

Package GetPackage(const fs::path& working_dir, const fs::path& full_path) {
  Package result = {
      .name = "engine",
      .license_file = FindLicense(working_dir),
  };
  fs::path relative = fs::relative(full_path, working_dir);
  bool after_third_party = false;
  fs::path current = working_dir;
  for (const fs::path& component : relative) {
    current /= component;
    if (after_third_party) {
      result.name = component;
      after_third_party = false;
      result.license_file = FindLicense(current);
    } else if (component.string() == "third_party") {
      after_third_party = true;
      result.license_file = std::nullopt;
    }
  }

  return result;
}

std::string ReadFile(const fs::path& path) {
  std::ifstream stream(path);
  assert(stream.good());
  std::string license((std::istreambuf_iterator<char>(stream)),
                      std::istreambuf_iterator<char>());
  if (license[license.size() - 1] == '\n') {
    license.pop_back();
  }
  return license;
}

class LicenseMap {
 public:
  void Add(std::string_view package, std::string_view license) {
    auto package_emplace_result =
        map_.try_emplace(license, absl::flat_hash_set<std::string>());
    absl::flat_hash_set<std::string>& comment_set =
        package_emplace_result.first->second;
    if (comment_set.find(package) == comment_set.end()) {
      // License is already seen.
      comment_set.emplace(std::string(package));
    }
  }

  void AddFile(std::string_view package, const fs::path& path) {
    if (!license_files_.contains(path.string())) {
      Add(package, ReadFile(path));
      license_files_.insert(path);
    }
  }

  void Write(std::ostream& licenses) {
    LicensesWriter writer(licenses);
    for (const auto& comment_entry : map_) {
      writer.Write(comment_entry.second, comment_entry.first);
    }
  }

 private:
  absl::btree_map<std::string, absl::flat_hash_set<std::string>> map_;
  absl::flat_hash_set<std::string> license_files_;
};
}  // namespace

std::vector<absl::Status> LicenseChecker::Run(std::string_view working_dir,
                                              std::ostream& licenses,
                                              const Data& data) {
  std::vector<absl::Status> errors;
  std::vector<fs::path> git_repos = GetGitRepos(working_dir);
  fs::path working_dir_path(working_dir);

  RE2 pattern(kHeaderLicenseRegex);

  size_t count = 0;
  LicenseMap license_map;
  for (const fs::path& git_repo : git_repos) {
    if (IsStdoutTerminal()) {
      PrintProgress(count++, git_repos.size());
    }

    absl::StatusOr<std::vector<std::string>> git_files = GitLsFiles(git_repo);
    if (!git_files.ok()) {
      errors.push_back(git_files.status());
      return errors;
    }
    for (const std::string& git_file : git_files.value()) {
      bool did_find_copyright = false;
      fs::path full_path = git_repo / git_file;
      if (!data.include_filter.Matches(full_path.string()) ||
          data.exclude_filter.Matches(full_path.string())) {
        // Ignore file.
        continue;
      }

      Package package = GetPackage(working_dir_path, full_path);
      if (package.license_file.has_value()) {
        license_map.AddFile(package.name, package.license_file.value());
      }

      VLOG(1) << full_path.string();
      absl::StatusOr<MMapFile> file = MMapFile::Make(full_path.string());
      if (!file.ok()) {
        if (file.status().code() == absl::StatusCode::kInvalidArgument) {
          // Zero byte file.
          continue;
        } else {
          // Failure to mmap file.
          errors.push_back(file.status());
          return errors;
        }
      }
      IterateComments(file->GetData(), file->GetSize(),
                      [&](std::string_view comment) {
                        VLOG(2) << comment;
                        re2::StringPiece match;
                        if (RE2::PartialMatch(comment, pattern, &match)) {
                          did_find_copyright = true;
                          VLOG(1) << comment;
                          if (!package.license_file.has_value()) {
                            license_map.Add(package.name, comment);
                          }
                        }
                      });
      if (!did_find_copyright && !package.license_file.has_value()) {
        errors.push_back(
            absl::NotFoundError("Expected copyright in " + full_path.string()));
      }
    }
  }
  license_map.Write(licenses);
  if (IsStdoutTerminal()) {
    PrintProgress(count++, git_repos.size());
    std::cout << std::endl;
  }

  return errors;
}

int LicenseChecker::Run(std::string_view working_dir,
                        std::ostream& licenses,
                        std::string_view data_dir) {
  absl::StatusOr<Data> data = Data::Open(data_dir);
  if (!data.ok()) {
    std::cerr << "Can't load data at " << data_dir << ": " << data.status()
              << std::endl;
    return 1;
  }
  std::vector<absl::Status> errors = Run(working_dir, licenses, data.value());
  for (const absl::Status& status : errors) {
    std::cerr << status << std::endl;
  }

  return errors.empty() ? 0 : 1;
}
