// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/flutter_main.h"

#include <vector>

#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/runtime/start_up.h"
#include "flutter/shell/common/shell.h"
#include "lib/fxl/arraysize.h"
#include "lib/fxl/command_line.h"
#include "lib/fxl/macros.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"

namespace shell {

static void Init(JNIEnv* env,
                 jclass clazz,
                 jobject context,
                 jobjectArray jargs) {
  // Prepare command line arguments and initialize the shell.
  std::vector<std::string> args;
  args.push_back("flutter_tester");
  for (auto& arg : fml::jni::StringArrayToVector(env, jargs)) {
    args.push_back(std::move(arg));
  }

  auto command_line = fxl::CommandLineFromIterators(args.begin(), args.end());
  std::string icu_data_path =
      command_line.GetOptionValueWithDefault("icu-data-file-path", "");
  Shell::InitStandalone(std::move(command_line), std::move(icu_data_path));
}

static void RecordStartTimestamp(JNIEnv* env,
                                 jclass jcaller,
                                 jlong initTimeMillis) {
  int64_t initTimeMicros =
      static_cast<int64_t>(initTimeMillis) * static_cast<int64_t>(1000);
  blink::engine_main_enter_ts = Dart_TimelineGetMicros() - initTimeMicros;
}

bool RegisterFlutterMain(JNIEnv* env) {
  static const JNINativeMethod methods[] = {
      {
          .name = "nativeInit",
          .signature = "(Landroid/content/Context;[Ljava/lang/String;)V",
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
