// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/android/update_service_android.h"

#include "jni/UpdateService_jni.h"

namespace sky {
namespace shell {

static jlong CheckForUpdates(JNIEnv* env, jobject jcaller, jstring j_data_dir) {
  std::string data_dir =
      base::android::ConvertJavaStringToUTF8(env, j_data_dir);
  scoped_ptr<UpdateTask> task(new UpdateTaskAndroid(env, jcaller, data_dir));
  task->Start();
  return reinterpret_cast<jlong>(task.release());
}

bool RegisterUpdateService(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

UpdateTaskAndroid::UpdateTaskAndroid(JNIEnv* env,
                                     jobject update_service,
                                     const std::string& data_dir)
    : UpdateTask(data_dir) {
  update_service_.Reset(env, update_service);
}

UpdateTaskAndroid::~UpdateTaskAndroid() {
}

void UpdateTaskAndroid::Finish() {
  // The Java side is responsible for deleting the UpdateTask when finished.
  Java_UpdateService_onUpdateFinished(base::android::AttachCurrentThread(),
                                      update_service_.obj());
}

void UpdateTaskAndroid::Destroy(JNIEnv* env, jobject jcaller) {
  delete this;
}

}  // namespace shell
}  // namespace sky
