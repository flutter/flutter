// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_ANDROID_UPDATE_SERVICE_ANDROID_H_
#define SKY_SHELL_ANDROID_UPDATE_SERVICE_ANDROID_H_

#include <jni.h>
#include <memory>

#include "base/android/scoped_java_ref.h"
#include "sky/engine/public/sky/sky_headless.h"

namespace sky {
namespace shell {

class UpdateTaskAndroid : public blink::SkyHeadless::Client {
 public:
  UpdateTaskAndroid(JNIEnv* env, jobject update_service);
  virtual ~UpdateTaskAndroid();

  void Start();

  // This C++ object is owned by the Java UpdateTask. This is called by
  // UpdateTask when it is destroyed.
  void Destroy(JNIEnv* env, jobject jcaller);

 private:
  void RunDartOnUIThread();

  // SkyHeadless::Client:
  void DidCreateIsolate(Dart_Isolate isolate) override;

  std::unique_ptr<blink::SkyHeadless> headless_;
  base::android::ScopedJavaGlobalRef<jobject> update_service_;
};

bool RegisterUpdateService(JNIEnv* env);

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_ANDROID_UPDATE_SERVICE_ANDROID_H_
