// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_IMPORTANT_FILE_WRITER_ANDROID_H_
#define BASE_ANDROID_IMPORTANT_FILE_WRITER_ANDROID_H_

#include <jni.h>

namespace base {
namespace android {

bool RegisterImportantFileWriterAndroid(JNIEnv* env);

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_IMPORTANT_FILE_WRITER_ANDROID_H_
