// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TESTING_ANDROID_NATIVE_TEST_LAUNCHER_H_
#define TESTING_ANDROID_NATIVE_TEST_LAUNCHER_H_

#include <jni.h>

namespace testing {
namespace android {

void InstallHandlers();
bool RegisterNativeTestJNI(JNIEnv* env);

}  // namespace android
}  // namespace testing

#endif  // TESTING_ANDROID_NATIVE_TEST_LAUNCHER_H_
