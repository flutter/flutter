// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/flutter_main.h"

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "flutter/common/settings.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/android_vm_init.h"
#include "flutter/shell/platform/android/flutter_embedder_native.h"

namespace flutter {

FlutterMain::FlutterMain(const flutter::Settings& settings,
                         flutter::AndroidRenderingAPI android_rendering_api)
    : settings_(settings), android_rendering_api_(android_rendering_api) {}

FlutterMain::~FlutterMain() = default;

static std::unique_ptr<FlutterMain> g_flutter_main;

FlutterMain& FlutterMain::Get() {
  FML_CHECK(g_flutter_main) << "ensureInitializationComplete must have already "
                               "been called.";
  return *g_flutter_main;
}

const flutter::Settings& FlutterMain::GetSettings() const {
  return settings_;
}

flutter::AndroidRenderingAPI FlutterMain::GetAndroidRenderingAPI() const {
  return android_rendering_api_;
}

void FlutterMain::Init(JNIEnv* env,
                       jclass clazz,
                       jobject context,
                       jobjectArray jargs,
                       jstring kernelPath,
                       jstring appStoragePath,
                       jstring engineCachesPath,
                       jlong initTimeMillis,
                       jint api_level) {
  TRACE_EVENT0("flutter", "FlutterMain::Init");
  std::vector<std::string> raw_args = fml::jni::StringArrayToVector(env, jargs);
  std::string kernel_path_str =
      kernelPath ? fml::jni::JavaStringToString(env, kernelPath) : "";
  std::string app_storage_path_str =
      appStoragePath ? fml::jni::JavaStringToString(env, appStoragePath) : "";
  std::string engine_caches_path_str =
      engineCachesPath ? fml::jni::JavaStringToString(env, engineCachesPath)
                       : "";

  android::AndroidVMInit::Init(env, clazz, context, raw_args, kernel_path_str,
                               app_storage_path_str, engine_caches_path_str,
                               static_cast<int64_t>(initTimeMillis),
                               static_cast<int>(api_level));

  Settings settings;
  auto vm_args = android::AndroidVMInit::GetGlobalVMArgs().value_or(
      android::AndroidVMArgs{});
  settings.enable_impeller = vm_args.enable_impeller;
  settings.enable_software_rendering = vm_args.enable_software_rendering;
  if (!vm_args.requested_rendering_backend.empty()) {
    settings.requested_rendering_backend = vm_args.requested_rendering_backend;
  }
  settings.trace_systrace = vm_args.trace_systrace;
  settings.enable_surface_control = vm_args.enable_surface_control;
  settings.enable_wide_gamut = vm_args.enable_wide_gamut;
  settings.old_gen_heap_size = vm_args.dart_old_gen_heap_size;
  settings.log_tag = vm_args.log_tag;

  AndroidRenderingAPI android_rendering_api =
      SelectedRenderingAPI(settings, api_level);
  g_flutter_main.reset(new FlutterMain(settings, android_rendering_api));
}

bool FlutterMain::Register(JNIEnv* env) {
  TRACE_EVENT0("flutter", "FlutterMain::Register");
  return FlutterEmbedderNative::RegisterJni(env);
}

AndroidRenderingAPI FlutterMain::SelectedRenderingAPI(
    const flutter::Settings& settings,
    int api_level) {
  TRACE_EVENT0("flutter", "FlutterMain::SelectedRenderingAPI");
  android::AndroidVMArgs args;
  args.enable_impeller = settings.enable_impeller;
  args.enable_software_rendering = settings.enable_software_rendering;
  args.requested_rendering_backend =
      settings.requested_rendering_backend.value_or("");
  args.api_level = api_level;
  return android::SelectRenderingAPI(args);
}

}  // namespace flutter
