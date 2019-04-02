// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TESTING_TESTING_H_
#define TESTING_TESTING_H_

#include "gtest/gtest.h"

namespace testing {

// Returns the directory containing the test fixture for the target if this
// target has fixtures configured. If there are no fixtures, this is a link
// error.
const char* GetFixturesPath();

}  // namespace testing

#endif  // TESTING_TESTING_H_
