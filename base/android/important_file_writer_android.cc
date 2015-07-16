// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/important_file_writer_android.h"

#include <string>

#include "base/android/jni_string.h"
#include "base/files/important_file_writer.h"
#include "base/threading/thread_restrictions.h"
#include "jni/ImportantFileWriterAndroid_jni.h"

namespace base {
namespace android {

static jboolean WriteFileAtomically(JNIEnv* env,
                                    jclass /* clazz */,
                                    jstring file_name,
                                    jbyteArray data) {
  // This is called on the UI thread during shutdown to save tab data, so
  // needs to enable IO.
  base::ThreadRestrictions::ScopedAllowIO allow_io;
  std::string native_file_name;
  base::android::ConvertJavaStringToUTF8(env, file_name, &native_file_name);
  base::FilePath path(native_file_name);
  int data_length = env->GetArrayLength(data);
  jbyte* native_data = env->GetByteArrayElements(data, NULL);
  std::string native_data_string(reinterpret_cast<char *>(native_data),
                                 data_length);
  bool result = base::ImportantFileWriter::WriteFileAtomically(
      path, native_data_string);
  env->ReleaseByteArrayElements(data, native_data, JNI_ABORT);
  return result;
}

bool RegisterImportantFileWriterAndroid(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace android
}  // namespace base
