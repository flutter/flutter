// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/jni_array.h"

#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/logging.h"

namespace base {
namespace android {
namespace {

// As |GetArrayLength| makes no guarantees about the returned value (e.g., it
// may be -1 if |array| is not a valid Java array), provide a safe wrapper
// that always returns a valid, non-negative size.
template <typename JavaArrayType>
size_t SafeGetArrayLength(JNIEnv* env, JavaArrayType jarray) {
  DCHECK(jarray);
  jsize length = env->GetArrayLength(jarray);
  DCHECK_GE(length, 0) << "Invalid array length: " << length;
  return static_cast<size_t>(std::max(0, length));
}

}  // namespace

ScopedJavaLocalRef<jbyteArray> ToJavaByteArray(
    JNIEnv* env, const uint8* bytes, size_t len) {
  jbyteArray byte_array = env->NewByteArray(len);
  CheckException(env);
  DCHECK(byte_array);

  env->SetByteArrayRegion(
      byte_array, 0, len, reinterpret_cast<const jbyte*>(bytes));
  CheckException(env);

  return ScopedJavaLocalRef<jbyteArray>(env, byte_array);
}

ScopedJavaLocalRef<jintArray> ToJavaIntArray(
    JNIEnv* env, const int* ints, size_t len) {
  jintArray int_array = env->NewIntArray(len);
  CheckException(env);
  DCHECK(int_array);

  env->SetIntArrayRegion(
      int_array, 0, len, reinterpret_cast<const jint*>(ints));
  CheckException(env);

  return ScopedJavaLocalRef<jintArray>(env, int_array);
}

ScopedJavaLocalRef<jintArray> ToJavaIntArray(
    JNIEnv* env, const std::vector<int>& ints) {
  return ToJavaIntArray(env, ints.data(), ints.size());
}

ScopedJavaLocalRef<jlongArray> ToJavaLongArray(
    JNIEnv* env, const int64* longs, size_t len) {
  jlongArray long_array = env->NewLongArray(len);
  CheckException(env);
  DCHECK(long_array);

  env->SetLongArrayRegion(
      long_array, 0, len, reinterpret_cast<const jlong*>(longs));
  CheckException(env);

  return ScopedJavaLocalRef<jlongArray>(env, long_array);
}

// Returns a new Java long array converted from the given int64 array.
BASE_EXPORT ScopedJavaLocalRef<jlongArray> ToJavaLongArray(
    JNIEnv* env, const std::vector<int64>& longs) {
  return ToJavaLongArray(env, longs.data(), longs.size());
}

ScopedJavaLocalRef<jobjectArray> ToJavaArrayOfByteArray(
    JNIEnv* env, const std::vector<std::string>& v) {
  ScopedJavaLocalRef<jclass> byte_array_clazz = GetClass(env, "[B");
  jobjectArray joa = env->NewObjectArray(v.size(),
                                         byte_array_clazz.obj(), NULL);
  CheckException(env);

  for (size_t i = 0; i < v.size(); ++i) {
    ScopedJavaLocalRef<jbyteArray> byte_array = ToJavaByteArray(env,
        reinterpret_cast<const uint8*>(v[i].data()), v[i].length());
    env->SetObjectArrayElement(joa, i, byte_array.obj());
  }
  return ScopedJavaLocalRef<jobjectArray>(env, joa);
}

ScopedJavaLocalRef<jobjectArray> ToJavaArrayOfStrings(
    JNIEnv* env, const std::vector<std::string>& v) {
  ScopedJavaLocalRef<jclass> string_clazz = GetClass(env, "java/lang/String");
  jobjectArray joa = env->NewObjectArray(v.size(), string_clazz.obj(), NULL);
  CheckException(env);

  for (size_t i = 0; i < v.size(); ++i) {
    ScopedJavaLocalRef<jstring> item = ConvertUTF8ToJavaString(env, v[i]);
    env->SetObjectArrayElement(joa, i, item.obj());
  }
  return ScopedJavaLocalRef<jobjectArray>(env, joa);
}

ScopedJavaLocalRef<jobjectArray> ToJavaArrayOfStrings(
    JNIEnv* env, const std::vector<string16>& v) {
  ScopedJavaLocalRef<jclass> string_clazz = GetClass(env, "java/lang/String");
  jobjectArray joa = env->NewObjectArray(v.size(), string_clazz.obj(), NULL);
  CheckException(env);

  for (size_t i = 0; i < v.size(); ++i) {
    ScopedJavaLocalRef<jstring> item = ConvertUTF16ToJavaString(env, v[i]);
    env->SetObjectArrayElement(joa, i, item.obj());
  }
  return ScopedJavaLocalRef<jobjectArray>(env, joa);
}

void AppendJavaStringArrayToStringVector(JNIEnv* env,
                                         jobjectArray array,
                                         std::vector<string16>* out) {
  DCHECK(out);
  if (!array)
    return;
  size_t len = SafeGetArrayLength(env, array);
  size_t back = out->size();
  out->resize(back + len);
  for (size_t i = 0; i < len; ++i) {
    ScopedJavaLocalRef<jstring> str(env,
        static_cast<jstring>(env->GetObjectArrayElement(array, i)));
    ConvertJavaStringToUTF16(env, str.obj(), &((*out)[back + i]));
  }
}

void AppendJavaStringArrayToStringVector(JNIEnv* env,
                                         jobjectArray array,
                                         std::vector<std::string>* out) {
  DCHECK(out);
  if (!array)
    return;
  size_t len = SafeGetArrayLength(env, array);
  size_t back = out->size();
  out->resize(back + len);
  for (size_t i = 0; i < len; ++i) {
    ScopedJavaLocalRef<jstring> str(env,
        static_cast<jstring>(env->GetObjectArrayElement(array, i)));
    ConvertJavaStringToUTF8(env, str.obj(), &((*out)[back + i]));
  }
}

void AppendJavaByteArrayToByteVector(JNIEnv* env,
                                     jbyteArray byte_array,
                                     std::vector<uint8>* out) {
  DCHECK(out);
  if (!byte_array)
    return;
  size_t len = SafeGetArrayLength(env, byte_array);
  if (!len)
    return;
  size_t back = out->size();
  out->resize(back + len);
  env->GetByteArrayRegion(byte_array, 0, len,
                          reinterpret_cast<int8*>(&(*out)[back]));
}

void JavaByteArrayToByteVector(JNIEnv* env,
                               jbyteArray byte_array,
                               std::vector<uint8>* out) {
  DCHECK(out);
  DCHECK(byte_array);
  out->clear();
  AppendJavaByteArrayToByteVector(env, byte_array, out);
}

void JavaIntArrayToIntVector(JNIEnv* env,
                             jintArray int_array,
                             std::vector<int>* out) {
  DCHECK(out);
  size_t len = SafeGetArrayLength(env, int_array);
  out->resize(len);
  if (!len)
    return;
  // TODO(jdduke): Use |out->data()| for pointer access after switch to libc++,
  // both here and in the other conversion routines. See crbug.com/427718.
  env->GetIntArrayRegion(int_array, 0, len, &(*out)[0]);
}

void JavaLongArrayToLongVector(JNIEnv* env,
                               jlongArray long_array,
                               std::vector<jlong>* out) {
  DCHECK(out);
  size_t len = SafeGetArrayLength(env, long_array);
  out->resize(len);
  if (!len)
    return;
  env->GetLongArrayRegion(long_array, 0, len, &(*out)[0]);
}

void JavaFloatArrayToFloatVector(JNIEnv* env,
                                 jfloatArray float_array,
                                 std::vector<float>* out) {
  DCHECK(out);
  size_t len = SafeGetArrayLength(env, float_array);
  out->resize(len);
  if (!len)
    return;
  env->GetFloatArrayRegion(float_array, 0, len, &(*out)[0]);
}

void JavaArrayOfByteArrayToStringVector(
    JNIEnv* env,
    jobjectArray array,
    std::vector<std::string>* out) {
  DCHECK(out);
  size_t len = SafeGetArrayLength(env, array);
  out->resize(len);
  for (size_t i = 0; i < len; ++i) {
    ScopedJavaLocalRef<jbyteArray> bytes_array(
        env, static_cast<jbyteArray>(
            env->GetObjectArrayElement(array, i)));
    jsize bytes_len = env->GetArrayLength(bytes_array.obj());
    jbyte* bytes = env->GetByteArrayElements(bytes_array.obj(), NULL);
    (*out)[i].assign(reinterpret_cast<const char*>(bytes), bytes_len);
    env->ReleaseByteArrayElements(bytes_array.obj(), bytes, JNI_ABORT);
  }
}

}  // namespace android
}  // namespace base
