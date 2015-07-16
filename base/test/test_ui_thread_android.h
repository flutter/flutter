// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_TEST_UI_THREAD_ANDROID_
#define BASE_TEST_TEST_UI_THREAD_ANDROID_

#include <jni.h>

namespace base {

// Set up a thread as the Chromium UI Thread, and run its looper. This is is
// intended for C++ unit tests (e.g. the net unit tests) that don't run with the
// UI thread as their main looper, but test code that, on Android, uses UI
// thread events, so need a running UI thread.
void StartTestUiThreadLooper();

bool RegisterTestUiThreadAndroid(JNIEnv* env);
}  // namespace base

#endif  //  BASE_TEST_TEST_UI_THREAD_ANDROID_
