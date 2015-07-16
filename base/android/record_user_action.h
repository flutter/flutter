// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_RECORD_USER_ACTION_H_
#define BASE_ANDROID_RECORD_USER_ACTION_H_

#include <jni.h>

namespace base {
namespace android {

// Registers the native methods through jni
bool RegisterRecordUserAction(JNIEnv* env);

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_RECORD_USER_ACTION_H_
