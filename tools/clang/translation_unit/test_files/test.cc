// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "test.h"

#include <bits/wchar.h>

#include "binomial.h"

// Notice that "binomial.h" is included both here and in the "test.h" file.
// The tool should however print the path to this header file only once.

int main() {
  // Just some nonesense calculations.
  int result = calculateNumberOfWaysToDistributeNItemsAmongKPersons(10, 5);
  return result + binomial(42, 1);
}
