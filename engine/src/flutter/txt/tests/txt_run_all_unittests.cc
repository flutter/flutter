// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/backtrace.h"
#include "flutter/testing/testing.h"

int main(int argc, char** argv) {
  fml::InstallCrashHandler();
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
