// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/android/javatests/validation_test_util.h"

#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/android/scoped_java_ref.h"
#include "base/test/test_support_android.h"
#include "jni/ValidationTestUtil_jni.h"
#include "mojo/public/cpp/bindings/tests/validation_test_input_parser.h"

namespace mojo {
namespace android {

bool RegisterValidationTestUtil(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

jobject ParseData(JNIEnv* env, jclass jcaller, jstring data_as_string) {
  std::string input =
      base::android::ConvertJavaStringToUTF8(env, data_as_string);
  std::vector<uint8_t> data;
  size_t num_handles;
  std::string error_message;
  if (!test::ParseValidationTestInput(
          input, &data, &num_handles, &error_message)) {
    ScopedJavaLocalRef<jstring> j_error_message =
        base::android::ConvertUTF8ToJavaString(env, error_message);
    return Java_ValidationTestUtil_buildData(
               env, NULL, 0, j_error_message.obj()).Release();
  }
  void* data_ptr = &data[0];
  if (!data_ptr) {
    DCHECK(!data.size());
    data_ptr = &data;
  }
  jobject byte_buffer =
      env->NewDirectByteBuffer(data_ptr, data.size());
  return Java_ValidationTestUtil_buildData(env, byte_buffer, num_handles, NULL)
      .Release();
}

}  // namespace android
}  // namespace mojo
