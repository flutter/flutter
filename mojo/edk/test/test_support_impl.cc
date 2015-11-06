// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/test_support/test_support.h"

#include "base/files/file_enumerator.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/path_service.h"
#include "base/test/perf_log.h"

namespace mojo {
namespace test {
namespace {

base::FilePath ResolveSourceRootRelativePath(const std::string& relative_path) {
  // TODO(vtl): Have someone inject the source root instead.
  base::FilePath path;
  if (!PathService::Get(base::DIR_SOURCE_ROOT, &path))
    return base::FilePath();
  return path.Append(base::FilePath::FromUTF8Unsafe(relative_path));
}

}  // namespace

void LogPerfResult(const char* test_name,
                   const char* sub_test_name,
                   double value,
                   const char* units) {
  DCHECK(test_name);
  if (sub_test_name) {
    std::string name = std::string(test_name) + "/" + sub_test_name;
    base::LogPerfResult(name.c_str(), value, units);
  } else {
    base::LogPerfResult(test_name, value, units);
  }
}

FILE* OpenSourceRootRelativeFile(const std::string& relative_path) {
  return base::OpenFile(ResolveSourceRootRelativePath(relative_path), "rb");
}

std::vector<std::string> EnumerateSourceRootRelativeDirectory(
    const std::string& relative_path) {
  std::vector<std::string> names;
  base::FileEnumerator e(ResolveSourceRootRelativePath(relative_path), false,
                         base::FileEnumerator::FILES);
  for (base::FilePath name = e.Next(); !name.empty(); name = e.Next())
    names.push_back(name.BaseName().AsUTF8Unsafe());
  return names;
}

}  // namespace test
}  // namespace mojo
