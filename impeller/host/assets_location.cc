// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/host/assets_location.h"

#include "flutter/fml/paths.h"

namespace flutter::testing {

//------------------------------------------------------------------------------
/// @brief      Returns the directory containing the test fixture for the target
///             if this target has fixtures configured. If there are no
///             fixtures, this is a link error. If you see a linker error on
///             this symbol, the unit-test target needs to depend on a
///             `test_fixtures` target.
///
/// @return     The fixtures path.
///
const char* GetFixturesPath();

}  // namespace flutter::testing

namespace impeller {

std::string GetAssetLocation(const char* asset_path) {
  return fml::paths::JoinPaths(
      {flutter::testing::GetFixturesPath(), std::string{asset_path}});
}

}  // namespace impeller
