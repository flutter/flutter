// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_message_response_android.h"

#include "flutter/shell/platform/android/platform_view_android_jni.h"
#include "lib/fxl/functional/make_copyable.h"

namespace shell {

PlatformMessageResponseAndroid::PlatformMessageResponseAndroid(
    int response_id,
    fml::jni::JavaObjectWeakGlobalRef weak_java_object,
    fxl::RefPtr<fxl::TaskRunner> platform_task_runner)
    : response_id_(response_id),
      weak_java_object_(weak_java_object),
      platform_task_runner_(std::move(platform_task_runner)) {}

// |blink::PlatformMessageResponse|
void PlatformMessageResponseAndroid::Complete(std::vector<uint8_t> data) {
  platform_task_runner_->PostTask(
      fxl::MakeCopyable([response = response_id_,               //
                         weak_java_object = weak_java_object_,  //
                         data = std::move(data)                 //
  ]() {
        // We are on the platform thread. Attempt to get the strong reference to
        // the Java object.
        auto env = fml::jni::AttachCurrentThread();
        auto java_object = weak_java_object.get(env);

        if (java_object.is_null()) {
          // The Java object was collected before this message response got to
          // it. Drop the response on the floor.
          return;
        }

        if (data.size() == 0) {
          // If the data is empty, there is no reason to create a Java byte
          // array. Make the response now with a nullptr now.
          FlutterViewHandlePlatformMessageResponse(env, java_object.obj(),
                                                   response, nullptr);
        }

        // Convert the vector to a Java byte array.
        fml::jni::ScopedJavaLocalRef<jbyteArray> data_array(
            env, env->NewByteArray(data.size()));
        env->SetByteArrayRegion(data_array.obj(), 0, data.size(),
                                reinterpret_cast<const jbyte*>(data.data()));

        // Make the response call into Java.
        FlutterViewHandlePlatformMessageResponse(env, java_object.obj(),
                                                 response, data_array.obj());
      }));
}

// |blink::PlatformMessageResponse|
void PlatformMessageResponseAndroid::CompleteEmpty() {
  Complete(std::vector<uint8_t>{});
}

}  // namespace shell
