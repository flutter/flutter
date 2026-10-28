// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_

#include <jni.h>
#include <cstdint>
#include <memory>
#include <string>
#include <unordered_map>

#include "flutter/fml/macros.h"

namespace flutter {

class CallbackCacheProvider {
 public:
  struct CallbackInfo {
    std::string name;
    std::string class_name;
    std::string library_path;
  };

  virtual ~CallbackCacheProvider() = default;
  virtual void SetCachePath(const std::string& path) = 0;
  virtual void LoadCacheFromDisk() = 0;
  virtual std::unique_ptr<CallbackInfo> LookupCallbackInformation(
      int64_t handle) = 0;
};

class DefaultCallbackCacheProvider : public CallbackCacheProvider {
 public:
  DefaultCallbackCacheProvider() = default;
  ~DefaultCallbackCacheProvider() override = default;

  void SetCachePath(const std::string& path) override;
  void LoadCacheFromDisk() override;
  std::unique_ptr<CallbackInfo> LookupCallbackInformation(
      int64_t handle) override;
};

class InMemoryCallbackCacheProvider : public CallbackCacheProvider {
 public:
  InMemoryCallbackCacheProvider() = default;
  ~InMemoryCallbackCacheProvider() override = default;

  void SetCachePath(const std::string& path) override;
  void LoadCacheFromDisk() override;
  std::unique_ptr<CallbackInfo> LookupCallbackInformation(
      int64_t handle) override;

  void RegisterCallback(int64_t handle,
                        const std::string& name,
                        const std::string& class_name,
                        const std::string& library_path);

  const std::string& GetCachePath() const { return cache_path_; }
  bool WasLoadedFromDisk() const { return loaded_from_disk_; }

 private:
  std::string cache_path_;
  bool loaded_from_disk_ = false;
  std::unordered_map<int64_t, CallbackInfo> callbacks_;
};

class JniDelegate {
 public:
  static void SetCallbackCacheProvider(
      std::shared_ptr<CallbackCacheProvider> provider);
  static std::shared_ptr<CallbackCacheProvider> GetCallbackCacheProvider();

  static jboolean GetIsSoftwareRenderingEnabled(JNIEnv* env, jobject jcaller);
  static jlong Attach(JNIEnv* env,
                      jobject jcaller,
                      jobject flutter_jni = nullptr);
  static void Destroy(JNIEnv* env, jobject jcaller, jlong shell_holder);
  static jobject Spawn(JNIEnv* env,
                       jobject jcaller,
                       jlong shell_holder,
                       jstring jEntrypoint,
                       jstring jLibraryUrl,
                       jstring jInitialRoute,
                       jobject jEntrypointArgs,
                       jlong engine_id);
  static void RunBundleAndSnapshotFromLibrary(JNIEnv* env,
                                              jobject jcaller,
                                              jlong shell_holder,
                                              jstring jBundlePath,
                                              jstring jEntrypoint,
                                              jstring jLibraryUrl,
                                              jobject jAssetManager,
                                              jobject jEntrypointArgs,
                                              jlong engine_id);
  static void UpdateJavaAssetManager(JNIEnv* env,
                                     jobject jcaller,
                                     jlong shell_holder,
                                     jobject jAssetManager,
                                     jstring jAssetBundlePath);
  static jobject LookupCallbackInformation(JNIEnv* env,
                                           jclass clazz,
                                           jlong handle);

  static void SurfaceCreated(JNIEnv* env,
                             jobject jcaller,
                             jlong shell_holder,
                             jobject jsurface);
  static void SurfaceWindowChanged(JNIEnv* env,
                                   jobject jcaller,
                                   jlong shell_holder,
                                   jobject jsurface);
  static void SurfaceChanged(JNIEnv* env,
                             jobject jcaller,
                             jlong shell_holder,
                             jint width,
                             jint height);
  static void SurfaceDestroyed(JNIEnv* env,
                               jobject jcaller,
                               jlong shell_holder);

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
                                 jint physicalDisplayCornerRadiusBottomLeft);

  static void UpdateDisplayMetrics(JNIEnv* env,
                                   jobject jcaller,
                                   jlong shell_holder);

  static void DispatchEmptyPlatformMessage(JNIEnv* env,
                                           jobject jcaller,
                                           jlong shell_holder,
                                           jstring channel,
                                           jint response_id);
  static void DispatchPlatformMessage(JNIEnv* env,
                                      jobject jcaller,
                                      jlong shell_holder,
                                      jstring channel,
                                      jobject message,
                                      jint position,
                                      jint response_id);
  static void InvokePlatformMessageEmptyResponseCallback(JNIEnv* env,
                                                         jobject jcaller,
                                                         jlong shell_holder,
                                                         jint response_id);
  static void InvokePlatformMessageResponseCallback(JNIEnv* env,
                                                    jobject jcaller,
                                                    jlong shell_holder,
                                                    jint response_id,
                                                    jobject message,
                                                    jint position);

  static void DispatchPointerDataPacket(JNIEnv* env,
                                        jobject jcaller,
                                        jlong shell_holder,
                                        jobject buffer,
                                        jint position);
  static void DispatchSemanticsAction(JNIEnv* env,
                                      jobject jcaller,
                                      jlong shell_holder,
                                      jint id,
                                      jint action,
                                      jobject args,
                                      jint args_position);
  static void SetSemanticsEnabled(JNIEnv* env,
                                  jobject jcaller,
                                  jlong shell_holder,
                                  jboolean enabled);
  static void SetAccessibilityFeatures(JNIEnv* env,
                                       jobject jcaller,
                                       jlong shell_holder,
                                       jint flags);

  static void RegisterTexture(JNIEnv* env,
                              jobject jcaller,
                              jlong shell_holder,
                              jlong texture_id,
                              jobject surface_texture_wrapper);
  static void RegisterImageTexture(JNIEnv* env,
                                   jobject jcaller,
                                   jlong shell_holder,
                                   jlong texture_id,
                                   jobject image_texture_entry,
                                   jboolean reset_on_background);
  static void MarkTextureFrameAvailable(JNIEnv* env,
                                        jobject jcaller,
                                        jlong shell_holder,
                                        jlong texture_id);
  static void ScheduleFrame(JNIEnv* env, jobject jcaller, jlong shell_holder);
  static void UnregisterTexture(JNIEnv* env,
                                jobject jcaller,
                                jlong shell_holder,
                                jlong texture_id);

  static void NotifyLowMemoryWarning(JNIEnv* env,
                                     jobject jcaller,
                                     jlong shell_holder);
  static void LoadDartDeferredLibrary(JNIEnv* env,
                                      jobject jcaller,
                                      jlong shell_holder,
                                      jint loading_unit_id,
                                      jobjectArray search_paths);
  static void DeferredComponentInstallFailure(JNIEnv* env,
                                              jobject jcaller,
                                              jint loading_unit_id,
                                              jstring error,
                                              jboolean is_transient);

  static void Init(JNIEnv* env,
                   jclass clazz,
                   jobject context,
                   jobjectArray args,
                   jstring bundle_path,
                   jstring app_storage_path,
                   jstring engine_caches_path,
                   jlong init_time_millis,
                   jint api_level);
  static void PrefetchDefaultFontManager(JNIEnv* env, jclass clazz);
  static void OnVsync(JNIEnv* env,
                      jclass clazz,
                      jlong frame_delay_nanos,
                      jlong refresh_period_nanos,
                      jlong java_baton);
  static void UpdateRefreshRate(JNIEnv* env,
                                jclass clazz,
                                jfloat refresh_rate_fps);

  static jboolean ShouldDisableAHB(JNIEnv* env, jobject jcaller);

  static void CleanupMessageData(JNIEnv* env,
                                 jobject jcaller,
                                 jlong message_data);
  static jboolean IsSurfaceControlEnabled(JNIEnv* env,
                                          jobject jcaller,
                                          jlong shell_holder);
  static jboolean FlutterTextUtilsIsEmoji(JNIEnv* env,
                                          jobject jcaller,
                                          jint code_point);
  static jboolean FlutterTextUtilsIsEmojiModifier(JNIEnv* env,
                                                  jobject jcaller,
                                                  jint code_point);
  static jboolean FlutterTextUtilsIsEmojiModifierBase(JNIEnv* env,
                                                      jobject jcaller,
                                                      jint code_point);
  static jboolean FlutterTextUtilsIsVariationSelector(JNIEnv* env,
                                                      jobject jcaller,
                                                      jint code_point);
  static jboolean FlutterTextUtilsIsRegionalIndicator(JNIEnv* env,
                                                      jobject jcaller,
                                                      jint code_point);
  static void ImageHeaderCallback(JNIEnv* env,
                                  jclass clazz,
                                  jlong generator_pointer,
                                  jint width,
                                  jint height);

 private:
  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(JniDelegate);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_
