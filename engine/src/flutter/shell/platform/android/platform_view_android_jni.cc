// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android_jni.h"
#include "flutter/common/settings.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "lib/ftl/arraysize.h"
#include "lib/ftl/logging.h"

#define PLATFORM_VIEW (*reinterpret_cast<std::shared_ptr<PlatformViewAndroid>*>(platform_view))

namespace shell {

static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_view_class = nullptr;

// Called By Native

static jmethodID g_handle_platform_message_method = nullptr;
void FlutterViewHandlePlatformMessage(JNIEnv* env,
                                      jobject obj,
                                      jstring channel,
                                      jobject message,
                                      jint responseId) {
  env->CallVoidMethod(obj, g_handle_platform_message_method, channel, message,
                      responseId);
  FTL_CHECK(env->ExceptionCheck() == JNI_FALSE);
}

static jmethodID g_handle_platform_message_response_method = nullptr;
void FlutterViewHandlePlatformMessageResponse(JNIEnv* env,
                                              jobject obj,
                                              jint responseId,
                                              jobject response) {
  env->CallVoidMethod(obj, g_handle_platform_message_response_method,
                      responseId, response);
  FTL_CHECK(env->ExceptionCheck() == JNI_FALSE);
}

static jmethodID g_update_semantics_method = nullptr;
void FlutterViewUpdateSemantics(JNIEnv* env,
                                jobject obj,
                                jobject buffer,
                                jobjectArray strings) {
  env->CallVoidMethod(obj, g_update_semantics_method, buffer, strings);
  FTL_CHECK(env->ExceptionCheck() == JNI_FALSE);
}

static jmethodID g_on_first_frame_method = nullptr;
void FlutterViewOnFirstFrame(JNIEnv* env, jobject obj) {
  env->CallVoidMethod(obj, g_on_first_frame_method);
  FTL_CHECK(env->ExceptionCheck() == JNI_FALSE);
}

// Called By Java

static jlong Attach(JNIEnv* env, jclass clazz, jobject flutterView) {
  auto view = new PlatformViewAndroid();
  auto storage = new std::shared_ptr<PlatformViewAndroid>(view);
  // Create a weak reference to the flutterView Java object so that we can make
  // calls into it later.
  view->Attach();
  view->set_flutter_view(fml::jni::JavaObjectWeakGlobalRef(env, flutterView));
  return reinterpret_cast<jlong>(storage);
}

static void Detach(JNIEnv* env, jobject jcaller, jlong platform_view) {
  PLATFORM_VIEW->Detach();
  delete &PLATFORM_VIEW;
}

static jstring GetObservatoryUri(JNIEnv* env, jclass clazz) {
  return env->NewStringUTF(
      blink::DartServiceIsolate::GetObservatoryUri().c_str());
}

static void SurfaceCreated(JNIEnv* env,
                           jobject jcaller,
                           jlong platform_view,
                           jobject surface,
                           jint backgroundColor) {
  return PLATFORM_VIEW->SurfaceCreated(env, surface, backgroundColor);
}

static void SurfaceChanged(JNIEnv* env,
                           jobject jcaller,
                           jlong platform_view,
                           jint width,
                           jint height) {
  return PLATFORM_VIEW->SurfaceChanged(width, height);
}

static void SurfaceDestroyed(JNIEnv* env,
                             jobject jcaller,
                             jlong platform_view) {
  return PLATFORM_VIEW->SurfaceDestroyed();
}

static void RunBundleAndSnapshot(JNIEnv* env,
                                 jobject jcaller,
                                 jlong platform_view,
                                 jstring bundlePath,
                                 jstring snapshotOverride) {
  return PLATFORM_VIEW->RunBundleAndSnapshot(
      fml::jni::JavaStringToString(env, bundlePath),       //
      fml::jni::JavaStringToString(env, snapshotOverride)  //
      );
}

void RunBundleAndSource(JNIEnv* env,
                        jobject jcaller,
                        jlong platform_view,
                        jstring bundlePath,
                        jstring main,
                        jstring packages) {
  return PLATFORM_VIEW->RunBundleAndSource(
      fml::jni::JavaStringToString(env, bundlePath),
      fml::jni::JavaStringToString(env, main),
      fml::jni::JavaStringToString(env, packages));
}

static void SetViewportMetrics(JNIEnv* env,
                               jobject jcaller,
                               jlong platform_view,
                               jfloat devicePixelRatio,
                               jint physicalWidth,
                               jint physicalHeight,
                               jint physicalPaddingTop,
                               jint physicalPaddingRight,
                               jint physicalPaddingBottom,
                               jint physicalPaddingLeft) {
  return PLATFORM_VIEW->SetViewportMetrics(devicePixelRatio,       //
                                           physicalWidth,          //
                                           physicalHeight,         //
                                           physicalPaddingTop,     //
                                           physicalPaddingRight,   //
                                           physicalPaddingBottom,  //
                                           physicalPaddingLeft);
}

static jobject GetBitmap(JNIEnv* env, jobject jcaller, jlong platform_view) {
  return PLATFORM_VIEW->GetBitmap(env).Release();
}

static void DispatchPlatformMessage(JNIEnv* env,
                                    jobject jcaller,
                                    jlong platform_view,
                                    jstring channel,
                                    jobject message,
                                    jint position,
                                    jint responseId) {
  return PLATFORM_VIEW->DispatchPlatformMessage(
      env, fml::jni::JavaStringToString(env, channel), message, position,
      responseId);
}

static void DispatchEmptyPlatformMessage(JNIEnv* env,
                                         jobject jcaller,
                                         jlong platform_view,
                                         jstring channel,
                                         jint responseId) {
  return PLATFORM_VIEW->DispatchEmptyPlatformMessage(
      env, fml::jni::JavaStringToString(env, channel), responseId);
}

static void DispatchPointerDataPacket(JNIEnv* env,
                                      jobject jcaller,
                                      jlong platform_view,
                                      jobject buffer,
                                      jint position) {
  return PLATFORM_VIEW->DispatchPointerDataPacket(env, buffer, position);
}

static void DispatchSemanticsAction(JNIEnv* env,
                                    jobject jcaller,
                                    jlong platform_view,
                                    jint id,
                                    jint action) {
  return PLATFORM_VIEW->DispatchSemanticsAction(id, action);
}

static void SetSemanticsEnabled(JNIEnv* env,
                                jobject jcaller,
                                jlong platform_view,
                                jboolean enabled) {
  return PLATFORM_VIEW->SetSemanticsEnabled(enabled);
}

static jboolean GetIsSoftwareRendering(JNIEnv* env, jobject jcaller) {
  return blink::Settings::Get().enable_software_rendering;
}

static void InvokePlatformMessageResponseCallback(JNIEnv* env,
                                                  jobject jcaller,
                                                  jlong platform_view,
                                                  jint responseId,
                                                  jobject message,
                                                  jint position) {
  return PLATFORM_VIEW->InvokePlatformMessageResponseCallback(
      env, responseId, message, position);
}

static void InvokePlatformMessageEmptyResponseCallback(JNIEnv* env,
                                                       jobject jcaller,
                                                       jlong platform_view,
                                                       jint responseId) {
  return PLATFORM_VIEW->InvokePlatformMessageEmptyResponseCallback(env,
                                                                   responseId);
}

bool PlatformViewAndroid::Register(JNIEnv* env) {
  if (env == nullptr) {
    return false;
  }

  g_flutter_view_class = new fml::jni::ScopedJavaGlobalRef<jclass>(
      env, env->FindClass("io/flutter/view/FlutterView"));

  if (g_flutter_view_class->is_null()) {
    return false;
  }

  static const JNINativeMethod methods[] = {
      {
          .name = "nativeAttach",
          .signature = "(Lio/flutter/view/FlutterView;)J",
          .fnPtr = reinterpret_cast<void*>(&shell::Attach),
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
          .name = "nativeRunBundleAndSnapshot",
          .signature = "(JLjava/lang/String;Ljava/lang/String;)V",
          .fnPtr = reinterpret_cast<void*>(&shell::RunBundleAndSnapshot),
      },
      {
          .name = "nativeRunBundleAndSource",
          .signature =
              "(JLjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
          .fnPtr = reinterpret_cast<void*>(&shell::RunBundleAndSource),
      },
      {
          .name = "nativeSetViewportMetrics",
          .signature = "(JFIIIIII)V",
          .fnPtr = reinterpret_cast<void*>(&shell::SetViewportMetrics),
      },
      {
          .name = "nativeGetBitmap",
          .signature = "(J)Landroid/graphics/Bitmap;",
          .fnPtr = reinterpret_cast<void*>(&shell::GetBitmap),
      },
      {
          .name = "nativeDispatchPlatformMessage",
          .signature = "(JLjava/lang/String;Ljava/nio/ByteBuffer;II)V",
          .fnPtr = reinterpret_cast<void*>(&shell::DispatchPlatformMessage),
      },
      {
          .name = "nativeDispatchEmptyPlatformMessage",
          .signature = "(JLjava/lang/String;I)V",
          .fnPtr =
              reinterpret_cast<void*>(&shell::DispatchEmptyPlatformMessage),
      },
      {
          .name = "nativeDispatchPointerDataPacket",
          .signature = "(JLjava/nio/ByteBuffer;I)V",
          .fnPtr = reinterpret_cast<void*>(&shell::DispatchPointerDataPacket),
      },
      {
          .name = "nativeDispatchSemanticsAction",
          .signature = "(JII)V",
          .fnPtr = reinterpret_cast<void*>(&shell::DispatchSemanticsAction),
      },
      {
          .name = "nativeSetSemanticsEnabled",
          .signature = "(JZ)V",
          .fnPtr = reinterpret_cast<void*>(&shell::SetSemanticsEnabled),
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
      {
          .name = "nativeGetIsSoftwareRenderingEnabled",
          .signature = "()Z",
          .fnPtr = reinterpret_cast<void*>(&shell::GetIsSoftwareRendering),
      },
  };

  if (env->RegisterNatives(g_flutter_view_class->obj(), methods,
                           arraysize(methods)) != 0) {
    return false;
  }

  g_handle_platform_message_method =
      env->GetMethodID(g_flutter_view_class->obj(), "handlePlatformMessage",
                       "(Ljava/lang/String;[BI)V");

  if (g_handle_platform_message_method == nullptr) {
    return false;
  }

  g_handle_platform_message_response_method = env->GetMethodID(
      g_flutter_view_class->obj(), "handlePlatformMessageResponse", "(I[B)V");

  if (g_handle_platform_message_response_method == nullptr) {
    return false;
  }

  g_update_semantics_method =
      env->GetMethodID(g_flutter_view_class->obj(), "updateSemantics",
                       "(Ljava/nio/ByteBuffer;[Ljava/lang/String;)V");

  if (g_update_semantics_method == nullptr) {
    return false;
  }

  g_on_first_frame_method =
      env->GetMethodID(g_flutter_view_class->obj(), "onFirstFrame", "()V");

  if (g_on_first_frame_method == nullptr) {
    return false;
  }
  return true;
}

}  // namespace shell
