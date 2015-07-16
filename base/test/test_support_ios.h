// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_TEST_SUPPORT_IOS_H_
#define BASE_TEST_TEST_SUPPORT_IOS_H_

#include "base/test/test_suite.h"

namespace base {

// Inits the message loop for tests on iOS.
void InitIOSTestMessageLoop();

// Inits the run hook for tests on iOS.
void InitIOSRunHook(TestSuite* suite, int argc, char* argv[]);

// Launches an iOS app that runs the tests in the suite passed to
// InitIOSRunHook.
void RunTestsFromIOSApp();

}  // namespace base

#endif  // BASE_TEST_TEST_SUPPORT_IOS_H_
