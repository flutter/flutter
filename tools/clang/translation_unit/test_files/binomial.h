// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
#ifndef TOOLS_CLANG_TRANSLATION_UNIT_TEST_FILES_BINOMIAL_H_
#define TOOLS_CLANG_TRANSLATION_UNIT_TEST_FILES_BINOMIAL_H_

int binomial(int n, int k) {
  return k > 0 ? binomial(n - 1, k - 1) * n / k : 1;
}

#endif  // TOOLS_CLANG_TRANSLATION_UNIT_TEST_FILES_BINOMIAL_H_
