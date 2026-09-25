// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/embedder/flutter_embedder_native.h"

#include <android/asset_manager_jni.h>
#include <android/hardware_buffer_jni.h>
#include <android/native_window_jni.h>
#include <dlfcn.h>
#include <jni.h>
#include <algorithm>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "unicode/uchar.h"

#include "flutter/common/constants.h"
#include "flutter/common/settings.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

class FlutterMain {
 public:
  static FlutterMain& Get();
  const flutter::Settings& GetSettings() const;
};

namespace {

static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_jni_class = nullptr;
static fml::jni::ScopedJavaGlobalRef<jclass>* g_java_long_class = nullptr;
static fml::jni::ScopedJavaGlobalRef<jclass>* g_flutter_callback_info_class =
    nullptr;

static jfieldID g_jni_shell_holder_field = nullptr;
static jmethodID g_jni_constructor = nullptr;
static jmethodID g_long_constructor = nullptr;
static jmethodID g_flutter_callback_info_constructor = nullptr;

static jmethodID g_handle_platform_message_method = nullptr;
static jmethodID g_handle_platform_message_response_method = nullptr;
static jmethodID g_on_first_frame_method = nullptr;
static jmethodID g_on_engine_restart_method = nullptr;
static jmethodID g_request_dart_deferred_library_method = nullptr;

class AndroidJniDelegate : public JniDelegate {
 public:
  explicit AndroidJniDelegate(
      const fml::jni::JavaObjectWeakGlobalRef& java_object)
      : java_object_(java_object) {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    platform_task_runner_ = fml::MessageLoop::GetCurrent().GetTaskRunner();
  }

  void HandlePlatformMessage(const std::string& channel,
                             const uint8_t* message,
                             size_t message_size,
                             int32_t response_id,
                             int64_t /*message_data*/) override {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    fml::jni::ScopedJavaLocalRef<jobject> java_obj = java_object_.get(env);
    if (java_obj.is_null()) {
      return;
    }
    fml::jni::ScopedJavaLocalRef<jstring> java_channel(
        env, env->NewStringUTF(channel.c_str()));
    fml::jni::ScopedJavaLocalRef<jobject> java_message;
    if (message != nullptr && message_size > 0) {
      java_message.Reset(env, env->NewDirectByteBuffer(
                                  const_cast<uint8_t*>(message), message_size));
    }
    env->CallVoidMethod(java_obj.obj(), g_handle_platform_message_method,
                        java_channel.obj(), java_message.obj(), response_id,
                        static_cast<jlong>(0));
    fml::jni::CheckException(env);
  }

  void HandlePlatformMessageResponse(int32_t response_id,
                                     const uint8_t* response,
                                     size_t response_size) override {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    fml::jni::ScopedJavaLocalRef<jobject> java_obj = java_object_.get(env);
    if (java_obj.is_null()) {
      return;
    }
    fml::jni::ScopedJavaLocalRef<jobject> java_response;
    if (response != nullptr && response_size > 0) {
      java_response.Reset(
          env, env->NewDirectByteBuffer(const_cast<uint8_t*>(response),
                                        response_size));
    }
    env->CallVoidMethod(java_obj.obj(),
                        g_handle_platform_message_response_method, response_id,
                        java_response.obj());
    fml::jni::CheckException(env);
  }

  void OnFirstFrame() override {
    TRACE_EVENT0("flutter", "AndroidJniDelegate::OnFirstFrame");
    if (platform_task_runner_ &&
        !platform_task_runner_->RunsTasksOnCurrentThread()) {
      fml::jni::JavaObjectWeakGlobalRef weak_java_obj = java_object_;
      platform_task_runner_->PostTask([weak_java_obj]() {
        JNIEnv* env = fml::jni::AttachCurrentThread();
        fml::jni::ScopedJavaLocalRef<jobject> java_obj = weak_java_obj.get(env);
        if (java_obj.is_null()) {
          return;
        }
        env->CallVoidMethod(java_obj.obj(), g_on_first_frame_method);
        fml::jni::CheckException(env);
      });
      return;
    }
    JNIEnv* env = fml::jni::AttachCurrentThread();
    fml::jni::ScopedJavaLocalRef<jobject> java_obj = java_object_.get(env);
    if (java_obj.is_null()) {
      return;
    }
    env->CallVoidMethod(java_obj.obj(), g_on_first_frame_method);
    fml::jni::CheckException(env);
  }

  void OnEngineRestart() override {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    fml::jni::ScopedJavaLocalRef<jobject> java_obj = java_object_.get(env);
    if (java_obj.is_null()) {
      return;
    }
    env->CallVoidMethod(java_obj.obj(), g_on_engine_restart_method);
    fml::jni::CheckException(env);
  }

  void RequestDartDeferredLibrary(intptr_t loading_unit_id) override {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    fml::jni::ScopedJavaLocalRef<jobject> java_obj = java_object_.get(env);
    if (java_obj.is_null()) {
      return;
    }
    env->CallVoidMethod(java_obj.obj(), g_request_dart_deferred_library_method,
                        static_cast<jint>(loading_unit_id));
    fml::jni::CheckException(env);
  }

  uintptr_t CreateSurfaceControl(const std::string& /*debug_name*/,
                                 int32_t /*width*/,
                                 int32_t /*height*/) override {
    return 0;
  }

  void ReleaseSurfaceControl(uintptr_t /*surface_control_handle*/) override {}

  bool SetBufferWithFence(uintptr_t /*surface_control_handle*/,
                          uintptr_t /*hardware_buffer_handle*/,
                          int /*fence_fd*/) override {
    return false;
  }

  bool ApplyTransaction() override { return false; }

  uintptr_t AcquireLatestHardwareBuffer(int64_t /*texture_id*/,
                                        uint32_t* /*out_width*/,
                                        uint32_t* /*out_height*/) override {
    return 0;
  }

  void ReleaseHardwareBuffer(uintptr_t /*hardware_buffer_handle*/) override {}

  void RequestVsync(intptr_t /*baton*/) override {}

 private:
  fml::jni::JavaObjectWeakGlobalRef java_object_;
  fml::RefPtr<fml::TaskRunner> platform_task_runner_;
};

static jlong AttachJNI(JNIEnv* env, jclass clazz, jobject flutterJNI) {
  fml::jni::JavaObjectWeakGlobalRef java_object(env, flutterJNI);
  auto jni_delegate =
      std::make_shared<AndroidJniDelegate>(std::move(java_object));
  const auto& settings = FlutterMain::Get().GetSettings();
  auto embedder_native = std::make_unique<FlutterEmbedderNative>(
      settings, std::move(jni_delegate));
  if (embedder_native->IsValid()) {
    return reinterpret_cast<jlong>(embedder_native.release());
  }
  return 0;
}

static void DestroyJNI(JNIEnv* env, jobject jcaller, jlong shell_holder) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder != nullptr) {
    delete embedder;
  }
}

static jobject SpawnJNI(JNIEnv* env,
                        jobject jcaller,
                        jlong shell_holder,
                        jstring jEntrypoint,
                        jstring jLibraryUrl,
                        jstring jInitialRoute,
                        jobject jEntrypointArgs,
                        jlong engineId) {
  auto* parent_embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (parent_embedder == nullptr) {
    FML_LOG(ERROR) << "Invalid parent embedder for spawn";
    return nullptr;
  }
  jobject jni = env->NewObject(g_flutter_jni_class->obj(), g_jni_constructor);
  if (jni == nullptr) {
    FML_LOG(ERROR) << "Could not create FlutterJNI instance";
    return nullptr;
  }
  fml::jni::JavaObjectWeakGlobalRef java_object(env, jni);
  auto child_delegate =
      std::make_shared<AndroidJniDelegate>(std::move(java_object));
  auto entrypoint = fml::jni::JavaStringToString(env, jEntrypoint);
  auto libraryUrl = fml::jni::JavaStringToString(env, jLibraryUrl);
  auto initial_route = fml::jni::JavaStringToString(env, jInitialRoute);
  auto entrypoint_args = fml::jni::StringListToVector(env, jEntrypointArgs);
  auto spawned =
      parent_embedder->Spawn(std::move(child_delegate), entrypoint, libraryUrl,
                             initial_route, entrypoint_args, engineId);
  if (spawned == nullptr || !spawned->IsValid()) {
    FML_LOG(ERROR) << "Could not spawn FlutterEmbedderNative";
    return nullptr;
  }
  jobject javaLong =
      env->CallStaticObjectMethod(g_java_long_class->obj(), g_long_constructor,
                                  reinterpret_cast<jlong>(spawned.release()));
  fml::jni::CheckException(env);
  if (javaLong == nullptr) {
    FML_LOG(ERROR) << "Could not create Long instance";
    return nullptr;
  }
  env->SetObjectField(jni, g_jni_shell_holder_field, javaLong);
  fml::jni::CheckException(env);
  return jni;
}

static void RunBundleAndSnapshotFromLibrary(JNIEnv* env,
                                            jobject jcaller,
                                            jlong shell_holder,
                                            jstring jBundlePath,
                                            jstring jEntrypoint,
                                            jstring jLibraryUrl,
                                            jobject jAssetManager,
                                            jobject jEntrypointArgs,
                                            jlong engineId) {
  TRACE_EVENT0("flutter", "FlutterJNI::RunBundleAndSnapshotFromLibrary");
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder == nullptr) {
    return;
  }
  auto bundle_path = fml::jni::JavaStringToString(env, jBundlePath);
  auto entrypoint = fml::jni::JavaStringToString(env, jEntrypoint);
  auto libraryUrl = fml::jni::JavaStringToString(env, jLibraryUrl);
  auto entrypoint_args = fml::jni::StringListToVector(env, jEntrypointArgs);

  AAssetManager* asset_manager = nullptr;
#if defined(__ANDROID__)
  embedder->SetJavaAssetManager(env, jAssetManager);
  if (jAssetManager != nullptr) {
    asset_manager = AAssetManager_fromJava(env, jAssetManager);
  }
#endif

  embedder->Launch(bundle_path, FlutterMain::Get().GetSettings().icu_data_path,
                   entrypoint, libraryUrl, entrypoint_args, engineId,
                   asset_manager);
}

static void DispatchEmptyPlatformMessage(JNIEnv* env,
                                         jobject jcaller,
                                         jlong shell_holder,
                                         jstring channel,
                                         jint response_id) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder == nullptr) {
    return;
  }
  embedder->SendPlatformMessage(fml::jni::JavaStringToString(env, channel),
                                nullptr, 0, response_id);
}

static void CleanupMessageData(JNIEnv* env,
                               jobject jcaller,
                               jlong message_data) {}

static void DispatchPlatformMessage(JNIEnv* env,
                                    jobject jcaller,
                                    jlong shell_holder,
                                    jstring channel,
                                    jobject message,
                                    jint position,
                                    jint response_id) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder == nullptr) {
    return;
  }
  const uint8_t* message_data = nullptr;
  if (message != nullptr && position > 0) {
    message_data =
        static_cast<const uint8_t*>(env->GetDirectBufferAddress(message));
  }
  embedder->SendPlatformMessage(fml::jni::JavaStringToString(env, channel),
                                message_data, static_cast<size_t>(position),
                                response_id);
}

static void InvokePlatformMessageResponseCallback(JNIEnv* env,
                                                  jobject jcaller,
                                                  jlong shell_holder,
                                                  jint responseId,
                                                  jobject message,
                                                  jint position) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder == nullptr) {
    return;
  }
  const uint8_t* response_data = nullptr;
  if (message != nullptr && position > 0) {
    response_data =
        static_cast<const uint8_t*>(env->GetDirectBufferAddress(message));
  }
  embedder->RespondToPlatformMessage(responseId, response_data,
                                     static_cast<size_t>(position));
}

static void InvokePlatformMessageEmptyResponseCallback(JNIEnv* env,
                                                       jobject jcaller,
                                                       jlong shell_holder,
                                                       jint responseId) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder == nullptr) {
    return;
  }
  embedder->RespondToPlatformMessage(responseId, nullptr, 0);
}

static void JniNotifyLowMemoryWarning(JNIEnv* env,
                                      jobject obj,
                                      jlong shell_holder) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder != nullptr) {
    embedder->NotifyLowMemoryWarning();
  }
}

static jobject GetBitmap(JNIEnv* env, jobject jcaller, jlong shell_holder) {
  return nullptr;
}

static void SurfaceCreated(JNIEnv* env,
                           jobject jcaller,
                           jlong shell_holder,
                           jobject jsurface) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder != nullptr) {
#if defined(__ANDROID__)
    fml::jni::ScopedJavaLocalFrame scoped_local_reference_frame(env);
    ANativeWindow* window = nullptr;
    if (jsurface != nullptr) {
      window = ANativeWindow_fromSurface(env, jsurface);
      if (window != nullptr) {
        ANativeWindow_setBuffersGeometry(window, 0, 0,
                                         1 /* WINDOW_FORMAT_RGBA_8888 */);
      }
    }
    embedder->NotifySurfaceCreated(reinterpret_cast<uintptr_t>(window));
#else
    embedder->NotifySurfaceCreated();
#endif
  }
}

static void SurfaceWindowChanged(JNIEnv* env,
                                 jobject jcaller,
                                 jlong shell_holder,
                                 jobject jsurface) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder != nullptr) {
    // Invariant 5 & Embedder API state machine: surface must be destroyed
    // synchronously before attaching a new native window.
    embedder->NotifySurfaceDestroyed();
#if defined(__ANDROID__)
    fml::jni::ScopedJavaLocalFrame scoped_local_reference_frame(env);
    ANativeWindow* window = nullptr;
    if (jsurface != nullptr) {
      window = ANativeWindow_fromSurface(env, jsurface);
      if (window != nullptr) {
        ANativeWindow_setBuffersGeometry(window, 0, 0,
                                         1 /* WINDOW_FORMAT_RGBA_8888 */);
      }
    }
    embedder->NotifySurfaceCreated(reinterpret_cast<uintptr_t>(window));
#else
    embedder->NotifySurfaceCreated();
#endif
  }
}

static void SurfaceChanged(JNIEnv* env,
                           jobject jcaller,
                           jlong shell_holder,
                           jint width,
                           jint height) {
  TRACE_EVENT0("flutter", "FlutterJNI::SurfaceChanged");
  if (auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder)) {
    if (embedder->GetSurfaceControl() != nullptr) {
      embedder->GetSurfaceControl()->NotifySurfaceChanged(
          embedder->GetEngineHandle(), /*view_id=*/0, width, height,
          /*pixel_ratio=*/1.0);
    }
  }
}

static void SurfaceDestroyed(JNIEnv* env, jobject jcaller, jlong shell_holder) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder != nullptr) {
    embedder->NotifySurfaceDestroyed();
  }
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
                               jint systemGestureInsetLeft,
                               jint physicalTouchSlop,
                               jintArray javaDisplayFeaturesBounds,
                               jintArray javaDisplayFeaturesType,
                               jintArray javaDisplayFeaturesState,
                               jint physicalMinWidth,
                               jint physicalMaxWidth,
                               jint physicalMinHeight,
                               jint physicalMaxHeight,
                               jint physicalDisplayCornerRadiusTopLeft,
                               jint physicalDisplayCornerRadiusTopRight,
                               jint physicalDisplayCornerRadiusBottomRight,
                               jint physicalDisplayCornerRadiusBottomLeft) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder == nullptr) {
    return;
  }

  jsize rectSize = javaDisplayFeaturesBounds != nullptr
                       ? env->GetArrayLength(javaDisplayFeaturesBounds)
                       : 0;
  std::vector<int> boundsIntVector(rectSize);
  if (rectSize > 0) {
    env->GetIntArrayRegion(javaDisplayFeaturesBounds, 0, rectSize,
                           boundsIntVector.data());
  }
  std::vector<double> displayFeaturesBounds(boundsIntVector.begin(),
                                            boundsIntVector.end());

  jsize typeSize = javaDisplayFeaturesType != nullptr
                       ? env->GetArrayLength(javaDisplayFeaturesType)
                       : 0;
  std::vector<int32_t> displayFeaturesType(typeSize);
  if (typeSize > 0) {
    env->GetIntArrayRegion(javaDisplayFeaturesType, 0, typeSize,
                           displayFeaturesType.data());
  }

  jsize stateSize = javaDisplayFeaturesState != nullptr
                        ? env->GetArrayLength(javaDisplayFeaturesState)
                        : 0;
  std::vector<int32_t> displayFeaturesState(stateSize);
  if (stateSize > 0) {
    env->GetIntArrayRegion(javaDisplayFeaturesState, 0, stateSize,
                           displayFeaturesState.data());
  }

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(FlutterWindowMetricsEvent);
  event.width = static_cast<size_t>(physicalWidth > 0 ? physicalWidth : 0);
  event.height = static_cast<size_t>(physicalHeight > 0 ? physicalHeight : 0);
  event.pixel_ratio = static_cast<double>(devicePixelRatio);
  event.left = 0;
  event.top = 0;
  event.physical_view_inset_top = static_cast<double>(physicalViewInsetTop);
  event.physical_view_inset_right = static_cast<double>(physicalViewInsetRight);
  event.physical_view_inset_bottom =
      static_cast<double>(physicalViewInsetBottom);
  event.physical_view_inset_left = static_cast<double>(physicalViewInsetLeft);
  event.display_id = 0;
  event.view_id = 0;
  const bool valid_width_constraints =
      physicalMaxWidth > 0 && physicalMaxWidth >= physicalMinWidth &&
      physicalWidth >= physicalMinWidth && physicalWidth <= physicalMaxWidth;
  const bool valid_height_constraints =
      physicalMaxHeight > 0 && physicalMaxHeight >= physicalMinHeight &&
      physicalHeight >= physicalMinHeight &&
      physicalHeight <= physicalMaxHeight;

  if (valid_width_constraints && valid_height_constraints) {
    event.has_constraints = true;
    event.min_width_constraint = static_cast<size_t>(physicalMinWidth);
    event.max_width_constraint = static_cast<size_t>(physicalMaxWidth);
    event.min_height_constraint = static_cast<size_t>(physicalMinHeight);
    event.max_height_constraint = static_cast<size_t>(physicalMaxHeight);
  } else {
    event.has_constraints = false;
    event.min_width_constraint = 0;
    event.max_width_constraint = 0;
    event.min_height_constraint = 0;
    event.max_height_constraint = 0;
  }

  event.has_extended_metrics = true;
  event.physical_padding_top = static_cast<double>(physicalPaddingTop);
  event.physical_padding_right = static_cast<double>(physicalPaddingRight);
  event.physical_padding_bottom = static_cast<double>(physicalPaddingBottom);
  event.physical_padding_left = static_cast<double>(physicalPaddingLeft);
  event.physical_system_gesture_inset_top =
      static_cast<double>(systemGestureInsetTop);
  event.physical_system_gesture_inset_right =
      static_cast<double>(systemGestureInsetRight);
  event.physical_system_gesture_inset_bottom =
      static_cast<double>(systemGestureInsetBottom);
  event.physical_system_gesture_inset_left =
      static_cast<double>(systemGestureInsetLeft);
  event.physical_touch_slop = static_cast<double>(physicalTouchSlop);

  size_t feature_count = 0;
  if (rectSize >= 4 && typeSize > 0 && stateSize > 0) {
    feature_count =
        std::min({static_cast<size_t>(rectSize / 4),
                  static_cast<size_t>(typeSize), static_cast<size_t>(stateSize),
                  static_cast<size_t>(kFlutterMaxDisplayFeatures)});
  }

  event.display_features_count = feature_count;
  if (feature_count > 0) {
    event.display_features_bounds = displayFeaturesBounds.data();
    event.display_features_type = displayFeaturesType.data();
    event.display_features_state = displayFeaturesState.data();
  } else {
    event.display_features_bounds = nullptr;
    event.display_features_type = nullptr;
    event.display_features_state = nullptr;
  }

  event.physical_display_corner_radius_top_left =
      static_cast<double>(physicalDisplayCornerRadiusTopLeft);
  event.physical_display_corner_radius_top_right =
      static_cast<double>(physicalDisplayCornerRadiusTopRight);
  event.physical_display_corner_radius_bottom_right =
      static_cast<double>(physicalDisplayCornerRadiusBottomRight);
  event.physical_display_corner_radius_bottom_left =
      static_cast<double>(physicalDisplayCornerRadiusBottomLeft);

  embedder->SendWindowMetricsEvent(event);
}

static void JniDispatchPointerDataPacket(JNIEnv* env,
                                         jobject jcaller,
                                         jlong shell_holder,
                                         jobject buffer,
                                         jint position) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder == nullptr) {
    return;
  }
  uint8_t* data = static_cast<uint8_t*>(env->GetDirectBufferAddress(buffer));
  if (data != nullptr && position > 0) {
    embedder->DispatchPointerDataPacket(data, static_cast<size_t>(position));
  }
}

static void JniDispatchSemanticsAction(JNIEnv* env,
                                       jobject jcaller,
                                       jlong shell_holder,
                                       jint id,
                                       jint action,
                                       jobject args,
                                       jint args_position) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder == nullptr) {
    return;
  }
  uint8_t* args_data = nullptr;
  size_t args_size = 0;
  if (args != nullptr && args_position > 0) {
    args_data = static_cast<uint8_t*>(env->GetDirectBufferAddress(args));
    args_size = static_cast<size_t>(args_position);
  }
  embedder->DispatchSemanticsAction(id, action, args_data, args_size);
}

static void JniSetSemanticsEnabled(JNIEnv* env,
                                   jobject jcaller,
                                   jlong shell_holder,
                                   jboolean enabled) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder != nullptr) {
    embedder->SetSemanticsEnabled(enabled);
  }
}

static void JniSetAccessibilityFeatures(JNIEnv* env,
                                        jobject jcaller,
                                        jlong shell_holder,
                                        jint flags) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder != nullptr) {
    embedder->SetAccessibilityFeatures(flags);
  }
}

static jboolean GetIsSoftwareRendering(JNIEnv* env, jobject jcaller) {
  return false;
}

static void RegisterTexture(JNIEnv* env,
                            jobject jcaller,
                            jlong shell_holder,
                            jlong texture_id,
                            jobject surface_texture) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder != nullptr) {
    embedder->RegisterExternalTexture(static_cast<int64_t>(texture_id));
    embedder->RegisterJavaTexture(env, static_cast<int64_t>(texture_id),
                                  surface_texture);
  }
}

static void RegisterImageTexture(JNIEnv* env,
                                 jobject jcaller,
                                 jlong shell_holder,
                                 jlong texture_id,
                                 jobject image_texture_entry,
                                 jboolean reset_on_background) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder != nullptr) {
    embedder->RegisterExternalTexture(static_cast<int64_t>(texture_id));
    embedder->RegisterJavaTexture(env, static_cast<int64_t>(texture_id),
                                  image_texture_entry);
  }
}

static void UnregisterTexture(JNIEnv* env,
                              jobject jcaller,
                              jlong shell_holder,
                              jlong texture_id) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder != nullptr) {
    embedder->UnregisterExternalTexture(static_cast<int64_t>(texture_id));
    embedder->UnregisterJavaTexture(static_cast<int64_t>(texture_id));
  }
}

static void MarkTextureFrameAvailable(JNIEnv* env,
                                      jobject jcaller,
                                      jlong shell_holder,
                                      jlong texture_id) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder != nullptr) {
    embedder->MarkExternalTextureFrameAvailable(
        static_cast<int64_t>(texture_id));
    embedder->UpdateJavaTexture(env, static_cast<int64_t>(texture_id));
  }
}

static void JniScheduleFrame(JNIEnv* env, jobject jcaller, jlong shell_holder) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder != nullptr) {
    embedder->ScheduleFrame();
  }
}

static jobject LookupCallbackInformation(JNIEnv* env,
                                         jobject /*unused*/,
                                         jlong handle) {
  return nullptr;
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

static void JniLoadDartDeferredLibrary(JNIEnv* env,
                                       jobject obj,
                                       jlong shell_holder,
                                       jint jLoadingUnitId,
                                       jobjectArray jSearchPaths) {
  auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder);
  if (embedder == nullptr) {
    return;
  }
  intptr_t loading_unit_id = static_cast<intptr_t>(jLoadingUnitId);
  std::vector<std::string> search_paths =
      fml::jni::StringArrayToVector(env, jSearchPaths);

  void* handle = nullptr;
  for (const std::string& path : search_paths) {
    handle = ::dlopen(path.c_str(), RTLD_NOW);
    if (handle != nullptr) {
      break;
    }
  }
  if (handle == nullptr) {
    return;
  }
  fml::RefPtr<fml::NativeLibrary> native_lib =
      fml::NativeLibrary::CreateWithHandle(handle, false);

  constexpr const char* kIsolateDataSymbol = "kDartSnapshotData";
  constexpr const char* kIsolateInstructionsSymbol = "kDartSnapshotText";

  struct DeferredSymbolHolder {
    std::unique_ptr<const fml::SymbolMapping> data;
    std::unique_ptr<const fml::SymbolMapping> instructions;
  };
  auto* holder =
      new DeferredSymbolHolder{std::make_unique<const fml::SymbolMapping>(
                                   native_lib, kIsolateDataSymbol),
                               std::make_unique<const fml::SymbolMapping>(
                                   native_lib, kIsolateInstructionsSymbol)};

  FlutterDartDeferredLibrary library = {};
  library.struct_size = sizeof(FlutterDartDeferredLibrary);
  library.loading_unit_id = loading_unit_id;
  library.snapshot_data = holder->data->GetMapping();
  library.snapshot_data_size = holder->data->GetSize();
  library.snapshot_instructions = holder->instructions->GetMapping();
  library.snapshot_instructions_size = holder->instructions->GetSize();
  library.user_data = holder;
  library.destruction_callback = [](void* user_data) {
    delete static_cast<DeferredSymbolHolder*>(user_data);
  };
  embedder->LoadDartDeferredLibrary(&library);
}

static void UpdateJavaAssetManager(JNIEnv* env,
                                   jobject obj,
                                   jlong shell_holder,
                                   jobject jAssetManager,
                                   jstring jAssetBundlePath) {
  TRACE_EVENT0("flutter", "FlutterJNI::UpdateJavaAssetManager");
  if (auto* embedder = FlutterEmbedderNative::FromHandle(shell_holder)) {
    AAssetManager* asset_manager = nullptr;
#if defined(__ANDROID__)
    embedder->SetJavaAssetManager(env, jAssetManager);
    if (jAssetManager != nullptr) {
      asset_manager = AAssetManager_fromJava(env, jAssetManager);
    }
#endif
    std::string bundle_path =
        jAssetBundlePath != nullptr
            ? fml::jni::JavaStringToString(env, jAssetBundlePath)
            : "";
    embedder->UpdateAssetManager(asset_manager, bundle_path);
  }
}

static void DeferredComponentInstallFailure(JNIEnv* env,
                                            jobject obj,
                                            jint jLoadingUnitId,
                                            jstring jError,
                                            jboolean jTransient) {}

static void UpdateDisplayMetrics(JNIEnv* env,
                                 jobject jcaller,
                                 jlong shell_holder) {}

static jboolean IsSurfaceControlEnabled(JNIEnv* env,
                                        jobject jcaller,
                                        jlong shell_holder) {
  return false;
}

static void OnVsyncFromJava(JNIEnv* env,
                            jclass jcaller,
                            jlong frameDelayNanos,
                            jlong refreshPeriodNanos,
                            jlong cookie) {}

static void OnUpdateRefreshRate(JNIEnv* env,
                                jclass jcaller,
                                jfloat refresh_rate) {}

}  // namespace

bool FlutterEmbedderNative::RegisterJni(JNIEnv* env) {
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

  g_java_long_class = new fml::jni::ScopedJavaGlobalRef<jclass>(
      env, env->FindClass("java/lang/Long"));
  if (g_java_long_class->is_null()) {
    FML_LOG(ERROR) << "Could not locate Long class";
    return false;
  }

  g_long_constructor = env->GetStaticMethodID(g_java_long_class->obj(),
                                              "valueOf", "(J)Ljava/lang/Long;");
  if (g_long_constructor == nullptr) {
    FML_LOG(ERROR) << "Could not locate Long.valueOf";
    return false;
  }

  g_jni_shell_holder_field = env->GetFieldID(
      g_flutter_jni_class->obj(), "nativeShellHolderId", "Ljava/lang/Long;");
  if (g_jni_shell_holder_field == nullptr) {
    FML_LOG(ERROR) << "Could not locate FlutterJNI.nativeShellHolderId";
    return false;
  }

  g_jni_constructor =
      env->GetMethodID(g_flutter_jni_class->obj(), "<init>", "()V");
  if (g_jni_constructor == nullptr) {
    FML_LOG(ERROR) << "Could not locate FlutterJNI.<init>";
    return false;
  }

  g_handle_platform_message_method =
      env->GetMethodID(g_flutter_jni_class->obj(), "handlePlatformMessage",
                       "(Ljava/lang/String;Ljava/nio/ByteBuffer;IJ)V");
  g_handle_platform_message_response_method = env->GetMethodID(
      g_flutter_jni_class->obj(), "handlePlatformMessageResponse",
      "(ILjava/nio/ByteBuffer;)V");
  g_on_first_frame_method =
      env->GetMethodID(g_flutter_jni_class->obj(), "onFirstFrame", "()V");
  g_on_engine_restart_method =
      env->GetMethodID(g_flutter_jni_class->obj(), "onPreEngineRestart", "()V");
  g_request_dart_deferred_library_method = env->GetMethodID(
      g_flutter_jni_class->obj(), "requestDartDeferredLibrary", "(I)V");

  static const JNINativeMethod flutter_jni_methods[] = {
      {
          .name = "nativeAttach",
          .signature = "(Lio/flutter/embedding/engine/FlutterJNI;)J",
          .fnPtr = reinterpret_cast<void*>(&AttachJNI),
      },
      {
          .name = "nativeDestroy",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&DestroyJNI),
      },
      {
          .name = "nativeSpawn",
          .signature = "(JLjava/lang/String;Ljava/lang/String;Ljava/lang/"
                       "String;Ljava/util/List;J)Lio/flutter/"
                       "embedding/engine/FlutterJNI;",
          .fnPtr = reinterpret_cast<void*>(&SpawnJNI),
      },
      {
          .name = "nativeRunBundleAndSnapshotFromLibrary",
          .signature = "(JLjava/lang/String;Ljava/lang/String;"
                       "Ljava/lang/String;Landroid/content/res/"
                       "AssetManager;Ljava/util/List;J)V",
          .fnPtr = reinterpret_cast<void*>(&RunBundleAndSnapshotFromLibrary),
      },
      {
          .name = "nativeDispatchEmptyPlatformMessage",
          .signature = "(JLjava/lang/String;I)V",
          .fnPtr = reinterpret_cast<void*>(&DispatchEmptyPlatformMessage),
      },
      {
          .name = "nativeCleanupMessageData",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&CleanupMessageData),
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
          .fnPtr = reinterpret_cast<void*>(&JniNotifyLowMemoryWarning),
      },
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
          .signature = "(JFIIIIIIIIIIIIIII[I[I[IIIIIIIII)V",
          .fnPtr = reinterpret_cast<void*>(&SetViewportMetrics),
      },
      {
          .name = "nativeDispatchPointerDataPacket",
          .signature = "(JLjava/nio/ByteBuffer;I)V",
          .fnPtr = reinterpret_cast<void*>(&JniDispatchPointerDataPacket),
      },
      {
          .name = "nativeDispatchSemanticsAction",
          .signature = "(JIILjava/nio/ByteBuffer;I)V",
          .fnPtr = reinterpret_cast<void*>(&JniDispatchSemanticsAction),
      },
      {
          .name = "nativeSetSemanticsEnabled",
          .signature = "(JZ)V",
          .fnPtr = reinterpret_cast<void*>(&JniSetSemanticsEnabled),
      },
      {
          .name = "nativeSetAccessibilityFeatures",
          .signature = "(JI)V",
          .fnPtr = reinterpret_cast<void*>(&JniSetAccessibilityFeatures),
      },
      {
          .name = "nativeGetIsSoftwareRenderingEnabled",
          .signature = "()Z",
          .fnPtr = reinterpret_cast<void*>(&GetIsSoftwareRendering),
      },
      {
          .name = "nativeRegisterTexture",
          .signature = "(JJLjava/lang/ref/WeakReference;)V",
          .fnPtr = reinterpret_cast<void*>(&RegisterTexture),
      },
      {
          .name = "nativeRegisterImageTexture",
          .signature = "(JJLjava/lang/ref/WeakReference;Z)V",
          .fnPtr = reinterpret_cast<void*>(&RegisterImageTexture),
      },
      {
          .name = "nativeMarkTextureFrameAvailable",
          .signature = "(JJ)V",
          .fnPtr = reinterpret_cast<void*>(&MarkTextureFrameAvailable),
      },
      {
          .name = "nativeScheduleFrame",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&JniScheduleFrame),
      },
      {
          .name = "nativeUnregisterTexture",
          .signature = "(JJ)V",
          .fnPtr = reinterpret_cast<void*>(&UnregisterTexture),
      },
      {
          .name = "nativeLookupCallbackInformation",
          .signature = "(J)Lio/flutter/view/FlutterCallbackInformation;",
          .fnPtr = reinterpret_cast<void*>(&LookupCallbackInformation),
      },
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
      {
          .name = "nativeLoadDartDeferredLibrary",
          .signature = "(JI[Ljava/lang/String;)V",
          .fnPtr = reinterpret_cast<void*>(&JniLoadDartDeferredLibrary),
      },
      {
          .name = "nativeUpdateJavaAssetManager",
          .signature =
              "(JLandroid/content/res/AssetManager;Ljava/lang/String;)V",
          .fnPtr = reinterpret_cast<void*>(&UpdateJavaAssetManager),
      },
      {
          .name = "nativeDeferredComponentInstallFailure",
          .signature = "(ILjava/lang/String;Z)V",
          .fnPtr = reinterpret_cast<void*>(&DeferredComponentInstallFailure),
      },
      {
          .name = "nativeUpdateDisplayMetrics",
          .signature = "(J)V",
          .fnPtr = reinterpret_cast<void*>(&UpdateDisplayMetrics),
      },
      {
          .name = "nativeIsSurfaceControlEnabled",
          .signature = "(J)Z",
          .fnPtr = reinterpret_cast<void*>(&IsSurfaceControlEnabled),
      },
      {
          .name = "nativeOnVsync",
          .signature = "(JJJ)V",
          .fnPtr = reinterpret_cast<void*>(&OnVsyncFromJava),
      },
      {
          .name = "nativeUpdateRefreshRate",
          .signature = "(F)V",
          .fnPtr = reinterpret_cast<void*>(&OnUpdateRefreshRate),
      },
  };

  if (env->RegisterNatives(g_flutter_jni_class->obj(), flutter_jni_methods,
                           std::size(flutter_jni_methods)) != 0) {
    FML_LOG(ERROR) << "Failed to RegisterNatives with FlutterJNI";
    return false;
  }

  return true;
}

}  // namespace flutter
