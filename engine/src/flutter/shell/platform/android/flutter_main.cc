// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/flutter_main.h"

#include <android/log.h>
#if defined(__ANDROID__)
#include <sys/system_properties.h>
#endif
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

constexpr int kMinimumAndroidApiLevelForImpeller = 29;

namespace {

fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_jni_class = nullptr;

// Workaround for crashes in Vivante GL driver on Android.
//
// See:
//   * https://github.com/flutter/flutter/issues/167850
//   * http://crbug.com/141785
#if defined(__ANDROID__)
bool IsVivante() {
  char product_model[PROP_VALUE_MAX];
  __system_property_get("ro.hardware.egl", product_model);
  return strcmp(product_model, "VIVANTE") == 0;
}
#else
bool IsVivante() {
  return false;
}
#endif  // defined(__ANDROID__)

}  // anonymous namespace

FlutterMain::FlutterMain(const flutter::Settings& settings,
                         flutter::AndroidRenderingAPI android_rendering_api)
    : settings_(settings), android_rendering_api_(android_rendering_api) {
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

flutter::AndroidRenderingAPI FlutterMain::GetAndroidRenderingAPI() {
  TRACE_EVENT0("flutter", "FlutterMain::GetAndroidRenderingAPI");
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

  AndroidRenderingAPI android_rendering_api =
      SelectedRenderingAPI(settings, api_level);

  // Initialize AndroidVMArgs and pass to FlutterEmbedderNative / AndroidVMInit.
  android::AndroidVMArgs vm_args;
  vm_args.command_line_args = args;
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

  g_flutter_main.reset(new FlutterMain(settings, android_rendering_api));
  g_flutter_main->SetupDartVMServiceUriCallback(env);
}

void FlutterMain::SetupDartVMServiceUriCallback(JNIEnv* env) {
  TRACE_EVENT0("flutter", "FlutterMain::SetupDartVMServiceUriCallback");
  if (!g_flutter_jni_class && env) {
    jclass clazz = env->FindClass("io/flutter/embedding/engine/FlutterJNI");
    if (!clazz) {
      return;
    }
    g_flutter_jni_class = new fml::jni::ScopedJavaGlobalRef<jclass>(env, clazz);
  }
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
#if !SLIMPELLER
  if (settings.enable_software_rendering) {
    if (settings.enable_impeller) {
      FML_CHECK(!settings.enable_impeller)
          << "Impeller does not support software rendering. Either disable "
             "software rendering or disable impeller.";
    }
    return AndroidRenderingAPI::kSoftware;
  }

#ifndef FLUTTER_RELEASE
  if (settings.requested_rendering_backend == "opengles" &&
      settings.enable_impeller) {
    return AndroidRenderingAPI::kImpellerOpenGLES;
  }
  if (settings.requested_rendering_backend == "vulkan" &&
      settings.enable_impeller) {
    return AndroidRenderingAPI::kImpellerVulkan;
  }
#endif

  if (settings.enable_impeller &&
      api_level >= kMinimumAndroidApiLevelForImpeller && !IsVivante()) {
    return AndroidRenderingAPI::kImpellerAutoselect;
  }

  return AndroidRenderingAPI::kSkiaOpenGLES;
#else
  return AndroidRenderingAPI::kImpellerAutoselect;
#endif  // !SLIMPELLER
}

}  // namespace flutter
