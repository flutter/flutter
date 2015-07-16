// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/path_utils.h"

#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/android/scoped_java_ref.h"
#include "base/files/file_path.h"

#include "jni/PathUtils_jni.h"

namespace base {
namespace android {

bool GetDataDirectory(FilePath* result) {
  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jstring> path =
      Java_PathUtils_getDataDirectory(env, GetApplicationContext());
  FilePath data_path(ConvertJavaStringToUTF8(path));
  *result = data_path;
  return true;
}

bool GetDatabaseDirectory(FilePath* result) {
  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jstring> path =
      Java_PathUtils_getDatabaseDirectory(env, GetApplicationContext());
  FilePath data_path(ConvertJavaStringToUTF8(path));
  *result = data_path;
  return true;
}

bool GetCacheDirectory(FilePath* result) {
  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jstring> path =
      Java_PathUtils_getCacheDirectory(env, GetApplicationContext());
  FilePath cache_path(ConvertJavaStringToUTF8(path));
  *result = cache_path;
  return true;
}

bool GetDownloadsDirectory(FilePath* result) {
  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jstring> path =
      Java_PathUtils_getDownloadsDirectory(env, GetApplicationContext());
  FilePath downloads_path(ConvertJavaStringToUTF8(path));
  *result = downloads_path;
  return true;
}

bool GetNativeLibraryDirectory(FilePath* result) {
  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jstring> path =
      Java_PathUtils_getNativeLibraryDirectory(env, GetApplicationContext());
  FilePath library_path(ConvertJavaStringToUTF8(path));
  *result = library_path;
  return true;
}

bool GetExternalStorageDirectory(FilePath* result) {
  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jstring> path =
      Java_PathUtils_getExternalStorageDirectory(env);
  FilePath storage_path(ConvertJavaStringToUTF8(path));
  *result = storage_path;
  return true;
}

bool RegisterPathUtils(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace android
}  // namespace base
