// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jni_router.h"

#include <cstring>
#include <mutex>
#include <string>
#include <vector>

#include "flutter/fml/callback_cache.h"
#include "flutter/fml/logging.h"
#include "flutter/shell/platform/android/flutter_embedder_native.h"
#include "flutter/shell/platform/android/jni_delegate.h"
#include "flutter/shell/platform/android/jvm_invoker.h"

#if __has_include("flutter/shell/platform/android/android_vm_init.h")
#include "flutter/shell/platform/android/android_vm_init.h"
#define FLUTTER_HAS_ANDROID_VM_INIT 1
#else
#define FLUTTER_HAS_ANDROID_VM_INIT 0
#endif

#if __has_include("flutter/shell/platform/android/android_vsync_waiter.h")
#include "flutter/shell/platform/android/android_vsync_waiter.h"
#define FLUTTER_HAS_ANDROID_VSYNC_WAITER 1
#else
#define FLUTTER_HAS_ANDROID_VSYNC_WAITER 0
#endif

namespace flutter {

namespace {

FlutterEmbedderNative* ToEmbedder(jlong handle) {
  return reinterpret_cast<FlutterEmbedderNative*>(handle);
}

std::string JStringToStdString(JNIEnv* env, jstring jstr) {
  if (!env || !jstr) {
    return "";
  }
  const char* chars = env->GetStringUTFChars(jstr, nullptr);
  if (!chars) {
    return "";
  }
  std::string result(chars);
  env->ReleaseStringUTFChars(jstr, chars);
  return result;
}

std::vector<std::string> JStringListToStdVector(JNIEnv* env, jobject jlist) {
  std::vector<std::string> result;
  if (!env || !jlist) {
    return result;
  }
  jclass list_class = env->GetObjectClass(jlist);
  if (!list_class) {
    return result;
  }
  jmethodID size_mid = env->GetMethodID(list_class, "size", "()I");
  jmethodID get_mid =
      env->GetMethodID(list_class, "get", "(I)Ljava/lang/Object;");
  if (size_mid && get_mid) {
    jint size = env->CallIntMethod(jlist, size_mid);
    for (jint i = 0; i < size; ++i) {
      jstring item =
          static_cast<jstring>(env->CallObjectMethod(jlist, get_mid, i));
      if (item) {
        result.push_back(JStringToStdString(env, item));
        env->DeleteLocalRef(item);
      }
    }
  }
  env->DeleteLocalRef(list_class);
  return result;
}

std::vector<std::string> JStringArrayToStdVector(JNIEnv* env,
                                                 jobjectArray jarray) {
  std::vector<std::string> result;
  if (!env || !jarray) {
    return result;
  }
  jsize len = env->GetArrayLength(jarray);
  for (jsize i = 0; i < len; ++i) {
    jstring item = static_cast<jstring>(env->GetObjectArrayElement(jarray, i));
    if (item) {
      result.push_back(JStringToStdString(env, item));
      env->DeleteLocalRef(item);
    }
  }
  return result;
}

std::mutex g_callback_cache_mutex;
std::shared_ptr<CallbackCacheProvider> g_callback_cache_provider;

JNINativeMethod MakeJniMethod(const char* name,
                              const char* signature,
                              void* fn_ptr) {
  return JNINativeMethod{
      .name = const_cast<char*>(name),
      .signature = const_cast<char*>(signature),
      .fnPtr = fn_ptr,
  };
}

const std::vector<JNINativeMethod> kFlutterJniMethods = {
    MakeJniMethod("nativeAttach",
                  "(Lio/flutter/embedding/engine/FlutterJNI;)J",
                  reinterpret_cast<void*>(&JniDelegate::Attach)),
    MakeJniMethod("nativeDestroy",
                  "(J)V",
                  reinterpret_cast<void*>(&JniDelegate::Destroy)),
    MakeJniMethod("nativeSpawn",
                  "(JLjava/lang/String;Ljava/lang/String;Ljava/lang/String;"
                  "Ljava/util/List;J)Lio/flutter/embedding/engine/FlutterJNI;",
                  reinterpret_cast<void*>(&JniDelegate::Spawn)),
    MakeJniMethod(
        "nativeRunBundleAndSnapshotFromLibrary",
        "(JLjava/lang/String;Ljava/lang/String;Ljava/lang/String;"
        "Landroid/content/res/AssetManager;Ljava/util/List;J)V",
        reinterpret_cast<void*>(&JniDelegate::RunBundleAndSnapshotFromLibrary)),
    MakeJniMethod(
        "nativeUpdateJavaAssetManager",
        "(JLandroid/content/res/AssetManager;Ljava/lang/String;)V",
        reinterpret_cast<void*>(&JniDelegate::UpdateJavaAssetManager)),
    MakeJniMethod(
        "nativeLookupCallbackInformation",
        "(J)Lio/flutter/view/FlutterCallbackInformation;",
        reinterpret_cast<void*>(&JniDelegate::LookupCallbackInformation)),
    MakeJniMethod("nativeSurfaceCreated",
                  "(JLandroid/view/Surface;)V",
                  reinterpret_cast<void*>(&JniDelegate::SurfaceCreated)),
    MakeJniMethod("nativeSurfaceWindowChanged",
                  "(JLandroid/view/Surface;)V",
                  reinterpret_cast<void*>(&JniDelegate::SurfaceWindowChanged)),
    MakeJniMethod("nativeSurfaceChanged",
                  "(JII)V",
                  reinterpret_cast<void*>(&JniDelegate::SurfaceChanged)),
    MakeJniMethod("nativeSurfaceDestroyed",
                  "(J)V",
                  reinterpret_cast<void*>(&JniDelegate::SurfaceDestroyed)),
    MakeJniMethod("nativeSetViewportMetrics",
                  "(JFIIIIIIIIIIIIIII[I[I[IIIIIIIII)V",
                  reinterpret_cast<void*>(&JniDelegate::SetViewportMetrics)),
    MakeJniMethod("nativeUpdateDisplayMetrics",
                  "(J)V",
                  reinterpret_cast<void*>(&JniDelegate::UpdateDisplayMetrics)),
    MakeJniMethod(
        "nativeDispatchEmptyPlatformMessage",
        "(JLjava/lang/String;I)V",
        reinterpret_cast<void*>(&JniDelegate::DispatchEmptyPlatformMessage)),
    MakeJniMethod("nativeCleanupMessageData",
                  "(J)V",
                  reinterpret_cast<void*>(&JniDelegate::CleanupMessageData)),
    MakeJniMethod(
        "nativeDispatchPlatformMessage",
        "(JLjava/lang/String;Ljava/nio/ByteBuffer;II)V",
        reinterpret_cast<void*>(&JniDelegate::DispatchPlatformMessage)),
    MakeJniMethod(
        "nativeInvokePlatformMessageEmptyResponseCallback",
        "(JI)V",
        reinterpret_cast<void*>(
            &JniDelegate::InvokePlatformMessageEmptyResponseCallback)),
    MakeJniMethod("nativeInvokePlatformMessageResponseCallback",
                  "(JILjava/nio/ByteBuffer;I)V",
                  reinterpret_cast<void*>(
                      &JniDelegate::InvokePlatformMessageResponseCallback)),
    MakeJniMethod(
        "nativeDispatchPointerDataPacket",
        "(JLjava/nio/ByteBuffer;I)V",
        reinterpret_cast<void*>(&JniDelegate::DispatchPointerDataPacket)),
    MakeJniMethod(
        "nativeDispatchSemanticsAction",
        "(JIILjava/nio/ByteBuffer;I)V",
        reinterpret_cast<void*>(&JniDelegate::DispatchSemanticsAction)),
    MakeJniMethod("nativeSetSemanticsEnabled",
                  "(JZ)V",
                  reinterpret_cast<void*>(&JniDelegate::SetSemanticsEnabled)),
    MakeJniMethod(
        "nativeSetAccessibilityFeatures",
        "(JI)V",
        reinterpret_cast<void*>(&JniDelegate::SetAccessibilityFeatures)),
    MakeJniMethod("nativeRegisterTexture",
                  "(JJLjava/lang/ref/WeakReference;)V",
                  reinterpret_cast<void*>(&JniDelegate::RegisterTexture)),
    MakeJniMethod("nativeRegisterImageTexture",
                  "(JJLjava/lang/ref/WeakReference;Z)V",
                  reinterpret_cast<void*>(&JniDelegate::RegisterImageTexture)),
    MakeJniMethod(
        "nativeMarkTextureFrameAvailable",
        "(JJ)V",
        reinterpret_cast<void*>(&JniDelegate::MarkTextureFrameAvailable)),
    MakeJniMethod("nativeScheduleFrame",
                  "(J)V",
                  reinterpret_cast<void*>(&JniDelegate::ScheduleFrame)),
    MakeJniMethod("nativeUnregisterTexture",
                  "(JJ)V",
                  reinterpret_cast<void*>(&JniDelegate::UnregisterTexture)),
    MakeJniMethod(
        "nativeNotifyLowMemoryWarning",
        "(J)V",
        reinterpret_cast<void*>(&JniDelegate::NotifyLowMemoryWarning)),
    MakeJniMethod(
        "nativeFlutterTextUtilsIsEmoji",
        "(I)Z",
        reinterpret_cast<void*>(&JniDelegate::FlutterTextUtilsIsEmoji)),
    MakeJniMethod(
        "nativeFlutterTextUtilsIsEmojiModifier",
        "(I)Z",
        reinterpret_cast<void*>(&JniDelegate::FlutterTextUtilsIsEmojiModifier)),
    MakeJniMethod("nativeFlutterTextUtilsIsEmojiModifierBase",
                  "(I)Z",
                  reinterpret_cast<void*>(
                      &JniDelegate::FlutterTextUtilsIsEmojiModifierBase)),
    MakeJniMethod("nativeFlutterTextUtilsIsVariationSelector",
                  "(I)Z",
                  reinterpret_cast<void*>(
                      &JniDelegate::FlutterTextUtilsIsVariationSelector)),
    MakeJniMethod("nativeFlutterTextUtilsIsRegionalIndicator",
                  "(I)Z",
                  reinterpret_cast<void*>(
                      &JniDelegate::FlutterTextUtilsIsRegionalIndicator)),
    MakeJniMethod(
        "nativeLoadDartDeferredLibrary",
        "(JI[Ljava/lang/String;)V",
        reinterpret_cast<void*>(&JniDelegate::LoadDartDeferredLibrary)),
    MakeJniMethod(
        "nativeDeferredComponentInstallFailure",
        "(ILjava/lang/String;Z)V",
        reinterpret_cast<void*>(&JniDelegate::DeferredComponentInstallFailure)),
    MakeJniMethod("nativeInit",
                  "(Landroid/content/Context;[Ljava/lang/String;Ljava/lang/"
                  "String;Ljava/lang/String;Ljava/lang/String;JI)V",
                  reinterpret_cast<void*>(&JniDelegate::Init)),
    MakeJniMethod(
        "nativePrefetchDefaultFontManager",
        "()V",
        reinterpret_cast<void*>(&JniDelegate::PrefetchDefaultFontManager)),
    MakeJniMethod(
        "nativeGetIsSoftwareRenderingEnabled",
        "()Z",
        reinterpret_cast<void*>(&JniDelegate::GetIsSoftwareRenderingEnabled)),
    MakeJniMethod("nativeOnVsync",
                  "(JJJ)V",
                  reinterpret_cast<void*>(&JniDelegate::OnVsync)),
    MakeJniMethod("nativeUpdateRefreshRate",
                  "(F)V",
                  reinterpret_cast<void*>(&JniDelegate::UpdateRefreshRate)),
    MakeJniMethod(
        "nativeIsSurfaceControlEnabled",
        "(J)Z",
        reinterpret_cast<void*>(&JniDelegate::IsSurfaceControlEnabled)),
    MakeJniMethod("nativeImageHeaderCallback",
                  "(JII)V",
                  reinterpret_cast<void*>(&JniDelegate::ImageHeaderCallback)),
    MakeJniMethod("nativeShouldDisableAHB",
                  "()Z",
                  reinterpret_cast<void*>(&JniDelegate::ShouldDisableAHB)),
};

}  // namespace

// CallbackCacheProvider implementations.
void DefaultCallbackCacheProvider::SetCachePath(const std::string& path) {
  fml::CallbackCache::SetCachePath(path);
}

void DefaultCallbackCacheProvider::LoadCacheFromDisk() {
  fml::CallbackCache::LoadCacheFromDisk();
}

std::unique_ptr<CallbackCacheProvider::CallbackInfo>
DefaultCallbackCacheProvider::LookupCallbackInformation(int64_t handle) {
  auto info = fml::CallbackCache::GetCallbackInformation(handle);
  if (!info) {
    return nullptr;
  }
  auto result = std::make_unique<CallbackInfo>();
  result->name = info->name;
  result->class_name = info->class_name;
  result->library_path = info->library_path;
  return result;
}

void InMemoryCallbackCacheProvider::SetCachePath(const std::string& path) {
  cache_path_ = path;
}

void InMemoryCallbackCacheProvider::LoadCacheFromDisk() {
  loaded_from_disk_ = true;
}

std::unique_ptr<CallbackCacheProvider::CallbackInfo>
InMemoryCallbackCacheProvider::LookupCallbackInformation(int64_t handle) {
  auto it = callbacks_.find(handle);
  if (it == callbacks_.end()) {
    return nullptr;
  }
  return std::make_unique<CallbackInfo>(it->second);
}

void InMemoryCallbackCacheProvider::RegisterCallback(
    int64_t handle,
    const std::string& name,
    const std::string& class_name,
    const std::string& library_path) {
  callbacks_[handle] = CallbackInfo{name, class_name, library_path};
}

// JniDelegate implementations.
void JniDelegate::SetCallbackCacheProvider(
    std::shared_ptr<CallbackCacheProvider> provider) {
  std::lock_guard<std::mutex> lock(g_callback_cache_mutex);
  g_callback_cache_provider = std::move(provider);
}

std::shared_ptr<CallbackCacheProvider> JniDelegate::GetCallbackCacheProvider() {
  std::lock_guard<std::mutex> lock(g_callback_cache_mutex);
  if (!g_callback_cache_provider) {
    g_callback_cache_provider =
        std::make_shared<DefaultCallbackCacheProvider>();
  }
  return g_callback_cache_provider;
}

jboolean JniDelegate::GetIsSoftwareRenderingEnabled(JNIEnv* env,
                                                    jobject jcaller) {
#if FLUTTER_HAS_ANDROID_VM_INIT
  return AndroidVmInit::GetIsSoftwareRenderingEnabled() ? JNI_TRUE : JNI_FALSE;
#else
  return JNI_FALSE;
#endif
}

jlong JniDelegate::Attach(JNIEnv* env, jobject jcaller, jobject flutter_jni) {
  auto* embedder = new FlutterEmbedderNative();
  jobject target_jni = flutter_jni != nullptr ? flutter_jni : jcaller;
  if (!embedder->Attach(env, target_jni)) {
    delete embedder;
    return 0;
  }
  return reinterpret_cast<jlong>(embedder);
}

void JniDelegate::Destroy(JNIEnv* env, jobject jcaller, jlong shell_holder) {
  auto* embedder = ToEmbedder(shell_holder);
  delete embedder;
}

jobject JniDelegate::Spawn(JNIEnv* env,
                           jobject jcaller,
                           jlong shell_holder,
                           jstring jEntrypoint,
                           jstring jLibraryUrl,
                           jstring jInitialRoute,
                           jobject jEntrypointArgs,
                           jlong engine_id) {
  auto* parent = ToEmbedder(shell_holder);
  if (!parent) {
    return nullptr;
  }
  std::string entrypoint = JStringToStdString(env, jEntrypoint);
  std::string library_url = JStringToStdString(env, jLibraryUrl);
  std::string initial_route = JStringToStdString(env, jInitialRoute);
  std::vector<std::string> args = JStringListToStdVector(env, jEntrypointArgs);

  jobject new_flutter_jni = nullptr;
  jfieldID shell_holder_fid = nullptr;
  if (env != nullptr) {
    jclass flutter_jni_cls =
        env->FindClass("io/flutter/embedding/engine/FlutterJNI");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      flutter_jni_cls = nullptr;
    }
    if (flutter_jni_cls != nullptr) {
      jmethodID ctor = env->GetMethodID(flutter_jni_cls, "<init>", "()V");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        ctor = nullptr;
      }
      shell_holder_fid =
          env->GetFieldID(flutter_jni_cls, "nativeShellHolderId", "J");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        shell_holder_fid = nullptr;
      }
      if (ctor != nullptr) {
        new_flutter_jni = env->NewObject(flutter_jni_cls, ctor);
        if (env->ExceptionCheck()) {
          env->ExceptionClear();
          new_flutter_jni = nullptr;
        }
      }
      env->DeleteLocalRef(flutter_jni_cls);
    }
  }

  auto child = parent->Spawn(
      env, new_flutter_jni != nullptr ? new_flutter_jni : jcaller, entrypoint,
      library_url, initial_route, args, static_cast<int64_t>(engine_id));
  if (!child) {
    if (new_flutter_jni != nullptr && env != nullptr) {
      env->DeleteLocalRef(new_flutter_jni);
    }
    return nullptr;
  }

  jlong child_handle = reinterpret_cast<jlong>(child.release());
  if (new_flutter_jni != nullptr && shell_holder_fid != nullptr &&
      env != nullptr) {
    env->SetLongField(new_flutter_jni, shell_holder_fid, child_handle);
    return new_flutter_jni;
  }
  return reinterpret_cast<jobject>(child_handle);
}

void JniDelegate::RunBundleAndSnapshotFromLibrary(JNIEnv* env,
                                                  jobject jcaller,
                                                  jlong shell_holder,
                                                  jstring jBundlePath,
                                                  jstring jEntrypoint,
                                                  jstring jLibraryUrl,
                                                  jobject jAssetManager,
                                                  jobject jEntrypointArgs,
                                                  jlong engine_id) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  std::string bundle_path = JStringToStdString(env, jBundlePath);
  std::string entrypoint = JStringToStdString(env, jEntrypoint);
  std::string library_url = JStringToStdString(env, jLibraryUrl);
  std::vector<std::string> args = JStringListToStdVector(env, jEntrypointArgs);

  embedder->RunBundleAndSnapshotFromLibrary(env, bundle_path, entrypoint,
                                            library_url, jAssetManager, args,
                                            static_cast<int64_t>(engine_id));
}

void JniDelegate::UpdateJavaAssetManager(JNIEnv* env,
                                         jobject jcaller,
                                         jlong shell_holder,
                                         jobject jAssetManager,
                                         jstring jAssetBundlePath) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  std::string bundle_path = JStringToStdString(env, jAssetBundlePath);
  embedder->UpdateJavaAssetManager(env, jAssetManager, bundle_path);
}

jobject JniDelegate::LookupCallbackInformation(JNIEnv* env,
                                               jclass clazz,
                                               jlong handle) {
  if (!env) {
    return nullptr;
  }
  auto provider = GetCallbackCacheProvider();
  auto info = provider->LookupCallbackInformation(static_cast<int64_t>(handle));
  if (!info) {
    return nullptr;
  }

  jclass info_class =
      env->FindClass("io/flutter/view/FlutterCallbackInformation");
  if (!info_class) {
    return nullptr;
  }
  jmethodID constructor = env->GetMethodID(
      info_class, "<init>",
      "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
  if (!constructor) {
    env->DeleteLocalRef(info_class);
    return nullptr;
  }

  jstring name_str = env->NewStringUTF(info->name.c_str());
  jstring class_str = env->NewStringUTF(info->class_name.c_str());
  jstring lib_str = env->NewStringUTF(info->library_path.c_str());

  jobject result =
      env->NewObject(info_class, constructor, name_str, class_str, lib_str);

  if (name_str) {
    env->DeleteLocalRef(name_str);
  }
  if (class_str) {
    env->DeleteLocalRef(class_str);
  }
  if (lib_str) {
    env->DeleteLocalRef(lib_str);
  }
  env->DeleteLocalRef(info_class);
  return result;
}

void JniDelegate::SurfaceCreated(JNIEnv* env,
                                 jobject jcaller,
                                 jlong shell_holder,
                                 jobject jsurface) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->SurfaceCreated(env, jsurface);
}

void JniDelegate::SurfaceWindowChanged(JNIEnv* env,
                                       jobject jcaller,
                                       jlong shell_holder,
                                       jobject jsurface) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->SurfaceWindowChanged(env, jsurface);
}

void JniDelegate::SurfaceChanged(JNIEnv* env,
                                 jobject jcaller,
                                 jlong shell_holder,
                                 jint width,
                                 jint height) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->SurfaceChanged(static_cast<size_t>(width),
                           static_cast<size_t>(height));
}

void JniDelegate::SurfaceDestroyed(JNIEnv* env,
                                   jobject jcaller,
                                   jlong shell_holder) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->SurfaceDestroyed();
}

void JniDelegate::SetViewportMetrics(
    JNIEnv* env,
    jobject jcaller,
    jlong shell_holder,
    jfloat devicePixelRatio,
    jint physicalWidth,
    jint physicalHeight,
    jint physicalPaddingTop,
    jint physicalPaddingRight,
    jint physicalPaddingBottom,
    jint physicalPaddingLeft,
    jint physicalViewInsetTop,
    jint physicalViewInsetRight,
    jint physicalViewInsetBottom,
    jint physicalViewInsetLeft,
    jint systemGestureInsetTop,
    jint systemGestureInsetRight,
    jint systemGestureInsetBottom,
    jint systemGestureInsetLeft,
    jint physicalTouchSlop,
    jintArray displayFeaturesBounds,
    jintArray displayFeaturesType,
    jintArray displayFeaturesState,
    jint minWidth,
    jint maxWidth,
    jint minHeight,
    jint maxHeight,
    jint physicalDisplayCornerRadiusTopLeft,
    jint physicalDisplayCornerRadiusTopRight,
    jint physicalDisplayCornerRadiusBottomRight,
    jint physicalDisplayCornerRadiusBottomLeft) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }

  std::vector<int32_t> bounds;
  std::vector<int32_t> types;
  std::vector<int32_t> states;

  if (env && displayFeaturesBounds) {
    jsize len = env->GetArrayLength(displayFeaturesBounds);
    bounds.resize(len);
    env->GetIntArrayRegion(displayFeaturesBounds, 0, len, bounds.data());
  }
  if (env && displayFeaturesType) {
    jsize len = env->GetArrayLength(displayFeaturesType);
    types.resize(len);
    env->GetIntArrayRegion(displayFeaturesType, 0, len, types.data());
  }
  if (env && displayFeaturesState) {
    jsize len = env->GetArrayLength(displayFeaturesState);
    states.resize(len);
    env->GetIntArrayRegion(displayFeaturesState, 0, len, states.data());
  }

  // Primary display ID on Android single-display viewport metrics.
  constexpr int32_t kDefaultDisplayId = 0;
  embedder->SetViewportMetrics(
      devicePixelRatio, physicalWidth, physicalHeight, physicalPaddingTop,
      physicalPaddingRight, physicalPaddingBottom, physicalPaddingLeft,
      physicalViewInsetTop, physicalViewInsetRight, physicalViewInsetBottom,
      physicalViewInsetLeft, systemGestureInsetTop, systemGestureInsetRight,
      systemGestureInsetBottom, systemGestureInsetLeft, physicalTouchSlop,
      bounds, types, states, kDefaultDisplayId, minWidth, maxWidth, minHeight,
      maxHeight, physicalDisplayCornerRadiusTopLeft,
      physicalDisplayCornerRadiusTopRight,
      physicalDisplayCornerRadiusBottomRight,
      physicalDisplayCornerRadiusBottomLeft);
}

void JniDelegate::UpdateDisplayMetrics(JNIEnv* env,
                                       jobject jcaller,
                                       jlong shell_holder) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->UpdateDisplayMetrics(env);
}

void JniDelegate::DispatchEmptyPlatformMessage(JNIEnv* env,
                                               jobject jcaller,
                                               jlong shell_holder,
                                               jstring channel,
                                               jint response_id) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  std::string channel_str = JStringToStdString(env, channel);
  embedder->DispatchEmptyPlatformMessage(channel_str, response_id);
}

void JniDelegate::DispatchPlatformMessage(JNIEnv* env,
                                          jobject jcaller,
                                          jlong shell_holder,
                                          jstring channel,
                                          jobject message,
                                          jint position,
                                          jint response_id) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  std::string channel_str = JStringToStdString(env, channel);
  static constexpr uint8_t kEmptyByte = 0;
  const uint8_t* data = nullptr;
  if (env && message) {
    data = static_cast<const uint8_t*>(env->GetDirectBufferAddress(message));
    if (data == nullptr && position == 0) {
      data = &kEmptyByte;
    }
  }
  embedder->DispatchPlatformMessage(channel_str, data,
                                    static_cast<size_t>(position), response_id);
}

void JniDelegate::InvokePlatformMessageEmptyResponseCallback(JNIEnv* env,
                                                             jobject jcaller,
                                                             jlong shell_holder,
                                                             jint response_id) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->InvokePlatformMessageEmptyResponseCallback(response_id);
}

void JniDelegate::InvokePlatformMessageResponseCallback(JNIEnv* env,
                                                        jobject jcaller,
                                                        jlong shell_holder,
                                                        jint response_id,
                                                        jobject message,
                                                        jint position) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  static constexpr uint8_t kEmptyByte = 0;
  const uint8_t* data = nullptr;
  if (env && message) {
    data = static_cast<const uint8_t*>(env->GetDirectBufferAddress(message));
    if (data == nullptr && position == 0) {
      data = &kEmptyByte;
    }
  }
  embedder->InvokePlatformMessageResponseCallback(
      response_id, data, static_cast<size_t>(position));
}

void JniDelegate::DispatchPointerDataPacket(JNIEnv* env,
                                            jobject jcaller,
                                            jlong shell_holder,
                                            jobject buffer,
                                            jint position) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  const uint8_t* data = nullptr;
  if (env && buffer) {
    data = static_cast<const uint8_t*>(env->GetDirectBufferAddress(buffer));
  }
  embedder->DispatchPointerDataPacket(data, static_cast<size_t>(position));
}

void JniDelegate::DispatchSemanticsAction(JNIEnv* env,
                                          jobject jcaller,
                                          jlong shell_holder,
                                          jint id,
                                          jint action,
                                          jobject args,
                                          jint args_position) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  const uint8_t* data = nullptr;
  if (env && args) {
    data = static_cast<const uint8_t*>(env->GetDirectBufferAddress(args));
  }
  embedder->DispatchSemanticsAction(id, action, data,
                                    static_cast<size_t>(args_position));
}

void JniDelegate::SetSemanticsEnabled(JNIEnv* env,
                                      jobject jcaller,
                                      jlong shell_holder,
                                      jboolean enabled) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->SetSemanticsEnabled(enabled == JNI_TRUE);
}

void JniDelegate::SetAccessibilityFeatures(JNIEnv* env,
                                           jobject jcaller,
                                           jlong shell_holder,
                                           jint flags) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->SetAccessibilityFeatures(flags);
}

void JniDelegate::RegisterTexture(JNIEnv* env,
                                  jobject jcaller,
                                  jlong shell_holder,
                                  jlong texture_id,
                                  jobject surface_texture_wrapper) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->RegisterTexture(texture_id, env, surface_texture_wrapper);
}

void JniDelegate::RegisterImageTexture(JNIEnv* env,
                                       jobject jcaller,
                                       jlong shell_holder,
                                       jlong texture_id,
                                       jobject image_texture_entry,
                                       jboolean reset_on_background) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->RegisterImageTexture(texture_id, env, image_texture_entry,
                                 reset_on_background == JNI_TRUE);
}

void JniDelegate::MarkTextureFrameAvailable(JNIEnv* env,
                                            jobject jcaller,
                                            jlong shell_holder,
                                            jlong texture_id) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->MarkTextureFrameAvailable(texture_id);
}

void JniDelegate::ScheduleFrame(JNIEnv* env,
                                jobject jcaller,
                                jlong shell_holder) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->ScheduleFrame();
}

void JniDelegate::UnregisterTexture(JNIEnv* env,
                                    jobject jcaller,
                                    jlong shell_holder,
                                    jlong texture_id) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->UnregisterTexture(texture_id);
}

void JniDelegate::NotifyLowMemoryWarning(JNIEnv* env,
                                         jobject jcaller,
                                         jlong shell_holder) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  embedder->NotifyLowMemoryWarning();
}

void JniDelegate::LoadDartDeferredLibrary(JNIEnv* env,
                                          jobject jcaller,
                                          jlong shell_holder,
                                          jint loading_unit_id,
                                          jobjectArray search_paths) {
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return;
  }
  std::vector<std::string> paths = JStringArrayToStdVector(env, search_paths);
  embedder->LoadDartDeferredLibrary(loading_unit_id, paths);
}

void JniDelegate::DeferredComponentInstallFailure(JNIEnv* env,
                                                  jobject jcaller,
                                                  jint loading_unit_id,
                                                  jstring error,
                                                  jboolean is_transient) {
  std::string error_str = JStringToStdString(env, error);
  auto* active = FlutterEmbedderNative::GetActiveInstance();
  if (active != nullptr) {
    active->NotifyDartDeferredLibraryLoadError(
        static_cast<int32_t>(loading_unit_id), error_str,
        is_transient == JNI_TRUE);
  }
}

void JniDelegate::Init(JNIEnv* env,
                       jclass clazz,
                       jobject context,
                       jobjectArray args,
                       jstring bundle_path,
                       jstring app_storage_path,
                       jstring engine_caches_path,
                       jlong init_time_millis,
                       jint api_level) {
  std::vector<std::string> args_vec = JStringArrayToStdVector(env, args);
  std::string bundle_str = JStringToStdString(env, bundle_path);
  std::string storage_str = JStringToStdString(env, app_storage_path);
  std::string caches_str = JStringToStdString(env, engine_caches_path);

#if FLUTTER_HAS_ANDROID_VM_INIT
  AndroidVmInit::Init(env, clazz, context, args_vec, bundle_str, storage_str,
                      caches_str, static_cast<int64_t>(init_time_millis),
                      static_cast<int>(api_level));
#endif

  auto cache_provider = GetCallbackCacheProvider();
  cache_provider->SetCachePath(storage_str);
  cache_provider->LoadCacheFromDisk();
}

void JniDelegate::PrefetchDefaultFontManager(JNIEnv* env, jclass clazz) {
#if FLUTTER_HAS_ANDROID_VM_INIT
  AndroidVmInit::PrefetchDefaultFontManager();
#endif
}

void JniDelegate::OnVsync(JNIEnv* env,
                          jclass clazz,
                          jlong frame_delay_nanos,
                          jlong refresh_period_nanos,
                          jlong java_baton) {
#if FLUTTER_HAS_ANDROID_VSYNC_WAITER
  AndroidVsyncWaiter::OnNativeVsync(static_cast<int64_t>(frame_delay_nanos),
                                    static_cast<int64_t>(refresh_period_nanos),
                                    static_cast<intptr_t>(java_baton));
#endif
}

void JniDelegate::UpdateRefreshRate(JNIEnv* env,
                                    jclass clazz,
                                    jfloat refresh_rate_fps) {
#if FLUTTER_HAS_ANDROID_VSYNC_WAITER
  AndroidVsyncWaiter::UpdateRefreshRate(refresh_rate_fps);
#endif
}

jboolean JniDelegate::ShouldDisableAHB(JNIEnv* env, jobject jcaller) {
  return JNI_FALSE;
}

void JniDelegate::CleanupMessageData(JNIEnv* env,
                                     jobject jcaller,
                                     jlong message_data) {
  (void)env;
  (void)jcaller;
  if (message_data != 0) {
    std::free(reinterpret_cast<void*>(message_data));
  }
}

jboolean JniDelegate::IsSurfaceControlEnabled(JNIEnv* env,
                                              jobject jcaller,
                                              jlong shell_holder) {
  (void)env;
  (void)jcaller;
  auto* embedder = ToEmbedder(shell_holder);
  if (!embedder) {
    return JNI_FALSE;
  }
  return embedder->IsSurfaceControlEnabled() ? JNI_TRUE : JNI_FALSE;
}

jboolean JniDelegate::FlutterTextUtilsIsEmoji(JNIEnv* env,
                                              jobject jcaller,
                                              jint code_point) {
  (void)env;
  (void)jcaller;
  (void)code_point;
  return JNI_FALSE;
}

jboolean JniDelegate::FlutterTextUtilsIsEmojiModifier(JNIEnv* env,
                                                      jobject jcaller,
                                                      jint code_point) {
  (void)env;
  (void)jcaller;
  (void)code_point;
  return JNI_FALSE;
}

jboolean JniDelegate::FlutterTextUtilsIsEmojiModifierBase(JNIEnv* env,
                                                          jobject jcaller,
                                                          jint code_point) {
  (void)env;
  (void)jcaller;
  (void)code_point;
  return JNI_FALSE;
}

jboolean JniDelegate::FlutterTextUtilsIsVariationSelector(JNIEnv* env,
                                                          jobject jcaller,
                                                          jint code_point) {
  (void)env;
  (void)jcaller;
  (void)code_point;
  return JNI_FALSE;
}

jboolean JniDelegate::FlutterTextUtilsIsRegionalIndicator(JNIEnv* env,
                                                          jobject jcaller,
                                                          jint code_point) {
  (void)env;
  (void)jcaller;
  (void)code_point;
  return JNI_FALSE;
}

void JniDelegate::ImageHeaderCallback(JNIEnv* env,
                                      jclass clazz,
                                      jlong generator_pointer,
                                      jint width,
                                      jint height) {
  (void)env;
  (void)clazz;
  (void)generator_pointer;
  (void)width;
  (void)height;
}

bool JniRouter::RegisterJniMethods(JNIEnv* env) {
  if (env == nullptr) {
    FML_LOG(ERROR) << "RegisterJniMethods called with null JNIEnv.";
    return false;
  }

  jclass flutter_jni_class =
      env->FindClass("io/flutter/embedding/engine/FlutterJNI");
  if (flutter_jni_class == nullptr) {
    FML_LOG(ERROR) << "Could not find FlutterJNI class.";
    return false;
  }

  jint result = env->RegisterNatives(
      flutter_jni_class, kFlutterJniMethods.data(), kFlutterJniMethods.size());
  env->DeleteLocalRef(flutter_jni_class);

  if (result != JNI_OK) {
    FML_LOG(ERROR) << "Failed to register FlutterJNI native methods.";
    return false;
  }

  return JvmInvoker::RegisterMethodIds(env);
}

const std::vector<JNINativeMethod>& JniRouter::GetFlutterJniMethods() {
  return kFlutterJniMethods;
}

const JNINativeMethod* JniRouter::GetNativeMethods(size_t* count_out) {
  if (count_out != nullptr) {
    *count_out = kFlutterJniMethods.size();
  }
  return kFlutterJniMethods.data();
}

}  // namespace flutter
