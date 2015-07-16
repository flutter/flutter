// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/jni_array.h"

#include "base/android/jni_android.h"
#include "base/android/scoped_java_ref.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace android {

TEST(JniArray, BasicConversions) {
  const uint8 kBytes[] = { 0, 1, 2, 3 };
  const size_t kLen = arraysize(kBytes);
  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jbyteArray> bytes = ToJavaByteArray(env, kBytes, kLen);
  ASSERT_TRUE(bytes.obj());

  std::vector<uint8> vec(5);
  JavaByteArrayToByteVector(env, bytes.obj(), &vec);
  EXPECT_EQ(4U, vec.size());
  std::vector<uint8> expected_vec(kBytes, kBytes + kLen);
  EXPECT_EQ(expected_vec, vec);

  AppendJavaByteArrayToByteVector(env, bytes.obj(), &vec);
  EXPECT_EQ(8U, vec.size());
  expected_vec.insert(expected_vec.end(), kBytes, kBytes + kLen);
  EXPECT_EQ(expected_vec, vec);
}

void CheckIntConversion(
    JNIEnv* env,
    const int* int_array,
    const size_t len,
    const ScopedJavaLocalRef<jintArray>& ints) {
  ASSERT_TRUE(ints.obj());

  jsize java_array_len = env->GetArrayLength(ints.obj());
  ASSERT_EQ(static_cast<jsize>(len), java_array_len);

  jint value;
  for (size_t i = 0; i < len; ++i) {
    env->GetIntArrayRegion(ints.obj(), i, 1, &value);
    ASSERT_EQ(int_array[i], value);
  }
}

TEST(JniArray, IntConversions) {
  const int kInts[] = { 0, 1, -1, kint32min, kint32max};
  const size_t kLen = arraysize(kInts);

  JNIEnv* env = AttachCurrentThread();
  CheckIntConversion(env, kInts, kLen, ToJavaIntArray(env, kInts, kLen));

  const std::vector<int> vec(kInts, kInts + kLen);
  CheckIntConversion(env, kInts, kLen, ToJavaIntArray(env, vec));
}

void CheckLongConversion(
    JNIEnv* env,
    const int64* long_array,
    const size_t len,
    const ScopedJavaLocalRef<jlongArray>& longs) {
  ASSERT_TRUE(longs.obj());

  jsize java_array_len = env->GetArrayLength(longs.obj());
  ASSERT_EQ(static_cast<jsize>(len), java_array_len);

  jlong value;
  for (size_t i = 0; i < len; ++i) {
    env->GetLongArrayRegion(longs.obj(), i, 1, &value);
    ASSERT_EQ(long_array[i], value);
  }
}

TEST(JniArray, LongConversions) {
  const int64 kLongs[] = { 0, 1, -1, kint64min, kint64max};
  const size_t kLen = arraysize(kLongs);

  JNIEnv* env = AttachCurrentThread();
  CheckLongConversion(env, kLongs, kLen, ToJavaLongArray(env, kLongs, kLen));

  const std::vector<int64> vec(kLongs, kLongs + kLen);
  CheckLongConversion(env, kLongs, kLen, ToJavaLongArray(env, vec));
}

TEST(JniArray, JavaIntArrayToIntVector) {
  const int kInts[] = {0, 1, -1};
  const size_t kLen = arraysize(kInts);

  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jintArray> jints(env, env->NewIntArray(kLen));
  ASSERT_TRUE(jints.obj());

  for (size_t i = 0; i < kLen; ++i) {
    jint j = static_cast<jint>(kInts[i]);
    env->SetIntArrayRegion(jints.obj(), i, 1, &j);
    ASSERT_FALSE(HasException(env));
  }

  std::vector<int> ints;
  JavaIntArrayToIntVector(env, jints.obj(), &ints);

  ASSERT_EQ(static_cast<jsize>(ints.size()), env->GetArrayLength(jints.obj()));

  jint value;
  for (size_t i = 0; i < kLen; ++i) {
    env->GetIntArrayRegion(jints.obj(), i, 1, &value);
    ASSERT_EQ(ints[i], value);
  }
}

TEST(JniArray, JavaFloatArrayToFloatVector) {
  const float kFloats[] = {0.0, 0.5, -0.5};
  const size_t kLen = arraysize(kFloats);

  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jfloatArray> jfloats(env, env->NewFloatArray(kLen));
  ASSERT_TRUE(jfloats.obj());

  for (size_t i = 0; i < kLen; ++i) {
    jfloat j = static_cast<jfloat>(kFloats[i]);
    env->SetFloatArrayRegion(jfloats.obj(), i, 1, &j);
    ASSERT_FALSE(HasException(env));
  }

  std::vector<float> floats;
  JavaFloatArrayToFloatVector(env, jfloats.obj(), &floats);

  ASSERT_EQ(static_cast<jsize>(floats.size()),
      env->GetArrayLength(jfloats.obj()));

  jfloat value;
  for (size_t i = 0; i < kLen; ++i) {
    env->GetFloatArrayRegion(jfloats.obj(), i, 1, &value);
    ASSERT_EQ(floats[i], value);
  }
}

TEST(JniArray, JavaArrayOfByteArrayToStringVector) {
  const int kMaxItems = 50;
  JNIEnv* env = AttachCurrentThread();

  // Create a byte[][] object.
  ScopedJavaLocalRef<jclass> byte_array_clazz(env, env->FindClass("[B"));
  ASSERT_TRUE(byte_array_clazz.obj());

  ScopedJavaLocalRef<jobjectArray> array(
      env, env->NewObjectArray(kMaxItems, byte_array_clazz.obj(), NULL));
  ASSERT_TRUE(array.obj());

  // Create kMaxItems byte buffers.
  char text[16];
  for (int i = 0; i < kMaxItems; ++i) {
    snprintf(text, sizeof text, "%d", i);
    ScopedJavaLocalRef<jbyteArray> byte_array = ToJavaByteArray(
        env, reinterpret_cast<uint8*>(text),
        static_cast<size_t>(strlen(text)));
    ASSERT_TRUE(byte_array.obj());

    env->SetObjectArrayElement(array.obj(), i, byte_array.obj());
    ASSERT_FALSE(HasException(env));
  }

  // Convert to std::vector<std::string>, check the content.
  std::vector<std::string> vec;
  JavaArrayOfByteArrayToStringVector(env, array.obj(), &vec);

  EXPECT_EQ(static_cast<size_t>(kMaxItems), vec.size());
  for (int i = 0; i < kMaxItems; ++i) {
    snprintf(text, sizeof text, "%d", i);
    EXPECT_STREQ(text, vec[i].c_str());
  }
}

}  // namespace android
}  // namespace base
