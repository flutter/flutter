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

const char* LicenseChecker::kHeaderLicenseRegex = "(?i)(license|copyright)";

namespace {
const std::array<std::string_view, 5> kLicenseFileNames = {
    "LICENSE", "LICENSE.TXT", "LICENSE.md", "LICENSE.MIT", "COPYING"};

RE2 kHeaderLicense(LicenseChecker::kHeaderLicenseRegex);

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
                                      repo_path.lexically_normal().string());
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

std::optional<fs::path> FindLicense(const Data& data,
                                    const fs::path& working_dir,
                                    const fs::path& relative_path) {
  for (std::string_view license_name : kLicenseFileNames) {
    fs::path relative_license_path =
        (relative_path / license_name).lexically_normal();
    fs::path full_license_path = working_dir / relative_license_path;
    if (fs::exists(full_license_path) &&
        !data.exclude_filter.Matches(relative_license_path.string())) {
      return full_license_path;
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
  bool is_root_package;
};

Package GetPackage(const Data& data,
                   const fs::path& working_dir,
                   const fs::path& relative_path) {
  Package result = {
      .name = working_dir.filename(),
      .license_file = FindLicense(data, working_dir, "."),
      .is_root_package = true,
  };
  bool after_third_party = false;
  fs::path current = ".";
  for (const fs::path& component : relative_path.parent_path()) {
    current /= component;
    std::optional<fs::path> current_license =
        FindLicense(data, working_dir, current);
    if (current_license.has_value()) {
      result.license_file = current_license;
    }
    if (after_third_party) {
      result.name = component;
      after_third_party = false;
    } else if (component.string() == "third_party") {
      after_third_party = true;
      result.license_file = std::nullopt;
      result.is_root_package = false;
    }
  }

  return result;
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

/// Checks the a license against known licenses and potentially adds it to the
/// license map.
/// @param path Path of the license file to check.
/// @param package Package the license file belongs to.
/// @param data The Data catalog of known licenses.
/// @param license_map The LicenseMap tracking seen licenses.
/// @return OkStatus if the license is known and successfully written to the
/// catalog.
absl::Status MatchLicenseFile(const fs::path& path,
                              const Package& package,
                              const Data& data,
                              LicenseMap* license_map) {
  if (!package.license_file.has_value()) {
    return absl::InvalidArgumentError("No license file.");
  }
  absl::StatusOr<MMapFile> license = MMapFile::Make(path.string());
  if (!license.ok()) {
    return license.status();
  } else {
    absl::StatusOr<std::vector<Catalog::Match>> matches =
        data.catalog.FindMatch(
            std::string_view(license->GetData(), license->GetSize()));

    if (matches.ok()) {
      for (const Catalog::Match& match : matches.value()) {
        license_map->Add(package.name, match.matched_text);
        VLOG(1) << "OK: " << path << " : " << match.matcher;
      }
    } else {
      return absl::NotFoundError(
          absl::StrCat("Unknown license in ",
                       package.license_file->lexically_normal().string(), " : ",
                       matches.status().message()));
    }
  }
  return absl::OkStatus();
}

/// State stored across calls to ProcessFile.
struct ProcessState {
  LicenseMap license_map;
  std::vector<absl::Status> errors;
  absl::flat_hash_set<fs::path> seen_license_files;
};

absl::Status ProcessFile(const fs::path& working_dir_path,
                         std::ostream& licenses,
                         const Data& data,
                         const fs::path& full_path,
                         const LicenseChecker::Flags& flags,
                         ProcessState* state) {
  std::vector<absl::Status>* errors = &state->errors;
  LicenseMap* license_map = &state->license_map;
  absl::flat_hash_set<fs::path>* seen_license_files =
      &state->seen_license_files;

  bool did_find_copyright = false;
  fs::path relative_path = fs::relative(full_path, working_dir_path);
  VLOG(2) << relative_path;
  if (!data.include_filter.Matches(relative_path.string()) ||
      data.exclude_filter.Matches(relative_path.string())) {
    VLOG(1) << "EXCLUDE: " << relative_path.lexically_normal();
    return absl::OkStatus();
  }

  Package package = GetPackage(data, working_dir_path, relative_path);
  if (package.license_file.has_value()) {
    auto [_, is_new_item] =
        seen_license_files->insert(package.license_file.value());
    if (is_new_item) {
      absl::Status match_status = MatchLicenseFile(package.license_file.value(),
                                                   package, data, license_map);
      if (!match_status.ok()) {
        errors->emplace_back(std::move(match_status));
      }
    }
  }

  absl::StatusOr<MMapFile> file = MMapFile::Make(full_path.string());
  if (!file.ok()) {
    if (file.status().code() == absl::StatusCode::kInvalidArgument) {
      // Zero byte file.
      return absl::OkStatus();
    } else {
      // Failure to mmap file.
      errors->push_back(file.status());
      return file.status();
    }
  }
  IterateComments(
      file->GetData(), file->GetSize(), [&](std::string_view comment) {
        VLOG(4) << comment;
        re2::StringPiece match;
        if (RE2::PartialMatch(comment, kHeaderLicense, &match)) {
          if (!VLOG_IS_ON(4)) {
            VLOG(3) << comment;
          }
          absl::StatusOr<std::vector<Catalog::Match>> matches =
              data.catalog.FindMatch(comment);
          if (matches.ok()) {
            did_find_copyright = true;
            for (const Catalog::Match& match : matches.value()) {
              license_map->Add(package.name, match.matched_text);
              VLOG(1) << "OK: " << relative_path.lexically_normal() << " : "
                      << match.matcher;
            }
          } else {
            if (flags.treat_unmatched_comments_as_errors) {
              errors->push_back(absl::NotFoundError(
                  absl::StrCat(relative_path.lexically_normal().string(), " : ",
                               matches.status().message(), "\n", comment)));
            }
            VLOG(2) << "NOT_FOUND: " << relative_path.lexically_normal()
                    << " : " << matches.status().message() << "\n"
                    << comment;
          }
        }
      });
  if (!did_find_copyright) {
    if (package.license_file.has_value()) {
      if (package.is_root_package) {
        errors->push_back(
            absl::NotFoundError("Expected root copyright in " +
                                relative_path.lexically_normal().string()));
      } else {
        fs::path relative_license_path =
            fs::relative(*package.license_file, working_dir_path);
        VLOG(1) << "OK: " << relative_path.lexically_normal()
                << " : dir license(" << relative_license_path.lexically_normal()
                << ")";
      }
    } else {
      errors->push_back(
          absl::NotFoundError("Expected copyright in " +
                              relative_path.lexically_normal().string()));
    }
  }
  return absl::OkStatus();
}
}  // namespace

std::vector<absl::Status> LicenseChecker::Run(std::string_view working_dir,
                                              std::ostream& licenses,
                                              const Data& data) {
  Flags flags;
  return Run(working_dir, licenses, data, flags);
}

std::vector<absl::Status> LicenseChecker::Run(
    std::string_view working_dir,
    std::ostream& licenses,
    const Data& data,
    const LicenseChecker::Flags& flags) {
  std::vector<fs::path> git_repos = GetGitRepos(working_dir);
  fs::path working_dir_path(working_dir);

  size_t count = 0;
  ProcessState state;
  for (const fs::path& git_repo : git_repos) {
    if (!VLOG_IS_ON(1) && IsStdoutTerminal()) {
      PrintProgress(count++, git_repos.size());
    }

    absl::StatusOr<std::vector<std::string>> git_files = GitLsFiles(git_repo);
    if (!git_files.ok()) {
      state.errors.push_back(git_files.status());
      return state.errors;
    }
    for (const std::string& git_file : git_files.value()) {
      fs::path full_path = git_repo / git_file;
      absl::Status process_result = ProcessFile(working_dir_path, licenses,
                                                data, full_path, flags, &state);
      if (!process_result.ok()) {
        return state.errors;
      }
    }
  }
  state.license_map.Write(licenses);
  if (!VLOG_IS_ON(1) && IsStdoutTerminal()) {
    PrintProgress(count++, git_repos.size());
    std::cout << std::endl;
  }

  return state.errors;
}

int LicenseChecker::Run(std::string_view working_dir,
                        std::ostream& licenses,
                        std::string_view data_dir,
                        const LicenseChecker::Flags& flags) {
  absl::StatusOr<Data> data = Data::Open(data_dir);
  if (!data.ok()) {
    std::cerr << "Can't load data at " << data_dir << ": " << data.status()
              << std::endl;
    return 1;
  }
  std::vector<absl::Status> errors =
      Run(working_dir, licenses, data.value(), flags);
  for (const absl::Status& status : errors) {
    std::cerr << status << "\n";
  }

  if (!errors.empty()) {
    std::cout << "Error count: " << errors.size();
  }

  return errors.empty() ? 0 : 1;
}

int LicenseChecker::FileRun(std::string_view working_dir,
                            std::string_view full_path,
                            std::ostream& licenses,
                            std::string_view data_dir,
                            const Flags& flags) {
  absl::StatusOr<Data> data = Data::Open(data_dir);
  if (!data.ok()) {
    std::cerr << "Can't load data at " << data_dir << ": " << data.status()
              << std::endl;
    return 1;
  }

  ProcessState state;
  absl::Status process_result = ProcessFile(working_dir, licenses, data.value(),
                                            full_path, flags, &state);

  if (!process_result.ok()) {
    std::cerr << process_result << std::endl;
    return 1;
  }

  state.license_map.Write(licenses);
  for (const absl::Status& status : state.errors) {
    std::cerr << status << "\n";
  }

  if (!state.errors.empty()) {
    std::cout << "Error count: " << state.errors.size();
  }

  return state.errors.empty() ? 0 : 1;
}
