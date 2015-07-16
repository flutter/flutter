// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_TEST_SUPPORT_ANDROID_H_
#define BASE_TEST_TEST_SUPPORT_ANDROID_H_

#include "base/base_export.h"

namespace base {

// Init logging for tests on Android. Logs will be output into Android's logcat.
BASE_EXPORT void InitAndroidTestLogging();

// Init path providers for tests on Android.
BASE_EXPORT void InitAndroidTestPaths();

// Init the message loop for tests on Android.
BASE_EXPORT void InitAndroidTestMessageLoop();

// Do all of the initializations above.
BASE_EXPORT void InitAndroidTest();

}  // namespace base

#endif  // BASE_TEST_TEST_SUPPORT_ANDROID_H_
