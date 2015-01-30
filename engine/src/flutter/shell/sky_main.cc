// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/sky_main.h"

#include "base/android/jni_android.h"
#include "base/android/jni_array.h"
#include "base/android/jni_string.h"
#include "base/at_exit.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/macros.h"
#include "base/message_loop/message_loop.h"
#include "base/run_loop.h"
#include "base/threading/simple_thread.h"
#include "jni/SkyMain_jni.h"

using base::LazyInstance;

namespace sky {
namespace shell {

namespace {

LazyInstance<scoped_ptr<base::MessageLoop>> g_java_message_loop =
    LAZY_INSTANCE_INITIALIZER;

LazyInstance<base::android::ScopedJavaGlobalRef<jobject>> g_main_activiy =
    LAZY_INSTANCE_INITIALIZER;

void InitializeLogging() {
  logging::LoggingSettings settings;
  settings.logging_dest = logging::LOG_TO_SYSTEM_DEBUG_LOG;
  logging::InitLogging(settings);
  // To view log output with IDs and timestamps use "adb logcat -v threadtime".
  logging::SetLogItems(false,   // Process ID
                       false,   // Thread ID
                       false,   // Timestamp
                       false);  // Tick count
}

}  // namespace

static void Init(JNIEnv* env,
                 jclass clazz,
                 jobject activity) {
  g_main_activiy.Get().Reset(env, activity);

  base::android::ScopedJavaLocalRef<jobject> scoped_activity(env, activity);
  base::android::InitApplicationContext(env, scoped_activity);

  base::CommandLine::Init(0, nullptr);

  InitializeLogging();

  g_java_message_loop.Get().reset(new base::MessageLoopForUI);
  base::MessageLoopForUI::current()->Start();
}

static jboolean Start(JNIEnv* env, jclass clazz) {
  LOG(INFO) << "Native code started!";
  return true;
}

bool RegisterSkyMain(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace sky
}  // namespace mojo
