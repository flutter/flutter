// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_TEST_SWIFTSHADER_UTILS_H_
#define FLUTTER_TESTING_TEST_SWIFTSHADER_UTILS_H_

namespace flutter::testing {

//------------------------------------------------------------------------------
/// @brief      Find and setup the installable client driver for a locally built
///             SwiftShader at known paths. The option to use SwiftShader can
///             only be used once in the process. While calling this method
///             multiple times is fine, specifying a different use_swiftshader
///             value will trip an assertion.
///
/// @warning    This call must be made before any Vulkan contexts are created in
///             the process.
///
/// @param[in]  use_swiftshader  If SwiftShader should be used.
///
void SetupSwiftshaderOnce(bool use_swiftshader);

}  // namespace flutter::testing

#endif  // FLUTTER_TESTING_TEST_SWIFTSHADER_UTILS_H_
