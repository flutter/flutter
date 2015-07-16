// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_JNI_ARRAY_H_
#define BASE_ANDROID_JNI_ARRAY_H_

#include <jni.h>
#include <string>
#include <vector>

#include "base/android/scoped_java_ref.h"
#include "base/basictypes.h"
#include "base/strings/string16.h"

namespace base {
namespace android {

// Returns a new Java byte array converted from the given bytes array.
BASE_EXPORT ScopedJavaLocalRef<jbyteArray> ToJavaByteArray(
    JNIEnv* env, const uint8* bytes, size_t len);

// Returns a new Java int array converted from the given int array.
BASE_EXPORT ScopedJavaLocalRef<jintArray> ToJavaIntArray(
    JNIEnv* env, const int* ints, size_t len);

BASE_EXPORT ScopedJavaLocalRef<jintArray> ToJavaIntArray(
    JNIEnv* env, const std::vector<int>& ints);

// Returns a new Java long array converted from the given int64 array.
BASE_EXPORT ScopedJavaLocalRef<jlongArray> ToJavaLongArray(
    JNIEnv* env, const int64* longs, size_t len);

BASE_EXPORT ScopedJavaLocalRef<jlongArray> ToJavaLongArray(
    JNIEnv* env, const std::vector<int64>& longs);

// Returns a array of Java byte array converted from |v|.
BASE_EXPORT ScopedJavaLocalRef<jobjectArray> ToJavaArrayOfByteArray(
    JNIEnv* env, const std::vector<std::string>& v);

BASE_EXPORT ScopedJavaLocalRef<jobjectArray> ToJavaArrayOfStrings(
    JNIEnv* env,  const std::vector<std::string>& v);

BASE_EXPORT ScopedJavaLocalRef<jobjectArray> ToJavaArrayOfStrings(
    JNIEnv* env,  const std::vector<string16>& v);

// Converts a Java string array to a native array.
BASE_EXPORT void AppendJavaStringArrayToStringVector(
    JNIEnv* env,
    jobjectArray array,
    std::vector<string16>* out);

BASE_EXPORT void AppendJavaStringArrayToStringVector(
    JNIEnv* env,
    jobjectArray array,
    std::vector<std::string>* out);

// Appends the Java bytes in |bytes_array| onto the end of |out|.
BASE_EXPORT void AppendJavaByteArrayToByteVector(
    JNIEnv* env,
    jbyteArray byte_array,
    std::vector<uint8>* out);

// Replaces the content of |out| with the Java bytes in |bytes_array|.
BASE_EXPORT void JavaByteArrayToByteVector(
    JNIEnv* env,
    jbyteArray byte_array,
    std::vector<uint8>* out);

// Replaces the content of |out| with the Java ints in |int_array|.
BASE_EXPORT void JavaIntArrayToIntVector(
    JNIEnv* env,
    jintArray int_array,
    std::vector<int>* out);

// Replaces the content of |out| with the Java longs in |long_array|.
BASE_EXPORT void JavaLongArrayToLongVector(
    JNIEnv* env,
    jlongArray long_array,
    std::vector<jlong>* out);

// Replaces the content of |out| with the Java floats in |float_array|.
BASE_EXPORT void JavaFloatArrayToFloatVector(
    JNIEnv* env,
    jfloatArray float_array,
    std::vector<float>* out);

// Assuming |array| is an byte[][] (array of byte arrays), replaces the
// content of |out| with the corresponding vector of strings. No UTF-8
// conversion is performed.
BASE_EXPORT void JavaArrayOfByteArrayToStringVector(
    JNIEnv* env,
    jobjectArray array,
    std::vector<std::string>* out);

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_JNI_ARRAY_H_
