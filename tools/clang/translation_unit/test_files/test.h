// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_CLANG_TRANSLATION_UNIT_TEST_FILES_TEST_H_
#define TOOLS_CLANG_TRANSLATION_UNIT_TEST_FILES_TEST_H_

#include "binomial.h"

// Number of ways to distribute n items of the same thing to k persons; each
// person should get at least one item.
int calculateNumberOfWaysToDistributeNItemsAmongKPersons(int n, int k) {
  return binomial(n - 1, k - 1);
}

#endif  // TOOLS_CLANG_TRANSLATION_UNIT_TEST_FILES_TEST_H_
