// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/flutter_main.h"

#include <android/log.h>
#include <sys/system_properties.h>
#include <cstring>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "flutter/common/settings.h"
#include "flutter/fml/command_line.h"
#include "flutter/fml/file.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/paths_android.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/android_vm_init.h"
#include "flutter/shell/platform/android/flutter_embedder_native.h"

namespace flutter {

namespace {

// Workaround for crashes in Vivante GL driver on Android.
//
// See:
//   * https://github.com/flutter/flutter/issues/167850
//   * http://crbug.com/141785
#ifdef FML_OS_ANDROID
bool IsVivante() {
  char product_model[PROP_VALUE_MAX];
  __system_property_get("ro.hardware.egl", product_model);
  return strcmp(product_model, "VIVANTE") == 0;
}
#else
bool IsVivante() {
  return false;
}
#endif  // FML_OS_ANDROID

}  // anonymous namespace

FlutterMain::FlutterMain(const flutter::Settings& settings,
                         flutter::AndroidRenderingAPI android_rendering_api,
                         const android::AndroidVMArgs& vm_args,
                         std::shared_ptr<android::AndroidVMInit> vm_init)
    : settings_(settings),
      android_rendering_api_(android_rendering_api),
      vm_args_(vm_args),
      vm_init_(std::move(vm_init)) {
  TRACE_EVENT0("flutter", "FlutterMain::FlutterMain");
}

FlutterMain::~FlutterMain() {
  TRACE_EVENT0("flutter", "FlutterMain::~FlutterMain");
}

static std::unique_ptr<FlutterMain> g_flutter_main;

FlutterMain& FlutterMain::Get() {
  TRACE_EVENT0("flutter", "FlutterMain::Get");
  FML_CHECK(g_flutter_main) << "ensureInitializationComplete must have already "
                               "been called.";
  return *g_flutter_main;
}

const flutter::Settings& FlutterMain::GetSettings() const {
  TRACE_EVENT0("flutter", "FlutterMain::GetSettings");
  return settings_;
}

flutter::AndroidRenderingAPI FlutterMain::GetAndroidRenderingAPI() const {
  TRACE_EVENT0("flutter", "FlutterMain::GetAndroidRenderingAPI");
  return android_rendering_api_;
}

const android::AndroidVMArgs& FlutterMain::GetVMArgs() const {
  TRACE_EVENT0("flutter", "FlutterMain::GetVMArgs");
  return vm_args_;
}

std::shared_ptr<android::AndroidVMInit> FlutterMain::GetVMInit() const {
  TRACE_EVENT0("flutter", "FlutterMain::GetVMInit");
  return vm_init_;
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
  std::vector<std::string> args;
  args.push_back("flutter");
  if (jargs != nullptr) {
    for (auto& arg : fml::jni::StringArrayToVector(env, jargs)) {
      args.push_back(std::move(arg));
    }
  }

  flutter::Settings settings;
  settings.enable_platform_isolates = true;

  if (engineCachesPath != nullptr) {
    fml::paths::InitializeAndroidCachesPath(
        fml::jni::JavaStringToString(env, engineCachesPath));
  }

  if (kernelPath != nullptr) {
    auto application_kernel_path =
        fml::jni::JavaStringToString(env, kernelPath);
    if (fml::IsFile(application_kernel_path)) {
      settings.application_kernel_asset = application_kernel_path;
    }
  }

  settings.log_message_callback = [](const std::string& tag,
                                     const std::string& message) {
    __android_log_print(ANDROID_LOG_INFO, tag.c_str(), "%.*s",
                        static_cast<int>(message.size()), message.c_str());
  };

  // Initialize AndroidVMArgs and parse flags.
  android::AndroidVMArgs vm_args;
  vm_args.command_line_args = args;
  for (const auto& arg : args) {
    if (arg == "--enable-software-rendering") {
      vm_args.enable_software_rendering = true;
    } else if (arg == "--enable-impeller=false" ||
               arg == "--enable-impeller=0") {
      vm_args.enable_impeller = false;
    } else if (arg == "--enable-impeller" || arg == "--enable-impeller=true" ||
               arg == "--enable-impeller=1") {
      vm_args.enable_impeller = true;
    } else if (arg.rfind("--impeller-backend=", 0) == 0) {
      vm_args.requested_rendering_backend =
          arg.substr(std::string("--impeller-backend=").length());
    }
  }
  if (kernelPath != nullptr) {
    vm_args.kernel_path = fml::jni::JavaStringToString(env, kernelPath);
  }
  if (appStoragePath != nullptr) {
    vm_args.app_storage_path =
        fml::jni::JavaStringToString(env, appStoragePath);
  }
  if (engineCachesPath != nullptr) {
    vm_args.engine_caches_path =
        fml::jni::JavaStringToString(env, engineCachesPath);
  }
  vm_args.init_time_millis = initTimeMillis;
  vm_args.api_level = api_level;

  AndroidRenderingAPI android_rendering_api =
      android::SelectRenderingAPI(vm_args, IsVivante());

  settings.enable_impeller =
      (android_rendering_api == AndroidRenderingAPI::kImpellerAutoselect ||
       android_rendering_api == AndroidRenderingAPI::kImpellerOpenGLES ||
       android_rendering_api == AndroidRenderingAPI::kImpellerVulkan);
  settings.enable_software_rendering =
      (android_rendering_api == AndroidRenderingAPI::kSoftware);
  settings.requested_rendering_backend = vm_args.requested_rendering_backend;

  auto vm_init = std::make_shared<android::AndroidVMInit>();
  vm_init->Init(vm_args);

  // Propagate to FlutterEmbedderNative global registry.
  android::FlutterEmbedderNative::SetDefaultVMInit(vm_init);
  android::FlutterEmbedderNative::SetDefaultVMArgs(vm_args);

  g_flutter_main.reset(
      new FlutterMain(settings, android_rendering_api, vm_args, vm_init));
}

static void PrefetchDefaultFontManager(JNIEnv* env, jclass jcaller) {
  TRACE_EVENT0("flutter", "FlutterMain::PrefetchDefaultFontManager");
  android::DefaultFontCollectionProvider font_provider(
      android::FlutterEmbedderNative::GetDefaultLibraryLoader());
  font_provider.PrefetchDefaultFontManager();
}

bool FlutterMain::Register(JNIEnv* env) {
  TRACE_EVENT0("flutter", "FlutterMain::Register");
  static const JNINativeMethod methods[] = {
      {
          .name = "nativeInit",
          .signature = "(Landroid/content/Context;[Ljava/lang/String;Ljava/"
                       "lang/String;Ljava/lang/String;Ljava/lang/String;JI)V",
          .fnPtr = reinterpret_cast<void*>(&Init),
      },
      {
          .name = "nativePrefetchDefaultFontManager",
          .signature = "()V",
          .fnPtr = reinterpret_cast<void*>(&PrefetchDefaultFontManager),
      },
  };

  jclass clazz = env->FindClass("io/flutter/embedding/engine/FlutterJNI");
  if (clazz == nullptr) {
    return false;
  }

  return env->RegisterNatives(clazz, methods, std::size(methods)) == 0;
}

// static
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
  return android::SelectRenderingAPI(args, IsVivante());
}

}  // namespace flutter
