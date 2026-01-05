// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_INTERACTIVE_TEST_HELPER_H_
#define FLUTTER_TESTING_INTERACTIVE_TEST_HELPER_H_

#include <string>

namespace flutter::testing {

/// @brief Runs the interactive test runner loop.
///
/// @param history_filename The filename to use for saving/loading the last used
/// filter.
void RunInteractive(const std::string& history_filename);

}  // namespace flutter::testing

#endif  // FLUTTER_TESTING_INTERACTIVE_TEST_HELPER_H_
