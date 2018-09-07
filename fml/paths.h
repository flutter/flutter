// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PATHS_H_
#define FLUTTER_FML_PATHS_H_

#include <string>
#include <utility>

namespace fml {
namespace paths {

std::pair<bool, std::string> GetExecutableDirectoryPath();

std::string JoinPaths(std::initializer_list<std::string> components);

// Returns the absolute path of a possibly relative path.
// It doesn't consult the filesystem or simplify the path.
std::string AbsolutePath(const std::string& path);

// Returns the directory name component of the given path.
std::string GetDirectoryName(const std::string& path);

// Decodes a URI encoded string.
std::string SanitizeURIEscapedCharacters(const std::string& str);

// Converts a file URI to a path.
std::string FromURI(const std::string& uri);

}  // namespace paths
}  // namespace fml

#endif  // FLUTTER_FML_PATHS_H_
