// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android_jni.h"

#include <android/native_window_jni.h>

#include <utility>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/assets/zip_asset_store.h"
#include "flutter/common/settings.h"
#include "flutter/fml/arraysize.h"
#include "flutter/fml/file.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/lib/ui/plugins/callback_cache.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/platform/android/android_external_texture_gl.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "flutter/shell/platform/android/flutter_main.h"

#define ANDROID_SHELL_HOLDER \
  (reinterpret_cast<shell::AndroidShellHolder*>(shell_holder))

namespace shell {

namespace {

bool CheckException(JNIEnv* env) {
  if (env->ExceptionCheck() == JNI_FALSE)
    return true;

  jthrowable exception = env->ExceptionOccurred();
  env->ExceptionClear();
  FML_LOG(ERROR) << fml::jni::GetJavaExceptionInfo(env, exception);
  env->DeleteLocalRef(exception);
  return false;
}

}  // anonymous namespace

static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_callback_info_class =
    nullptr;
static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_view_class = nullptr;
static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_native_view_class =
    nullptr;
static fml::jni::ScopedJavaGlobalRef<jclass>* g_surface_texture_class = nullptr;

// Called By Native

static jmethodID g_flutter_callback_info_constructor = nullptr;
jobject CreateFlutterCallbackInformation(
    JNIEnv* env,
    const std::string& callbackName,
    const std::string& callbackClassName,
    const std::string& callbackLibraryPath) {
  return env->NewObject(g_flutter_callback_info_class->obj(),
                        g_flutter_callback_info_constructor,
                        env->NewStringUTF(callbackName.c_str()),
                        env->NewStringUTF(callbackClassName.c_str()),
                        env->NewStringUTF(callbackLibraryPath.c_str()));
}

static jmethodID g_handle_platform_message_method = nullptr;
void FlutterViewHandlePlatformMessage(JNIEnv* env,
                                      jobject obj,
                                      jstring channel,
                                      jobject message,
                                      jint responseId) {
  env->CallVoidMethod(obj, g_handle_platform_message_method, channel, message,
                      responseId);
  FML_CHECK(CheckException(env));
}

static jmethodID g_handle_platform_message_response_method = nullptr;
void FlutterViewHandlePlatformMessageResponse(JNIEnv* env,
                                              jobject obj,
                                              jint responseId,
                                              jobject response) {
  env->CallVoidMethod(obj, g_handle_platform_message_response_method,
                      responseId, response);
  FML_CHECK(CheckException(env));
}

static jmethodID g_update_semantics_method = nullptr;
void FlutterViewUpdateSemantics(JNIEnv* env,
                                jobject obj,
                                jobject buffer,
                                jobjectArray strings) {
  env->CallVoidMethod(obj, g_update_semantics_method, buffer, strings);
  FML_CHECK(CheckException(env));
}

static jmethodID g_update_custom_accessibility_actions_method = nullptr;
void FlutterViewUpdateCustomAccessibilityActions(JNIEnv* env,
                                                 jobject obj,
                                                 jobject buffer,
                                                 jobjectArray strings) {
  env->CallVoidMethod(obj, g_update_custom_accessibility_actions_method, buffer,
                      strings);
  FML_CHECK(CheckException(env));
}

static jmethodID g_on_first_frame_method = nullptr;
void FlutterViewOnFirstFrame(JNIEnv* env, jobject obj) {
  env->CallVoidMethod(obj, g_on_first_frame_method);
  FML_CHECK(CheckException(env));
}

static jmethodID g_on_engine_restart_method = nullptr;
void FlutterViewOnPreEngineRestart(JNIEnv* env, jobject obj) {
  env->CallVoidMethod(obj, g_on_engine_restart_method);
  FML_CHECK(CheckException(env));
}

static jmethodID g_attach_to_gl_context_method = nullptr;
void SurfaceTextureAttachToGLContext(JNIEnv* env, jobject obj, jint textureId) {
  env->CallVoidMethod(obj, g_attach_to_gl_context_method, textureId);
  FML_CHECK(CheckException(env));
}

static jmethodID g_update_tex_image_method = nullptr;
void SurfaceTextureUpdateTexImage(JNIEnv* env, jobject obj) {
  env->CallVoidMethod(obj, g_update_tex_image_method);
  FML_CHECK(CheckException(env));
}

static jmethodID g_get_transform_matrix_method = nullptr;
void SurfaceTextureGetTransformMatrix(JNIEnv* env,
                                      jobject obj,
                                      jfloatArray result) {
  env->CallVoidMethod(obj, g_get_transform_matrix_method, result);
  FML_CHECK(CheckException(env));
}

static jmethodID g_detach_from_gl_context_method = nullptr;
void SurfaceTextureDetachFromGLContext(JNIEnv* env, jobject obj) {
  env->CallVoidMethod(obj, g_detach_from_gl_context_method);
  FML_CHECK(CheckException(env));
}

// Called By Java

static jlong Attach(JNIEnv* env,
                    jclass clazz,
                    jobject flutterView,
                    jboolean is_background_view) {
  fml::jni::JavaObjectWeakGlobalRef java_object(env, flutterView);
  auto shell_holder = std::make_unique<AndroidShellHolder>(
      FlutterMain::Get().GetSettings(), java_object, is_background_view);
  if (shell_holder->IsValid()) {
    return reinterpret_cast<jlong>(shell_holder.release());
  } else {
    return 0;
  }
}

static void Detach(JNIEnv* env, jobject jcaller, jlong shell_holder) {
  // Nothing to do.
}

static void Destroy(JNIEnv* env, jobject jcaller, jlong shell_holder) {
  delete ANDROID_SHELL_HOLDER;
}

static jstring GetObservatoryUri(JNIEnv* env, jclass clazz) {
  return env->NewStringUTF(
      blink::DartServiceIsolate::GetObservatoryUri().c_str());
}

static void SurfaceCreated(JNIEnv* env,
                           jobject jcaller,
                           jlong shell_holder,
                           jobject jsurface,
                           jint backgroundColor) {
  // Note: This frame ensures that any local references used by
  // ANativeWindow_fromSurface are released immediately. This is needed as a
  // workaround for https://code.google.com/p/android/issues/detail?id=68174
  fml::jni::ScopedJavaLocalFrame scoped_local_reference_frame(env);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      ANativeWindow_fromSurface(env, jsurface));
  ANDROID_SHELL_HOLDER->GetPlatformView()->NotifyCreated(std::move(window));
}

static void SurfaceChanged(JNIEnv* env,
                           jobject jcaller,
                           jlong shell_holder,
                           jint width,
                           jint height) {
  ANDROID_SHELL_HOLDER->GetPlatformView()->NotifyChanged(
      SkISize::Make(width, height));
}

static void SurfaceDestroyed(JNIEnv* env, jobject jcaller, jlong shell_holder) {
  ANDROID_SHELL_HOLDER->GetPlatformView()->NotifyDestroyed();
}

std::unique_ptr<IsolateConfiguration> CreateIsolateConfiguration(
    const blink::AssetManager& asset_manager) {
  if (blink::DartVM::IsRunningPrecompiledCode()) {
    return IsolateConfiguration::CreateForAppSnapshot();
  }

  const auto configuration_from_blob =
      [&asset_manager](const std::string& snapshot_name)
      -> std::unique_ptr<IsolateConfiguration> {
    auto blob = asset_manager.GetAsMapping(snapshot_name);
    auto delta = asset_manager.GetAsMapping("kernel_delta.bin");
    if (blob && delta) {
      std::vector<std::unique_ptr<fml::Mapping>> kernels;
      kernels.emplace_back(std::move(blob));
      kernels.emplace_back(std::move(delta));
      return IsolateConfiguration::CreateForKernelList(std::move(kernels));
    }
    if (blob) {
      return IsolateConfiguration::CreateForSnapshot(std::move(blob));
    }
    if (delta) {
      return IsolateConfiguration::CreateForSnapshot(std::move(delta));
    }
    return nullptr;
  };

  if (auto kernel = configuration_from_blob("kernel_blob.bin")) {
    return kernel;
  }
  if (auto script = configuration_from_blob("snapshot_blob.bin")) {
    return script;
  }

  // This happens when starting isolate directly from CoreJIT snapshot.
  return IsolateConfiguration::CreateForAppSnapshot();
}

static void RunBundleAndSnapshotFromLibrary(JNIEnv* env,
                                            jobject jcaller,
                                            jlong shell_holder,
                                            jstring jbundlepath,
                                            jstring jdefaultPath,
                                            jstring jEntrypoint,
                                            jstring jLibraryUrl,
                                            jobject jAssetManager) {
  auto asset_manager = fml::MakeRefCounted<blink::AssetManager>();

  const auto bundlepath = fml::jni::JavaStringToString(env, jbundlepath);
  if (bundlepath.size() > 0) {
    // If we got a bundle path, attempt to use that as a directory asset
    // bundle or a zip asset bundle.
    const auto file_ext_index = bundlepath.rfind(".");
    if (bundlepath.substr(file_ext_index) == ".zip") {
      asset_manager->PushBack(
          std::make_unique<blink::ZipAssetStore>(bundlepath));
    } else {
      asset_manager->PushBack(std::make_unique<blink::DirectoryAssetBundle>(
          fml::OpenFile(bundlepath.c_str(), fml::OpenPermission::kRead, true)));
    }

    // Use the last path component of the bundle path to determine the
    // directory in the APK assets.
    const auto last_slash_index = bundlepath.rfind("/", bundlepath.size());
    if (last_slash_index != std::string::npos) {
      auto apk_asset_dir = bundlepath.substr(
          last_slash_index + 1, bundlepath.size() - last_slash_index);

      asset_manager->PushBack(std::make_unique<blink::APKAssetProvider>(
          env,                       // jni environment
          jAssetManager,             // asset manager
          std::move(apk_asset_dir))  // apk asset dir
      );
    }
  }

  const auto defaultpath = fml::jni::JavaStringToString(env, jdefaultPath);
  if (defaultpath.size() > 0) {
    asset_manager->PushBack(std::make_unique<blink::DirectoryAssetBundle>(
        fml::OpenFile(defaultpath.c_str(), fml::OpenPermission::kRead, true)));
  }

  auto isolate_configuration = CreateIsolateConfiguration(*asset_manager);
  if (!isolate_configuration) {
    FML_DLOG(ERROR)
        << "Isolate configuration could not be determined for engine launch.";
    return;
  }

  RunConfiguration config(std::move(isolate_configuration),
                          std::move(asset_manager));

  {
    auto entrypoint = fml::jni::JavaStringToString(env, jEntrypoint);
    auto libraryUrl = fml::jni::JavaStringToString(env, jLibraryUrl);

    if ((entrypoint.size() > 0) && (libraryUrl.size() > 0)) {
      config.SetEntrypointAndLibrary(std::move(entrypoint),
                                     std::move(libraryUrl));
    } else if (entrypoint.size() > 0) {
      config.SetEntrypoint(std::move(entrypoint));
    }
  }

  ANDROID_SHELL_HOLDER->Launch(std::move(config));
}

static jobject LookupCallbackInformation(JNIEnv* env,
                                         /* unused */ jobject,
                                         jlong handle) {
  auto cbInfo = blink::DartCallbackCache::GetCallbackInformation(handle);
  if (cbInfo == nullptr) {
    return nullptr;
  }
  return CreateFlutterCallbackInformation(env, cbInfo->name, cbInfo->class_name,
                                          cbInfo->library_path);
}

static void SetViewportMetrics(JNIEnv* env,
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
                               jint physicalViewInsetLeft) {
  const blink::ViewportMetrics metrics = {
      .device_pixel_ratio = static_cast<double>(devicePixelRatio),
      .physical_width = static_cast<double>(physicalWidth),
      .physical_height = static_cast<double>(physicalHeight),
      .physical_padding_top = static_cast<double>(physicalPaddingTop),
      .physical_padding_right = static_cast<double>(physicalPaddingRight),
      .physical_padding_bottom = static_cast<double>(physicalPaddingBottom),
      .physical_padding_left = static_cast<double>(physicalPaddingLeft),
      .physical_view_inset_top = static_cast<double>(physicalViewInsetTop),
      .physical_view_inset_right = static_cast<double>(physicalViewInsetRight),
      .physical_view_inset_bottom =
          static_cast<double>(physicalViewInsetBottom),
      .physical_view_inset_left = static_cast<double>(physicalViewInsetLeft),
  };

  ANDROID_SHELL_HOLDER->SetViewportMetrics(metrics);
}

static jobject GetBitmap(JNIEnv* env, jobject jcaller, jlong shell_holder) {
  auto screenshot = ANDROID_SHELL_HOLDER->Screenshot(
      Rasterizer::ScreenshotType::UncompressedImage, false);
  if (screenshot.data == nullptr) {
    return nullptr;
  }

  const SkISize& frame_size = screenshot.frame_size;
  jsize pixels_size = frame_size.width() * frame_size.height();
  jintArray pixels_array = env->NewIntArray(pixels_size);
  if (pixels_array == nullptr) {
    return nullptr;
  }

  jint* pixels = env->GetIntArrayElements(pixels_array, nullptr);
  if (pixels == nullptr) {
    return nullptr;
  }

  auto pixels_src = static_cast<const int32_t*>(screenshot.data->data());

  // Our configuration of Skia does not support rendering to the
  // BitmapConfig.ARGB_8888 format expected by android.graphics.Bitmap.
  // Convert from kRGBA_8888 to kBGRA_8888 (equivalent to ARGB_8888).
  for (int i = 0; i < pixels_size; i++) {
    int32_t src_pixel = pixels_src[i];
    uint8_t* src_bytes = reinterpret_cast<uint8_t*>(&src_pixel);
    std::swap(src_bytes[0], src_bytes[2]);
    pixels[i] = src_pixel;
  }

  env->ReleaseIntArrayElements(pixels_array, pixels, 0);

  jclass bitmap_class = env->FindClass("android/graphics/Bitmap");
  if (bitmap_class == nullptr) {
    return nullptr;
  }

  jmethodID create_bitmap = env->GetStaticMethodID(
      bitmap_class, "createBitmap",
      "([IIILandroid/graphics/Bitmap$Config;)Landroid/graphics/Bitmap;");
  if (create_bitmap == nullptr) {
    return nullptr;
  }

  jclass bitmap_config_class = env->FindClass("android/graphics/Bitmap$Config");
  if (bitmap_config_class == nullptr) {
    return nullptr;
  }

  jmethodID bitmap_config_value_of = env->GetStaticMethodID(
      bitmap_config_class, "valueOf",
      "(Ljava/lang/String;)Landroid/graphics/Bitmap$Config;");
  if (bitmap_config_value_of == nullptr) {
    return nullptr;
  }

  jstring argb = env->NewStringUTF("ARGB_8888");
  if (argb == nullptr) {
    return nullptr;
  }

  jobject bitmap_config = env->CallStaticObjectMethod(
      bitmap_config_class, bitmap_config_value_of, argb);
  if (bitmap_config == nullptr) {
    return nullptr;
  }

  return env->CallStaticObjectMethod(bitmap_class, create_bitmap, pixels_array,
                                     frame_size.width(), frame_size.height(),
                                     bitmap_config);
}

static void DispatchPlatformMessage(JNIEnv* env,
                                    jobject jcaller,
                                    jlong shell_holder,
                                    jstring channel,
                                    jobject message,
                                    jint position,
                                    jint responseId) {
  ANDROID_SHELL_HOLDER->GetPlatformView()->DispatchPlatformMessage(
      env,                                         //
      fml::jni::JavaStringToString(env, channel),  //
      message,                                     //
      position,                                    //
      responseId                                   //
  );
}

static void DispatchEmptyPlatformMessage(JNIEnv* env,
                                         jobject jcaller,
                                         jlong shell_holder,
                                         jstring channel,
                                         jint responseId) {
  ANDROID_SHELL_HOLDER->GetPlatformView()->DispatchEmptyPlatformMessage(
      env,                                         //
      fml::jni::JavaStringToString(env, channel),  //
      responseId                                   //
  );
}

static void DispatchPointerDataPacket(JNIEnv* env,
                                      jobject jcaller,
                                      jlong shell_holder,
                                      jobject buffer,
                                      jint position) {
  uint8_t* data = static_cast<uint8_t*>(env->GetDirectBufferAddress(buffer));
  auto packet = std::make_unique<blink::PointerDataPacket>(data, position);
  ANDROID_SHELL_HOLDER->DispatchPointerDataPacket(std::move(packet));
}

static void DispatchSemanticsAction(JNIEnv* env,
                                    jobject jcaller,
                                    jlong shell_holder,
                                    jint id,
                                    jint action,
                                    jobject args,
                                    jint args_position) {
  ANDROID_SHELL_HOLDER->GetPlatformView()->DispatchSemanticsAction(
      env,           //
      id,            //
      action,        //
      args,          //
      args_position  //
  );
}

static void SetSemanticsEnabled(JNIEnv* env,
                                jobject jcaller,
                                jlong shell_holder,
                                jboolean enabled) {
  ANDROID_SHELL_HOLDER->GetPlatformView()->SetSemanticsEnabled(enabled);
}

static void SetAccessibilityFeatures(JNIEnv* env,
                                     jobject jcaller,
                                     jlong shell_holder,
                                     jint flags) {
  ANDROID_SHELL_HOLDER->GetPlatformView()->SetAccessibilityFeatures(flags);
}

static jboolean GetIsSoftwareRendering(JNIEnv* env, jobject jcaller) {
  return FlutterMain::Get().GetSettings().enable_software_rendering;
}

static void RegisterTexture(JNIEnv* env,
                            jobject jcaller,
                            jlong shell_holder,
                            jlong texture_id,
                            jobject surface_texture) {
  ANDROID_SHELL_HOLDER->GetPlatformView()->RegisterExternalTexture(
      static_cast<int64_t>(texture_id),                        //
      fml::jni::JavaObjectWeakGlobalRef(env, surface_texture)  //
  );
}

static void MarkTextureFrameAvailable(JNIEnv* env,
                                      jobject jcaller,
                                      jlong shell_holder,
                                      jlong texture_id) {
  ANDROID_SHELL_HOLDER->GetPlatformView()->MarkTextureFrameAvailable(
      static_cast<int64_t>(texture_id));
}

static void UnregisterTexture(JNIEnv* env,
                              jobject jcaller,
                              jlong shell_holder,
                              jlong texture_id) {
  ANDROID_SHELL_HOLDER->GetPlatformView()->UnregisterTexture(
      static_cast<int64_t>(texture_id));
}

static void InvokePlatformMessageResponseCallback(JNIEnv* env,
                                                  jobject jcaller,
                                                  jlong shell_holder,
                                                  jint responseId,
                                                  jobject message,
                                                  jint position) {
  ANDROID_SHELL_HOLDER->GetPlatformView()
      ->InvokePlatformMessageResponseCallback(env,         //
                                              responseId,  //
                                              message,     //
                                              position     //
      );
}

static void InvokePlatformMessageEmptyResponseCallback(JNIEnv* env,
                                                       jobject jcaller,
                                                       jlong shell_holder,
                                                       jint responseId) {
  ANDROID_SHELL_HOLDER->GetPlatformView()
      ->InvokePlatformMessageEmptyResponseCallback(env,        //
                                                   responseId  //
      );
}

bool PlatformViewAndroid::Register(JNIEnv* env) {
  if (env == nullptr) {
    return false;
  }

  g_flutter_callback_info_class = new fml::jni::ScopedJavaGlobalRef<jclass>(
      env, env->FindClass("io/flutter/view/FlutterCallbackInformation"));
  if (g_flutter_callback_info_class->is_null()) {
    return false;
  }

  g_flutter_callback_info_constructor = env->GetMethodID(
      g_flutter_callback_info_class->obj(), "<init>",
      "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
  if (g_flutter_callback_info_constructor == nullptr) {
    return false;
  }

  g_flutter_view_class = new fml::jni::ScopedJavaGlobalRef<jclass>(
      env, env->FindClass("io/flutter/view/FlutterView"));
  if (g_flutter_view_class->is_null()) {
    return false;
  }

  g_flutter_native_view_class = new fml::jni::ScopedJavaGlobalRef<jclass>(
      env, env->FindClass("io/flutter/view/FlutterNativeView"));
  if (g_flutter_native_view_class->is_null()) {
    return false;
  }

  g_surface_texture_class = new fml::jni::ScopedJavaGlobalRef<jclass>(
      env, env->FindClass("android/graphics/SurfaceTexture"));
  if (g_surface_texture_class->is_null()) {
    return false;
  }

  static const JNINativeMethod native_view_methods[] = {
      {
          .name = "nativeAttach",
          .signature = "(Lio/flutter/view/FlutterNativeView;Z)J",
          .fnPtr = reinterpret_cast<void*>(&shell::Attach),
      },
      {
          .name = "nativeDestroy",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&shell::Destroy),
      },
      {
          .name = "nativeRunBundleAndSnapshotFromLibrary",
          .signature =
              "(JLjava/lang/String;Ljava/lang/String;Ljava/lang/String;"
              "Ljava/lang/String;Landroid/content/res/AssetManager;)V",
          .fnPtr =
              reinterpret_cast<void*>(&shell::RunBundleAndSnapshotFromLibrary),
      },
      {
          .name = "nativeDetach",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&shell::Detach),
      },
      {
          .name = "nativeGetObservatoryUri",
          .signature = "()Ljava/lang/String;",
          .fnPtr = reinterpret_cast<void*>(&shell::GetObservatoryUri),
      },
      {
          .name = "nativeDispatchEmptyPlatformMessage",
          .signature = "(JLjava/lang/String;I)V",
          .fnPtr =
              reinterpret_cast<void*>(&shell::DispatchEmptyPlatformMessage),
      },
      {
          .name = "nativeDispatchPlatformMessage",
          .signature = "(JLjava/lang/String;Ljava/nio/ByteBuffer;II)V",
          .fnPtr = reinterpret_cast<void*>(&shell::DispatchPlatformMessage),
      },
      {
          .name = "nativeInvokePlatformMessageResponseCallback",
          .signature = "(JILjava/nio/ByteBuffer;I)V",
          .fnPtr = reinterpret_cast<void*>(
              &shell::InvokePlatformMessageResponseCallback),
      },
      {
          .name = "nativeInvokePlatformMessageEmptyResponseCallback",
          .signature = "(JI)V",
          .fnPtr = reinterpret_cast<void*>(
              &shell::InvokePlatformMessageEmptyResponseCallback),
      },
  };

  static const JNINativeMethod view_methods[] = {
      {
          .name = "nativeSurfaceCreated",
          .signature = "(JLandroid/view/Surface;I)V",
          .fnPtr = reinterpret_cast<void*>(&shell::SurfaceCreated),
      },
      {
          .name = "nativeSurfaceChanged",
          .signature = "(JII)V",
          .fnPtr = reinterpret_cast<void*>(&shell::SurfaceChanged),
      },
      {
          .name = "nativeSurfaceDestroyed",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&shell::SurfaceDestroyed),
      },
      {
          .name = "nativeSetViewportMetrics",
          .signature = "(JFIIIIIIIIII)V",
          .fnPtr = reinterpret_cast<void*>(&shell::SetViewportMetrics),
      },
      {
          .name = "nativeGetBitmap",
          .signature = "(J)Landroid/graphics/Bitmap;",
          .fnPtr = reinterpret_cast<void*>(&shell::GetBitmap),
      },
      {
          .name = "nativeDispatchPointerDataPacket",
          .signature = "(JLjava/nio/ByteBuffer;I)V",
          .fnPtr = reinterpret_cast<void*>(&shell::DispatchPointerDataPacket),
      },
      {
          .name = "nativeDispatchSemanticsAction",
          .signature = "(JIILjava/nio/ByteBuffer;I)V",
          .fnPtr = reinterpret_cast<void*>(&shell::DispatchSemanticsAction),
      },
      {
          .name = "nativeSetSemanticsEnabled",
          .signature = "(JZ)V",
          .fnPtr = reinterpret_cast<void*>(&shell::SetSemanticsEnabled),
      },
      {
          .name = "nativeSetAccessibilityFeatures",
          .signature = "(JI)V",
          .fnPtr = reinterpret_cast<void*>(&shell::SetAccessibilityFeatures),
      },
      {
          .name = "nativeGetIsSoftwareRenderingEnabled",
          .signature = "()Z",
          .fnPtr = reinterpret_cast<void*>(&shell::GetIsSoftwareRendering),
      },
      {
          .name = "nativeRegisterTexture",
          .signature = "(JJLandroid/graphics/SurfaceTexture;)V",
          .fnPtr = reinterpret_cast<void*>(&shell::RegisterTexture),
      },
      {
          .name = "nativeMarkTextureFrameAvailable",
          .signature = "(JJ)V",
          .fnPtr = reinterpret_cast<void*>(&shell::MarkTextureFrameAvailable),
      },
      {
          .name = "nativeUnregisterTexture",
          .signature = "(JJ)V",
          .fnPtr = reinterpret_cast<void*>(&shell::UnregisterTexture),
      },
  };

  static const JNINativeMethod callback_info_methods[] = {
      {
          .name = "nativeLookupCallbackInformation",
          .signature = "(J)Lio/flutter/view/FlutterCallbackInformation;",
          .fnPtr = reinterpret_cast<void*>(&shell::LookupCallbackInformation),
      },
  };

  if (env->RegisterNatives(g_flutter_native_view_class->obj(),
                           native_view_methods,
                           arraysize(native_view_methods)) != 0) {
    return false;
  }

  if (env->RegisterNatives(g_flutter_view_class->obj(), view_methods,
                           arraysize(view_methods)) != 0) {
    return false;
  }

  if (env->RegisterNatives(g_flutter_callback_info_class->obj(),
                           callback_info_methods,
                           arraysize(callback_info_methods)) != 0) {
    return false;
  }

  g_handle_platform_message_method =
      env->GetMethodID(g_flutter_native_view_class->obj(),
                       "handlePlatformMessage", "(Ljava/lang/String;[BI)V");

  if (g_handle_platform_message_method == nullptr) {
    return false;
  }

  g_handle_platform_message_response_method =
      env->GetMethodID(g_flutter_native_view_class->obj(),
                       "handlePlatformMessageResponse", "(I[B)V");

  if (g_handle_platform_message_response_method == nullptr) {
    return false;
  }

  g_update_semantics_method =
      env->GetMethodID(g_flutter_native_view_class->obj(), "updateSemantics",
                       "(Ljava/nio/ByteBuffer;[Ljava/lang/String;)V");

  if (g_update_semantics_method == nullptr) {
    return false;
  }

  g_update_custom_accessibility_actions_method = env->GetMethodID(
      g_flutter_native_view_class->obj(), "updateCustomAccessibilityActions",
      "(Ljava/nio/ByteBuffer;[Ljava/lang/String;)V");

  if (g_update_custom_accessibility_actions_method == nullptr) {
    return false;
  }

  g_on_first_frame_method = env->GetMethodID(g_flutter_native_view_class->obj(),
                                             "onFirstFrame", "()V");

  if (g_on_first_frame_method == nullptr) {
    return false;
  }

  g_on_engine_restart_method = env->GetMethodID(
      g_flutter_native_view_class->obj(), "onPreEngineRestart", "()V");

  if (g_on_engine_restart_method == nullptr) {
    return false;
  }

  g_attach_to_gl_context_method = env->GetMethodID(
      g_surface_texture_class->obj(), "attachToGLContext", "(I)V");

  if (g_attach_to_gl_context_method == nullptr) {
    return false;
  }

  g_update_tex_image_method =
      env->GetMethodID(g_surface_texture_class->obj(), "updateTexImage", "()V");

  if (g_update_tex_image_method == nullptr) {
    return false;
  }

  g_get_transform_matrix_method = env->GetMethodID(
      g_surface_texture_class->obj(), "getTransformMatrix", "([F)V");

  if (g_get_transform_matrix_method == nullptr) {
    return false;
  }

  g_detach_from_gl_context_method = env->GetMethodID(
      g_surface_texture_class->obj(), "detachFromGLContext", "()V");

  if (g_detach_from_gl_context_method == nullptr) {
    return false;
  }

  return true;
}

}  // namespace shell
