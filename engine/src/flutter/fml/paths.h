// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PATHS_H_
#define FLUTTER_FML_PATHS_H_

#include <string>
#include <utility>

#include "lib/fxl/strings/string_view.h"

namespace fml {
namespace paths {

std::pair<bool, std::string> GetExecutableDirectoryPath();

std::string JoinPaths(std::initializer_list<fxl::StringView> components);

}  // namespace paths
}  // namespace fml

#endif  // FLUTTER_FML_PATHS_H_
