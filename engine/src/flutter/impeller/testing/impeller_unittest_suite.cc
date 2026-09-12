// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/testing/impeller_unittest_suite.h"

#include "flutter/fml/logging.h"
#include "flutter/impeller/playground/playground_test.h"

namespace impeller {
namespace testing {

bool ImpellerUnittestSetup() {
  return ::impeller::PlaygroundTest::SetupTestEnvironment();
}

}  // namespace testing
}  // namespace impeller
