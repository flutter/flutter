// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_AIKS_UNITTESTS_H_
#define FLUTTER_IMPELLER_AIKS_AIKS_UNITTESTS_H_

#include "impeller/aiks/aiks_playground.h"
#include "impeller/golden_tests/golden_playground_test.h"

namespace impeller {
namespace testing {

#ifdef IMPELLER_GOLDEN_TESTS
using AiksTest = GoldenPlaygroundTest;
#else
using AiksTest = AiksPlayground;
#endif

}  // namespace testing
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_AIKS_UNITTESTS_H_
