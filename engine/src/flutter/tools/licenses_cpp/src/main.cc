#include <filesystem>
#include <iostream>

#include "flutter/third_party/abseil-cpp/absl/flags/flag.h"
#include "flutter/third_party/abseil-cpp/absl/flags/parse.h"
#include "flutter/third_party/abseil-cpp/absl/flags/usage.h"
#include "flutter/third_party/abseil-cpp/absl/status/statusor.h"

ABSL_FLAG(std::optional<std::string>,
          working_dir,
          std::nullopt,
          "[REQUIRED] The directory to scan.");
ABSL_FLAG(std::optional<std::string>,
          data_dir,
          std::nullopt,
          "[REQUIRED] The directory with the licenses.");

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

int Run(std::string_view working_dir, std::string_view data_dir) {
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

int main(int argc, char** argv) {
  absl::SetProgramUsageMessage(
      absl::StrCat("Sample usage:\n", argv[0],
                   " --working_dir=<directory> --data_dir=<directory>"));

  std::vector<char*> args = absl::ParseCommandLine(argc, argv);

  bool run = true;
  if (!absl::GetFlag(FLAGS_working_dir).has_value()) {
    run = false;
    std::cerr << "Expected --working_dir flag." << std::endl;
  }
  if (!absl::GetFlag(FLAGS_data_dir).has_value()) {
    run = false;
    std::cerr << "Expected --data_dir flag." << std::endl;
  }

  if (run) {
    return Run(absl::GetFlag(FLAGS_working_dir).value(),
               absl::GetFlag(FLAGS_data_dir).value());
  }

  return 1;
}
