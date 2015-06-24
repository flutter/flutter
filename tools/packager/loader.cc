// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/packager/loader.h"

#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/strings/string_util.h"
#include "sky/tools/packager/logging.h"
#include "sky/tools/packager/scope.h"
#include "sky/tools/packager/switches.h"

namespace {

std::string Fetch(const std::string& url) {
  base::FilePath path(url);
  std::string source;
  CHECK(base::ReadFileToString(path, &source)) << url;
  return source;
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

class Loader {
 public:
  Loader(const base::FilePath& package_root);

  std::string CanonicalizePackageURL(std::string url);
  Dart_Handle CanonicalizeURL(Dart_Handle library, Dart_Handle url);
  Dart_Handle Import(Dart_Handle url);
  Dart_Handle Source(Dart_Handle library, Dart_Handle url);

 private:
  base::FilePath package_root_;

  DISALLOW_COPY_AND_ASSIGN(Loader);
};

Loader::Loader(const base::FilePath& package_root)
    : package_root_(package_root) {
}

std::string Loader::CanonicalizePackageURL(std::string url) {
  DCHECK(StartsWithASCII(url, "package:", true));
  ReplaceFirstSubstringAfterOffset(&url, 0, "package:", "");
  return package_root_.Append(url).AsUTF8Unsafe();
}

Dart_Handle Loader::CanonicalizeURL(Dart_Handle library, Dart_Handle url) {
  std::string string = StringFromDart(url);
  if (StartsWithASCII(string, "dart:", true))
    return url;
  if (StartsWithASCII(string, "package:", true))
    return StringToDart(CanonicalizePackageURL(string));
  base::FilePath base_path(StringFromDart(Dart_LibraryUrl(library)));
  base::FilePath resolved_path = base_path.DirName().Append(string);
  base::FilePath normalized_path = SimplifyPath(resolved_path);
  return StringToDart(normalized_path.AsUTF8Unsafe());
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
    CHECK(command_line.HasSwitch(kPackageRoot)) << "Need --package-root";
    g_loader = new Loader(command_line.GetSwitchValuePath(kPackageRoot));
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
      Dart_LoadScript(StringToDart(url), StringToDart(Fetch(url)), 0, 0));
}
