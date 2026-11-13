// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_SK_DATA_FIXTURES_H_
#define FLUTTER_TESTING_SK_DATA_FIXTURES_H_

#include <string>

#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkRefCnt.h"

namespace flutter::testing {

//------------------------------------------------------------------------------
/// @brief      Opens a fixture of the given file name and returns a Skia SkData
///             holding its contents.
///
///             This lives apart from `testing.h` so that the core test helpers
///             do not depend on Skia.
///
/// @param[in]  fixture_name  The fixture name
///
/// @return     An SkData, or null if the fixture does not exist or its contents
///             cannot be mapped in.
///
sk_sp<SkData> OpenFixtureAsSkData(const std::string& fixture_name);

}  // namespace flutter::testing

#endif  // FLUTTER_TESTING_SK_DATA_FIXTURES_H_
