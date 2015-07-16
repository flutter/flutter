// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/test_file_util.h"

#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/files/file_path.h"
#include "jni/ContentUriTestUtils_jni.h"

namespace base {

bool RegisterContentUriTestUtils(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

FilePath InsertImageIntoMediaStore(const FilePath& path) {
  JNIEnv* env = base::android::AttachCurrentThread();
  ScopedJavaLocalRef<jstring> j_path =
      base::android::ConvertUTF8ToJavaString(env, path.value());
  ScopedJavaLocalRef<jstring> j_uri =
      Java_ContentUriTestUtils_insertImageIntoMediaStore(
          env, base::android::GetApplicationContext(), j_path.obj());
  std::string uri = base::android::ConvertJavaStringToUTF8(j_uri);
  return FilePath(uri);
}

}  // namespace base
