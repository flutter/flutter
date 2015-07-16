// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Md5sum implementation for Android. This version handles files as well as
// directories. Its output is sorted by file path.

#include <fstream>
#include <iostream>
#include <set>
#include <string>

#include "base/files/file_enumerator.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/md5.h"

namespace {

// Returns whether |path|'s MD5 was successfully written to |digest_string|.
bool MD5Sum(const char* path, std::string* digest_string) {
  base::ScopedFILE file(fopen(path, "rb"));
  if (!file) {
    LOG(ERROR) << "Could not open file " << path;
    return false;
  }
  base::MD5Context ctx;
  base::MD5Init(&ctx);
  const size_t kBufferSize = 1 << 16;
  scoped_ptr<char[]> buf(new char[kBufferSize]);
  size_t len;
  while ((len = fread(buf.get(), 1, kBufferSize, file.get())) > 0)
    base::MD5Update(&ctx, base::StringPiece(buf.get(), len));
  if (ferror(file.get())) {
    LOG(ERROR) << "Error reading file " << path;
    return false;
  }
  base::MD5Digest digest;
  base::MD5Final(&digest, &ctx);
  *digest_string = base::MD5DigestToBase16(digest);
  return true;
}

// Returns the set of all files contained in |files|. This handles directories
// by walking them recursively. Excludes, .svn directories and file under them.
std::set<std::string> MakeFileSet(const char** files) {
  const std::string svn_dir_component = FILE_PATH_LITERAL("/.svn/");
  std::set<std::string> file_set;
  for (const char** file = files; *file; ++file) {
    base::FilePath file_path(*file);
    if (base::DirectoryExists(file_path)) {
      base::FileEnumerator file_enumerator(
          file_path, true /* recurse */, base::FileEnumerator::FILES);
      for (base::FilePath child, empty;
           (child = file_enumerator.Next()) != empty; ) {
        // If the path contains /.svn/, ignore it.
        if (child.value().find(svn_dir_component) == std::string::npos) {
          child = base::MakeAbsoluteFilePath(child);
          file_set.insert(child.value());
        }
      }
    } else {
      file_set.insert(*file);
    }
  }
  return file_set;
}

}  // namespace

int main(int argc, const char* argv[]) {
  if (argc < 2) {
    LOG(ERROR) << "Usage: md5sum <path/to/file_or_dir>...";
    return 1;
  }
  const std::set<std::string> files = MakeFileSet(argv + 1);
  bool failed = false;
  std::string digest;
  for (std::set<std::string>::const_iterator it = files.begin();
       it != files.end(); ++it) {
    if (!MD5Sum(it->c_str(), &digest))
      failed = true;
    base::FilePath file_path(*it);
    std::cout << digest << "  "
              << base::MakeAbsoluteFilePath(file_path).value() << std::endl;
  }
  return failed;
}
