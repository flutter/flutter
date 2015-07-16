// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/jni_string.h"

#include "base/android/jni_android.h"
#include "base/android/scoped_java_ref.h"
#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace android {

TEST(JniString, BasicConversionsUTF8) {
  const std::string kSimpleString = "SimpleTest8";
  JNIEnv* env = AttachCurrentThread();
  std::string result =
      ConvertJavaStringToUTF8(ConvertUTF8ToJavaString(env, kSimpleString));
  EXPECT_EQ(kSimpleString, result);
}

TEST(JniString, BasicConversionsUTF16) {
  const string16 kSimpleString = UTF8ToUTF16("SimpleTest16");
  JNIEnv* env = AttachCurrentThread();
  string16 result =
      ConvertJavaStringToUTF16(ConvertUTF16ToJavaString(env, kSimpleString));
  EXPECT_EQ(kSimpleString, result);
}

}  // namespace android
}  // namespace base
