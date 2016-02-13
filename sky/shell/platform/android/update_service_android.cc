// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/android/update_service_android.h"

#include "base/logging.h"
#include "base/task_runner_util.h"
#include "jni/UpdateService_jni.h"
#include "sky/engine/bindings/mojo_services.h"
#include "sky/engine/public/sky/sky_headless.h"
#include "sky/shell/shell.h"

namespace sky {
namespace shell {

static jlong CheckForUpdates(JNIEnv* env, jobject jcaller) {
  std::unique_ptr<UpdateTaskAndroid> task(new UpdateTaskAndroid(env, jcaller));
  task->Start();
  return reinterpret_cast<jlong>(task.release());
}

bool RegisterUpdateService(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

UpdateTaskAndroid::UpdateTaskAndroid(JNIEnv* env, jobject update_service)
    : headless_(new blink::SkyHeadless(this)) {
  update_service_.Reset(env, update_service);
}

UpdateTaskAndroid::~UpdateTaskAndroid() {
}

void UpdateTaskAndroid::Start() {
  Shell::Shared().ui_task_runner()->PostTask(
      FROM_HERE, base::Bind(&UpdateTaskAndroid::RunDartOnUIThread,
                            base::Unretained(this)));
}

void UpdateTaskAndroid::DidCreateIsolate(Dart_Isolate isolate) {
  blink::MojoServices::Create(isolate, nullptr, nullptr);
}

void UpdateTaskAndroid::RunDartOnUIThread() {
  headless_->Init("sky:updater");
  // TODO(abarth): Run updater from FLX.
}

void UpdateTaskAndroid::Destroy(JNIEnv* env, jobject jcaller) {
  Shell::Shared().ui_task_runner()->DeleteSoon(FROM_HERE, headless_.release());
  delete this;
}

}  // namespace shell
}  // namespace sky
