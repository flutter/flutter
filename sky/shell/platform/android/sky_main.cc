// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/android/sky_main.h"

#include "base/android/jni_android.h"
#include "base/android/jni_array.h"
#include "base/android/jni_string.h"
#include "base/at_exit.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/macros.h"
#include "base/message_loop/message_loop.h"
#include "base/path_service.h"
#include "base/run_loop.h"
#include "base/threading/simple_thread.h"
#include "jni/SkyMain_jni.h"
#include "mojo/edk/embedder/embedder.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "sky/shell/shell.h"
#include "ui/gl/gl_surface.h"

using base::LazyInstance;

namespace sky {
namespace shell {

namespace {

LazyInstance<std::unique_ptr<base::MessageLoop>> g_java_message_loop =
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

void InitializeTracing() {
  base::FilePath path;
  bool result = ::PathService::Get(base::DIR_ANDROID_APP_DATA, &path);
  DCHECK(result);
  sky::shell::Shell::Shared()
      .tracing_controller()
      .set_traces_base_path(path);
}

}  // namespace

static void Init(JNIEnv* env,
                 jclass clazz,
                 jobject context,
                 jobjectArray jargs) {
  base::PlatformThread::SetName("java_ui_thread");
  base::android::ScopedJavaLocalRef<jobject> scoped_context(env, context);
  base::android::InitApplicationContext(env, scoped_context);

  std::vector<std::string> args;
  args.push_back("sky_shell");
  base::android::AppendJavaStringArrayToStringVector(env, jargs, &args);

  base::CommandLine::Init(0, nullptr);
  base::CommandLine::ForCurrentProcess()->InitFromArgv(args);

  InitializeLogging();

  g_java_message_loop.Get().reset(new base::MessageLoopForUI);
  base::MessageLoopForUI::current()->Start();

  mojo::embedder::Init(mojo::embedder::CreateSimplePlatformSupport());

  CHECK(gfx::GLSurface::InitializeOneOff());
  Shell::InitStandalone();

  InitializeTracing();
}

bool RegisterSkyMain(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace sky
}  // namespace mojo
