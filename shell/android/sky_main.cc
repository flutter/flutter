// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/android/sky_main.h"

#include "base/android/jni_android.h"
#include "base/android/jni_array.h"
#include "base/android/jni_string.h"
#include "base/at_exit.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/i18n/icu_util.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/macros.h"
#include "base/message_loop/message_loop.h"
#include "base/run_loop.h"
#include "base/threading/simple_thread.h"
#include "jni/SkyMain_jni.h"
#include "sky/shell/service_provider.h"
#include "sky/shell/shell.h"
#include "ui/gl/gl_surface_egl.h"

using base::LazyInstance;

namespace sky {
namespace shell {

namespace {

LazyInstance<scoped_ptr<base::MessageLoop>> g_java_message_loop =
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

static void Init(JNIEnv* env, jclass clazz, jobject context) {
  base::android::ScopedJavaLocalRef<jobject> scoped_context(env, context);
  base::android::InitApplicationContext(env, scoped_context);

  base::CommandLine::Init(0, nullptr);
  InitializeLogging();

  g_java_message_loop.Get().reset(new base::MessageLoopForUI);
  base::MessageLoopForUI::current()->Start();

  base::i18n::InitializeICU();
  gfx::GLSurface::InitializeOneOff();

  Shell::Init(make_scoped_ptr(new ServiceProviderContext(
      g_java_message_loop.Get()->task_runner())));
}

bool RegisterSkyMain(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace sky
}  // namespace mojo
