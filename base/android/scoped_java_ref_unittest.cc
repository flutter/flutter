// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/scoped_java_ref.h"

#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace android {

namespace {
int g_local_refs = 0;
int g_global_refs = 0;

const JNINativeInterface* g_previous_functions;

jobject NewGlobalRef(JNIEnv* env, jobject obj) {
  ++g_global_refs;
  return g_previous_functions->NewGlobalRef(env, obj);
}

void DeleteGlobalRef(JNIEnv* env, jobject obj) {
  --g_global_refs;
  return g_previous_functions->DeleteGlobalRef(env, obj);
}

jobject NewLocalRef(JNIEnv* env, jobject obj) {
  ++g_local_refs;
  return g_previous_functions->NewLocalRef(env, obj);
}

void DeleteLocalRef(JNIEnv* env, jobject obj) {
  --g_local_refs;
  return g_previous_functions->DeleteLocalRef(env, obj);
}
}  // namespace

class ScopedJavaRefTest : public testing::Test {
 protected:
  void SetUp() override {
    g_local_refs = 0;
    g_global_refs = 0;
    JNIEnv* env = AttachCurrentThread();
    g_previous_functions = env->functions;
    hooked_functions = *g_previous_functions;
    env->functions = &hooked_functions;
    // We inject our own functions in JNINativeInterface so we can keep track
    // of the reference counting ourselves.
    hooked_functions.NewGlobalRef = &NewGlobalRef;
    hooked_functions.DeleteGlobalRef = &DeleteGlobalRef;
    hooked_functions.NewLocalRef = &NewLocalRef;
    hooked_functions.DeleteLocalRef = &DeleteLocalRef;
  }

  void TearDown() override {
    JNIEnv* env = AttachCurrentThread();
    env->functions = g_previous_functions;
  }
  // From JellyBean release, the instance of this struct provided in JNIEnv is
  // read-only, so we deep copy it to allow individual functions to be hooked.
  JNINativeInterface hooked_functions;
};

// The main purpose of this is testing the various conversions compile.
TEST_F(ScopedJavaRefTest, Conversions) {
  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jstring> str = ConvertUTF8ToJavaString(env, "string");
  ScopedJavaGlobalRef<jstring> global(str);
  {
    ScopedJavaGlobalRef<jobject> global_obj(str);
    ScopedJavaLocalRef<jobject> local_obj(global);
    const JavaRef<jobject>& obj_ref1(str);
    const JavaRef<jobject>& obj_ref2(global);
    EXPECT_TRUE(env->IsSameObject(obj_ref1.obj(), obj_ref2.obj()));
    EXPECT_TRUE(env->IsSameObject(global_obj.obj(), obj_ref2.obj()));
  }
  global.Reset(str);
  const JavaRef<jstring>& str_ref = str;
  EXPECT_EQ("string", ConvertJavaStringToUTF8(str_ref));
  str.Reset();
}

TEST_F(ScopedJavaRefTest, RefCounts) {
  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jstring> str;
  // The ConvertJavaStringToUTF8 below creates a new string that would normally
  // return a local ref. We simulate that by starting the g_local_refs count at
  // 1.
  g_local_refs = 1;
  str.Reset(ConvertUTF8ToJavaString(env, "string"));
  EXPECT_EQ(1, g_local_refs);
  EXPECT_EQ(0, g_global_refs);
  {
    ScopedJavaGlobalRef<jstring> global_str(str);
    ScopedJavaGlobalRef<jobject> global_obj(global_str);
    EXPECT_EQ(1, g_local_refs);
    EXPECT_EQ(2, g_global_refs);

    ScopedJavaLocalRef<jstring> str2(env, str.Release());
    EXPECT_EQ(1, g_local_refs);
    {
      ScopedJavaLocalRef<jstring> str3(str2);
      EXPECT_EQ(2, g_local_refs);
    }
    EXPECT_EQ(1, g_local_refs);
    str2.Reset();
    EXPECT_EQ(0, g_local_refs);
    global_str.Reset();
    EXPECT_EQ(1, g_global_refs);
    ScopedJavaGlobalRef<jobject> global_obj2(global_obj);
    EXPECT_EQ(2, g_global_refs);
  }

  EXPECT_EQ(0, g_local_refs);
  EXPECT_EQ(0, g_global_refs);
}

}  // namespace android
}  // namespace base
