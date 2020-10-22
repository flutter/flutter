// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android_jni_impl.h"

#include <android/native_window_jni.h>
#include <jni.h>
#include <utility>

#include "unicode/uchar.h"

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/common/settings.h"
#include "flutter/fml/file.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/fml/size.h"
#include "flutter/lib/ui/plugins/callback_cache.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/platform/android/android_external_texture_gl.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "flutter/shell/platform/android/flutter_main.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/platform_view_android.h"

#define ANDROID_SHELL_HOLDER \
  (reinterpret_cast<AndroidShellHolder*>(shell_holder))

namespace flutter {

namespace {

bool CheckException(JNIEnv* env) {
  if (env->ExceptionCheck() == JNI_FALSE) {
    return true;
  }

  jthrowable exception = env->ExceptionOccurred();
  env->ExceptionClear();
  FML_LOG(ERROR) << fml::jni::GetJavaExceptionInfo(env, exception);
  env->DeleteLocalRef(exception);
  return false;
}

}  // anonymous namespace

static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_callback_info_class =
    nullptr;

static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_jni_class = nullptr;

static fml::jni::ScopedJavaGlobalRef<jclass>* g_texture_wrapper_class = nullptr;

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

static jmethodID g_handle_platform_message_response_method = nullptr;

static jmethodID g_update_semantics_method = nullptr;

static jmethodID g_update_custom_accessibility_actions_method = nullptr;

static jmethodID g_on_first_frame_method = nullptr;

static jmethodID g_on_engine_restart_method = nullptr;

static jmethodID g_create_overlay_surface_method = nullptr;

static jmethodID g_destroy_overlay_surfaces_method = nullptr;

static jmethodID g_on_begin_frame_method = nullptr;

static jmethodID g_on_end_frame_method = nullptr;

static jmethodID g_attach_to_gl_context_method = nullptr;

static jmethodID g_update_tex_image_method = nullptr;

static jmethodID g_get_transform_matrix_method = nullptr;

static jmethodID g_detach_from_gl_context_method = nullptr;

static jmethodID g_compute_platform_resolved_locale_method = nullptr;

// Called By Java
static jmethodID g_on_display_platform_view_method = nullptr;

// static jmethodID g_on_composite_platform_view_method = nullptr;

static jmethodID g_on_display_overlay_surface_method = nullptr;

static jmethodID g_overlay_surface_id_method = nullptr;

static jmethodID g_overlay_surface_surface_method = nullptr;

// Mutators
static fml::jni::ScopedJavaGlobalRef<jclass>* g_mutators_stack_class = nullptr;
static jmethodID g_mutators_stack_init_method = nullptr;
static jmethodID g_mutators_stack_push_transform_method = nullptr;
static jmethodID g_mutators_stack_push_cliprect_method = nullptr;

// Called By Java
static jlong AttachJNI(JNIEnv* env,
                       jclass clazz,
                       jobject flutterJNI,
                       jboolean is_background_view) {
  fml::jni::JavaObjectWeakGlobalRef java_object(env, flutterJNI);
  std::shared_ptr<PlatformViewAndroidJNI> jni_facade =
      std::make_shared<PlatformViewAndroidJNIImpl>(java_object);
  auto shell_holder = std::make_unique<AndroidShellHolder>(
      FlutterMain::Get().GetSettings(), jni_facade, is_background_view);
  if (shell_holder->IsValid()) {
    return reinterpret_cast<jlong>(shell_holder.release());
  } else {
    return 0;
  }
}

static void DestroyJNI(JNIEnv* env, jobject jcaller, jlong shell_holder) {
  delete ANDROID_SHELL_HOLDER;
}

static void SurfaceCreated(JNIEnv* env,
                           jobject jcaller,
                           jlong shell_holder,
                           jobject jsurface) {
  // Note: This frame ensures that any local references used by
  // ANativeWindow_fromSurface are released immediately. This is needed as a
  // workaround for https://code.google.com/p/android/issues/detail?id=68174
  fml::jni::ScopedJavaLocalFrame scoped_local_reference_frame(env);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      ANativeWindow_fromSurface(env, jsurface));
  ANDROID_SHELL_HOLDER->GetPlatformView()->NotifyCreated(std::move(window));
}

static void SurfaceWindowChanged(JNIEnv* env,
                                 jobject jcaller,
                                 jlong shell_holder,
                                 jobject jsurface) {
  // Note: This frame ensures that any local references used by
  // ANativeWindow_fromSurface are released immediately. This is needed as a
  // workaround for https://code.google.com/p/android/issues/detail?id=68174
  fml::jni::ScopedJavaLocalFrame scoped_local_reference_frame(env);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      ANativeWindow_fromSurface(env, jsurface));
  ANDROID_SHELL_HOLDER->GetPlatformView()->NotifySurfaceWindowChanged(
      std::move(window));
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

static void RunBundleAndSnapshotFromLibrary(JNIEnv* env,
                                            jobject jcaller,
                                            jlong shell_holder,
                                            jstring jBundlePath,
                                            jstring jEntrypoint,
                                            jstring jLibraryUrl,
                                            jobject jAssetManager) {
  auto asset_manager = std::make_shared<flutter::AssetManager>();

  asset_manager->PushBack(std::make_unique<flutter::APKAssetProvider>(
      env,                                             // jni environment
      jAssetManager,                                   // asset manager
      fml::jni::JavaStringToString(env, jBundlePath))  // apk asset dir
  );

  std::unique_ptr<IsolateConfiguration> isolate_configuration;
  if (flutter::DartVM::IsRunningPrecompiledCode()) {
    isolate_configuration = IsolateConfiguration::CreateForAppSnapshot();
  } else {
    std::unique_ptr<fml::Mapping> kernel_blob =
        fml::FileMapping::CreateReadOnly(
            ANDROID_SHELL_HOLDER->GetSettings().application_kernel_asset);
    if (!kernel_blob) {
      FML_DLOG(ERROR) << "Unable to load the kernel blob asset.";
      return;
    }
    isolate_configuration =
        IsolateConfiguration::CreateForKernel(std::move(kernel_blob));
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
  auto cbInfo = flutter::DartCallbackCache::GetCallbackInformation(handle);
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
                               jint physicalViewInsetLeft,
                               jint systemGestureInsetTop,
                               jint systemGestureInsetRight,
                               jint systemGestureInsetBottom,
                               jint systemGestureInsetLeft) {
  const flutter::ViewportMetrics metrics{
      static_cast<double>(devicePixelRatio),
      static_cast<double>(physicalWidth),
      static_cast<double>(physicalHeight),
      static_cast<double>(physicalPaddingTop),
      static_cast<double>(physicalPaddingRight),
      static_cast<double>(physicalPaddingBottom),
      static_cast<double>(physicalPaddingLeft),
      static_cast<double>(physicalViewInsetTop),
      static_cast<double>(physicalViewInsetRight),
      static_cast<double>(physicalViewInsetBottom),
      static_cast<double>(physicalViewInsetLeft),
      static_cast<double>(systemGestureInsetTop),
      static_cast<double>(systemGestureInsetRight),
      static_cast<double>(systemGestureInsetBottom),
      static_cast<double>(systemGestureInsetLeft),
  };

  ANDROID_SHELL_HOLDER->GetPlatformView()->SetViewportMetrics(metrics);
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

  auto* pixels_src = static_cast<const int32_t*>(screenshot.data->data());

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
  auto packet = std::make_unique<flutter::PointerDataPacket>(data, position);
  ANDROID_SHELL_HOLDER->GetPlatformView()->DispatchPointerDataPacket(
      std::move(packet));
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

static void NotifyLowMemoryWarning(JNIEnv* env,
                                   jobject obj,
                                   jlong shell_holder) {
  ANDROID_SHELL_HOLDER->NotifyLowMemoryWarning();
}

static jboolean FlutterTextUtilsIsEmoji(JNIEnv* env,
                                        jobject obj,
                                        jint codePoint) {
  return u_hasBinaryProperty(codePoint, UProperty::UCHAR_EMOJI);
}

static jboolean FlutterTextUtilsIsEmojiModifier(JNIEnv* env,
                                                jobject obj,
                                                jint codePoint) {
  return u_hasBinaryProperty(codePoint, UProperty::UCHAR_EMOJI_MODIFIER);
}

static jboolean FlutterTextUtilsIsEmojiModifierBase(JNIEnv* env,
                                                    jobject obj,
                                                    jint codePoint) {
  return u_hasBinaryProperty(codePoint, UProperty::UCHAR_EMOJI_MODIFIER_BASE);
}

static jboolean FlutterTextUtilsIsVariationSelector(JNIEnv* env,
                                                    jobject obj,
                                                    jint codePoint) {
  return u_hasBinaryProperty(codePoint, UProperty::UCHAR_VARIATION_SELECTOR);
}

static jboolean FlutterTextUtilsIsRegionalIndicator(JNIEnv* env,
                                                    jobject obj,
                                                    jint codePoint) {
  return u_hasBinaryProperty(codePoint, UProperty::UCHAR_REGIONAL_INDICATOR);
}
bool RegisterApi(JNIEnv* env) {
  static const JNINativeMethod flutter_jni_methods[] = {
      // Start of methods from FlutterJNI
      {
          .name = "nativeAttach",
          .signature = "(Lio/flutter/embedding/engine/FlutterJNI;Z)J",
          .fnPtr = reinterpret_cast<void*>(&AttachJNI),
      },
      {
          .name = "nativeDestroy",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&DestroyJNI),
      },
      {
          .name = "nativeRunBundleAndSnapshotFromLibrary",
          .signature = "(JLjava/lang/String;Ljava/lang/String;"
                       "Ljava/lang/String;Landroid/content/res/AssetManager;)V",
          .fnPtr = reinterpret_cast<void*>(&RunBundleAndSnapshotFromLibrary),
      },
      {
          .name = "nativeDispatchEmptyPlatformMessage",
          .signature = "(JLjava/lang/String;I)V",
          .fnPtr = reinterpret_cast<void*>(&DispatchEmptyPlatformMessage),
      },
      {
          .name = "nativeDispatchPlatformMessage",
          .signature = "(JLjava/lang/String;Ljava/nio/ByteBuffer;II)V",
          .fnPtr = reinterpret_cast<void*>(&DispatchPlatformMessage),
      },
      {
          .name = "nativeInvokePlatformMessageResponseCallback",
          .signature = "(JILjava/nio/ByteBuffer;I)V",
          .fnPtr =
              reinterpret_cast<void*>(&InvokePlatformMessageResponseCallback),
      },
      {
          .name = "nativeInvokePlatformMessageEmptyResponseCallback",
          .signature = "(JI)V",
          .fnPtr = reinterpret_cast<void*>(
              &InvokePlatformMessageEmptyResponseCallback),
      },
      {
          .name = "nativeNotifyLowMemoryWarning",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&NotifyLowMemoryWarning),
      },

      // Start of methods from FlutterView
      {
          .name = "nativeGetBitmap",
          .signature = "(J)Landroid/graphics/Bitmap;",
          .fnPtr = reinterpret_cast<void*>(&GetBitmap),
      },
      {
          .name = "nativeSurfaceCreated",
          .signature = "(JLandroid/view/Surface;)V",
          .fnPtr = reinterpret_cast<void*>(&SurfaceCreated),
      },
      {
          .name = "nativeSurfaceWindowChanged",
          .signature = "(JLandroid/view/Surface;)V",
          .fnPtr = reinterpret_cast<void*>(&SurfaceWindowChanged),
      },
      {
          .name = "nativeSurfaceChanged",
          .signature = "(JII)V",
          .fnPtr = reinterpret_cast<void*>(&SurfaceChanged),
      },
      {
          .name = "nativeSurfaceDestroyed",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&SurfaceDestroyed),
      },
      {
          .name = "nativeSetViewportMetrics",
          .signature = "(JFIIIIIIIIIIIIII)V",
          .fnPtr = reinterpret_cast<void*>(&SetViewportMetrics),
      },
      {
          .name = "nativeDispatchPointerDataPacket",
          .signature = "(JLjava/nio/ByteBuffer;I)V",
          .fnPtr = reinterpret_cast<void*>(&DispatchPointerDataPacket),
      },
      {
          .name = "nativeDispatchSemanticsAction",
          .signature = "(JIILjava/nio/ByteBuffer;I)V",
          .fnPtr = reinterpret_cast<void*>(&DispatchSemanticsAction),
      },
      {
          .name = "nativeSetSemanticsEnabled",
          .signature = "(JZ)V",
          .fnPtr = reinterpret_cast<void*>(&SetSemanticsEnabled),
      },
      {
          .name = "nativeSetAccessibilityFeatures",
          .signature = "(JI)V",
          .fnPtr = reinterpret_cast<void*>(&SetAccessibilityFeatures),
      },
      {
          .name = "nativeGetIsSoftwareRenderingEnabled",
          .signature = "()Z",
          .fnPtr = reinterpret_cast<void*>(&GetIsSoftwareRendering),
      },
      {
          .name = "nativeRegisterTexture",
          .signature = "(JJLio/flutter/embedding/engine/renderer/"
                       "SurfaceTextureWrapper;)V",
          .fnPtr = reinterpret_cast<void*>(&RegisterTexture),
      },
      {
          .name = "nativeMarkTextureFrameAvailable",
          .signature = "(JJ)V",
          .fnPtr = reinterpret_cast<void*>(&MarkTextureFrameAvailable),
      },
      {
          .name = "nativeUnregisterTexture",
          .signature = "(JJ)V",
          .fnPtr = reinterpret_cast<void*>(&UnregisterTexture),
      },

      // Methods for Dart callback functionality.
      {
          .name = "nativeLookupCallbackInformation",
          .signature = "(J)Lio/flutter/view/FlutterCallbackInformation;",
          .fnPtr = reinterpret_cast<void*>(&LookupCallbackInformation),
      },

      // Start of methods for FlutterTextUtils
      {
          .name = "nativeFlutterTextUtilsIsEmoji",
          .signature = "(I)Z",
          .fnPtr = reinterpret_cast<void*>(&FlutterTextUtilsIsEmoji),
      },
      {
          .name = "nativeFlutterTextUtilsIsEmojiModifier",
          .signature = "(I)Z",
          .fnPtr = reinterpret_cast<void*>(&FlutterTextUtilsIsEmojiModifier),
      },
      {
          .name = "nativeFlutterTextUtilsIsEmojiModifierBase",
          .signature = "(I)Z",
          .fnPtr =
              reinterpret_cast<void*>(&FlutterTextUtilsIsEmojiModifierBase),
      },
      {
          .name = "nativeFlutterTextUtilsIsVariationSelector",
          .signature = "(I)Z",
          .fnPtr =
              reinterpret_cast<void*>(&FlutterTextUtilsIsVariationSelector),
      },
      {
          .name = "nativeFlutterTextUtilsIsRegionalIndicator",
          .signature = "(I)Z",
          .fnPtr =
              reinterpret_cast<void*>(&FlutterTextUtilsIsRegionalIndicator),
      },
  };

  if (env->RegisterNatives(g_flutter_jni_class->obj(), flutter_jni_methods,
                           fml::size(flutter_jni_methods)) != 0) {
    FML_LOG(ERROR) << "Failed to RegisterNatives with FlutterJNI";
    return false;
  }

  g_handle_platform_message_method =
      env->GetMethodID(g_flutter_jni_class->obj(), "handlePlatformMessage",
                       "(Ljava/lang/String;[BI)V");

  if (g_handle_platform_message_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate handlePlatformMessage method";
    return false;
  }

  g_handle_platform_message_response_method = env->GetMethodID(
      g_flutter_jni_class->obj(), "handlePlatformMessageResponse", "(I[B)V");

  if (g_handle_platform_message_response_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate handlePlatformMessageResponse method";
    return false;
  }

  g_update_semantics_method =
      env->GetMethodID(g_flutter_jni_class->obj(), "updateSemantics",
                       "(Ljava/nio/ByteBuffer;[Ljava/lang/String;)V");

  if (g_update_semantics_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate updateSemantics method";
    return false;
  }

  g_update_custom_accessibility_actions_method = env->GetMethodID(
      g_flutter_jni_class->obj(), "updateCustomAccessibilityActions",
      "(Ljava/nio/ByteBuffer;[Ljava/lang/String;)V");

  if (g_update_custom_accessibility_actions_method == nullptr) {
    FML_LOG(ERROR)
        << "Could not locate updateCustomAccessibilityActions method";
    return false;
  }

  g_on_first_frame_method =
      env->GetMethodID(g_flutter_jni_class->obj(), "onFirstFrame", "()V");

  if (g_on_first_frame_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate onFirstFrame method";
    return false;
  }

  g_on_engine_restart_method =
      env->GetMethodID(g_flutter_jni_class->obj(), "onPreEngineRestart", "()V");

  if (g_on_engine_restart_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate onEngineRestart method";
    return false;
  }

  g_create_overlay_surface_method =
      env->GetMethodID(g_flutter_jni_class->obj(), "createOverlaySurface",
                       "()Lio/flutter/embedding/engine/FlutterOverlaySurface;");

  if (g_create_overlay_surface_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate createOverlaySurface method";
    return false;
  }

  g_destroy_overlay_surfaces_method = env->GetMethodID(
      g_flutter_jni_class->obj(), "destroyOverlaySurfaces", "()V");

  if (g_destroy_overlay_surfaces_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate destroyOverlaySurfaces method";
    return false;
  }

  fml::jni::ScopedJavaLocalRef<jclass> overlay_surface_class(
      env, env->FindClass("io/flutter/embedding/engine/FlutterOverlaySurface"));
  if (overlay_surface_class.is_null()) {
    FML_LOG(ERROR) << "Could not locate FlutterOverlaySurface class";
    return false;
  }
  g_overlay_surface_id_method =
      env->GetMethodID(overlay_surface_class.obj(), "getId", "()I");
  if (g_overlay_surface_id_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate FlutterOverlaySurface#getId() method";
    return false;
  }
  g_overlay_surface_surface_method = env->GetMethodID(
      overlay_surface_class.obj(), "getSurface", "()Landroid/view/Surface;");
  if (g_overlay_surface_surface_method == nullptr) {
    FML_LOG(ERROR)
        << "Could not locate FlutterOverlaySurface#getSurface() method";
    return false;
  }

  return true;
}

bool PlatformViewAndroid::Register(JNIEnv* env) {
  if (env == nullptr) {
    FML_LOG(ERROR) << "No JNIEnv provided";
    return false;
  }

  g_flutter_callback_info_class = new fml::jni::ScopedJavaGlobalRef<jclass>(
      env, env->FindClass("io/flutter/view/FlutterCallbackInformation"));
  if (g_flutter_callback_info_class->is_null()) {
    FML_LOG(ERROR) << "Could not locate FlutterCallbackInformation class";
    return false;
  }

  g_flutter_callback_info_constructor = env->GetMethodID(
      g_flutter_callback_info_class->obj(), "<init>",
      "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
  if (g_flutter_callback_info_constructor == nullptr) {
    FML_LOG(ERROR) << "Could not locate FlutterCallbackInformation constructor";
    return false;
  }

  g_flutter_jni_class = new fml::jni::ScopedJavaGlobalRef<jclass>(
      env, env->FindClass("io/flutter/embedding/engine/FlutterJNI"));
  if (g_flutter_jni_class->is_null()) {
    FML_LOG(ERROR) << "Failed to find FlutterJNI Class.";
    return false;
  }

  g_mutators_stack_class = new fml::jni::ScopedJavaGlobalRef<jclass>(
      env,
      env->FindClass(
          "io/flutter/embedding/engine/mutatorsstack/FlutterMutatorsStack"));
  if (g_mutators_stack_class == nullptr) {
    FML_LOG(ERROR) << "Could not locate FlutterMutatorsStack";
    return false;
  }

  g_mutators_stack_init_method =
      env->GetMethodID(g_mutators_stack_class->obj(), "<init>", "()V");
  if (g_mutators_stack_init_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate FlutterMutatorsStack.init method";
    return false;
  }

  g_mutators_stack_push_transform_method =
      env->GetMethodID(g_mutators_stack_class->obj(), "pushTransform", "([F)V");
  if (g_mutators_stack_push_transform_method == nullptr) {
    FML_LOG(ERROR)
        << "Could not locate FlutterMutatorsStack.pushTransform method";
    return false;
  }

  g_mutators_stack_push_cliprect_method = env->GetMethodID(
      g_mutators_stack_class->obj(), "pushClipRect", "(IIII)V");
  if (g_mutators_stack_push_cliprect_method == nullptr) {
    FML_LOG(ERROR)
        << "Could not locate FlutterMutatorsStack.pushCilpRect method";
    return false;
  }

  g_on_display_platform_view_method =
      env->GetMethodID(g_flutter_jni_class->obj(), "onDisplayPlatformView",
                       "(IIIIIIILio/flutter/embedding/engine/mutatorsstack/"
                       "FlutterMutatorsStack;)V");

  if (g_on_display_platform_view_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate onDisplayPlatformView method";
    return false;
  }

  g_on_begin_frame_method =
      env->GetMethodID(g_flutter_jni_class->obj(), "onBeginFrame", "()V");

  if (g_on_begin_frame_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate onBeginFrame method";
    return false;
  }

  g_on_end_frame_method =
      env->GetMethodID(g_flutter_jni_class->obj(), "onEndFrame", "()V");

  if (g_on_end_frame_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate onEndFrame method";
    return false;
  }

  g_on_display_overlay_surface_method = env->GetMethodID(
      g_flutter_jni_class->obj(), "onDisplayOverlaySurface", "(IIIII)V");

  if (g_on_display_overlay_surface_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate onDisplayOverlaySurface method";
    return false;
  }

  g_texture_wrapper_class = new fml::jni::ScopedJavaGlobalRef<jclass>(
      env, env->FindClass(
               "io/flutter/embedding/engine/renderer/SurfaceTextureWrapper"));
  if (g_texture_wrapper_class->is_null()) {
    FML_LOG(ERROR) << "Could not locate SurfaceTextureWrapper class";
    return false;
  }

  g_attach_to_gl_context_method = env->GetMethodID(
      g_texture_wrapper_class->obj(), "attachToGLContext", "(I)V");

  if (g_attach_to_gl_context_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate attachToGlContext method";
    return false;
  }

  g_update_tex_image_method =
      env->GetMethodID(g_texture_wrapper_class->obj(), "updateTexImage", "()V");

  if (g_update_tex_image_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate updateTexImage method";
    return false;
  }

  g_get_transform_matrix_method = env->GetMethodID(
      g_texture_wrapper_class->obj(), "getTransformMatrix", "([F)V");

  if (g_get_transform_matrix_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate getTransformMatrix method";
    return false;
  }

  g_detach_from_gl_context_method = env->GetMethodID(
      g_texture_wrapper_class->obj(), "detachFromGLContext", "()V");

  if (g_detach_from_gl_context_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate detachFromGlContext method";
    return false;
  }

  g_compute_platform_resolved_locale_method = env->GetMethodID(
      g_flutter_jni_class->obj(), "computePlatformResolvedLocale",
      "([Ljava/lang/String;)[Ljava/lang/String;");

  if (g_compute_platform_resolved_locale_method == nullptr) {
    FML_LOG(ERROR) << "Could not locate computePlatformResolvedLocale method";
    return false;
  }

  return RegisterApi(env);
}

PlatformViewAndroidJNIImpl::PlatformViewAndroidJNIImpl(
    fml::jni::JavaObjectWeakGlobalRef java_object)
    : java_object_(java_object) {}

PlatformViewAndroidJNIImpl::~PlatformViewAndroidJNIImpl() = default;

void PlatformViewAndroidJNIImpl::FlutterViewHandlePlatformMessage(
    fml::RefPtr<flutter::PlatformMessage> message,
    int responseId) {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return;
  }

  fml::jni::ScopedJavaLocalRef<jstring> java_channel =
      fml::jni::StringToJavaString(env, message->channel());

  if (message->hasData()) {
    fml::jni::ScopedJavaLocalRef<jbyteArray> message_array(
        env, env->NewByteArray(message->data().size()));
    env->SetByteArrayRegion(
        message_array.obj(), 0, message->data().size(),
        reinterpret_cast<const jbyte*>(message->data().data()));
    env->CallVoidMethod(java_object.obj(), g_handle_platform_message_method,
                        java_channel.obj(), message_array.obj(), responseId);
  } else {
    env->CallVoidMethod(java_object.obj(), g_handle_platform_message_method,
                        java_channel.obj(), nullptr, responseId);
  }

  FML_CHECK(CheckException(env));
}

void PlatformViewAndroidJNIImpl::FlutterViewHandlePlatformMessageResponse(
    int responseId,
    std::unique_ptr<fml::Mapping> data) {
  // We are on the platform thread. Attempt to get the strong reference to
  // the Java object.
  JNIEnv* env = fml::jni::AttachCurrentThread();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    // The Java object was collected before this message response got to
    // it. Drop the response on the floor.
    return;
  }
  if (data == nullptr) {  // Empty response.
    env->CallVoidMethod(java_object.obj(),
                        g_handle_platform_message_response_method, responseId,
                        nullptr);
  } else {
    // Convert the vector to a Java byte array.
    fml::jni::ScopedJavaLocalRef<jbyteArray> data_array(
        env, env->NewByteArray(data->GetSize()));
    env->SetByteArrayRegion(data_array.obj(), 0, data->GetSize(),
                            reinterpret_cast<const jbyte*>(data->GetMapping()));

    env->CallVoidMethod(java_object.obj(),
                        g_handle_platform_message_response_method, responseId,
                        data_array.obj());
  }

  FML_CHECK(CheckException(env));
}

void PlatformViewAndroidJNIImpl::FlutterViewUpdateSemantics(
    std::vector<uint8_t> buffer,
    std::vector<std::string> strings) {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return;
  }

  fml::jni::ScopedJavaLocalRef<jobject> direct_buffer(
      env, env->NewDirectByteBuffer(buffer.data(), buffer.size()));
  fml::jni::ScopedJavaLocalRef<jobjectArray> jstrings =
      fml::jni::VectorToStringArray(env, strings);

  env->CallVoidMethod(java_object.obj(), g_update_semantics_method,
                      direct_buffer.obj(), jstrings.obj());

  FML_CHECK(CheckException(env));
}

void PlatformViewAndroidJNIImpl::FlutterViewUpdateCustomAccessibilityActions(
    std::vector<uint8_t> actions_buffer,
    std::vector<std::string> strings) {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return;
  }

  fml::jni::ScopedJavaLocalRef<jobject> direct_actions_buffer(
      env,
      env->NewDirectByteBuffer(actions_buffer.data(), actions_buffer.size()));

  fml::jni::ScopedJavaLocalRef<jobjectArray> jstrings =
      fml::jni::VectorToStringArray(env, strings);

  env->CallVoidMethod(java_object.obj(),
                      g_update_custom_accessibility_actions_method,
                      direct_actions_buffer.obj(), jstrings.obj());

  FML_CHECK(CheckException(env));
}

void PlatformViewAndroidJNIImpl::FlutterViewOnFirstFrame() {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return;
  }

  env->CallVoidMethod(java_object.obj(), g_on_first_frame_method);

  FML_CHECK(CheckException(env));
}

void PlatformViewAndroidJNIImpl::FlutterViewOnPreEngineRestart() {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return;
  }

  env->CallVoidMethod(java_object.obj(), g_on_engine_restart_method);

  FML_CHECK(CheckException(env));
}

void PlatformViewAndroidJNIImpl::SurfaceTextureAttachToGLContext(
    JavaWeakGlobalRef surface_texture,
    int textureId) {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  fml::jni::ScopedJavaLocalRef<jobject> surface_texture_local_ref =
      surface_texture.get(env);
  if (surface_texture_local_ref.is_null()) {
    return;
  }

  env->CallVoidMethod(surface_texture_local_ref.obj(),
                      g_attach_to_gl_context_method, textureId);

  FML_CHECK(CheckException(env));
}

void PlatformViewAndroidJNIImpl::SurfaceTextureUpdateTexImage(
    JavaWeakGlobalRef surface_texture) {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  fml::jni::ScopedJavaLocalRef<jobject> surface_texture_local_ref =
      surface_texture.get(env);
  if (surface_texture_local_ref.is_null()) {
    return;
  }

  env->CallVoidMethod(surface_texture_local_ref.obj(),
                      g_update_tex_image_method);

  FML_CHECK(CheckException(env));
}

// The bounds we set for the canvas are post composition.
// To fill the canvas we need to ensure that the transformation matrix
// on the `SurfaceTexture` will be scaled to fill. We rescale and preseve
// the scaled aspect ratio.
SkSize ScaleToFill(float scaleX, float scaleY) {
  const double epsilon = std::numeric_limits<double>::epsilon();
  // scaleY is negative.
  const double minScale = fmin(scaleX, fabs(scaleY));
  const double rescale = 1.0f / (minScale + epsilon);
  return SkSize::Make(scaleX * rescale, scaleY * rescale);
}

void PlatformViewAndroidJNIImpl::SurfaceTextureGetTransformMatrix(
    JavaWeakGlobalRef surface_texture,
    SkMatrix& transform) {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  fml::jni::ScopedJavaLocalRef<jobject> surface_texture_local_ref =
      surface_texture.get(env);
  if (surface_texture_local_ref.is_null()) {
    return;
  }

  fml::jni::ScopedJavaLocalRef<jfloatArray> transformMatrix(
      env, env->NewFloatArray(16));

  env->CallVoidMethod(surface_texture_local_ref.obj(),
                      g_get_transform_matrix_method, transformMatrix.obj());
  FML_CHECK(CheckException(env));

  float* m = env->GetFloatArrayElements(transformMatrix.obj(), nullptr);
  float scaleX = m[0], scaleY = m[5];
  const SkSize scaled = ScaleToFill(scaleX, scaleY);
  SkScalar matrix3[] = {
      scaled.fWidth, m[1],           m[2],   //
      m[4],          scaled.fHeight, m[6],   //
      m[8],          m[9],           m[10],  //
  };
  env->ReleaseFloatArrayElements(transformMatrix.obj(), m, JNI_ABORT);
  transform.set9(matrix3);
}

void PlatformViewAndroidJNIImpl::SurfaceTextureDetachFromGLContext(
    JavaWeakGlobalRef surface_texture) {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  fml::jni::ScopedJavaLocalRef<jobject> surface_texture_local_ref =
      surface_texture.get(env);
  if (surface_texture_local_ref.is_null()) {
    return;
  }

  env->CallVoidMethod(surface_texture_local_ref.obj(),
                      g_detach_from_gl_context_method);

  FML_CHECK(CheckException(env));
}

void PlatformViewAndroidJNIImpl::FlutterViewOnDisplayPlatformView(
    int view_id,
    int x,
    int y,
    int width,
    int height,
    int viewWidth,
    int viewHeight,
    MutatorsStack mutators_stack) {
  JNIEnv* env = fml::jni::AttachCurrentThread();
  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return;
  }

  jobject mutatorsStack = env->NewObject(g_mutators_stack_class->obj(),
                                         g_mutators_stack_init_method);

  std::vector<std::shared_ptr<Mutator>>::const_iterator iter =
      mutators_stack.Begin();
  while (iter != mutators_stack.End()) {
    switch ((*iter)->GetType()) {
      case transform: {
        const SkMatrix& matrix = (*iter)->GetMatrix();
        SkScalar matrix_array[9];
        matrix.get9(matrix_array);
        fml::jni::ScopedJavaLocalRef<jfloatArray> transformMatrix(
            env, env->NewFloatArray(9));

        env->SetFloatArrayRegion(transformMatrix.obj(), 0, 9, matrix_array);
        env->CallVoidMethod(mutatorsStack,
                            g_mutators_stack_push_transform_method,
                            transformMatrix.obj());
        break;
      }
      case clip_rect: {
        const SkRect& rect = (*iter)->GetRect();
        env->CallVoidMethod(
            mutatorsStack, g_mutators_stack_push_cliprect_method,
            static_cast<int>(rect.left()), static_cast<int>(rect.top()),
            static_cast<int>(rect.right()), static_cast<int>(rect.bottom()));
        break;
      }
      // TODO(cyanglaz): Implement other mutators.
      // https://github.com/flutter/flutter/issues/58426
      case clip_rrect:
      case clip_path:
      case opacity:
        break;
    }
    ++iter;
  }

  env->CallVoidMethod(java_object.obj(), g_on_display_platform_view_method,
                      view_id, x, y, width, height, viewWidth, viewHeight,
                      mutatorsStack);

  FML_CHECK(CheckException(env));
}

void PlatformViewAndroidJNIImpl::FlutterViewDisplayOverlaySurface(
    int surface_id,
    int x,
    int y,
    int width,
    int height) {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return;
  }

  env->CallVoidMethod(java_object.obj(), g_on_display_overlay_surface_method,
                      surface_id, x, y, width, height);

  FML_CHECK(CheckException(env));
}

void PlatformViewAndroidJNIImpl::FlutterViewBeginFrame() {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return;
  }

  env->CallVoidMethod(java_object.obj(), g_on_begin_frame_method);

  FML_CHECK(CheckException(env));
}

void PlatformViewAndroidJNIImpl::FlutterViewEndFrame() {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return;
  }

  env->CallVoidMethod(java_object.obj(), g_on_end_frame_method);

  FML_CHECK(CheckException(env));
}

std::unique_ptr<PlatformViewAndroidJNI::OverlayMetadata>
PlatformViewAndroidJNIImpl::FlutterViewCreateOverlaySurface() {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return nullptr;
  }

  fml::jni::ScopedJavaLocalRef<jobject> overlay(
      env, env->CallObjectMethod(java_object.obj(),
                                 g_create_overlay_surface_method));
  FML_CHECK(CheckException(env));

  if (overlay.is_null()) {
    return std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(0,
                                                                     nullptr);
  }

  jint overlay_id =
      env->CallIntMethod(overlay.obj(), g_overlay_surface_id_method);

  jobject overlay_surface =
      env->CallObjectMethod(overlay.obj(), g_overlay_surface_surface_method);

  auto overlay_window = fml::MakeRefCounted<AndroidNativeWindow>(
      ANativeWindow_fromSurface(env, overlay_surface));

  return std::make_unique<PlatformViewAndroidJNI::OverlayMetadata>(
      overlay_id, std::move(overlay_window));
}

void PlatformViewAndroidJNIImpl::FlutterViewDestroyOverlaySurfaces() {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return;
  }

  env->CallVoidMethod(java_object.obj(), g_destroy_overlay_surfaces_method);

  FML_CHECK(CheckException(env));
}

std::unique_ptr<std::vector<std::string>>
PlatformViewAndroidJNIImpl::FlutterViewComputePlatformResolvedLocale(
    std::vector<std::string> supported_locales_data) {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  std::unique_ptr<std::vector<std::string>> out =
      std::make_unique<std::vector<std::string>>();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return out;
  }
  fml::jni::ScopedJavaLocalRef<jobjectArray> j_locales_data =
      fml::jni::VectorToStringArray(env, supported_locales_data);
  jobjectArray result = static_cast<jobjectArray>(env->CallObjectMethod(
      java_object.obj(), g_compute_platform_resolved_locale_method,
      j_locales_data.obj()));

  FML_CHECK(CheckException(env));

  int length = env->GetArrayLength(result);
  for (int i = 0; i < length; i++) {
    out->emplace_back(fml::jni::JavaStringToString(
        env, static_cast<jstring>(env->GetObjectArrayElement(result, i))));
  }
  return out;
}

double PlatformViewAndroidJNIImpl::GetDisplayRefreshRate() {
  JNIEnv* env = fml::jni::AttachCurrentThread();

  auto java_object = java_object_.get(env);
  if (java_object.is_null()) {
    return kUnknownDisplayRefreshRate;
  }

  jclass clazz = env->GetObjectClass(java_object.obj());
  if (clazz == nullptr) {
    return kUnknownDisplayRefreshRate;
  }

  jfieldID fid = env->GetStaticFieldID(clazz, "refreshRateFPS", "F");
  return static_cast<double>(env->GetStaticFloatField(clazz, fid));
}

}  // namespace flutter
