// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tools/licenses_cpp/src/license_checker.h"

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <filesystem>
#include <vector>
#include "flutter/third_party/abseil-cpp/absl/status/statusor.h"
#include "flutter/third_party/re2/re2/re2.h"

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

class MMapFile {
 public:
  static absl::StatusOr<MMapFile> Make(std::string_view path) {
    int fd = open(path.data(), O_RDONLY);
    if (fd < 0) {
      return absl::UnavailableError("can't open file");
    }

    struct stat st;
    if (fstat(fd, &st) < 0) {
      close(fd);
      return absl::UnavailableError("can't stat file");
    }

    const char* data = static_cast<const char*>(
        mmap(nullptr, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0));

    if (data == MAP_FAILED) {
      close(fd);
      return absl::UnavailableError(
          absl::StrCat("can't mmap file (", path, "): ", std::strerror(errno)));
    }

    return MMapFile(fd, data, st.st_size);
  }

  ~MMapFile() {
    if (data_) {
      munmap(const_cast<char*>(data_), size_);
    }
    if (fd_ >= 0) {
      close(fd_);
    }
  }

  MMapFile(const MMapFile&) = delete;

  MMapFile& operator=(const MMapFile&) = delete;

  MMapFile(MMapFile&& other) {
    fd_ = other.fd_;
    data_ = other.data_;
    size_ = other.size_;
    other.fd_ = -1;
    other.data_ = nullptr;
    other.size_ = 0;
  }

  const char* GetData() const { return data_; }
  size_t GetSize() const { return size_; }

 private:
  MMapFile(int fd, const char* data, size_t size)
      : fd_(fd), data_(data), size_(size) {}

  int fd_ = -1;
  const char* data_ = nullptr;
  size_t size_ = 0;
};
}  // namespace

int LicenseChecker::Run(std::string_view working_dir,
                        std::string_view data_dir) {
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
      absl::StatusOr<MMapFile> file = MMapFile::Make(full_path.string());
      if (!file.ok()) {
        std::cerr << file.status() << std::endl;
        continue;
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
