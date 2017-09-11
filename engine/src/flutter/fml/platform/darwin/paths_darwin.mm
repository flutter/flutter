// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/paths.h"

#include <Foundation/Foundation.h>

#include "lib/fxl/files/path.h"

namespace fml {
namespace paths {

std::pair<bool, std::string> GetExecutableDirectoryPath() {
  return {true, files::GetDirectoryName([NSBundle mainBundle].executablePath.UTF8String)};
}

}  // namespace paths
}  // namespace fml
