// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/license_checker.h"

#include <unistd.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <vector>

#include "flutter/third_party/re2/re2/re2.h"
#include "flutter/tools/licenses_cpp/src/comments.h"
#include "flutter/tools/licenses_cpp/src/data.h"
#include "flutter/tools/licenses_cpp/src/deps_parser.h"
#include "flutter/tools/licenses_cpp/src/filter.h"
#include "flutter/tools/licenses_cpp/src/mmap_file.h"
#include "third_party/abseil-cpp/absl/container/btree_map.h"
#include "third_party/abseil-cpp/absl/container/flat_hash_set.h"
#include "third_party/abseil-cpp/absl/log/log.h"
#include "third_party/abseil-cpp/absl/log/vlog_is_on.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"
#include "third_party/abseil-cpp/absl/strings/str_cat.h"

namespace fs = std::filesystem;

const char* LicenseChecker::kHeaderLicenseRegex = "(?i)(license|copyright)";

namespace {
// TODO(): Move this into the data directory.
const std::array<std::string_view, 9> kLicenseFileNames = {
    "LICENSE", "LICENSE.TXT", "LICENSE.txt",  "LICENSE.md", "LICENSE.MIT",
    "COPYING", "License.txt", "docs/FTL.TXT", "README.ijg"};

// TODO(): Move this into the data directory
//  These are directories that when they are found in third_party directories
//  are ignored as package names.
const std::array<std::string_view, 2> kThirdPartyIgnore = {"pkg",
                                                           "vulkan-deps"};

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

/// This makes sure trailing slashes on paths are treated the same.
/// Example:
///   f("/foo/") == f("/foo") == "foo"
std::string GetDirFilename(const fs::path& working_dir) {
  std::string result = working_dir.filename();
  if (result.empty()) {
    result = working_dir.parent_path().filename();
  }
  return result;
}

Package GetPackage(const Data& data,
                   const fs::path& working_dir,
                   const fs::path& relative_path,
                   const LicenseChecker::Flags& flags) {
  std::string root_package_name = flags.root_package_name.has_value()
                                      ? flags.root_package_name.value()
                                      : GetDirFilename(working_dir);
  Package result = {
      .name = root_package_name,
      .license_file = FindLicense(data, working_dir, "."),
      .is_root_package = true,
  };
  bool after_third_party = false;
  bool after_ignored_third_party = false;
  fs::path current = ".";
  for (const fs::path& component : relative_path.parent_path()) {
    current /= component;
    std::optional<fs::path> current_license =
        FindLicense(data, working_dir, current);
    if (current_license.has_value()) {
      result.license_file = current_license;
    }
    if (after_ignored_third_party) {
      after_ignored_third_party = false;
      result.name = component;
    } else if (after_third_party) {
      if (std::find(kThirdPartyIgnore.begin(), kThirdPartyIgnore.end(),
                    component.string()) != kThirdPartyIgnore.end()) {
        after_ignored_third_party = true;
      }
      after_third_party = false;
      result.name = component;
    } else if (component.string() == "third_party") {
      after_third_party = true;
      result.license_file = std::nullopt;
      result.is_root_package = false;
    }
  }
  if (std::find(kLicenseFileNames.begin(), kLicenseFileNames.end(),
                relative_path.filename()) != kLicenseFileNames.end()) {
    result.license_file = working_dir / relative_path;
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
        license_map->Add(package.name, match.GetMatchedText());
        VLOG(1) << "OK: " << path << " : " << match.GetMatcher();
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

namespace {
bool ProcessSourceCode(const fs::path& relative_path,
                       const MMapFile& file,
                       const Data& data,
                       const Package& package,
                       const LicenseChecker::Flags& flags,
                       ProcessState* state) {
  bool did_find_copyright = false;
  std::vector<absl::Status>* errors = &state->errors;
  LicenseMap* license_map = &state->license_map;
  int32_t comment_count = 0;

  auto comment_handler = [&](std::string_view comment) -> void {
    comment_count += 1;
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
          license_map->Add(package.name, match.GetMatchedText());
          VLOG(1) << "OK: " << relative_path.lexically_normal() << " : "
                  << match.GetMatcher();
        }
      } else {
        if (flags.treat_unmatched_comments_as_errors) {
          errors->push_back(absl::NotFoundError(
              absl::StrCat(relative_path.lexically_normal().string(), " : ",
                           matches.status().message(), "\n", comment)));
        }
        VLOG(2) << "NOT_FOUND: " << relative_path.lexically_normal() << " : "
                << matches.status().message() << "\n"
                << comment;
      }
    }
  };

  IterateComments(file.GetData(), file.GetSize(), comment_handler);

  // If we didn't find any comments, the input may be a text file, not source
  // code. So, we attempt to match the full text.
  if (comment_count <= 0) {
    comment_handler(std::string_view(file.GetData(), file.GetSize()));
  }

  return did_find_copyright;
}

std::vector<std::string_view> SplitLines(std::string_view input) {
  std::vector<std::string_view> result;

  size_t pos = 0;
  while (true) {
    while (pos < input.size() && input[pos] == '\n') {
      pos++;
    }
    const ::std::string::size_type newline = input.find('\n', pos);
    if (newline == ::std::string::npos) {
      result.push_back(input.substr(pos));
      break;
    } else {
      result.push_back(input.substr(pos, newline - pos));
      pos = newline + 1;
    }
  }

  return result;
}

bool ProcessNotices(const fs::path& relative_path,
                    const MMapFile& file,
                    const Data& data,
                    const Package& package,
                    const LicenseChecker::Flags& flags,
                    ProcessState* state) {
  // std::vector<absl::Status>* errors = &state->errors;
  // LicenseMap* license_map = &state->license_map;
  static const std::string kDelimitor =
      "------------------------------------------------------------------------"
      "--------";
  static const std::string pattern_str =
      "(?s)(.+?)\n\n(.+?)(?:\n?" + kDelimitor + "|$)";
  static const RE2 regex(pattern_str);

  std::vector<absl::Status>* errors = &state->errors;
  LicenseMap* license_map = &state->license_map;
  re2::StringPiece input(file.GetData(), file.GetSize());
  std::string_view projects_text;
  std::string_view license;
  while (RE2::FindAndConsume(&input, regex, &projects_text, &license)) {
    std::vector<std::string_view> projects = SplitLines(projects_text);

    VLOG(4) << license;

    absl::StatusOr<std::vector<Catalog::Match>> matches =
        data.catalog.FindMatch(license);
    if (matches.ok()) {
      for (const Catalog::Match& match : matches.value()) {
        for (std::string_view project : projects) {
          license_map->Add(project, match.GetMatchedText());
        }
        VLOG(1) << "OK: " << relative_path.lexically_normal() << " : "
                << match.GetMatcher();
      }
    } else {
      VLOG(2) << "NOT_FOUND: " << relative_path.lexically_normal() << " : "
              << matches.status().message() << "\n"
              << license;
      if (flags.treat_unmatched_comments_as_errors) {
        errors->push_back(absl::NotFoundError(
            absl::StrCat(relative_path.lexically_normal().string(), " : ",
                         matches.status().message(), "\n", license)));
      }
    }
  }
  // Not having a license in a NOTICES file isn't technically a problem.
  return true;
}

}  // namespace

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
  fs::path relative_path = full_path.lexically_relative(working_dir_path);
  VLOG(2) << "Process: " << relative_path;
  if (!data.include_filter.Matches(relative_path.string()) ||
      data.exclude_filter.Matches(relative_path.string())) {
    VLOG(1) << "EXCLUDE: " << relative_path.lexically_normal();
    return absl::OkStatus();
  }

  Package package = GetPackage(data, working_dir_path, relative_path, flags);
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
  } else {
    VLOG(3) << "No license file: " << relative_path.lexically_normal();
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

  if (full_path.filename().string() == "NOTICES") {
    did_find_copyright =
        ProcessNotices(relative_path, *file, data, package, flags, state);
  } else {
    did_find_copyright =
        ProcessSourceCode(relative_path, *file, data, package, flags, state);
  }
  if (!did_find_copyright) {
    if (package.license_file.has_value()) {
      if (package.is_root_package) {
        errors->push_back(
            absl::NotFoundError("Expected root copyright in " +
                                relative_path.lexically_normal().string()));
      } else {
        fs::path relative_license_path =
            package.license_file->lexically_relative(working_dir_path);
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

namespace {
// Searches parent directories for `file_name` starting from `starting_dir`.
fs::path FindFileInParentDirectories(const fs::path& starting_dir,
                                     const std::string_view file_name) {
  fs::path current_dir = fs::absolute(starting_dir);
  while (!current_dir.empty() && current_dir != current_dir.root_path()) {
    fs::path file_path = current_dir / file_name;
    if (fs::exists(file_path)) {
      return file_path;
    }
    current_dir = current_dir.parent_path();
  }
  return fs::path();
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
  fs::path working_dir_path =
      fs::absolute(fs::path(working_dir)).lexically_normal();
  std::vector<fs::path> git_repos = GetGitRepos(working_dir_path.string());

  size_t count = 0;
  ProcessState state;

  // Not every dependency is a git repository, so it won't be considered with
  // the crawl that happens below of git repositories. For those dependencies
  // we just crawl the whole directory.
  fs::path deps_path = FindFileInParentDirectories(working_dir_path, "DEPS");
  if (!deps_path.empty()) {
    absl::StatusOr<MMapFile> deps_file = MMapFile::Make(deps_path.string());
    if (deps_file.ok()) {
      DepsParser deps_parser;
      std::vector<std::string> deps = deps_parser.Parse(
          std::string_view(deps_file->GetData(), deps_file->GetSize()));
      for (const std::string& dep : deps) {
        fs::path dep_path = deps_path.parent_path() / dep;
        if (fs::is_directory(dep_path)) {
          // We don't want to process deps that are outside the working
          // directory.
          if (dep_path.string().find(working_dir_path.string()) != 0) {
            continue;
          }

          for (const auto& entry : fs::recursive_directory_iterator(dep_path)) {
            if (entry.is_regular_file()) {
              absl::Status process_result =
                  ProcessFile(working_dir_path, licenses, data, entry.path(),
                              flags, &state);
              if (!process_result.ok()) {
                return state.errors;
              }
            }
          }
        }
      }
    }
  }

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

  if (!data.secondary_dir.empty()) {
    for (const auto& entry :
         fs::recursive_directory_iterator(data.secondary_dir)) {
      if (!fs::is_directory(entry)) {
        fs::path relative_path = fs::relative(entry, data.secondary_dir);
        if (!fs::exists(working_dir / relative_path.parent_path())) {
          state.errors.push_back(absl::InvalidArgumentError(absl::StrCat(
              "secondary license path mixmatch at ", relative_path.string())));
        } else {
          fs::path full_path = data.secondary_dir / entry;
          Package package =
              GetPackage(data, working_dir_path, relative_path, flags);
          absl::StatusOr<MMapFile> file = MMapFile::Make(full_path.string());
          if (file.ok()) {
            state.license_map.Add(
                package.name,
                std::string_view(file->GetData(), file->GetSize()));
          } else {
            state.errors.push_back(file.status());
          }
        }
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
  fs::path working_dir_path =
      fs::absolute(fs::path(working_dir)).lexically_normal();
  fs::path absolute_full_path = fs::absolute(fs::path(full_path));
  absl::Status process_result =
      ProcessFile(working_dir_path, licenses, data.value(), absolute_full_path,
                  flags, &state);

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
