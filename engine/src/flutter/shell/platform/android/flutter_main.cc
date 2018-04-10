// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/flutter_main.h"

#include <vector>

#include "flutter/fml/message_loop.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/runtime/start_up.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "lib/fxl/arraysize.h"
#include "lib/fxl/command_line.h"
#include "lib/fxl/files/file.h"
#include "lib/fxl/macros.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"

namespace shell {

FlutterMain::FlutterMain(blink::Settings settings)
    : settings_(std::move(settings)) {}

FlutterMain::~FlutterMain() = default;

static std::unique_ptr<FlutterMain> g_flutter_main;

FlutterMain& FlutterMain::Get() {
  FXL_CHECK(g_flutter_main) << "ensureInitializationComplete must have already "
                               "been called.";
  return *g_flutter_main;
}

const blink::Settings& FlutterMain::GetSettings() const {
  return settings_;
}

void FlutterMain::Init(JNIEnv* env,
                       jclass clazz,
                       jobject context,
                       jobjectArray jargs,
                       jstring bundlePath) {
  std::vector<std::string> args;
  args.push_back("flutter");
  for (auto& arg : fml::jni::StringArrayToVector(env, jargs)) {
    args.push_back(std::move(arg));
  }
  auto command_line = fxl::CommandLineFromIterators(args.begin(), args.end());

  auto settings = SettingsFromCommandLine(command_line);

  settings.assets_path = fml::jni::JavaStringToString(env, bundlePath);

  if (!blink::DartVM::IsRunningPrecompiledCode()) {
    // Check to see if the appropriate kernel files are present and configure
    // settings accordingly.
    auto platform_kernel_path =
        fml::paths::JoinPaths({settings.assets_path, "platform.dill"});
    auto application_kernel_path =
        fml::paths::JoinPaths({settings.assets_path, "kernel_blob.bin"});

    if (files::IsFile(platform_kernel_path) &&
        files::IsFile(application_kernel_path)) {
      settings.kernel_snapshot_path = platform_kernel_path;
      settings.application_kernel_asset = application_kernel_path;
    }
  }

  settings.task_observer_add = [](intptr_t key, fxl::Closure callback) {
    fml::MessageLoop::GetCurrent().AddTaskObserver(key, std::move(callback));
  };

  settings.task_observer_remove = [](intptr_t key) {
    fml::MessageLoop::GetCurrent().RemoveTaskObserver(key);
  };
  // Not thread safe. Will be removed when FlutterMain is refactored to no
  // longer be a singleton.
  g_flutter_main.reset(new FlutterMain(std::move(settings)));
}

static void RecordStartTimestamp(JNIEnv* env,
                                 jclass jcaller,
                                 jlong initTimeMillis) {
  int64_t initTimeMicros =
      static_cast<int64_t>(initTimeMillis) * static_cast<int64_t>(1000);
  blink::engine_main_enter_ts = Dart_TimelineGetMicros() - initTimeMicros;
}

bool FlutterMain::Register(JNIEnv* env) {
  static const JNINativeMethod methods[] = {
      {
          .name = "nativeInit",
          .signature = "(Landroid/content/Context;[Ljava/lang/String;Ljava/"
                       "lang/String;)V",
          .fnPtr = reinterpret_cast<void*>(&Init),
      },
      {
          .name = "nativeRecordStartTimestamp",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&RecordStartTimestamp),
      },
  };

  jclass clazz = env->FindClass("io/flutter/view/FlutterMain");

  if (clazz == nullptr) {
    return false;
  }

  return env->RegisterNatives(clazz, methods, arraysize(methods)) == 0;
}

}  // namespace shell
