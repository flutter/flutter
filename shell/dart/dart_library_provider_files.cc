// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/dart/dart_library_provider_files.h"

#include "base/bind.h"
#include "base/strings/string_util.h"
#include "base/threading/worker_pool.h"
#include "mojo/common/data_pipe_utils.h"
#include "sky/engine/tonic/dart_converter.h"

namespace sky {
namespace shell {
namespace {

void Ignored(bool) {
}

base::FilePath SimplifyPath(const base::FilePath& path) {
  std::vector<base::FilePath::StringType> components;
  path.GetComponents(&components);
  base::FilePath result;
  for (const auto& component : components) {
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

DartLibraryProviderFiles::DartLibraryProviderFiles(
    const base::FilePath& package_root)
    : package_root_(package_root) {
}

DartLibraryProviderFiles::~DartLibraryProviderFiles() {
}

void DartLibraryProviderFiles::GetLibraryAsStream(
    const String& name,
    blink::DataPipeConsumerCallback callback) {
  mojo::DataPipe pipe;
  callback.Run(pipe.consumer_handle.Pass());

  base::FilePath source(name.toUTF8());
  scoped_refptr<base::TaskRunner> runner =
      base::WorkerPool::GetTaskRunner(true);
  mojo::common::CopyFromFile(source, pipe.producer_handle.Pass(), 0,
                             runner.get(), base::Bind(&Ignored));
}

std::string DartLibraryProviderFiles::CanonicalizePackageURL(std::string url) {
  DCHECK(StartsWithASCII(url, "package:", true));
  ReplaceFirstSubstringAfterOffset(&url, 0, "package:", "");
  return package_root_.Append(url).AsUTF8Unsafe();
}

Dart_Handle DartLibraryProviderFiles::CanonicalizeURL(Dart_Handle library,
                                                      Dart_Handle url) {
  std::string string = blink::StdStringFromDart(url);
  if (StartsWithASCII(string, "dart:", true))
    return url;
  if (StartsWithASCII(string, "package:", true))
    return blink::StdStringToDart(CanonicalizePackageURL(string));
  base::FilePath base_path(blink::StdStringFromDart(Dart_LibraryUrl(library)));
  base::FilePath resolved_path = base_path.DirName().Append(string);
  base::FilePath normalized_path = SimplifyPath(resolved_path);
  return blink::StdStringToDart(normalized_path.AsUTF8Unsafe());
}

}  // namespace shell
}  // namespace sky
