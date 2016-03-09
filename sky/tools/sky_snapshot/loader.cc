// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/sky_snapshot/loader.h"

#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/strings/string_util.h"
#include "sky/tools/sky_snapshot/logging.h"
#include "sky/tools/sky_snapshot/scope.h"
#include "sky/tools/sky_snapshot/switches.h"

namespace {

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

class Loader {
 public:
  Loader(const base::FilePath& package_root);

  const std::set<std::string>& dependencies() const { return dependencies_; }

  std::string CanonicalizePackageURL(std::string url);
  Dart_Handle CanonicalizeURL(Dart_Handle library, Dart_Handle url);
  std::string Fetch(const std::string& url);
  Dart_Handle Import(Dart_Handle url);
  Dart_Handle Source(Dart_Handle library, Dart_Handle url);

 private:
  std::set<std::string> dependencies_;
  base::FilePath package_root_;

  DISALLOW_COPY_AND_ASSIGN(Loader);
};

Loader::Loader(const base::FilePath& package_root)
    : package_root_(package_root) {
}

std::string Loader::CanonicalizePackageURL(std::string url) {
  DCHECK(base::StartsWithASCII(url, "package:", true));
  base::ReplaceFirstSubstringAfterOffset(&url, 0, "package:", "");
  return package_root_.Append(url).AsUTF8Unsafe();
}

Dart_Handle Loader::CanonicalizeURL(Dart_Handle library, Dart_Handle url) {
  std::string string = StringFromDart(url);
  if (base::StartsWithASCII(string, "dart:", true))
    return url;
  if (base::StartsWithASCII(string, "package:", true))
    return StringToDart(CanonicalizePackageURL(string));
  base::FilePath base_path(StringFromDart(Dart_LibraryUrl(library)));
  base::FilePath resolved_path = base_path.DirName().Append(string);
  base::FilePath normalized_path = SimplifyPath(resolved_path);
  return StringToDart(normalized_path.AsUTF8Unsafe());
}

std::string Loader::Fetch(const std::string& url) {
  base::FilePath path(url);
  std::string source;
  if (!base::ReadFileToString(path, &source)) {
    fprintf(stderr, "error: Unable to find Dart library '%s'.\n", url.c_str());
    exit(1);
  }
  dependencies_.insert(url);
  return source;
}

Dart_Handle Loader::Import(Dart_Handle url) {
  Dart_Handle source = StringToDart(Fetch(StringFromDart(url)));
  Dart_Handle result = Dart_LoadLibrary(url, source, 0, 0);
  LogIfError(result);
  return result;
}

Dart_Handle Loader::Source(Dart_Handle library, Dart_Handle url) {
  Dart_Handle source = StringToDart(Fetch(StringFromDart(url)));
  Dart_Handle result = Dart_LoadSource(library, url, source, 0, 0);
  LogIfError(result);
  return result;
}

Loader* g_loader = nullptr;

Loader& GetLoader() {
  if (!g_loader) {
    base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();
    CHECK(command_line.HasSwitch(switches::kPackageRoot))
        << "Need --package-root";
    g_loader =
        new Loader(command_line.GetSwitchValuePath(switches::kPackageRoot));
  }
  return *g_loader;
}

}  // namespace

Dart_Handle HandleLibraryTag(Dart_LibraryTag tag,
                             Dart_Handle library,
                             Dart_Handle url) {
  CHECK(Dart_IsLibrary(library));
  CHECK(Dart_IsString(url));

  if (tag == Dart_kCanonicalizeUrl)
    return GetLoader().CanonicalizeURL(library, url);

  if (tag == Dart_kImportTag)
    return GetLoader().Import(url);

  if (tag == Dart_kSourceTag)
    return GetLoader().Source(library, url);

  return Dart_NewApiError("Unknown library tag.");
}

void LoadScript(const std::string& url) {
  LogIfError(
      Dart_LoadScript(StringToDart(url), StringToDart(GetLoader().Fetch(url)),
                      0, 0));
}

const std::set<std::string>& GetDependencies() {
  return GetLoader().dependencies();
}
