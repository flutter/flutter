// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_ANDROID_UPDATE_SERVICE_ANDROID_H_
#define SKY_SHELL_ANDROID_UPDATE_SERVICE_ANDROID_H_

#include <jni.h>

#include "base/android/jni_string.h"
#include "sky/shell/updater/update_task.h"

namespace sky {
namespace shell {

class UpdateTaskAndroid : public UpdateTask {
 public:
  UpdateTaskAndroid(JNIEnv* env,
                    jobject update_service,
                    const std::string& data_dir);
  ~UpdateTaskAndroid();

  void Finish() override;

  // This C++ object is owned by the Java UpdateService. This is called by
  // UpdateService when it is destroyed.
  void Destroy(JNIEnv* env, jobject jcaller);

 private:
  base::android::ScopedJavaGlobalRef<jobject> update_service_;
};

bool RegisterUpdateService(JNIEnv* env);

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_ANDROID_UPDATE_SERVICE_ANDROID_H_
