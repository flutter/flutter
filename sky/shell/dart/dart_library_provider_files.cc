// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/dart/dart_library_provider_files.h"

#include "base/bind.h"
#include "base/files/file_util.h"
#include "base/strings/string_util.h"
#include "base/threading/worker_pool.h"
#include "mojo/data_pipe_utils/data_pipe_utils.h"
#include "sky/engine/tonic/dart_converter.h"

namespace sky {
namespace shell {
namespace {

void CopyComplete(base::FilePath file, bool success) {
  if (!success)
    LOG(FATAL) << "Failed to load " << file.AsUTF8Unsafe();
}

base::FilePath SimplifyPath(const base::FilePath& path) {
  std::vector<base::FilePath::StringType> components;
  path.GetComponents(&components);
  auto it = components.begin();
  base::FilePath result(*it++);
  for (; it != components.end(); it++) {
    auto& component = *it;
    if (component == base::FilePath::kCurrentDirectory)
      continue;
    if (component == base::FilePath::kParentDirectory)
      result = result.DirName();
    else
      result = result.Append(component);
  }
  return result;
}

}  // namespace

DartLibraryProviderFiles::DartLibraryProviderFiles() {
}

DartLibraryProviderFiles::~DartLibraryProviderFiles() {
}

void DartLibraryProviderFiles::LoadPackagesMap(const base::FilePath& packages) {
  packages_ = base::MakeAbsoluteFilePath(packages);
  std::string packages_source;
  if (!base::ReadFileToString(packages_, &packages_source)) {
    LOG(ERROR) << "error: Unable to load .packages file '"
               << packages_.AsUTF8Unsafe() << "'.";
    exit(1);
  }
  std::string error;
  if (!packages_map_.Parse(packages_source, &error)) {
    LOG(ERROR) << "error: Unable to parse .packages file '"
               << packages_.AsUTF8Unsafe() << "'.\n" << error;
    exit(1);
  }
}

void DartLibraryProviderFiles::GetLibraryAsStream(
    const std::string& name,
    blink::DataPipeConsumerCallback callback) {
  mojo::DataPipe pipe;
  callback.Run(pipe.consumer_handle.Pass());

  base::FilePath source(name);
  scoped_refptr<base::TaskRunner> runner =
      base::WorkerPool::GetTaskRunner(true);
  mojo::common::CopyFromFile(source, pipe.producer_handle.Pass(), 0,
                             runner.get(), base::Bind(&CopyComplete, source));
}

std::string DartLibraryProviderFiles::CanonicalizePackageURL(std::string url) {
  DCHECK(base::StartsWithASCII(url, "package:", true));
  base::ReplaceFirstSubstringAfterOffset(&url, 0, "package:", "");
  size_t slash = url.find('/');
  if (slash == std::string::npos)
    return std::string();
  std::string package = url.substr(0, slash);
  std::string library_path = url.substr(slash + 1);
  std::string package_path = packages_map_.Resolve(package);
  if (package_path.empty())
    return std::string();
  if (base::StartsWithASCII(package_path, "file://", true)) {
    base::ReplaceFirstSubstringAfterOffset(&package_path, 0, "file://", "");
    return package_path + library_path;
  }
  auto path = packages_.DirName().Append(package_path).Append(library_path);
  return SimplifyPath(path).AsUTF8Unsafe();
}

std::string DartLibraryProviderFiles::CanonicalizeFileURL(std::string url) {
  DCHECK(base::StartsWithASCII(url, "file:", true));
  base::ReplaceFirstSubstringAfterOffset(&url, 0, "file:", "");
  return url;
}

Dart_Handle DartLibraryProviderFiles::CanonicalizeURL(Dart_Handle library,
                                                      Dart_Handle url) {
  std::string string = blink::StdStringFromDart(url);
  if (base::StartsWithASCII(string, "dart:", true))
    return url;
  if (base::StartsWithASCII(string, "package:", true))
    return blink::StdStringToDart(CanonicalizePackageURL(string));
  if (base::StartsWithASCII(string, "file:", true))
    return blink::StdStringToDart(CanonicalizeFileURL(string));
  base::FilePath base_path(blink::StdStringFromDart(Dart_LibraryUrl(library)));
  base::FilePath resolved_path = base_path.DirName().Append(string);
  base::FilePath normalized_path = SimplifyPath(resolved_path);
  return blink::StdStringToDart(normalized_path.AsUTF8Unsafe());
}

}  // namespace shell
}  // namespace sky
