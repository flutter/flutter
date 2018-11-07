// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_message_response_android.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/shell/platform/android/platform_view_android_jni.h"

namespace shell {

PlatformMessageResponseAndroid::PlatformMessageResponseAndroid(
    int response_id,
    fml::jni::JavaObjectWeakGlobalRef weak_java_object,
    fml::RefPtr<fml::TaskRunner> platform_task_runner)
    : response_id_(response_id),
      weak_java_object_(weak_java_object),
      platform_task_runner_(std::move(platform_task_runner)) {}

// |blink::PlatformMessageResponse|
void PlatformMessageResponseAndroid::Complete(
    std::unique_ptr<fml::Mapping> data) {
  platform_task_runner_->PostTask(
      fml::MakeCopyable([response = response_id_,               //
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

        // Convert the vector to a Java byte array.
        fml::jni::ScopedJavaLocalRef<jbyteArray> data_array(
            env, env->NewByteArray(data->GetSize()));
        env->SetByteArrayRegion(
            data_array.obj(), 0, data->GetSize(),
            reinterpret_cast<const jbyte*>(data->GetMapping()));

        // Make the response call into Java.
        FlutterViewHandlePlatformMessageResponse(env, java_object.obj(),
                                                 response, data_array.obj());
      }));
}

// |blink::PlatformMessageResponse|
void PlatformMessageResponseAndroid::CompleteEmpty() {
  platform_task_runner_->PostTask(
      fml::MakeCopyable([response = response_id_,              //
                         weak_java_object = weak_java_object_  //
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
        // Make the response call into Java.
        FlutterViewHandlePlatformMessageResponse(env, java_object.obj(),
                                                 response, nullptr);
      }));
}
}  // namespace shell
