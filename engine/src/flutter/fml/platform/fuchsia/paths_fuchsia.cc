// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/paths.h"

namespace fml {
namespace paths {

std::pair<bool, std::string> GetExecutableDirectoryPath() {
  return {false, ""};
}

}  // namespace paths
}  // namespace fml
